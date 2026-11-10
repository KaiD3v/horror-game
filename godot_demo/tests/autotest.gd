# Base of the scripted play-tests. `godot --path . res://scenes/<...>.tscn -- --autotest` makes the scene attach
# res://tests/test_<scene>.gd (Level / menu call attach()), which plays it through: checks print
# "AUTOTEST ok|FAIL <what>", captures go to res://captures/demo_<name>.png, and it ends with "AUTOTEST PASS" or
# "AUTOTEST FAILED: ..." and quits. A test overrides run(); `L` is the scene under test, `player` its player.
class_name AutoTest
extends Node

var L: Node
var player: Player
var fails: Array[String] = []


static func attach(scene: Node) -> void:
	var path := Paths.TESTS % scene.scene_file_path.get_file().get_basename()
	if not ResourceLoader.exists(path):
		print("AUTOTEST no test at %s" % path)
		return
	var t: AutoTest = load(path).new(); t.L = scene
	scene.add_child.call_deferred(t)  # once the scene has finished building


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(Paths.CAPTURES))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if L is Level:
		player = L.player
		L.hud.legend.visible = false
		for e in get_tree().get_nodes_in_group("enemy"):
			if e is Enemy:
				e.active = false  # dormant until a test wakes it
	await run()
	print("AUTOTEST %s" % ("PASS" if fails.is_empty() else "FAILED: " + ", ".join(fails)))
	get_tree().quit()


func run() -> void:
	pass


# --- helpers ----------------------------------------------------------------------------------------------
func check(ok: bool, what: String) -> void:
	print("AUTOTEST %s %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		fails.append(what)


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/demo_%s.png" % [Paths.CAPTURES, n])


func press(a: String, s: float) -> void:
	Input.action_press(a); await wait(s); Input.action_release(a)


func tap(a: String) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame; await get_tree().process_frame  # one frame could be lost to a shader-compile hitch
	e = InputEventAction.new(); e.action = a; e.pressed = false
	Input.parse_input_event(e)
	await get_tree().process_frame  # ...and the release (a button acts on it)


func until(cond: Callable, timeout: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t0 > timeout * 1000.0:
			return false
		await get_tree().process_frame
	return true


## Teleport a body (yaw 0 = facing north, -z); the player's camera and coat come along.
func put(body: Node3D, pos: Vector3, yaw: float) -> void:
	body.global_position = pos + Vector3(0, 0.05, 0); body.rotation.y = yaw
	if body == player:
		player.velocity = Vector3.ZERO; player.pivot.rotation.y = yaw
		player.pivot.global_position = pos + Vector3(0, 1.55, 0)
		player.coat.reset()  # a teleport would whip the coat


## Hold forward for s seconds of wall-clock (a shader hitch would eat a fixed frame count).
func walk(s: float) -> void:
	Input.action_press("forward"); await wait(s); Input.action_release("forward")


## Top-down capture of the level with its navmesh in red (only the polygons keep(centre) accepts).
func map_shot(name: String, at: Vector3, size: float, light: float, hide: Array = [], keep := func(_c): return true, alpha := 0.35) -> void:
	var nm: NavigationMesh = L.nav.navigation_mesh
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts := nm.get_vertices()
	for i in nm.get_polygon_count():
		var poly := nm.get_polygon(i)
		var mid := Vector3.ZERO
		for idx in poly:
			mid += verts[idx] / poly.size()
		if not keep.call(mid):
			continue
		for k in range(1, poly.size() - 1):
			for idx in [poly[0], poly[k], poly[k + 1]]:
				st.add_vertex(verts[idx] + Vector3(0, 0.15, 0))
	var overlay = MeshInstance3D.new(); overlay.mesh = st.commit(); L.add_child(overlay)
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.85, 0.15, 0.1, alpha); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED; overlay.material_override = m
	var top = Camera3D.new(); L.add_child(top)
	top.projection = Camera3D.PROJECTION_ORTHOGONAL; top.size = size; top.far = 200
	top.position = at; top.rotation.x = -PI / 2
	for n in hide:
		n.visible = false
	var fog: bool = L.env.fog_enabled; var amb: float = L.env.ambient_light_energy
	L.env.fog_enabled = false; L.env.ambient_light_energy = light
	top.make_current(); await wait(0.2); await shot(name)
	L.env.fog_enabled = fog; L.env.ambient_light_energy = amb
	for n in hide:
		n.visible = true
	player.cam.make_current(); top.queue_free(); overlay.queue_free()


## Every note of this scene (NotesData): lies on something solid, E beside it reads it (paused), it is kept,
## Tab rereads them.
func notes_suite() -> void:
	var mine = NotesData.in_scene(L.scene_id)
	var papers := {}
	for p in L.find_children("*", "NotePaper", false, false):
		papers[p.id] = p
	check(papers.size() == mine.size() and papers.values().all(func(p): return p.placed),
		"%d note(s) lying here, on something solid" % mine.size())
	for n in mine:
		var paper: NotePaper = papers[n.id]
		var found := false
		for k in 8:  # stand beside it, on the floor, from whichever side is free
			var dir := Vector3.FORWARD.rotated(Vector3.UP, k * TAU / 8)
			var from := paper.global_position + dir * 0.9 + Vector3.UP * 0.3
			var down: Dictionary = L.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.0, 1, [player.get_rid()]))
			if down.is_empty():
				continue
			player.global_position = down.position + Vector3.UP * 0.05; player.velocity = Vector3.ZERO
			player.pivot.rotation.y = atan2(dir.x, dir.z)  # the camera behind him, looking at the paper
			player.pivot.global_position = player.global_position + Vector3(0, 1.55, 0)
			await wait(0.5)
			if L.interactor.current == paper:
				found = true; break
		check(found and L.hud.prompt.visible and L.hud.prompt.text == "E · ler", "next to \"%s\": E · ler" % n.title)
		await shot("nota_%s_chao" % n.id)
		await tap("interact"); await wait(0.3)
		check(get_tree().paused and L.notes.page.visible and L.notes.text.text == n.text, "E reads \"%s\", the game paused" % n.title)
		await shot("nota_%s" % n.id)
		await tap("interact"); await wait(0.3)
		check(not get_tree().paused and not is_instance_valid(paper) and n.id in NotesReader.read,
			"closed, kept: %d read" % NotesReader.read.size())
	await tap("notes"); await wait(0.2)
	var reread: bool = L.notes.showing == NotesReader.read.size() - 1 and get_tree().paused
	await tap("notes"); await wait(0.2)
	check(reread and not get_tree().paused, "Tab rereads the notes found, Tab closes")

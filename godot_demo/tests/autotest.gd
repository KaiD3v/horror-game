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
		Inventory.reset(); Inventory.give_tools(); Shop.reset(); Chest.reset(); Story.reset()  # the tests hold every weapon (their own test takes them away)
		WorldTime.reset(16 * 60 + 30); Weather.force(1.0, 1.0)  # the same light every run: late afternoon, fog, drizzle
		if L.day:
			L.day._step(0.0)
		player = L.player
		for e in get_tree().get_nodes_in_group("enemy"):
			if e is Enemy:
				e.active = false  # dormant until a test wakes it
	var only := only_suite()
	if only != "" and has_method(only + "_tests"):  # `-- --autotest --only=<x>`: just <x>_tests()
		await Callable(self, only + "_tests").call()
	else:
		await run()
	print("AUTOTEST %s" % ("PASS" if fails.is_empty() else "FAILED: " + ", ".join(fails)))
	get_tree().quit()


func run() -> void:
	pass


## `--only=<x>` on the command line: run just that suite (x_tests) of the scene's test.
static func only_suite() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			return a.trim_prefix("--only=")
	return ""


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
## Tab lists them in the notebook.
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
			player.pivot.rotation.y = atan2(dir.x, dir.z); player.rotation.y = player.pivot.rotation.y  # he and the camera look at the paper
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
	Caderno.section = 2  # Tab: the notebook (Caderno), its Notas page lists them, E there rereads one
	await tap("notes"); await wait(0.2)
	var listed: bool = L.caderno.visible and get_tree().paused and L.caderno.rows.size() == NotesReader.read.size()
	await tap("notes"); await wait(0.2)
	check(listed and not L.caderno.visible and not get_tree().paused, "Tab: the notes found listed in the notebook, Tab closes")


## Every trunk ChestData puts here: on the ground, with clear floor in front of it where he kneels; a capture of it.
func chest_suite() -> void:
	var here: Array = L.find_children("*", "Chest", true, false)
	check(here.size() == ChestData.in_scene(L.scene_id).size(), "%d trunk(s) here" % here.size())
	var w: World3D = L.get_world_3d()
	for c: Chest in here:
		var spot := c.global_position + c.global_basis.z * Chest.FRONT
		var down := w.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(c.global_position + Vector3.UP * 0.05, c.global_position + Vector3.DOWN))  # from inside its own box
		var under: Dictionary = L.ray(spot.x, spot.z, c.global_position.y + 1.5)
		var room := w.direct_space_state.intersect_shape(_capsule_at(spot + Vector3(0, 0.95, 0)))
		check(not down.is_empty() and absf(down.position.y - c.global_position.y) < 0.15 and not under.is_empty()
			and absf(under.position.y - c.global_position.y) < 0.3 and room.is_empty(),
			"trunk %s on the ground, room to kneel before it (floor %.2f / %.2f, %d in the way)"
			% [c.id, under.position.y if under else INF, c.global_position.y, room.size()])
		put(player, spot + c.global_basis.z * 1.0, c.rotation.y); await wait(0.6); await shot("bau_" + c.id)


func _capsule_at(at: Vector3) -> PhysicsShapeQueryParameters3D:  # the player's body standing at `at` (its middle)
	var q := PhysicsShapeQueryParameters3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.25; cap.height = 1.6
	q.shape = cap; q.transform = Transform3D(Basis(), at); q.exclude = [player.get_rid()]
	return q


## Every seller here (an Npc with "loja"): you talk to them across the counter, "Ver o que tem à venda" opens their list
## (paused), buying spends money and adds the goods, no money = no sale, the stock runs out, Esc back to the talk.
func shop_suite() -> void:
	for who in L.npcs:
		var npc: Npc = L.npcs[who]
		if not npc.info.has("loja"):
			continue
		var found := false
		for k in 16:  # stand on the floor in front of them, within reach of the counter
			var dir := Vector3.FORWARD.rotated(Vector3.UP, k * TAU / 16)
			var from: Vector3 = npc.global_position + dir * (1.4 + 0.3 * (k % 2)) + Vector3.UP * 1.2
			var down: Dictionary = L.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.0, 1, [player.get_rid()]))
			if down.is_empty() or down.position.y > npc.global_position.y + 0.3:
				continue
			put(player, down.position, atan2(dir.x, dir.z)); await wait(0.4)
			if L.interactor.current == npc.talk:
				found = true; break
		check(found and L.hud.prompt.text == "E · falar com %s" % npc.info.nome, "%s: \"%s\"" % [who, L.hud.prompt.text])
		await tap("interact"); await wait(0.3)
		var box: DialogBox = L.dialog
		box._choose()  # past their greeting
		var at := -1
		for i in box.rows.size():
			if box.rows[i].text.ends_with("Ver o que tem à venda"):
				at = i
		check(box.visible and at >= 0, "talking to %s: \"Ver o que tem à venda\" among the options" % who)
		box.pick(at); await wait(0.3)
		var menu: ShopMenu = L.shop
		var shop_id: String = npc.info.loja
		var offers := Shop.offers(shop_id)
		check(menu.visible and get_tree().paused and menu.rows.size() == offers.size(), "E opens %s's list, the game paused (%d items)" % [who, menu.rows.size()])
		var ambient: Array = L.find_children("*", "", true, false).filter(func(a):
			return (a is AudioStreamPlayer or a is AudioStreamPlayer3D) and a.playing and a.process_mode == Node.PROCESS_MODE_ALWAYS)
		await wait(0.3)
		check(ambient.size() > 0 and ambient.all(func(a): return a.playing and not a.stream_paused and a.can_process()),
			"the room's sounds go on while you buy (%d loops)" % ambient.size())
		await shot("loja_%s" % shop_id)
		var o: Dictionary = offers[0]
		var money := Inventory.money; var had := Inventory.count(o.item)
		await tap("interact"); await wait(0.1)
		check(Inventory.money == money - o.preco and Inventory.count(o.item) == had + o.qtd,
			"buying %s: %s spent, %d more in the bag" % [o.item, ItemCatalog.price(o.preco), Inventory.count(o.item) - had])
		Inventory.money = 0; had = Inventory.count(o.item)
		await tap("interact"); await wait(0.1)
		check(Inventory.money == 0 and Inventory.count(o.item) == had and menu.line.text.contains("Volta"), "no money, no sale: %s" % menu.line.text)
		var limited := -1
		for i in offers.size():
			if offers[i].estoque >= 0:
				limited = i
		if limited >= 0:
			Inventory.money = 9999
			while Shop.left(shop_id, limited) > 0:
				menu.buy(limited)
			menu.buy(limited)
			check(menu.line.text.contains("Acabou") and Shop.left(shop_id, limited) == 0, "the stock runs out: %s" % menu.line.text)
		await tap("back"); await wait(0.1)
		check(menu.focused() == 1 % menu.rows.size(), "S moves down the list")
		await tap("ui_cancel"); await wait(0.2)
		check(not menu.visible and box.visible and box.choosing and get_tree().paused, "Esc leaves the shop, back to the talk")
		await tap("ui_cancel"); await wait(0.2)
		check(not box.visible and not get_tree().paused, "Esc again ends the talk")
		Inventory.reset(); Inventory.give_tools(); Shop.reset()

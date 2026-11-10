# Engine check of protagonista.glb (not a scene test): inspects the import and captures frames of every animation.
# Run: Godot_console.exe --path godot_demo --script res://tests/protagonista_anims.gd
extends SceneTree

const OUT := "res://captures/"
const PHASES := [0.0, 0.25, 0.5, 0.75, 1.0]

var ap: AnimationPlayer
var sun: DirectionalLight3D
var env: Environment


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var model: Node3D = load("res://models/characters/protagonista.glb").instantiate()
	root.add_child(model)
	ap = model.find_child("AnimationPlayer", true, false)
	var sk: Skeleton3D = _first(model, "Skeleton3D")

	# --- report ---------------------------------------------------------------------------
	print("REPORT skeleton bones=", sk.get_bone_count(),
		" grip.L=", sk.find_bone("grip.L"), " lantern=", sk.find_bone("lantern"), " machete=", sk.find_bone("machete"))
	for n in ap.get_animation_list():
		var a := ap.get_animation(n)
		print("REPORT anim %-16s length=%.3f loop=%d tracks=%d" % [n, a.length, a.loop_mode, a.get_track_count()])
	var mi: MeshInstance3D = _first(model, "MeshInstance3D")
	var aabb := mi.get_aabb()
	print("REPORT mesh surfaces=", mi.mesh.get_surface_count(), " aabb_size=", aabb.size, " skin=", mi.skin != null)
	for i in mi.mesh.get_surface_count():
		var m := mi.get_active_material(i)
		if m is BaseMaterial3D and m.albedo_texture:
			print("REPORT material %s texture=%s filter=%d" % [m.resource_name, m.albedo_texture.resource_name, m.texture_filter])

	# --- stage: neutral light + the lantern light riding the lantern bone -----------------
	var cam := Camera3D.new(); root.add_child(cam)
	cam.transform = Transform3D(Basis(), Vector3(2.0, 1.2, 3.0)).looking_at(Vector3(0, 0.85, 0)); cam.fov = 35
	sun = DirectionalLight3D.new(); root.add_child(sun)
	sun.rotation_degrees = Vector3(-50, 30, 0); sun.light_energy = 1.2
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.22, 0.22, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55); env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var ba := BoneAttachment3D.new(); ba.bone_name = "lantern"; sk.add_child(ba)
	var omni := OmniLight3D.new(); ba.add_child(omni)
	omni.position = Vector3(0, 0.09, 0)  # glass centre, down the bone
	omni.light_color = Color(1.0, 0.62, 0.28); omni.light_energy = 1.0; omni.omni_range = 3.0
	_capture.call_deferred()


func _first(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := _first(c, cls)
		if r:
			return r
	return null


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func _capture() -> void:
	for n in ap.get_animation_list():
		var length := ap.get_animation(n).length
		for i in PHASES.size():
			ap.play(n); ap.seek(PHASES[i] * length, true); ap.pause()
			await _shot("%s%s_%d.png" % [OUT, n, i])
	# night shot: lantern only
	env.background_color = Color(0.01, 0.012, 0.02); env.ambient_light_energy = 0.05; sun.visible = false
	for n in ["Idle_Lantern", "Combat_Idle", "Death"]:  # Godot strips the _Loop suffix
		ap.play(n); ap.seek(ap.get_animation(n).length * (1.0 if n == "Death" else 0.0), true); ap.pause()
		await _shot("%snight_%s.png" % [OUT, n])
	print("REPORT done")
	quit()

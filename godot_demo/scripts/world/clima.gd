# Weather over the village (../docs/VILAREJO.md "Clima"): a fine drizzle that stops under roofs, puddles on the road
# that catch the lantern, banks of mist rolling down the valley from the Colônia, dead leaves on the wind, ash still
# lifting off the burnt house. One wind for all of it. vilarejo.gd adds this and calls setup().
class_name Clima
extends Node3D

const WIND := Vector3(0.3, 0, 1.0)       # down from the Colônia (north, -z) towards the ravine
const MIST := Color(0.31, 0.33, 0.35)    # a shade lighter than the fog, so the banks read against it
const BANKS := 46
const PUDDLES := 18

var player: Node3D
var rain: GPUParticles3D
var rain_sound: AudioStreamPlayer
var leaves: GPUParticles3D
var ash: GPUParticles3D
var embers: GPUParticles3D
var puddles: Array[MeshInstance3D] = []
var banks: Array[MeshInstance3D] = []
var _bank_h: Array[float] = []      # height of each bank's centre over the ground
var _reground := 0.0


var area: AABB                       # the playable area: where the mist banks roam


func setup(p: Node3D, road: PackedVector2Array, burnt: Vector3, play_area: AABB) -> void:
	player = p; area = play_area
	var hf := GPUParticlesCollisionHeightField3D.new(); add_child(hf)  # roofs, eaves and the ground stop rain and leaves
	hf.size = Vector3(32, 40, 32); hf.resolution = GPUParticlesCollisionHeightField3D.RESOLUTION_256
	hf.follow_camera_enabled = true; hf.update_mode = GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS
	_rain(); _leaves(); _ash(burnt); _banks(); _puddles(road)
	rain_sound = Audio.play2d(self, "garoa", -15.0, true)


func _process(delta: float) -> void:
	if player == null:
		return
	var at := player.global_position
	rain.global_position = at + Vector3(0, 9, 0) - WIND.normalized() * 1.5  # upwind, so it lands round you
	leaves.global_position = at + Vector3(0, 2.5, 0) - WIND.normalized() * 6.0
	_drift(delta)


# --- drizzle: thin streaks, slanted by the wind ----------------------------------------------------------
func _rain() -> void:
	rain = GPUParticles3D.new(); add_child(rain)
	rain.amount = 2000; rain.lifetime = 1.3; rain.local_coords = false; rain.preprocess = 1.3
	rain.visibility_aabb = AABB(Vector3(-14, -14, -14), Vector3(28, 18, 28))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; m.emission_box_extents = Vector3(13, 0.5, 13)
	m.direction = (Vector3.DOWN * 7.0 + WIND.normalized()).normalized(); m.spread = 2.0
	m.initial_velocity_min = 7.0; m.initial_velocity_max = 8.5; m.gravity = Vector3.ZERO
	m.particle_flag_align_y = true
	m.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	rain.process_material = m
	var q := QuadMesh.new(); q.size = Vector2(0.01, 0.22)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.7, 0.75, 0.8, 0.17); mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	q.material = mat; rain.draw_pass_1 = q


# --- dead leaves on the wind; they settle where they land ---------------------------------------------------
func _leaves() -> void:
	leaves = GPUParticles3D.new(); add_child(leaves)
	leaves.amount = 120; leaves.lifetime = 9.0; leaves.local_coords = false; leaves.preprocess = 6.0
	leaves.visibility_aabb = AABB(Vector3(-20, -6, -20), Vector3(40, 12, 40))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; m.emission_box_extents = Vector3(14, 2.5, 14)
	m.direction = WIND.normalized(); m.spread = 25.0
	m.initial_velocity_min = 1.0; m.initial_velocity_max = 2.6; m.gravity = Vector3(0, -0.6, 0)
	m.turbulence_enabled = true; m.turbulence_noise_strength = 2.5; m.turbulence_noise_scale = 3.0
	m.turbulence_influence_min = 0.15; m.turbulence_influence_max = 0.35
	m.particle_flag_align_y = true  # it turns with every gust
	m.collision_mode = ParticleProcessMaterial.COLLISION_RIGID; m.collision_bounce = 0.0; m.collision_friction = 1.0
	var g := Gradient.new()  # browns and a few yellows
	g.set_color(0, Color(0.36, 0.22, 0.12)); g.set_color(1, Color(0.62, 0.48, 0.2)); g.add_point(0.6, Color(0.45, 0.3, 0.14))
	var gt := GradientTexture1D.new(); gt.gradient = g; m.color_initial_ramp = gt
	m.scale_min = 0.7; m.scale_max = 1.3
	leaves.process_material = m
	leaves.draw_pass_1 = _flake(Vector2(0.06, 0.09), _leaf_tex(), false)


func _leaf_tex() -> ImageTexture:  # 8x12 pointed oval, alpha cut, nearest like everything else
	var img := Image.create(8, 12, false, Image.FORMAT_RGBA8)
	for y in 12:
		for x in 8:
			var u := (x + 0.5) / 8.0 * 2.0 - 1.0; var v := (y + 0.5) / 12.0 * 2.0 - 1.0
			var w := 1.0 - absf(v)  # pointed at both ends
			img.set_pixel(x, y, Color(1, 1, 1, 1) * (0.75 if x == 4 else 1.0) if absf(u) < w * 0.95 else Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _flake(size: Vector2, tex: Texture2D, glow: bool) -> QuadMesh:
	var q := QuadMesh.new(); q.size = size
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true; mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0; mat.metallic_specular = 0.0
	if tex:
		mat.albedo_texture = tex; mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	if glow:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = mat
	return q


# --- ash lifting off the burnt house, a few embers still alive in it -----------------------------------------
func _ash(at: Vector3) -> void:
	for glow in [false, true]:
		var e := GPUParticles3D.new(); add_child(e); e.position = at + Vector3(0, 0.6, 0)
		e.amount = 18 if glow else 160; e.lifetime = 4.0 if glow else 10.0; e.preprocess = 8.0
		e.local_coords = false; e.visibility_aabb = AABB(Vector3(-12, -2, -12), Vector3(30, 14, 30))
		var m := ParticleProcessMaterial.new()
		m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; m.emission_box_extents = Vector3(3.5, 0.6, 3.0)
		m.direction = (Vector3.UP * 0.8 + WIND.normalized()).normalized(); m.spread = 30.0
		m.initial_velocity_min = 0.3; m.initial_velocity_max = 0.9; m.gravity = Vector3(0, -0.02, 0)
		m.turbulence_enabled = true; m.turbulence_noise_strength = 1.5; m.turbulence_noise_scale = 2.0
		m.angular_velocity_min = -180; m.angular_velocity_max = 180
		m.color = Color(1.0, 0.45, 0.12) if glow else Color(0.62, 0.6, 0.57)
		m.scale_min = 0.6; m.scale_max = 1.4
		e.process_material = m
		e.draw_pass_1 = _flake(Vector2(0.03, 0.03) if glow else Vector2(0.06, 0.045), null, glow)
		if glow:
			embers = e
		else:
			ash = e


# --- mist banks: big soft cards standing on the ground, turned to the camera, drifting downhill -------------
func _banks() -> void:
	var sh := Paths.shader("neblina_bancos")
	var nt := NoiseTexture2D.new(); nt.seamless = true; nt.width = 128; nt.height = 128
	var fn := FastNoiseLite.new(); fn.frequency = 0.02; nt.noise = fn
	for i in BANKS:
		var mat := ShaderMaterial.new(); mat.shader = sh
		mat.set_shader_parameter("noise", nt); mat.set_shader_parameter("tint", MIST)
		mat.set_shader_parameter("seed", randf() * 10.0); mat.set_shader_parameter("density", randf_range(0.35, 0.6))
		var q := QuadMesh.new(); q.size = Vector2(randf_range(9, 18), randf_range(2.5, 5.0)); q.material = mat
		var card := MeshInstance3D.new(); card.mesh = q; card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(card)
		card.global_position = Vector3(randf_range(area.position.x, area.end.x), 0, randf_range(area.position.z, area.end.z))
		_bank_h.append(q.size.y * 0.45 - 0.2)
		card.global_position.y = _ground(card.global_position.x, card.global_position.z) + _bank_h[i]
		banks.append(card)


func _drift(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var w := WIND.normalized() * 0.6 * delta  # a slow walk downhill
	_reground -= delta
	for i in banks.size():
		var c := banks[i]
		c.global_position += w
		if c.global_position.z > area.end.z:  # out past the ravine: rolls in again from the Colônia's wall
			c.global_position = Vector3(randf_range(area.position.x, area.end.x), 0, area.position.z)
			c.global_position.y = _ground(c.global_position.x, c.global_position.z) + _bank_h[i]
		elif c.global_position.x > area.end.x:
			c.global_position.x = area.position.x
		if _reground <= 0.0:  # follow the slope, smoothly
			c.global_position.y = lerpf(c.global_position.y, _ground(c.global_position.x, c.global_position.z) + _bank_h[i], 0.5)
		if cam:
			var to := cam.global_position - c.global_position
			c.rotation.y = atan2(to.x, to.z)
	if _reground <= 0.0:
		_reground = 0.4


# --- puddles along the road: dark, glossy, rings from the drizzle ----------------------------------------------
func _puddles(road: PackedVector2Array) -> void:
	var sh := Paths.shader("poca")
	var nt := NoiseTexture2D.new(); nt.seamless = true; nt.width = 64; nt.height = 64
	var fn := FastNoiseLite.new(); fn.frequency = 0.05; nt.noise = fn
	var rng := RandomNumberGenerator.new(); rng.seed = 1974
	var tries := 0
	while puddles.size() < PUDDLES and tries < 200:
		tries += 1
		var i := rng.randi_range(0, road.size() - 2)
		var p := road[i].lerp(road[i + 1], rng.randf()) + Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.2, 1.2))
		var hit := _ray(p.x, p.y)
		if hit.is_empty() or hit.normal.y < 0.96:  # only on flat ground, not on a prop
			continue
		var mat := ShaderMaterial.new(); mat.shader = sh
		mat.set_shader_parameter("noise", nt); mat.set_shader_parameter("seed", rng.randf() * 10.0)
		mat.set_shader_parameter("sky", Color(0.25, 0.27, 0.29))
		var pm := PlaneMesh.new(); var s := rng.randf_range(0.9, 2.2); pm.size = Vector2(s, s * rng.randf_range(0.6, 1.0))
		pm.material = mat
		var m := MeshInstance3D.new(); m.mesh = pm; m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		m.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, hit.normal)) * Basis(Vector3.UP, rng.randf() * TAU),
			hit.position + hit.normal * 0.045)  # over the blood decals (0.035)
		puddles.append(m)


func _ray(x: float, z: float) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 60, z), Vector3(x, -30, z))
	return get_world_3d().direct_space_state.intersect_ray(q)


func _ground(x: float, z: float) -> float:
	var hit := _ray(x, z)
	return hit.position.y if hit else 0.0

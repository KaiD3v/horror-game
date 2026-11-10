# The game's look, shared by every level: N64-style materials (nearest texels, no shine), world environments,
# lights, triplanar scenery materials and solid boxes for greyboxing.
class_name Looks


## Imported (GLB) materials: nearest texels like the characters, no shine.
static func n64(root: Node) -> void:
	Nodes.visit_surfaces(root, func(_mi, _i, m):
		if m is BaseMaterial3D:
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			m.roughness = 1.0; m.metallic_specular = 0.2)


## Materials that give their own light (window panes, lamp glass, embers) ignore the lighting.
static func unshade(root: Node, names: Array) -> void:
	Nodes.visit_surfaces(root, func(_mi, _i, m):
		if m is BaseMaterial3D and m.resource_name in names:
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED)


## A WorldEnvironment from a preset (Atmospheres): bg, ambient, ambient_energy, fog, fog_density
## [, fog_height, fog_height_density].
static func environment(parent: Node, p: Dictionary) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = p.bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = p.ambient; env.ambient_light_energy = p.ambient_energy
	env.fog_enabled = true; env.fog_light_color = p.fog; env.fog_density = p.fog_density
	if p.has("fog_height"):
		env.fog_height = p.fog_height; env.fog_height_density = p.fog_height_density
	var we := WorldEnvironment.new(); we.environment = env; parent.add_child(we)
	return env


static func sky_light(parent: Node, rot: Vector3, color: Color, energy: float) -> DirectionalLight3D:
	var l := DirectionalLight3D.new(); parent.add_child(l)
	l.rotation_degrees = rot; l.light_color = color; l.light_energy = energy
	return l


static func omni(parent: Node, at: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	var o := OmniLight3D.new(); parent.add_child(o); o.position = at
	o.light_color = color; o.light_energy = energy; o.omni_range = reach
	return o


## Scenery texture (../tools/texturas -> res://textures) tiled in world space, so boxes of any size share one scale
## and neighbouring boxes line up; nearest filtering like the characters' textures.
static func triplanar(name: String, scale := 1.0, tint := Color.WHITE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(Paths.TEXTURE % name); m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_triplanar = true; m.uv1_world_triplanar = true; m.uv1_scale = Vector3.ONE * scale
	m.roughness = 1.0; m.metallic_specular = 0.2
	return m


## A solid box (greybox walls, props); look: a Color or a Material.
static func box(parent: Node, pos: Vector3, size: Vector3, look: Variant) -> StaticBody3D:
	var body := StaticBody3D.new(); parent.add_child(body); body.position = pos
	var shape := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = size; shape.shape = bs
	body.add_child(shape)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm; body.add_child(mi)
	if look is Material:
		bm.material = look
	else:
		var mat := StandardMaterial3D.new(); mat.albedo_color = look; bm.material = mat
	return body

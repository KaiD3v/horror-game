# The parlatório (../docs/INTRODUCAO.md): where the interned met their visitors, their own children among them,
# through a wire screen from wall to wall, never touching; a counter each side to lean on, a bench each side.
# It is in the Colônia (colonia.gd, by the gatehouse) and in the opening's memory of 1955 (Abertura).
# build(parent, at, yaw, width): the screen across the origin along local x, the visitors' side towards +z.
class_name Parlatorio

const HIGH := 2.6             # the screen's top rail
static var wire: StandardMaterial3D


static func build(parent: Node3D, at: Vector3, yaw: float, width: float) -> Node3D:
	var root := Node3D.new(); parent.add_child(root); root.position = at; root.rotation.y = yaw
	var wood := Looks.triplanar("painted_wood", 1.5)
	Looks.box(root, Vector3(0, 0.45, 0), Vector3(width, 0.9, 0.1), wood)            # the low wall under it
	Looks.box(root, Vector3(0, HIGH, 0), Vector3(width, 0.12, 0.12), wood)          # the top rail
	for i in int(width / 1.5) + 1:                                                     # posts
		Looks.box(root, Vector3(-width / 2 + 0.04 + i * (width - 0.08) / int(width / 1.5), (0.9 + HIGH) / 2, 0),
			Vector3(0.08, HIGH - 0.9, 0.1), wood)
	var mesh := MeshInstance3D.new(); root.add_child(mesh); var q := QuadMesh.new()  # the wire
	q.size = Vector2(width, HIGH - 0.96); q.material = _wire(width, HIGH - 0.96); mesh.mesh = q
	mesh.position.y = (0.9 + HIGH) / 2
	var body := StaticBody3D.new(); root.add_child(body); var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
	bs.size = Vector3(width, HIGH, 0.06); cs.shape = bs; cs.position.y = HIGH / 2; body.add_child(cs)
	for s in [-1, 1]:
		Looks.box(root, Vector3(0, 0.93, s * 0.2), Vector3(width, 0.05, 0.3), wood)  # counters
		Looks.box(root, Vector3(0, 0.22, s * 1.2), Vector3(width - 1.2, 0.44, 0.4), wood)  # benches
	return root


static func _wire(w: float, h: float) -> StandardMaterial3D:  # chain link: diagonal wires, see-through between
	if wire == null:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for x in 16:
			for y in 16:
				if (x + y) % 16 == 0 or (x - y + 16) % 16 == 0:
					img.set_pixel(x, y, Color(0.42, 0.42, 0.4))
		wire = StandardMaterial3D.new(); wire.albedo_texture = ImageTexture.create_from_image(img)
		wire.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; wire.cull_mode = BaseMaterial3D.CULL_DISABLED
		wire.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; wire.metallic = 0.5
		wire.uv1_scale = Vector3(w / 0.12, h / 0.12, 1.0)  # a 12 cm diamond
	return wire

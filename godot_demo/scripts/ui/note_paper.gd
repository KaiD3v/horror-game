# A note lying in the world (NotesData): a small aged paper, pale in the dark. E reads it: it goes to NotesReader
# (which keeps it) and leaves the floor.
class_name NotePaper
extends Interactable

var id := ""
var placed := false   # it found something solid under it


static func make(level: Level, n: Dictionary) -> NotePaper:
	var p := NotePaper.new(); p.id = n.id; p.prompt = "E · ler"
	level.add_child(p)
	var hit := level.ray(n.at.x, n.at.y, n.get("from", 30.0))
	p.placed = not hit.is_empty()
	p.position = (hit.position if p.placed else Vector3(n.at.x, 0, n.at.y)) + Vector3.UP * 0.012
	p.rotation.y = deg_to_rad(n.yaw)
	var mi := MeshInstance3D.new(); p.add_child(mi)
	var q := QuadMesh.new(); q.size = Vector2(0.21, 0.27); q.orientation = PlaneMesh.FACE_Y; mi.mesh = q
	var m := StandardMaterial3D.new(); m.albedo_texture = load(Paths.TEXTURE % ("nota_%s_p" % n.paper))
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS; m.roughness = 1.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR  # the torn edge
	m.emission_enabled = true; m.emission = Color(0.55, 0.52, 0.45); m.emission_energy_multiplier = 0.12
	q.material = m
	return p


func _use(_by: Node3D) -> void:
	var reader: NotesReader = get_tree().get_first_node_in_group("notes_reader")
	reader.take(id)
	queue_free()

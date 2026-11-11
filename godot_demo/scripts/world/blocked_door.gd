# A door in a wall that will not open as it is, and what opens it (`kind`):
#   "cadeado"  a padlock on a hasp: E with its key (ItemCatalog tipo "chave", `requires`) and the padlock is gone, the
#              key spent on it (Interactable), the door swings open. No animation of his own.
#   "tabuas"   boarded up, three planks nailed across: E with the crowbar (pe_de_cabra) and he forces them off one by
#              one with it in his hand, then "Porta aberta" (FoundBanner) and the door swings open.
# Once open it stays open (Story "aberta:<id>"). Its origin: the foot of the doorway, the front (where you come from)
# towards +z. make(level, at, yaw, kind, id, key) for one in a level's _build.
class_name BlockedDoor
extends Interactable

const WIDTH := 1.0
const HIGH := 2.1
const WALL := Vector3(4.0, 2.6, 0.3)   # the wall it stands in

var id := ""
var kind := "cadeado"
var leaf: Node3D          # the door itself, on its hinge
var lock_shape: Node3D    # the padlock / the planks
var planks: Array[Node3D] = []
var opening := false


static func make(level: Node, at: Vector3, yaw: float, k: String, door_id: String, key := "") -> BlockedDoor:
	var d := BlockedDoor.new(); d.id = door_id; d.kind = k; d.position = at; d.rotation.y = yaw
	d.radius = 1.3; d.height = 2.0
	if k == "cadeado":
		d.requires = key; d.prompt = "E · abrir o cadeado"; d.refusal = "Trancada com cadeado. Precisa da chave."
	else:
		d.requires = "pe_de_cabra"; d.prompt = "E · arrombar a porta"; d.refusal = "Pregada com tábuas. Com um pé de cabra, talvez."
	level.add_child(d)
	return d


func _ready() -> void:
	super()
	var wall := Looks.triplanar("plaster", 0.5, Color(0.72, 0.68, 0.6))
	var side := (WALL.x - WIDTH) / 2
	for s in [-1, 1]:  # the wall either side of the doorway, and over it
		Looks.box(self, Vector3(s * (WIDTH + side) / 2, WALL.y / 2, 0), Vector3(side, WALL.y, WALL.z), wall)
	Looks.box(self, Vector3(0, (HIGH + WALL.y) / 2, 0), Vector3(WIDTH, WALL.y - HIGH, WALL.z), wall)
	var hinge := Node3D.new(); add_child(hinge); hinge.position = Vector3(-WIDTH / 2, 0, 0.05)  # hinged on the left, opens away
	Looks.box(hinge, Vector3(WIDTH / 2, HIGH / 2, 0), Vector3(WIDTH - 0.04, HIGH - 0.02, 0.06),
		Looks.triplanar("planks", 1.5, Color(0.55, 0.42, 0.32)))
	leaf = hinge
	if kind == "cadeado":
		lock_shape = Node3D.new(); add_child(lock_shape); lock_shape.position = Vector3(WIDTH / 2 - 0.12, 1.0, 0.14)
		_part(lock_shape, Vector3(0.0, 0.0, 0), Vector3(0.07, 0.08, 0.03), Color(0.62, 0.48, 0.2))  # the brass body
		_part(lock_shape, Vector3(0.0, 0.065, 0), Vector3(0.05, 0.05, 0.012), Color(0.4, 0.38, 0.35))  # the shackle
		_part(lock_shape, Vector3(-0.06, 0.06, -0.03), Vector3(0.12, 0.03, 0.02), Color(0.3, 0.28, 0.26))  # the hasp
	else:
		for i in 3:  # three planks across, a little askew
			var p := Node3D.new(); add_child(p); p.position = Vector3(0, 0.55 + i * 0.55, 0.13); p.rotation.z = [0.12, -0.08, 0.15][i]
			_part(p, Vector3.ZERO, Vector3(WIDTH + 0.35, 0.16, 0.035), Color(0.42, 0.32, 0.24), Looks.triplanar("planks", 2.0, Color(0.6, 0.48, 0.38)))
			planks.append(p)
	if Story.has("aberta:" + id):
		_opened(false)


func _part(parent: Node3D, at: Vector3, size: Vector3, col: Color, mat: Material = null) -> void:
	var mi := MeshInstance3D.new(); parent.add_child(mi); mi.position = at
	var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	if mat == null:
		mat = StandardMaterial3D.new(); mat.albedo_color = col; mat.metallic = 0.4
	bm.material = mat


func _use(by: Node3D) -> void:
	if opening or not by is Player:
		return
	opening = true
	if kind == "cadeado":  # the key turned (Interactable spent it): the padlock is just gone
		Audio.play2d(self, "tilintar", -6.0)
		_opened(true)
	else:
		await _force(by)


## The crowbar: he puts away what he holds, faces the door and works each plank off (Push: leaning into the bar).
func _force(p: Player) -> void:
	p.busy = true
	await p.free_hands()
	var spot := global_position + global_basis.z * 0.75; spot.y = p.global_position.y
	var tw := create_tween().set_parallel()
	tw.tween_property(p, "global_position", spot, 0.25)
	tw.tween_property(p, "rotation:y", p.rotation.y + angle_difference(p.rotation.y, rotation.y), 0.25)
	await tw.finished
	var bar := p.hold_item("pe_de_cabra")
	for plank in planks:
		p.play("Push")
		Audio.play2d(self, "rangido", -2.0).pitch_scale = randf_range(0.8, 1.0)
		await get_tree().create_timer(0.7).timeout
		var fall := create_tween().set_parallel()  # it comes away and drops
		fall.tween_property(plank, "rotation:z", plank.rotation.z + randf_range(-1.2, 1.2), 0.4)
		fall.tween_property(plank, "position", plank.position + Vector3(randf_range(-0.3, 0.3), -plank.position.y + 0.05, 0.4), 0.4)
		await fall.finished
		Audio.play2d(self, "pouso", -6.0)
		await get_tree().create_timer(0.3).timeout
	await get_tree().create_timer(0.3).timeout
	bar.queue_free()
	p.busy = false
	await FoundBanner.tell(self, "A PORTA CEDEU", "Porta aberta", "As tábuas saíram. O caminho está livre.")
	_opened(true)


func _opened(now: bool) -> void:
	Story.mark("aberta:" + id)
	enabled = false
	if lock_shape:
		lock_shape.queue_free(); lock_shape = null
	for plank in planks:  # (opened before: they lie on the floor already)
		if not now:
			plank.position = Vector3(plank.position.x, 0.05, 0.5); plank.rotation.z = 0.3
	var to := deg_to_rad(100.0)  # swung in, away from you
	if now:
		Audio.play2d(self, "porta", -6.0)
		create_tween().set_trans(Tween.TRANS_SINE).tween_property(leaf, "rotation:y", to, 1.0)
	else:
		leaf.rotation.y = to

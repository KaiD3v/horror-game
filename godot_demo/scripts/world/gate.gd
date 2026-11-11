# A double gate between two pillars that takes you to another scene (the Colônia's, at the top of the village road).
# Locked at first: a chain through the leaves and a padlock; E with its key (`requires`, ItemCatalog tipo "chave")
# spends the key, the padlock and chain drop and the leaves creak ajar, too narrow a gap to pass (Story "aberta:<id>",
# for good). E again and you go through: `scene`. Its origin: the foot of the opening, its +z the side you come from.
# make(level, at, yaw, id, key, scene, text) for one in a level's _build.
class_name Gate
extends Interactable

const WIDTH := 4.4    # both leaves, closed
const HIGH := 3.2
const AJAR := 15.0    # degrees each leaf swings: a dark gap of ~20 cm, not a way through

var id := ""
var scene := ""
var go_text := ""
var leaves: Array[Node3D] = []
var chain: Node3D


static func make(level: Node, at: Vector3, yaw: float, gate_id: String, key: String, to_scene: String, text: String) -> Gate:
	var g := Gate.new(); g.id = gate_id; g.scene = to_scene; g.go_text = text; g.position = at; g.rotation.y = yaw
	g.requires = key; g.refusal = "Corrente e cadeado. O portão está trancado."
	g.radius = 2.2; g.height = 2.0
	level.add_child(g)
	return g


func opened() -> bool:
	return Story.has("aberta:" + id)


func _ready() -> void:
	super()
	var wood := Looks.triplanar("planks", 1.5, Color(0.42, 0.33, 0.26))
	var iron := StandardMaterial3D.new(); iron.albedo_color = Color(0.22, 0.2, 0.19); iron.metallic = 0.6; iron.roughness = 0.7
	for s in [-1, 1]:  # hinged on the pillars; each leaf reaches to the middle
		var hinge := Node3D.new(); add_child(hinge); hinge.position = Vector3(s * WIDTH / 2, 0, 0)
		Looks.box(hinge, Vector3(-s * WIDTH / 4, HIGH / 2 + 0.05, 0), Vector3(WIDTH / 2 - 0.03, HIGH, 0.1), wood)
		for z in [0.5, HIGH - 0.4]:  # iron straps across
			_part(hinge, Vector3(-s * WIDTH / 4, z, 0.06), Vector3(WIDTH / 2 - 0.1, 0.1, 0.02), iron)
		leaves.append(hinge)
	chain = Node3D.new(); add_child(chain); chain.position = Vector3(0, 1.3, 0.09)
	for k in 9:  # a slack chain across the meeting leaves
		var x := -0.6 + 0.15 * k
		_part(chain, Vector3(x, -0.08 * sin(PI * k / 8.0), 0), Vector3(0.11, 0.05, 0.03), iron).rotation.z = 0.0 if k % 2 else 1.2
	var brass := StandardMaterial3D.new(); brass.albedo_color = Color(0.55, 0.45, 0.22); brass.metallic = 0.5
	_part(chain, Vector3(0.05, -0.17, 0.02), Vector3(0.09, 0.11, 0.04), brass)  # the padlock
	if opened():
		_open(false)
	_update()


func _part(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); parent.add_child(mi); mi.position = at
	var bm := BoxMesh.new(); bm.size = size; bm.material = mat; mi.mesh = bm
	return mi


func _update() -> void:
	prompt = go_text if opened() else "E · abrir o portão"


func _use(by: Node3D) -> void:
	if not by is Player:
		return
	if opened():
		SceneRouter.go_to(self, scene, id, 0.6)
		return
	Story.mark("aberta:" + id)
	Audio.play2d(self, "cadeado_abrir", -4.0)
	by.notice.emit("O cadeado cedeu. O portão abriu uma fresta.")
	_open(true)
	_update()


func _open(now: bool) -> void:
	if chain:
		chain.queue_free(); chain = null
	for i in leaves.size():
		var to := deg_to_rad(AJAR) * (1 if i == 0 else -1)  # both swing in, away from you
		if now:
			get_tree().create_timer(0.8).timeout.connect(func():
				Audio.play2d(self, "porta", -6.0).pitch_scale = 0.7  # heavy, slow
				create_tween().set_trans(Tween.TRANS_SINE).tween_property(leaves[i], "rotation:y", to, 2.0))
		else:
			leaves[i].rotation.y = to

# Something heaped across the way that a tool takes apart blow by blow (a slash one piece, the overhead two,
# Player.HIT_DAMAGE) until none is left and the way is open (Story "quebrado:<id>"); any other blow does nothing to it.
# E near it with the tool in the inventory puts it in his hand (`requires`). What it is (`kind`, KINDS):
#   "entulho"  fallen stone: the pickaxe (picareta)
#   "cana"     bundles of dry sugarcane stacked against a door: the machete (facao)
#   "mato"     a thicket of dry taquara and vine grown over something: the machete (what it hid: the level's)
# Its origin: the foot of its front face (where you come from, +z), the heap behind it. Hit like an enemy: the group
# "breakable" and take_hit(n, by).
class_name Breakable
extends Interactable

signal broken

const SIZE := Vector3(2.2, 1.6, 1.0)
const PIECES := 5
const KINDS := {
	"entulho": {"tool": "picareta", "prompt": "E · pegar a picareta", "refusal": "Pedra demais para tirar com as mãos.",
		"how": "Golpeie a pedra com a picareta (botão esquerdo).", "wrong": "A lâmina só lasca a pedra.",
		"hit": "picareta_pedra", "miss": "bloqueio", "done": "entulho_desabar"},
	"cana": {"tool": "facao", "prompt": "E · sacar o facão", "refusal": "Feixes de cana escorados na porta. Com uma lâmina, talvez.",
		"how": "A lâmina corta isso (botão esquerdo).", "wrong": "Isso não corta cana.",
		"hit": "cana_cortar", "miss": "tabua_cair", "done": "tabua_cair"},
	"mato": {"tool": "facao", "prompt": "E · sacar o facão", "refusal": "Mato fechado. Com um facão, talvez.",
		"how": "A lâmina abre caminho (botão esquerdo).", "wrong": "Isso não corta mato.",
		"hit": "cana_cortar", "miss": "cana_cortar", "done": "cana_cortar"},
}

var id := ""
var kind := "entulho"
var tool := "picareta"
var pieces: Array[Node3D] = []
var body: StaticBody3D
var player: Player


static func make(level: Node, at: Vector3, yaw: float, heap_id: String, what := "entulho") -> Breakable:
	var k: Dictionary = KINDS[what]
	var b := Breakable.new(); b.id = heap_id; b.kind = what; b.tool = k.tool; b.position = at; b.rotation.y = yaw
	b.requires = k.tool; b.prompt = k.prompt; b.refusal = k.refusal
	b.radius = 1.6; b.height = 2.0
	level.add_child(b)
	return b


func _ready() -> void:
	if Story.has("quebrado:" + id):
		queue_free()
		return
	super()
	add_to_group("breakable")
	body = StaticBody3D.new(); add_child(body)  # one block for the whole heap, until the last piece goes
	var cs := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = SIZE; cs.shape = box
	cs.position = Vector3(0, SIZE.y / 2, -SIZE.z / 2); body.add_child(cs)
	if kind == "cana":
		_cane()
		return
	if kind == "mato":
		_thicket()
		return
	var rock := Looks.triplanar("stone", 1.2, Color(0.62, 0.6, 0.56))
	var at := [Vector3(-0.6, 0.35, -0.35), Vector3(0.55, 0.32, -0.45), Vector3(0.0, 0.4, -0.6), Vector3(-0.2, 0.95, -0.5), Vector3(0.35, 1.25, -0.55)]
	for i in PIECES:  # the top ones go first (the list is knocked off from its end)
		var mi := MeshInstance3D.new(); add_child(mi); mi.position = at[i]
		mi.rotation = Vector3(randf_range(-0.3, 0.3), randf_range(0, TAU), randf_range(-0.3, 0.3))
		var bm := BoxMesh.new(); bm.size = Vector3(0.9, 0.7, 0.8) * (1.0 - 0.12 * i); bm.material = rock; mi.mesh = bm
		pieces.append(mi)


func _cane() -> void:  # bundles of dry cane, tied in the middle, standing and leaning against the door, two rows
	var straw := StandardMaterial3D.new(); straw.albedo_color = Color(0.62, 0.55, 0.36); straw.roughness = 1.0
	var tie := StandardMaterial3D.new(); tie.albedo_color = Color(0.3, 0.22, 0.14)
	for i in PIECES:  # the front ones go first (knocked off from the end of the list)
		var p := Node3D.new(); add_child(p)
		var row := 0 if i < 3 else 1
		p.position = Vector3(-0.75 + 0.75 * (i % 3) + (0.35 if row == 1 else 0.0), 0.0, -0.75 + 0.45 * row)
		p.rotation = Vector3(-0.12 - 0.08 * row, randf_range(-0.4, 0.4), randf_range(-0.08, 0.08))
		for s in 7:  # the canes of one bundle
			var c := MeshInstance3D.new(); p.add_child(c)
			var cm := CylinderMesh.new(); cm.top_radius = 0.022; cm.bottom_radius = 0.026; cm.height = 1.75; cm.radial_segments = 5
			cm.material = straw; c.mesh = cm
			var a := s * TAU / 7.0
			c.position = Vector3(cos(a) * 0.09, 0.875, sin(a) * 0.09); c.rotation = Vector3(randf_range(-0.04, 0.04), 0, randf_range(-0.04, 0.04))
		var band := MeshInstance3D.new(); p.add_child(band)
		var bm := CylinderMesh.new(); bm.top_radius = 0.13; bm.bottom_radius = 0.13; bm.height = 0.06; bm.material = tie; band.mesh = bm
		band.position.y = 0.9
		pieces.append(p)


func _thicket() -> void:  # clumps of taquara, dry leaves at their tops, vine across them
	var cane := StandardMaterial3D.new(); cane.albedo_color = Color(0.5, 0.48, 0.3); cane.roughness = 1.0
	var leaf := StandardMaterial3D.new(); leaf.albedo_color = Color(0.42, 0.36, 0.2); leaf.roughness = 1.0
	for i in PIECES:  # the front clumps go first
		var p := Node3D.new(); add_child(p)
		p.position = Vector3(-0.8 + 0.4 * i, 0.0, -0.25 - 0.55 * float(i % 2)) if i < 4 else Vector3(0.0, 0.0, -0.75)
		for k in 6:
			var c := MeshInstance3D.new(); p.add_child(c)
			var cm := CylinderMesh.new(); var h := randf_range(1.4, 2.0); cm.top_radius = 0.018; cm.bottom_radius = 0.03; cm.height = h
			cm.radial_segments = 5; cm.material = cane; c.mesh = cm
			c.position = Vector3(randf_range(-0.22, 0.22), h / 2, randf_range(-0.2, 0.2)); c.rotation = Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15))
			var top := MeshInstance3D.new(); c.add_child(top); var tm := BoxMesh.new(); tm.size = Vector3(0.3, 0.25, 0.08); tm.material = leaf
			top.mesh = tm; top.position.y = h / 2 - 0.1; top.rotation.y = randf() * TAU
		pieces.append(p)


func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player and not pieces.is_empty():  # with the tool already in hand there is nothing to take: no prompt
		enabled = not (player.mode == Player.Mode.COMBAT and player.held == tool)


func _use(by: Node3D) -> void:
	if by is Player:
		by.equip(Player.Mode.COMBAT, tool)
		by.notice.emit(KINDS[kind].how)


func take_hit(n: int, by := "") -> void:
	var k: Dictionary = KINDS[kind]
	if by != tool:
		Audio.play2d(self, k.miss, -4.0)
		if player:
			player.notice.emit(k.wrong)
		return
	Audio.play2d(self, k.hit, -2.0).pitch_scale = randf_range(0.92, 1.08)
	for i in mini(n, pieces.size()):
		var s: Node3D = pieces.pop_back()
		var tw := create_tween().set_parallel()  # it falls off the heap and lies there
		tw.tween_property(s, "position", s.position + Vector3(randf_range(-0.8, 0.8), -s.position.y + 0.15, randf_range(0.5, 1.0)), 0.45)
		tw.tween_property(s, "rotation", s.rotation + Vector3(randf_range(-2, 2) if kind == "entulho" else -1.45, 0, randf_range(-2, 2) if kind != "mato" else 0.0), 0.45)
		if kind == "entulho":
			tw.tween_property(s, "scale", Vector3.ONE * 0.45, 0.45)
	if pieces.is_empty():
		Audio.play2d(self, k.done, -2.0)
		body.queue_free(); remove_from_group("breakable"); enabled = false
		Story.mark("quebrado:" + id)
		if player:
			player.notice.emit("O caminho está livre.")
		broken.emit()

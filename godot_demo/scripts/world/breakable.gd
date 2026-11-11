# A heap of fallen stone across the way, broken with the pickaxe: each blow knocks stones off it (a slash one, the
# overhead two, Player.HIT_DAMAGE) until none is left and the way is open (Story "quebrado:<id>"). Any other blow
# only rings off it. E near it with the pickaxe in the inventory puts it in his hand (requires "picareta").
# Its origin: the foot of its front face (where you come from, +z), the heap behind it. Hit like an enemy: the group
# "breakable" and take_hit(n, by).
class_name Breakable
extends Interactable

const SIZE := Vector3(2.2, 1.6, 1.0)
const STONES := 5

var id := ""
var stones: Array[Node3D] = []
var body: StaticBody3D
var player: Player


static func make(level: Node, at: Vector3, yaw: float, rubble_id: String) -> Breakable:
	var b := Breakable.new(); b.id = rubble_id; b.position = at; b.rotation.y = yaw
	b.requires = "picareta"; b.prompt = "E · pegar a picareta"; b.refusal = "Pedra demais para tirar com as mãos."
	b.radius = 1.6; b.height = 2.0
	level.add_child(b)
	return b


func _ready() -> void:
	if Story.has("quebrado:" + id):
		queue_free()
		return
	super()
	add_to_group("breakable")
	body = StaticBody3D.new(); add_child(body)  # one block for the whole heap, until the last stone goes
	var cs := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = SIZE; cs.shape = box
	cs.position = Vector3(0, SIZE.y / 2, -SIZE.z / 2); body.add_child(cs)
	var rock := Looks.triplanar("stone", 1.2, Color(0.62, 0.6, 0.56))
	var at := [Vector3(-0.6, 0.35, -0.35), Vector3(0.55, 0.32, -0.45), Vector3(0.0, 0.4, -0.6), Vector3(-0.2, 0.95, -0.5), Vector3(0.35, 1.25, -0.55)]
	for i in STONES:  # the top ones go first (the list is knocked off from its end)
		var mi := MeshInstance3D.new(); add_child(mi); mi.position = at[i]
		mi.rotation = Vector3(randf_range(-0.3, 0.3), randf_range(0, TAU), randf_range(-0.3, 0.3))
		var bm := BoxMesh.new(); bm.size = Vector3(0.9, 0.7, 0.8) * (1.0 - 0.12 * i); bm.material = rock; mi.mesh = bm
		stones.append(mi)


func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player and not stones.is_empty():  # with the pickaxe already in hand there is nothing to take: no prompt
		enabled = not (player.mode == Player.Mode.COMBAT and player.held == "picareta")


func _use(by: Node3D) -> void:
	if by is Player:
		by.equip(Player.Mode.COMBAT, "picareta")
		by.notice.emit("Golpeie a pedra com a picareta (botão esquerdo).")


func take_hit(n: int, by := "") -> void:
	if by != "picareta":
		Audio.play2d(self, "bloqueio", -4.0)
		if player:
			player.notice.emit("A lâmina só lasca a pedra.")
		return
	Audio.play2d(self, "bloqueio", -2.0).pitch_scale = randf_range(0.55, 0.65)  # iron on stone
	for k in mini(n, stones.size()):
		var s: Node3D = stones.pop_back()
		var tw := create_tween().set_parallel()  # it rolls off the heap and lies there
		tw.tween_property(s, "position", s.position + Vector3(randf_range(-0.8, 0.8), -s.position.y + 0.2, randf_range(0.5, 1.0)), 0.45)
		tw.tween_property(s, "rotation", s.rotation + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)), 0.45)
		tw.tween_property(s, "scale", Vector3.ONE * 0.45, 0.45)
	if stones.is_empty():
		Audio.play2d(self, "pedra_arrastar", -2.0)
		body.queue_free(); remove_from_group("breakable"); enabled = false
		Story.mark("quebrado:" + id)
		if player:
			player.notice.emit("O caminho está livre.")

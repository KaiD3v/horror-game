# A trunk (ChestData, models/props/bau.glb), opened as in the old adventure games: no menu. E and he puts away what
# he holds, steps up to it and goes down on one knee (Open_Chest); the lid comes up in his hand and falls back, a warm
# light comes from inside, he takes what lies there and holds it up before his face. The world holds its breath (the
# enemies stop) while its name shows at the bottom of the screen; E again and he tucks it into his coat
# (Stow_Item) and stands up. It goes into the Inventory as the name shows, and the trunk stays open for good
# (`opened`, until a new game). A trunk that needs a key: `requires` (Interactable).
class_name Chest
extends Interactable

signal found(item: String)

const FRONT := 0.64           # m from its centre to where he kneels (= the rig's CHEST_FRONT + half its depth)
const LID := {14: 0.0, 22: 55.0, 26: 75.0, 32: 108.0, 36: 100.0, 40: 104.0}  # Open_Chest frame -> degrees (rig CHEST_LID)
const TAKE := 36              # Open_Chest frame: the thing comes into his hand
const HOLD := 61              # ...frame where the clip is held while the name shows
const TUCK := 9               # Stow_Item frame: into the coat
const VIEW := -1.7          # the camera's turn round him while he opens it (rad; 0 = behind him, - = his left, the hand that takes it)

static var opened: Array[String] = []   # ids, until a new game

var id := ""
var item := ""
var qtd := 1
var model: Node3D
var lid: Node3D
var glow: OmniLight3D
var busy := false


static func reset() -> void:
	opened.clear()


static func make(level: Level, c: Dictionary) -> Chest:
	var ch := Chest.new(); ch.id = c.id; ch.item = c.item; ch.qtd = c.get("qtd", 1)
	ch.requires = c.get("requires", ""); ch.refusal = c.get("refusal", "")
	ch.prompt = "E · abrir o baú"; ch.radius = 1.3
	level.add_child(ch)
	var hit := level.ray(c.at.x, c.at.y, c.get("from", 30.0))
	ch.global_position = hit.position if hit else Vector3(c.at.x, 0, c.at.y)
	ch.rotation.y = deg_to_rad(c.yaw)
	return ch


func _ready() -> void:
	super()
	model = load(Paths.PROP % "bau").instantiate(); add_child(model)
	lid = model.find_child("tampa")
	var body := StaticBody3D.new(); add_child(body)
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(0.82, 0.55, 0.48)
	shape.shape = box; shape.position.y = 0.275; body.add_child(shape)
	glow = OmniLight3D.new(); add_child(glow); glow.position = Vector3(0, 0.3, 0)
	glow.light_color = Color(1.0, 0.72, 0.4); glow.light_energy = 0.0; glow.omni_range = 2.2
	if id in opened:  # found before: open and empty
		lid.rotation.x = -deg_to_rad(LID[40]); enabled = false


func _use(by: Node3D) -> void:
	if busy or not by is Player:
		return
	_open(by)


func _open(p: Player) -> void:
	busy = true; enabled = false; p.busy = true; p.cam_override = Player.CAM_KNEEL
	await p.free_hands()
	var held: Array = get_tree().get_nodes_in_group("enemy").filter(func(e): return e is Enemy and e.active)
	for e in held:
		e.active = false
	# up to it, facing it; the camera comes round to his front
	var spot := global_position + global_basis.z * FRONT; spot.y = p.global_position.y
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tw.tween_property(p, "global_position", spot, 0.25)
	tw.tween_property(p, "rotation:y", p.rotation.y + angle_difference(p.rotation.y, rotation.y), 0.25)
	tw.tween_property(p.pivot, "rotation:y", p.pivot.rotation.y + angle_difference(p.pivot.rotation.y, rotation.y + VIEW), 0.6)
	tw.tween_property(p.pitch, "rotation:x", -0.2, 0.6)
	await tw.finished
	p.velocity = Vector3.ZERO
	p.play("Open_Chest")
	var lt := create_tween()  # the lid, in step with his hand
	var last := 0
	for f in LID:
		lt.tween_property(lid, "rotation:x", -deg_to_rad(LID[f]), (f - last) / 30.0); last = f
	create_tween().tween_property(glow, "light_energy", 1.4, 0.6).set_delay(22 / 30.0)  # light from inside as it opens
	_at(14, func(): Audio.play3d(self, "bau_abrir", Vector3(0, 0.5, 0), -2.0, false, 3.0, 20.0))
	await _frame(p, TAKE)
	var thing := _in_hand(p)
	await _frame(p, HOLD)
	p.tree.active = false  # held there while the name shows
	Inventory.add(item, qtd); opened.append(id)
	found.emit(item)
	Audio.play2d(self, "bau_achado", -3.0)
	await FoundBanner.open(self, item, qtd)
	p.tree.active = true
	p.play("Stow_Item")
	create_tween().tween_property(glow, "light_energy", 0.0, 1.0)
	await _frame(p, TUCK)
	thing.queue_free()
	while p.action == "Stow_Item":
		await get_tree().process_frame
	for e in held:
		if is_instance_valid(e):
			e.active = true
	p.busy = false; p.cam_override = {}; busy = false


## Waits until the player's one-shot reaches frame f (30 fps).
func _frame(p: Player, f: int) -> void:
	while p.action != "" and p.action_t < (f - 1) / 30.0:
		await get_tree().process_frame


func _at(f: int, fn: Callable) -> void:
	get_tree().create_timer((f - 1) / 30.0).timeout.connect(fn)


func _in_hand(p: Player) -> Node3D:  # the thing itself, held up (Player.hold_item)
	return p.hold_item(item)

# The game's opening (../docs/INTRODUCAO.md), played once at the start of a new game in the village: the two letters
# that brought him (NotesData obito, carta_mae), the truck that leaves him at the fallen bridge, the sawn beams, the
# crossing of the ravine and the beam that gives way behind him, the barricade, the village and the Colônia's light;
# then the game, with the task "Subir à Colônia". Holding E or Esc for a second skips to that same end.
# The menu's "Novo jogo" sets `pending`; vilarejo.gd plays it (run). Each shot is a plain function, in order.
class_name Intro
extends CanvasLayer

signal finished

static var pending := false   # a new game asked for it (Story "intro:vista" once seen)

const LETTERS := ["obito", "carta_mae"]
const HOLD := 1.0             # s held to skip
const BEAM_TOP := Vector2(-2.6, 47.4)   # the loose beam (vilarejo GLB ponte_viga_solta: narrativa.loose_beam), x, z
const BEAM_FOOT := Vector2(-2.6, 50.3)
const BAR := 0.12             # letterbox, a fraction of the screen's height

var L                         # the village (vilarejo.gd)
var player: Player
var cam: Camera3D
var black: ColorRect
var caption: Label
var title: Label
var hint: Label
var fill: ColorRect
var lights: Node3D            # the truck's headlights
var held := 0.0
var skipped := false
var done := false
var shot := 0                 # the shot on screen (1..9; the test reads it)
var tweens: Array[Tween] = []


func _init(level: Node) -> void:
	L = level; player = level.player
	layer = 4; process_mode = Node.PROCESS_MODE_ALWAYS  # under the notes' page (5); skipping works while a letter is up


func _ready() -> void:  # (anchored, so it fits whatever size the window is; anchors set before add_child)
	for top in [true, false]:
		var bar := ColorRect.new(); bar.color = Color.BLACK
		bar.anchor_right = 1.0; bar.anchor_top = 0.0 if top else 1.0 - BAR; bar.anchor_bottom = BAR if top else 1.0
		add_child(bar)
	black = ColorRect.new(); black.color = Color.BLACK; black.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(black)
	caption = _label(1.0 - BAR - 0.09, 18)
	title = _label(0.38, 54); title.modulate.a = 0.0
	hint = Label.new(); hint.text = "segure E para pular"; hint.add_theme_font_size_override("font_size", 12)
	hint.anchor_left = 1.0; hint.anchor_right = 1.0; hint.anchor_top = 1.0; hint.anchor_bottom = 1.0
	hint.offset_left = -190; hint.offset_top = -24; hint.modulate = Color(0.75, 0.72, 0.66, 0.6); add_child(hint)
	fill = ColorRect.new(); fill.color = Color(0.85, 0.66, 0.36)
	fill.anchor_left = 1.0; fill.anchor_right = 1.0; fill.anchor_top = 1.0; fill.anchor_bottom = 1.0
	fill.offset_left = -190; fill.offset_right = -190; fill.offset_top = -6; fill.offset_bottom = -4; add_child(fill)
	cam = Camera3D.new(); cam.fov = 50.0; L.add_child(cam)


func _label(at: float, size: int) -> Label:  # a centred line across the screen, `at` a fraction of its height
	var l := Label.new(); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.anchor_right = 1.0; l.anchor_top = at; l.anchor_bottom = at; l.offset_bottom = size + 20
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	add_child(l)
	return l


func _process(delta: float) -> void:
	if done:
		return
	held = held + delta if Input.is_action_pressed("interact") or Input.is_action_pressed("ui_cancel") else 0.0
	fill.offset_right = fill.offset_left + 180.0 * minf(held / HOLD, 1.0)
	if held >= HOLD and not skipped:
		skipped = true


## The whole of it: the shots in order, then the game. Skipping cuts to the same end.
func run() -> void:
	pending = false
	player.busy = true; L.hud.visible = false; L.menu.set_process_unhandled_input(false)
	cam.make_current()
	for s in [_dated, _letters, _truck, _sawn, _crossing, _gave_way, _barricade, _village, _handover]:
		if skipped:
			break
		shot += 1
		await s.call()
	_finish()


# --- the shots ----------------------------------------------------------------------------------------------------
func _dated() -> void:  # 1. black, the place and the date
	_put(L.ground(0.4, 62.0), PI)  # (off screen: on the road south of the ravine, looking back at the truck)
	caption.text = "Serra de Santa Clara · março de 1974"
	await _wait(4.0)
	caption.text = ""


func _letters() -> void:  # 2. what brought him: the 1959 notice of her death, and her letter of 1974
	for id in LETTERS:
		if skipped:
			return
		Audio.play2d(self, "papel_desdobrar", -4.0)
		L.notes.take(id)
		while L.notes.showing >= 0 and not skipped:  # read at his pace (E closes it); skipping leaves it to _finish
			await get_tree().process_frame


func _truck() -> void:  # 3. dawn on the road; the lorry that brought him backs away into the fog
	var g: Vector3 = player.global_position
	lights = Node3D.new(); L.add_child(lights); lights.position = Vector3(0.3, g.y + 1.0, 68.0)
	for sx in [-0.8, 0.8]:
		var s := SpotLight3D.new(); lights.add_child(s); s.position.x = sx; s.light_color = Color(1.0, 0.85, 0.6)
		s.light_energy = 6.0; s.spot_range = 30.0; s.spot_angle = 28.0; s.rotation.y = 0.0  # pointing north, -z
		var lamp := OmniLight3D.new(); lights.add_child(lamp); lamp.position = Vector3(sx, 0, -0.2)
		lamp.light_color = s.light_color; lamp.light_energy = 1.5; lamp.omni_range = 1.5
	_look(Vector3(2.2, g.y + 1.5, 59.0), g + Vector3(0, 1.3, 2.0))
	Audio.play3d(lights, "caminhao_partindo", Vector3.ZERO, 4.0, false, 6.0, 120.0)
	_tw().tween_property(black, "color:a", 0.0, 2.0)
	await _wait(1.5)
	caption.text = "— Daqui o senhor vai a pé. Ninguém sobe pra Santa Clara."
	await _wait(3.5)
	caption.text = ""
	var t := _tw().set_parallel()
	t.tween_property(lights, "position:z", 95.0, 5.0).set_ease(Tween.EASE_IN)
	for l in lights.get_children():
		if l is Light3D:
			t.tween_property(l, "light_energy", 0.0, 5.0)
	await _wait(2.0)
	_tw().tween_property(player, "rotation:y", 0.0, 1.2)  # he turns to the road ahead
	await _wait(2.0)


func _sawn() -> void:  # 4. to the brink: the bridge is down, its beams sawn through
	var g: Vector3 = player.global_position
	_look(Vector3(-3.6, g.y + 1.5, 56.6), Vector3(-0.4, g.y + 1.0, 60.5))  # from the brink, him coming to it
	await _walk(Vector3(-1.1, 0, 56.7))  # to the brink over the abutment (the ravine drops from z = 56.1)
	await _wait(0.6)
	var stub: Vector3 = L.marker("intro_serrado").global_position  # a stub on the south abutment, its cut face north
	var spill := OmniLight3D.new(); L.add_child(spill); spill.global_position = stub + Vector3(0.1, 0.5, -0.4)  # (the lantern's, helped)
	spill.light_color = Color(1.0, 0.7, 0.4); spill.light_energy = 1.2; spill.omni_range = 2.0
	_look(stub + Vector3(0.6, 0.25, -1.0), stub)
	await _wait(3.5)
	spill.queue_free()


func _crossing() -> void:  # 5. down into the ravine, through the water, up the beam on the far side
	var brink: Vector3 = L.ground(-2.6, 56.4)
	_put(brink, PI)  # his back to the drop
	_look(brink + Vector3(-4.2, 0.6, -1.0), brink + Vector3(0, -0.4, -0.6))
	player.play("Climb_Ledge", true)
	_tw().tween_property(player, "global_position", brink + Vector3(0, -1.25, -0.4), player.action_len)
	await _wait(player.action_len + 0.3)
	await _cut()
	var bottom: Vector3 = L.ground(-2.4, 53.0)
	_put(bottom, 0.0)
	_look(bottom + Vector3(3.0, 1.2, -1.5), bottom + Vector3(-0.3, 0.8, -2.5))
	await _walk(Vector3(-2.6, 0, 50.9))
	for i in 2:  # onto the beam
		player.play("Climb_Step")
		_tw().tween_property(player, "global_position", player.global_position + Vector3(0, 0.5, -0.2), player.action_len)
		await _wait(player.action_len)
	await _cut()
	var top: Vector3 = L.ground(-2.6, 46.75)
	_put(top - Vector3(0, 1.25, -0.35), 0.0)
	_look(top + Vector3(1.8, 0.4, 2.6), top + Vector3(0, 0.2, 0))
	player.play("Climb_Ledge")
	_tw().tween_property(player, "global_position", top, player.action_len).set_trans(Tween.TRANS_SINE)
	await _wait(player.action_len + 0.2)


func _gave_way() -> void:  # 6. the beam gives way behind him: no way back
	var beam: Node3D = L.marker("ponte_viga_solta")
	Audio.play3d(beam, "viga_cedendo", Vector3(0, -2, 1), 4.0, false, 4.0, 60.0)
	var p := player.global_position  # from down in the ravine, looking up: him on the brink, the beam leaning below him
	_look(p + Vector3(-1.8, -1.7, 3.5), p + Vector3(0, 0.9, 0))
	await _wait(0.7)
	var to: Transform3D = fallen(L)
	var t := _tw().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(beam, "global_position", to.origin, 1.1)
	t.tween_property(beam, "quaternion", to.basis.get_rotation_quaternion(), 1.1)
	await _wait(1.2)
	_tw().tween_property(player, "rotation:y", PI, 0.8)  # he looks back at it
	await _wait(2.4)
	_tw().tween_property(player, "rotation:y", 0.0, 0.8)
	await _wait(1.0)


func _barricade() -> void:  # 7. past the villagers' barricade, a PROCURA-SE nailed to it
	var g: Vector3 = L.ground(-0.3, 45.6)
	_put(g, 0.0)
	_look(Vector3(1.6, g.y + 1.5, 42.0), Vector3(-0.5, g.y + 0.9, 46.3))
	await _walk(Vector3(0.0, 0, 43.4))
	await _wait(0.8)


func _village() -> void:  # 8. up behind him: the roofs in the fog, the Colônia's light; the bell; the title
	var p: Vector3 = player.global_position
	_look(p + Vector3(0.0, 1.8, 1.6), p + Vector3(0, 1.6, -6.0))
	var t := _tw().set_parallel().set_trans(Tween.TRANS_SINE)
	t.tween_property(cam, "global_position", p + Vector3(0, 7.0, 3.5), 6.0)
	t.tween_method(func(k: float): cam.look_at(p + Vector3(0, 1.6 + 8.0 * k, -6.0 - 40.0 * k)), 0.0, 1.0, 6.0)
	await _wait(2.5)
	Audio.play2d(self, "sino", -8.0)
	title.text = "SANTA CLARA"
	_tw().tween_property(title, "modulate:a", 1.0, 1.5)
	await _wait(4.5)
	_tw().tween_property(title, "modulate:a", 0.0, 1.2)
	await _wait(1.3)


func _handover() -> void:  # 9. down to where the game's camera sits
	var at: Transform3D = L._player_start()
	_put(at.origin - Vector3(0, 0.3, 0), at.basis.get_euler().y)
	player.pivot.rotation.y = player.rotation.y
	await _wait(0.1)
	var t := _tw().set_parallel().set_trans(Tween.TRANS_SINE)
	t.tween_property(cam, "global_transform", player.cam.global_transform, 1.5)
	await _wait(1.6)


# --- the end, played or skipped -----------------------------------------------------------------------------------
func _finish() -> void:
	done = true
	for t in tweens:
		if t.is_valid():
			t.kill()
	if L.notes.showing >= 0:
		L.notes.close()
	if is_instance_valid(lights):
		lights.queue_free()
	for id in LETTERS:
		if id not in NotesReader.read:
			NotesReader.read.append(id)
	var beam: Node3D = L.marker("ponte_viga_solta"); beam.global_transform = fallen(L)
	var at: Transform3D = L._player_start()
	player.walk_to = Vector3.INF; player.velocity = Vector3.ZERO; player.stop_action()
	player.global_transform = at; player.pivot.rotation.y = at.basis.get_euler().y
	player.busy = false
	player.cam.make_current(); cam.queue_free()
	L.hud.visible = true; L.menu.set_process_unhandled_input(true)
	Story.mark("intro:vista")
	Story.set_task("colonia", "ativa")
	player.notice.emit("Nova tarefa: %s" % QuestData.title("colonia"))
	finished.emit()
	queue_free()


## Where the loose beam lies once it has fallen: along the bottom of the ravine, westwards, half in the water.
## (Its origin is its top end; standing, it leans from the north brink down to the water: narrativa.loose_beam.)
static func fallen(level: Node) -> Transform3D:
	var top: Vector3 = level.ground(BEAM_TOP.x, BEAM_TOP.y) - Vector3(0, 0.15, 0)
	var foot: Vector3 = level.ground(BEAM_FOOT.x, BEAM_FOOT.y) + Vector3(0, 0.1, 0)
	var q := Quaternion((foot - top).normalized(), Vector3(-1.0, 0.06, 0.15).normalized())
	return Transform3D(Basis(q), level.ground(-2.4, 51.2) + Vector3(0, 0.12, 0))


# --- helpers ------------------------------------------------------------------------------------------------------
func _tw() -> Tween:
	var t := create_tween(); tweens.append(t)
	return t


## Wait s seconds of game time, or less if skipped.
func _wait(s: float) -> void:
	var t := 0.0
	while t < s and not skipped:
		await get_tree().process_frame
		t += get_process_delta_time()


func _cut() -> void:  # a short dip to black between two shots
	black.color.a = 1.0
	await _wait(0.5)
	_tw().tween_property(black, "color:a", 0.0, 0.5)


func _put(at: Vector3, yaw: float) -> void:
	player.global_position = at + Vector3(0, 0.05, 0); player.rotation.y = yaw; player.velocity = Vector3.ZERO
	player.pivot.global_position = at + Vector3(0, 1.55, 0); player.coat.reset()


func _look(from: Vector3, at: Vector3) -> void:
	cam.global_position = from; cam.look_at(at)


## Walk him to `to` (x, z; at walk pace, the usual steps); back when there, or after 12 s, or skipped.
func _walk(to: Vector3) -> void:
	player.walk_to = Vector3(to.x, player.global_position.y, to.z)
	var t := 0.0
	while not skipped and t < 12.0 and Vector2(player.global_position.x - to.x, player.global_position.z - to.z).length() > 0.25:
		await get_tree().process_frame
		t += get_process_delta_time()
	player.walk_to = Vector3.INF

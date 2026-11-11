# A cutscene's frame and timing (Abertura, Intro): letterbox bars, a caption line, a title, a black to fade through,
# its own camera, and holding E (or Esc) for a second to skip. The shots are plain functions that play() runs in
# order; each waits with wait(), cut short once skipped, so a skip runs straight on to the end it shares with playing.
class_name Cutscene
extends CanvasLayer

const HOLD := 1.0             # s held to skip
const BAR := 0.12             # letterbox, a fraction of the screen's height

var world: Node3D             # where its camera lives
var cam: Camera3D
var black: ColorRect
var caption: Label
var title: Label
var fill: ColorRect
var held := 0.0
var skipped := false
var done := false
var shot := 0                 # the shot on screen, from 1 (the tests read it)
var tweens: Array[Tween] = []
var moving: Tween             # the camera's own move (cam_tw); a cut (look) stops it


func _init(where: Node3D) -> void:
	world = where
	layer = 4; process_mode = Node.PROCESS_MODE_ALWAYS  # under the notes' page (5); skipping works while a page is up


func _ready() -> void:  # (anchored, so it fits whatever size the window is; anchors set before add_child)
	for top in [true, false]:
		var bar := ColorRect.new(); bar.color = Color.BLACK
		bar.anchor_right = 1.0; bar.anchor_top = 0.0 if top else 1.0 - BAR; bar.anchor_bottom = BAR if top else 1.0
		add_child(bar)
	black = ColorRect.new(); black.color = Color.BLACK; black.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(black)
	caption = _label(1.0 - BAR - 0.09, 18)
	title = _label(0.38, 54); title.modulate.a = 0.0
	var hint := Label.new(); hint.text = "segure E para pular"; hint.add_theme_font_size_override("font_size", 12)
	hint.anchor_left = 1.0; hint.anchor_right = 1.0; hint.anchor_top = 1.0; hint.anchor_bottom = 1.0
	hint.offset_left = -190; hint.offset_top = -24; hint.modulate = Color(0.75, 0.72, 0.66, 0.6); add_child(hint)
	fill = ColorRect.new(); fill.color = Color(0.85, 0.66, 0.36)
	fill.anchor_left = 1.0; fill.anchor_right = 1.0; fill.anchor_top = 1.0; fill.anchor_bottom = 1.0
	fill.offset_left = -190; fill.offset_right = -190; fill.offset_top = -6; fill.offset_bottom = -4; add_child(fill)
	cam = Camera3D.new(); cam.fov = 50.0; world.add_child(cam)


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
	if held >= HOLD:
		skipped = true


## The shots in order (each a Callable that awaits), until the last or a skip; then every tween stops.
func play(shots: Array) -> void:
	cam.make_current()
	for s in shots:
		if skipped:
			break
		shot += 1
		await s.call()
	done = true
	for t in tweens:
		if t.is_valid():
			t.kill()


func tw() -> Tween:
	var t := create_tween(); tweens.append(t)
	return t


## A tween for moving the camera, the only one: the next cut (look) or move stops it.
func cam_tw() -> Tween:
	if moving and moving.is_valid():
		moving.kill()
	moving = tw()
	return moving


## Wait s seconds, or less if skipped.
func wait(s: float) -> void:
	var t := 0.0
	while t < s and not skipped:
		await get_tree().process_frame
		t += get_process_delta_time()


func cut() -> void:  # a short dip to black between two shots
	black.color.a = 1.0
	await wait(0.5)
	tw().tween_property(black, "color:a", 0.0, 0.5)


func fade(to: float, s: float) -> void:  # the black over everything to `to` (1 = all black)
	tw().tween_property(black, "color:a", to, s)


func look(from: Vector3, at: Vector3) -> void:  # a cut: the camera there, looking at `at`
	if moving and moving.is_valid():
		moving.kill()
	cam.global_position = from; cam.look_at(at)


func say(t: String) -> void:
	caption.text = t

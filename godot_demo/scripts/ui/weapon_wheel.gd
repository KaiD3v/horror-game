# Q: the weapon wheel. Held, time slows and a ring opens around the screen's centre with what he can hold
# (WHEEL): the mouse (or WASD) points at one, letting go of Q puts it in his hands (Player.equip: whatever he
# holds goes away first). A quick tap skips the ring: crossbow out, or back to the lantern.
class_name WeaponWheel
extends CanvasLayer

const WHEEL := [  # clockwise from the top
	{"mode": Player.Mode.EXPLORE, "nome": "Lamparina", "nota": "mãos livres"},
	{"mode": Player.Mode.COMBAT, "nome": "Facão", "nota": "corpo a corpo"},
	{"mode": Player.Mode.XBOW, "nome": "Besta", "nota": "virotes %d"},
]
const HOLD := 0.18         # s of Q held before the ring opens (shorter = a tap)
const SLOW := 0.25         # time scale while it is open
const OUTER := 150.0       # ring radii, px
const INNER := 62.0
const GAP := 0.06          # rad between slices
const DEADZONE := 28.0     # px of mouse travel before a slice is pointed at
const BASE := Color(0.07, 0.06, 0.05, 0.78)
const PICKED := Color(0.42, 0.11, 0.06, 0.9)   # the shop's red
const EDGE := Color(0.75, 0.72, 0.66)
const HELD := Color(0.86, 0.62, 0.3)           # what is in his hands now (the lantern's amber)

var player: Player
var open := false
var picked := -1           # slice pointed at, -1 = none
var aim := Vector2.ZERO    # mouse travel since it opened, px
var _down_at := -1         # ms Q went down, -1 = up
var ring: Control
var names: Array[Label] = []
var notes: Array[Label] = []
var centre: Label


func _init(p: Player) -> void:
	player = p


func _ready() -> void:
	layer = 4; process_mode = Node.PROCESS_MODE_ALWAYS  # sees the pause, to step aside for the notes / shop
	ring = Control.new(); add_child(ring); ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.draw.connect(_draw_ring)
	for i in WHEEL.size():
		var at := slice_dir(i) * (OUTER + INNER) / 2
		names.append(_label(at + Vector2(0, -10), 24)); names[i].text = WHEEL[i].nome
		notes.append(_label(at + Vector2(0, 14), 12))
	centre = _label(Vector2.ZERO, 12)
	ring.visible = false


func _label(at: Vector2, size: int) -> Label:  # centred on `at`, relative to the screen's centre
	var l := Label.new(); ring.add_child(l); l.size = Vector2(160, 24)
	l.position = ring.get_viewport_rect().size / 2 + at - l.size / 2
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", EDGE)
	return l


static func slice_dir(i: int) -> Vector2:
	var a := -PI / 2 + i * TAU / WHEEL.size()
	return Vector2(cos(a), sin(a))


## Which slice a direction on screen points at (+y = down), -1 when it is too short.
static func slice_at(v: Vector2) -> int:
	if v.length() < DEADZONE:
		return -1
	return wrapi(roundi((v.angle() + PI / 2) / (TAU / WHEEL.size())), 0, WHEEL.size())


func _process(_delta: float) -> void:
	if get_tree().paused or player.mode == Player.Mode.DEAD:
		_close(false); _down_at = -1
		return
	var q := Input.is_action_pressed("weapons")
	if q and _down_at < 0:
		_down_at = Time.get_ticks_msec()  # real time: the ring slows the game's
	elif q and not open and Time.get_ticks_msec() - _down_at >= HOLD * 1000.0:
		_open()
	elif not q and _down_at >= 0:
		_down_at = -1
		if open:
			_close(true)
		else:  # a tap: the old Q
			player.equip(Player.Mode.EXPLORE if player.mode == Player.Mode.XBOW else Player.Mode.XBOW)
	if open:
		var keys := Input.get_vector("left", "right", "forward", "back")
		if keys.length() > 0.5:
			aim = keys * OUTER
		_point(slice_at(aim))


func _input(e: InputEvent) -> void:  # open: the mouse steers the ring, not the camera or the machete
	if not open:
		return
	if e is InputEventMouseMotion:
		aim = (aim + e.relative).limit_length(OUTER)
	elif not e is InputEventMouseButton:
		return
	get_viewport().set_input_as_handled()


func _open() -> void:
	open = true; aim = Vector2.ZERO; picked = -1
	Engine.time_scale = SLOW
	for i in WHEEL.size():
		notes[i].text = WHEEL[i].nota % Inventory.count("virote") if "%d" in WHEEL[i].nota else WHEEL[i].nota
	ring.visible = true; _point(-1)


func _close(choose: bool) -> void:
	if not open:
		return
	open = false; ring.visible = false
	Engine.time_scale = 1.0
	if choose and picked >= 0:
		player.equip(WHEEL[picked].mode)


func _point(i: int) -> void:
	picked = i
	for k in WHEEL.size():
		names[k].add_theme_color_override("font_color", HELD if WHEEL[k].mode == _holding() else EDGE)
	centre.text = WHEEL[i].nome if i >= 0 else "Q soltar"
	ring.queue_redraw()


func _holding() -> int:  # crouched = hands as when exploring
	return Player.Mode.EXPLORE if player.mode == Player.Mode.CROUCH else player.mode


func _exit_tree() -> void:  # never leave the next scene in slow motion
	Engine.time_scale = 1.0


func _draw_ring() -> void:  # flat slices, no smoothing: the game's low-res look
	var c := ring.get_viewport_rect().size / 2
	var step := TAU / WHEEL.size()
	for i in WHEEL.size():
		var mid := -PI / 2 + i * step
		var pts := PackedVector2Array()
		for k in 17:  # outer arc out, inner arc back
			pts.append(c + Vector2.from_angle(mid - step / 2 + GAP + (step - 2 * GAP) * k / 16.0) * OUTER)
		for k in 17:
			pts.append(c + Vector2.from_angle(mid + step / 2 - GAP - (step - 2 * GAP) * k / 16.0) * INNER)
		ring.draw_colored_polygon(pts, PICKED if i == picked else BASE)
		pts.append(pts[0])
		ring.draw_polyline(pts, HELD if WHEEL[i].mode == _holding() else EDGE.darkened(0.4), 2.0)
	ring.draw_circle(c, INNER - 10, BASE)
	if aim.length() >= DEADZONE:  # where the mouse points, on the inner rim
		ring.draw_rect(Rect2(c + aim.normalized() * (INNER - 18) - Vector2(3, 3), Vector2(6, 6)), EDGE)

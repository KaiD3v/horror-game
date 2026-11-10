# Q: the weapon wheel. Held, time slows and a wooden rosary opens around the screen's centre with a little tablet
# per weapon on it (WHEEL), its picture burnt in like an ex-voto (art: ../tools/texturas/roda_armas.py, at 2x).
# The mouse (or WASD) points at one, and candlelight comes up behind it; letting go of Q puts it in his hands
# (Player.equip: whatever he holds goes away first). A red ribbon is tied on the one he holds now.
class_name WeaponWheel
extends CanvasLayer

const WHEEL := [  # clockwise from the top, at the art's slots (roda_armas.py SLOTS); key = its number key
	{"mode": Player.Mode.COMBAT, "nome": "Facão", "nota": "corpo a corpo", "arte": "facao", "tecla": "1"},
	{"mode": Player.Mode.XBOW, "nome": "Besta", "nota": "virotes: %d", "arte": "besta", "tecla": "2"},
	{"mode": Player.Mode.EXPLORE, "nome": "Lamparina", "nota": "sem arma na mão", "arte": "lamparina", "tecla": "3"},
]
const PX := 2.0            # texels -> pixels
const RADIUS := 64.0       # the rosary's radius, texels (roda_armas.py R)
const SLOW := 0.25         # time scale while it is open
const DEADZONE := 28.0     # px of mouse travel before a tablet is pointed at
const REACH := 150.0       # px: how far the mouse travel counts
const TEXT := Color(0.86, 0.82, 0.72)
const FAINT := Color(0.62, 0.58, 0.5)

var player: Player
var open := false
var picked := -1           # tablet pointed at, -1 = none
var aim := Vector2.ZERO    # mouse travel since it opened, px
var ring: Control
var centre: Label
var note: Label
var art := {}              # name -> Texture2D


func _init(p: Player) -> void:
	player = p


func _ready() -> void:
	layer = 4; process_mode = Node.PROCESS_MODE_ALWAYS  # sees the pause, to step aside for the notes / shop
	for n in ["terco", "fita", "brilho"] + WHEEL.map(func(w): return "placa_" + w.arte):
		art[n] = load(Paths.TEXTURE % ("roda_" + n))
	ring = Control.new(); add_child(ring); ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE; ring.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ring.draw.connect(_draw_ring)
	for i in WHEEL.size():  # "1 Facão" under each tablet
		var l := _label(slice_dir(i) * RADIUS * PX + Vector2(0, 46), 12, FAINT)
		l.text = "%s  %s" % [WHEEL[i].tecla, WHEEL[i].nome]
	centre = _label(Vector2(0, -8), 24, TEXT)
	note = _label(Vector2(0, 16), 12, FAINT)
	ring.visible = false


func _label(at: Vector2, size: int, col: Color) -> Label:  # centred on `at`, relative to the screen's centre
	var l := Label.new(); ring.add_child(l); l.size = Vector2(180, 24)
	l.position = _mid() + at - l.size / 2
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8)); l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _mid() -> Vector2:
	return ring.get_viewport_rect().size / 2


static func slice_dir(i: int) -> Vector2:
	var a := -PI / 2 + i * TAU / WHEEL.size()
	return Vector2(cos(a), sin(a))


## Which tablet a direction on screen points at (+y = down), -1 when it is too short.
static func slice_at(v: Vector2) -> int:
	if v.length() < DEADZONE:
		return -1
	return wrapi(roundi((v.angle() + PI / 2) / (TAU / WHEEL.size())), 0, WHEEL.size())


func _process(_delta: float) -> void:
	if get_tree().paused or player.mode == Player.Mode.DEAD:
		_close(false)
		return
	var q := Input.is_action_pressed("weapons")
	if q and not open:
		_open()
	elif not q and open:
		_close(true)
	if open:
		var keys := Input.get_vector("left", "right", "forward", "back")
		if keys.length() > 0.5:
			aim = keys * REACH
		picked = slice_at(aim)
		centre.text = WHEEL[picked].nome if picked >= 0 else ""
		note.text = (WHEEL[picked].nota % Inventory.count("virote") if "%d" in WHEEL[picked].nota
			else WHEEL[picked].nota) if picked >= 0 else "aponte com o mouse"
		ring.queue_redraw()  # the candle flickers


func _input(e: InputEvent) -> void:  # open: the mouse steers the wheel, not the camera or the machete
	if not open:
		return
	if e is InputEventMouseMotion:
		aim = (aim + e.relative).limit_length(REACH)
	elif not e is InputEventMouseButton:
		return
	get_viewport().set_input_as_handled()


func _open() -> void:
	open = true; aim = Vector2.ZERO; picked = -1
	Engine.time_scale = SLOW
	ring.visible = true; ring.modulate.a = 0.0
	create_tween().set_ignore_time_scale().tween_property(ring, "modulate:a", 1.0, 0.12)


func _close(choose: bool) -> void:
	if not open:
		return
	open = false; ring.visible = false
	Engine.time_scale = 1.0
	if choose and picked >= 0:
		player.equip(WHEEL[picked].mode)


func _holding() -> int:  # crouched = hands as when exploring
	return Player.Mode.EXPLORE if player.mode == Player.Mode.CROUCH else player.mode


func _exit_tree() -> void:  # never leave the next scene in slow motion
	Engine.time_scale = 1.0


func _draw_ring() -> void:
	var c := _mid()
	ring.draw_rect(Rect2(Vector2.ZERO, c * 2), Color(0, 0, 0, 0.35))  # the world dims behind it
	var t: Texture2D = art.terco
	ring.draw_texture_rect(t, Rect2(c - Vector2(t.get_width(), t.get_width()) / 2 * PX, t.get_size() * PX), false)
	var flicker := 0.85 + 0.1 * sin(Time.get_ticks_msec() * 0.013) + 0.05 * sin(Time.get_ticks_msec() * 0.031)
	for i in WHEEL.size():
		var at := c + slice_dir(i) * RADIUS * PX
		var lit := i == picked
		if lit:
			var g: Texture2D = art.brilho
			ring.draw_texture_rect(g, Rect2(at - g.get_size() * PX / 2, g.get_size() * PX), false, Color(1, 1, 1, flicker))
		var p: Texture2D = art["placa_" + WHEEL[i].arte]
		var top := (at - p.get_size() * PX / 2 + Vector2(0, -2.0 * PX if lit else 0.0)).round()  # pointed: lifted 2 texels
		ring.draw_texture_rect(p, Rect2(top, p.get_size() * PX), false,
			Color(1.25 * flicker + 0.1, 1.1 * flicker + 0.05, 0.9) if lit else Color(0.72, 0.68, 0.64))
		if WHEEL[i].mode == _holding():
			var f: Texture2D = art.fita
			ring.draw_texture_rect(f, Rect2(top + Vector2(p.get_width() - 7, -3) * PX, f.get_size() * PX), false)

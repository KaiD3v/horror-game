# The body and the pockets, drawn small in the corners and only when they matter, then fading out:
#   bottom left   his health as ex-voto hearts (the tin hearts hung at a saint's feet): one per max_health, the flame
#                 on top lit while it is whole; a blocked blow empties a quarter. Shown when it changes (a blow, a cure,
#                 a new heart), shaking on a blow; a new heart glows in.
#   under them    his breath as rosary beads, one per BEAD of stamina_max, a crucifix at the end: shown while it is not
#                 full, spent beads hollow, reddened when winded. More stamina, more beads.
#   bottom right  what he carries that runs out: the ammo of the weapon in hand while it is out (bright while one is
#                 on the rail), and any count that changes (picked up, bought, used: +N / -N) for a moment, money too.
# The hearts and beads grow with max_health / stamina_max: an upgrade is just raising them.
class_name HudStatus
extends Control

const HOLD := 3.5                 # s shown after a change, then...
const FADE := 0.8                 # ...s fading out
const BEAD := 0.5                 # stamina a bead stands for (STAMINA_MAX 4 = 8 beads)
const PER_ROW := 10               # hearts in a row, more go above
const AMMO := {Player.Mode.XBOW: "virote"}   # the weapon in hand -> what it spends: shown while it is out
const MARGIN := 28.0
const HEART := 22.0               # heart spacing
const WAX := Color(0.6, 0.11, 0.07)
const TIN := Color(0.5, 0.4, 0.27)     # = DialogBox.GILT
const DARK := Color(0.05, 0.04, 0.03, 0.75)
const BONE := Color(0.86, 0.82, 0.72)  # = DialogBox.TEXT
const FAINT := Color(0.58, 0.54, 0.47)
const CANDLE := Color(1.0, 0.76, 0.42)
const BLOOD := Color(0.78, 0.16, 0.1)

var player: Player
var hearts_t := 0.0               # time left on screen (HOLD + FADE when shown)
var beads_t := 0.0
var rows := {}                    # item id (or "dinheiro") -> time left on screen
var delta_n := {}                 # ...and by how much it just changed (0 = no change, only shown)
var shake_t := 0.0                # a blow: the hearts shake
var glow_t := 0.0                 # a new heart glowing in
var _health := NAN
var _max := 0
var _counts := {}
var _font: Font
var _heart := PackedVector2Array()  # a heart's outline, centred on 0, HEART-ish wide


func _init(p: Player) -> void:
	player = p
	set_anchors_preset(PRESET_FULL_RECT); mouse_filter = MOUSE_FILTER_IGNORE
	for i in 24:  # the classic heart curve
		var t := TAU * i / 24.0
		_heart.append(Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * 0.6)


func _ready() -> void:
	_font = get_theme_default_font()
	_counts = _snapshot()


## Every count that runs out (not the tools: having one is shown by FoundBanner), and the money.
func _snapshot() -> Dictionary:
	var s := {"dinheiro": Inventory.money}
	for id in Inventory.items:
		if not ItemCatalog.tool(id):
			s[id] = Inventory.count(id)
	return s


func _show(t: float) -> float:
	return maxf(t, HOLD + FADE)


static func alpha(t: float) -> float:
	return clampf(t / FADE, 0.0, 1.0)


func _process(delta: float) -> void:
	if is_nan(_health):
		_health = player.health; _max = player.max_health
	if player.max_health > _max:
		glow_t = 1.5
	if player.health != _health or player.max_health != _max or player.mode == Player.Mode.DEAD:
		if player.health < _health:
			shake_t = 0.35
		hearts_t = _show(hearts_t)
	_health = player.health; _max = player.max_health
	if player.stamina < player.stamina_max - 0.01:
		beads_t = _show(beads_t)
	var now := _snapshot()
	for id in now:
		if now[id] != _counts.get(id, 0):
			delta_n[id] = now[id] - _counts.get(id, 0); rows[id] = _show(0.0)
	_counts = now
	var ammo: String = AMMO.get(player.mode, "")
	if ammo != "":
		rows[ammo] = _show(rows.get(ammo, 0.0))
	hearts_t -= delta; beads_t -= delta; shake_t -= delta; glow_t -= delta
	for id in rows.keys():
		rows[id] -= delta
		if rows[id] <= 0.0:
			rows.erase(id); delta_n.erase(id)
	queue_redraw()


func _draw() -> void:
	var foot := size.y - MARGIN
	if hearts_t > 0.0:
		_draw_hearts(Vector2(MARGIN + 8, foot - 30), alpha(hearts_t))
	if beads_t > 0.0:
		_draw_beads(Vector2(MARGIN, foot - 6), alpha(beads_t))
	var y := foot
	for id in rows:
		_draw_row(id, Vector2(size.x - MARGIN, y), alpha(rows[id]))
		y -= 26


func _draw_hearts(at: Vector2, a: float) -> void:
	if shake_t > 0.0:
		at += Vector2(randf_range(-2, 2), randf_range(-1, 1)).round()
	for i in player.max_health:
		var c := at + Vector2((i % PER_ROW) * HEART, -floorf(i / float(PER_ROW)) * HEART)
		var fill := clampf(player.health - i, 0.0, 1.0)
		var s := 1.0
		if fill > 0.0 and player.health <= 1.0 and player.mode != Player.Mode.DEAD:
			s += 0.08 * maxf(0.0, sin(Time.get_ticks_msec() * 0.008))  # the last one beats
		if i == player.max_health - 1 and glow_t > 0.0:
			draw_circle(c, 12.0, Color(CANDLE, 0.35 * a * glow_t / 1.5))
		var shape: PackedVector2Array = Transform2D(0.0, Vector2(s, s), 0.0, c) * _heart
		draw_colored_polygon(shape, Color(DARK, DARK.a * a))
		if fill > 0.0:  # filled from the left, a quarter at a time
			var w := 9.6 * s  # the heart's half width
			var cut := PackedVector2Array([c + Vector2(-w, -12), c + Vector2(-w + 2 * w * fill, -12), c + Vector2(-w + 2 * w * fill, 12), c + Vector2(-w, 12)])
			for part in Geometry2D.intersect_polygons(shape, cut):
				draw_colored_polygon(part, Color(WAX, a))
		var edge := shape.duplicate(); edge.append(shape[0])
		draw_polyline(edge, Color(TIN if fill > 0.0 else FAINT, a * (1.0 if fill > 0.0 else 0.5)), 1.5)
		if fill >= 1.0:  # the sacred heart's flame
			draw_colored_polygon(PackedVector2Array([c + Vector2(-2.5, -3), c + Vector2(0, -10), c + Vector2(2.5, -3)]), Color(CANDLE, a))


func _draw_beads(at: Vector2, a: float) -> void:
	var n := ceili(player.stamina_max / BEAD - 0.001)
	var gap := 11.0
	var col := BLOOD if player.winded else BONE
	# the crucifix the string hangs from, then the string
	draw_line(at + Vector2(0, -5), at + Vector2(0, 6), Color(TIN, a), 2.0)
	draw_line(at + Vector2(-3, -2), at + Vector2(3, -2), Color(TIN, a), 2.0)
	draw_line(at + Vector2(4, 0), at + Vector2(6 + gap * n, 0), Color(FAINT, 0.5 * a), 1.0)
	for i in n:
		var c := at + Vector2(12 + gap * i, 0)
		var fill := clampf((player.stamina - i * BEAD) / BEAD, 0.0, 1.0)
		draw_circle(c, 3.5, Color(DARK, DARK.a * a))
		draw_arc(c, 3.5, 0.0, TAU, 12, Color(FAINT, 0.6 * a), 1.0)
		if fill > 0.0:
			draw_circle(c, 3.5 * (0.5 + 0.5 * fill), Color(col, a * (0.4 + 0.6 * fill)))


## One line of the right-hand tally, right-aligned at `at`: the item's mark, how many, what just changed.
func _draw_row(id: String, at: Vector2, a: float) -> void:
	var size_f := 16
	var n: int = Inventory.money if id == "dinheiro" else Inventory.count(id)
	var txt := ItemCatalog.price(n) if id == "dinheiro" else str(n)
	var d: int = delta_n.get(id, 0)
	var x := at.x
	if d != 0 and rows[id] > HOLD + FADE - 2.0:
		var dt := ("+%d" if d > 0 else "%d") % d
		x -= _font.get_string_size(dt, HORIZONTAL_ALIGNMENT_LEFT, -1, size_f).x
		draw_string(_font, Vector2(x, at.y), dt, HORIZONTAL_ALIGNMENT_LEFT, -1, size_f, Color(CANDLE if d > 0 else BLOOD, a))
		x -= 8
	x -= _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size_f).x
	draw_string(_font, Vector2(x, at.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size_f, Color(BONE if n > 0 else BLOOD, a))
	if id == "dinheiro":
		return
	var it := ItemCatalog.item(id)
	var g := Vector2(x - 14, at.y - 6)
	match it.tipo:
		"municao":  # a bolt: shaft, iron head, fletching; bright while one is on the rail
			var c := Color(CANDLE if player.loaded and AMMO.get(player.mode, "") == id else FAINT, a)
			draw_line(g + Vector2(-10, 4), g + Vector2(8, -4), c, 1.5)
			draw_colored_polygon(PackedVector2Array([g + Vector2(11, -5.5), g + Vector2(6, -5), g + Vector2(8, -1)]), c)
			draw_line(g + Vector2(-10, 4), g + Vector2(-12, 1), c, 1.5)
			draw_line(g + Vector2(-10, 4), g + Vector2(-9, 7), c, 1.5)
		"cura":  # a rolled bandage with a cross
			draw_rect(Rect2(g + Vector2(-7, -5), Vector2(12, 10)), Color(BONE, 0.8 * a))
			draw_line(g + Vector2(-1, -3), g + Vector2(-1, 3), Color(BLOOD, a), 2.0)
			draw_line(g + Vector2(-4, 0), g + Vector2(2, 0), Color(BLOOD, a), 2.0)
		_:  # no mark yet: its name
			var w := _font.get_string_size(it.nome, HORIZONTAL_ALIGNMENT_LEFT, -1, size_f - 4).x
			draw_string(_font, Vector2(g.x + 4 - w, at.y), it.nome, HORIZONTAL_ALIGNMENT_LEFT, -1, size_f - 4, Color(FAINT, a))

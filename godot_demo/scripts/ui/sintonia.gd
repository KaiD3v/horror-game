# Tuning Bento's radio (../docs/CONTEUDO_VILAREJO.md "A sintonia do rádio", venda.gd): the AM band on the screen, a needle;
# A/D (or the mouse wheel) turn the dial, E or Esc leave. The stations fade in as the needle nears them, the static
# between (radio_chiado):
#   750 kHz   Rádio Nacional, music (musica_venda)
#   1010 kHz  the Voz do Brasil, in its hour (19-20h); otherwise only a carrier hum under the static
#   1180 kHz  between two stations, a frequency that should not be there: only in the small hours (0-5h), and only once
#             Firmina, Bento and Tenório have each had their task done. The Colônia, transmitting (radio_colonia): held on
#             it, he makes out a voice reading numbers. The last is 0187: his mother's (NotesData "obito").
# The game goes on (no pause), he stands at the radio (busy).
class_name Sintonia
extends CanvasLayer

signal closed

const LO := 540.0
const HI := 1600.0
const SPEED := 160.0          # kHz a second, holding A or D
const WIDTH := 28.0           # how far off a station still comes through
const COLONIA := 1180.0
const NUMBERS := ["...0412...", "...0231...", "...0587... 0612...", "...0187."]  # Bastião, Celina, two more, his mother

var player: Player
var freq := 640.0
var players := {}             # sound -> AudioStreamPlayer
var band: Control
var needle: ColorRect
var readout: Label
var heard: Label
var lock := 0.0               # seconds held on the Colônia's frequency
var told := 0                 # how many of its numbers he has made out


static func colonia_on() -> bool:
	var h := WorldTime.hour()
	return h < 5.0 and Story.task("sino") == "feita" and Story.task("pao") == "feita" and Story.task("galinhas") == "feita"


func _init(p: Player) -> void:
	player = p; layer = 60


func _ready() -> void:
	player.busy = true; player.velocity = Vector3.ZERO
	for n in ["radio_chiado", "musica_venda", "voz_do_brasil", "radio_colonia"]:
		var a := Audio.play2d(self, n, -80.0, true); players[n] = a
	var panel := PanelContainer.new(); add_child(panel)
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
	panel.offset_left = -330; panel.offset_right = 330; panel.offset_top = -210; panel.offset_bottom = -40
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.16, 0.11, 0.07, 0.95); sb.border_color = Color(0.55, 0.42, 0.22)
	sb.set_border_width_all(2); sb.set_content_margin_all(14); panel.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 8); panel.add_child(box)
	readout = _label(box, "", Color(1.0, 0.82, 0.45))
	band = Control.new(); band.custom_minimum_size = Vector2(620, 46); box.add_child(band)
	var glass := ColorRect.new(); glass.color = Color(0.95, 0.82, 0.5, 0.9); glass.size = Vector2(620, 46); band.add_child(glass)
	for k in range(6, 17):  # the scale: 600 .. 1600
		var x := (k * 100.0 - LO) / (HI - LO) * 620.0
		var tick := ColorRect.new(); tick.color = Color(0.25, 0.15, 0.08); tick.position = Vector2(x, 0); tick.size = Vector2(2, 14); band.add_child(tick)
		var num := Label.new(); num.text = str(k * 10); num.position = Vector2(x - 10, 16); band.add_child(num)
		num.add_theme_color_override("font_color", Color(0.25, 0.15, 0.08))
	needle = ColorRect.new(); needle.color = Color(0.7, 0.08, 0.05); needle.size = Vector2(3, 46); band.add_child(needle)
	heard = _label(box, "", Color(0.92, 0.9, 0.84)); heard.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(box, "A/D · girar o dial    E · largar o rádio", Color(0.6, 0.55, 0.48))
	_mix(0.0)


func _label(parent: Node, t: String, c: Color) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_color_override("font_color", c); parent.add_child(l)
	return l


## How strong each station is at the needle (0..1).
func strength(at: float) -> Dictionary:
	var near := func(f: float) -> float: return clampf(1.0 - absf(freq - f) / WIDTH, 0.0, 1.0)
	var voz := DayData.radio(WorldTime.hour()) == "voz_do_brasil"
	return {"musica_venda": near.call(750.0), "voz_do_brasil": near.call(1010.0) if voz else 0.0,
		"radio_colonia": near.call(COLONIA) if colonia_on() else 0.0}


func _process(delta: float) -> void:
	var turn := Input.get_axis("left", "right")
	if turn != 0.0:
		freq = clampf(freq + turn * SPEED * delta, LO, HI)
	_mix(delta)


func _mix(delta: float) -> void:
	var s := strength(freq)
	var best := 0.0
	for n in s:
		players[n].volume_db = linear_to_db(maxf(s[n], 0.0001)) - 4.0
		best = maxf(best, s[n])
	players.radio_chiado.volume_db = linear_to_db(maxf(1.0 - best * 0.9, 0.0001)) - 6.0
	needle.position.x = (freq - LO) / (HI - LO) * 620.0 - 1.0
	readout.text = "AM  %d kHz" % int(freq)
	var on := ""
	if s.musica_venda > 0.7:
		on = "Uma moda de viola, longe."
	elif s.voz_do_brasil > 0.7:
		on = "\"Em Brasília, dezenove horas.\" A Voz do Brasil."
	elif s.radio_colonia > 0.75:
		lock += delta
		var k := mini(int(lock / 2.2), NUMBERS.size())
		if k > told:
			told = k
			if told == NUMBERS.size():
				_heard_mother()
		on = "Entre o chiado, uma voz de homem, lenta, lendo números: " + " ".join(NUMBERS.slice(0, maxi(told, 1)))
	if s.radio_colonia <= 0.75:
		lock = 0.0
	heard.text = on


func _heard_mother() -> void:
	if Story.has("radio:colonia"):
		return
	Story.mark("radio:colonia")
	if "radio_colonia" not in NotesReader.read:
		NotesReader.read.append("radio_colonia")
	player.notice.emit("0187. O número da mãe, no ofício. ...Anotado no caderno.")


func close() -> void:
	player.busy = false
	closed.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo():
		return
	if e is InputEventMouseButton and e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		freq = clampf(freq + (6.0 if e.button_index == MOUSE_BUTTON_WHEEL_UP else -6.0), LO, HI)
	elif e.is_action("interact") or (e is InputEventKey and e.keycode == KEY_ESCAPE):
		close()
	else:
		return
	get_viewport().set_input_as_handled()

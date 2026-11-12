# A combination padlock's wheels (the venda's cellar, ../docs/CONTEUDO_VILAREJO.md "O porão da venda"): four brass
# wheels of 0-9. A/D pick a wheel, W/S turn it, E tries the shackle, Esc leaves. Right: `opened`. The game goes on
# around him (he stands at the lock: busy).
class_name Segredo
extends CanvasLayer

signal opened
signal closed

var player: Player
var code := ""
var digits := [0, 0, 0, 0]
var at := 0
var wheels: Array[Label] = []
var line: Label


func _init(p: Player, combination: String) -> void:
	player = p; code = combination; layer = 60


func _ready() -> void:
	player.busy = true; player.velocity = Vector3.ZERO
	var panel := PanelContainer.new(); add_child(panel)
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -190; panel.offset_right = 190; panel.offset_top = -110; panel.offset_bottom = 110
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.08, 0.07, 0.06, 0.95); sb.border_color = Color(0.6, 0.48, 0.22)
	sb.set_border_width_all(2); sb.set_content_margin_all(16); panel.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 12); panel.add_child(box)
	var title := Label.new(); title.text = "Cadeado de segredo"; title.add_theme_color_override("font_color", Color(0.86, 0.72, 0.42))
	box.add_child(title)
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	for i in 4:
		var w := Label.new(); w.add_theme_font_size_override("font_size", 34); row.add_child(w); wheels.append(w)
	line = Label.new(); line.add_theme_color_override("font_color", Color(0.85, 0.82, 0.76)); box.add_child(line)
	var hint := Label.new(); hint.text = "A/D · roda    W/S · girar    E · puxar    Esc · largar"
	hint.add_theme_color_override("font_color", Color(0.55, 0.52, 0.48)); box.add_child(hint)
	_show()


func _show() -> void:
	for i in 4:
		wheels[i].text = " %d " % digits[i]
		wheels[i].add_theme_color_override("font_color", Color(1.0, 0.85, 0.45) if i == at else Color(0.7, 0.6, 0.4))
		var frame := StyleBoxFlat.new(); frame.bg_color = Color(0.25, 0.2, 0.1, 0.9 if i == at else 0.4)
		frame.border_color = Color(1.0, 0.85, 0.45); frame.set_border_width_all(2 if i == at else 0)
		wheels[i].add_theme_stylebox_override("normal", frame)


func entered() -> String:
	return "".join(digits.map(func(d): return str(d)))


func set_code(s: String) -> void:  # (the autotest)
	for i in 4:
		digits[i] = int(s[i])
	_show()


func pull() -> bool:
	Audio.play2d(self, "cadeado_abrir" if entered() == code else "tilintar", -4.0)
	if entered() != code:
		line.text = "O cadeado não cede."
		return false
	opened.emit(); close()
	return true


func close() -> void:
	player.busy = false
	closed.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo():
		return
	if e.is_action("left"):
		at = wrapi(at - 1, 0, 4)
	elif e.is_action("right"):
		at = wrapi(at + 1, 0, 4)
	elif e.is_action("forward"):
		digits[at] = wrapi(digits[at] + 1, 0, 10)
	elif e.is_action("back"):
		digits[at] = wrapi(digits[at] - 1, 0, 10)
	elif e.is_action("interact"):
		pull(); get_viewport().set_input_as_handled(); return
	elif e is InputEventKey and e.keycode == KEY_ESCAPE:
		close(); get_viewport().set_input_as_handled(); return
	else:
		return
	_show()
	get_viewport().set_input_as_handled()

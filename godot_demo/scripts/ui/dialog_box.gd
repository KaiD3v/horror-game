# Talking to a villager (Dialog has the rules, scripts/data/dialogos/ what they say): the game pauses and a dark box
# opens across the bottom of the screen, edged in old gilt like a holy card, the speaker's name on a tab above it with
# a red ribbon (the rosary's, WeaponWheel). Their words come out a few letters at a time; E (or a click) shows the rest,
# then the next page. After the last page, their options in a numbered list: W/S or the mouse to point, E / Enter /
# click / the number key to choose, Esc to leave. Choosing their shop puts the shop's page over the talk; closing it
# comes back here.
class_name DialogBox
extends CanvasLayer

signal closed

const TEXT := Color(0.86, 0.82, 0.72)
const FAINT := Color(0.58, 0.54, 0.47)
const CANDLE := Color(1.0, 0.76, 0.42)
const GILT := Color(0.5, 0.4, 0.27)
const RIBBON := Color(0.55, 0.14, 0.08)
const CPS := 55.0              # letters a second

var dialog: Dialog
var box: PanelContainer
var tab: PanelContainer
var name_l: Label
var text: Label
var list: VBoxContainer
var foot: Label
var rows: Array[Button] = []
var shown := 0.0               # letters out so far
var choosing := false


func _ready() -> void:
	add_to_group("dialog_box")
	layer = 6; process_mode = Node.PROCESS_MODE_ALWAYS  # talking pauses the game, not the talk
	var dim := ColorRect.new(); add_child(dim); dim.color = Color(0, 0, 0, 0.3); dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box = PanelContainer.new(); add_child(box)
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 40; box.offset_right = -40; box.offset_top = -150; box.offset_bottom = -26
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN  # more options: it grows up the screen, never off its foot
	box.add_theme_stylebox_override("panel", _frame(GILT, 4))
	var v := VBoxContainer.new(); box.add_child(v); v.add_theme_constant_override("separation", 6)
	text = _label(v, 24, TEXT); text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(0, 58)
	list = VBoxContainer.new(); v.add_child(list); list.add_theme_constant_override("separation", 0)
	foot = _label(v, 12, FAINT); foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tab = PanelContainer.new(); add_child(tab)
	tab.add_theme_stylebox_override("panel", _frame(RIBBON, 0))
	name_l = _label(tab, 24, CANDLE)
	visible = false


## A dark panel edged in `edge` (gilt for the box, the ribbon's red for the name tab).
func _frame(edge: Color, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = Color(0.045, 0.038, 0.032)
	s.border_color = edge; s.set_border_width_all(2)
	s.content_margin_left = 22; s.content_margin_right = 22; s.content_margin_top = 8 + pad; s.content_margin_bottom = 8
	s.shadow_color = Color(0, 0, 0, 0.6); s.shadow_size = 6
	return s


func _label(parent: Node, size: int, col: Color) -> Label:
	var l := Label.new(); parent.add_child(l)
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 2); l.add_theme_constant_override("shadow_offset_y", 2)
	return l


## Talk to `who` (an NpcCatalog id).
func open(who: String, player: Player) -> void:
	dialog = Dialog.new(who, player)
	name_l.text = dialog.nome
	visible = true
	get_tree().paused = true
	dialog.begin()
	_speak()


func close() -> void:
	visible = false; choosing = false
	get_tree().paused = false
	closed.emit()


## The current page, letter by letter.
func _speak() -> void:
	choosing = false; _clear_rows()
	text.text = dialog.line(); shown = 0.0; text.visible_characters = 0
	foot.text = "E  continuar"
	if text.text == "":
		_choose()


func _process(delta: float) -> void:
	if visible:
		tab.position = Vector2(box.global_position.x + 18, box.global_position.y - tab.size.y + 2)  # the name sits on the box
		if not choosing and text.visible_characters >= 0 and text.visible_characters < text.text.length():
			shown += CPS * delta
			text.visible_characters = mini(int(shown), text.text.length())
			if text.visible_characters >= text.text.length():
				text.visible_characters = -1


func typing() -> bool:
	return text.visible_characters != -1 and text.visible_characters < text.text.length()


## After the last page: their options.
func _choose() -> void:
	choosing = true; _clear_rows()
	text.visible_characters = -1
	var opts := dialog.options()
	for i in opts.size():
		var b := Button.new(); list.add_child(b); b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.text = "%d   %s" % [i + 1, opts[i].texto]
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for s in ["font_color", "font_pressed_color"]:
			b.add_theme_color_override(s, FAINT)
		for s in ["font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(s, CANDLE)
		b.pressed.connect(pick.bind(i)); b.mouse_entered.connect(b.grab_focus)
		rows.append(b)
	foot.text = "W/S escolher   ·   E confirmar   ·   Esc sair"
	if rows:
		rows[0].grab_focus()


func _clear_rows() -> void:
	for r in rows:
		r.queue_free()
	rows.clear()


## The player picks option i of those on offer.
func pick(i: int) -> void:
	var opts := dialog.options()
	if not choosing or i < 0 or i >= opts.size():
		return
	var ui := dialog.pick(opts[i])
	if ui == Dialog.END:
		close()
	elif ui.begins_with("loja:"):  # their shop over the talk; back here when it closes
		var shop: ShopMenu = get_tree().get_first_node_in_group("shop_menu")
		visible = false
		shop.closed.connect(_back_from_shop, CONNECT_ONE_SHOT)
		shop.open(ui.trim_prefix("loja:"), dialog.nome)
	elif opts[i].get("vai", "") != "":  # somewhere new: its words (none: straight to its options)
		_speak()
	else:
		_choose()


func _back_from_shop() -> void:
	visible = true
	get_tree().paused = true
	_choose()


func focused() -> int:
	return rows.find(get_viewport().gui_get_focus_owner())


func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	if e.is_action_pressed("interact") or e.is_action_pressed("ui_accept") or (e.is_action_pressed("attack") and not choosing):
		if typing():
			text.visible_characters = -1
		elif not choosing and dialog.more():
			dialog.next_page(); _speak()
		elif not choosing:
			_choose()
		elif focused() >= 0:
			pick(focused())
	elif e.is_action_pressed("ui_cancel") or e.is_action_pressed("notes"):
		if choosing:
			close()
		else:
			_choose()  # skip to the options
	elif choosing and (e.is_action_pressed("forward") or e.is_action_pressed("back")) and rows:
		rows[wrapi(focused() + (1 if e.is_action_pressed("back") else -1), 0, rows.size())].grab_focus()
	elif choosing and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode >= KEY_1 and e.physical_keycode <= KEY_9:
		pick(e.physical_keycode - KEY_1)
	else:
		return
	get_viewport().set_input_as_handled()

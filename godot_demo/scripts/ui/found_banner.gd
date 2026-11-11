# What you just found (Chest): a dark band across the bottom of the screen, "Você encontrou", its name and what it
# says about itself (ItemCatalog). No menu: E (or a click, Enter) and it goes. `await FoundBanner.open(...)`.
class_name FoundBanner
extends CanvasLayer

signal done

const TEXT := Color(0.86, 0.82, 0.72)
const FAINT := Color(0.62, 0.58, 0.5)
const MIN_TIME := 0.8   # s before E closes it (the E that opened the trunk must not skip it)

var shown_at := 0
var head: Label
var name_l: Label
var desc: Label


## Anything else to announce the same way (a door forced open): its head, its name, a line.
static func tell(from: Node, head_text: String, title: String, line: String) -> void:
	var b := FoundBanner.new(); from.get_tree().current_scene.add_child(b)
	b.head.text = head_text; b.name_l.text = title; b.desc.text = line
	await b.done


static func open(from: Node, item: String, qtd := 1) -> void:
	var b := FoundBanner.new(); from.get_tree().current_scene.add_child(b)
	var it := ItemCatalog.item(item)
	b.name_l.text = it.nome + (" (%d)" % qtd if qtd > 1 else "")
	b.desc.text = it.descricao
	await b.done


func _init() -> void:
	layer = 5; process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("found_banner")
	var band := ColorRect.new(); add_child(band); band.color = Color(0.03, 0.025, 0.02, 0.82)
	band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); band.offset_top = -150
	head = _label(band, 14, 14, FAINT); head.text = "VOCÊ ENCONTROU"
	name_l = _label(band, 34, 28, TEXT)
	desc = _label(band, 74, 16, FAINT); desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var foot := _label(band, 120, 12, FAINT); foot.text = "E  continuar"
	band.modulate.a = 0.0
	create_tween().tween_property(band, "modulate:a", 1.0, 0.25)
	shown_at = Time.get_ticks_msec()


func _label(band: Control, top: float, size: int, col: Color) -> Label:
	var l := Label.new(); band.add_child(l)
	l.set_anchors_preset(Control.PRESET_TOP_WIDE); l.offset_top = top; l.offset_left = 80; l.offset_right = -80
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 2); l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _unhandled_input(e: InputEvent) -> void:
	if not (e.is_action_pressed("interact") or e.is_action_pressed("ui_accept") or e.is_action_pressed("attack")):
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() - shown_at >= MIN_TIME * 1000.0:
		done.emit(); queue_free()

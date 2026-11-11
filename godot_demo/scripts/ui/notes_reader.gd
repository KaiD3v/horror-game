# Reading the notes (NotesData): the game pauses on the page, held up close (aged paper at 2x from
# ../tools/texturas/notas_papeis.py, the text in the game font). Once read a note is yours: the notebook (Caderno,
# Tab) lists them to reread; A/D leafs through, E / Tab / Esc closes. Kept across scenes (a static list).
class_name NotesReader
extends CanvasLayer

signal closed

const PAGE := Vector2(420, 540)   # the paper on screen: 210 x 270 texels at 2x
const INK := {"caderno": Color(0.13, 0.12, 0.2), "oficio": Color(0.11, 0.1, 0.1), "ficha": Color(0.2, 0.12, 0.08)}

static var read: Array[String] = []   # ids, in the order you found them

var showing := -1                     # index into `read` on screen, -1 = closed
var page: TextureRect
var text: Label
var foot: Label


func _ready() -> void:
	add_to_group("notes_reader")
	layer = 5; process_mode = Node.PROCESS_MODE_ALWAYS  # reading pauses the game, not the reader
	var screen := get_viewport().get_visible_rect().size
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.72); dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	page = TextureRect.new(); page.position = Vector2((screen.x - PAGE.x) / 2, 30); page.size = PAGE
	page.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	text = Label.new(); page.add_child(text); text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.position = Vector2(44, 68); text.size = Vector2(PAGE.x - 72, PAGE.y - 90)  # baselines on the paper's rules
	text.add_theme_constant_override("line_spacing", 0)
	foot = Label.new(); foot.position = Vector2(0, screen.y - 26); foot.size = Vector2(screen.x, 24)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; foot.add_theme_font_size_override("font_size", 12)
	foot.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	for n in [dim, page, foot]:
		n.visible = false; add_child(n)


## A note found: kept and opened.
func take(id: String) -> void:
	if id not in read:
		read.append(id)
	open(read.find(id))


func open(i: int) -> void:
	showing = i
	var n := NotesData.note(read[i])
	page.texture = load(Paths.TEXTURE % ("nota_%s" % n.paper))
	text.text = n.text; text.add_theme_color_override("font_color", INK[n.paper])
	foot.text = "%s   ·   %d de %d achados   ·   %sE fechar" % [n.title, i + 1, NotesData.NOTES.size(),
		"A/D folhear   ·   " if read.size() > 1 else ""]
	for c in get_children():
		c.visible = true
	get_tree().paused = true


func close() -> void:
	showing = -1
	for c in get_children():
		c.visible = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(e: InputEvent) -> void:
	if showing >= 0:
		if e.is_action_pressed("interact") or e.is_action_pressed("notes") or e.is_action_pressed("ui_cancel"):
			close()
		elif e.is_action_pressed("left") or e.is_action_pressed("right"):
			open(wrapi(showing + (1 if e.is_action_pressed("right") else -1), 0, read.size()))
		get_viewport().set_input_as_handled()

# His notebook (Tab): the game pauses on two ruled pages side by side (the notes' paper, nota_caderno), in pen.
# Three sections, as ribbons along the top of the left page:
#   Tarefas  what people asked of him (QuestData, where each stands in Story): the ones going on, then the ones done
#   Bolso    the day and the hour, his money, and everything he carries (tools first, then keys, then the rest)
#   Notas    the papers he found (NotesReader): E reads one, closing it comes back here
# The left page lists, the right page tells about the one chosen. A/D (or a click on a ribbon) changes section, W/S (or
# the mouse) chooses, E reads a note, Tab / Esc closes.
class_name Caderno
extends CanvasLayer

signal closed

const PAGE := Vector2(420, 540)            # the paper at 2x, like the notes
const INK := Color(0.13, 0.12, 0.2)        # = NotesReader's caderno
const PICKED := Color(0.55, 0.14, 0.08)
const FAINT := Color(0.45, 0.43, 0.42)
const SECTIONS := ["Tarefas", "Bolso", "Notas"]

static var section := 0                    # the one it opens on: where it was left

var left: TextureRect
var right: TextureRect
var tabs: Array[Button] = []
var head: Label                            # Bolso: the day, the hour, the money
var list: VBoxContainer
var empty: Label
var title: Label
var detail: Label
var rows: Array[Button] = []
var entries: Array = []                    # what each row stands for: {texto, detalhe, apagado, nota}


func _ready() -> void:
	add_to_group("caderno")
	layer = 5; process_mode = Node.PROCESS_MODE_ALWAYS  # reading it pauses the game, not the notebook
	var screen := get_viewport().get_visible_rect().size
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.72); dim.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(dim)
	var x0 := (screen.x - PAGE.x * 2) / 2
	left = _page(Vector2(x0, 30), false); right = _page(Vector2(x0 + PAGE.x, 30), true)
	var bar := HBoxContainer.new(); left.add_child(bar); bar.position = Vector2(40, 30); bar.add_theme_constant_override("separation", 18)
	for i in SECTIONS.size():
		var t := Button.new(); bar.add_child(t); t.text = SECTIONS[i]; t.flat = true; t.focus_mode = Control.FOCUS_NONE
		t.add_theme_font_size_override("font_size", 24)
		t.pressed.connect(show_section.bind(i))
		tabs.append(t)
	head = _label(left, Vector2(44, 84), FAINT)
	list = VBoxContainer.new(); left.add_child(list); list.position = Vector2(36, 84); list.size = Vector2(PAGE.x - 72, 420)
	list.add_theme_constant_override("separation", 0)
	empty = _label(left, Vector2(44, 100), FAINT)
	title = _label(right, Vector2(44, 40), INK)
	detail = _label(right, Vector2(44, 100), Color(0.22, 0.2, 0.26)); detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size = Vector2(PAGE.x - 88, 400)
	var foot := Label.new(); add_child(foot); foot.position = Vector2(0, screen.y - 26); foot.size = Vector2(screen.x, 24)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; foot.add_theme_font_size_override("font_size", 12)
	foot.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	foot.text = "A/D seção   ·   W/S escolher   ·   E ler (notas)   ·   Tab / Esc fechar"
	visible = false


func _page(at: Vector2, flip: bool) -> TextureRect:
	var p := TextureRect.new(); add_child(p); p.position = at; p.size = PAGE
	p.texture = load(Paths.TEXTURE % "nota_caderno"); p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; p.flip_h = flip
	return p


func _label(page: Control, at: Vector2, col: Color) -> Label:
	var l := Label.new(); page.add_child(l); l.position = at; l.size = Vector2(PAGE.x - 88, 24)
	l.add_theme_font_size_override("font_size", 24); l.add_theme_color_override("font_color", col)
	return l


func open() -> void:
	visible = true
	get_tree().paused = true
	show_section(section)


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func show_section(i: int) -> void:
	section = wrapi(i, 0, SECTIONS.size())
	for k in tabs.size():
		for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			tabs[k].add_theme_color_override(s, PICKED if k == section else FAINT)
	entries = _entries()
	head.text = _head(); head.visible = head.text != ""
	list.position.y = 84 + (head.get_line_count() * 26 + 12 if head.visible else 0)
	for r in rows:
		r.queue_free()
	rows.clear()
	for i2 in entries.size():
		var e: Dictionary = entries[i2]
		var b := Button.new(); list.add_child(b); b.flat = true; b.text = e.texto
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_font_size_override("font_size", 24)
		for s in ["font_color", "font_pressed_color"]:
			b.add_theme_color_override(s, FAINT if e.get("apagado", false) else INK)
		for s in ["font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(s, PICKED)
		b.focus_entered.connect(_tell.bind(i2)); b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(_read.bind(i2))
		rows.append(b)
	empty.text = ["Nada anotado ainda.", "Os bolsos estão vazios.", "Nenhum papel guardado."][section]
	empty.visible = rows.is_empty()
	title.text = ""; detail.text = ""
	if rows:
		rows[0].grab_focus(); _tell(0)


## What a section lists.
func _entries() -> Array:
	var out := []
	match SECTIONS[section]:
		"Tarefas":
			for state in ["ativa", "feita"]:
				for id in QuestData.QUESTS:
					if Story.task(id) == state:
						var q: Dictionary = QuestData.QUESTS[id]
						out.append({"texto": ("· " if state == "ativa" else "+ ") + q.titulo, "titulo": q.titulo,
							"detalhe": q.descricao + ("\n\nCumprida." if state == "feita" else ""), "apagado": state == "feita"})
		"Bolso":
			for kind in ["ferramenta", "chave", ""]:  # tools and weapons, keys, then what runs out
				for id in ItemCatalog.ITEMS:
					var it: Dictionary = ItemCatalog.ITEMS[id]
					var n := Inventory.count(id)
					if n > 0 and (it.tipo == kind or (kind == "" and it.tipo not in ["ferramenta", "chave"])):
						var label: String = "Contas de terço (%d de %d)" % [(n - 1) % Inventory.BEADS + 1, Inventory.BEADS] if id == "conta_terco" \
							else "Lamparina · " + Inventory.lamp_state() if id == "lamparina" \
							else it.nome + (" (%d de %d)" % [n, Inventory.cap(it.tipo)] if it.tipo == "municao" \
							else " (%d)" % n if it.tipo not in ["ferramenta", "melhoria", "equipamento"] else "")
						out.append({"texto": label, "titulo": it.nome,
							"detalhe": it.descricao})
		"Notas":
			for i in NotesReader.read.size():
				var n := NotesData.note(NotesReader.read[i])
				out.append({"texto": n.title, "titulo": n.title, "detalhe": "E · ler", "nota": i})
	return out


func _head() -> String:
	if SECTIONS[section] != "Bolso":
		return ""
	return "Dia %d · %s · %s\nDinheiro: %s de %s%s" % [int(WorldTime.minutes / 1440.0) + 1, WorldTime.period().nome, WorldTime.clock(),
		ItemCatalog.price(Inventory.money), ItemCatalog.price(Inventory.cap("dinheiro")),
		"   ·   com o Bento: " + ItemCatalog.price(Inventory.banked) if Inventory.banked > 0 else ""]


func _tell(i: int) -> void:  # the right page: the one chosen
	title.text = entries[i].titulo; detail.text = entries[i].detalhe


## E on a note: the reader over the notebook; closing it comes back here.
func _read(i: int) -> void:
	if not entries[i].has("nota"):
		return
	var reader: NotesReader = get_tree().get_first_node_in_group("notes_reader")
	visible = false
	reader.closed.connect(func(): open.call_deferred(), CONNECT_ONE_SHOT)
	reader.open(entries[i].nota)


func focused() -> int:
	return rows.find(get_viewport().gui_get_focus_owner())


func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		var p: Player = get_tree().get_first_node_in_group("player")
		if e.is_action_pressed("notes") and not get_tree().paused and p and p.mode != Player.Mode.DEAD:
			open()
			get_viewport().set_input_as_handled()
		return
	if e.is_action_pressed("ui_cancel") or e.is_action_pressed("notes"):
		close()
	elif e.is_action_pressed("left") or e.is_action_pressed("right"):
		show_section(section + (1 if e.is_action_pressed("right") else -1))
	elif (e.is_action_pressed("forward") or e.is_action_pressed("back")) and rows:
		rows[wrapi(focused() + (1 if e.is_action_pressed("back") else -1), 0, rows.size())].grab_focus()
	elif e.is_action_pressed("interact") and focused() >= 0:
		_read(focused())
	else:
		return
	get_viewport().set_input_as_handled()

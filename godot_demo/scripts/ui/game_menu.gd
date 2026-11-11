# The menus over a level, in the title menu's look (its font, the warm / dim lines, the flame mark):
#   pause  Esc (when nothing else has the game paused: notes, shop, a talk): the game stops under a dark veil.
#          Continuar (or Esc again), Controles, Carregar o jogo salvo (if there is one), Voltar ao menu, Sair do jogo.
#   death  a while after he falls (DEATH_DELAY), the screen bleeds to near black; "Morreu." and the hour, then
#          Tentar de novo (the return point: this scene as it was when he came in, SaveGame), Carregar o jogo salvo,
#          Voltar ao menu, Sair do jogo. The world goes on under it.
class_name GameMenu
extends CanvasLayer

const DEATH_DELAY := 2.0       # s after the fall: the death clip plays out first
const FADE := 1.2
const WARM := Color(0.96, 0.8, 0.5)     # = the title menu's
const DIM := Color(0.62, 0.62, 0.6)
const BONE := Color(0.86, 0.84, 0.78)
const BLOOD := Color(0.62, 0.1, 0.06)

var player: Player
var veil: ColorRect
var title: Label
var line: Label
var box: VBoxContainer
var buttons: Array[Button] = []
var controls: Control
var paused := false            # the pause menu is up
var dead := false              # the death menu is up


func _init(p: Player) -> void:
	player = p


func _ready() -> void:
	layer = 20; process_mode = Node.PROCESS_MODE_ALWAYS
	veil = ColorRect.new(); veil.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(veil)  # (anchors before entering
	var col := VBoxContainer.new(); col.set_anchors_preset(Control.PRESET_FULL_RECT); veil.add_child(col)  # the tree)
	col.alignment = BoxContainer.ALIGNMENT_CENTER; col.add_theme_constant_override("separation", 4)
	title = Label.new(); col.add_child(title); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	line = Label.new(); col.add_child(line); line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_color_override("font_color", DIM)
	var gap := Control.new(); col.add_child(gap); gap.custom_minimum_size.y = 28
	box = VBoxContainer.new(); col.add_child(box); box.add_theme_constant_override("separation", 2)
	controls = controls_panel(self)
	controls.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _show_controls(false))
	veil.visible = false
	player.died.connect(_on_died)


## Puts up the pause menu (false: back to the game).
func pause(on: bool) -> void:
	paused = on
	get_tree().paused = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_CAPTURED
	_show_controls(false)
	veil.visible = on
	if on:
		veil.color = Color(0, 0, 0, 0.62)
		var l := get_tree().get_first_node_in_group("level")
		_fill("Pausa", BONE, "teste: " + l.controls_extra if l and l.controls_extra != "" else "", [["Continuar", pause.bind(false)], ["Controles", _show_controls.bind(true)]]
			+ _saved() + [["Voltar ao menu", _to_menu], ["Sair do jogo", get_tree().quit]])


func _on_died() -> void:
	await get_tree().create_timer(DEATH_DELAY, true, false, true).timeout
	if player.mode != Player.Mode.DEAD:
		return
	dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	veil.visible = true; veil.color = Color(0.08, 0.0, 0.0, 0.0); veil.modulate.a = 0.0
	_fill("Morreu.", BLOOD, "às %s, %s" % [WorldTime.clock(), _where()], [["Tentar de novo", _retry]] + _saved()
		+ [["Voltar ao menu", _to_menu], ["Sair do jogo", get_tree().quit]])
	var tw := create_tween().set_parallel()
	tw.tween_property(veil, "color:a", 0.86, FADE); tw.tween_property(veil, "modulate:a", 1.0, FADE)


func _where() -> String:  # the level's name (Level.title)
	var l := get_tree().get_first_node_in_group("level")
	return l.title if l and l.title != "" else "Santa Clara"


func _fill(head: String, head_col: Color, sub: String, items: Array) -> void:
	title.text = head; title.add_theme_color_override("font_color", head_col)
	line.text = sub; line.visible = sub != ""
	for b in buttons:
		b.queue_free()
	buttons.clear()
	for item in items:
		var b := Button.new(); box.add_child(b); b.text = item[0]; b.flat = true
		b.add_theme_font_size_override("font_size", 24)
		for s in ["font_color", "font_pressed_color"]:
			b.add_theme_color_override(s, DIM)
		for s in ["font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(s, WARM)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(item[1]); b.mouse_entered.connect(b.grab_focus)
		b.focus_entered.connect(_mark.bind(b))
		buttons.append(b)
	buttons[0].grab_focus()


func _mark(b: Button) -> void:  # the flame mark before the chosen line, as on the title menu
	for o in buttons:
		o.text = o.text.trim_prefix("•  ")
	b.text = "•  " + b.text


func _saved() -> Array:  # the option to load the saved game, when there is one
	return [["Carregar o jogo salvo", _load_saved]] if SaveGame.exists() else []


func _retry() -> void:
	get_tree().paused = false
	SaveGame.retry(self)


func _load_saved() -> void:
	get_tree().paused = false
	SaveGame.load_saved(self)


func _to_menu() -> void:
	get_tree().paused = false
	SceneRouter.go_to(self, Paths.MENU, "", 0.6, "")


func _show_controls(on: bool) -> void:
	if controls.visible == on:
		return
	controls.visible = on
	for b in buttons:
		b.focus_mode = Control.FOCUS_NONE if on else Control.FOCUS_ALL
	if not on and buttons.size() > 1:
		buttons[1].grab_focus()


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_action_pressed("ui_cancel"):
		return
	if controls.visible:
		_show_controls(false)
	elif paused:
		pause(false)
	elif not dead and not get_tree().paused and player.mode != Player.Mode.DEAD:  # notes / shop / talk: theirs
		pause(true)
	else:
		return
	get_viewport().set_input_as_handled()


## The controls, over everything (the title menu's Controles and the pause menu's); hidden until shown.
static func controls_panel(parent: Node) -> Control:
	var p := ColorRect.new(); parent.add_child(p); p.color = Color(0, 0, 0, 0.78); p.size = Vector2(960, 600); p.visible = false
	var rows := [["WASD", "trotar"], ["Ctrl / Shift", "andar / correr"], ["Mouse", "olhar"], ["E", "interagir · armado: travar mira"],
		["1", "facão"], ["2", "besta"], ["3", "lamparina (no gancho / na mão)"], ["Q", "roda de armas (segurar) / guardar (toque)"],
		["Mouse esq.", "golpe (de novo: de cima)"], ["Mouse dir.", "erguer: bloquear / mirar (segurar)"], ["Espaço", "esquiva"], ["C", "agachar"],
		["R", "recarregar"], ["F", "curativo"], ["Tab", "caderno: tarefas, bolso, notas"], ["4", "picareta"], ["Esc", "pausa"]]
	var grid := GridContainer.new(); p.add_child(grid); grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28); grid.add_theme_constant_override("v_separation", 0)
	var head := Label.new(); p.add_child(head); head.text = "Controles"; head.position = Vector2(338, 40)
	head.add_theme_font_size_override("font_size", 36)
	head.add_theme_color_override("font_color", BONE)
	for r in rows:
		for i in 2:
			var l := Label.new(); grid.add_child(l); l.text = r[i]
			l.add_theme_color_override("font_color", WARM if i == 0 else Color(0.8, 0.78, 0.74))
			if i == 0:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; l.custom_minimum_size.x = 150
	grid.position = Vector2(160, 96)
	var back := Label.new(); p.add_child(back); back.text = "Esc  voltar"; back.position = Vector2(338, 548)
	back.add_theme_color_override("font_color", DIM)
	return p

# Title menu: the painted village behind fog that drifts, the lantern's flame breathing, wind.
# Keyboard (arrows + Enter, Esc back) or mouse. `-- --autotest` runs tests/test_menu.gd.
extends Control

const TITLE := "SANTA CLARA"
const SUBTITLE := "serra, 1974"
const LANTERN := Vector2(497, 440)  # the flame in menu_fundo.webp (1024 x 572)
const WARM := Color(0.96, 0.8, 0.5)
const DIM := Color(0.62, 0.62, 0.6)

var bg: TextureRect
var glow: TextureRect
var buttons: Array[Button] = []
var controls: Control
var started := false
var _t := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(PRESET_FULL_RECT)
	var art: Texture2D = load(Paths.UI % "menu_fundo.webp")
	bg = TextureRect.new(); add_child(bg); bg.texture = art
	bg.size = Vector2(960, 600); bg.pivot_offset = bg.size / 2
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE)  # a slow breath in and out
	tw.tween_property(bg, "scale", Vector2.ONE * 1.05, 24.0); tw.tween_property(bg, "scale", Vector2.ONE, 24.0)

	# the flame's glow rides on the painting (child of bg, so it follows the zoom)
	var k := maxf(960.0 / art.get_width(), 600.0 / art.get_height())
	var at := LANTERN * k - (Vector2(art.get_width(), art.get_height()) * k - bg.size) / 2
	var g := Gradient.new(); g.set_color(0, Color(1.0, 0.75, 0.4, 0.55)); g.set_color(1, Color(1.0, 0.6, 0.3, 0.0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(0.5, 0.0); gt.width = 128; gt.height = 128
	glow = TextureRect.new(); bg.add_child(glow); glow.texture = gt
	glow.size = Vector2(170, 170); glow.position = at - glow.size / 2; glow.pivot_offset = glow.size / 2
	var add := CanvasItemMaterial.new(); add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD; glow.material = add

	var fog := ColorRect.new(); add_child(fog); fog.size = bg.size; fog.mouse_filter = MOUSE_FILTER_IGNORE
	var sh := ShaderMaterial.new(); sh.shader = Paths.shader("menu_neblina")
	var nz := NoiseTexture2D.new(); nz.seamless = true; nz.width = 256; nz.height = 256
	nz.noise = FastNoiseLite.new(); nz.noise.frequency = 0.012
	sh.set_shader_parameter("noise", nz); fog.material = sh

	_shade(0, 150, 0.75, true)    # sky darkened under the title
	_shade(430, 170, 0.8, false)  # ground darkened under the options

	var title := _label(TITLE, Paths.UI % "fonts/santa_clara.fnt", 48, Color(0.86, 0.84, 0.78))
	title.position = Vector2(42, 24)
	var sub := _label(SUBTITLE, Paths.UI % "fonts/santa_clara.fnt", 24, Color(0.7, 0.66, 0.6))
	sub.position = Vector2(46, 84)

	var box := VBoxContainer.new(); add_child(box); box.alignment = BoxContainer.ALIGNMENT_END
	box.size = Vector2(240, 110); box.position = Vector2(960 - 240 - 42, 600 - 110 - 26)
	box.add_theme_constant_override("separation", 2)
	for item in [["Novo jogo", _start], ["Controles", _show_controls.bind(true)], ["Sair", get_tree().quit]]:
		var b := Button.new(); box.add_child(b); b.text = item[0]; b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.add_theme_font_size_override("font_size", 24)  # the game font (tema.tres), at 2x
		for s in ["font_color", "font_pressed_color"]:
			b.add_theme_color_override(s, DIM)
		for s in ["font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(s, WARM)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(item[1]); b.mouse_entered.connect(b.grab_focus)
		b.focus_entered.connect(_mark.bind(b))
		buttons.append(b)
	buttons[0].grab_focus.call_deferred()

	controls = _controls_panel()
	var wind := AudioStreamPlayer.new(); add_child(wind)
	wind.stream = Audio.sfx("vento", true); wind.volume_db = -10.0; wind.play()
	if SceneRouter.testing():
		AutoTest.attach(self)


func _shade(y: float, h: float, a: float, down: bool) -> void:
	var g := Gradient.new(); g.set_color(0, Color(0, 0, 0, a if down else 0.0)); g.set_color(1, Color(0, 0, 0, 0.0 if down else a))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill_from = Vector2(0, 0); gt.fill_to = Vector2(0, 1)
	var r := TextureRect.new(); add_child(r); r.texture = gt; r.mouse_filter = MOUSE_FILTER_IGNORE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; r.position = Vector2(0, y); r.size = Vector2(960, h)


func _label(text: String, font: String, sz: int, col: Color) -> Label:
	var l := Label.new(); add_child(l); l.text = text
	l.add_theme_font_override("font", load(font)); l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8)); l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _mark(b: Button) -> void:  # a small flame mark before the chosen line
	for o in buttons:
		o.text = o.text.trim_prefix("•  ")
	b.text = "•  " + b.text


func _process(delta: float) -> void:
	_t += delta  # the flame: a slow breath plus a little nervous flicker
	var f := 0.82 + 0.1 * sin(_t * 2.1) + 0.08 * sin(_t * 11.0 + sin(_t * 3.7) * 2.0)
	glow.modulate.a = f; glow.scale = Vector2.ONE * (0.94 + 0.08 * f)


func _controls_panel() -> Control:
	var p := ColorRect.new(); add_child(p); p.color = Color(0, 0, 0, 0.78); p.size = Vector2(960, 600); p.visible = false
	var rows := [["WASD", "trotar"], ["Ctrl", "andar"], ["Shift", "correr"], ["Mouse", "olhar"], ["E", "entrar / interagir"],
		["L", "guardar / acender a lamparina"], ["F", "sacar / guardar a faca"], ["Botão esquerdo", "golpe"],
		["Botão direito", "golpe de cima"], ["Espaço", "esquiva"], ["C", "agachar"], ["Q", "besta"], ["R", "recarregar"], ["Tab", "notas"]]
	var grid := GridContainer.new(); p.add_child(grid); grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28); grid.add_theme_constant_override("v_separation", 0)
	var head := Label.new(); p.add_child(head); head.text = "Controles"; head.position = Vector2(338, 50)
	head.add_theme_font_size_override("font_size", 36)
	head.add_theme_color_override("font_color", Color(0.86, 0.84, 0.78))
	for r in rows:
		for i in 2:
			var l := Label.new(); grid.add_child(l); l.text = r[i]
			l.add_theme_color_override("font_color", WARM if i == 0 else Color(0.8, 0.78, 0.74))
			if i == 0:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; l.custom_minimum_size.x = 150
	grid.position = Vector2(160, 108)
	p.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _show_controls(false))
	var back := Label.new(); p.add_child(back); back.text = "Esc  voltar"; back.position = Vector2(338, 532)
	back.add_theme_color_override("font_color", DIM)
	return p


func _show_controls(on: bool) -> void:
	controls.visible = on
	for b in buttons:
		b.focus_mode = FOCUS_NONE if on else FOCUS_ALL
	if not on:
		buttons[1].grab_focus()


func _unhandled_input(e: InputEvent) -> void:
	if controls.visible and (e.is_action_pressed("ui_cancel") or e.is_action_pressed("ui_accept")):
		_show_controls(false); get_viewport().set_input_as_handled()


func _start() -> void:  # the bell, a slow fade, and the village opens from black (no door creak)
	if started:
		return
	started = true
	for b in buttons:
		b.disabled = true
	if not SceneRouter.testing():
		Audio.play2d(self, "sino", -6.0)
	SceneRouter.go_to(self, Paths.VILAREJO, "", 1.6, "")

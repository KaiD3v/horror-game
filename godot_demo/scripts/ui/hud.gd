# What is on screen over the game, for every level: the controls line, the crosshair (crossbow up), the prompt of
# whatever you can use, short messages (say), the body's state at the screen's edges instead of bars
# (visao.gdshader: hurt and tired), the death line, and the fade in from black after a scene change.
class_name Hud
extends CanvasLayer

const CONTROLS := "WASD trotar · Ctrl andar · Shift correr · L lamparina · E usar · F facão · LMB/RMB golpes · Espaço esquiva (+A/D lateral) · C agachar · Q besta · R recarregar · Tab notas"
const DEATH := "Morreu. Enter para recomeçar."

var player: Player
var legend: Label
var crosshair: Label
var prompt: Label
var message: Label
var vision: ColorRect
var _message_t := 0.0


func _init(p: Player, title: String, extra := "") -> void:
	player = p
	_build(title + " · " + CONTROLS + (" · " + extra if extra != "" else ""))


func _build(controls: String) -> void:
	vision = ColorRect.new(); add_child(vision); vision.set_anchors_preset(Control.PRESET_FULL_RECT)
	vision.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vision.material = ShaderMaterial.new(); vision.material.shader = Paths.shader("visao")
	legend = Label.new(); add_child(legend); legend.position = Vector2(10, 8); legend.text = controls
	legend.add_theme_font_size_override("font_size", 12)  # the game font at 1x: the controls line fits
	crosshair = _centred("+", 0.48); crosshair.visible = false
	message = _centred("", 0.83); message.visible = false
	prompt = _centred("", 0.88); prompt.visible = false


func _centred(t: String, at: float) -> Label:  # a line across the screen, at a fraction of its height
	var l := Label.new(); add_child(l); l.text = t
	l.set_anchors_preset(Control.PRESET_TOP_WIDE); l.anchor_top = at; l.anchor_bottom = at; l.offset_top = -14
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _ready() -> void:
	player.died.connect(func(): legend.text = DEATH; legend.add_theme_font_size_override("font_size", 24))
	var arrival := SceneRouter.take_arrival()
	if arrival[0]:  # came through a door: it creaks and shuts behind you
		if arrival[1] != "":
			Audio.play2d(self, arrival[1], -4.0)
		var black := ColorRect.new(); black.color = Color.BLACK; black.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(black)
		var tw := create_tween(); tw.tween_property(black, "color:a", 0.0, 0.35); tw.tween_callback(black.queue_free)


func set_prompt(t: String) -> void:
	prompt.visible = t != ""; prompt.text = t


func say(t: String, seconds := 3.5) -> void:
	message.text = t; _message_t = seconds


func _process(delta: float) -> void:
	_message_t -= delta
	message.visible = _message_t > 0.0
	crosshair.visible = player.mode == Player.Mode.XBOW and player.action == ""
	var c: PlayerCondition = player.condition
	vision.visible = c.wound > 0.0 or c.tired > 0.0  # (no screen copy while he is fine)
	vision.material.set_shader_parameter("hurt", c.wound)
	vision.material.set_shader_parameter("tired", c.tired)

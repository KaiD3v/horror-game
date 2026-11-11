# What is on screen over the game, for every level: the controls line, the crosshair (crossbow up), the prompt of
# whatever you can use, short messages (say), the body's state at the screen's edges (visao.gdshader: hurt and
# tired), the hearts / breath / what he carries in the corners when they change (HudStatus) and the fade in from
# black after a scene change. (Dying: GameMenu.)
class_name Hud
extends CanvasLayer

const CONTROLS := "WASD trotar · Ctrl andar · Shift correr · E usar · 1 facão · 2 besta · 3 lamparina · 4 picareta · Q roda (toque: guardar) · LMB golpe (2x: de cima) · RMB erguer (bloquear / mirar) · E travar mira · Espaço esquiva (+A/D lateral) · C agachar · R recarregar · F curativo · Tab caderno"

var player: Player
var legend: Label
var crosshair: Label
var status: HudStatus  # hearts, breath, ammo and counts, shown when they matter
var prompt: Label
var message: Label
var vision: ColorRect
var lock_mark: Control  # over the enemy the camera is locked on (E)
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
	status = HudStatus.new(player); add_child(status)
	message = _centred("", 0.83); message.visible = false
	prompt = _centred("", 0.88); prompt.visible = false
	lock_mark = Control.new(); add_child(lock_mark); lock_mark.visible = false
	lock_mark.draw.connect(func():  # a hollow diamond, blood red, hard pixels
		var d := PackedVector2Array([Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0), Vector2(0, -7)])
		lock_mark.draw_polyline(d, Color(0, 0, 0, 0.7), 4.0)
		lock_mark.draw_polyline(d, Color(0.78, 0.16, 0.1), 2.0))


func _centred(t: String, at: float) -> Label:  # a line across the screen, at a fraction of its height
	var l := Label.new(); add_child(l); l.text = t
	l.set_anchors_preset(Control.PRESET_TOP_WIDE); l.anchor_top = at; l.anchor_bottom = at; l.offset_top = -14
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _ready() -> void:
	player.died.connect(func(): legend.visible = false)
	player.notice.connect(say.bind(2.5))
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
	crosshair.visible = player.aiming and player.action == ""
	var at := Vector3.ZERO if player.lock == null else player.lock.global_position + Vector3(0, 2.25, 0)
	lock_mark.visible = player.lock != null and not player.cam.is_position_behind(at)
	if lock_mark.visible:
		lock_mark.position = player.cam.unproject_position(at).round()
	var c: PlayerCondition = player.condition
	vision.visible = c.wound > 0.0 or c.tired > 0.0  # (no screen copy while he is fine)
	vision.material.set_shader_parameter("hurt", c.wound)
	vision.material.set_shader_parameter("tired", c.tired)

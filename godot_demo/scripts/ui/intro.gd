# The arrival, the opening's last act (../docs/INTRODUCAO.md), played in the village once Abertura (the memory in the
# parlatório, the letter in São Paulo, the night bus) hands over: the bus that leaves him where the line ends, the
# fallen bridge and its sawn beams, down into the ravine and up the far side, the beam that gives way behind him, the
# village and the Colônia's light; then the game, with the task "Subir à Colônia". Skipped (here or in Abertura),
# straight to that same end. vilarejo.gd plays it when `pending` (set by the menu's "Novo jogo").
class_name Intro
extends Cutscene

signal finished

static var pending := false    # a new game asked for it (Story "intro:vista" once seen)
static var skip_next := false  # Abertura was skipped: skip this too

const NOTES := ["carta_mae", "obito", "foto", "recorte"]  # what Abertura showed: kept in the notebook
const BEAM_TOP := Vector2(-2.6, 47.4)   # the loose beam (vilarejo GLB ponte_viga_solta: narrativa.loose_beam), x, z
const BEAM_FOOT := Vector2(-2.6, 50.3)

var L                         # the village (vilarejo.gd)
var player: Player
var lights: Node3D            # the bus's headlights
var lit: Array[ShaderMaterial] = []  # the Colônia's lit windows (vilarejo.gd haze, light = 1), that flicker


func _init(level: Node) -> void:
	super(level)
	L = level; player = level.player


## The whole of it, then the game. Skipping cuts to the same end.
func run() -> void:
	pending = false
	skipped = skip_next; skip_next = false
	player.busy = true; L.hud.visible = false; L.menu.set_process_unhandled_input(false)
	for m: ShaderMaterial in L.haze:
		if m.get_shader_parameter("light") == 1.0:
			lit.append(m)
	await play([_dated, _bus, _sawn, _crossing, _gave_way, _village, _handover])
	_finish()


# --- the shots ----------------------------------------------------------------------------------------------------
func _dated() -> void:  # 1. black: the day he gets there
	_put(L.ground(0.4, 60.0), PI)  # (off screen: on the road south of the ravine, looking back at the bus)
	say("28 de março de 1974 · Serra de Santa Clara")
	await wait(3.0)
	say("")


func _bus() -> void:  # 2. dawn on the road; the bus that brought him turns back into the fog
	var g: Vector3 = player.global_position
	lights = Node3D.new(); L.add_child(lights); lights.position = Vector3(0.3, g.y + 1.1, 66.0)
	for sx in [-0.9, 0.9]:
		var s := SpotLight3D.new(); lights.add_child(s); s.position.x = sx; s.light_color = Color(1.0, 0.85, 0.6)
		s.light_energy = 6.0; s.spot_range = 30.0; s.spot_angle = 28.0  # pointing north, -z
		var lamp := OmniLight3D.new(); lights.add_child(lamp); lamp.position = Vector3(sx, 0, -0.2)
		lamp.light_color = s.light_color; lamp.light_energy = 1.5; lamp.omni_range = 1.5
	look(Vector3(2.2, g.y + 1.5, 57.0), g + Vector3(0, 1.3, 2.0))
	Audio.play3d(lights, "caminhao_partindo", Vector3.ZERO, 4.0, false, 6.0, 120.0)
	fade(0.0, 2.0)
	await wait(1.5)
	say("— Pra Santa Clara não tem mais linha. O senhor desce aqui.")
	await wait(3.5)
	say("")
	var t := tw().set_parallel()
	t.tween_property(lights, "position:z", 95.0, 5.0).set_ease(Tween.EASE_IN)
	for l in lights.get_children():
		if l is Light3D:
			t.tween_property(l, "light_energy", 0.0, 5.0)
	await wait(1.5)
	tw().tween_property(player, "rotation:y", 0.0, 1.2)  # he turns to the road ahead
	await wait(1.5)


func _sawn() -> void:  # 3. to the brink: the bridge is down, its beams sawn through
	var g: Vector3 = player.global_position
	look(Vector3(-3.6, g.y + 1.5, 56.6), Vector3(-0.4, g.y + 1.0, 60.0))  # from the brink, him coming to it
	await _walk(Vector3(-1.1, 0, 56.7))  # to the brink over the abutment (the ravine drops from z = 56.1)
	await wait(0.4)
	var stub: Vector3 = L.marker("intro_serrado").global_position  # a stub on the south abutment, its cut face north
	var spill := OmniLight3D.new(); L.add_child(spill); spill.global_position = stub + Vector3(0.1, 0.5, -0.4)  # (the lantern's, helped)
	spill.light_color = Color(1.0, 0.7, 0.4); spill.light_energy = 1.2; spill.omni_range = 2.0
	look(stub + Vector3(0.6, 0.25, -1.0), stub)
	Audio.play2d(self, "impacto_grave", -9.0)  # sawn, not broken
	await wait(3.0)
	spill.queue_free()


func _crossing() -> void:  # 4. down over the brink... and, a cut later, up out of it on the far side
	var brink: Vector3 = L.ground(-2.6, 56.4)
	_put(brink, PI)  # his back to the drop
	look(brink + Vector3(-4.2, 0.6, -1.0), brink + Vector3(0, -0.4, -0.6))
	player.play("Climb_Ledge", true)
	tw().tween_property(player, "global_position", brink + Vector3(0, -1.25, -0.4), player.action_len)
	await wait(player.action_len + 0.2)
	await cut()
	var top: Vector3 = L.ground(-2.6, 46.75)
	_put(top - Vector3(0, 1.25, -0.35), 0.0)
	look(top + Vector3(1.8, 0.4, 2.6), top + Vector3(0, 0.2, 0))
	player.play("Climb_Ledge")
	tw().tween_property(player, "global_position", top, player.action_len).set_trans(Tween.TRANS_SINE)
	await wait(player.action_len + 0.2)


func _gave_way() -> void:  # 5. the beam he came up gives way behind him: no way back
	var beam: Node3D = L.marker("ponte_viga_solta")
	Audio.play3d(beam, "viga_cedendo", Vector3(0, -2, 1), 4.0, false, 4.0, 60.0)
	var p := player.global_position  # from down in the ravine, looking up: him on the brink, the beam leaning below him
	look(p + Vector3(-1.8, -1.7, 3.5), p + Vector3(0, 0.9, 0))
	await wait(0.7)
	var to: Transform3D = fallen(L)
	var t := tw().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(beam, "global_position", to.origin, 1.1)
	t.tween_property(beam, "quaternion", to.basis.get_rotation_quaternion(), 1.1)
	await wait(1.2)
	tw().tween_property(player, "rotation:y", PI, 0.8)  # he looks back at it
	await wait(2.2)
	tw().tween_property(player, "rotation:y", 0.0, 0.8)
	await wait(0.9)


func _village() -> void:  # 6. up behind him: the roofs in the fog; the bell; the title; up there a light goes out
	var p: Vector3 = player.global_position
	look(p + Vector3(0.0, 1.8, 1.6), p + Vector3(0, 1.6, -6.0))
	var t := cam_tw().set_parallel().set_trans(Tween.TRANS_SINE)
	t.tween_property(cam, "global_position", p + Vector3(0, 7.0, 3.5), 6.0)
	t.tween_method(func(k: float): cam.look_at(p + Vector3(0, 1.6 + 8.0 * k, -6.0 - 40.0 * k)), 0.0, 1.0, 6.0)
	await wait(2.5)
	Audio.play2d(self, "sino", -8.0)
	title.text = "SANTA CLARA"
	tw().tween_property(title, "modulate:a", 1.0, 1.5)
	await wait(3.0)
	_flicker()  # someone up there
	Audio.play2d(self, "impacto_grave", -10.0)
	Audio.music_stop(5.0)
	await wait(1.5)
	tw().tween_property(title, "modulate:a", 0.0, 1.2)
	await wait(1.3)


func _flicker() -> void:  # the Colônia's lit windows go dark, come back, dark, back
	for m in lit:
		var t := tw()
		for v in [0.0, 1.0, 0.0, 1.0]:
			t.tween_property(m, "shader_parameter/light", v, 0.01)
			t.tween_interval(0.18 if v == 0.0 else 0.12)


func _handover() -> void:  # 7. down to where the game's camera sits
	var at: Transform3D = L._player_start()
	_put(at.origin - Vector3(0, 0.3, 0), at.basis.get_euler().y)
	player.pivot.rotation.y = player.rotation.y
	await wait(0.1)
	cam_tw().set_trans(Tween.TRANS_SINE).tween_property(cam, "global_transform", player.cam.global_transform, 1.5)
	await wait(1.6)


# --- the end, played or skipped -----------------------------------------------------------------------------------
func _finish() -> void:
	Audio.music_stop(1.5)  # (already fading, played through; skipped, it goes now)
	if is_instance_valid(lights):
		lights.queue_free()
	for m in lit:  # (a skip mid-flicker: lit again)
		m.set_shader_parameter("light", 1.0)
	for id in NOTES:
		if id not in NotesReader.read:
			NotesReader.read.append(id)
	var beam: Node3D = L.marker("ponte_viga_solta"); beam.global_transform = fallen(L)
	var at: Transform3D = L._player_start()
	player.walk_to = Vector3.INF; player.velocity = Vector3.ZERO; player.stop_action()
	player.global_transform = at; player.pivot.rotation.y = at.basis.get_euler().y
	player.busy = false
	player.cam.make_current(); cam.queue_free()
	L.hud.visible = true; L.menu.set_process_unhandled_input(true)
	Story.mark("intro:vista")
	Story.set_task("colonia", "ativa")
	player.notice.emit("Nova tarefa: %s" % QuestData.title("colonia"))
	finished.emit()
	queue_free()


## Where the loose beam lies once it has fallen: along the bottom of the ravine, westwards, half in the water.
## (Its origin is its top end; standing, it leans from the north brink down to the water: narrativa.loose_beam.)
static func fallen(level: Node) -> Transform3D:
	var top: Vector3 = level.ground(BEAM_TOP.x, BEAM_TOP.y) - Vector3(0, 0.15, 0)
	var foot: Vector3 = level.ground(BEAM_FOOT.x, BEAM_FOOT.y) + Vector3(0, 0.1, 0)
	var q := Quaternion((foot - top).normalized(), Vector3(-1.0, 0.06, 0.15).normalized())
	return Transform3D(Basis(q), level.ground(-2.4, 51.2) + Vector3(0, 0.12, 0))


# --- him ----------------------------------------------------------------------------------------------------------
func _put(at: Vector3, yaw: float) -> void:
	player.global_position = at + Vector3(0, 0.05, 0); player.rotation.y = yaw; player.velocity = Vector3.ZERO
	player.pivot.global_position = at + Vector3(0, 1.55, 0); player.coat.reset()


## Walk him to `to` (x, z; at walk pace, the usual steps); back when there, or after 12 s, or skipped.
func _walk(to: Vector3) -> void:
	player.walk_to = Vector3(to.x, player.global_position.y, to.z)
	var t := 0.0
	while not skipped and t < 12.0 and Vector2(player.global_position.x - to.x, player.global_position.z - to.z).length() > 0.25:
		await get_tree().process_frame
		t += get_process_delta_time()
	player.walk_to = Vector3.INF

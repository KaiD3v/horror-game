# The player's footsteps: a step every stride on the floor kind (terra, madeira, ladrilho: sounds passo_<kind>_1-4),
# quieter crouched, heavier running.
class_name Footsteps
extends Node

var player: Player
var kind := "terra"
var steps := 0            # footsteps played (autotest)
var _stride := 0.0
var _sound: AudioStreamPlayer


func _init(p: Player, floor_kind: String) -> void:
	player = p; kind = floor_kind


func _ready() -> void:
	_sound = AudioStreamPlayer.new(); add_child(_sound)


func _process(delta: float) -> void:
	if not player.is_on_floor():
		return
	var v := Vector2(player.velocity.x, player.velocity.z).length()
	if v < 0.3:
		_stride = 0.0
		return
	_stride += v * delta
	if _stride >= clamp(v * 0.42, 0.45, 0.95):  # one step every ~0.4 s of travel: walk, jog, sprint
		_stride = 0.0; steps += 1
		_sound.stream = Audio.sfx("passo_%s_%d" % [kind, randi_range(1, 4)])
		_sound.pitch_scale = randf_range(0.9, 1.1)
		_sound.volume_db = -16.0 if player.crouched else (-5.0 if v > 1.5 else -8.0)
		_sound.play()

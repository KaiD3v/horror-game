# A Enfermeira (models/characters/enfermeira.glb, ../tools/personagens/enfermeira_build.py): tall, thin, silent. She
# only moves while nobody is looking at her. In the player's view and lit, she freezes mid-step. The lantern in hand
# lights her up to 9 m; hung on the belt, or with the machete or crossbow out, only 4 m. Looked away from, she glides
# up from behind, faster than a jog. No footsteps: the keys and scissors at her waist tinkle while she moves, and she
# breathes on the player's neck before the stab. Seen up close, she stabs anyway. Too tall for the low doors.
class_name Enfermeira
extends Enemy

const HUNT := 14.0           # she starts stalking you inside this distance, sight or no sight
const LIT := 9.0             # how far you can see her: lantern in hand / anything else
const DIM := 4.0
const LUNGE := 1.5           # looked at but this close: she strikes anyway
const BREATH := 2.6          # the breath on your neck, from this close behind

var seen := false
var moving := false
var chain: AudioStreamPlayer3D
var breath_cd := 0.0


func _init() -> void:
	model_name = "enfermeira"; body_radius = 0.3
	max_health = 4                          # machete slash 1, overhead 2, bolt 3
	speed = 2.2; stride = 2.1               # jog is 1.66, sprint 2.6: you cannot outwalk her without looking back
	attack_range = 1.2; attack_reach = 1.7; attack_hit = 13.0 / 30.0
	attack_cooldown = 1.4                   # after a stab she stands still a moment: your window to hit back
	attack_track = 0.6


func _ready() -> void:
	super()
	chain = Audio.play3d(self, "tilintar", Vector3(0, 1.0, 0), -80.0, true, 2.0, 18.0)


func _physics_process(delta: float) -> void:
	moving = false
	super(delta)
	breath_cd = max(0.0, breath_cd - delta)
	chain.volume_db = move_toward(chain.volume_db, -4.0 if moving else -80.0, 160.0 * delta)  # stops dead with her


func _decide(to: Vector3, dist: float, delta: float) -> void:
	seen = _observed()
	match state:
		State.IDLE:
			if dist < HUNT and not seen:
				go(State.CHASE, "Walk", 0.3)
		State.CHASE:
			if seen:
				ap.speed_scale = 0.0  # a statue, caught mid-step
				if dist < LUNGE and cooldown == 0.0:
					go(State.ATTACK, "Attack", 0.1)
			elif dist <= attack_range:
				if cooldown == 0.0:
					go(State.ATTACK, "Attack", 0.15)
				else:
					ap.speed_scale = 0.0
			else:
				ap.speed_scale = 1.0
				_face(to if dist < 2.0 else _route(_behind(), to), delta * 2.0)
				walk_forward(); moving = true
				if dist < BREATH and breath_cd == 0.0:
					breath_cd = 7.0
					Audio.play3d(self, "sopro", Vector3(0, 1.9, 0), 0.0, false, 1.5)


## The spot just behind the camera: she comes up from behind.
func _behind() -> Vector3:
	var back: Vector3 = target.cam.global_basis.z; back.y = 0
	return target.global_position + back.normalized() * 0.9


func _observed() -> bool:
	var cam: Camera3D = target.get("cam")
	var p := global_position + Vector3(0, 1.2, 0)
	if cam == null or not cam.is_position_in_frustum(p):
		return false
	var lantern_in_hand: bool = target.holds_lantern()
	if cam.global_position.distance_to(p) > (LIT if lantern_in_hand else DIM):
		return false
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, p, 1, [get_rid(), target.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

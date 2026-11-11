# O Poceiro (models/characters/poceiro.glb, ../tools/personagens/poceiro_build.py; ../docs/MUTANTES_NOITE.md): the
# blind well-digger. At nightfall he hauls himself out of the square's well; at dawn he climbs back down. He hunts by
# ear alone: no sight, no light. Each frame he hears the player as far as the noise they make (HEAR): a sprint
# carries, a crouch hardly at all, a blow or a shot rings out. He roars and goes to where the sound was, not to you:
# keep still and quiet and he stops there, listens, and wanders back. Within arm's reach he feels you anyway, and
# his two-fisted blow takes 2. A hit tells him where you are. The chapel bell draws him to the church (hear()).
# Slow, huge, hard to kill (10): better to slip past than to fight. The bucket at his hip clanks as he walks.
class_name Poceiro
extends Enemy

# how far off the player is heard, by what they are doing
const HEAR := {"sprint": 16.0, "jog": 9.0, "walk": 4.0, "sneak": 1.5, "still": 1.2, "fight": 14.0}
const LOUD := ["Attack_Slash", "Attack_Overhead", "Shoot_Crossbow", "Block_Hit", "Hit_React", "Dodge_Back",
	"Dodge_Left", "Dodge_Right"]
const ROAM := 8.0            # he wanders this far round the well
const ROAM_SPEED := 0.9
const LISTEN := 3.0          # seconds he stands listening where the sound was

var mouth: Vector3           # the well's mouth and the spot beside it he steps out to (vilarejo.gd)
var beside: Vector3
var heard_at := Vector3.INF  # the sound he is going to
var fresh := false           # a new sound since he last decided
var heard_t := 99.0          # seconds since he last heard the player himself
var listening := 0.0
var roam_to := Vector3.INF
var pause := 2.0
var going_home := false
var bucket: AudioStreamPlayer3D


func _init() -> void:
	model_name = "poceiro"; body_radius = 0.4
	max_health = 10                          # machete slash 1, overhead 2, bolt 3
	speed = 1.9; stride = 1.68               # faster than a jog (1.66), slower than a sprint (2.6)
	turn_speed = 3.0
	attack_range = 1.6; attack_reach = 2.2; attack_hit = 20.0 / 30.0
	attack_cooldown = 1.5; attack_track = 0.4; attack_damage = 2
	step_length = 0.9
	voice = {"idle": "poceiro_respira", "alert": "poceiro_rugido", "attack": "poceiro_rugido", "hurt": "poceiro_rugido",
		"death": "poceiro_queda", "step": "mutante_passo"}


func _ready() -> void:
	super()
	bucket = Audio.play3d(self, "poceiro_balde", Vector3(-0.3, 0.8, 0), -80.0, true, 3.0, 28.0)


## Up out of the well (from below its mouth) and out beside it.
func emerge(well_mouth: Vector3, out: Vector3) -> void:
	mouth = well_mouth; beside = out
	global_position = mouth - Vector3(0, 2.4, 0)
	var flat := out - mouth; flat.y = 0
	rotation.y = atan2(-flat.x, -flat.z)
	Audio.play3d(get_parent(), "poceiro_agua", mouth, 2.0, false, 4.0, 40.0)
	travel(mouth, func(): travel(beside, _stood_up, "Walk", 0.6, 2.0), "Climb", 0.0, 0.9)


func _stood_up() -> void:
	go(State.IDLE, "Idle", 0.3); pause = 3.0


## Dawn: back to the well and down it.
func go_home() -> void:
	if state != State.DEAD:
		going_home = true
		if state == State.IDLE or state == State.ALERT:
			go(State.CHASE, "Walk", 0.3)


## A sound at `at` (the player's noise, a hit, the chapel bell): he goes to it.
func hear(at: Vector3) -> void:
	heard_at = at; fresh = true


func take_hit(n: int) -> void:
	if target:
		hear(target.global_position); heard_t = 0.0
	super(n)


func _physics_process(delta: float) -> void:
	var moving := not flight.is_empty() or Vector2(velocity.x, velocity.z).length() > 0.3
	bucket.volume_db = move_toward(bucket.volume_db, -4.0 if moving and state != State.DEAD else -80.0, 120.0 * delta)
	super(delta)


## How far off the player can be heard right now.
func noise() -> float:
	var p: Player = target
	if p.mode == Player.Mode.DEAD:
		return 0.0
	if p.action in LOUD:
		return HEAR.fight
	var v := Vector2(p.velocity.x, p.velocity.z).length()
	if v > Player.JOG_SPEED + 0.2:
		return HEAR.sprint
	if p.mode == Player.Mode.CROUCH:
		return HEAR.sneak if v > 0.1 else HEAR.still
	if v > Player.WALK_SPEED + 0.15:
		return HEAR.jog
	return HEAR.walk if v > 0.1 else HEAR.still


func _decide(to: Vector3, dist: float, delta: float) -> void:
	heard_t += delta
	if dist < noise():
		hear(target.global_position); heard_t = 0.0
	if going_home:
		_home(delta); return
	match state:
		State.IDLE:
			if fresh:
				fresh = false; roam_to = Vector3.INF
				go(State.ALERT, "Listen", 0.2)  # the roar, the head swings to it
			elif listening > 0.0:
				listening -= delta
			else:
				_roam(delta)
		State.ALERT:
			var d := heard_at - global_position; d.y = 0
			_face(d, delta)
			if t >= 1.2:
				go(State.CHASE, "Walk", 0.3)
		State.CHASE:
			fresh = false
			if heard_t < 1.0 and dist <= attack_range and cooldown == 0.0:
				go(State.ATTACK, "Attack", 0.15); return
			var d := heard_at - global_position; d.y = 0
			if heard_at == Vector3.INF or d.length() < 1.0:  # there, and nothing more: he stops and listens
				heard_at = Vector3.INF; listening = LISTEN
				go(State.IDLE, "Listen", 0.3); ap.queue("Idle")
			else:
				_face(d if d.length() < 2.0 else _route(heard_at, d), delta)
				walk_forward()


func _roam(delta: float) -> void:  # slow turns round the well, stopping to listen
	if pause > 0.0:
		pause -= delta; return
	if roam_to == Vector3.INF:
		var a := randf() * TAU
		roam_to = _on_nav(mouth + Vector3(cos(a), 0, sin(a)) * randf_range(2.5, ROAM))
		ap.play("Walk", 0.3, ROAM_SPEED / stride)
	var d := roam_to - global_position; d.y = 0
	if d.length() < 0.6:
		roam_to = Vector3.INF; pause = randf_range(4.0, 8.0); ap.play("Idle", 0.4); return
	_face(_route(roam_to, d), delta)
	var fwd := -global_basis.z
	velocity.x = fwd.x * ROAM_SPEED; velocity.z = fwd.z * ROAM_SPEED


func _home(delta: float) -> void:
	var d := beside - global_position; d.y = 0
	if d.length() < 0.7:
		travel(mouth, func(): travel(mouth - Vector3(0, 2.6, 0), queue_free, "Climb", 0.0, 0.9), "Walk", 0.6, 2.0)
		Audio.play3d(get_parent(), "poceiro_agua", mouth, 2.0, false, 4.0, 40.0)
		return
	if state != State.CHASE:
		go(State.CHASE, "Walk", 0.3)
	_face(_route(beside, d), delta)
	walk_forward()

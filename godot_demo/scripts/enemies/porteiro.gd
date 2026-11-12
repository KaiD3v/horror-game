# O Porteiro (models/characters/porteiro.glb, ../tools/personagens/porteiro_build.py; ../docs/CHAVE_DO_PORTAO.md): the
# village's last fight, in the crypt under the Moura mausoleum (jazigo.gd). Severino, the Colônia's gatekeeper, grown
# huge on the doctor's serum, the ring of keys in his fist, a lantern on his chest. He waits (phase 0) until you come
# down; then three phases, each asking for what the village taught:
#   1  the round (HEALTH to P2): he walks at you and swings the keys. The side swing ("Attack") the machete can block;
#      the smash from above ("Smash", the keys raised and jangling first) goes through any block (pierce): dodge it.
#      After the smash the keys are stuck in the floor for a moment: the window for a combo.
#   2  the wall (P2 to P3): he leaps up onto the altar and throws gravestone chunks ("Throw"), one every THROW_EVERY s;
#      up there only bolts reach him (the lantern on his chest is what they hit); the columns stop the stones.
#   3  the dark (P3 to 0): the lantern broken, he puts the candles out (the arena does it on phase_changed) and hunts as
#      the night mutants do: the lantern in your hand he runs at; in the dark he hears you (as O Poceiro, noise()).
#      A blow from behind does BACK times the harm.
# Takes no stagger from the machete (only from bolts and from behind). Dies on his knees, the keys out of his hand.
class_name Porteiro
extends Enemy

signal phase_changed(n: int)
signal died

const HEALTH := 30
const P2 := 20                 # health at which he takes to the altar...
const P3 := 10                 # ...and at which his lantern breaks
const THROW_EVERY := 3.0
const SMASH_HIT := 28.0 / 30.0
const SMASH_FREE := 56.0 / 30.0   # the keys out of the floor again
const THROW_AT := 22.0 / 30.0
const BACK := 3                # harm from behind
const HEAR := {"sprint": 14.0, "jog": 8.0, "walk": 3.5, "sneak": 1.3, "still": 1.0, "fight": 12.0}
const LOUD := ["Attack_Slash", "Attack_Overhead", "Shoot_Crossbow", "Block_Hit", "Hit_React", "Dodge_Back",
	"Dodge_Left", "Dodge_Right"]
const DARK_SPEED := 2.1        # after a light in the dark: faster than a jog, slower than a sprint

var phase := 0
var blow := "Attack"
var swings := 0
var altar := Vector3.INF       # where he stands up on the altar (the arena's marker)
var below := Vector3.INF       # where he lands coming down off it
var throw_in := THROW_EVERY
var heard_at := Vector3.INF
var lamp: OmniLight3D
var lamp_on := true


func _init() -> void:
	model_name = "porteiro"; body_radius = 0.45
	max_health = HEALTH
	speed = 1.5; stride = 0.955; turn_speed = 3.0
	attack_range = 1.9; attack_reach = 2.5; attack_hit = 18.0 / 30.0
	attack_cooldown = 0.9; attack_track = 0.5; attack_damage = 1
	step_length = 0.95
	voice = {"idle": "porteiro_gemido", "alert": "porteiro_rugido", "hurt": "porteiro_gemido", "death": "porteiro_queda",
		"step": "porteiro_chaves"}


func _ready() -> void:
	super()
	lamp = OmniLight3D.new(); add_child(lamp); lamp.position = Vector3(0, 1.65, -0.35)
	lamp.light_color = Color(1.0, 0.68, 0.32); lamp.light_energy = 1.4; lamp.omni_range = 6.0
	_lamp_glow(true)


## Down the stair: the roar, and the fight begins.
func wake() -> void:
	if phase != 0:
		return
	phase = 1; target = get_tree().get_first_node_in_group("player")
	go(State.ALERT, "Roar", 0.2)
	phase_changed.emit(1)


func _decide(to: Vector3, dist: float, delta: float) -> void:
	match phase:
		0:
			return
		1:
			_round(to, dist, delta)
		2:
			_wall(to, delta)
		3:
			_dark(to, dist, delta)


func _round(to: Vector3, dist: float, delta: float) -> void:
	if state == State.ALERT:  # the roar
		if t >= ap.get_animation("Roar").length:
			go(State.CHASE, "Walk", 0.3)
		return
	if dist <= attack_range and cooldown == 0.0:
		swings += 1
		blow = "Smash" if swings % 3 == 0 or (target.blocking and swings % 2 == 0) else "Attack"  # a block invites the smash
		go(State.ATTACK, blow, 0.15)
		if blow == "Smash":
			Audio.play3d(self, "porteiro_chaves", Vector3(0, 2.4, 0), 4.0, false, 5.0, 30.0)  # the keys raised: the warning
		return
	if state != State.CHASE:
		go(State.CHASE, "Walk", 0.3)
	_face(_route(target.global_position, to), delta)
	walk_forward()


func _wall(to: Vector3, delta: float) -> void:
	if not flight.is_empty():
		return
	_face(to, delta * 2.0)
	throw_in -= delta
	if throw_in <= 0.0 and state == State.IDLE:
		throw_in = THROW_EVERY
		blow = "Throw"; go(State.ATTACK, "Throw", 0.15)


func _dark(to: Vector3, dist: float, delta: float) -> void:
	if state == State.ALERT:
		if t >= ap.get_animation("Roar").length:
			go(State.IDLE, "Idle", 0.3)
		return
	var lit: bool = target.holds_lantern()
	if lit or dist < noise():
		heard_at = target.global_position
	if heard_at == Vector3.INF:
		if state != State.IDLE:
			go(State.IDLE, "Idle", 0.3)
		return
	if dist <= attack_range and cooldown == 0.0 and (lit or dist < noise() + 0.5):
		swings += 1
		blow = "Smash" if swings % 2 == 0 else "Attack"
		go(State.ATTACK, blow, 0.15)
		return
	var d := heard_at - global_position; d.y = 0
	if d.length() < 0.8:  # there, and nothing: he stands and listens
		heard_at = Vector3.INF; go(State.IDLE, "Idle", 0.3)
		return
	if state != State.CHASE:
		go(State.CHASE, "Walk", 0.3)
	_face(_route(heard_at, d), delta)
	var fwd := -global_basis.z
	var v := DARK_SPEED if lit else speed
	velocity.x = fwd.x * v; velocity.z = fwd.z * v


## How far off he hears the player right now (in the dark: he has no eyes for anything but a light).
func noise() -> float:
	var p: Player = target
	if p.mode == Player.Mode.DEAD:
		return 0.0
	if p.action in LOUD:
		return HEAR.fight
	var v := Vector2(p.velocity.x, p.velocity.z).length()
	if v > Player.JOG_SPEED + 0.2:
		return HEAR.sprint
	if p.crouched:
		return HEAR.sneak if v > 0.1 else HEAR.still
	if v > Player.WALK_SPEED + 0.15:
		return HEAR.jog
	return HEAR.walk if v > 0.1 else HEAR.still


func _attack(to: Vector3, level: bool, delta: float) -> void:
	match blow:
		"Smash":
			if t < SMASH_HIT - 0.25:
				_face(to, delta * attack_track)
			elif not hit_done and t >= SMASH_HIT:
				hit_done = true
				Audio.play3d(self, "porteiro_golpe", Vector3(0, 0.2, -1.6), 4.0, false, 6.0, 40.0)
				if level and to.length() < attack_reach + 0.3 and (-global_basis.z).dot(to.normalized()) > 0.4:
					target.take_damage(2, self, true)
				if target is Player:
					target.shake = 0.4
			if t >= SMASH_FREE:  # the keys out of the floor
				_end_blow()
		"Throw":
			_face(to, delta * 2.0)
			if not hit_done and t >= THROW_AT:
				hit_done = true
				var hand := global_position + Vector3(0, 2.6, 0) - global_basis.z * 0.4
				var s := Stone.new(); get_parent().add_child(s)
				s.launch(hand, target.global_position + Vector3(0, 1.2, 0), self)
			if t >= ap.get_animation("Throw").length:
				go(State.IDLE, "Idle", 0.2)
		_:
			super(to, level, delta)


func _end_blow() -> void:
	cooldown = attack_cooldown
	go(State.CHASE, "Walk", 0.25)


## A blow of n (by: what struck). Up on the altar only bolts reach; from behind, BACK times; the machete does not
## stagger him. The phases turn here.
func take_hit(n: int, by := "") -> void:
	if state == State.DEAD:
		return
	if phase == 0:
		wake()
	if target == null:
		target = get_tree().get_first_node_in_group("player")
	if phase == 2 and by != "besta":
		target.notice.emit("Lá em cima o facão não alcança.")
		return
	var to := target.global_position - global_position; to.y = 0
	var behind := to.length() > 0.01 and (-global_basis.z).dot(to.normalized()) < -0.3
	if behind and by != "besta":
		n *= BACK
	health -= n
	if phase == 1 and health <= P2:  # (no blow skips a phase: it stops at the next one's line; he dies only in the last)
		health = P2; _to_wall()
	elif phase == 2 and health <= P3:
		health = P3; _to_dark()
	elif health <= 0:
		health = 0
		_die()
	elif (by == "besta" or behind) and state != State.ATTACK and flight.is_empty():
		go(State.HIT, "Hit", 0.05)
	elif phase == 3:
		heard_at = target.global_position  # a blow tells him where you are


func _stagger() -> void:
	if t >= ap.get_animation("Hit").length:
		go(State.IDLE if phase == 2 else State.CHASE, "Idle" if phase == 2 else "Walk", 0.2)


## Phase 2: a roar, and up onto the altar in one leap.
func _to_wall() -> void:
	phase = 2; throw_in = THROW_EVERY * 0.6
	phase_changed.emit(2)
	if altar != Vector3.INF:
		travel(altar, func(): go(State.IDLE, "Idle", 0.2), "Jump", 1.6, 4.0)
	Audio.play3d(self, "porteiro_rugido", Vector3(0, 2.0, 0), 4.0, false, 8.0, 50.0)


## Phase 3: the lantern on his chest breaks; down off the altar into the dark (the arena puts the candles out).
func _to_dark() -> void:
	phase = 3; heard_at = Vector3.INF
	_lamp_glow(false)
	Audio.play3d(self, "lampiao_quebrar", Vector3(0, 1.6, -0.3), 4.0, false, 6.0, 40.0)
	phase_changed.emit(3)
	var land := below if below != Vector3.INF else global_position
	travel(land, func(): go(State.ALERT, "Roar", 0.2), "Jump", 1.0, 4.0)


func _lamp_glow(on: bool) -> void:
	lamp_on = on
	if lamp:
		lamp.visible = on
	Nodes.visit_surfaces(self, func(mi: MeshInstance3D, i: int, m: Material):
		if m and m.resource_name == "o_lampiao":
			var g := StandardMaterial3D.new(); g.resource_name = "o_lampiao"
			if on:
				g.albedo_color = Color(1.0, 0.8, 0.45); g.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			else:
				g.albedo_color = Color(0.08, 0.07, 0.06)
			mi.set_surface_override_material(i, g))


func _die() -> void:
	_lamp_glow(false)
	go(State.DEAD, "Death", 0.1)
	remove_from_group("enemy")
	killed.emit(); died.emit()


## A chunk of gravestone in flight: along an arc to where he aimed; a column (anything) in the way stops it; it hurts the
## player it passes close to.
class Stone extends Node3D:
	var from := Vector3.ZERO
	var to := Vector3.ZERO
	var k := 0.0
	var dur := 0.9
	var by: Node3D
	var done := false

	func launch(a: Vector3, b: Vector3, thrower: Node3D) -> void:
		from = a; to = b; by = thrower; global_position = a
		dur = clampf(a.distance_to(b) / 11.0, 0.45, 1.2)
		var mi := MeshInstance3D.new(); add_child(mi)
		var bm := BoxMesh.new(); bm.size = Vector3(0.32, 0.22, 0.26); mi.mesh = bm
		var m := StandardMaterial3D.new(); m.albedo_color = Color(0.55, 0.54, 0.5); bm.material = m

	func _physics_process(delta: float) -> void:
		if done:
			return
		k = minf(1.0, k + delta / dur)
		var mid := (from + to) / 2 + Vector3(0, 1.2, 0)
		var next := from.lerp(mid, k).lerp(mid.lerp(to, k), k)
		var p: Player = get_tree().get_first_node_in_group("player")
		var skip: Array[RID] = [by.get_rid()]
		if p:
			skip.append(p.get_rid())  # (the player is hit by nearness, below)
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position, next, 1, skip))
		rotation += Vector3(7, 5, 3) * delta
		if p and next.distance_to(p.global_position + Vector3(0, 1.0, 0)) < 0.75:
			p.take_damage(1, by)
			_break(next); return
		if hit:
			_break(hit.position); return
		global_position = next
		if k >= 1.0:
			_break(next)

	func _break(at: Vector3) -> void:
		done = true; global_position = at
		Audio.play3d(get_parent(), "pedra_quebrar", at, 2.0, false, 5.0, 35.0)
		var tw := create_tween(); tw.tween_property(self, "scale", Vector3.ONE * 0.1, 0.2); tw.tween_callback(queue_free)

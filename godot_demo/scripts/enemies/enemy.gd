# Base of every creature that hunts the player (Mutante, Enfermeira): its body (capsule, model, navmesh agent), its
# health and states, the blow it strikes and the stagger it takes. A creature sets its stats in _init() and decides
# what to do each frame in _decide(); the attack and the stagger play out here (_attack, _stagger). Its sounds are
# data too (`voice`): what it plays on each state, now and then while it roams, and at each step.
# A scripted move that ignores gravity and walls (a glide off a roof, a climb out of a well) is travel().
# Takes hits from player.gd (group "enemy", take_hit).
class_name Enemy
extends CharacterBody3D

signal killed

enum State { IDLE, ALERT, CHASE, ATTACK, HIT, DEAD }

@export var active := true      # false = dormant (autotest)
# --- stats (a creature sets these in _init) ---
var model_name := "monster"     # res://models/characters/<model_name>.glb
var body_radius := 0.35
var max_health := 6
var speed := 1.45               # walking speed, m/s
var stride := 1.28              # its Walk clip's speed at 1x: the clip is sped up to match `speed`
var turn_speed := 4.0
var attack_range := 1.3         # starts a blow when this close
var attack_reach := 1.9         # the blow connects up to here, if the player is in front
var attack_hit := 18.0 / 30.0   # when in the Attack clip it connects
var attack_cooldown := 0.6
var attack_track := 0.5         # how much it can still turn to follow you during the wind-up
var attack_damage := 1
var weak_to: Array[String] = []  # ItemCatalog ids: only these hurt it ([] = anything does); the rest only SHRUG
# event -> sound name (res://sounds, takes picked at random): idle (now and then), alert, attack, hurt, death, step.
# Leave one out and it is silent there (A Enfermeira has none: no voice, no footsteps).
var voice := {}
var step_length := 0.64         # metres between footsteps (half its Walk stride)
# --- state ---
var health := 6
var state := State.IDLE
var t := 0.0                    # seconds in the current state
var cooldown := 0.0
var hit_done := false
var target: Node3D
var ap: AnimationPlayer
var agent: NavigationAgent3D    # follows the level navmesh; with none (training room) it walks straight at you
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _grunt_in := randf_range(3.0, 8.0)
var _stride := 0.0
var flight := {}                # a travel() under way: from, ctrl, to, dur, k, then
const SHRUG := "O golpe não lhe faz nada."
const SAY := {  # event -> volume dB, unit size, max distance: the scream carries, the steps stay close
	"idle": [-3.0, 4.0, 30.0], "alert": [4.0, 8.0, 60.0], "attack": [0.0, 5.0, 35.0], "hurt": [0.0, 5.0, 35.0],
	"death": [2.0, 6.0, 45.0], "step": [-7.0, 3.0, 25.0]}


func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	var col := CollisionShape3D.new(); add_child(col)
	var cap := CapsuleShape3D.new(); cap.radius = body_radius; cap.height = 2.1
	col.shape = cap; col.position.y = 1.05
	var model: Node3D = load(Paths.character(model_name)).instantiate()
	add_child(model)
	model.rotation.y = PI  # glTF faces +Z, the body's forward is -Z
	ap = Nodes.find_first(model, "AnimationPlayer")
	agent = NavigationAgent3D.new(); agent.radius = body_radius; agent.height = 2.2  # too tall for the low doors
	agent.path_desired_distance = 0.4; agent.target_desired_distance = 0.5
	add_child(agent)
	ap.play("Idle")


## Into state s, playing anim (Walk sped up to the walking speed).
func go(s: State, anim: String, blend := 0.2) -> void:
	state = s; t = 0.0; hit_done = false
	ap.play(anim, blend, speed / stride if anim == "Walk" else 1.0)
	ap.speed_scale = 1.0
	say({State.ALERT: "alert", State.ATTACK: "attack", State.HIT: "hurt", State.DEAD: "death"}.get(s, ""))


## Its sound for an event (voice), from its head (its feet for the steps).
func say(event: String) -> void:
	if voice.has(event):
		var v: Array = SAY[event]
		var p := Audio.play3d(self, voice[event], Vector3(0, 0.1 if event == "step" else 1.8, 0), v[0], false, v[1], v[2])
		p.pitch_scale = randf_range(0.92, 1.06)


## A blow of n from `by` (the ItemCatalog id that struck: "facao", "besta"). With weak_to set, only those hurt it.
func take_hit(n: int, by := "") -> void:
	if state == State.DEAD:
		return
	if target == null:
		target = get_tree().get_first_node_in_group("player")
	if not weak_to.is_empty() and by not in weak_to:
		if target is Player:
			target.notice.emit(SHRUG)
		return
	health -= n
	if health <= 0:
		go(State.DEAD, "Death", 0.1)
		remove_from_group("enemy")  # the corpse keeps its collision (it would fall through the floor) but takes no hits
		killed.emit()
	else:
		go(State.HIT, "Hit", 0.05)


func _physics_process(delta: float) -> void:
	if not flight.is_empty():
		_travel_step(delta)
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	velocity.x = 0; velocity.z = 0
	t += delta
	cooldown = max(0.0, cooldown - delta)
	if active and state != State.DEAD:
		_think(delta)
		_sounds(delta)
	move_and_slide()


func _sounds(delta: float) -> void:  # a grunt now and then while it roams; a step every step_length it walks
	_grunt_in -= delta
	if _grunt_in <= 0.0 and state in [State.IDLE, State.CHASE]:
		say("idle"); _grunt_in = randf_range(5.0, 11.0)
	_stride += Vector2(velocity.x, velocity.z).length() * delta
	if _stride >= step_length:
		_stride = 0.0; say("step")


func _think(delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player")
	if target == null:
		return
	if target.get("mode") == Player.Mode.DEAD:  # player dead -> lose interest
		if state != State.IDLE:
			go(State.IDLE, "Idle", 0.5)
		return
	var to := target.global_position - global_position; to.y = 0
	match state:
		State.ATTACK:
			_attack(to, delta)
		State.HIT:
			_stagger()
		_:
			_decide(to, to.length(), delta)


## What it does when not striking or staggering: IDLE, ALERT, CHASE. Each creature its own.
func _decide(_to: Vector3, _dist: float, _delta: float) -> void:
	pass


func _attack(to: Vector3, delta: float) -> void:
	if t < attack_hit:
		_face(to, delta * attack_track)
	elif not hit_done:
		hit_done = true
		if to.length() < attack_reach and (-global_basis.z).dot(to.normalized()) > 0.5:
			target.take_damage(attack_damage, self)
	if t >= ap.get_animation("Attack").length:
		cooldown = attack_cooldown
		go(State.CHASE, "Walk", 0.25)


func _stagger() -> void:
	if t >= ap.get_animation("Hit").length:
		go(State.CHASE, "Walk", 0.2)


## Along an arc to `to` (`arc` metres over the higher end) at `v` m/s, playing `anim` (state ALERT), through
## anything in the way and with no gravity; then `then`.
func travel(to: Vector3, then: Callable, anim: String, arc: float, v: float) -> void:
	var from := global_position
	var flat := to - from; flat.y = 0
	if flat.length() > 0.1:
		rotation.y = atan2(-flat.x, -flat.z)
	flight = {"from": from, "to": to, "ctrl": Vector3((from.x + to.x) / 2, maxf(from.y, to.y) + arc, (from.z + to.z) / 2),
		"dur": clampf(from.distance_to(to) / v, 0.5, 6.0), "k": 0.0, "then": then}
	go(State.ALERT, anim, 0.2)


func _travel_step(delta: float) -> void:
	flight.k = minf(1.0, flight.k + delta / flight.dur)
	var k: float = flight.k
	global_position = (flight.from as Vector3).lerp(flight.ctrl, k).lerp((flight.ctrl as Vector3).lerp(flight.to, k), k)
	velocity = Vector3.ZERO
	if k >= 1.0:
		var then: Callable = flight.then
		flight = {}
		then.call()


func walk_forward() -> void:
	var fwd := -global_basis.z
	velocity.x = fwd.x * speed; velocity.z = fwd.z * speed


## Where to head for `goal` along the navmesh (the direct way `to` when there is no navmesh, or when it is as close as
## it can get: you are behind a low door).
func _route(goal: Vector3, to: Vector3) -> Vector3:
	agent.target_position = goal
	var d := agent.get_next_path_position() - global_position; d.y = 0
	return d if d.length() > 0.05 else to


## The navmesh point closest to p (p itself where there is no navmesh).
func _on_nav(p: Vector3) -> Vector3:
	var map := get_world_3d().navigation_map
	return NavigationServer3D.map_get_closest_point(map, p) if NavigationServer3D.map_get_regions(map).size() > 0 else p


func _face(to: Vector3, delta: float) -> void:
	if to.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), turn_speed * delta)


## A clear line from `eye` to the player's chest (nothing on collision layer 1 in between).
func _clear_line(eye: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(eye, target.global_position + Vector3(0, 1.3, 0), 1, [get_rid(), target.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

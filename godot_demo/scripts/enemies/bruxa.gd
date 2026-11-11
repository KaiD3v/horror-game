# A Bruxa (models/characters/bruxa.glb, ../tools/personagens/bruxa_build.py; ../docs/MUTANTES_NOITE.md): the moth.
# Only at night, perched folded on the village's roof ridges, eyes throwing the light back. The lantern in hand
# calls her from LURE metres off (with a clear line from the roof); she turns to stare at it, clicks, opens her wings and glides down to
# it. On the ground she circles the light on wrists and feet out of reach and darts in now and then to rake at it.
# Hang the lantern on the belt and she loses you beyond DIM: she hunts round where the light went out, then flies
# back up to a roof. At dawn they all fly off towards the Colônia. No footsteps: wings and clicks.
class_name Bruxa
extends Enemy

const LURE := 22.0         # the lantern in hand calls her from this far (from a roof: needs a clear line)
const DIM := 2.5           # hung on the belt, the light reaches her only this close
const ORBIT := 4.0         # she circles the light this far out
const DART := 5.0          # m/s on a dart in
const SEARCH_SPEED := 1.6
const SEARCH_TIME := 6.0
const FLY := 7.0           # m/s along a glide
const WATCH := 1.5         # seconds she stares at the light, eyes shining, before she comes

var roosts: Array[Vector3] = []   # the roof ridges she can perch on (vilarejo.gd)
var roost = null                  # the one she is on (Vector3), null once she leaves it
var darting := false
var dart_in := 3.0
var orbit_a := 0.0
var orbit_dir := 1.0
var last_light := Vector3.ZERO
var searching := 0.0              # > 0: hunting round where the light went out
var watching := 0.0
var wings: AudioStreamPlayer3D
var shine: StandardMaterial3D     # the eyeshine (b_brilho), brighter when the lantern faces her


func _init() -> void:
	model_name = "bruxa"; body_radius = 0.3
	max_health = 3                          # machete slash 1, overhead 2; one bolt
	speed = 2.6; stride = 3.49              # circling; a dart is faster (DART)
	turn_speed = 6.0
	attack_range = 1.5; attack_reach = 2.0; attack_hit = 10.0 / 30.0
	attack_cooldown = 0.8; attack_track = 0.8
	voice = {"idle": "bruxa_estalo", "alert": "bruxa_estalo", "attack": "bruxa_estalo", "hurt": "bruxa_guincho",
		"death": "bruxa_guincho"}


func _ready() -> void:
	super()
	wings = Audio.play3d(self, "bruxa_asas", Vector3(0, 1.0, 0), -80.0, true, 3.0, 30.0)
	Nodes.visit_surfaces(self, func(mi: MeshInstance3D, i: int, m: Material):
		if m and m.resource_name == "b_brilho":
			shine = m.duplicate(); shine.emission_energy_multiplier = 0.6; mi.set_surface_override_material(i, shine))


## Perched on a roof ridge from the start (the level spawns them at nightfall).
func perch_on(at: Vector3) -> void:
	roost = at; global_position = at; velocity = Vector3.ZERO
	go(State.IDLE, "Idle", 0.3)


func _physics_process(delta: float) -> void:
	var moving := not flight.is_empty() or (state == State.CHASE and Vector2(velocity.x, velocity.z).length() > 0.3)
	wings.volume_db = move_toward(wings.volume_db, -6.0 if moving and state != State.DEAD else -80.0, 120.0 * delta)
	if target and shine:
		var lit: bool = target.lantern_out and global_position.distance_to(target.global_position) < LURE
		shine.emission_energy_multiplier = move_toward(shine.emission_energy_multiplier, 4.0 if lit else 0.6, 6.0 * delta)
	super(delta)


## A glide from where she is to `to`, arcing over; `then` when she gets there.
func fly_to(to: Vector3, then: Callable) -> void:
	roost = null
	travel(to, then, "Fly", 2.5, FLY)


## Dawn: up and away north, over the Colônia, and gone.
func leave() -> void:
	if state == State.DEAD:
		return
	fly_to(global_position + Vector3(randf_range(-15, 15), 30, -60), queue_free)


func take_hit(n: int) -> void:
	flight = {}  # hit on the wing: she drops
	super(n)


func _decide(to: Vector3, dist: float, delta: float) -> void:
	match state:
		State.IDLE:  # perched (or settled after losing you): the light calls her; she turns and watches it first
			if target.lantern_out and dist < LURE and _clear_line(global_position + Vector3(0, 1.2, 0)):
				_face(to, delta * 0.5); watching += delta
				if watching >= WATCH:
					watching = 0.0; go(State.ALERT, "Alert", 0.15)
			else:
				watching = 0.0
		State.ALERT:  # wings open, then down to the light
			_face(to, delta)
			if flight.is_empty() and t >= ap.get_animation("Alert").length:
				_glide_down()
		State.CHASE:
			_hunt(to, dist, delta)


func _glide_down() -> void:
	var back := global_position - target.global_position; back.y = 0
	var p := target.global_position + back.normalized() * ORBIT
	var map := get_world_3d().navigation_map
	if NavigationServer3D.map_get_regions(map).size() > 0:
		p = NavigationServer3D.map_get_closest_point(map, p)
	fly_to(p, _landed)


func _landed() -> void:
	var from := global_position - target.global_position
	orbit_a = atan2(from.z, from.x); orbit_dir = 1.0 if randf() < 0.5 else -1.0
	dart_in = randf_range(1.5, 3.0); searching = 0.0
	go(State.CHASE, "Walk", 0.2)


func _hunt(to: Vector3, dist: float, delta: float) -> void:
	var lit: bool = (target.lantern_out and dist < LURE * 1.3) or dist < DIM
	if lit:
		last_light = target.global_position; searching = 0.0
	elif searching == 0.0:
		searching = SEARCH_TIME; darting = false
	if searching > 0.0:  # the light went out: round the spot, then back up to a roof
		searching -= delta
		if searching <= 0.0:
			searching = 0.0; _go_roost(); return
		var round_spot := last_light + Vector3(cos(t * 0.9), 0, sin(t * 0.9)) * 2.0
		var d := round_spot - global_position; d.y = 0
		_move(_route(round_spot, d), SEARCH_SPEED, delta)
		return
	dart_in -= delta
	if dart_in <= 0.0 and cooldown == 0.0:
		darting = true
	if darting:  # straight in at the light, then the rake
		if dist <= attack_range:
			darting = false; dart_in = randf_range(2.0, 4.0)
			go(State.ATTACK, "Attack", 0.1)
		else:
			_move(to if dist < 2.5 else _route(target.global_position, to), DART, delta)
		return
	orbit_a += orbit_dir * speed / ORBIT * delta  # round the light, out of reach
	var goal := target.global_position + Vector3(cos(orbit_a), 0, sin(orbit_a)) * ORBIT
	var g := goal - global_position; g.y = 0
	_move(_route(goal, g), speed if g.length() > 0.3 else 0.0, delta)


func _move(dir: Vector3, v: float, delta: float) -> void:
	_face(dir, delta)
	var fwd := -global_basis.z
	velocity.x = fwd.x * v; velocity.z = fwd.z * v
	ap.speed_scale = maxf(v, 0.4) / speed


func _go_roost() -> void:
	var taken := get_tree().get_nodes_in_group("enemy").filter(func(e): return e != self and e is Bruxa).map(func(e): return e.roost)
	var best = null
	for r in roosts:
		if r not in taken and (best == null or global_position.distance_to(r) < global_position.distance_to(best)):
			best = r
	if best == null:
		go(State.IDLE, "Idle", 0.3)  # nowhere free: she settles where she is
	else:
		fly_to(best, perch_on.bind(best))


func _stagger() -> void:
	if t >= ap.get_animation("Hit").length:
		if roost != null:
			_glide_down()
		else:
			go(State.CHASE, "Walk", 0.2)

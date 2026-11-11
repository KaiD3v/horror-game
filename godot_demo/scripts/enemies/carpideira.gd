# A Carpideira (models/characters/carpideira.glb, ../tools/personagens/carpideira_build.py; ../docs/MUTANTES_NOITE.md):
# the mourner. Only at night: she walks the alleys between the houses (walks, vilarejo.gd) with a candle in her hands,
# weeping; you hear her before you see her, and now and then the weeping turns into a small child's crying, to draw
# you in. The candle is the only other light in the village at night: you see her coming, and so do the bruxas
# (group "vela", its "body" meta = her). She is the one who sees: in front of her, as far as the light you carry lets her (SEE). Seen, she
# gasps and stares, and after NOTICE seconds of it she screams: the scream calls the others to you (screamed). Then she
# follows at a distance, screaming again while she still sees you, until she loses you. She never strikes. She is
# weak (2): a bolt, an overhead blow or anything from behind kills her before the scream; a slash from in front only
# makes her scream. At dawn she walks to the chapel and goes in.
class_name Carpideira
extends Enemy

signal screamed(at: Vector3)

# how far she sees you in front of her, by the light you carry and how you hold yourself
const SEE := {"lantern": 20.0, "dark": 8.0, "crouch": 4.0}
const CONE := 0.4             # cos of the half-angle she sees in (about 66 degrees either side)
const NOTICE := 1.2           # seconds of seeing you before the scream
const AGAIN := 6.0            # she screams again this often while she still sees you
const LOSE := 6.0             # out of sight this long and she goes back to weeping
const KEEP := 4.0             # she follows no closer than this
const FOLLOW := 1.5           # m/s, following: a jog (1.66) slowly loses her, a sprint easily
const FLAME := Vector3(0, 1.46, 0.28)  # the candle's flame at rest, in the model's space
const LIGHT := 2.2

var walks: Array[Vector3] = []   # the alleys she walks between (vilarejo.gd)
var walk_to := Vector3.INF
var pause := 2.0
var notice := 0.0
var again := 0.0
var lost := 0.0
var seen_at := Vector3.INF
var scream_t := 0.0              # > 0: screaming, standing still
var cry_in := randf_range(15.0, 30.0)
var hush := 0.0                  # > 0: the child's cry instead of the weeping
var home := Vector3.INF          # dawn: the chapel door
var weeping: AudioStreamPlayer3D
var candle: OmniLight3D


func _init() -> void:
	model_name = "carpideira"; body_radius = 0.3
	max_health = 2                           # machete slash 1 (from in front), overhead 2, bolt 3; from behind, any
	speed = 0.8; stride = 0.78               # her walk; following is faster (FOLLOW)
	turn_speed = 3.0
	attack_range = 0.0                       # she never strikes
	voice = {"alert": "carpideira_suspiro", "hurt": "carpideira_suspiro", "death": "carpideira_queda"}


func _ready() -> void:
	super()
	weeping = Audio.play3d(self, "carpideira_choro", Vector3(0, 1.6, 0), -80.0, true, 5.0, 35.0)
	# the candle's light rides on her right hand, at the flame (glTF space, the model's own: +Z is her front)
	var skel: Skeleton3D = Nodes.find_first(self, "Skeleton3D")
	var hand := BoneAttachment3D.new(); hand.bone_name = "hand.R"; skel.add_child(hand)
	candle = OmniLight3D.new(); hand.add_child(candle); candle.add_to_group("vela"); candle.set_meta("body", self)
	candle.position = skel.get_bone_global_rest(skel.find_bone("hand.R")).affine_inverse() * FLAME
	candle.light_color = Color(1.0, 0.7, 0.38); candle.light_energy = LIGHT; candle.omni_range = 6.0


func _physics_process(delta: float) -> void:
	if state != State.DEAD:
		candle.light_energy = LIGHT + 0.25 * sin(Time.get_ticks_msec() * 0.013) * sin(Time.get_ticks_msec() * 0.0071)
		hush = maxf(0.0, hush - delta)
		if state == State.IDLE and home == Vector3.INF:
			cry_in -= delta
			if cry_in <= 0.0:  # the weeping turns into a child's cry for a while
				cry_in = randf_range(18.0, 35.0); hush = 4.0
				Audio.play3d(self, "carpideira_crianca", Vector3(0, 1.5, 0), 0.0, false, 5.0, 40.0)
	var weep := state == State.IDLE and hush == 0.0
	weeping.volume_db = move_toward(weeping.volume_db, 2.0 if weep else -80.0, (60.0 if weep else 240.0) * delta)
	super(delta)


## Dawn: to the chapel door and in.
func go_home(door: Vector3) -> void:
	if state != State.DEAD:
		home = door; go(State.IDLE, "Walk", 0.3)


## She sees you: in front of her, as far as your light lets her, with nothing in between.
func sees(to: Vector3, dist: float) -> bool:
	var p: Player = target
	if p.mode == Player.Mode.DEAD:
		return false
	var reach: float = SEE.lantern if p.lantern_out else (SEE.crouch if p.mode == Player.Mode.CROUCH else SEE.dark)
	if dist > reach or (-global_basis.z).dot(to.normalized()) < CONE:
		return false
	return _clear_line(global_position + Vector3(0, 1.6, 0))


func take_hit(n: int) -> void:
	if state == State.DEAD:
		return
	if target == null:
		target = get_tree().get_first_node_in_group("player")
	var from := target.global_position - global_position; from.y = 0
	if (-global_basis.z).dot(from.normalized()) < 0.0:
		n = max_health  # from behind: she never saw it coming
	super(n)
	if state == State.DEAD:  # the candle goes out
		weeping.stop(); candle.remove_from_group("vela")
		create_tween().tween_property(candle, "light_energy", 0.0, 0.8)


func _decide(to: Vector3, dist: float, delta: float) -> void:
	if home != Vector3.INF:
		_walk(home, speed, delta)
		if _flat(home) < 1.2:
			queue_free()  # into the chapel
		return
	var see := sees(to, dist)
	match state:
		State.IDLE:  # walking the alleys, weeping
			if see:
				notice = 0.0; go(State.ALERT, "Notice", 0.15)
			else:
				_patrol(delta)
		State.ALERT:  # she has seen something: she stares at it; long enough, and she screams
			_face(to, delta)
			notice += delta if see else -0.6 * delta
			if notice >= NOTICE:
				_scream()
			elif notice <= 0.0:
				notice = 0.0; pause = 2.0; go(State.IDLE, "Idle", 0.4)
		State.CHASE:  # screaming, then following at a distance
			scream_t -= delta; again -= delta
			if see:
				seen_at = target.global_position; lost = 0.0
			else:
				lost += delta
			if scream_t > 0.0:
				_face(to, delta); return
			if see and again <= 0.0:
				_scream(); return
			if lost > LOSE:
				pause = 3.0; walk_to = Vector3.INF; go(State.IDLE, "Idle", 0.5); return
			if _flat(seen_at) > KEEP or not see:
				if ap.current_animation != "Walk":
					ap.play("Walk", 0.3, FOLLOW / stride)
				_walk(seen_at, FOLLOW, delta)
			else:
				if ap.current_animation != "Notice":
					ap.play("Notice", 0.3)
				_face(to, delta)


func _scream() -> void:
	notice = 0.0; again = AGAIN; lost = 0.0; seen_at = target.global_position
	go(State.CHASE, "Scream", 0.1)
	scream_t = ap.get_animation("Scream").length
	Audio.play3d(self, "carpideira_grito", Vector3(0, 1.7, 0), 8.0, false, 12.0, 120.0)
	screamed.emit(target.global_position)


func _stagger() -> void:  # hit from in front and still standing: she screams
	if t >= ap.get_animation("Hit").length:
		_scream()


func _patrol(delta: float) -> void:
	if pause > 0.0:
		pause -= delta; return
	if walk_to == Vector3.INF:
		var far := walks.filter(func(w): return w.distance_to(global_position) > 6.0)
		if far.is_empty():
			pause = 5.0; return
		walk_to = far.pick_random()
		ap.play("Walk", 0.3, 1.0)
	_walk(walk_to, speed, delta)
	if _flat(walk_to) < 0.7:
		walk_to = Vector3.INF; pause = randf_range(4.0, 9.0); ap.play("Idle", 0.4)


func _walk(goal: Vector3, v: float, delta: float) -> void:
	var d := goal - global_position; d.y = 0
	_face(_route(goal, d), delta)
	var fwd := -global_basis.z
	velocity.x = fwd.x * v; velocity.z = fwd.z * v


func _flat(p: Vector3) -> float:  # how far off p is, along the ground
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()

# A heavy block to push (models/props/puzzle.glb "pedra"), Zelda style: walk into one of its sides and keep at it for
# LEAN seconds and he puts his shoulder to it (Push): it grinds along, straight away from him, a SIZE at a time, and he
# goes with it for as long as you keep walking that way. Only along its own sides, so blocks stay on their grid; never
# into anything, nor off the floor's edge. To bring it back from a wall or a corner: hold the right mouse button at a
# side and he takes hold of it (`held`): W pushes, S pulls it after him (if there is room behind him), and letting go of
# the button lets go of it. It can be climbed from any side too (a Climbable rides on it). Puzzles read `pushed` (where
# it ended up after each SIZE) or just where it stands.
class_name Pushable
extends AnimatableBody3D

signal pushed(to: Vector3)

const SIZE := 1.0           # its side, and how far one push takes it (= puzzle_build.py)
const LEAN := 0.4           # s of walking into it before it gives
const STEP_TIME := 1.2      # s for one push (= the Push clip, 36 frames)
const FACE := 0.42          # where his feet stay from the face (= protagonista_rig.py PUSH_FACE)
const BODY := 0.25 + 0.15   # how close (beyond the face) he must be: his radius and a margin

var model := "pedra"
var leaning := 0.0
var moving := false
var held := Vector3.ZERO    # the side he holds it by (world, outward), ZERO when he does not


static func make(parent: Node, at: Vector3, yaw := 0.0, look := "pedra") -> Pushable:
	var b := Pushable.new(); b.model = look; b.position = at; b.rotation.y = yaw
	parent.add_child(b)
	return b


func _ready() -> void:
	add_to_group("pushable")
	sync_to_physics = false
	var all: Node = load(Paths.PROP % "puzzle").instantiate()
	var m: Node3D = all.find_child(model, false); all.remove_child(m); all.free(); add_child(m)
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3.ONE * SIZE
	shape.shape = box; shape.position.y = SIZE / 2; add_child(shape)
	Climbable.make(self, Vector3.ZERO, 0.0, SIZE, Vector2.ONE * SIZE).extra = "  ·  Botão direito · segurar"


func _physics_process(delta: float) -> void:
	if moving:
		return
	if held != Vector3.ZERO:
		_holding()
		return
	var side := _side()
	if side != Vector3.ZERO and Input.is_action_pressed("block"):
		_grab(side)
		return
	var d := -side if side != Vector3.ZERO and _walking(_player(), -side) else Vector3.ZERO
	leaning = leaning + delta if d != Vector3.ZERO else 0.0
	if leaning >= LEAN:
		leaning = -0.6  # refused: a moment before he tries again
		if _free(global_position + d * SIZE):
			_push(d)


func _player() -> Player:
	return get_tree().get_first_node_in_group("player")


## The side he stands at, close and in its middle (world, outward), exploring; ZERO when he is not at one.
func _side() -> Vector3:
	var p := _player()
	if p == null or p.busy or p.mode != Player.Mode.EXPLORE or p.action != "":
		return Vector3.ZERO
	var rel := global_transform.affine_inverse() * p.global_position
	if absf(rel.y) > 0.5:
		return Vector3.ZERO
	var n := Vector3(signf(rel.x), 0, 0) if absf(rel.x) > absf(rel.z) else Vector3(0, 0, signf(rel.z))
	var along := rel.dot(n)
	if along > SIZE / 2 + BODY or absf(rel.z if n.x != 0.0 else rel.x) > SIZE * 0.35:  # off its side / its middle
		return Vector3.ZERO
	return global_basis * n


## Whether the player is still steering him along d.
func _walking(p: Player, d: Vector3) -> bool:
	var input := Input.get_vector("left", "right", "forward", "back")
	var move := p.pivot.global_basis * Vector3(input.x, 0, input.y); move.y = 0
	return move.length() > 0.5 and move.normalized().dot(d) > 0.8


## Right button at a side: he squares up to it, both hands on it (and stands still while he holds it).
func _grab(side: Vector3) -> void:
	var p := _player()
	held = side; p.busy = true; p.velocity = Vector3.ZERO
	var at := global_position + side * (SIZE / 2 + FACE); at.y = p.global_position.y
	p.rotation.y = atan2(side.x, side.z)  # facing it
	create_tween().tween_property(p, "global_position", at, 0.12)


## Holding it: W (towards it) pushes, S (away) pulls; the button let go, he lets go.
func _holding() -> void:
	var p := _player()
	if not Input.is_action_pressed("block") or p.mode != Player.Mode.EXPLORE:
		held = Vector3.ZERO; p.busy = false
		return
	Hints.want(self, "puxar")
	if _walking(p, -held) and _free(global_position - held * SIZE):
		_push(-held, true)
	elif _walking(p, held) and _free(global_position + held * SIZE) and _room(p.global_position + held * SIZE):
		_pull(held)


## Room for it at `to`: nothing in the way and floor under it.
func _free(to: Vector3) -> bool:
	var w := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new(); var box := BoxShape3D.new(); box.size = Vector3.ONE * (SIZE - 0.08)
	q.shape = box; q.transform = Transform3D(global_basis, to + Vector3.UP * SIZE / 2); q.exclude = [get_rid(), _player().get_rid()]
	var under := PhysicsRayQueryParameters3D.create(to + Vector3.UP * 0.3, to + Vector3.DOWN * 0.3, 1, [get_rid()])
	return w.intersect_shape(q).is_empty() and not w.intersect_ray(under).is_empty()


## Room for him at `at` (his body, clear of the floor).
func _room(at: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new(); var c := CylinderShape3D.new(); c.radius = 0.25; c.height = 1.5
	q.shape = c; q.transform = Transform3D(Basis(), at + Vector3.UP * 0.95); q.exclude = [get_rid(), _player().get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(q).is_empty()


func _push(d: Vector3, holding := false) -> void:
	var p := _player()
	moving = true; p.busy = true
	var to := global_position + d * SIZE
	var at := global_position - d * (SIZE / 2 + FACE); at.y = p.global_position.y  # his shoulder to the middle of it
	p.rotation.y = atan2(-d.x, -d.z)
	await create_tween().tween_property(p, "global_position", at, 0.12).finished
	while true:  # a SIZE at a time, on without a stop while he is still walking that way and there is room
		p.play("Push")
		Audio.play3d(self, "pedra_arrastar", Vector3(0, 0.3, 0), 0.0, false, 4.0, 30.0)
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "global_position", to, STEP_TIME)
		tw.tween_property(p, "global_position", at + d * SIZE, STEP_TIME)
		await tw.finished
		pushed.emit(to)
		at += d * SIZE
		if not (_walking(p, d) and _free(to + d * SIZE)):
			break
		to += d * SIZE
	moving = false; p.busy = holding  # (still holding it: he stays at it)


## One step pulled towards him: he leans back and walks backwards a SIZE, the block after him.
func _pull(d: Vector3) -> void:
	var p := _player()
	moving = true
	p.play("Push", true)  # (the push, backwards: leaning back into the pull)
	Audio.play3d(self, "pedra_arrastar", Vector3(0, 0.3, 0), 0.0, false, 4.0, 30.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "global_position", global_position + d * SIZE, STEP_TIME)
	tw.tween_property(p, "global_position", p.global_position + d * SIZE, STEP_TIME)
	await tw.finished
	pushed.emit(global_position)
	Hints.did("puxar")
	moving = false

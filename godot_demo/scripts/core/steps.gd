# Steps and stairs for a CharacterBody3D (the player, the enemies). Godot's bodies slide along walls and slopes but
# stop dead at any upright edge: a doorstep, a stair. Before moving, up() looks whether what stops the body is a step
# (an edge no higher than MAX with floor on top and room above): then the body is lifted onto it and moves on. Going
# down, keep_down() snaps it to the floor below instead of letting it hop off each step. flight() builds a run of
# stairs (and future staircases are just that).
class_name Steps

const MAX := 0.4      # the highest step taken in stride (= the village navmesh's agent climb)
const SNAP := 0.45    # how far down a body keeps to the floor when it walks off an edge
const AHEAD := 0.12   # how far past the edge it looks for the step's top


## Lifts `body` onto a step its velocity is about to run into; returns how much it rose (0 = no step).
static func up(body: CharacterBody3D, delta: float) -> float:
	var h := Vector3(body.velocity.x, 0, body.velocity.z) * delta
	if h.length() < 0.0001 or not body.is_on_floor():
		return 0.0
	var hit := KinematicCollision3D.new()
	if not body.test_move(body.global_transform, h, hit) or hit.get_normal().y > 0.7:
		return 0.0  # nothing in the way, or only a slope it can walk
	var lift := Vector3.UP * MAX
	if body.test_move(body.global_transform, lift):
		return 0.0  # no headroom
	var raised := body.global_transform.translated(lift)
	var fwd := h.normalized() * maxf(h.length(), AHEAD)
	if body.test_move(raised, fwd):
		return 0.0  # a wall, not a step
	var top := KinematicCollision3D.new()
	if not body.test_move(raised.translated(fwd), Vector3.DOWN * MAX, top) or top.get_normal().y < cos(body.floor_max_angle):
		return 0.0  # nothing to stand on beyond the edge, or too steep
	var dy := MAX - top.get_travel().length()
	if dy < 0.01:
		return 0.0
	body.global_position.y += dy
	return dy


## Down the stairs: the body stays on the floor across drops up to SNAP instead of flying off each step.
static func keep_down(body: CharacterBody3D) -> void:
	body.floor_snap_length = SNAP


## A run of `count` stairs, each `rise` high and `run` deep, `width` wide, climbing from `foot` (the middle of the
## bottom step's front edge, on the floor) along yaw's -Z. Solid boxes from the floor up; returns them.
static func flight(parent: Node, foot: Vector3, yaw: float, count: int, rise: float, run: float, width: float, look: Variant) -> Array[StaticBody3D]:
	var made: Array[StaticBody3D] = []
	var b := Basis(Vector3.UP, yaw)
	for i in count:
		var h := rise * (i + 1)
		var at := foot + b * Vector3(0, h / 2, -run * (i + 0.5))
		var s := Looks.box(parent, at, Vector3(width, h, run), look); s.rotation.y = yaw
		made.append(s)
	return made

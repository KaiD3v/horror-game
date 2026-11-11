# Something to climb: a box seen from its foot. This node stands at the middle of its base; `size` is the footprint
# (x, z), `top` how high it goes, `faces` which of its sides can be climbed (local outward normals: all four by
# default; a wall with holds on one face only gets just that one). At the foot of any of them, facing it, E:
#   up to LEDGE_MAX  a ledge: he hangs the lantern on its hook, both hands on the edge and hauls himself up (Climb_Ledge)
#   higher           a wall (holds; puzzle_build.py "muro" looks it): flat against it (mode CLIMB), W climbs a hold up
#                    (Climb_Step), S one down; at the top he goes over as onto a ledge, at the foot S lets go.
# A Pushable carries one (it can be climbed too). Coming down off the top is by stepping off (he drops).
class_name Climbable
extends Interactable

signal climbed

const SIDES: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD, Vector3.RIGHT, Vector3.LEFT]
const LEDGE := 1.25         # = protagonista_rig.py LEDGE: the ledge Climb_Ledge was made for (others: lifted to fit)
const LEDGE_MAX := 1.6
const LEDGE_FACE := 0.33    # rig: his feet from the edge while he reaches up
const LEDGE_IN := 0.6       # rig: how far in he ends up from the edge
const RISE := Vector2(8, 22)  # rig: Climb_Ledge frames over which he rises...
const IN := Vector2(20, 30)   # ...and moves in
const WALL_FACE := 0.30     # rig: his feet from a wall's face
const RUNG := 0.5           # rig: how far one Climb_Step takes him
const NEAR := 1.0           # how far from a face he can be to start

var top := LEDGE
var size := Vector2.ONE
var faces: Array[Vector3] = SIDES.duplicate()
var busy := false


## A box to climb: base = the middle of its base, footprint `size` (x, z) turned by `yaw`, `top` high.
static func make(parent: Node, base: Vector3, yaw: float, height: float, footprint: Vector2, sides: Array[Vector3] = SIDES) -> Climbable:
	var c := Climbable.new(); c.top = height; c.size = footprint; c.faces = sides
	c.position = base; c.rotation.y = yaw
	parent.add_child(c)
	return c


func _ready() -> void:
	super()
	prompt = "E · subir" if top <= LEDGE_MAX else "E · escalar"


## The face he stands before (a local normal), or ZERO: at the foot (not on top), within NEAR of it, along it.
func face_at(p: Vector3) -> Vector3:
	var l := to_local(p)
	if not enabled or absf(l.y) > 0.5:
		return Vector3.ZERO
	var best := Vector3.ZERO; var best_d := INF
	for n in faces:
		var half := (size.x if n.x != 0.0 else size.y) / 2
		var side := (size.y if n.x != 0.0 else size.x) / 2
		var out := l.dot(n) - half
		var along := absf(l.z if n.x != 0.0 else l.x)
		if out >= 0.0 and out <= NEAR and along <= side and out < best_d:
			best = n; best_d = out
	return best


func reach(p: Vector3) -> float:
	var n := face_at(p)
	return INF if n == Vector3.ZERO else to_local(p).dot(n) - (size.x if n.x != 0.0 else size.y) / 2


func _use(by: Node3D) -> void:
	if busy or not by is Player:
		return
	var n := face_at(by.global_position)
	if n != Vector3.ZERO:
		_climb(by, n)


func _climb(p: Player, n: Vector3) -> void:
	busy = true; p.busy = true
	await p.free_hands()
	var wall := top > LEDGE_MAX
	var half := (size.x if n.x != 0.0 else size.y) / 2
	var side := (size.y if n.x != 0.0 else size.x) / 2
	var tangent := Vector3(-n.z, 0, n.x)
	var x := clampf(to_local(p.global_position).dot(tangent), -side + 0.3, side - 0.3)
	var out := global_basis * n
	var at := global_transform * (n * (half + (WALL_FACE if wall else LEDGE_FACE)) + tangent * x)
	p.rotation.y = atan2(out.x, out.z)  # facing it
	await create_tween().tween_property(p, "global_position", at, 0.15).finished
	if wall:
		p.cam_override = Player.CAM_CLIMB
		p.set_mode(Player.Mode.CLIMB)
		while true:
			await get_tree().process_frame
			var h := p.global_position.y - global_position.y
			if Input.is_action_pressed("forward"):
				if h + RUNG > top - LEDGE + 0.01:  # the last of it: over the top
					p.global_position.y = global_position.y + top - LEDGE
					p.set_mode(Player.Mode.EXPLORE)
					await _haul(p, LEDGE, -out)
					break
				await _step(p, RUNG)
			elif Input.is_action_pressed("back"):
				if h < 0.01:  # at the foot: lets go
					p.set_mode(Player.Mode.EXPLORE)
					break
				await _step(p, -minf(RUNG, h))
		p.cam_override = {}
	else:
		await _haul(p, top, -out)
	p.busy = false; busy = false
	climbed.emit()


## Up over an edge `height` above him and in along `fwd` (Climb_Ledge), the root along the clip's path.
func _haul(p: Player, height: float, fwd: Vector3) -> void:
	var from := p.global_position
	Audio.play3d(p, "escalar", Vector3(0, 1.2, 0), -2.0)
	p.play("Climb_Ledge")
	while p.action == "Climb_Ledge":
		var f := p.action_t * 30.0 + 1.0
		p.global_position = from + Vector3.UP * height * _ramp(f, RISE) + fwd * LEDGE_IN * _ramp(f, IN)
		await get_tree().process_frame
	p.global_position = from + Vector3.UP * height + fwd * LEDGE_IN


## One hold up (dy > 0) or down (Climb_Step, backwards).
func _step(p: Player, dy: float) -> void:
	var from := p.global_position
	p.play("Climb_Step", dy < 0.0)
	Audio.play3d(p, "escalar", Vector3(0, 1.5, 0), -8.0)
	while p.action == "Climb_Step":
		p.global_position = from + Vector3.UP * dy * minf(1.0, p.action_t / p.action_len)
		await get_tree().process_frame
	p.global_position = from + Vector3.UP * dy


static func _ramp(f: float, r: Vector2) -> float:
	var t := clampf((f - r.x) / (r.y - r.x), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

# A gap to jump across (a fallen bridge, a ditch, between two roofs): two ends, this node's place and `other`, each a
# spot to stand on at the edge. At either end, with nothing in his hands, Space jumps him to the other (Jump): a
# crouch, a spring, knees up, the landing taken in the knees. Up to MAX apart; the far end may be higher or lower.
class_name Jumpable
extends Interactable

signal jumped(to: Vector3)

const MAX := 3.5            # metres between the ends, at most
const ARC := 0.55           # how high he flies above the straight line
const OFF := 8.0            # Jump frames he leaves the ground on...
const LAND := 21.0          # ...and lands on (= protagonista_rig.py JUMP_OFF, JUMP_LAND)
const END := 1.1            # how near an end he must be

var other := Vector3.ZERO
var busy := false


static func make(parent: Node, a: Vector3, b: Vector3) -> Jumpable:
	assert(a.distance_to(b) <= MAX, "a gap too wide to jump")
	var j := Jumpable.new(); j.position = a; j.other = b
	parent.add_child(j)
	return j


func _ready() -> void:
	super()
	key = "dodge"; prompt = "Espaço · pular"


## In reach: near either end, on its level, exploring (with a weapon out Space is the dodge).
func reach(p: Vector3) -> float:
	var pl: Player = get_tree().get_first_node_in_group("player")
	if not enabled or pl == null or pl.mode != Player.Mode.EXPLORE:
		return INF
	var d := INF
	for e in [global_position, other]:
		var v: Vector3 = e - p
		if absf(v.y) < 0.6:
			d = minf(d, Vector2(v.x, v.z).length())
	return d if d < END else INF


func _use(by: Node3D) -> void:
	if busy or not by is Player:
		return
	_jump(by)


func _jump(p: Player) -> void:
	busy = true; p.busy = true
	var near_a := p.global_position.distance_to(global_position) < p.global_position.distance_to(other)
	var from: Vector3 = global_position if near_a else other
	var to: Vector3 = other if near_a else global_position
	var d := to - from
	p.rotation.y = atan2(-d.x, -d.z)
	await create_tween().tween_property(p, "global_position", from, 0.12).finished
	p.play("Jump")
	var landed := false
	while p.action == "Jump":
		var t := clampf((p.action_t * 30.0 + 1.0 - OFF) / (LAND - OFF), 0.0, 1.0)
		p.global_position = from + d * t + Vector3.UP * ARC * 4.0 * t * (1.0 - t)
		if t >= 1.0 and not landed:
			landed = true; Audio.play3d(p, "pouso", Vector3(0, 0.1, 0), -2.0)
		await get_tree().process_frame
	p.global_position = to
	p.busy = false; busy = false
	jumped.emit(to)

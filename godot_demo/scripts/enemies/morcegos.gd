# The bats of Juca's still (../docs/TUTORIAL_VILAREJO.md "Dungeon 1"): a colony hanging under the roof, the first thing
# in the game that comes at him, and on purpose a weak one. The lantern in hand wakes them (near under them, up on the
# loft: WAKE, BELOW): they drop and
# flap round the light, and now and then one bites (BITE, every BITE_EVERY s, while the lantern is in his hand). Hang
# it on the belt (3) and after LOSE s they go back up. The machete knocks them down: each bat is in the group
# "breakable" (take_hit), so a swing in front of him hits the ones there. They teach A Bruxa's rule before the night
# does: what flies goes to the light in the hand.
class_name Morcegos
extends Node3D

const COUNT := 7
const WAKE := 5.0           # m from under the roost (level): the lantern in hand wakes them...
const BELOW := 5.0          # ...if he is no farther than this below it (up on the loft, not on the floor)
const LOSE := 2.0           # s with the lantern on the belt before they go back up
const BITE := 0.5
const BITE_EVERY := 1.8
const SPEED := 4.5          # m/s, flying

var bats: Array[Bat] = []
var swarming := false
var calm := 0.0
var bite_in := BITE_EVERY
var player: Player
var flutter: AudioStreamPlayer3D


func _ready() -> void:
	for i in COUNT:
		var b := Bat.new(); b.top_level = true; add_child(b)
		b.home = global_position + Vector3(randf_range(-1.6, 1.6), randf_range(-0.15, 0.15), randf_range(-0.7, 0.7))
		b.global_position = b.home
		bats.append(b)


func alive() -> Array[Bat]:
	return bats.filter(func(b): return is_instance_valid(b) and not b.dead)


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
	var left := alive()
	var lit := player.mode != Player.Mode.DEAD and player.holds_lantern()
	var to := global_position - player.global_position
	var far := Vector2(to.x, to.z).length()
	if not swarming and lit and far < WAKE and to.y < BELOW and not left.is_empty():
		swarming = true; calm = 0.0; bite_in = BITE_EVERY * 0.6
		Audio.play3d(self, "morcegos_guincho", Vector3.ZERO, 0.0, false, 4.0, 25.0)
		Hints.want(self, "lamparina", 4.0)
	if swarming:
		calm = 0.0 if lit else calm + delta
		if calm > LOSE or far > WAKE * 2.0 or left.is_empty():
			swarming = false
	var head := player.global_position + Vector3(0, 1.55, 0)
	var near := false
	for b in left:
		b.fly(head if swarming else Vector3.INF, delta)
		near = near or b.global_position.distance_to(head) < 1.7
	if swarming and lit and near:
		bite_in -= delta
		if bite_in <= 0.0:
			bite_in = BITE_EVERY
			player.take_damage(BITE, left.pick_random())
	_sound(swarming and not left.is_empty(), head)


func _sound(on: bool, at: Vector3) -> void:  # the wings, round his head while they are on him
	if on and flutter == null:
		flutter = Audio.play3d(self, "morcegos", Vector3.ZERO, -2.0, true, 3.0, 20.0)
	elif not on and flutter:
		flutter.queue_free(); flutter = null
	if flutter:
		flutter.global_position = at


## One bat: a dark body and two wings that beat; it hangs head down at `home` or circles a point (fly).
class Bat extends Node3D:
	var home := Vector3.ZERO
	var dead := false
	var phase := randf() * TAU
	var spin := randf_range(2.6, 3.8) * (1.0 if randf() < 0.5 else -1.0)
	var reach := randf_range(0.75, 1.35)
	var wings: Array[Node3D] = []
	var t := randf() * 10.0

	func _ready() -> void:
		add_to_group("breakable")
		var skin := StandardMaterial3D.new(); skin.albedo_color = Color(0.09, 0.07, 0.07); skin.roughness = 1.0
		var body := MeshInstance3D.new(); add_child(body)
		var bm := BoxMesh.new(); bm.size = Vector3(0.07, 0.06, 0.13); bm.material = skin; body.mesh = bm
		for s in [-1.0, 1.0]:
			var pivot := Node3D.new(); add_child(pivot); pivot.position.x = s * 0.03
			var w := MeshInstance3D.new(); pivot.add_child(w); w.position.x = s * 0.1
			var wm := BoxMesh.new(); wm.size = Vector3(0.2, 0.006, 0.1); wm.material = skin; w.mesh = wm
			wings.append(pivot)

	## Towards a circle round `at` (Vector3.INF: back to its roost), wings beating.
	func fly(at: Vector3, delta: float) -> void:
		t += delta
		var goal := home
		if at != Vector3.INF:
			phase += spin * delta
			goal = at + Vector3(cos(phase) * reach, sin(phase * 1.7) * 0.35, sin(phase) * reach)
		var to := goal - global_position
		var home_now := at == Vector3.INF and to.length() < 0.05
		global_position += to.limit_length(Morcegos.SPEED * delta)
		if home_now:  # hanging head down, wings folded
			rotation = Vector3(PI, 0, 0)
			for i in 2:
				wings[i].rotation.z = (1.0 if i == 0 else -1.0) * 1.3
			return
		if to.length() > 0.01:
			look_at(global_position + to.normalized() + Vector3(0, 0.001, 0), Vector3.UP)
		for i in 2:
			wings[i].rotation.z = (1.0 if i == 0 else -1.0) * sin(t * 28.0) * 0.9

	func take_hit(_n: int, _by := "") -> void:
		if dead:
			return
		dead = true; remove_from_group("breakable")
		Audio.play3d(self, "morcegos_guincho", Vector3.ZERO, -4.0, false, 3.0, 15.0).pitch_scale = 1.4
		var hit := get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 10.0, 1))
		var floor_y: float = hit.position.y + 0.03 if hit else global_position.y - 1.5
		var tw := create_tween()
		tw.tween_property(self, "global_position:y", floor_y, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(self, "rotation", Vector3(0, rotation.y, PI / 2), 0.35)
		tw.tween_interval(4.0)
		tw.tween_callback(queue_free)

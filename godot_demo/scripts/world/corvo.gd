# A crow (../tools/cenarios/vilarejo k_corvo + k_corvo_asa, on a corvo_NN marker). Perched, it pecks, looks round and
# hops. Come within 7 m (3 m crouched) and it beats its wings off with the rest of its flock, climbs away into the
# fog and is gone. It comes back to its perch a while later, once you are well away.
class_name Corvo
extends Node3D

const SCARE := 7.0
const SCARE_CROUCH := 3.0
const FLOCK := 5.0          # crows this close to the one you scared go with it
const GONE_AFTER := 7.0     # seconds of flight, then it is lost in the fog
const RETURN := 25.0        # comes back when you are this far from its perch...
const AWAY := Vector2(40, 80)  # ...and this long has passed

var home: Transform3D
var pivot := Node3D.new()   # pecks and head turns, without moving the perch
var wings: Array[Node3D] = []
var player: Node3D
var flying := false
var gone := false
var t := 0.0
var idle_in := 0.0
var vel := Vector3.ZERO


func setup(body: Mesh, wing: Mesh) -> void:
	home = transform
	add_to_group("corvo")
	add_child(pivot)
	var b := MeshInstance3D.new(); b.mesh = body; pivot.add_child(b)
	for side in [1.0, -1.0]:  # hinged at the shoulders; the left one is the right mirrored
		var hinge := Node3D.new(); hinge.position = Vector3(0.06 * side, 0.25, 0.0); hinge.scale.x = side
		var w := MeshInstance3D.new(); w.mesh = wing; hinge.add_child(w)
		hinge.visible = false; pivot.add_child(hinge); wings.append(hinge)
	idle_in = randf_range(0.5, 3.0)


func scare(delay := 0.0) -> void:
	if flying or gone:
		return
	flying = true; t = -delay
	var away: Vector3 = global_position - player.global_position; away.y = 0
	away = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
	vel = (away.rotated(Vector3.UP, randf_range(-0.6, 0.6)) * 1.5 + Vector3.UP * 3.2)
	for c in get_tree().get_nodes_in_group("corvo"):
		if c != self and c.home.origin.distance_to(home.origin) < FLOCK:
			c.scare(delay + randf_range(0.05, 0.35))


func _process(delta: float) -> void:
	if player == null:
		return
	t += delta
	if gone:
		if t > idle_in and player.global_position.distance_to(home.origin) > RETURN:
			gone = false; flying = false; visible = true; transform = home; t = 0.0
		return
	if flying:
		_fly(delta)
		return
	var near := SCARE_CROUCH if player.get("mode") == Player.Mode.CROUCH else SCARE
	if player.global_position.distance_to(global_position) < near:
		scare()
		return
	idle_in -= delta
	if idle_in <= 0.0:
		_fidget()
		idle_in = randf_range(1.2, 4.0)


func _fidget() -> void:
	var tw := create_tween()
	match randi() % 3:
		0:  # peck at what it is standing on
			tw.tween_property(pivot, "rotation:x", 0.5, 0.08); tw.tween_property(pivot, "rotation:x", 0.0, 0.12)
			tw.tween_property(pivot, "rotation:x", 0.5, 0.08); tw.tween_property(pivot, "rotation:x", 0.0, 0.12)
		1:  # look round, sharp
			tw.tween_property(pivot, "rotation:y", randf_range(-0.9, 0.9), 0.06)
		2:  # a hop, turning
			var r := pivot.rotation.y + randf_range(-1.2, 1.2)
			tw.tween_property(pivot, "position:y", 0.08, 0.08); tw.parallel().tween_property(pivot, "rotation:y", r, 0.16)
			tw.tween_property(pivot, "position:y", 0.0, 0.08)


func _fly(delta: float) -> void:
	if t < 0.0:
		return  # its neighbour went first
	if not wings[0].visible:
		for w in wings:
			w.visible = true
		pivot.rotation = Vector3.ZERO
		var lvl := get_parent()
		Audio.play3d(lvl, "asas", global_position, -2.0, false, 4.0, 40.0)
		if randf() < 0.5:
			Audio.play3d(lvl, "corvo_%d" % randi_range(1, 3), global_position, 0.0, false, 8.0, 90.0)
	vel.y = move_toward(vel.y, 1.6, 1.5 * delta)  # the steep jump off, then a steady climb
	var flat := Vector3(vel.x, 0, vel.z)
	flat = flat.normalized() * move_toward(flat.length(), 4.5, 2.0 * delta)
	vel.x = flat.x; vel.z = flat.z
	global_position += vel * delta
	basis = Basis.looking_at(vel.normalized(), Vector3.UP, true)  # its front is +z
	var beat := sin(t * TAU * (7.0 if t < 1.0 else 5.0))  # frantic off the ground, then easier
	for w in wings:
		w.rotation.z = beat * 0.9 * w.scale.x  # the mirrored one turns the other way, so both go up together
	if t > GONE_AFTER:
		gone = true; visible = false; t = 0.0; idle_in = randf_range(AWAY.x, AWAY.y)
		for w in wings:
			w.visible = false

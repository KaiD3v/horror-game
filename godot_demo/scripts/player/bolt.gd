# A crossbow bolt in flight: a little drop, it sticks in what it hits (point buried) and rides along with it; an
# enemy takes DAMAGE.
class_name Bolt
extends Node3D

const SPEED := 30.0
const DAMAGE := 3      # the mutant takes 6: two bolts
const DROP := 2.0      # m/s² down

var vel := Vector3.ZERO
var flying := true
var ignore: Array[RID] = []


static func fire(parent: Node, at: Vector3, dir: Vector3, shooter: RID) -> Bolt:
	var b := Bolt.new(); parent.add_child(b); b.add_to_group("bolt")
	b.global_position = at; b.vel = dir * SPEED; b.ignore = [shooter]
	var shaft := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.012, 0.012, 0.3); shaft.mesh = bm
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.30, 0.20, 0.12); bm.material = wood
	b.add_child(shaft); shaft.position.z = 0.15  # the shaft trails behind the point (+z = backwards)
	var fl := MeshInstance3D.new(); var fm := BoxMesh.new(); fm.size = Vector3(0.002, 0.03, 0.05); fl.mesh = fm
	var red := StandardMaterial3D.new(); red.albedo_color = Color(0.5, 0.13, 0.11); fm.material = red
	b.add_child(fl); fl.position.z = 0.27
	b.look_at(at + dir)
	return b


func _physics_process(delta: float) -> void:
	if not flying:
		return
	vel += Vector3.DOWN * DROP * delta
	var to := global_position + vel * delta
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position, to, 1, ignore))
	if hit:
		flying = false
		global_position = hit.position - vel.normalized() * 0.08  # stuck, the point buried
		if hit.collider.is_in_group("enemy") and hit.collider.has_method("take_hit"):
			hit.collider.take_hit(DAMAGE, Player.WEAPON_ITEM[Player.Mode.XBOW])
			reparent(hit.collider)  # rides along with what it hit
	else:
		look_at(to); global_position = to
		if global_position.length() > 200.0:
			queue_free()

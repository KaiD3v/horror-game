# Something the crossbow can hit that is not a creature: a rope holding something up, a bottle on a peg. A body a bolt
# stops in (Bolt calls struck()); `hit` once, then it takes no more (its owner decides what happens: the plank falls,
# the bottle smashes and makes a noise over there).
class_name Target
extends StaticBody3D

signal hit

var done := false


static func make(parent: Node, at: Vector3, size: Vector3, look: Mesh = null) -> Target:
	var t := Target.new(); t.position = at; parent.add_child(t)
	var cs := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = size; cs.shape = box; t.add_child(cs)
	if look:
		var mi := MeshInstance3D.new(); mi.mesh = look; t.add_child(mi)
	return t


func struck(_by: Node3D) -> void:
	if done:
		return
	done = true
	for c in get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", true)
	hit.emit()

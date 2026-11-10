# Training dummy (the training room): counts hits and wobbles.
class_name Dummy
extends StaticBody3D

var hits := 0
var damage := 0
var mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("enemy")
	var shape := CollisionShape3D.new(); add_child(shape)
	var box := BoxShape3D.new(); box.size = Vector3(0.4, 1.6, 0.4); shape.shape = box; shape.position.y = 0.8
	mesh = MeshInstance3D.new(); add_child(mesh)
	var m := BoxMesh.new(); m.size = Vector3(0.35, 1.6, 0.3); mesh.mesh = m; mesh.position.y = 0.8
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.35, 0.27, 0.2); m.material = mat
	var arms := MeshInstance3D.new(); mesh.add_child(arms)
	var am := BoxMesh.new(); am.size = Vector3(1.0, 0.12, 0.12); am.material = mat; arms.mesh = am; arms.position.y = 0.45


func take_hit(n: int) -> void:
	hits += 1; damage += n
	var tw := create_tween()
	tw.tween_property(mesh, "rotation:x", -0.35 * n, 0.08)
	tw.tween_property(mesh, "rotation:x", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC)

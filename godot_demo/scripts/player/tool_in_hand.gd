# A tool held as the machete is (Player.held, the pickaxe): the machete shrinks away on its bone and the tool's shape
# (models/props/itens.glb) takes its place, wherever the clips put the machete (in the fist, carried low). Shown only
# while the machete bone is in his hand; sheathed, the tool is put away.
class_name ToolInHand
extends SkeletonModifier3D

var player: Player
var bone := -1
var shape: Node3D
var shown := ""


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or player == null:
		return
	if bone < 0:
		bone = sk.find_bone("machete")
	var tool := player.held != "facao" and player.mode != Player.Mode.DEAD
	if tool != (shown != "") or (tool and shown != player.held):
		_swap(player.held if tool else "")
	if not tool:
		return
	var at := sk.get_bone_global_pose(bone)  # where the machete is, before it goes
	shape.transform = at.orthonormalized()
	shape.visible = player.machete_in_hand()
	var tiny := sk.get_bone_pose(bone); tiny.basis = tiny.basis.scaled(Vector3.ONE * 0.001)
	sk.set_bone_pose(bone, tiny)


func _swap(id: String) -> void:
	if shape:
		shape.queue_free(); shape = null
	shown = id
	if id != "":
		var all: Node = load(Paths.PROP % "itens").instantiate()
		shape = all.find_child(id, false); all.remove_child(shape); all.free()
		get_skeleton().add_child(shape)

# The lantern back at its rest pose under the hips = on its belt hook, whatever the clip says (player.gd turns it
# on while the lantern is hung but the clip has it in hand: machete, crossbow, death).
class_name LanternHook
extends SkeletonModifier3D

var bone := -1


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk and bone >= 0:
		sk.set_bone_pose(bone, sk.get_bone_rest(bone))

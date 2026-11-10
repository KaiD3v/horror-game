# Spring physics on the protagonist's coat flaps (skirt.* chains, already draped clear of the legs in every clip):
# they lag behind the body when it moves and swing back to the animated pose; legs and pelvis are capsules.
class_name CoatPhysics

const STIFFNESS := 3.0
const DRAG := 0.5
const LEGS := [["thigh", "shin", 0.10], ["shin", "foot", 0.085]]  # bone, next bone, capsule radius


static func setup(skeleton: Skeleton3D) -> SpringBoneSimulator3D:
	var coat := SpringBoneSimulator3D.new(); skeleton.add_child(coat)
	var chains := []
	for side in [".L", ".R"]:
		for panel in ["F", "B"]:  # not the side flaps: they carry the sheath and the holster (child bones), no springs
			chains.append(["skirt.%s.1%s" % [panel, side], "skirt.%s.2%s" % [panel, side]])
	coat.setting_count = chains.size()
	for i in chains.size():
		coat.set_root_bone_name(i, chains[i][0]); coat.set_end_bone_name(i, chains[i][1])
		coat.set_extend_end_bone(i, true)  # one more joint at the hem
		coat.set_end_bone_direction(i, SkeletonModifier3D.BONE_DIRECTION_FROM_PARENT)
		coat.set_end_bone_length(i, 0.17)
		coat.set_center_from(i, SpringBoneSimulator3D.CENTER_FROM_WORLD_ORIGIN)  # inertia from moving about
		coat.set_stiffness(i, STIFFNESS); coat.set_drag(i, DRAG)
		coat.set_gravity(i, 0.0); coat.set_radius(i, 0.03)
	for side in [".L", ".R"]:
		for leg in LEGS:
			var rest := skeleton.get_bone_global_rest(skeleton.find_bone(leg[0] + side))
			var tail := rest.affine_inverse() * skeleton.get_bone_global_rest(skeleton.find_bone(leg[1] + side)).origin
			var cap := SpringBoneCollisionCapsule3D.new(); coat.add_child(cap)
			cap.bone_name = leg[0] + side; cap.radius = leg[2]
			cap.position_offset = tail / 2.0  # capsule axis (local Y) along the bone, centred on it
			cap.rotation_offset = Quaternion(Vector3.UP, tail.normalized())
			cap.height = tail.length() + 2.0 * leg[2]
	# the pelvis under the coat (tools/personagens/protagonista_build.py): a sideways capsule on the hips, so a
	# swinging flap can't sink into it
	var hips_rest := skeleton.get_bone_global_rest(skeleton.find_bone("hips"))
	var seat := SpringBoneCollisionCapsule3D.new(); coat.add_child(seat)
	seat.bone_name = "hips"; seat.radius = 0.11; seat.height = 0.3
	seat.position_offset = hips_rest.affine_inverse() * Vector3(0, 0.69, 0)  # glTF: Blender z = Godot y
	seat.rotation_offset = Quaternion(Vector3.UP, (hips_rest.basis.inverse() * Vector3.RIGHT).normalized())
	return coat

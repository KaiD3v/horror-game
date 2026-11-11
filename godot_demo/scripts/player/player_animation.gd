# The protagonist's AnimationTree (protagonista.glb's clips). Modes play underneath; one-shot actions (draw,
# sheathe, attacks, dodge, hit) play over the mode:
#   idle --+                 guard / block (Blend2) --+
#   walk/jog/sprint (x2: lantern in hand l_, on the hook f_) -- l_/f_explore -- hands (Blend2)       walk legs -----+-- combat (Blend2, legs only)
#   machete / crossbow carried low (c_/cf_/x_explore: their own idle/walk/jog/sprint; c_hands picks the machete set
#   with the lantern in hand c_ or on the hook cf_) <-> raised: combat_ready, xbow_ready
#   explore / combat_ready / death / crouch / xbow_ready -- mode (Transition) -- crouch_legs -- arm -- upper -- action
#   crouch_legs: crouched with a weapon out, the legs kneel / sneak (k_crouch) under it (Blend2, legs only)
#   the one-shots, by how much of him they move (Player.LAYER): arm (OneShot <- shot_arm: the right arm and the
#   lantern, Stow_Lantern with the machete in the other hand), upper (<- shot_up: all but the legs, so he walks on:
#   draw, sheathe, reload, shoot), action (<- shot: the whole body, he stops: attacks, dodges, crouching down)
# Player drives it by the parameters: <l|f>_explore, _jog_mix, _run_mix, _walk_ts... (see player.gd).
class_name PlayerAnimation

const MODE_INPUTS := ["explore", "combat", "dead", "crouch", "xbow", "climb"]  # = Player.Mode
const LEG_BONES := ["hips", "thigh.L", "thigh.R", "shin.L", "shin.R", "foot.L", "foot.R"]
const ARM_BONES := ["upper_arm.R", "forearm.R", "hand.R", "grip.R", "lantern"]  # the lantern's arm (the arm one-shot)


static func build(model: Node3D, ap: AnimationPlayer) -> AnimationTree:
	var bt := AnimationNodeBlendTree.new()
	var anim := func(n: String) -> AnimationNodeAnimation:
		var a := AnimationNodeAnimation.new(); a.animation = n; return a
	for hs in [["l", "Lantern", ""], ["f", "Free", "_Free"]]:  # the lantern in hand / on the belt hook
		var p: String = hs[0]
		_locomotion(bt, anim, p, hs[1])
		bt.add_node(p + "_kneel", anim.call("Crouch_Idle" + hs[2])); bt.add_node(p + "_sneak", anim.call("Crouch_Walk" + hs[2]))
		bt.add_node(p + "_crouch", AnimationNodeBlend2.new())   # kneeling still <-> sneaking, by speed
		bt.connect_node(p + "_crouch", 0, p + "_kneel"); bt.connect_node(p + "_crouch", 1, p + "_sneak")
	for n in ["hands", "crouch_hands"]:  # which set: Stow_Lantern (a one-shot) hides the switch
		bt.add_node(n, AnimationNodeBlend2.new())
	bt.connect_node("hands", 0, "l_explore"); bt.connect_node("hands", 1, "f_explore")
	bt.connect_node("crouch_hands", 0, "l_crouch"); bt.connect_node("crouch_hands", 1, "f_crouch")

	for c in [["c", "Machete"], ["cf", "Machete_Free"], ["x", "Crossbow"]]:  # a drawn weapon carried low: its own sets
		_locomotion(bt, anim, c[0], c[1])
	bt.add_node("c_hands", AnimationNodeBlend2.new())  # the carried machete with the lantern in hand / on the hook
	bt.connect_node("c_hands", 0, "c_explore"); bt.connect_node("c_hands", 1, "cf_explore")
	bt.add_node("guard", anim.call("Combat_Idle"))
	bt.add_node("block_pose", anim.call("Block"))     # RMB held: the machete raised across
	bt.add_node("block", AnimationNodeBlend2.new())
	bt.connect_node("block", 0, "guard"); bt.connect_node("block", 1, "block_pose")
	bt.add_node("walk2", anim.call("Walk_Lantern"))
	bt.add_node("combat", _legs_only(ap))
	bt.connect_node("combat", 0, "block"); bt.connect_node("combat", 1, "walk2")
	bt.add_node("aim", anim.call("Aim_Crossbow_Empty"))
	bt.add_node("walk3", anim.call("Walk_Lantern"))
	bt.add_node("xbow", _legs_only(ap))
	bt.connect_node("xbow", 0, "aim"); bt.connect_node("xbow", 1, "walk3")
	# drawn but not raised (RMB raises): carried low (c_ / x_explore). On the carried crossbow, whether a bolt is on
	# the rail comes from x_carry (Carry_Crossbow[_Empty]: only its string and rail bolt)
	bt.add_node("x_carry", anim.call("Carry_Crossbow_Empty"))
	var bolt := AnimationNodeBlend2.new(); bolt.filter_enabled = true
	for b in ["xbow.string", "bolt.rail"]:
		bolt.set_filter_path(NodePath("%s:%s" % [_skeleton_path(ap), b]), true)
	bt.add_node("x_low", bolt)
	bt.connect_node("x_low", 0, "x_explore"); bt.connect_node("x_low", 1, "x_carry")
	for w in [["c_hands", "combat"], ["x_low", "xbow"]]:
		bt.add_node(w[1] + "_ready", AnimationNodeBlend2.new())  # carried <-> raised
		bt.connect_node(w[1] + "_ready", 0, w[0]); bt.connect_node(w[1] + "_ready", 1, w[1])

	bt.add_node("death", anim.call("Death"))
	bt.add_node("climb", anim.call("Climb_Idle_Loop"))  # on a wall: Climb_Step (a one-shot) moves him
	var mode_node := AnimationNodeTransition.new(); mode_node.input_count = MODE_INPUTS.size(); mode_node.xfade_time = 0.2
	for i in MODE_INPUTS.size():
		mode_node.set_input_name(i, MODE_INPUTS[i])
	bt.add_node("mode", mode_node)
	for i in MODE_INPUTS.size():
		bt.connect_node("mode", i, ["hands", "combat_ready", "death", "crouch_hands", "xbow_ready", "climb"][i])

	bt.add_node("k_kneel", anim.call("Crouch_Idle_Free")); bt.add_node("k_sneak", anim.call("Crouch_Walk_Free"))
	bt.add_node("k_crouch", AnimationNodeBlend2.new())   # (legs only below) kneeling still <-> sneaking, by speed
	bt.connect_node("k_crouch", 0, "k_kneel"); bt.connect_node("k_crouch", 1, "k_sneak")
	bt.add_node("crouch_legs", _legs_only(ap))
	bt.connect_node("crouch_legs", 0, "mode"); bt.connect_node("crouch_legs", 1, "k_crouch")

	var skel := _skeleton_path(ap)
	var sk: Skeleton3D = Nodes.find_first(model, "Skeleton3D")
	var under := "crouch_legs"
	for l in [["arm", "shot_arm"], ["upper", "shot_up"], ["action", "shot"]]:
		var one := AnimationNodeOneShot.new(); one.fadein_time = 0.06; one.fadeout_time = 0.12
		if l[0] != "action":
			one.filter_enabled = true
			for b in sk.get_bone_count():
				var bone := sk.get_bone_name(b)
				var front_back := bone.begins_with("skirt.") and not bone.begins_with("skirt.S.")  # pushed by the legs
				if (bone in ARM_BONES) if l[0] == "arm" else not (bone in LEG_BONES or front_back):
					one.set_filter_path(NodePath("%s:%s" % [skel, bone]), true)
		bt.add_node(l[1], anim.call("Draw_Machete"))
		bt.add_node(l[0], one)
		bt.connect_node(l[0], 0, under); bt.connect_node(l[0], 1, l[1])
		under = l[0]
	bt.connect_node("output", 0, "action")

	var tree := AnimationTree.new(); tree.tree_root = bt
	model.add_child(tree)
	tree.anim_player = tree.get_path_to(ap)
	tree.active = true
	return tree


## One walk / jog / sprint set, prefix p (<p>_explore at the top): its clips each time-scaled so the feet keep pace.
static func _locomotion(bt: AnimationNodeBlendTree, anim: Callable, p: String, kind: String) -> void:
	bt.add_node(p + "_idle", anim.call("Idle_" + kind))
	for g in ["Walk", "Jog", "Run"]:
		var n: String = p + "_" + g.to_lower()
		bt.add_node(n, anim.call(g + "_" + kind)); bt.add_node(n + "_ts", AnimationNodeTimeScale.new())
		bt.connect_node(n + "_ts", 0, n)
	bt.add_node(p + "_jog_mix", AnimationNodeBlend2.new())   # walk <-> jog
	bt.connect_node(p + "_jog_mix", 0, p + "_walk_ts"); bt.connect_node(p + "_jog_mix", 1, p + "_jog_ts")
	bt.add_node(p + "_run_mix", AnimationNodeBlend2.new())   # (walk/jog) <-> sprint
	bt.connect_node(p + "_run_mix", 0, p + "_jog_mix"); bt.connect_node(p + "_run_mix", 1, p + "_run_ts")
	bt.add_node(p + "_explore", AnimationNodeBlend2.new())   # standing <-> moving
	bt.connect_node(p + "_explore", 0, p + "_idle"); bt.connect_node(p + "_explore", 1, p + "_run_mix")


static func _skeleton_path(ap: AnimationPlayer) -> String:  # the tracks' skeleton, as Walk_Lantern names it
	var walk_anim := ap.get_animation("Walk_Lantern")
	return String(walk_anim.track_get_path(0)).get_slice(":", 0)


## Blend2 where only the legs (and the front/back coat flaps they push) follow the walk on input 1; the side flaps
## stay with input 0, because the drawn machete and crossbow are child bones of them.
static func _legs_only(ap: AnimationPlayer) -> AnimationNodeBlend2:
	var legs := AnimationNodeBlend2.new(); legs.filter_enabled = true
	var walk_anim := ap.get_animation("Walk_Lantern")
	for i in walk_anim.get_track_count():
		var p := walk_anim.track_get_path(i)
		var bone := p.get_concatenated_subnames()
		if bone in LEG_BONES or (bone.begins_with("skirt.") and not bone.begins_with("skirt.S.")):
			legs.set_filter_path(p, true)
	return legs

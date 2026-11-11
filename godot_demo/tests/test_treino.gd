# The training room (scenes/levels/treino.tscn): the protagonist's moves one by one against the dummy, then a fight
# with the mutant, his wounds, and death.
extends AutoTest

var coat_hem := Vector3.ZERO  # back-left flap after the coat physics (only readable in skeleton_updated)


func run() -> void:
	await wait(0.6); await shot("1_idle")
	var z0 := player.global_position.z
	Input.action_press("back"); await wait(0.8); await shot("2_jog"); await wait(0.8)
	var jv := Vector2(player.velocity.x, player.velocity.z).length()
	Input.action_release("back"); await wait(0.3)
	var jogged := player.global_position.z - z0
	check(absf(jv - Player.JOG_SPEED) < 0.05 and jogged > 2.2 and jogged < 2.9 and player.stamina == Player.STAMINA_MAX,
		"WASD jogs at %.2f m/s by default (%.2f m in 1.6 s), no stamina spent" % [jv, jogged])
	Input.action_press("walk"); Input.action_press("forward"); await wait(1.0); await shot("2_walk")
	var wv := Vector2(player.velocity.x, player.velocity.z).length()
	Input.action_release("forward"); Input.action_release("walk"); await wait(0.3)
	check(absf(wv - Player.WALK_SPEED) < 0.05, "Ctrl held: walks at %.2f m/s" % wv)
	# back to where the old walk-forward step left him (1.4 m up, in reach of the dummy): the tests below rely on it
	player.global_position = Vector3(0, player.global_position.y, -1.4); player.velocity = Vector3.ZERO; player.rotation.y = 0.0
	player.coat.reset(); await wait(0.3)

	var p0 := player.global_position  # sprint away from the dummy, then put the player back
	Input.action_press("back"); Input.action_press("sprint"); await wait(0.9); await shot("2b_sprint")
	var trail := await coat_offset()
	check(trail > 0.03, "coat flaps trail behind while sprinting (%.3f m off the animation)" % trail)
	var side_cam = Camera3D.new(); L.add_child(side_cam)
	for i in 3:
		side_cam.global_position = player.global_position + player.global_basis.x * 2.6 + Vector3(0, 0.9, 0)
		side_cam.look_at(player.global_position + Vector3(0, 0.8, 0)); side_cam.make_current()
		await wait(0.1); await shot("2b_coat_%d" % i)
	player.cam.make_current(); side_cam.queue_free()
	var v := Vector2(player.velocity.x, player.velocity.z).length()
	var gait: float = player.tree.get("parameters/l_run_mix/blend_amount")
	Input.action_release("sprint"); Input.action_release("back")
	check(absf(v - Player.RUN_SPEED) < 0.05 and gait > 0.99, "Shift sprints at %.2f m/s on the run cycle (gait=%.2f)" % [v, gait])
	check(player.stamina < Player.STAMINA_MAX - 0.7, "sprinting spends stamina (%.2f left)" % player.stamina)
	player.stamina = 0.3
	Input.action_press("back"); Input.action_press("sprint"); await wait(0.8); await shot("2c_winded")
	v = Vector2(player.velocity.x, player.velocity.z).length()
	Input.action_release("sprint"); Input.action_release("back")
	check(player.winded and absf(v - Player.JOG_SPEED) < 0.05, "out of stamina: winded, back to the jog (%.2f m/s)" % v)
	check(player.condition.tired > 0.5 and player.condition.pant.playing and L.hud.vision.visible and not stamina_hud(),
		"winded: he pants and the screen's edges darken, no bar (tired %.2f)" % player.condition.tired)
	await wait(1.6)
	check(player.stamina > 0.2, "stamina recovers after resting (%.2f)" % player.stamina)
	player.stamina = Player.STAMINA_MAX; player.winded = false
	player.global_position = p0; player.velocity = Vector3.ZERO; player.rotation.y = 0.0
	await wait(0.3)

	await tap("crouch"); await wait(0.7); await shot("2d_crouch")
	var hips_y: float = player.skeleton.get_bone_global_pose(player.skeleton.find_bone("hips")).origin.y
	check(player.mode == Player.Mode.CROUCH and hips_y < 0.7, "C crouches (hips at %.2f m)" % hips_y)
	check(player.cam_now.height < 1.2, "the camera drops with him (%.2f m)" % player.cam_now.height)
	var still := await coat_offset()
	check(still < 0.02, "at rest the coat physics sits on the animated drape (%.3f m off)" % still)
	var c0 := player.global_position  # sneak away from the dummy, then put the player back
	Input.action_press("back"); Input.action_press("sprint"); await wait(1.0); await shot("2e_sneak")
	var sv := Vector2(player.velocity.x, player.velocity.z).length()
	var sneak: float = player.tree.get("parameters/l_crouch/blend_amount")
	await wait(0.5); Input.action_release("sprint"); Input.action_release("back")
	check(player.mode == Player.Mode.CROUCH and absf(sv - Player.CROUCH_SPEED) < 0.03 and sneak > 0.99,
		"crouched, WASD sneaks at %.2f m/s (no sprinting) on the sneak cycle" % sv)
	await wait(0.4)
	player.global_position = c0; player.velocity = Vector3.ZERO; player.rotation.y = 0.0; player.coat.reset()
	await wait(0.3)
	await tap("crouch"); await wait(0.7)
	check(player.mode == Player.Mode.EXPLORE and player.action == "", "C again stands up")
	check(player.cam_now.height > 1.5, "...and the camera rises back (%.2f m)" % player.cam_now.height)

	# L hangs the lantern on the belt hook: hands free, moving and fighting; L again takes it back
	var l0 := player.global_position
	await tap("lantern"); await wait(0.8); await shot("2f_stowed")
	check(not player.lantern_out and player.action == "" and player.lantern_hung(), "L hangs the lantern on its belt hook")
	Input.action_press("back"); await wait(0.9); await shot("2g_free_jog")
	var fv := Vector2(player.velocity.x, player.velocity.z).length()
	var free_set: float = player.tree.get("parameters/hands/blend_amount")
	Input.action_release("back")
	check(free_set == 1.0 and absf(fv - Player.JOG_SPEED) < 0.05 and player.lantern_hung(),
		"jogs hands-free (%.2f m/s), the lantern swinging on the hook" % fv)
	player.global_position = l0; player.velocity = Vector3.ZERO; player.rotation.y = 0.0; player.coat.reset()
	await tap("draw"); await wait(1.2)
	var hung := [false]  # the hook is a skeleton modifier: read the pose once modifiers have run
	player.skeleton.skeleton_updated.connect(func(): hung[0] = player.lantern_hung(), CONNECT_ONE_SHOT)
	await player.skeleton.skeleton_updated
	await shot("2h_free_combat")
	check(player.mode == Player.Mode.COMBAT and player.machete_in_hand() and hung[0], "machete drawn, the lantern stays on the hook")
	var sk0: Skeleton3D = player.skeleton
	var hand_y := sk0.get_bone_global_pose(sk0.find_bone("hand.R")).origin.y
	var hips0_y := sk0.get_bone_global_pose(sk0.find_bone("hips")).origin.y
	check(player.tree.get("parameters/c_hands/blend_amount") == 1.0 and hand_y < hips0_y,
		"...and the empty right hand hangs at rest (%.2f m, hips %.2f m)" % [hand_y, hips0_y])
	await tap("draw"); await wait(1.2)
	await tap("lantern"); await wait(0.8)
	check(player.lantern_out and not player.lantern_hung(), "L again takes it back in hand")
	player.global_position = l0; player.velocity = Vector3.ZERO; player.rotation.y = 0.0; player.coat.reset()
	await wait(0.3)

	await tap("crossbow"); await wait(1.4); await shot("2f_crossbow")
	check(player.mode == Player.Mode.XBOW and player.crossbow_in_hand(), "2 draws the crossbow into the right fist")
	check(player.lantern_hung(), "...the lantern hangs on its belt hook meanwhile")
	check(not player.loaded, "...and it comes out unloaded")
	await tap("reload"); await wait(0.9); await shot("2f_reload"); await wait(1.3)
	var sk: Skeleton3D = player.skeleton
	var drawn := sk.get_bone_global_pose(sk.find_bone("xbow.string")).origin.distance_to(
		sk.get_bone_global_pose(sk.find_bone("crossbow")).origin)
	check(player.loaded and player.action == "" and drawn < 0.12,
		"R reloads: string drawn back (%.2f m from the butt), a bolt from the quiver on the rail" % drawn)
	await carry_tests(func(): return player.crossbow_in_hand(), "crossbow")
	await tap("attack"); await wait(0.3)
	check(player.loaded and player.action == "" and get_tree().get_nodes_in_group("bolt").is_empty(), "carried low, LMB does not shoot")
	Input.action_press("block"); await wait(0.6)
	check(player.aiming and L.hud.crosshair.visible and player.cam_now.fov < Player.CAM_EXPLORE.fov - 8.0,
		"RMB held raises it to the aim: the crosshair, the tight camera (fov %.0f)" % player.cam_now.fov)
	var target: Vector3 = L.dummy.global_position + Vector3(0, 1.0, 0) - player.cam.global_position  # crosshair on the dummy
	player.pivot.rotation.y = atan2(-target.x, -target.z); await wait(0.6)
	await tap("attack"); await wait(0.1); await shot("2g_loose"); await wait(0.5)
	check(L.dummy.hits == 1 and get_tree().get_nodes_in_group("bolt").size() == 1, "LMB looses a bolt into the dummy (hits=%d)" % L.dummy.hits)
	check(not player.loaded, "...and leaves it empty")
	Input.action_release("block"); await wait(0.4)
	check(not player.aiming and not L.hud.crosshair.visible, "letting go of RMB lowers it")
	L.dummy.hits = 0; L.dummy.damage = 0
	player.pivot.rotation.y = 0.0; await wait(0.3)
	await tap("crossbow"); await wait(1.4)
	check(player.mode == Player.Mode.EXPLORE and not player.crossbow_in_hand() and not player.lantern_hung(),
		"2 again holsters it and the lantern is back in hand")
	await wheel_tests()

	await tap("draw"); await wait(0.45); await shot("3_drawing"); await wait(0.7)
	check(player.mode == Player.Mode.COMBAT, "draw -> combat mode")
	check(player.machete_in_hand(), "machete in the left hand after drawing")
	check(player.tree.get("parameters/c_hands/blend_amount") == 0.0, "...carried with the lantern out in the right hand")
	await carry_tests(func(): return player.machete_in_hand(), "machete")

	await tap("attack"); await wait(0.33); await shot("4_slash"); await wait(0.6)
	check(L.dummy.hits == 1, "slash hits the dummy (hits=%d)" % L.dummy.hits)
	player.attack("Attack_Overhead"); await wait(0.43); await shot("5_overhead"); await wait(0.7)
	check(L.dummy.hits == 2 and L.dummy.damage == 3, "overhead hits harder (hits=%d dmg=%d)" % [L.dummy.hits, L.dummy.damage])
	player.stamina = Player.STAMINA_MAX
	await tap("attack"); await wait(0.45); await tap("attack"); await wait(1.5)
	check(L.dummy.hits == 4, "slash + LMB during follow-through combos into the overhead (hits=%d)" % L.dummy.hits)

	await combat_tests()
	player.stamina = Player.STAMINA_MAX
	var d0 = player.global_position.distance_to(L.dummy.global_position)
	await tap("dodge"); await wait(0.27); await shot("6_dodge"); await wait(0.5)
	var d1 = player.global_position.distance_to(L.dummy.global_position)
	check(d1 - d0 > 0.6 and d1 - d0 < 1.0, "dodge jumps ~0.8 m back (%.2f m)" % (d1 - d0))
	for side in [["left", "Dodge_Left", -1.0], ["right", "Dodge_Right", 1.0]]:
		var right := player.global_basis.x; var q0 := player.global_position
		Input.action_press(side[0]); await tap("dodge")
		var started: bool = player.action == side[1]
		await wait(0.24); await shot("6_" + side[1].to_lower()); Input.action_release(side[0]); await wait(0.45)
		var dx: float = (player.global_position - q0).dot(right) * side[2]
		check(started and dx > 0.6 and dx < 1.0, "Space+%s hops %.2f m to the %s" % [side[0], dx, side[0]])

	player.take_damage(1); await wait(0.12); await shot("7_hit"); await wait(0.6)
	check(player.health == 2 and player.mode == Player.Mode.COMBAT, "hit react keeps fighting (hp=%d)" % player.health)

	await tap("draw"); await wait(1.2); await shot("8_sheathed")
	check(player.mode == Player.Mode.EXPLORE, "1 again sheathes -> explore mode")
	check(not player.machete_in_hand(), "machete back in the sheath")

	# phase B: the mutant, straight ahead, awake
	L.dummy.queue_free()
	player.health = 20
	L.enemy.global_position = player.global_position + Vector3(0.6, 0, -6.5)
	L.enemy.active = true
	await tap("draw")
	check(await until(func(): return L.enemy.state == Enemy.State.ALERT, 3.0), "mutant sees you and screams")
	await wait(0.4); await shot("10_alert")
	check(await until(func(): return L.enemy.state == Enemy.State.CHASE, 3.0), "mutant gives chase")
	await until(func(): return player.global_position.distance_to(L.enemy.global_position) < 3.0, 6.0)
	await shot("11_chase")
	await until(func(): return L.enemy.state == Enemy.State.ATTACK and L.enemy.t > 0.4, 6.0)
	await shot("12_attack")
	check(await until(func(): return player.health < 20, 3.0), "mutant's blade hurts you (hp=%d)" % player.health)
	for i in 14:
		if L.enemy.state == Enemy.State.DEAD:
			break
		player.stamina = Player.STAMINA_MAX
		player.attack("Attack_Overhead"); await wait(1.05)
	check(L.enemy.state == Enemy.State.DEAD, "machete kills the mutant (its hp=%d)" % L.enemy.health)
	await wait(1.6); await shot("13_mutant_dead")
	sounds_heard()
	await wound_tests()
	await inventory_tests()
	await unlock_tests()
	await chest_tests()
	await course_tests()
	await steps_tests()
	player.health = 2

	player.take_damage(2); await wait(1.8); await shot("9_dead")
	check(player.mode == Player.Mode.DEAD, "dies at 0 hp")
	var p := player.global_position
	await press("forward", 0.5)
	check(player.global_position.distance_to(p) < 0.05, "no control after death")
	await wait(2.2)
	check(not player.condition.breath.playing and not player.condition.heart.playing, "dead: the breathing and the heart stop")



func coat_offset() -> float:
	# how far the spring physics has moved the back-left flap off its animated pose, in metres
	var sk: Skeleton3D = player.skeleton
	if not sk.skeleton_updated.is_connected(_on_skeleton_updated):
		sk.skeleton_updated.connect(_on_skeleton_updated)
	await get_tree().process_frame; await get_tree().process_frame
	var on := coat_hem
	player.coat.active = false
	await get_tree().process_frame; await get_tree().process_frame
	var off := coat_hem
	player.coat.active = true
	return on.distance_to(off)


func _on_skeleton_updated() -> void:
	var sk: Skeleton3D = player.skeleton
	coat_hem = sk.get_bone_global_pose(sk.find_bone("skirt.B.2.L")).origin


func wound_tests() -> void:
	var mi: MeshInstance3D = Nodes.find_first(player.model, "MeshInstance3D")
	var bloody := 0; var rest_ok := true
	for i in mi.mesh.get_surface_count():
		var m: Material = mi.mesh.surface_get_material(i)
		bloody += int(m.next_pass == player.condition.blood)
		var a := mi.mesh.surface_get_arrays(i)
		var v: Vector3 = a[Mesh.ARRAY_VERTEX][0]; var c: PackedFloat32Array = a[Mesh.ARRAY_CUSTOM0]
		rest_ok = rest_ok and c.size() == a[Mesh.ARRAY_VERTEX].size() * 4 and Vector3(c[0], c[1], c[2]).is_equal_approx(v)
	check(bloody == PlayerCondition.BLOODY.size() and rest_ok, "blood overlay on %d surfaces, rest positions in CUSTOM0" % bloody)
	if player.mode == Player.Mode.COMBAT:
		await tap("draw"); await wait(1.2)  # exploring, he keeps facing where he was: the camera can go round
	L.enemy.queue_free()  # its body would catch the camera arm going round
	var lamp = OmniLight3D.new(); L.add_child(lamp); lamp.omni_range = 6.0; lamp.light_energy = 1.5
	player.health = 3; player.condition.wound = 0.0
	var red: Array[int] = []
	for hp in [3, 2, 1]:
		if hp < 3:
			player.take_damage(1)
			await until(func(): return is_equal_approx(player.condition.wound, 1.0 - hp / 3.0), 4.0)
		var n := 0
		for side in [0.0, PI]:  # his back (the game's view), then his front
			player.pivot.rotation.y = player.rotation.y + side
			lamp.global_position = player.global_position + player.global_basis.z.rotated(Vector3.UP, side) * 1.6 + Vector3.UP * 1.6
			await wait(0.5); await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.save_png("res://captures/demo_14_ferido_%d_%s.png" % [hp, "costas" if side == 0.0 else "frente"])
			for y in range(0, img.get_height(), 2):
				for x in range(0, img.get_width(), 2):
					var c := img.get_pixel(x, y)
					n += int(c.r > 0.08 and c.r > 2.2 * c.g and c.r > 2.0 * c.b)
		red.append(n)
		check(player.condition.breath.playing == (hp == 1) and player.condition.heart.playing == (hp == 1),
			"hp %d: breathing %s" % [hp, "hard, the heart pounding" if hp == 1 else "quiet"])
	check(red[0] < red[1] and red[1] < red[2], "blood spreads with each hit (red px %s)" % [red])
	await wait(1.0)
	check(player.condition.breath.volume_db > -12.0, "the breathing fades in (%.1f dB)" % player.condition.breath.volume_db)
	player.pivot.rotation.y = player.rotation.y; lamp.queue_free()


## A drawn weapon, not raised: carried low, he jogs with it and turns where he goes (no strafing, the explore camera).
func carry_tests(in_hand: Callable, what: String) -> void:
	var p0 := player.global_position; var r0 := player.rotation.y
	await wait(0.5)
	check(not player.raised and player.raise_amt < 0.01 and in_hand.call(), "the %s carried low, still in his fist" % what)
	Input.action_press("right"); await wait(0.8)
	var sk := player.skeleton; var foot := sk.find_bone("foot.L")
	var f0 := sk.get_bone_global_pose(foot).origin; await wait(0.25)
	var stepped := sk.get_bone_global_pose(foot).origin.distance_to(f0)
	await wait(0.15); await shot("2h_carry_" + what)
	var v := Vector2(player.velocity.x, player.velocity.z).length()
	var facing := (-player.global_basis.z).dot(player.pivot.global_basis.x)
	Input.action_release("right"); await wait(0.4)
	check(stepped > 0.1, "...his legs walk under it (a foot moved %.2f m in 0.25 s)" % stepped)
	check(absf(v - Player.JOG_SPEED) < 0.05 and facing > 0.9 and absf(player.cam_now.fov - Player.CAM_EXPLORE.fov) < 1.0,
		"...he jogs with it (%.2f m/s), turning where he goes (%.2f), the explore camera" % [v, facing])
	player.global_position = p0; player.velocity = Vector3.ZERO; player.rotation.y = r0; player.coat.reset()
	await wait(0.4)


## Stamina for swings and dodges, the block (RMB) and the lock-on (E), against the dummy in front.
func combat_tests() -> void:
	player.stamina = Player.STAMINA_MAX; player.rest = 0.0
	await tap("attack"); await wait(0.9)
	check(absf(player.stamina - (Player.STAMINA_MAX - Player.COST.Attack_Slash)) < 0.05,
		"a slash spends stamina (%.2f left)" % player.stamina)
	player.stamina = Player.STAMINA_MAX
	await tap("dodge"); await wait(0.7)
	check(absf(player.stamina - (Player.STAMINA_MAX - Player.COST.Dodge)) < 0.05, "a dodge spends stamina (%.2f left)" % player.stamina)
	player.global_position = Vector3(0, player.global_position.y, -1.4); player.velocity = Vector3.ZERO
	player.rotation.y = 0.0; player.pivot.rotation.y = 0.0; await wait(0.3)
	player.stamina = 0.3; var hits: int = L.dummy.hits
	await tap("attack"); await wait(0.6)
	await tap("dodge"); await wait(0.3)
	check(player.action == "" and L.dummy.hits == hits and L.hud.message.text == "Sem fôlego.",
		"out of breath: no swing, no dodge (\"%s\")" % L.hud.message.text)
	player.stamina = Player.STAMINA_MAX

	Input.action_press("block"); await wait(0.5); await shot("5b_block")
	check(player.blocking and player.block_amt > 0.99, "RMB held raises the machete to block")
	var hp := player.health; var st := player.stamina
	player.take_damage(1, L.dummy); await wait(0.15); await shot("5c_block_hit")
	check(absf(player.health - (hp - Player.BLOCK_CHIP)) < 0.01 and player.stamina >= st and "bloqueio" in Audio.heard,
		"a blow from the front on the block: %.2f hp gets through, no stamina spent" % (hp - player.health))
	await wait(0.6)
	var behind := Node3D.new(); L.add_child(behind); behind.global_position = player.global_position + player.global_basis.z * 1.5
	hp = player.health
	player.take_damage(1, behind); behind.queue_free(); await wait(0.7)
	check(absf(player.health - (hp - 1.0)) < 0.01, "...from behind the block does not help (-%.2f)" % (hp - player.health))
	Input.action_release("block"); await wait(0.4)
	check(not player.blocking and player.block_amt < 0.01, "letting go lowers it")
	player.health = player.max_health

	var dummy: Node3D = L.dummy  # (in the group "enemy" like the creatures)
	var here := player.global_position
	player.global_position = here + Vector3(0, 0, Player.LOCK_RANGE + 2.0); await wait(0.3)  # out of reach
	await tap("interact"); await wait(0.1)
	check(player.lock != dummy, "E with the dummy past %.0f m: not locked on it" % Player.LOCK_RANGE)
	player.lock = null; player.global_position = here
	player.pivot.rotation.y = 0.35; await wait(0.2)
	await tap("interact"); await wait(0.8); await shot("5d_lock")
	var to := player._lock_point(dummy) - player.cam.global_position
	var off := (-player.cam.global_basis.z).angle_to(to)
	check(player.lock == dummy and off < 0.05 and L.hud.lock_mark.visible,
		"E locks on: the camera swings onto it (%.3f rad off), the mark over it" % off)
	var m := InputEventMouseMotion.new(); m.relative = Vector2(300, 0); Input.parse_input_event(m); await wait(0.2)
	check(player.lock == dummy and (-player.cam.global_basis.z).angle_to(player._lock_point(dummy) - player.cam.global_position) < 0.05,
		"...the mouse does not pull it away")
	await tap("interact"); await wait(0.1)
	check(player.lock == null and not L.hud.lock_mark.visible, "E again lets go")
	player.global_position = Vector3(0, player.global_position.y, -1.4); player.velocity = Vector3.ZERO
	player.rotation.y = 0.0; player.pivot.rotation.y = 0.0; player.pitch.rotation.x = -0.25
	L.dummy.hits = 2; L.dummy.damage = 3; await wait(0.4)


## Q held: the weapon wheel (WeaponWheel). Slows time, the mouse picks a tablet, letting go puts it in his hands,
## swapping straight from one weapon to the other. Then the number keys do the same without it.
func wheel_tests() -> void:
	var W: WeaponWheel = L.wheel
	check(WeaponWheel.slice_at(Vector2(0, -60)) == 0 and WeaponWheel.slice_at(Vector2(60, 35)) == 1
		and WeaponWheel.slice_at(Vector2(-60, 35)) == 2 and WeaponWheel.slice_at(Vector2(5, 5)) == -1,
		"the tablets: machete up, crossbow lower right, lantern lower left, nothing in the middle")
	var yaw := player.pivot.rotation.y; var p0 := player.global_position; var r0 := player.rotation.y
	Input.action_press("weapons"); await get_tree().process_frame; await get_tree().process_frame
	check(W.open and Engine.time_scale == WeaponWheel.SLOW and W.ring.visible, "Q held opens the wheel, time slows (x%.2f)" % Engine.time_scale)
	await _swipe(0); await wait(0.05); await shot("2w_wheel")
	check(W.picked == 0 and W.centre.text == "Facão" and player.pivot.rotation.y == yaw,
		"the mouse points at the machete (the camera stays put) picked=%d text=%s yaw=%.3f/%.3f" % [W.picked, W.centre.text, player.pivot.rotation.y, yaw])
	Input.action_release("weapons"); await get_tree().process_frame; await get_tree().process_frame
	check(not W.open and Engine.time_scale == 1.0, "letting go closes it, time back to normal")
	await wait(1.3)
	check(player.mode == Player.Mode.COMBAT and player.machete_in_hand(), "...and the machete comes out")
	Input.action_press("weapons"); await wait(0.1); await _swipe(1); await shot("2w_wheel_held")
	check(W.note.text == "virotes: %d" % Inventory.count("virote"), "the crossbow's tablet says the bolts left (%s)" % W.note.text)
	Input.action_release("weapons"); await wait(2.8)
	check(player.mode == Player.Mode.XBOW and player.crossbow_in_hand() and not player.machete_in_hand() and player.wanted == -1,
		"machete -> crossbow in one pick: sheathed, then the crossbow drawn")
	Input.action_press("weapons"); await wait(0.1)
	Input.action_press("left"); Input.action_press("back"); await get_tree().process_frame; await get_tree().process_frame
	var by_keys := W.picked
	Input.action_release("left"); Input.action_release("back"); Input.action_release("weapons"); await wait(1.5)
	check(by_keys == 2 and player.mode == Player.Mode.EXPLORE and not player.crossbow_in_hand() and not player.lantern_hung(),
		"A+S points at the lantern: the crossbow holstered, the lantern back in hand")
	Input.action_press("weapons"); await wait(0.1)
	Input.action_release("weapons"); await wait(0.4)
	check(player.mode == Player.Mode.EXPLORE and player.action == "", "let go without pointing: nothing changes")

	var keys := {}
	for a in ["draw", "crossbow", "lantern", "heal", "weapons"]:
		keys[a] = (InputMap.action_get_events(a)[0] as InputEventKey).physical_keycode
	check(keys == {"draw": KEY_1, "crossbow": KEY_2, "lantern": KEY_3, "heal": KEY_F, "weapons": KEY_Q},
		"keys: 1 machete, 2 crossbow, 3 lantern, F bandage, Q the wheel")
	await tap("crossbow"); await wait(1.4)
	await tap("draw"); await wait(2.8)
	check(player.mode == Player.Mode.COMBAT and player.machete_in_hand() and not player.crossbow_in_hand(),
		"crossbow out, 1: holstered and the machete drawn")
	await tap("lantern"); await wait(1.3)
	check(player.mode == Player.Mode.EXPLORE and not player.machete_in_hand() and not player.lantern_hung(),
		"3 with the machete out: sheathed, the lantern in hand")
	await tap("crossbow"); await wait(1.4)
	await tap("weapons"); await wait(1.4)
	check(player.mode == Player.Mode.EXPLORE and not player.crossbow_in_hand() and not L.wheel.open,
		"a tap of Q with the crossbow out: holstered")
	await tap("draw"); await wait(1.2)
	await tap("weapons"); await wait(1.2)
	check(player.mode == Player.Mode.EXPLORE and not player.machete_in_hand(), "...and with the machete out: sheathed")
	player.velocity = Vector3.ZERO
	player.global_position = p0; player.rotation.y = r0; player.pivot.rotation.y = yaw; player.coat.reset()
	await wait(0.3)


func _swipe(i: int) -> void:  # the mouse dragged towards slice i
	var m := InputEventMouseMotion.new(); m.relative = WeaponWheel.slice_dir(i) * 90.0
	Input.parse_input_event(m)
	await get_tree().process_frame; await get_tree().process_frame


func stamina_hud() -> bool:  # any bar left on screen? (the stamina is the panting and the edges now)
	return L.find_children("*", "ColorRect", true, false).any(func(c): return c != L.hud.vision and c.visible and c.size.y < 20)


## Everything above made its sound (Audio.heard): the machete, the crossbow, the lantern, his hurt, the mutant.
func sounds_heard() -> void:
	var groups := {"machete": ["facao_sacar", "facao_guardar", "facao_golpe", "facao_acerto"],
		"crossbow": ["besta_sacar", "besta_recarga", "besta_disparo"], "lantern and hurt": ["lamparina", "dano"],
		"mutant": ["mutante_grito", "mutante_ataque", "mutante_dor", "mutante_morte", "mutante_passo"]}
	for g in groups:
		var missing: Array = groups[g].filter(func(n): return n not in Audio.heard)
		check(missing.is_empty(), "%s sounds play (missing: %s)" % [g, missing])
	check(Audio.pick("facao_golpe") in ["facao_golpe_1", "facao_golpe_2", "facao_golpe_3"], "a blow picks one of its 3 takes")


## What he carries (Inventory): X dresses a wound with a bandage; the crossbow spends a bolt a reload.
func inventory_tests() -> void:
	player.health = 1; Inventory.items["atadura"] = 1
	await tap("heal"); await wait(0.2)
	check(player.health == 2 and Inventory.count("atadura") == 0 and "curativo" in Audio.heard, "X: a bandage closes a wound (hp %d)" % player.health)
	await tap("heal"); await wait(0.2)
	check(player.health == 2 and L.hud.message.text == "Sem curativos.", "no bandage left: \"%s\"" % L.hud.message.text)
	if player.mode == Player.Mode.COMBAT:
		await tap("draw"); await wait(1.2)
	Inventory.items["virote"] = 1
	await tap("crossbow"); await wait(1.4)
	await tap("reload"); await wait(2.2)
	check(player.loaded and Inventory.count("virote") == 0 and L.hud.ammo.visible, "a reload takes a bolt from the quiver (%d left)" % Inventory.count("virote"))
	Input.action_press("block"); await wait(0.3)
	await tap("attack"); await wait(0.6)
	Input.action_release("block")
	await tap("reload"); await wait(0.3)
	check(not player.loaded and player.action == "" and L.hud.message.text == "Sem virotes.", "no bolts, no reload: \"%s\"" % L.hud.message.text)
	await tap("crossbow"); await wait(1.4)
	Inventory.reset(); Inventory.give_tools()


# --- items that unlock things (ItemCatalog "ferramenta"): a new game has only the lantern -----------------------------
func unlock_tests() -> void:
	Inventory.reset()
	check(Inventory.has("lamparina") and not Inventory.has("facao") and not Inventory.has("besta"), "a new game: the lantern, no machete, no crossbow")
	await tap("draw"); await wait(1.2)
	check(player.mode == Player.Mode.EXPLORE and not player.machete_in_hand() and L.hud.message.text == "Sem facão.",
		"1 with no machete: nothing comes out (\"%s\")" % L.hud.message.text)
	await tap("attack"); await wait(1.2)
	check(player.mode == Player.Mode.EXPLORE and not player.machete_in_hand(), "...nor with a click")
	var W: WeaponWheel = L.wheel
	Input.action_press("weapons"); await wait(0.1); await _swipe(1)
	check(W.note.text == "ainda não tem", "the wheel: the crossbow's tablet is dark (%s)" % W.note.text)
	await shot("2w_wheel_locked")
	Input.action_release("weapons"); await wait(1.4)
	check(player.mode == Player.Mode.EXPLORE and not player.crossbow_in_hand(), "...let go on it, nothing comes out")
	# a door that needs a key
	var door := Interactable.new(); door.requires = "facao"; door.refusal = "O mato fechou a trilha."; L.add_child(door)
	var opened := [0]; door.used.connect(func(_b): opened[0] += 1)
	door.use(player)
	check(opened[0] == 0 and L.hud.message.text == "O mato fechou a trilha.", "a locked way says why: \"%s\"" % L.hud.message.text)
	# the shop: the bolts wait for the crossbow, a tool sells once
	Inventory.money = 100
	check(Shop.buy("armaria", 0) == Shop.Result.LOCKED and Inventory.count("virote") == 6, "no bolts for sale without the crossbow")
	check(Shop.buy("armaria", 2) == Shop.Result.OK and Inventory.has("besta") and Shop.buy("armaria", 0) == Shop.Result.OK,
		"the crossbow bought, then the bolts")
	check(Shop.left("armaria", 2) == 0 and Shop.buy("armaria", 2) == Shop.Result.SOLD_OUT, "a crossbow is bought once")
	Shop.reset()
	# found lying about
	var knife := Pickup.make(L, player.global_position, "facao")
	await wait(0.2)
	check(L.interactor.current == knife and L.hud.prompt.text == "E · pegar facão", "a machete on the floor: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(0.2)
	check(Inventory.has("facao") and not is_instance_valid(knife), "E takes it")
	check(Pickup.make(L, player.global_position, "facao").is_queued_for_deletion(), "a tool you already have is not lying there again")
	door.use(player)
	check(opened[0] == 1, "...and the way it locked opens")
	door.queue_free()
	await tap("draw"); await wait(1.3)
	check(player.mode == Player.Mode.COMBAT and player.machete_in_hand(), "the machete found: 1 draws it")
	await tap("draw"); await wait(1.3)
	# a creature only some things hurt
	var m: Mutante = L.add_enemy(Mutante.new(), Vector3(8, 0, 8), 0.0); m.active = false
	m.weak_to = ["besta"]
	m.take_hit(2, "facao")
	check(m.health == m.max_health and L.hud.message.text == Enemy.SHRUG, "weak only to bolts: the machete does nothing (\"%s\")" % L.hud.message.text)
	m.take_hit(2, "besta")
	check(m.health == m.max_health - 2, "...a bolt does")
	m.queue_free()
	Inventory.reset(); Inventory.give_tools()


# --- a trunk (Chest): E, he kneels, opens it, holds up what was inside while its name shows; E, he tucks it away -----
func chest_tests() -> void:
	Inventory.reset()
	player.velocity = Vector3.ZERO
	var at := player.global_position + Vector3(0, 0, -1.1)
	var c := Chest.make(L, {"id": "teste", "at": Vector2(at.x, at.z), "yaw": 0.0, "item": "facao"})
	var m: Mutante = L.add_enemy(Mutante.new(), Vector3(9, 0, 9), 0.0)
	await wait(0.3)
	check(L.interactor.current == c and L.hud.prompt.text == "E · abrir o baú", "a trunk: \"%s\"" % L.hud.prompt.text)
	await shot("40_bau")
	Audio.heard.clear(); await tap("interact")
	var kneels := await until(func(): return player.action == "Open_Chest", 2.0)
	check(kneels and player.busy and not m.active, "E: he steps up to it and goes down on one knee, the world holds still")
	var spot := c.global_position + c.global_basis.z * Chest.FRONT
	check(Vector2(player.global_position.x - spot.x, player.global_position.z - spot.z).length() < 0.05
		and absf(angle_difference(player.rotation.y, c.rotation.y)) < 0.05, "...right in front of it, facing it")
	await until(func(): return player.action_t > 27 / 30.0, 2.0)
	await shot("41_bau_abrindo")
	check(c.lid.rotation.x < -1.0 and "bau_abrir" in Audio.heard, "the lid comes up in his hand, creaking (%.0f deg)" % rad_to_deg(-c.lid.rotation.x))
	var p0 := player.global_position
	Input.action_press("forward")
	var shown := await until(func(): return get_tree().get_first_node_in_group("found_banner") != null, 4.0)
	Input.action_release("forward")
	var banner: FoundBanner = get_tree().get_first_node_in_group("found_banner")
	var grip: BoneAttachment3D = player.skeleton.get_children().filter(func(n): return n is BoneAttachment3D and n.bone_name == "grip.L").front()
	await wait(0.3); await shot("42_bau_achado")
	check(shown and banner.name_l.text == "Facão" and Inventory.has("facao") and "bau_achado" in Audio.heard,
		"he holds it up: \"%s\" at the bottom of the screen, in the bag" % (banner.name_l.text if banner else ""))
	check(grip != null and grip.get_child_count() == 1 and grip.get_child(0).name == "facao", "the machete itself in his hand")
	check(player.global_position.distance_to(p0) < 0.02 and not player.tree.active, "...held there: W does not move him")
	await tap("interact"); await wait(0.1)
	check(is_instance_valid(banner) and banner.is_inside_tree(), "the E that opened it does not skip the name")
	await wait(0.6); await tap("interact"); await wait(0.1)
	check(not is_instance_valid(banner) and player.action == "Stow_Item", "E again: the name goes, he tucks it away")
	var back := await until(func(): return not player.busy, 3.0)
	check(back and not is_instance_valid(grip) and player.action == "" and m.active and "teste" in Chest.opened
		and not c.enabled and L.hud.prompt.text == "", "...and stands up, the world moves again; the trunk stays open and empty")
	await wait(0.3); await shot("43_bau_aberto")
	var again := Chest.make(L, {"id": "teste", "at": Vector2(at.x + 3, at.z), "yaw": 0.0, "item": "facao"})
	await wait(0.1)
	check(not again.enabled and again.lid.rotation.x < -1.0, "found before: open and empty when the scene comes back")
	again.queue_free()
	m.active = false; m.queue_free()
	# a weapon out: put away first; three bolts in one go
	await tap("draw"); await wait(1.3)
	var bolts := Chest.make(L, {"id": "teste2", "at": Vector2(at.x - 2.5, at.z), "yaw": 0.0, "item": "virote", "qtd": 3})
	var had := Inventory.count("virote")
	bolts.use(player)
	shown = await until(func(): return get_tree().get_first_node_in_group("found_banner") != null, 7.0)
	banner = get_tree().get_first_node_in_group("found_banner")
	check(shown and player.mode == Player.Mode.EXPLORE and banner.name_l.text == "Virote (3)" and Inventory.count("virote") == had + 3,
		"machete out: sheathed first; \"%s\"" % (banner.name_l.text if banner else ""))
	await wait(0.9); await tap("interact")
	await until(func(): return not player.busy, 3.0)
	# a locked one
	var locked := Chest.make(L, {"id": "teste3", "at": Vector2(at.x + 2.5, at.z), "yaw": 0.0, "item": "garrafada",
		"requires": "besta", "refusal": "Um cadeado enferrujado."})
	Inventory.items.erase("besta")
	locked.use(player)
	check(not player.busy and L.hud.message.text == "Um cadeado enferrujado." and not Inventory.has("garrafada"), "a padlocked trunk: \"%s\"" % L.hud.message.text)
	for x in [c, bolts, locked]:
		x.queue_free()
	Inventory.reset(); Inventory.give_tools()


# --- the puzzle moves (east of the room): push the block, up the ledge, across the gap, up the wall -----------------
func course_tests() -> void:
	player.velocity = Vector3.ZERO; player.health = 99
	var b: Pushable = L.block
	put(player, b.global_position + Vector3(0, 0, 0.8), 0.0); player.pivot.rotation.y = 0.0  # south of it, W = north
	await wait(0.3)
	Audio.heard.clear()
	Input.action_press("forward")
	var pushing := await until(func(): return player.action == "Push", 2.0)
	await wait(0.5); await shot("50_empurrar")
	await until(func(): return b.global_position.z < 3.02, 2.0)  # one step done...
	var gaps := 0
	for k in 40:  # ...and on into the next ones without a stop while W is held
		await wait(0.03)
		if player.action != "Push":
			gaps += 1
	Input.action_release("forward")
	await until(func(): return not b.moving, 2.0); await wait(0.3)
	var z := b.global_position.z
	check(pushing and gaps == 0 and z < 2.02 and absf(z - roundf(z)) < 0.02 and absf(b.global_position.x - 8.0) < 0.01
		and "pedra_arrastar" in Audio.heard and not player.busy and player.action == "",
		"W held: he keeps pushing, step after step with no stop, until W is let go (z %.2f)" % z)
	var stone := Pushable.make(L, Vector3(3, 0, 3.2))  # the pillar at (3, 2) right behind it
	await wait(0.2)
	put(player, stone.global_position + Vector3(0, 0, 0.8), 0.0)
	Input.action_press("forward"); await wait(1.2); Input.action_release("forward")
	check(is_equal_approx(stone.global_position.z, 3.2) and player.action != "Push", "a block with a pillar behind it does not move")
	stone.queue_free()
	put(player, b.global_position + Vector3(0.8, 0, 0), PI / 2); await wait(0.3)  # beside the block, facing it
	check(L.hud.prompt.text == "E · subir", "the block can be climbed too: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await until(func(): return not player.busy and player.action == "", 3.0)
	check(player.global_position.y > 0.95 and absf(player.global_position.x - b.global_position.x) < 0.45,
		"E: up onto the block, from its side (y %.2f)" % player.global_position.y)
	# the ledge, from its east side
	put(player, Vector3(12.0, 0, -2), PI / 2); await wait(0.3)
	check(L.hud.prompt.text == "E · subir", "at the foot of a ledge, any side: \"%s\"" % L.hud.prompt.text)
	await tap("interact")
	await until(func(): return player.action == "Climb_Ledge" and player.action_t > 0.5, 2.0)
	await shot("51_subir")
	var up := await until(func(): return not player.busy, 3.0)
	await wait(0.2)
	check(up and player.global_position.y > 1.2 and player.global_position.x < 11.3 and player.lantern_out and not player.lantern_hung(),
		"E: up onto it, the lantern back in hand (y %.2f x %.2f)" % [player.global_position.y, player.global_position.x])
	# the gap
	put(player, Vector3(10, 1.26, -2.4), 0.0); await wait(0.3)
	check(L.hud.prompt.text == "Espaço · pular", "at the edge of a gap: \"%s\"" % L.hud.prompt.text)
	Audio.heard.clear(); await tap("dodge")
	await until(func(): return player.action == "Jump" and player.action_t > 0.42, 2.0)
	await shot("52_pulo")
	var mid := player.global_position
	var over := await until(func(): return not player.busy, 2.0)
	await wait(0.4)
	check(over and mid.y > 1.5 and absf(player.global_position.z + 5.4) < 0.05 and player.global_position.y > 1.2 and "pouso" in Audio.heard,
		"Space: across the gap (%.1f m up mid-air), landing on the far side" % (mid.y - 1.25))
	await tap("draw"); await wait(1.3); await wait(0.1)
	check(L.hud.prompt.text == "", "machete out: no jump on offer (Space is the dodge)")
	await tap("draw"); await wait(1.3)
	# the wall
	put(player, Vector3(7.6, 0, -9.0), PI / 2); await wait(0.3)
	check(L.hud.prompt.text == "", "the wall's plain side: no holds, nothing to climb")
	put(player, Vector3(6, 0, -7.4), 0.0); await wait(0.3)
	check(L.hud.prompt.text == "E · escalar", "at the foot of a wall: \"%s\"" % L.hud.prompt.text)
	await tap("interact")
	var on := await until(func(): return player.mode == Player.Mode.CLIMB, 2.0)
	Input.action_press("forward"); await wait(1.5); Input.action_release("forward")
	await until(func(): return player.action == "", 1.0)
	var h := player.global_position.y
	await shot("53_escalar")
	check(on and h > 0.9 and player.busy, "E: flat against it; W climbs hold by hold (%.1f m)" % h)
	Input.action_press("back")
	var off := await until(func(): return player.mode == Player.Mode.EXPLORE and not player.busy, 6.0)
	Input.action_release("back")
	check(off and player.global_position.y < 0.05, "S climbs back down and lets go at the foot")
	await tap("interact"); await until(func(): return player.mode == Player.Mode.CLIMB, 2.0)
	Input.action_press("forward")
	var topped := await until(func(): return not player.busy, 12.0)
	Input.action_release("forward")
	await wait(0.3); await shot("54_topo")
	check(topped and player.global_position.y > 3.4 and player.global_position.z < -8.3 and player.mode == Player.Mode.EXPLORE,
		"W to the top: over it and standing up there (y %.2f)" % player.global_position.y)
	# up there he is out of a mutant's reach: it comes to the foot of the wall but never strikes
	var hp := player.health
	var m: Mutante = L.add_enemy(Mutante.new(), Vector3(6, 0, -6.5), PI)
	m.target = player; m.active = true; m.go(Enemy.State.CHASE, "Walk")
	await put(player, Vector3(6, 3.51, -8.6), PI); player.velocity = Vector3.ZERO
	var below := await until(func(): return Vector2(m.global_position.x - 6, m.global_position.z + 8.6).length() < 1.3, 6.0)
	var struck := false
	for k in 40:
		await wait(0.1)
		struck = struck or m.state == Enemy.State.ATTACK
	await shot("55_fora_de_alcance")
	check(below and not struck and player.health == hp, "on the wall top, the mutant right below (%.1f m flat) never strikes: hp %.2f -> %.2f"
		% [Vector2(m.global_position.x - 6, m.global_position.z + 8.6).length(), hp, player.health])
	m.active = false; m.queue_free()
	put(player, Vector3(0, 0, 4), 0.0); await wait(0.5)


# --- stairs (west of the room): he walks up and down them; an edge too high stops him; a mutant follows him up ------
func steps_tests() -> void:
	player.velocity = Vector3.ZERO; player.health = 99
	put(player, Vector3(-9, 0, 4.6), 0.0); player.pivot.rotation.y = 0.0; await wait(0.4)
	Input.action_press("forward")
	var up := await until(func(): return player.global_position.y > 0.95 and player.global_position.z < 1.6, 4.0)
	Input.action_release("forward")
	await shot("60_escada")
	check(up, "W into the stairs: up them, onto the 1 m landing (y %.2f z %.2f)" % [player.global_position.y, player.global_position.z])
	await wait(0.3)
	check(absf(player.model.position.y) < 0.02, "...the body caught up with each step (lag %.3f)" % player.model.position.y)
	put(player, Vector3(-9, 1.0, 1.5), PI); player.pivot.rotation.y = PI; await wait(0.3)
	Input.action_press("forward")
	var airborne := 0
	var t0 := Time.get_ticks_msec()
	while player.global_position.z < 4.3 and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().physics_frame
		if not player.is_on_floor():
			airborne += 1
	Input.action_release("forward")
	check(player.global_position.y < 0.05 and player.global_position.z >= 4.3 and airborne <= 2,
		"...and down them on his feet, not hopping off each step (%d frames in the air)" % airborne)
	put(player, Vector3(-6, 0, 3.6), 0.0); player.pivot.rotation.y = 0.0; await wait(0.3)
	Input.action_press("forward")
	var high := await until(func(): return player.global_position.y > 0.4 and player.global_position.z < 2.6, 2.0)
	await shot("61_degrau_alto")
	Input.action_release("forward"); await wait(0.4)
	check(high and absf(player.global_position.y - 0.45) < 0.03 and absf(player.model.position.y) < 0.02,
		"a 45 cm step (a porch's): up it in stride (y %.2f)" % player.global_position.y)
	put(player, Vector3(-12.5, 0, 3.6), 0.0); player.pivot.rotation.y = 0.0; await wait(0.3)
	Input.action_press("forward"); await wait(1.2); Input.action_release("forward")
	check(player.global_position.y < 0.05 and player.global_position.z > 3.0, "a 60 cm block is no step: it stops him (y %.2f)" % player.global_position.y)
	put(player, Vector3(-9, 1.0, 1.2), PI); await wait(0.2)
	var m: Mutante = L.add_enemy(Mutante.new(), Vector3(-9, 0, 6.5), PI)
	m.target = player; m.active = true; m.go(Enemy.State.CHASE, "Walk")
	var climbed := await until(func(): return m.global_position.y > 0.7, 10.0)
	check(climbed, "a mutant follows him up the stairs (y %.2f)" % m.global_position.y)
	m.active = false; m.queue_free()
	put(player, Vector3(0, 0, 4), 0.0); await wait(0.3)

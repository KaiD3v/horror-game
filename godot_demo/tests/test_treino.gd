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
		"winded: he pants and the screen's edges darken, no bar (tired %.2f pant %s edges %s bar %s)"
		% [player.condition.tired, player.condition.pant.playing, L.hud.vision.visible, stamina_hud()])
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
	await pull_tests()
	await steps_tests()
	await descend_tests()
	await hud_tests()
	await equip_tests()
	await pause_tests()
	await save_tests()
	await keys_tests()
	await caderno_tests()
	await progression_tests()
	await hints_tests()
	player.health = 2

	player.take_damage(2); await wait(1.8); await shot("9_dead")
	check(player.mode == Player.Mode.DEAD, "dies at 0 hp")
	var p := player.global_position
	await press("forward", 0.5)
	check(player.global_position.distance_to(p) < 0.05, "no control after death")
	await wait(2.2)
	check(not player.condition.breath.playing and not player.condition.heart.playing, "dead: the breathing and the heart stop")
	await death_tests()



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
	check(WeaponWheel.slice_at(Vector2(-50, -50)) == 0 and WeaponWheel.slice_at(Vector2(50, -50)) == 1
		and WeaponWheel.slice_at(Vector2(50, 50)) == 2 and WeaponWheel.slice_at(Vector2(-50, 50)) == 3
		and WeaponWheel.slice_at(Vector2(5, 5)) == -1,
		"the tablets: machete upper left, crossbow upper right, pickaxe lower right, lantern lower left, nothing in the middle")
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
	check(by_keys == 3 and player.mode == Player.Mode.EXPLORE and not player.crossbow_in_hand() and not player.lantern_hung(),
		"A+S points at the lantern: the crossbow holstered, the lantern back in hand")
	Input.action_press("weapons"); await wait(0.1)
	Input.action_release("weapons"); await wait(0.4)
	check(player.mode == Player.Mode.EXPLORE and player.action == "", "let go without pointing: nothing changes")
	Input.action_press("weapons"); await wait(0.1); await _swipe(2)
	check(W.centre.text == "Picareta" and W.note.text == "quebra pedra", "the pickaxe's tablet (%s)" % W.note.text)
	await shot("2w_wheel_picareta")
	Input.action_release("weapons"); await wait(1.4)
	check(player.mode == Player.Mode.COMBAT and player.held == "picareta" and player.tool_hand.shape.visible, "...let go on it: the pickaxe in hand")
	Input.action_press("weapons"); await wait(0.1); await _swipe(0)
	Input.action_release("weapons"); await wait(2.8)
	check(player.mode == Player.Mode.COMBAT and player.held == "facao" and player.machete_in_hand() and player.wanted == -1,
		"pickaxe -> machete in one pick: put away, the machete drawn")
	await player.free_hands()

	var keys := {}
	for a in ["draw", "crossbow", "lantern", "heal", "weapons"]:
		keys[a] = (InputMap.action_get_events(a)[0] as InputEventKey).physical_keycode
	check(keys == {"draw": KEY_1, "crossbow": KEY_2, "lantern": KEY_3, "heal": KEY_F, "weapons": KEY_Q},
		"keys: 1 machete, 2 crossbow, 3 lantern, F bandage, Q the wheel")
	await tap("crossbow"); await wait(1.4)
	await tap("draw"); await wait(2.8)
	check(player.mode == Player.Mode.COMBAT and player.machete_in_hand() and not player.crossbow_in_hand(),
		"crossbow out, 1: holstered and the machete drawn")
	await tap("lantern"); await wait(1.0)
	check(player.mode == Player.Mode.COMBAT and player.machete_in_hand() and not player.lantern_out,
		"3 with the machete out: the lantern onto its hook, the machete stays")
	await tap("lantern"); await wait(1.0)
	await tap("draw"); await wait(1.3)
	check(player.mode == Player.Mode.EXPLORE and not player.machete_in_hand() and not player.lantern_hung(),
		"3 again and 1: the lantern back in hand, the machete sheathed")
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
	check(player.loaded and Inventory.count("virote") == 0 and L.hud.status.rows.has("virote"), "a reload takes a bolt from the quiver (%d left)" % Inventory.count("virote"))
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
	check(Shop.offers("armaria").all(func(o): return o.item != "besta"), "the crossbow is not for sale (it is found)")
	Inventory.add("besta")
	check(Shop.buy("armaria", 0) == Shop.Result.OK and Inventory.count("virote") == 9, "with the crossbow, the bolts")
	Inventory.items.erase("besta")
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
	check(L.hud.prompt.text.begins_with("E · subir"), "the block can be climbed too: \"%s\"" % L.hud.prompt.text)
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
	check(L.hud.prompt.text != "Espaço · pular", "machete out: no jump on offer (Space is the dodge): \"%s\"" % L.hud.prompt.text)
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
# --- the block held (right button at a side): S pulls it out after him, W pushes, letting go lets go ----------------
func pull_tests() -> void:
	var b: Pushable = L.block
	var start := b.global_position
	player.velocity = Vector3.ZERO
	if player.mode != Player.Mode.EXPLORE:
		await tap("draw"); await wait(1.2)
	put(player, b.global_position + Vector3(0, 0, 0.8), 0.0); player.pivot.rotation.y = 0.0; await wait(0.4)
	check(L.hud.prompt.text.ends_with("Botão direito · segurar"), "at the block: \"%s\"" % L.hud.prompt.text)
	Input.action_press("block"); await wait(0.4)
	check(b.held != Vector3.ZERO and player.busy and L.hud.prompt.text == Hints.TEXT.puxar or Hints.learned("puxar"),
		"right button: he takes hold of it (\"%s\")" % L.hud.prompt.text)
	Input.action_press("back")
	await until(func(): return b.global_position.z > start.z + 0.98, 4.0)
	Input.action_release("back"); await until(func(): return not b.moving, 4.0); await wait(0.3)
	var z := b.global_position.z
	check(z > start.z + 0.98 and absf(z - roundf(z)) < 0.02, "S: pulled towards him, a step at a time (z %.2f -> %.2f)" % [start.z, z])
	await shot("58_puxar")
	Input.action_press("forward")
	await until(func(): return b.global_position.z < start.z + 0.02, 8.0)
	Input.action_release("forward"); await until(func(): return not b.moving, 4.0); await wait(0.3)
	check(absf(b.global_position.z - start.z) < 0.02 and player.busy, "W while holding it: pushed back, still holding")
	Input.action_release("block"); await wait(0.3)
	check(b.held == Vector3.ZERO and not player.busy, "the button let go: he lets go of it")
	b.global_position = start


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


# --- coming down (the course): backwards over an edge, hanging; and what a drop costs -------------------------------
func descend_tests() -> void:
	player.velocity = Vector3.ZERO; player.health = 3.0
	put(player, Vector3(11.1, 1.26, -2), -PI / 2); await wait(0.4)  # on the first ledge, near its east edge
	check(L.hud.prompt.text == "E · descer", "on top, near the edge: \"%s\"" % L.hud.prompt.text)
	await tap("interact")
	await until(func(): return player.action == "Climb_Ledge" and player.action_t > 0.9, 2.0)
	await shot("56_descer")
	var down := await until(func(): return not player.busy, 3.0)
	await wait(0.3)
	check(down and player.global_position.y < 0.05 and player.global_position.x > 11.6 and player.health == 3.0,
		"E: down over the edge, backwards, hanging by his hands, to the ground unhurt (x %.2f y %.2f)" % [player.global_position.x, player.global_position.y])
	put(player, Vector3(6, 3.51, -8.6), PI); await wait(0.4)  # on the wall top, by its face
	check(L.hud.prompt.text == "E · descer", "on the wall top, by the face with the holds: \"%s\"" % L.hud.prompt.text)
	await tap("interact")
	var hanging := await until(func(): return player.mode == Player.Mode.CLIMB and player.action == "", 4.0)
	await shot("57_descer_muro")
	check(hanging and player.busy and absf(player.global_position.y - (3.5 - Climbable.LEDGE)) < 0.05,
		"E: over the top onto the wall's holds (y %.2f)" % player.global_position.y)
	Input.action_press("back")
	var foot := await until(func(): return not player.busy, 10.0)
	Input.action_release("back")
	check(foot and player.global_position.y < 0.05 and player.mode == Player.Mode.EXPLORE and player.health == 3.0,
		"S hold by hold down to the foot of it, unhurt")
	check(Player.fall_damage(2.0) == 0 and Player.fall_damage(3.5) == 1 and Player.fall_damage(5.0) == 2 and Player.fall_damage(6.6) == 3,
		"a drop: 2 m nothing, 3.5 m one wound, 5 m two, 6.6 m three (dead)")
	put(player, Vector3(6.5, 3.51, -9.8), -PI / 2); player.pivot.rotation.y = -PI / 2; await wait(0.4)
	Audio.heard.clear()
	Input.action_press("forward")
	await until(func(): return player.global_position.x > 7.4 and player.is_on_floor() and player.global_position.y < 0.1, 4.0)
	Input.action_release("forward"); await wait(0.3)
	check(player.health == 2.0 and "pouso" in Audio.heard and L.hud.message.text == "A queda o machucou.",
		"walking off the 3.5 m top: a hard landing, one wound (hp %.1f)" % player.health)
	put(player, Vector3(0, 5.0, 6), 0.0); await until(func(): return player.global_position.y < 0.1 and player.is_on_floor(), 3.0); await wait(0.2)
	check(player.health == 0.0 and player.mode == Player.Mode.DEAD, "5 m more with two wounds left: dead (hp %.1f)" % player.health)
	player.health = player.max_health; player.set_mode(Player.Mode.EXPLORE)  # up again for the tests after


## The corners (HudStatus): empty while nothing changes; a blow shows the hearts, spent breath the beads, a count that
## changes its row (+N), the crossbow its bolts while it is out; each fades after HOLD. More max health / stamina:
## more hearts / beads.
func hud_tests() -> void:
	var st: HudStatus = L.hud.status
	var gone := HudStatus.HOLD + HudStatus.FADE + 0.2
	Inventory.give_tools()
	player.health = player.max_health; player.stamina = player.stamina_max; player.winded = false
	if player.mode == Player.Mode.CROUCH:
		await tap("crouch"); await wait(0.6)
	await wait(gone)
	check(st.hearts_t <= 0.0 and st.beads_t <= 0.0 and st.rows.is_empty(), "nothing in the corners while nothing changes")
	player.take_damage(1); await wait(0.2)
	check(st.hearts_t > HudStatus.HOLD and st.beads_t <= 0.0, "a blow shows the hearts, only them")
	await wait(gone)
	check(st.hearts_t <= 0.0, "...and they fade")
	player.stamina = 1.0; player.rest = 0.0; await wait(0.2)
	check(st.beads_t > HudStatus.HOLD and st.hearts_t <= 0.0, "spent breath shows the beads")
	player.stamina = player.stamina_max; await wait(gone)
	check(st.beads_t <= 0.0, "...gone once full")
	Inventory.add("atadura", 2); await wait(0.2)
	check(st.rows.has("atadura") and st.delta_n.get("atadura", 0) == 2 and not st.rows.has("virote"), "a count that changes shows (+2)")
	await tap("crossbow"); await wait(1.4)
	await wait(gone)
	check(st.rows.has("virote") and not st.rows.has("atadura"), "the crossbow out: its bolts stay; the bandages faded")
	player.health = 1.25; player.stamina = 2.2; player.max_health = 4; player.stamina_max = 5.0
	Inventory.add("virote", 3); Inventory.money += 20; await wait(0.3)
	check(st.glow_t > 0.0 and st.hearts_t > 0.0 and st.rows.has("dinheiro"), "a new heart glows in; money that comes in shows")
	await shot("hud")
	await tap("crossbow"); await wait(1.2)
	await wait(gone)
	check(st.rows.is_empty(), "the crossbow away: its bolts fade too")
	player.max_health = 3; player.stamina_max = Player.STAMINA_MAX
	player.health = player.max_health; player.stamina = player.stamina_max


func _hips_y() -> float:
	return player.skeleton.get_bone_global_pose(player.skeleton.find_bone("hips")).origin.y


func _speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()


## What goes with what: reloading, drawing and sheathing on the move; the lantern hung / taken with the machete in
## the other hand; crouching with either weapon (and staying down through draw, sheathe, aim, shot); 3 with the
## crossbow out puts it away for the lantern.
func equip_tests() -> void:
	Inventory.give_tools(); Inventory.items["virote"] = 5
	player.health = player.max_health; player.stamina = player.stamina_max; player.winded = false
	if player.mode != Player.Mode.EXPLORE:
		await player.free_hands()
	if not player.lantern_out:
		await tap("lantern"); await wait(0.8)
	var p0 := player.global_position
	# the crossbow, reloaded while jogging, then while sprinting
	await tap("crossbow"); await wait(1.4)
	Input.action_press("back"); await wait(0.6)
	await tap("reload"); await wait(0.5)
	var rv := _speed()
	check(player.action == "Reload_Crossbow" and rv > Player.JOG_SPEED - 0.1, "reloading while jogging: he keeps going (%.2f m/s)" % rv)
	await until(func(): return player.action == "", 3.0)
	check(player.loaded, "...and the bolt is on the rail")
	player.global_position = p0
	Input.action_press("block"); await wait(0.3); await tap("attack"); await wait(0.5); Input.action_release("block")
	Input.action_press("sprint"); await wait(0.4)
	await tap("reload"); await wait(0.5)
	rv = _speed()
	Input.action_release("sprint"); Input.action_release("back")
	check(player.action == "Reload_Crossbow" and rv > Player.RUN_SPEED - 0.2, "...and while sprinting (%.2f m/s)" % rv)
	await until(func(): return player.action == "", 3.0)
	player.global_position = p0; player.velocity = Vector3.ZERO; await wait(0.3)
	# crouched with the crossbow: aim and shoot down there
	var stand_y := _hips_y()
	await tap("crouch"); await wait(0.5)
	check(player.crouched and player.mode == Player.Mode.XBOW and _hips_y() < stand_y - 0.2,
		"C with the crossbow out: he kneels, the crossbow stays (hips %.2f -> %.2f m)" % [stand_y, _hips_y()])
	Input.action_press("block"); await wait(0.4)
	check(player.aiming and player.crouched and player.cam_now.height < Player.CAM_AIM.height - 0.25, "...aims kneeling, the camera low")
	await shot("equip_xbow_crouch")
	await tap("attack"); await wait(0.6)
	Input.action_release("block")
	check(not player.loaded and player.crouched, "...and shoots without getting up")
	Input.action_press("back"); await wait(0.6)
	var cv := _speed(); Input.action_release("back")
	check(absf(cv - Player.CROUCH_SPEED) < 0.05, "...sneaks with it (%.2f m/s)" % cv)
	# 3 with the crossbow out: it goes away, the lantern comes to hand; he stays down
	await tap("lantern"); await until(func(): return player.mode != Player.Mode.XBOW and player.action == "", 3.0)
	check(player.mode == Player.Mode.CROUCH and player.lantern_out and player.crouched, "3 with the crossbow: holstered, the lantern back, still crouched")
	# the machete drawn crouched: still down; sheathed: still down
	await tap("draw"); await until(func(): return player.action == "", 2.0)
	check(player.mode == Player.Mode.COMBAT and player.crouched and _hips_y() < stand_y - 0.2, "1 crouched: the machete out, he stays down")
	await shot("equip_machete_crouch")
	await tap("crouch"); await wait(0.4)
	check(not player.crouched and _hips_y() > stand_y - 0.1, "C again: up, the machete still out")
	# the lantern with the machete in the other hand
	await tap("lantern"); await wait(0.8)
	var hung := [false]
	player.skeleton.skeleton_updated.connect(func(): hung[0] = player.lantern_hung(), CONNECT_ONE_SHOT)
	await player.skeleton.skeleton_updated
	check(player.mode == Player.Mode.COMBAT and player.machete_in_hand() and not player.lantern_out and hung[0],
		"3 with the machete out: the lantern onto its hook, the machete stays in hand")
	await tap("lantern"); await wait(0.8)
	check(player.mode == Player.Mode.COMBAT and player.lantern_out and not player.lantern_hung(), "3 again: back in hand, machete still out")
	# sheathing on the move
	player.global_position = p0
	Input.action_press("back"); await wait(0.6)
	await tap("draw"); await wait(0.3)
	var dv := _speed(); Input.action_release("back")
	check(player.action == "Draw_Machete" and dv > Player.JOG_SPEED - 0.1, "sheathing while jogging (%.2f m/s)" % dv)
	await until(func(): return player.action == "", 2.0)
	# a swing stands him up
	await tap("draw"); await until(func(): return player.action == "", 2.0)
	await tap("crouch"); await wait(0.4)
	await tap("attack"); await wait(0.2)
	check(not player.crouched and player.action == "Attack_Slash", "a swing from crouched stands him up")
	await until(func(): return player.action == "", 2.0)
	await player.free_hands()
	check(player.mode == Player.Mode.EXPLORE and not player.crouched, "free_hands: everything away, on his feet")
	player.global_position = p0; player.velocity = Vector3.ZERO


## Esc: the pause menu stops the game; Esc again (or Continuar) goes back; Controles over it; not over the notes.
# --- Hints (../docs/TUTORIAL_VILAREJO.md): no controls line; a key on the prompt line when the world asks for it,
# until he has done it twice, then never again ----------------------------------------------------------------------
func hints_tests() -> void:
	Story.reset(); Inventory.give_tools()
	var line: Label = L.hud.prompt
	check(L.hud.get("legend") == null, "no controls line on the HUD (they are in the pause menu)")
	put(player, Vector3(-3.0, 0.0, -6.0), 0.0); await wait(0.4)
	check(not line.visible, "nothing asked: an empty prompt line")
	await tap("crossbow"); await wait(1.4)
	check(line.visible and line.text == Hints.TEXT.mirar, "the crossbow out, not aimed: \"%s\"" % line.text)
	for i in 2:
		await press("block", 0.4); await wait(0.3)
	check(Hints.learned("mirar") and not line.visible, "aimed twice: the line is gone for good")
	await tap("crossbow"); await wait(1.2)
	await tap("draw"); await wait(1.0)
	var e: Enemy = L.add_enemy(Mutante.new(), player.global_position + Vector3(0, 0, -3), 0.0)  # (the room's may be dead by now)
	e.active = false
	e.target = player; e.go(Enemy.State.ATTACK, "Attack"); await wait(0.1)
	check(line.text == Hints.TEXT.bloquear and line.visible, "a blow coming at the machete: \"%s\"" % line.text)
	e.go(Enemy.State.IDLE, "Idle")
	for i in 2:
		await press("block", 0.3); await wait(0.2)
	e.go(Enemy.State.ATTACK, "Attack"); await wait(0.1)
	check(Hints.learned("bloquear") and not line.visible, "blocked twice: no line at the next blow")
	e.queue_free()
	await tap("draw"); await wait(1.0)
	Inventory.add("atadura", 2)
	for i in 2:
		player.take_damage(1); await wait(0.2)
		check(i == 1 or line.text == Hints.TEXT.curativo, "hurt, with a bandage: \"%s\"" % line.text)
		await tap("heal"); await wait(0.6)
	player.take_damage(1); await wait(0.2)
	check(Hints.learned("curativo") and not line.visible, "dressed twice: hurt again, no line")
	player.health = player.max_health
	Hints.want(player, "lamparina", 4.0); await wait(0.1)
	check(line.text == Hints.TEXT.lamparina, "the light called something: \"%s\"" % line.text)
	for i in 3:  # hung, back in hand, hung: twice on the hook
		await tap("lantern"); await wait(0.9)
	check(Hints.learned("lamparina") and not player.holds_lantern(), "hung on the hook twice: learned")
	await tap("lantern"); await wait(0.9)
	Story.reset()


func pause_tests() -> void:
	var m: GameMenu = L.menu
	await wait(0.5)
	await tap("ui_cancel"); await wait(0.2)
	check(m.paused and get_tree().paused and m.veil.visible and m.buttons.size() == 4 and m.buttons[0].text == "•  Continuar",
		"Esc pauses: Continuar, Controles, Voltar ao menu, Sair do jogo")
	check(m.line.visible and m.line.text == "teste: H dano", "the room's test key under Pausa (\"%s\")" % m.line.text)
	await shot("pausa")
	await tap("ui_down"); await tap("ui_accept")
	check(m.controls.visible, "Controles opens over it")
	await tap("ui_cancel")
	check(not m.controls.visible and m.paused, "Esc closes Controles, still paused")
	await tap("ui_cancel")
	check(not m.paused and not get_tree().paused and not m.veil.visible, "Esc again: back to the game")
	await tap("ui_cancel"); m.buttons[2].pressed.emit(); await wait(0.1)
	check(SceneRouter.requested == Paths.MENU and not get_tree().paused, "Voltar ao menu goes to the title")
	m.pause(false)
	NotesReader.read.append(NotesData.NOTES[0].id)
	await tap("notes"); await wait(0.2)
	await tap("ui_cancel"); await wait(0.2)
	check(not m.paused and not get_tree().paused, "Esc over the notes closes them, no pause")
	NotesReader.read.pop_back()


## Dying: after a while "Morreu." and the hour, Tentar de novo (this scene again) / Voltar ao menu / Sair do jogo.
func death_tests() -> void:
	var m: GameMenu = L.menu
	if player.mode != Player.Mode.DEAD:
		player.take_damage(99)
	await until(func(): return m.dead, GameMenu.DEATH_DELAY + 1.0); await wait(GameMenu.FADE)
	check(m.veil.visible and m.title.text == "Morreu." and m.buttons.size() == 3 and m.buttons[0].text == "•  Tentar de novo",
		"dead: \"Morreu.\" (%s), Tentar de novo, Voltar ao menu, Sair do jogo" % m.line.text)
	await shot("morte")
	await tap("ui_cancel")
	check(not m.paused, "no pause menu over death")
	await tap("ui_accept"); await wait(0.1)
	check(SceneRouter.requested == L.scene_file_path, "Tentar de novo: this scene again")


## The oratório saves (SaveGame): E, a prayer, the candle lit for good, "Jogo salvo."; what the save holds comes back
## on loading it; dying, "Tentar de novo" puts back how the scene was when he came in; a restored game places him.
func save_tests() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path()))
	check(not SaveGame.exists(), "no save yet (the tests' own file)")
	if player.mode != Player.Mode.EXPLORE:
		await player.free_hands()
	var o: Oratorio = L.find_children("*", "Oratorio", true, false)[0]
	put(player, o.global_position + o.global_basis.z * 1.0, o.rotation.y); player.pivot.rotation.y = o.rotation.y
	await wait(0.4)
	check(L.hud.prompt.text == "E · rezar no oratório", "at the oratório: \"%s\"" % L.hud.prompt.text)
	Inventory.money = 77; Inventory.items["virote"] = 4; player.health = 2.0
	await tap("interact")
	await until(func(): return not player.busy, 4.0)
	await shot("oratorio")
	check(SaveGame.exists() and L.hud.message.text == "Jogo salvo." and Story.has("oratorio:" + o.id) and o.flame.light_energy > 0.5,
		"E: he prays, the candle lit, \"%s\"" % L.hud.message.text)
	var saved := SaveGame.read()
	check(saved.cena == L.scene_file_path and saved.dinheiro == 77 and saved.itens.virote == 4 and saved.vida == 2.0,
		"the save holds the scene, the money, the bolts, his health")
	# what happened since is undone by loading it
	Inventory.money = 5; Inventory.items["virote"] = 0; Chest.opened.append("x"); WorldTime.minutes += 300.0
	SaveGame.load_saved(L)
	check(Inventory.money == 77 and Inventory.count("virote") == 4 and "x" not in Chest.opened
		and SceneRouter.requested == L.scene_file_path and SaveGame.pending.cena == L.scene_file_path,
		"Carregar: the money, the bolts, the trunks as saved; its scene next")
	# ...and the next level places him as saved
	player.health = 3.0; player.global_position += Vector3(2, 0, 0)
	var at := SaveGame.start(L.scene_file_path, Transform3D.IDENTITY)
	SaveGame.pending.lamparina = false
	SaveGame.settle(player, L.scene_file_path)
	check(at.origin.distance_to(saved.pos) < 0.01 and player.health == 2.0 and not player.lantern_out and SaveGame.pending.is_empty(),
		"a restored game: where he saved, his health, the lantern on its hook")
	player._set_lantern(true); player.health = player.max_health
	# the return point: the scene as it was when he came in (settle took it just now)
	var money := Inventory.money
	Inventory.money = 0; Inventory.items["atadura"] = 0; Story.mark("algo")
	SaveGame.retry(L)
	check(Inventory.money == money and not Story.has("algo") and SceneRouter.requested == L.scene_file_path,
		"Tentar de novo: the money and what happened as when he came in")
	SaveGame.pending = {}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path()))


## The progression items (ItemCatalog): the crowbar, the pickaxe and the rope are tools (only shown to a lock); a key
## opens only its own lock and is spent on it, the lock staying open; each has its shape for the trunk.
func keys_tests() -> void:
	for id in ["pe_de_cabra", "picareta", "corda"]:
		check(ItemCatalog.tool(id), "%s: a tool" % id)
	check(ItemCatalog.key("chave_sacristia") and not ItemCatalog.key("corda") and not ItemCatalog.key(""), "chave_sacristia: a key")
	var all: Node = load(Paths.PROP % "itens").instantiate()
	for id in ["pe_de_cabra", "picareta", "corda", "chave_sacristia"]:
		check(all.find_child(ItemCatalog.item(id).get("modelo", id), false) != null, "%s: its shape in itens.glb" % id)
	all.free()
	var door := Interactable.new(); door.requires = "chave_sacristia"; L.add_child(door)
	var opened := [0]
	door.used.connect(func(_b): opened[0] += 1)
	Inventory.items.erase("chave_sacristia")
	door.use(player)
	check(opened[0] == 0 and L.hud.message.text == "Precisa de: Chave da sacristia.", "no key: locked (\"%s\")" % L.hud.message.text)
	Inventory.add("chave_sacristia")
	door.use(player)
	check(opened[0] == 1 and Inventory.count("chave_sacristia") == 0 and Story.has("destrancado:chave_sacristia")
		and L.hud.message.text == "Usou: Chave da sacristia.", "the key: it opens, and stays in the lock")
	door.use(player)
	check(opened[0] == 2, "...open for good after")
	var tool := Interactable.new(); tool.requires = "pe_de_cabra"; L.add_child(tool)
	Inventory.add("pe_de_cabra"); tool.use(player)
	check(Inventory.has("pe_de_cabra"), "a tool is not spent")
	door.queue_free(); tool.queue_free()


## Tab: the notebook pauses the game on Tarefas / Bolso / Notas; the tasks as they stand, the day, hour, money and all
## he carries (tools, keys, the rest), the notes to reread (and back to the notebook after); Tab closes.
func caderno_tests() -> void:
	var c: Caderno = L.caderno
	Caderno.section = 0; Story.reset()
	await tap("notes"); await wait(0.2)
	check(c.visible and get_tree().paused and c.empty.visible and c.empty.text == "Nada anotado ainda.", "Tab: the notebook, no tasks yet")
	await tap("notes"); await wait(0.1)
	check(not c.visible and not get_tree().paused, "Tab again closes it")
	Story.set_task("garrafada", "ativa")
	await tap("notes"); await wait(0.2)
	check(c.rows.size() == 1 and c.rows[0].text == "· A garrafada do altar" and c.detail.text.begins_with("Dona Firmina"),
		"a task going on, its description on the right page")
	await shot("caderno_tarefas")
	Story.set_task("garrafada", "feita"); c.show_section(0)
	check(c.rows[0].text.begins_with("+ ") and c.detail.text.ends_with("Cumprida."), "...done: marked off")
	Inventory.items["chave_sacristia"] = 1; Inventory.items["virote"] = 3
	await tap("right"); await wait(0.1)
	var names := c.rows.map(func(r): return r.text)
	check(Caderno.section == 1 and c.head.text.begins_with("Dia ") and ("Dinheiro: Cr$ %d" % Inventory.money) in c.head.text
		and WorldTime.clock() in c.head.text, "D: Bolso, the day, the hour and the money (%s)" % c.head.text.replace("
", " / "))
	check(names.find("Lamparina") < names.find("Chave da sacristia (1)") and names.find("Chave da sacristia (1)") < names.find("Virote (3)"),
		"...tools, then keys, then the rest: %s" % ", ".join(names))
	await tap("back"); await wait(0.1)
	check(c.title.text == ItemCatalog.item("facao").nome or c.title.text != "", "W/S: the right page tells about it (%s)" % c.title.text)
	await shot("caderno_bolso")
	NotesReader.read.append(NotesData.NOTES[0].id)
	await tap("right"); await wait(0.1)
	check(Caderno.section == 2 and c.rows.size() == 1 and c.rows[0].text == NotesData.NOTES[0].title, "D: Notas, the papers found")
	await tap("interact"); await wait(0.2)
	check(not c.visible and L.notes.page.visible and get_tree().paused, "E reads it")
	await tap("ui_cancel"); await wait(0.2)
	check(c.visible and get_tree().paused and not L.notes.page.visible, "...closing it, back to the notebook")
	await tap("ui_cancel"); await wait(0.1)
	check(not c.visible and not get_tree().paused, "Esc closes the notebook")
	NotesReader.read.pop_back(); Story.reset(); Inventory.items.erase("chave_sacristia")


## What the progression items open (the south of the room): the padlock (its key, spent on it), the boarded door (the
## crowbar: the planks forced off, "Porta aberta"), the heap of stone (the pickaxe in hand, blow by blow), the well (the
## rope tied, then down to the bottom scene).
func progression_tests() -> void:
	if player.mode != Player.Mode.EXPLORE:
		await player.free_hands()
	player.health = player.max_health
	# the padlock
	put(player, Vector3(-9, 0, 9.0), PI); await wait(0.3)
	check(L.hud.prompt.text == "E · abrir o cadeado", "the padlocked door: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(0.2)
	check(not Story.has("aberta:treino_cadeado") and L.hud.message.text == "Trancada com cadeado. Precisa da chave.", "no key: \"%s\"" % L.hud.message.text)
	put(player, Vector3(-9, 0, 7.6), PI); await wait(0.3)
	await tap("interact"); await wait(0.2)
	check(Inventory.has("chave_cadeado"), "the key picked up off the floor")
	put(player, Vector3(-9, 0, 9.0), PI); await wait(0.3)
	await tap("interact"); await wait(1.2)
	check(not Inventory.has("chave_cadeado") and L.locked.lock_shape == null and L.locked.leaf.rotation.y > 1.5 and not L.locked.enabled,
		"E with the key: the padlock gone, the key spent, the door open")
	await shot("prog_cadeado")
	# the boarded door
	Inventory.items.erase("pe_de_cabra")
	put(player, Vector3(-3, 0, 9.0), PI); await wait(0.3)
	await tap("interact"); await wait(0.2)
	check(L.hud.message.text.begins_with("Pregada com tábuas"), "no crowbar: \"%s\"" % L.hud.message.text)
	Inventory.add("pe_de_cabra")
	await tap("interact"); await wait(1.4)
	check(player.busy and player.action == "Push" or player.action == "", "the crowbar: he works at the planks")
	await shot("prog_pe_de_cabra")
	var banner: bool = await until(func(): return get_tree().get_first_node_in_group("found_banner") != null, 12.0)
	var fb: FoundBanner = get_tree().get_first_node_in_group("found_banner")
	check(banner and fb.name_l.text == "Porta aberta", "...the planks off: \"Porta aberta\"")
	await shot("prog_porta_aberta")
	await wait(0.9); await tap("interact"); await wait(1.2)
	check(Story.has("aberta:treino_tabuas") and L.boarded.leaf.rotation.y > 1.5 and not player.busy, "...and the door swings open")
	# the heap of stone
	put(player, Vector3(3, 0, 9.0), PI); await wait(0.3)
	check(L.hud.prompt.text == "E · pegar a picareta", "the heap: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await until(func(): return player.action == "", 2.0); await wait(0.2)
	var shape: Node3D = player.tool_hand.shape
	check(player.mode == Player.Mode.COMBAT and player.held == "picareta" and shape != null and shape.visible, "E: the pickaxe in his hand")
	var blade := [1.0]  # (a skeleton modifier: read once the modifiers have run)
	player.skeleton.skeleton_updated.connect(func(): blade[0] = player.skeleton.get_bone_pose_scale(player.skeleton.find_bone("machete")).x, CONNECT_ONE_SHOT)
	await player.skeleton.skeleton_updated
	check(blade[0] < 0.01, "...the machete hidden (scale %.3f)" % blade[0])
	var look := player.pivot.rotation.y
	player.pivot.rotation.y = player.rotation.y - 2.0; await wait(0.6)
	await shot("prog_picareta")
	player.pivot.rotation.y = look; await wait(0.3)
	var stones: int = L.rubble.pieces.size()
	player.stamina = player.stamina_max; player.attack("Attack_Slash"); await wait(0.9)
	check(L.rubble.pieces.size() == stones - 1, "a blow knocks a stone off (%d left)" % L.rubble.pieces.size())
	for k in 6:
		if not is_instance_valid(L.rubble) or L.rubble.pieces.is_empty():
			break
		player.stamina = player.stamina_max; player.attack("Attack_Overhead"); await wait(1.1)
	check(Story.has("quebrado:treino_entulho") and L.rubble.pieces.is_empty() and not is_instance_valid(L.rubble.body),
		"...until the heap is gone and the way open")
	await shot("prog_entulho")
	await tap("draw"); await until(func(): return player.held == "facao" and player.action == "" and player.mode == Player.Mode.COMBAT, 4.0)
	check(player.held == "facao" and player.machete_in_hand() and player.skeleton.get_bone_pose_scale(player.skeleton.find_bone("machete")).x > 0.9,
		"1: the pickaxe away, the machete back in hand")
	await player.free_hands()
	# the well
	Inventory.items.erase("corda")
	put(player, Vector3(9, 0, 8.1), PI); await wait(0.3)
	await tap("interact"); await wait(0.2)
	check(not L.well.roped() and L.hud.message.text.begins_with("Escuro e fundo"), "no rope: \"%s\"" % L.hud.message.text)
	Inventory.add("corda")
	await tap("interact"); await wait(0.2)
	check(L.well.roped() and L.well.rope != null and L.hud.prompt.text == "E · descer pela corda", "the rope tied: \"%s\"" % L.hud.prompt.text)
	check(["cadeado_abrir", "tabua_arrancar", "tabua_cair", "picareta_pedra", "entulho_desabar", "corda_amarrar"].all(func(n): return n in Audio.heard),
		"each made its own sound: %s" % ", ".join(Audio.heard.slice(-12)))
	await shot("prog_poco")
	await tap("interact"); await wait(0.2)
	check(SceneRouter.requested == "res://scenes/levels/poco.tscn" and Story.marks["poco:volta"] == [L.scene_file_path, "treino_poco"],
		"E again: down to the bottom of the well")
	var up: Transform3D = Well.arrival(L, "treino_poco", Transform3D.IDENTITY)
	check(up.origin.distance_to(L.well.position) < 2.0 and up.origin.z < L.well.position.z, "coming up: beside the well, in front of it")

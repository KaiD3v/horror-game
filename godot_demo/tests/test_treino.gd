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
	await tap("draw"); await wait(1.2)
	await tap("lantern"); await wait(0.8)
	check(player.lantern_out and not player.lantern_hung(), "L again takes it back in hand")
	player.global_position = l0; player.velocity = Vector3.ZERO; player.rotation.y = 0.0; player.coat.reset()
	await wait(0.3)

	await tap("crossbow"); await wait(1.4); await shot("2f_crossbow")
	check(player.mode == Player.Mode.XBOW and player.crossbow_in_hand(), "Q draws the crossbow into the right fist")
	check(player.lantern_hung(), "...the lantern hangs on its belt hook meanwhile")
	check(not player.loaded, "...and it comes out unloaded")
	await tap("reload"); await wait(0.9); await shot("2f_reload"); await wait(1.3)
	var sk: Skeleton3D = player.skeleton
	var drawn := sk.get_bone_global_pose(sk.find_bone("xbow.string")).origin.distance_to(
		sk.get_bone_global_pose(sk.find_bone("crossbow")).origin)
	check(player.loaded and player.action == "" and drawn < 0.12,
		"R reloads: string drawn back (%.2f m from the butt), a bolt from the quiver on the rail" % drawn)
	var target: Vector3 = L.dummy.global_position + Vector3(0, 1.0, 0) - player.cam.global_position  # crosshair on the dummy
	player.pivot.rotation.y = atan2(-target.x, -target.z); await wait(0.6)
	await tap("attack"); await wait(0.1); await shot("2g_loose"); await wait(0.5)
	check(L.dummy.hits == 1 and get_tree().get_nodes_in_group("bolt").size() == 1, "LMB looses a bolt into the dummy (hits=%d)" % L.dummy.hits)
	check(not player.loaded, "...and leaves it empty")
	L.dummy.hits = 0; L.dummy.damage = 0
	player.pivot.rotation.y = 0.0; await wait(0.3)
	await tap("crossbow"); await wait(1.4)
	check(player.mode == Player.Mode.EXPLORE and not player.crossbow_in_hand() and not player.lantern_hung(),
		"Q again holsters it and the lantern is back in hand")

	await tap("draw"); await wait(0.45); await shot("3_drawing"); await wait(0.7)
	check(player.mode == Player.Mode.COMBAT, "draw -> combat mode")
	check(player.machete_in_hand(), "machete in the left hand after drawing")

	await tap("attack"); await wait(0.33); await shot("4_slash"); await wait(0.6)
	check(L.dummy.hits == 1, "slash hits the dummy (hits=%d)" % L.dummy.hits)
	await tap("heavy"); await wait(0.43); await shot("5_overhead"); await wait(0.7)
	check(L.dummy.hits == 2 and L.dummy.damage == 3, "overhead hits harder (hits=%d dmg=%d)" % [L.dummy.hits, L.dummy.damage])
	await tap("attack"); await wait(0.45); await tap("attack"); await wait(1.5)
	check(L.dummy.hits == 4, "slash + LMB during follow-through combos into the overhead (hits=%d)" % L.dummy.hits)

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
	check(player.mode == Player.Mode.EXPLORE, "F again sheathes -> explore mode")
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
		await tap("heavy"); await wait(1.05)
	check(L.enemy.state == Enemy.State.DEAD, "machete kills the mutant (its hp=%d)" % L.enemy.health)
	await wait(1.6); await shot("13_mutant_dead")
	sounds_heard()
	await wound_tests()
	await inventory_tests()
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
	await tap("attack"); await wait(0.6)
	await tap("reload"); await wait(0.3)
	check(not player.loaded and player.action == "" and L.hud.message.text == "Sem virotes.", "no bolts, no reload: \"%s\"" % L.hud.message.text)
	await tap("crossbow"); await wait(1.4)
	Inventory.reset()

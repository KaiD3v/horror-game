# The Colônia greybox (scenes/levels/colonia.tscn): the navmesh and its low doors, the bolted shortcut, the mutant
# held at the church door and finding its way round, A Enfermeira, the notes.
extends AutoTest


func run() -> void:
	await wait(1.0); await shot("c1_portaria")
	check(L.nav.navigation_mesh.get_polygon_count() > 50, "navmesh baked (%d polygons)" % L.nav.navigation_mesh.get_polygon_count())
	check(L.reachable(Vector3(0, 0, 5), Vector3(-2, 0, 12)), "mutant can follow you from the yard into Pavilhão B")
	check(not L.reachable(Vector3(0, 0, 5), Vector3(0, 0, -14)), "the church's low door keeps the mutant out")
	check(not L.reachable(Vector3(5, 0, 12), Vector3(13, 0, 12)), "infirmary sealed to it while the shortcut is bolted")
	await map_shot("c0_mapa", Vector3(1.5, 40, 1.5), 46, 2.5, L.ceilings,
		func(c): return L.reachable(Vector3(0, 0, 6), c), 0.45)  # red: where the mutant can walk from the yard

	put(player, Vector3(-7, 0, 0), -PI / 2); await wait(0.6); await shot("c2_patio")
	put(player, Vector3(-6, 0, 11), -PI / 2); await wait(0.6); await shot("c3_pavilhao")
	put(player, Vector3(8.6, 0, 13), -PI / 2)
	Input.action_press("forward")  # held until through (a fixed time is at the mercy of a first-run shader hitch)
	await until(func(): return player.global_position.x > 10.5, 12.0)  # wall-clock: allow a shader hitch
	Input.action_release("forward")
	check(player.global_position.x > 10.5, "the player fits through the low door (x=%.2f)" % player.global_position.x)

	put(player, Vector3(15, 0, 0.8), PI); await wait(0.2)
	await tap("interact"); await wait(0.2)
	check(is_instance_valid(L.shortcut) and L.hud.message.text.begins_with("Trancada"), "shortcut won't open from the refectory")
	put(player, Vector3(15, 0, 3.2), 0.0); await wait(0.2)
	await tap("interact"); await wait(0.6)
	check(not is_instance_valid(L.shortcut), "E unbolts the shortcut from the infirmary side")
	check(L.reachable(Vector3(5, 0, 12), Vector3(13, 0, 12)), "...and the infirmary is now reachable for it")

	# the mutant gives chase into the church and has to stop at the low door
	player.health = 99
	put(player, Vector3(1.5, 0, -13.5), 0.0)
	put(L.enemy, Vector3(3, 0, -5), PI)
	L.enemy.target = player; L.enemy.active = true; L.enemy.go(Enemy.State.CHASE, "Walk")
	put(player, Vector3(1.5, 0, -13.5), PI)  # looking back at the door
	await wait(6.0); await shot("c4_porta_baixa")
	check(L.enemy.global_position.z > -10.0, "it stops at the church's low door (z=%.2f)" % L.enemy.global_position.z)

	# it walks round the ward wall, through the door, to reach you
	put(L.enemy, Vector3(6, 0, 6), 0.0); put(player, Vector3(0, 0, 13), -PI / 2)
	L.enemy.go(Enemy.State.CHASE, "Walk")
	var ok = await until(func(): return L.enemy.global_position.distance_to(player.global_position) < 2.2, 25.0)
	await shot("c5_contorna")
	check(ok, "it paths around the wall and through the ward door (%.1f m away)" % L.enemy.global_position.distance_to(player.global_position))
	L.enemy.active = false; put(L.enemy, Vector3(-13, 0, 1), 0.0)  # out of the way, in the gatehouse
	await nurse_tests()
	await notes_suite()



func nurse_tests() -> void:
	# A Enfermeira, in the infirmary: she closes in from behind, freezes when lit and looked at, comes on in the dark
	player.health = 99
	put(player, Vector3(12, 0, 9), PI / 2)  # facing the low door (west), she is 6 m behind (east)
	put(L.nurse, Vector3(18, 0, 9), PI / 2)
	L.nurse.target = player; L.nurse.active = true
	await wait(1.0)
	var d = L.nurse.global_position.distance_to(player.global_position)
	check(L.nurse.state == Enemy.State.CHASE and d < 5.2, "the nurse stalks you from behind (%.1f m away)" % d)
	check(L.nurse.chain.volume_db > -30.0, "her keys tinkle while she moves (%.0f dB)" % L.nurse.chain.volume_db)
	put(player, Vector3(11, 0, 9), -PI / 2)  # turn round: the lantern lights her
	await wait(0.6)
	var p0 = L.nurse.global_position
	await wait(1.2); await shot("c6_enfermeira_vista")
	check(L.nurse.seen and L.nurse.global_position.distance_to(p0) < 0.05 and L.nurse.ap.speed_scale == 0.0,
		"looked at and lit, she freezes mid-step (moved %.2f m)" % L.nurse.global_position.distance_to(p0))
	check(L.nurse.chain.volume_db < -60.0, "...and the keys go quiet")
	player.toggle_lantern(); await wait(0.9)  # lantern on the belt: you only see 4 m into the dark
	check(L.nurse.global_position.distance_to(p0) > 0.3, "the lantern on the belt: she comes on although you look (%.2f m)" % L.nurse.global_position.distance_to(p0))
	player.toggle_lantern(); await wait(0.9)
	put(player, player.global_position, PI / 2)  # turn your back on her
	var hurt := await until(func(): return player.health < 99, 6.0)
	await shot("c7_enfermeira_costas")
	check(L.nurse.breath_cd > 0.0, "she breathes on your neck before the stab")
	check(hurt, "she stabs you from behind (hp %d)" % player.health)
	put(player, player.global_position, player.rotation.y + PI)  # face her, machete out
	await tap("draw"); await wait(0.8)
	for i in 10:
		if L.nurse.state == Enemy.State.DEAD:
			break
		var to = L.nurse.global_position - player.global_position
		put(player, player.global_position, atan2(-to.x, -to.z))
		await tap("heavy"); await wait(1.05)
	check(L.nurse.state == Enemy.State.DEAD, "the machete kills her (her hp=%d)" % L.nurse.health)
	await wait(1.6); await shot("c8_enfermeira_morta")

# Juca's still (scenes/interiors/alambique.tscn, ../docs/TUTORIAL_VILAREJO.md "Dungeon 1"): what every interior does
# (test_interior.gd), and the route through it: the block pushed under the loft and up, the bats and the lantern, the
# jump over the tank, the wall with holds up the tower, the cane at the front door cut and the front door open.
extends "res://tests/test_interior.gd"


func tour() -> void:
	player.health = 99.0
	Story.mark("intro:vista")
	await walk(1.2)  # in from the side door
	var b: Pushable = L.block
	put(player, b.global_position + Vector3(0.8, 0, 0), PI / 2); await wait(0.4)  # east of it, facing west
	Input.action_press("forward")
	await until(func(): return b.global_position.x < -3.98 and not b.moving, 9.0)
	Input.action_release("forward"); await wait(0.5)
	check(absf(b.global_position.x + 4.0) < 0.02, "the block pushed west twice, under the loft's edge (x %.2f)" % b.global_position.x)
	await shot("alambique_2_pedra")
	put(player, b.global_position + Vector3(0.8, 0, 0), PI / 2); await wait(0.3)
	await tap("interact"); await until(func(): return not player.busy, 4.0); await wait(0.3)
	check(absf(player.global_position.y - 1.0) < 0.1, "E: up onto the block (%.2f up)" % player.global_position.y)
	check(L.hud.prompt.text.begins_with("E · subir") or L.hud.prompt.text.begins_with("E · escalar") or L.hud.prompt.text.begins_with("E ·"),
		"on it, by the loft's edge: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await until(func(): return not player.busy, 4.0); await wait(0.3)
	check(absf(player.global_position.y - L.LOFT) < 0.1 and player.global_position.x < -4.5,
		"E: from the block up onto the loft (%.2f up)" % player.global_position.y)
	# the bats over the walkway: the lantern in hand wakes them, on the belt they go back up, the machete knocks them down
	var bats: Morcegos = L.bats
	put(player, Vector3(-2.0, L.LOFT, -3.4), PI / 2); await wait(0.3)
	if not player.holds_lantern():
		await tap("lantern"); await wait(0.9)
	var hp := player.health
	await until(func(): return bats.swarming, 3.0)
	await wait(3.5); await shot("alambique_3_morcegos")
	check(bats.swarming and player.health < hp, "the lantern in hand: the bats come down round it and bite (%.1f lost)" % (hp - player.health))
	await tap("lantern"); await wait(Morcegos.LOSE + 2.5)
	check(not bats.swarming and not player.holds_lantern(), "hung on the belt: they go back up")
	await tap("lantern"); await wait(1.0)
	await until(func(): return bats.swarming, 3.0)
	await tap("draw"); await wait(1.3)
	for i in 8:
		await tap("attack"); await wait(0.75)
	check(bats.alive().size() < Morcegos.COUNT, "the machete knocks them down (%d of %d left)" % [bats.alive().size(), Morcegos.COUNT])
	await tap("draw"); await wait(1.2)
	await tap("lantern"); await wait(0.9)
	# the jump over the tank, the wall with holds up the tower
	put(player, Vector3(0.6, L.LOFT, -4.0), -PI / 2); await wait(0.3)
	check(L.hud.prompt.text == "Espaço · pular", "at the walkway's end: \"%s\"" % L.hud.prompt.text)
	await tap("dodge"); await until(func(): return not player.busy, 3.0); await wait(0.3)
	check(player.global_position.x > 3.5 and absf(player.global_position.y - L.LOFT) < 0.1, "across the tank onto the platform")
	put(player, Vector3(5.25, L.LOFT, -0.5), PI); await wait(0.3)  # before the wall's face (it looks north, to -z)
	await tap("interact")
	var on := await until(func(): return player.mode == Player.Mode.CLIMB, 3.0)
	Input.action_press("forward")
	await until(func(): return not player.busy, 14.0)
	Input.action_release("forward"); await wait(0.3)
	check(on and player.global_position.y > L.LOFT + 3.4, "up the wall's holds to the top of the tower (%.2f up)" % player.global_position.y)
	await shot("alambique_4_torre")
	# the front door: shored up with cane until the machete cuts it, then the way out (and in)
	player.health = 99.0
	var cane: Breakable = L.cane
	check(not L.front.enabled, "the front door stays shut while the cane is there")
	put(player, cane.global_position - cane.global_basis.z * -0.9, PI); await wait(0.3)
	check(L.hud.prompt.text == "E · sacar o facão", "at the cane: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(1.3)
	for i in 6:
		if not is_instance_valid(cane) or cane.pieces.is_empty():
			break
		await tap("attack"); await wait(0.9)
	check(Story.has("quebrado:alambique_cana") and L.front.enabled, "the machete cuts the cane down: the front door opens")
	await shot("alambique_5_cana")
	await tap("draw"); await wait(1.2)
	put(player, L.front.global_position, PI); await wait(0.3)
	await tap("interact")
	check(SceneRouter.requested == Paths.VILAREJO and SceneRouter.arriving == "alambique", "E at it: out by the front")
	SceneRouter.arriving = "alambique"
	var t: Transform3D = L._player_start()
	check(t.origin.distance_to((L.room.get_node("entrada_frente") as Node3D).position) < 0.1, "coming in by the front: just inside it")
	SceneRouter.arriving = ""; SceneRouter.requested = ""
	player.health = player.max_health

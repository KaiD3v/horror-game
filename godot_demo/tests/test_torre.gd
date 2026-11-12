# The chapel's bell tower (scenes/interiors/torre.tscn, ../docs/CONTEUDO_VILAREJO.md "O sino da capela"): what every
# interior does (test_interior.gd), and the way up: the stone pushed north under the landing's chalked edge, up it and
# onto the landing, the wall with holds to the top floor, the trapdoor out to the belfry.
extends "res://tests/test_interior.gd"


func tour() -> void:
	player.health = 99.0
	await walk(1.6)
	var b: Pushable = L.block
	put(player, b.global_position + Vector3(0, 0, 0.85), 0.0); await wait(0.4)  # south of it, facing north
	Input.action_press("forward")
	await until(func(): return b.global_position.z < 0.02 and not b.moving, 8.0)
	Input.action_release("forward"); await wait(0.5)
	check(absf(b.global_position.z) < 0.02, "the stone pushed north once, against the landing (z %.2f)" % b.global_position.z)
	await shot("torre_2_pedra")
	put(player, b.global_position + Vector3(0, 0, 0.8), 0.0); await wait(0.3)
	await tap("interact"); await until(func(): return not player.busy, 4.0); await wait(0.3)
	check(absf(player.global_position.y - 1.0) < 0.1, "E: up onto the stone (%.2f up)" % player.global_position.y)
	await tap("interact"); await until(func(): return not player.busy, 4.0); await wait(0.3)
	check(absf(player.global_position.y - L.LAND) < 0.1 and player.global_position.z < -0.5,
		"E: from the stone up onto the landing (%.2f up)" % player.global_position.y)
	put(player, Vector3(1.0, L.LAND, -0.75), 0.0); await wait(0.3)  # before the wall's face (it looks south, to +z)
	check(L.hud.prompt.text == "E · escalar", "before the wall with holds: \"%s\"" % L.hud.prompt.text)
	await tap("interact")
	var on := await until(func(): return player.mode == Player.Mode.CLIMB, 3.0)
	Input.action_press("forward")
	await until(func(): return not player.busy, 14.0)
	Input.action_release("forward"); await wait(0.3)
	check(on and player.global_position.y > L.LAND + 3.4, "up the wall's holds to the top floor (%.2f up)" % player.global_position.y)
	await shot("torre_3_muro")
	var hatch: Node3D = L.room.get_node("alcapao")
	put(player, hatch.position + Vector3(0, 0, 0.2), 0.0); await wait(0.4)
	check(L.hud.prompt.text == "E · subir ao campanário", "at the trapdoor: \"%s\"" % L.hud.prompt.text)
	await shot("torre_4_alcapao")
	await tap("interact")
	check(SceneRouter.requested == Paths.VILAREJO and SceneRouter.arriving == "campanario", "E: up through it, onto the belfry")
	SceneRouter.requested = ""; SceneRouter.arriving = ""

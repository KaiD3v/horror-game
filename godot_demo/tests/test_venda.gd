# Seu Bento's shop: the counter and the stair nailed shut stop you; the notices, the drinking corner.
extends "res://tests/test_interior.gd"


func tour() -> void:
	# the counter's front is at z = -0.58: walking at it stops you there
	put(player, Vector3(-1.5, 0.02, 1.4), 0.0); await wait(0.3)
	await walk(2.5)
	check(player.global_position.z > -0.58, "the counter stops you (z=%.2f)" % player.global_position.z)
	await shot("venda_2_balcao")
	# the stair up to the family's rooms is nailed shut: walking at it from below gets you nowhere
	put(player, Vector3(3.9, 0.02, 1.6), 0.0); await wait(0.3)
	await walk(2.0)
	check(player.global_position.z > 0.5, "the stair is nailed shut (z=%.2f)" % player.global_position.z)
	put(player, Vector3(1.6, 0.02, 1.6), -0.5); await wait(0.6); await shot("venda_3_escada")
	put(player, Vector3(1.2, 0.02, 1.0), -2.6); await wait(0.6); await shot("venda_4_procura")   # the notices by the door
	put(player, Vector3(-1.2, 0.02, 0.6), 2.2); await wait(0.6); await shot("venda_5_mesa")     # drinking corner

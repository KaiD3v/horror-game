# Tenório's gun shop: the counter stops you; the trophy wall, the stove.
extends "res://tests/test_interior.gd"


func tour() -> void:
	# the counter's front is at z = -0.49: walking at it stops you there
	put(player, Vector3(-1.0, 0.02, 1.4), 0.0); await wait(0.3)
	await walk(2.5)
	check(player.global_position.z > -0.49, "the counter stops you (z=%.2f)" % player.global_position.z)
	await shot("armaria_2_balcao")
	put(player, Vector3(1.2, 0.02, 0.6), 0.45); await wait(0.6); await shot("armaria_3_trofeu")   # the wall behind him
	put(player, Vector3(-1.2, 0.02, 1.2), 1.9); await wait(0.6); await shot("armaria_4_fogao")    # stove, shelves

# The chapel: up the aisle to the coffin, which blocks it; the ex-votos, the votive rack, the altar.
extends "res://tests/test_interior.gd"


func tour() -> void:
	# up the aisle between the pews, until the coffin (its foot at z = -1.8) stops you
	var z0 := player.global_position.z
	await walk(8.0)
	var z := player.global_position.z
	check(z0 - z > 5.0 and z > -1.8, "up the aisle between the pews to the coffin, which blocks it (z=%.2f)" % z)
	await shot("capela_2_nave")
	put(player, Vector3(1.9, 0.02, -0.2), -1.2); await wait(0.6); await shot("capela_3_exvotos")    # the ex-votos board
	put(player, Vector3(-0.9, 0.02, -1.6), 0.85); await wait(0.6); await shot("capela_4_velario")   # the votive rack
	put(player, Vector3(1.9, 0.02, -3.0), 0.35); await wait(0.6); await shot("capela_5_altar")      # coffin, altar, retable

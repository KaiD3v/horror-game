# The venda's cellar (scenes/interiors/porao.tscn): what every interior does (test_interior.gd: Odete's letter is its
# note), the bandages on the shelf, and up the ladder back into the shop.
extends "res://tests/test_interior.gd"


func tour() -> void:
	await walk(1.6)
	await shot("porao_2_bau")
	put(player, Vector3(1.6, 0.02, -1.0), PI); await wait(0.4)
	await tap("interact"); await wait(0.3)
	check(Inventory.count("atadura") >= 2, "two rolls of bandage on the shelf")

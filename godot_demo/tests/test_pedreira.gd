# The quarry's gallery (scenes/interiors/pedreira.tscn): what every interior does (test_interior.gd: the serum's inventory
# is its note), the brazier still warm, the box of bolts.
extends "res://tests/test_interior.gd"


func tour() -> void:
	await walk(2.5)
	await shot("pedreira_2_galeria")
	put(player, Vector3(-0.7, 0.02, -1.2), PI); await wait(0.4)
	check(L.hud.prompt.text == "E · olhar o braseiro", "the brazier: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(0.3)
	check(Story.has("pedreira:brasa"), "its embers still warm: somebody sleeps here")
	var b := Inventory.count("virote")
	put(player, Vector3(-0.8, 0.02, -3.0), PI); await wait(0.4)
	await tap("interact"); await wait(0.3)
	check(Inventory.count("virote") == b + 6, "a box of bolts")
	await shot("pedreira_3_deposito")

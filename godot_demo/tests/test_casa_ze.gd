# Zé's house (scenes/interiors/casa_ze.tscn, ../docs/TUTORIAL_VILAREJO.md "O vilarejo se abre"): what every interior does
# (test_interior.gd): in at the door, lit, solid, his note on the table, his trunk, out again.
extends "res://tests/test_interior.gd"


func tour() -> void:
	await walk(1.0)
	put(player, Vector3(1.2, 0.02, 0.4), -2.4); await wait(0.5); await shot("casa_ze_2_mesa")
	var bead: Array = L.find_children("*", "Pickup", true, false).filter(func(p): return p.id == "conta_ze")
	check(bead.size() == 1, "a rosary bead hidden here (conta_ze)")

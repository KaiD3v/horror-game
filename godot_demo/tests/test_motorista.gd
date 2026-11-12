# The driver's house (scenes/interiors/motorista.tscn, ../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"): what every
# interior does (test_interior.gd: his trip book is its note), and the São Cristóvão medal in the tin under his cot.
extends "res://tests/test_interior.gd"


func tour() -> void:
	await walk(1.4)
	await shot("motorista_2_quarto")
	var m: Node3D = L.room.get_node("medalha")
	put(player, Vector3(m.position.x + 0.9, 0.02, m.position.z), -PI / 2); await wait(0.4)
	await tap("interact"); await wait(0.4)
	check(Inventory.has("medalha"), "under the cot, in a tin: \"%s\"" % ItemCatalog.item("medalha").nome)

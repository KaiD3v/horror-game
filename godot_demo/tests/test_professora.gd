# Dona Lurdes's house (scenes/interiors/professora.tscn, ../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"): what
# every interior does (test_interior.gd: her class diary is its note), and her husband's watch on the night table.
extends "res://tests/test_interior.gd"


func tour() -> void:
	await walk(1.4)
	await shot("professora_2_quarto")
	var m: Node3D = L.room.get_node("relogio")
	put(player, Vector3(m.position.x + 0.2, 0.02, m.position.z + 0.9), PI * 0.1); await wait(0.4)
	await tap("interact"); await wait(0.4)
	check(Inventory.has("relogio_bolso"), "the pocket watch on the night table: \"%s\"" % ItemCatalog.item("relogio_bolso").nome)

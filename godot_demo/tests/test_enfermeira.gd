# The nurse's house (scenes/interiors/enfermeira.tscn, ../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"): what every
# interior does (test_interior.gd: her letters are its note); the empty hanger, the covered mirror, the syringe.
extends "res://tests/test_interior.gd"


func tour() -> void:
	await walk(1.4)
	await shot("enfermeira_2_quarto")
	put(player, Vector3(1.2, 0.02, -0.4), -0.9); await wait(0.6); await shot("enfermeira_3_cabide")
	# her first-aid tin, in the suitcase by the door (../docs/MELHORIAS.md): six cures fit
	Inventory.items.erase("estojo_celina")
	put(player, L.SUITCASE + Vector3(-0.9, -0.4, 0), -PI / 2); await wait(0.5)
	check(L.hud.prompt.text == "E · abrir a mala", "at the suitcase: \"%s\"" % L.hud.prompt.text)
	await shot("enfermeira_4_mala")
	await tap("interact"); await wait(0.3)
	check(Inventory.has("estojo_celina") and Inventory.cap("cura") == 6 and Story.has("pego:enfermeira_estojo"), "E: Celina's tin (6 cures)")

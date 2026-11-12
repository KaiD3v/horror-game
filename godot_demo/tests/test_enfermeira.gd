# The nurse's house (scenes/interiors/enfermeira.tscn, ../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"): what every
# interior does (test_interior.gd: her letters are its note); the empty hanger, the covered mirror, the syringe.
extends "res://tests/test_interior.gd"


func tour() -> void:
	await walk(1.4)
	await shot("enfermeira_2_quarto")
	put(player, Vector3(1.2, 0.02, -0.4), -0.9); await wait(0.6); await shot("enfermeira_3_cabide")

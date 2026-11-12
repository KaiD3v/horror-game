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


func run() -> void:
	await super()
	await rotina_tests()


# --- the routine in here (NpcCatalog "rotina"): out sweeping at dawn, back at nine; the radio's hour -----------------
func rotina_tests() -> void:
	var counter: Node3D = L.room.get_node("npc_vendeiro")
	put(player, (L.room.get_node("entrada") as Node3D).position, PI); await wait(0.3)  # (back to the counter: unseen)
	WorldTime.reset(7 * 60); await wait(0.4)
	check(not L.npcs.has("vendeiro"), "7:00 the counter empty: Bento is out sweeping")
	WorldTime.reset(9 * 60 + 30); await wait(0.4)
	check(L.npcs.has("vendeiro") and L.npcs.vendeiro.global_position.distance_to(counter.global_position) < 0.2,
		"9:30 back behind his counter")
	WorldTime.reset(19 * 60 + 10); await wait(0.4)
	check(L.on_air == "voz_do_brasil" and L.radio.playing, "19:00 the radio: the Voz do Brasil")
	WorldTime.reset(20 * 60 + 5); await wait(0.4)
	check(L.on_air == "musica_venda", "20:00 back to music")

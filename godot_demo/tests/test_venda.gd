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
	await sintonia_tests()
	await porao_tests()


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


# --- the radio's dial (Sintonia, ../docs/CONTEUDO_VILAREJO.md "A sintonia do rádio"): the stations come through near
# them, the static between; in the small hours, with the three tasks done, the Colônia at 1180 and his mother's number
func sintonia_tests() -> void:
	WorldTime.reset(10 * 60); await wait(0.3)
	var m: Node3D = L.room.get_node("som_musica_venda")
	put(player, Vector3(m.position.x + 0.6, 0.02, m.position.z), PI / 2); await wait(0.4)
	check(L.hud.prompt.text == "E · mexer no rádio", "at the radio: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(0.3)
	var s: Sintonia = L.tuning
	check(s != null and player.busy, "he takes the dial")
	s.freq = 750.0; await wait(0.2)
	check(s.strength(750.0).musica_venda > 0.9 and "viola" in s.heard.text, "750: music")
	s.freq = 900.0; await wait(0.2)
	check(s.heard.text == "" and s.players.radio_chiado.volume_db > -10.0, "between stations: static")
	s.freq = 1180.0; await wait(0.3)
	check(s.strength(1180.0).radio_colonia == 0.0, "1180 by day, or before the three tasks: nothing there")
	await shot("venda_6_radio")
	s.close(); await wait(0.2)
	Story.set_task("sino", "feita"); Story.set_task("pao", "feita"); Story.set_task("galinhas", "feita")
	WorldTime.reset(2 * 60 + 30)
	s = L.tune(); s.freq = 1180.0
	await until(func(): return Story.has("radio:colonia"), 14.0)
	check(Story.has("radio:colonia") and "radio_colonia" in NotesReader.read and "0187" in s.heard.text,
		"2:30, the tasks done: the Colônia at 1180, a voice reading numbers; the last is his mother's (0187)")
	await shot("venda_7_colonia")
	s.close(); Story.reset(); WorldTime.reset(16 * 60 + 30)


# --- the cellar (../docs/CONTEUDO_VILAREJO.md "O porão da venda"): the number scratched on the counter, the combination
# padlock on the trapdoor (wrong, then 0612), down the ladder
func porao_tests() -> void:
	var s: Vector3 = L.SCRATCH
	put(player, Vector3(s.x, 0.02, s.z + 0.6), 0.0); await wait(0.4)
	check(L.hud.prompt.text == "E · olhar o balcão", "the counter's end: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(0.3)
	check(Story.has("porao:numero"), "scratched into it: a heart, an O., 0612")
	await shot("venda_8_balcao")
	put(player, L.TRAPDOOR + Vector3(0, 0.02, 0.7), 0.0); await wait(0.4)
	check(L.hud.prompt.text == "E · abrir o cadeado de segredo", "the iron trapdoor: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(0.3)
	var lock: Segredo = L.cracking
	check(lock != null and player.busy, "its combination padlock: four wheels")
	lock.set_code("1234"); check(not lock.pull(), "1234: it does not give")
	await shot("venda_9_segredo")
	lock.set_code("0612"); lock.pull(); await wait(0.3)
	check(Story.has("aberta:porao") and L.down.enabled and not player.busy, "0612: open")
	put(player, L.TRAPDOOR + Vector3(0, 0.02, 0.4), 0.0); await wait(0.4)
	SceneRouter.requested = ""
	await tap("interact")
	check(SceneRouter.requested == Paths.interior("porao") and SceneRouter.arriving == "porao", "E: down to the cellar")
	SceneRouter.requested = ""; SceneRouter.arriving = ""; Story.reset()

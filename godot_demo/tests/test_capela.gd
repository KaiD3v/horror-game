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
	# the sacristy door by the altar (../docs/TUTORIAL_VILAREJO.md "Dungeon 2"): padlocked; Dona Firmina's key opens it
	# and it goes down to the ossuary, whose stairs bring you back up beside it
	Inventory.items.erase("chave_sacristia"); Story.marks.erase("destrancado:chave_sacristia")
	var d: BlockedDoor = L.sacristy
	put(player, d.global_position + d.global_basis.z * 0.9, d.rotation.y + PI); await wait(0.4)
	check(L.hud.prompt.text == "E · abrir o cadeado", "at the sacristy door: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(0.2)
	check(L.hud.message.text.begins_with("Trancada com cadeado"), "no key: \"%s\"" % L.hud.message.text)
	Inventory.add("chave_sacristia")
	await tap("interact"); await wait(0.6)
	check(Story.has("aberta:sacristia") and L.down.enabled and L.hud.prompt.text == "E · descer pela sacristia",
		"Dona Firmina's key: the padlock off, the way down (\"%s\")" % L.hud.prompt.text)
	await shot("capela_6_sacristia")
	await tap("interact")
	check(SceneRouter.requested == Paths.interior("ossuario") and SceneRouter.arriving == "sacristia", "E: down to the ossuary")
	SceneRouter.requested = ""; SceneRouter.arriving = "sacristia"
	var t: Transform3D = L._player_start()
	check(t.origin.distance_to((L.room.get_node("entrada_sacristia") as Node3D).position) < 0.1, "up from the ossuary: beside the sacristy door")
	SceneRouter.arriving = ""

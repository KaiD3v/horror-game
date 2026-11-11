# The ossuary (scenes/interiors/ossuario.tscn, ../docs/TUTORIAL_VILAREJO.md "Dungeon 2"): in from the sacristy; the
# bolts on the stairs; the bones (standing they crack and stir the sleeper, crouched hardly); the crossbow; a bolt in the
# rope and the plank falls across the cut; the sleeper in the cistern (a crouch near him does not wake him, a bottle
# smashed draws him to it); the rope up the well; the tunnel, the scapular; the stairs back up; and killing him.
extends AutoTest


func run() -> void:
	WorldTime.reset(10 * 60)
	await wait(1.0)
	var entry: Node3D = L.room.get_node("entrada")
	check(player.is_on_floor() and player.global_position.distance_to(entry.position) < 0.3, "in from the sacristy, on the landing")
	check(L.find_children("*", "Oratorio", true, false).size() == 1, "an oratório on the landing")
	await shot("ossuario_1_patamar")
	var bolts := Inventory.count("virote")
	var spot: Node3D = L.room.get_node("virotes")
	put(player, spot.position + Vector3(-0.4, 0, 0), PI); await wait(0.4)
	await tap("interact"); await wait(0.2)
	check(Inventory.count("virote") == bolts + 5 and Story.has("pego:ossuario_virotes"), "Tenório's bolts on the stairs (5)")
	# the bones: standing, each step cracks and stirs him; crouched, hardly a sound
	var p: Poceiro = L.poceiro
	check(p != null and p.asleep, "by day O Poceiro sleeps down in the cistern")
	p.active = true  # (AutoTest leaves creatures dormant: this one is the test)
	put(player, Vector3(0, 0, -4.2), 0.0); await wait(0.4)
	Audio.heard.clear(); L.stir = 0.0
	check(L.hud.prompt.text == Hints.TEXT.agachar or Hints.learned("agachar"), "at the bones: \"%s\"" % L.hud.prompt.text)
	await walk(2.5)
	var loud: float = L.stir
	check(loud > 0.3 and "ossos_pisar" in Audio.heard, "walking the bones standing: they crack, he stirs (%.2f)" % loud)
	await shot("ossuario_2_galeria")
	put(player, Vector3(0, 0, -6.0), 0.0); await wait(0.3); L.stir = 0.0
	await tap("crouch"); await wait(0.8)
	await walk(3.5)
	check(L.stir < 0.05 and p.asleep, "crouched over them: hardly a sound (%.2f)" % L.stir)
	await tap("crouch"); await wait(0.8)
	# the crossbow, and the rope that holds the plank up
	Inventory.items.erase("besta")
	var at: Node3D = L.room.get_node("besta")
	put(player, at.position + Vector3(0.5, 0, 0), PI / 2); await wait(0.4)
	check(L.hud.prompt.text == "E · pegar besta", "Tenório's crossbow by his blood: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(0.2)
	check(Inventory.has("besta"), "E takes it")
	put(player, Vector3(0, 0, -17.2), 0.0); await wait(0.3)
	check(not Story.has("ponte:ossuario") and L.plank.rotation.x < 0.1, "across the cut the plank stands on end")
	await shot("ossuario_3_corte")
	var from := player.global_position + Vector3(0, 1.5, 0)
	Bolt.fire(L, from, (L.rope.global_position - from).normalized(), player.get_rid())
	await until(func(): return Story.has("ponte:ossuario"), 2.0); await wait(1.4)
	check(absf(L.plank.rotation.x - PI / 2) < 0.05 and "corda_arrebentar" in Audio.heard, "a bolt in the rope: the plank falls across")
	Input.action_press("forward"); await until(func(): return player.global_position.z < -22.6, 6.0); Input.action_release("forward")
	await wait(0.3)
	check(player.global_position.z < -22.5 and player.global_position.y > -0.3, "over the plank to the far side")
	await shot("ossuario_4_ponte")
	# the cistern: he sleeps through a crouch nearby; a bottle smashed over there draws him to it
	put(player, Vector3(3.5, 0, -28.0), 0.0); await wait(0.3)
	await tap("crouch"); await wait(0.8)
	await wait(1.5)
	check(p.asleep, "crouched, 6 m off: he sleeps on")
	await shot("ossuario_5_cisterna")
	var bottle: Target = L.bottles[0]
	from = player.global_position + Vector3(0, 1.0, 0)
	Bolt.fire(L, from, (bottle.global_position - from).normalized(), player.get_rid())
	await until(func(): return bottle.done, 2.0)
	await wait(6.0)
	check(bottle.done and not p.asleep and p.global_position.distance_to(bottle.global_position) < 3.5,
		"a bolt in a bottle on the far wall: it smashes and he goes to it (%.1f m off it)" % p.global_position.distance_to(bottle.global_position))
	var up: Node3D = L.room.get_node("corda")
	put(player, up.position + Vector3(0.6, 0, 0.4), 0.0); await wait(0.3)
	check(L.hud.prompt.text == "E · subir pela corda", "at the rope under the shaft: \"%s\"" % L.hud.prompt.text)
	await tap("interact")
	check(SceneRouter.requested == Paths.VILAREJO and SceneRouter.arriving == "poco" and Story.has("corda:poco_largo"),
		"E: up the rope, out by the square's well (and it stays tied)")
	SceneRouter.requested = ""; SceneRouter.arriving = ""
	await tap("crouch"); await wait(0.8)
	# the tunnel north (the pickaxe), the scapular by it
	var sc: Node3D = L.room.get_node("escapulario")
	put(player, sc.position + Vector3(-0.5, 0, 0.3), -PI / 2); await wait(0.3)
	await tap("interact"); await wait(0.2)
	check(Inventory.has("escapulario"), "Joaquim's scapular by the fallen tunnel")
	check(L.find_children("*", "Breakable", true, false).size() == 1, "the tunnel north fallen in (the pickaxe)")
	# killing him: he stays dead (not up the well at night either)
	p.take_hit(99, "besta"); await wait(0.3)
	check(Story.has("morto:poceiro"), "killed down here: for good")
	# back up the stairs
	put(player, entry.position, PI); await wait(0.3)
	await tap("interact")
	check(SceneRouter.requested == Paths.interior("capela") and SceneRouter.arriving == "sacristia", "E on the landing: up into the chapel")
	SceneRouter.requested = ""; SceneRouter.arriving = "poco"
	var t: Transform3D = L._player_start()
	check(t.origin.distance_to((L.room.get_node("entrada_poco") as Node3D).position) < 0.1, "down the rope from the square: under the shaft")
	SceneRouter.arriving = ""
	Story.reset()

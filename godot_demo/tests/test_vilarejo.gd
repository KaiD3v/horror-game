# The village (scenes/levels/vilarejo.tscn): the GLB's colliders and navmesh, sounds, NPCs, walking it, the doors in
# and out, the story pieces, weather and crows, the finish, the notes, the night mutants.
extends AutoTest


func run() -> void:
	L.night_watch = false  # no bruxas while the rest is tested (bruxa_tests lets the night in)
	await wait(1.5); await shot("v1_chegada")
	var bodies = L.village.find_children("*", "StaticBody3D", true, false).size()
	check(bodies >= 20, "village colliders imported from the GLB suffixes (%d bodies)" % bodies)
	check(L.env.fog_enabled and L.env.fog_density > 0.04, "fog on")
	var spawn: Vector3 = L.village.get_node("spawn_jogador").position
	check(player.is_on_floor() and absf(player.global_position.y - spawn.y) < 0.4,
		"the player stands on the terrain at the village's entrance (y=%.2f, ground %.2f)" % [player.global_position.y, spawn.y])
	var n = L.nav.navigation_mesh.get_polygon_count()
	check(n > 200, "navmesh baked over the village (%d polygons)" % n)
	var well = L.village.get_node("spawn_mutante").position as Vector3
	check(L.reachable(well, spawn), "the mutant can walk from the square down the road to the entrance")
	check(not L.reachable(well, Vector3(9.5, L.ground(9.5, 30).y, 30)), "houses are solid: nothing walks inside casa_02")
	var kit := 0  # the prop kit's instances (tools/cenarios/vilarejo props()): barril_01, carroca_01, ...
	for c in L.village.get_children():
		if c.name.get_slice("_", 0) in ["barril", "caixote", "lenha", "carroca", "roda", "varal", "espantalho", "banco",
				"cocho", "cruzeiro", "placa", "carrinho", "feno"]:
			kit += 1
	check(kit >= 30, "scene props placed round the village (%d)" % kit)
	check(not L.reachable(well, Vector3(5.6, L.ground(5.6, -4.2).y, -4.2)), "props are solid: the trough by the well blocks the way")
	check(L.wind.playing and L.wind.stream.loop_mode != AudioStreamWAV.LOOP_DISABLED and L.npcs.benzedeira.voice.playing,
		"the wind loops, Dona Firmina prays under her breath")
	var heard := 0
	for k in ["corvo", "cao", "sino"]:
		var e = L.events.fire(k)
		heard += 1 if e and e.playing else 0
	check(heard == 3 and L.creakers.size() >= 3, "crows, the dog, the bell sound in the world (%d creaking spots)" % L.creakers.size())
	for who in L.npcs:
		var ap: AnimationPlayer = L.npcs[who].anim
		var at: Vector3 = L.npcs[who].global_position
		check(ap.is_playing() and ap.current_animation == "Idle" and not L.reachable(well, at),
			"NPC %s stands on its marker, idling, solid (%.1f, %.1f)" % [who, at.x, at.z])
	await map_shot("v0_mapa", Vector3(0, 80, -3), 120, 1.5)

	var z0 := player.global_position.z
	var s0 = L.footsteps.steps
	await walk(4.0)
	check(L.footsteps.steps - s0 >= 4, "footsteps on the dirt road (%d)" % (L.footsteps.steps - s0))
	check(z0 - player.global_position.z > 2.5 and player.is_on_floor(),
		"walks up the dirt road over the uneven ground (%.1f m)" % (z0 - player.global_position.z))
	await shot("v2_estrada")

	# casa_02's front wall is at x = 6.75 (Blender 9.5 - depth 5.5 / 2): walking into it stops you
	put(player, L.ground(4.6, 30.4), -PI / 2); await wait(0.3)
	await walk(3.0)
	check(player.global_position.x < 6.75, "the house's wall stops you (x=%.2f)" % player.global_position.x)
	await shot("v3_casa")

	# the ruin (casa_01) has a doorway on its east side at x = -7.5: you can walk in
	put(player, L.ground(-5.0, 36.0), PI / 2); await wait(0.3)
	await walk(4.0)
	check(player.global_position.x < -8.0, "you walk into the ruin through its doorway (x=%.2f)" % player.global_position.x)
	await shot("v4_ruina")

	put(player, L.ground(1.5, 8.0), 0.6); await wait(0.6); await shot("v5_largo")       # the square, chapel to the left
	put(player, L.ground(-1.5, -53.0), 0.0); await wait(0.6); await shot("v6_portao")    # the Colônia's gate up the hill
	put(player, L.ground(22.0, 27.0), -PI / 2); await wait(0.6); await shot("v8_espantalho")  # the scarecrow in the field
	put(player, L.ground(3.0, -13.0), -PI / 2); await wait(0.6); await shot("v9_venda")       # the shop: barrels, crates, cart
	put(player, L.ground(-1.0, 30.0), 0.73); await wait(0.6); await shot("v10_carroca")       # the broken cart on the way in
	const SHOT_DIST := {"capela": 4.6}  # how far out to stand for the shop-front capture (the chapel's: past the cross)
	for d in L.DOORS:  # each door: the shop front, E goes in, coming out puts you back at its steps
		var door = L.village.get_node("porta_" + d) as Node3D
		var shop: Vector3 = door.position; var away: Vector3 = door.basis.z  # the marker's +z: out from the house (= the model's front)
		var front: Vector3 = shop + away * SHOT_DIST.get(d, 2.6)
		put(player, L.ground(front.x, front.z), door.rotation.y); await wait(0.6); await shot("v12_" + d)
		put(player, L.ground(shop.x, shop.z), door.rotation.y); await wait(0.3)
		check(L.hud.prompt.visible and L.hud.prompt.text == L.DOORS[d], "at the %s's door: \"%s\"" % [d, L.hud.prompt.text])
		SceneRouter.requested = ""; await tap("interact")
		check(SceneRouter.requested == Paths.interior(d), "E at the door goes in (%s)" % SceneRouter.requested)
		SceneRouter.arriving = d
		var out: Transform3D = L._player_start()
		put(player, out.origin - Vector3(0, 0.3, 0), out.basis.get_euler().y)
		await wait(0.8)
		check(player.is_on_floor() and player.global_position.distance_to(shop) < 0.6,
			"coming out of the %s, you stand at its door (%.2f m off)" % [d, player.global_position.distance_to(shop)])
	put(player, L.ground(-4.5, -3.4), 0.0); await wait(0.6); await shot("v13_benzedeira")    # Dona Firmina by the cross

	# the story the village tells (../docs/VILAREJO.md "Narrativa ambiental"): all of it is in the GLB
	for piece in ["narrativa", "ponte_caida", "ravina_agua", "marca_carcaca"]:
		check(L.village.get_node_or_null(piece) != null, "narrative piece in the village: %s" % piece)
	var carcass = (L.village.get_node("marca_carcaca") as Node3D).position
	await life_tests(carcass)
	await finish_tests()
	put(player, L.ground(carcass.x - 3.0, carcass.z + 3.0), -PI / 4); await wait(0.6); await shot("v16_carcaca")
	var caw = L.events.fire("corvo")
	check(caw != null and caw.position.distance_to(carcass) < 1.0, "near the carcass the crows call from it")
	put(player, L.ground(1.0, 8.0), 0.0); await wait(0.6); await shot("v14_rastro")            # the trail up the road
	put(player, L.ground(3.5, 15.5), -PI / 2); await wait(0.6); await shot("v15_casa04")       # where it started
	put(player, L.ground(-26.0, 1.0), PI); await wait(0.6); await shot("v17_queimada")         # the burnt house
	put(player, L.ground(4.6, 30.6), -PI / 2); await wait(0.6); await shot("v18_acorrentada")  # chained from outside
	put(player, L.ground(1.0, 45.3), PI); await wait(0.6); await shot("v19_ponte")             # the way out, fallen, fenced off

	# by day the village is empty of hunters: the Mutante first shows in the Colônia (only the night brings any here)
	check(L.find_children("*", "Mutante", true, false).is_empty() and get_tree().get_nodes_in_group("enemy").is_empty(),
		"no enemy in the village by day")
	await notes_suite()
	await chest_suite()
	await day_tests()
	await bruxa_tests()
	await poceiro_tests()
	await carpideira_tests()



func finish_tests() -> void:
	# AO in the vertex colours; weathering decals on the walls; the far shapes and the Colônia through the fog
	var terrain: MeshInstance3D = L.village.find_children("terreno*", "MeshInstance3D", true, false)[0]
	var cols: PackedColorArray = terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var darkest := 1.0
	for c in cols:
		darkest = minf(darkest, c.r)
	check(cols.size() > 0 and darkest < 0.6, "AO baked into the terrain's vertex colours (darkest %.2f)" % darkest)
	var stains := {}
	for mi in L.village.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(i)
			if m and m.resource_name in ["umidade", "musgo", "escorrido", "rachadura"]:
				stains[m.resource_name] = true
	check(stains.size() == 4, "weathering on the walls: %s" % ", ".join(stains.keys()))
	var sil := 0
	for n in ["silhueta_longe", "silhueta_perto", "colonia_silhueta", "colonia_luzes"]:
		var mi: Array[Node] = L.village.find_children(n + "*", "MeshInstance3D", true, false)
		sil += 1 if mi.size() > 0 and mi[0].get_surface_override_material(0) is ShaderMaterial else 0
	check(sil == 4, "ridges, araucarias and the Colônia stand beyond the fog (%d/4 hazed)" % sil)
	put(player, L.ground(1.0, 10.0), 0.0); await wait(0.8); await shot("v24_rumo_colonia")   # up the road: the goal
	put(player, L.ground(-1.0, -50.0), 0.0); await wait(0.8); await shot("v25_sobre_o_muro")  # at the gate
	put(player, L.ground(0.0, 40.0), PI * 0.75); await wait(0.8); await shot("v26_serra")       # the ridges round
	put(player, L.ground(4.0, -10.5), -PI / 2 - 0.4); await wait(0.8); await shot("v27_manchas")  # casa_04's walls up close


func life_tests(carcass: Vector3) -> void:
	# weather: drizzle that roofs stop, its hiss; puddles on the road; mist banks drifting downhill; leaves and ash
	var rain: GPUParticles3D = L.clima.rain
	check(rain.emitting and rain.amount >= 1500 and rain.process_material.collision_mode == ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT,
		"drizzle falls round you and stops on what it hits (%d drops)" % rain.amount)
	check(L.clima.rain_sound.playing and L.clima.rain_sound.stream.loop_mode != AudioStreamWAV.LOOP_DISABLED, "the drizzle hisses, looped")
	var dry := 0
	for pd in L.clima.puddles:
		dry += 1 if absf(pd.global_position.y - L.ground(pd.global_position.x, pd.global_position.z).y) > 0.2 else 0
	check(L.clima.puddles.size() >= 12 and dry == 0, "puddles lie on the road (%d, %d floating)" % [L.clima.puddles.size(), dry])
	var b0: Vector3 = L.clima.banks[0].global_position
	await wait(1.0)
	var moved: Vector3 = L.clima.banks[0].global_position - b0; moved.y = 0
	check(L.clima.banks.size() >= 40 and moved.length() > 0.4 and moved.z > 0.0,
		"mist banks roll downhill from the Colônia (%d banks, %.2f m/s)" % [L.clima.banks.size(), moved.length()])
	check(L.clima.leaves.emitting and L.clima.ash.emitting and L.clima.embers.emitting, "leaves on the wind, ash and embers off the burnt house")
	var pd: MeshInstance3D = L.clima.puddles[0]
	put(player, L.ground(pd.global_position.x, pd.global_position.z + 2.2), 0.0); await wait(0.8); await shot("v20_poca")
	put(player, L.ground(1.0, 20.0), 0.0); await wait(0.8); await shot("v21_garoa")
	put(player, L.ground(-21.0, 2.0), PI / 2 + 0.3); await wait(0.8); await shot("v22_cinzas")
	# crows: 9 on their perches; crouched you creep up on them, standing they all take off
	check(L.crows.size() >= 9, "crows perch round the village (%d)" % L.crows.size())
	var flock = L.crows.filter(func(c): return c.home.origin.distance_to(carcass) < 3.0)
	player.crouch(); await wait(0.9)  # kneel well away, then creep up
	put(player, L.ground(carcass.x - 4.5, carcass.z + 1.0), -PI / 2 + 0.2); await wait(1.5)
	check(flock.size() >= 4 and flock.all(func(c): return not c.flying), "crouched, you get within 4.5 m of the crows on the carcass")
	player.crouch(); await wait(0.9)
	check(flock.all(func(c): return c.flying), "stand up and the whole flock takes off")
	await wait(0.9); await shot("v23_corvos")
	var up: float = flock.map(func(c): return c.global_position.y - c.home.origin.y).min()
	check(up > 1.0, "they climb away (the lowest %.1f m up)" % up)
	await wait(7.0)
	check(flock.all(func(c): return c.gone), "...and are lost in the fog")


# --- the day and its weather (WorldTime, Weather, DayCycle) ------------------------------------------------
func day_tests() -> void:
	var at := {0: "madrugada", 359: "madrugada", 360: "manha", 719: "manha", 720: "tarde", 1079: "tarde", 1080: "noite", 1439: "noite", 1440: "madrugada"}
	var wrong := at.keys().filter(func(m): WorldTime.minutes = m; return WorldTime.period().id != at[m])
	check(wrong.is_empty(), "the periods: madrugada 00-05:59, manhã 06-11:59, tarde 12-17:59, noite 18-23:59 (wrong at %s)" % [wrong])
	WorldTime.reset(10 * 60); L.day._step(0.0)
	var m0 := WorldTime.minutes
	await wait(2.0)
	check(absf(WorldTime.minutes - m0 - 2.0) < 0.35, "1 s = 1 game minute (%.2f min in 2 s)" % (WorldTime.minutes - m0))
	# light round the clock: no jumps from one minute to the next, darker at night than by day
	var worst := 0.0; var prev := DayData.sample(0.0)
	for m in range(1, 1441):
		var k := DayData.sample(m / 60.0)
		worst = maxf(worst, maxf(absf(k.amb_e - prev.amb_e), absf(k.fog.v - prev.fog.v) + absf(k.sun_e + k.moon_e - prev.sun_e - prev.moon_e)))
		prev = k
	check(worst < 0.015, "the light changes smoothly through the day (biggest step in a minute %.4f)" % worst)
	var lit := {}
	for p in [["madrugada", 3], ["manha", 8], ["tarde", 14], ["noite", 21]]:
		WorldTime.reset(p[1] * 60); Weather.force(0.0, 1.0 if p[0] == "manha" else 0.3); L.day._step(0.0)
		lit[p[0]] = L.env.ambient_light_energy + L.sun.light_energy
		put(player, L.ground(1.0, 10.0), 0.0); await wait(0.6); await shot("v28_%s" % p[0])
	check(lit.tarde > lit.noite * 2.0 and lit.manha > lit.madrugada * 2.0, "day is lit, night is dark (%s)" % [lit])
	# the weather plan: every morning fog; elsewhere rain and fog by chance
	Weather.release()
	var rains := 0; var fogs := 0; var mornings_fog := 0
	for i in 400:
		WorldTime.minutes = (i * 4 + 2) * 360.0 + 1.0  # an afternoon (12:01) of day i
		Weather.rain_until = -1.0; Weather.plan(); rains += int(Weather.rain_from >= 0.0 and Weather.rain_from >= WorldTime.period_start())
		fogs += int(Weather.fog_goal >= 0.5)
		WorldTime.minutes = (i * 4 + 1) * 360.0 + 1.0  # a morning
		Weather.plan(); mornings_fog += int(Weather.fog_goal == 1.0)
	check(mornings_fog == 400, "every morning is foggy (%d/400)" % mornings_fog)
	check(absf(rains / 400.0 - DayData.CHANCES.tarde.chuva) < 0.08 and absf(fogs / 400.0 - DayData.CHANCES.tarde.nevoa) < 0.08,
		"afternoons: rain %.0f %%, fog %.0f %% of the time (chances %.0f / %.0f %%)" % [rains / 4.0, fogs / 4.0, DayData.CHANCES.tarde.chuva * 100, DayData.CHANCES.tarde.nevoa * 100])
	# a rain setting in: eased, never a snap; the drizzle and its hiss follow
	WorldTime.reset(14 * 60); Weather.reset(); Weather.plan(); Weather.rain = 0.0
	Weather.rain_from = WorldTime.minutes; Weather.rain_until = WorldTime.minutes + 120.0
	var steps: Array[float] = []
	for i in 14:
		var r0 := Weather.rain; L.day._step(1.0); steps.append(Weather.rain - r0)
	check(steps.max() <= 1.0 / DayData.RAIN_EASE + 0.001 and Weather.rain == 1.0 and is_equal_approx(L.clima.rain.amount_ratio, 1.0),
		"rain sets in over %d game minutes, the drizzle with it (%.2f)" % [DayData.RAIN_EASE, L.clima.rain.amount_ratio])
	put(player, L.ground(1.0, 20.0), 0.0); await wait(0.6); await shot("v29_chuva_tarde")
	# a new period is told on the screen
	WorldTime.reset(11 * 60 + 59); L.day._step(0.0); L.day._step(2.0); await wait(0.1)
	check(L.hud.message.visible and L.hud.message.text.begins_with("Tarde"), "the period is told as it begins: \"%s\"" % L.hud.message.text)
	Weather.force(1.0, 1.0)


# --- A Bruxa (../docs/MUTANTES_NOITE.md): on the roofs at night, down to the lantern, gone at dawn ---------------
func bruxa_tests() -> void:
	WorldTime.reset(10 * 60); Weather.force(0.0, 0.3); L.day._step(0.0)
	player.health = 99; player.pitch.rotation.x = 0.2
	put(player, L.ground(0.0, 40.0), PI)
	L.night_watch = true; await wait(0.3)
	check(L.bruxas.is_empty(), "by day there is no bruxa in the village")
	await _lantern(false)  # on the belt while they settle: nothing calls them yet
	WorldTime.reset(21 * 60); L.day._step(0.0); await wait(0.5)
	var up: Array = L.bruxas.filter(func(b): return b.roost != null and b.global_position.distance_to(b.roost) < 0.4)
	check(L.bruxas.size() == L.BRUXAS and up.size() == L.BRUXAS and L.perches.size() >= 8,
		"at nightfall %d bruxas perch on roof ridges (%d ridges, %d up there)" % [L.bruxas.size(), L.perches.size(), up.size()])
	_hush_carpideira()
	for b in L.bruxas:
		b.active = false
	L.poceiro.active = false  # (poceiro_tests)
	var b: Bruxa = null; var spot := Vector3.INF
	for c in L.bruxas:
		spot = _below(c.roost)
		if spot != Vector3.INF:
			b = c; break
	check(b != null, "open ground in plain view of a roof (%s)" % spot)
	if b == null:
		return
	var d := b.global_position - spot
	put(player, spot, atan2(-d.x, -d.z))
	await _lantern(true); await wait(1.2)
	check(player.lantern_out and b.shine.emission_energy_multiplier > 2.0,
		"her eyes throw the lantern back from the roof (%.1f)" % b.shine.emission_energy_multiplier)
	Audio.heard.clear(); b.active = true
	var stare := await until(func(): return b.watching > 1.1, 3.0)
	var facing := (-b.global_basis.z).dot((player.global_position - b.global_position) * Vector3(1, 0, 1)) / (player.global_position - b.global_position).length()
	await shot("v30_bruxa_telhado")
	check(stare and facing > 0.8 and b.state == Enemy.State.IDLE, "the lantern catches her eye: she turns on the roof and stares at it (%.2f)" % facing)
	var flew := await until(func(): return not b.flight.is_empty(), 4.0)
	check(flew and "bruxa_estalo" in Audio.heard, "then she clicks, opens her wings, leaves the roof")
	await wait(0.5); await shot("v31_bruxa_voo")
	var down := await until(func(): return b.state == Enemy.State.CHASE, 6.0)
	var dist := b.global_position.distance_to(player.global_position)
	check(down and b.is_on_floor() and dist < Bruxa.ORBIT + 1.5, "she glides down to the light (%.1f m off)" % dist)
	var h0 := player.health
	var hit := await until(func(): return player.health < h0, 12.0)
	await shot("v32_bruxa_ataque")
	check(hit, "she circles the light and darts in to rake at it (health %.1f -> %.1f)" % [h0, player.health])
	await until(func(): return b.state == Enemy.State.CHASE and not b.darting, 3.0)
	await _lantern(false)
	var lost := await until(func(): return b.searching > 0.0, 4.0)
	check(lost and not player.lantern_out, "the lantern hung on the belt: she loses you, hunts round where it went out")
	var away := player.global_position - b.global_position; away.y = 0
	put(player, NavigationServer3D.map_get_closest_point(L.get_world_3d().navigation_map, player.global_position + away.normalized() * 9.0), 0.0)
	var home := await until(func(): return b.roost != null and b.flight.is_empty() and b.state == Enemy.State.IDLE, Bruxa.SEARCH_TIME + 8.0)
	check(home, "then flies back up to a roof (%s)" % b.roost)
	var other: Bruxa = L.bruxas[1] if L.bruxas[0] == b else L.bruxas[0]
	other.take_hit(3)
	check(other.state == Enemy.State.DEAD and not other.is_in_group("enemy"), "a bolt (3) kills one")
	WorldTime.reset(6 * 60 + 1); L.day._step(0.0)
	var gone := await until(func(): return not is_instance_valid(b), 8.0)
	check(gone, "at dawn the living fly off over the Colônia and are gone")
	L.night_watch = false


# --- O Poceiro (../docs/MUTANTES_NOITE.md): up out of the well at night, hunts by ear, back down at dawn ----------
func poceiro_tests() -> void:
	var map: RID = L.get_world_3d().navigation_map
	WorldTime.reset(10 * 60); L.day._step(0.0)
	L.night_watch = true; await wait(0.3)
	await _lantern(false)
	put(player, L.ground(-1.0, 24.0), PI)
	Audio.heard.clear(); player.health = 99
	WorldTime.reset(21 * 60); L.day._step(0.0); await wait(0.3)
	_hush_carpideira()
	for b in L.bruxas:
		b.active = false
	var p: Poceiro = L.poceiro
	check(p != null and not p.flight.is_empty() and p.global_position.y < p.mouth.y, "at nightfall something climbs up the well")
	var out := await until(func(): return p.flight.is_empty() and p.state == Enemy.State.IDLE, 8.0)
	await wait(0.5)
	check(out and p.is_on_floor() and p.global_position.distance_to(p.beside) < 0.8 and "poceiro_agua" in Audio.heard,
		"O Poceiro hauls himself out, water pouring off him, and stands by the well (%.2f m off)" % p.global_position.distance_to(p.beside))
	p.pause = 999.0  # he stays put between the hearing checks
	var near: Vector3 = NavigationServer3D.map_get_closest_point(map, p.global_position + Vector3(0, 0, 5.0))
	var d := p.global_position - near
	put(player, near, atan2(-d.x, -d.z)); await wait(0.6); await shot("v33_poceiro_poco")
	player.crouch(); await wait(2.5)
	check(player.mode == Player.Mode.CROUCH and p.state == Enemy.State.IDLE and p.heard_at == Vector3.INF,
		"crouched and still %.1f m from him: he does not hear you" % player.global_position.distance_to(p.global_position))
	player.crouch(); await until(func(): return player.action == "", 2.0)
	put(player, NavigationServer3D.map_get_closest_point(map, p.global_position + Vector3(0, 0, 12.0)), PI)
	Audio.heard.clear()
	Input.action_press("sprint"); await walk(1.0); Input.action_release("sprint")
	var heard := await until(func(): return p.state in [Enemy.State.ALERT, Enemy.State.CHASE], 2.0)
	check(heard and "poceiro_rugido" in Audio.heard, "a sprint %.0f m off: he hears it and roars" % player.global_position.distance_to(p.global_position))
	var spot: Vector3 = p.heard_at
	put(player, NavigationServer3D.map_get_closest_point(map, spot + Vector3(5.0, 0, 0)), PI); player.crouch()
	var h0 := player.health
	var there := await until(func(): return p.listening > 0.0, 15.0)
	check(there and p.global_position.distance_to(spot) < 1.6 and player.health == h0,
		"he goes to where the sound was, not to you, and stands listening (%.1f m from it)" % p.global_position.distance_to(spot))
	player.crouch(); await until(func(): return player.action == "", 2.0)
	await until(func(): return p.listening <= 0.0, Poceiro.LISTEN + 1.0)
	var front: Vector3 = p.global_position - p.global_basis.z * 1.1
	d = p.global_position - front
	put(player, NavigationServer3D.map_get_closest_point(map, front), atan2(-d.x, -d.z))
	h0 = player.health
	var hit := await until(func(): return player.health <= h0 - 2.0, 6.0)
	await shot("v34_poceiro_golpe")
	check(hit, "at arm's length the blind man feels you: the two-fisted blow takes 2 (%.0f -> %.0f)" % [h0, player.health])
	await until(func(): return p.state == Enemy.State.CHASE and player.action == "", 4.0)
	put(player, NavigationServer3D.map_get_closest_point(map, p.global_position + Vector3(-7.0, 0, 6.0)), 0.0); player.crouch()
	await wait(0.3)
	p.take_hit(1)
	check(p.heard_at.distance_to(player.global_position) < 0.5, "a hit tells him where you are")
	await until(func(): return p.state != Enemy.State.HIT, 2.0)
	L._bell()
	var door: Vector3 = L.marker("porta_capela").position
	var d0 := p.global_position.distance_to(door)
	await wait(4.0)
	check(p.heard_at.distance_to(door) < 0.5 and p.global_position.distance_to(door) < d0 - 3.0,
		"the chapel bell draws him to the church (%.1f -> %.1f m)" % [d0, p.global_position.distance_to(door)])
	WorldTime.reset(6 * 60 + 1); L.day._step(0.0)
	var gone := await until(func(): return not is_instance_valid(p), 30.0)
	check(gone, "at dawn he goes back to the well and down it")
	L.night_watch = false


# --- A Carpideira (../docs/MUTANTES_NOITE.md): weeps down the alleys with a candle; seen, she screams the others in -
func carpideira_tests() -> void:
	WorldTime.reset(10 * 60); L.day._step(0.0)
	L.night_watch = true; await wait(0.3)
	if player.mode == Player.Mode.CROUCH:  # (poceiro_tests leaves him crouched)
		await until(func(): return player.action == "", 2.0); player.crouch()
	await _lantern(false)
	put(player, L.ground(-1.0, 24.0), PI); player.health = 99
	WorldTime.reset(21 * 60); L.day._step(0.0); await wait(0.3)
	_hush_bruxas_poceiro()
	var c: Carpideira = L.carpideira
	check(c != null and L.alleys.size() >= 8 and c.global_position.distance_to(player.global_position) > 18.0
		and c.candle.is_in_group("vela") and c.candle.light_energy > 1.0,
		"at nightfall A Carpideira starts down an alley far off, her candle lit (%d alleys)" % L.alleys.size())
	var from := c.global_position
	await wait(4.0)
	check(c.state == Enemy.State.IDLE and c.global_position.distance_to(from) > 1.0 and c.weeping.volume_db > -10.0,
		"she walks the alleys weeping (%.1f m)" % c.global_position.distance_to(from))
	Audio.heard.clear(); c.cry_in = 0.0; await wait(0.3)
	check("carpideira_crianca" in Audio.heard and c.hush > 0.0, "now and then the weeping turns into a child's crying")
	c.pause = 999.0  # she stands where she is from here on
	# her candle calls a bruxa down off a roof: she circles it like a moth, no darts
	var b: Bruxa = null; var spot := Vector3.INF
	for x in L.bruxas:
		spot = _below(x.roost)
		if spot != Vector3.INF:
			b = x; break
	check(b != null, "open ground in plain view of a roof (%s)" % spot)
	if b == null:
		return
	c.active = false; put(c, spot, 0.0)
	put(player, L.ground(-1.0, 40.0), PI)
	b.active = true
	var moth := await until(func(): return b.lamp == c.candle and b.state == Enemy.State.CHASE and b.flight.is_empty(), 10.0)
	await wait(1.5)
	check(moth and b.global_position.distance_to(c.global_position) < Bruxa.ORBIT + 1.5 and not b.darting,
		"her candle calls a bruxa down off the roof: she circles it (%.1f m off)" % b.global_position.distance_to(c.global_position))
	var view := _open_from(c, 7.0)
	if view != Vector3.INF:  # the picture: her and the moth round her candle, from 7 m
		var v := c.global_position - view; c.rotation.y = atan2(v.x, v.z)
		put(player, view, atan2(-v.x, -v.z)); player.pitch.rotation.x = 0.0; await wait(0.8); await shot("v35_carpideira_vela")
	b.active = false
	# what she sees: only in front of her, as far as your light lets her
	var at := _open_from(c, 6.0)
	check(at != Vector3.INF, "open ground 6 m from her (%s)" % at)
	if at == Vector3.INF:
		return
	var d := at - c.global_position
	c.rotation.y = atan2(d.x, d.z)  # her back to you
	put(player, at, atan2(d.x, d.z)); await _lantern(true)
	Audio.heard.clear(); c.active = true; await wait(1.0)
	check(c.state == Enemy.State.IDLE and c.notice == 0.0, "behind her back, even with the lantern, she does not see you")
	c.active = false; await _lantern(false); await until(func(): return player.action == "", 2.0); player.crouch()
	c.rotation.y = atan2(-d.x, -d.z); c.active = true; await wait(1.0)  # turned to you
	check(c.state == Enemy.State.IDLE, "in front of her at 6 m, crouched in the dark: she does not see you")
	await until(func(): return player.action == "", 2.0); player.crouch()
	var seen := await until(func(): return c.state == Enemy.State.ALERT, 2.0)
	check(seen and "carpideira_suspiro" in Audio.heard, "standing up in the dark at 6 m: she sees you and gasps")
	put(player, L.ground(-1.0, 40.0), PI)
	var calm := await until(func(): return c.state == Enemy.State.IDLE, 4.0)
	check(calm and "carpideira_grito" not in Audio.heard, "out of her sight before she screams: she goes back to weeping")
	# the scream: the poceiro hears it, the bruxas come to it
	put(player, at, atan2(d.x, d.z)); await _lantern(true)
	var screamed := await until(func(): return "carpideira_grito" in Audio.heard, 4.0)
	await wait(0.4); await shot("v36_carpideira_grito")
	var called: Array = L.bruxas.filter(func(x): return is_instance_valid(x) and x.last_light.distance_to(player.global_position) < 1.0)
	check(screamed and c.state == Enemy.State.CHASE and L.poceiro.heard_at.distance_to(player.global_position) < 1.0 and called.size() > 0,
		"she stares, then screams: the poceiro hears where you are, %d bruxa(s) fly to it" % called.size())
	# she follows at a distance, and loses you out of sight
	await until(func(): return c.scream_t <= 0.0, 3.0)
	var away := _open_from(c, 11.0)
	if away != Vector3.INF:
		put(player, away, 0.0)
		var d0 := c.global_position.distance_to(player.global_position)
		await wait(3.0)
		check(c.global_position.distance_to(player.global_position) < d0 - 1.5,
			"she follows you (%.1f -> %.1f m)" % [d0, c.global_position.distance_to(player.global_position)])
	await _lantern(false); put(player, L.ground(-1.0, 40.0), PI)
	var gave_up := await until(func(): return c.state == Enemy.State.IDLE, Carpideira.LOSE + 4.0)
	check(gave_up, "out of her sight she gives up and goes back to weeping")
	# weak: a slash from in front only makes her scream; anything from behind kills her
	c.pause = 999.0; at = _open_from(c, 1.4)
	d = at - c.global_position; c.rotation.y = atan2(-d.x, -d.z); put(player, at, atan2(d.x, d.z))
	Audio.heard.clear(); c.take_hit(1)
	var shriek := await until(func(): return "carpideira_grito" in Audio.heard, 2.0)
	check(shriek and c.health == 1, "a slash from in front does not kill her: she screams")
	c.active = false; await wait(0.2); c.rotation.y = atan2(d.x, d.z)  # her back to you
	c.take_hit(1)
	await wait(1.0)
	check(c.state == Enemy.State.DEAD and not c.candle.is_in_group("vela") and c.candle.light_energy < 0.5 and not c.weeping.playing,
		"from behind, one blow kills her: the candle goes out")
	# dawn: a new night's Carpideira walks to the chapel and goes in
	WorldTime.reset(10 * 60); L.day._step(0.0); await wait(0.3)
	WorldTime.reset(21 * 60); L.day._step(0.0); await wait(0.3)
	_hush_bruxas_poceiro()
	c = L.carpideira
	var door: Vector3 = L.marker("porta_capela").position
	put(c, NavigationServer3D.map_get_closest_point(L.get_world_3d().navigation_map, door + Vector3(6.0, 0, 6.0)), 0.0)
	await wait(0.3)
	WorldTime.reset(6 * 60 + 1); L.day._step(0.0)
	var gone := await until(func(): return not is_instance_valid(c), 20.0)
	check(gone, "at dawn she walks to the chapel and goes in")
	L.night_watch = false


func _hush_carpideira() -> void:  # the other night tests run without her
	L.carpideira.active = false; L.carpideira.candle.remove_from_group("vela")


func _hush_bruxas_poceiro() -> void:
	for b in L.bruxas:
		b.active = false
	L.poceiro.active = false


## Open ground (on the navmesh) dist metres from c, with a clear line from her eyes.
func _open_from(c: Node3D, dist: float) -> Vector3:
	var w: World3D = L.get_world_3d()
	for i in 24:
		var a := TAU * i / 24.0
		var q: Vector3 = L.ground(c.global_position.x + cos(a) * dist, c.global_position.z + sin(a) * dist, c.global_position.y + 3.0)
		var rq := PhysicsRayQueryParameters3D.create(c.global_position + Vector3(0, 1.6, 0), q + Vector3(0, 1.3, 0), 1, [c.get_rid()])
		if NavigationServer3D.map_get_closest_point(w.navigation_map, q).distance_to(q) < 0.3 \
				and w.direct_space_state.intersect_ray(rq).is_empty():
			return q
	return Vector3.INF


## The lantern in hand (true) or on the belt, once he is free to move it.
func _lantern(on: bool) -> void:
	await until(func(): return player.action == "" and player.mode == Player.Mode.EXPLORE, 3.0)
	if player.lantern_out != on:
		player.toggle_lantern()


## Open ground (on the navmesh) about 11 m from the roof ridge p, in plain view of it.
func _below(p: Vector3) -> Vector3:
	var w: World3D = L.get_world_3d()
	for i in 24:
		var a := TAU * i / 24.0
		var q: Vector3 = L.ground(p.x + cos(a) * 11.0, p.z + sin(a) * 11.0)
		var rq := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.2, 0), q + Vector3(0, 1.3, 0), 1)
		if NavigationServer3D.map_get_closest_point(w.navigation_map, q).distance_to(q) < 0.3 				and w.direct_space_state.intersect_ray(rq).is_empty():
			return q
	return Vector3.INF


# --- the armaria's porch (Steps): from the foot of its stone step he walks up onto the deck --------------------------
func porch_tests() -> void:
	var door: Node3D = L.marker("porta_armaria")
	put(player, door.position, door.rotation.y); player.pivot.rotation.y = door.rotation.y
	await wait(0.4)
	var y0 := player.global_position.y
	Input.action_press("forward"); await wait(1.6); Input.action_release("forward")
	await wait(0.3); await shot("v40_alpendre")
	check(player.global_position.y - y0 > 0.4 and player.is_on_floor(),
		"from the foot of the armaria's step, W: up onto the porch (%.2f m up)" % (player.global_position.y - y0))


# --- talking (Talk, DialogBox, Dialog): Dona Firmina's lines, a rumour in turn, her task from start to end -------------
func dialog_tests() -> void:
	WorldTime.reset(10 * 60); L.day._step(0.0)
	var npc: Npc = L.npcs["benzedeira"]
	var front := npc.global_position + npc.global_basis.z * 1.3
	put(player, L.ground(front.x, front.z), 0.0); await wait(0.4)
	check(L.interactor.current == npc.talk and L.hud.prompt.text == "E · falar com Dona Firmina", "by her: \"%s\"" % L.hud.prompt.text)
	await tap("interact"); await wait(0.3)
	var box: DialogBox = L.dialog
	var to := npc.global_position - player.global_position
	check(box.visible and get_tree().paused and box.name_l.text == "Dona Firmina" and box.typing()
		and absf(angle_difference(player.rotation.y, atan2(-to.x, -to.z))) < 0.05,
		"E: he turns to her, the game pauses, her name on the tab, her words coming out letter by letter")
	await wait(0.3); await shot("v41_dialogo_fala")
	await tap("interact")
	check(not box.typing() and box.text.text.begins_with("Ave Maria"), "E shows the rest of the page at once")
	var said := [box.text.text]
	for k in 12:  # one E a page (and one more to hurry a page still coming out)
		if box.choosing:
			break
		if box.typing():
			await tap("interact")
		await tap("interact")
		if not box.choosing:
			said.append(box.text.text)
	var pages := said.size()
	var opts := box.rows.map(func(b): return b.text.substr(4))
	check(box.choosing and pages == 3 and opts == ["Perguntar o que se fala por aí", "Perguntar sobre ela", "Perguntar sobre a Colônia",
		"Perguntar se precisa de alguma coisa", "Ir embora"], "three pages of greeting, then her options: %s" % [opts])
	await wait(0.2); await shot("v42_dialogo_opcoes")
	await tap("back"); await wait(0.05)
	check(box.focused() == 1, "S points at the next option")
	box.pick(0); await tap("interact")
	var rumour1 := box.text.text
	box._choose(); box.pick(0); await tap("interact")
	check(box.text.text != rumour1, "ask again what people say: another rumour (\"%s...\")" % box.text.text.substr(0, 30))
	box._choose()
	var e := InputEventKey.new(); e.physical_keycode = KEY_4; e.pressed = true; Input.parse_input_event(e)
	await get_tree().process_frame; await get_tree().process_frame
	check(Story.task("garrafada") == "ativa" and box.text.text.begins_with("Preciso"), "4 (\"se precisa de alguma coisa\"): she gives the task")
	box._choose()
	opts = box.rows.map(func(b): return b.text.substr(4))
	check("Falar da garrafada" in opts and "Perguntar se precisa de alguma coisa" not in opts, "...which changes what you can ask: %s" % [opts])
	await tap("ui_cancel"); await wait(0.2)
	check(not box.visible and not get_tree().paused and L.hud.message.text == "Nova tarefa: A garrafada do altar",
		"Esc ends the talk; the HUD: \"%s\"" % L.hud.message.text)
	Inventory.add("garrafada"); player.health = 1.0
	var money := Inventory.money
	await tap("interact"); await wait(0.2)
	check(box.text.text.begins_with("Ainda de pé"), "talking again: a shorter greeting (\"%s\")" % box.text.text.substr(0, 20))
	box._choose()
	opts = box.rows.map(func(b): return b.text.substr(4))
	var give: int = opts.find("Entregar a garrafada")
	box.pick(give)
	check(Story.task("garrafada") == "feita" and not Inventory.has("garrafada") and Inventory.money == money + 20
		and player.health == player.max_health, "the garrafada handed over: task done, healed, Cr$ 20 more")
	box._choose()
	opts = box.rows.map(func(b): return b.text.substr(4))
	check(opts.all(func(o): return "garrafada" not in o and "precisa" not in o), "...and no more talk of it: %s" % [opts])
	box.close(); await wait(0.1)
	WorldTime.reset(22 * 60); L.day._step(0.0); L.night_watch = false
	await tap("interact"); await wait(0.2)
	check(box.text.text.begins_with("Não é hora"), "at night she would rather not talk (\"%s\")" % box.text.text.substr(0, 20))
	box.close()
	WorldTime.reset(10 * 60); L.day._step(0.0)


## The oratório by the road in: standing, clear of the road and the ruin, its prompt.
func oratorio_tests() -> void:
	var o: Oratorio = L.find_children("*", "Oratorio", true, false)[0]
	put(player, o.global_position + o.global_basis.z * 2.2, o.rotation.y); player.pivot.rotation.y = o.rotation.y
	await wait(0.6); await shot("oratorio_estrada")
	var front := o.global_position + o.global_basis.z * 0.8
	check(absf(o.global_position.y - L.ground(front.x, front.z).y) < 0.3, "on the ground")
	put(player, o.global_position + o.global_basis.z * 1.0, o.rotation.y); await wait(0.4)
	check(L.hud.prompt.text == "E · rezar no oratório", "its prompt: \"%s\"" % L.hud.prompt.text)


# What closes the map (../docs/VILAREJO.md "Bordas"): he walks into each edge and something he can see stops him,
# never the invisible walls behind (x = +-54); nowhere does he fall.
func edges_tests() -> void:
	var hp := player.health
	for side in [1.0, -1.0]:  # the rocky banks east and west, too steep to climb
		for z in [-30.0, 0.0, 30.0]:
			put(player, L.ground(side * 44.0, z), -side * PI / 2); await wait(0.3)
			await walk(5.0); await wait(0.3)
			var x := player.global_position.x
			check(absf(x) < 52.5, "the %s bank (or a tree on it) stops him at x=%.1f (z=%d), before the walls" % ["east" if side > 0 else "west", x, z])
	put(player, L.ground(44.0, 10.0), -PI / 2); player.pivot.rotation.y = -PI / 2; await wait(0.6); await shot("borda_leste")
	for x in [-30.0, 0.0, 8.0, 30.0]:  # the ravine: the fence along its brink (the road's barricade at x=0)
		put(player, L.ground(x, 42.0), PI); await wait(0.3)
		await walk(4.0); await wait(0.3)
		var p := player.global_position
		check(p.z < 46.4 and player.is_on_floor(), "the ravine's fence stops him at z=%.1f (x=%d), on his feet" % [p.z, x])
	put(player, L.ground(2.0, 43.5), PI); player.pivot.rotation.y = PI; await wait(0.6); await shot("borda_ravina")
	for x in [-3.5, 0.0, 3.5]:  # the Colônia's wall: the gate shut, no gap beside its pillars
		put(player, L.ground(x, -56.0), 0.0); await wait(0.3)
		await walk(3.0); await wait(0.3)
		check(player.global_position.z > -59.8, "the Colônia's wall stops him at z=%.2f (x=%.1f)" % [player.global_position.z, x])
	check(player.health == hp, "no fall hurt him (%d of %d)" % [player.health, hp])
	var stood: Vector3 = L.ground(5.0, 20.0)  # the safety net: out of the world, back where he stood
	put(player, stood, 0.0); await wait(0.5)
	player.global_position = Vector3(5.0, -80.0, 20.0); await wait(0.3)
	check(absf(player.global_position.y - stood.y) < 1.0, "fallen out of the world, he is put back (y=%.1f)" % player.global_position.y)


# The Colônia's gate (Gate): locked at first; its key opens it a crack, too narrow to pass; then E goes up.
func gate_tests() -> void:
	var gate: Gate = L.find_children("*", "Gate", true, false)[0]
	Story.marks.erase("aberta:" + gate.id); Story.marks.erase("destrancado:chave_portao"); Inventory.take("chave_portao", 99)
	var said := []; player.notice.connect(func(t): said.append(t))
	var front := gate.global_position + gate.global_basis.z * 1.3
	put(player, L.ground(front.x, front.z), gate.rotation.y); await wait(0.6); await shot("portao_trancado")
	check(L.hud.prompt.text == "E · abrir o portão", "at the gate: \"%s\"" % L.hud.prompt.text)
	SceneRouter.requested = ""; await tap("interact")
	check(not gate.opened() and SceneRouter.requested == "" and said.size() > 0 and said[-1] == gate.refusal,
		"without the key it stays shut: \"%s\"" % (said[-1] if said else ""))
	Inventory.add("chave_portao"); await tap("interact"); await wait(3.2)
	check(gate.opened() and not Inventory.has("chave_portao") and gate.chain == null, "the key spent, the chain gone")
	check(absf(rad_to_deg(gate.leaves[0].rotation.y) - Gate.AJAR) < 1.0 and absf(rad_to_deg(gate.leaves[1].rotation.y) + Gate.AJAR) < 1.0,
		"both leaves swung in, ajar (%.0f, %.0f deg)" % [rad_to_deg(gate.leaves[0].rotation.y), rad_to_deg(gate.leaves[1].rotation.y)])
	await shot("portao_fresta")
	put(player, L.ground(gate.global_position.x, gate.global_position.z + 1.0), gate.rotation.y); await wait(0.3)
	await walk(3.0); await wait(0.3)
	var tips := gate.global_position.z - (Gate.WIDTH / 2) * sin(deg_to_rad(Gate.AJAR))  # how far in the leaves' edges swung
	check(player.global_position.z > tips, "the gap is too narrow to go through: he stops between the leaves (z=%.2f, edges at %.2f)" % [player.global_position.z, tips])
	put(player, L.ground(front.x, front.z), gate.rotation.y); await wait(0.4)
	check(L.hud.prompt.text == "E · entrar na Colônia", "open: \"%s\"" % L.hud.prompt.text)
	await tap("interact")
	check(SceneRouter.requested == Paths.COLONIA, "E goes up to the Colônia (%s)" % SceneRouter.requested)
	var again := Gate.make(L, gate.position + Vector3(0, 0, 30), gate.rotation.y, gate.id, "chave_portao", Paths.COLONIA, "")
	check(again.chain == null and absf(rad_to_deg(again.leaves[0].rotation.y) - Gate.AJAR) < 1.0, "back in the village it is still open")
	again.queue_free()

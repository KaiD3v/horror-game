# The village (scenes/levels/vilarejo.tscn): the GLB's colliders and navmesh, sounds, NPCs, walking it, the doors in
# and out, the story pieces, weather and crows, the finish, the chase, the notes.
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
	put(player, L.ground(1.0, 46.5), PI); await wait(0.6); await shot("v19_ponte")             # the way out, fallen

	# it gives chase across the square and up the road, over the slope
	player.health = 99
	put(player, L.ground(0.0, 12.0), PI); put(L.enemy, L.ground(4.5, 0.0), PI)
	L.enemy.target = player; L.enemy.active = true; L.enemy.go(Enemy.State.CHASE, "Walk")
	var ok = await until(func(): return L.enemy.global_position.distance_to(player.global_position) < 2.2, 20.0)
	await shot("v7_perseguicao")
	check(ok, "the mutant follows the navmesh over the terrain to you (%.1f m away)" % L.enemy.global_position.distance_to(player.global_position))
	L.enemy.active = false; put(L.enemy, L.ground(-30.0, 40.0), 0.0)
	await notes_suite()
	await day_tests()
	await bruxa_tests()
	await poceiro_tests()



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

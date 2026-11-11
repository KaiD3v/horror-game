# What every interior (scripts/levels/interior.gd) must do: you come in at the door, its people idle, its lamps and
# sounds are on, it is solid, footsteps sound on its floor, its notes, and E at the door takes you back out.
# Each room's test (test_armaria.gd...) extends this one and adds its own walk round in tour().
extends AutoTest


func run() -> void:
	await wait(1.5); await shot(L.door + "_1_entrada")
	var entry = (L.room.get_node("entrada") as Node3D).position
	check(player.is_on_floor() and player.global_position.distance_to(entry) < 0.3, "you come in just inside the door, on the floor")
	for who in L.npcs:
		var ap: AnimationPlayer = L.npcs[who].anim
		check(ap.is_playing() and ap.current_animation == "Idle", "%s idles behind the counter" % who)
	check(L.lights.size() >= 4, "lit by its own lamps and windows (%d lights)" % L.lights.size())
	var bodies: int = L.room.find_children("*", "StaticBody3D", true, false).size()
	check(bodies >= 3, "room, ceiling and furniture are solid (%d bodies)" % bodies)
	check(L.tone.playing and L.tone.stream.loop_mode != AudioStreamWAV.LOOP_DISABLED, "room tone loops")
	check(L.loops.all(func(l): return l.playing), "%d sounds in the room (fire, candles, clock)" % L.loops.size())
	var s0: int = L.footsteps.steps
	await tour()
	check(L.footsteps.steps - s0 >= 2, "footsteps on the %s floor (%d)" % [L.footsteps.kind, L.footsteps.steps - s0])
	await notes_suite()
	await chest_suite()
	await shop_suite()
	put(player, entry + Vector3(0, 0.02, 0), 0.0); await wait(0.4)
	check(L.hud.prompt.visible, "at the door: \"%s\"" % L.hud.prompt.text)
	await tap("interact")
	check(SceneRouter.requested == Paths.VILAREJO and SceneRouter.arriving == L.door,
		"E at the door goes back out to the village (%s)" % SceneRouter.requested)
	await cutaway()
	# the windows by the hour: daylight by day, nearly dark at night
	WorldTime.reset(13 * 60); L.day._step(0.0)
	var by_day: float = L.windows.map(func(w): return w.light_energy).reduce(func(a, b): return a + b, 0.0)
	WorldTime.reset(23 * 60); L.day._step(0.0)
	var by_night: float = L.windows.map(func(w): return w.light_energy).reduce(func(a, b): return a + b, 0.0)
	check(L.windows.size() > 0 and by_night < by_day * 0.3 and L.day.panes.size() > 0,
		"the windows go dark at night (%.2f by day, %.2f at night)" % [by_day, by_night])
	await wait(0.3); await shot(L.door + "_9_noite")


func tour() -> void:  # the room's own checks and captures
	pass


func cutaway() -> void:  # the room from above with the ceiling off: res://captures/demo_<door>_0_planta.png
	var ceiling: Node3D = L.room.get_node("teto")
	ceiling.visible = false
	var top = Camera3D.new(); L.add_child(top)
	top.position = L.cutaway; top.look_at(Vector3(0, 0.3, -0.3)); top.fov = 60
	L.env.ambient_light_energy = 0.9
	top.make_current(); await wait(0.2); await shot(L.door + "_0_planta")
	ceiling.visible = true; L.env.ambient_light_energy = L.ambient
	player.cam.make_current(); top.queue_free()

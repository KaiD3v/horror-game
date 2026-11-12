# The crypt under the Moura mausoleum (scenes/interiors/jazigo.tscn, ../docs/CHAVE_DO_PORTAO.md): the arena. In at the
# grate, down the stair; the round room lit by its candles, the columns, the altar too high to climb, the coffin; the
# box of bolts at the stair's foot; back up to the cemetery.
extends AutoTest


func run() -> void:
	await wait(1.0)
	var entry: Node3D = L.room.get_node("entrada")
	check(player.is_on_floor() and player.global_position.distance_to(entry.position) < 0.3, "in at the grate, on the landing")
	check(L.boss != null and L.boss.phase == 0, "O Porteiro waits by the coffin")
	await walk(4.5)
	check(player.global_position.y < 0.3 and player.global_position.z < -4.0, "down the stair into the crypt (y %.2f)" % player.global_position.y)
	await shot("jazigo_1_escada")
	check(L.candles.size() >= 8 and L.candles.all(func(c): return c.visible and c.light_energy > 0.0), "lit by its candles (%d)" % L.candles.size())
	for n in ["altar", "caixao", "porteiro", "escada", "virotes"]:
		check(L.room.has_node(n), "its marker: %s" % n)
	var bolts := Inventory.count("virote")
	var box: Node3D = L.room.get_node("virotes")
	put(player, box.position + Vector3(-0.7, 0, 0), -PI / 2); await wait(0.3)
	await tap("interact"); await wait(0.2)
	check(Inventory.count("virote") == bolts + 6, "a box of bolts at the stair's foot (6)")
	var altar: Node3D = L.room.get_node("altar")
	put(player, Vector3(altar.position.x, 0.05, altar.position.z + 1.6), 0.0); await wait(0.3)
	check(not (L.interactor.current is Climbable), "the altar: too high to climb (\"%s\")" % L.hud.prompt.text)
	var top := Camera3D.new(); L.add_child(top); top.position = Vector3(0, 13, -2); top.look_at(Vector3(0, 0, -11.5)); top.fov = 70
	(L.room.get_node("teto") as Node3D).visible = false; L.env.ambient_light_energy = 0.5
	top.make_current(); await wait(0.2); await shot("jazigo_0_planta")
	(L.room.get_node("teto") as Node3D).visible = true; L.env.ambient_light_energy = L.ambient; player.cam.make_current(); top.queue_free()
	put(player, entry.position, PI); await wait(0.3)
	await tap("interact")
	check(SceneRouter.requested == Paths.VILAREJO and SceneRouter.arriving == "jazigo", "E at the grate: back up to the cemetery")
	SceneRouter.requested = ""; SceneRouter.arriving = ""
	await boss_tests()

# --- O Porteiro (../docs/CHAVE_DO_PORTAO.md): asleep until you come down; the side swing blocked, the smash through the
# block; up on the altar only bolts hurt him and the columns stop his stones; the dark: he goes for the lantern in the
# hand, not for one on the belt; from behind triple; his death: the stair open, the keys and the heart ----------------
func boss_tests() -> void:
	var b: Porteiro = L.boss
	b.active = true; player.health = 99.0; player.max_health = 99
	put(player, Vector3(0, 0.05, -8.0), 0.0); await wait(0.6)  # (the walk round the room above may have woken him already)
	check(b.phase == 1 and L.shut != null and L.bar != null, "down on the floor: he wakes, the stair shuts behind, his name and health up top")
	await shot("jazigo_3_porteiro")
	if player.mode != Player.Mode.COMBAT:
		await tap("draw"); await wait(1.2)
	# the side swing, on the block: only a chip; the smash: through it
	put(player, b.global_position - b.global_basis.z * 1.6, b.rotation.y + PI); await wait(0.2)
	Input.action_press("block"); await wait(0.4)
	var hp := player.health
	b.blow = "Attack"; b.cooldown = 0.0; b.go(Enemy.State.ATTACK, "Attack", 0.1); await wait(1.4)
	check(absf(hp - player.health - Player.BLOCK_CHIP) < 0.01, "the side swing on the machete: a chip gets through (%.2f)" % (hp - player.health))
	hp = player.health
	b.blow = "Smash"; b.go(Enemy.State.ATTACK, "Smash", 0.1); await wait(1.1)
	check(absf(hp - player.health - 2.0) < 0.01, "the smash goes through the block: 2 (%.2f)" % (hp - player.health))
	await shot("jazigo_4_golpe")
	Input.action_release("block"); await wait(1.2)
	# behind: three times; to 20: up onto the altar
	var h := b.health
	put(player, b.global_position + b.global_basis.z * 1.2, b.rotation.y); await wait(0.1)
	b.take_hit(1, "facao")
	check(h - b.health == Porteiro.BACK, "a blow from behind: %d" % (h - b.health))
	b.take_hit(99, "facao")  # (a huge blow: still only down to the next phase)
	await until(func(): return b.flight.is_empty() and b.phase == 2, 4.0); await wait(0.5)
	check(b.phase == 2 and b.health == Porteiro.P2 and absf(b.global_position.y - b.altar.y) < 0.3,
		"no blow skips a phase: at %d, up onto the altar (%.2f)" % [b.health, b.global_position.y])
	h = b.health
	b.take_hit(2, "facao")
	check(b.health == h, "up there the machete does nothing")
	var from := Vector3(0, 1.4, -10.0)
	Bolt.fire(L, from, (b.global_position + Vector3(0, 1.6, 0) - from).normalized(), player.get_rid()); await wait(0.6)
	check(h - b.health == Bolt.DAMAGE, "a bolt in his lantern: %d" % (h - b.health))
	# the stones: in the open they hurt; behind a column they break on it
	var col := Vector3(sin(PI / 8) * 4.6, 0.05, -(11.5 - cos(PI / 8) * 4.6))  # (the column south of the altar's right)
	var away := (col - b.global_position); away.y = 0
	put(player, col + away.normalized() * 1.0, 0.0); await wait(0.1)
	hp = player.health
	b.throw_in = 0.0; await wait(Porteiro.THROW_EVERY + 0.5)
	check(player.health == hp, "behind a column: the stone breaks on it")
	put(player, Vector3(-3.0, 0.05, -9.5), 0.0); hp = player.health
	b.throw_in = 0.0; await until(func(): return player.health < hp, Porteiro.THROW_EVERY + 2.5)
	check(player.health < hp, "in the open: a stone finds him")
	await shot("jazigo_5_altar")
	# to 10: the lantern breaks, the candles go out, down into the dark
	check(b.phase == 2 and absf(b.global_position.y - b.altar.y) < 0.3, "...and he is still up there after the stones")
	b.take_hit(b.health - Porteiro.P3, "besta")
	await until(func(): return b.flight.is_empty() and b.phase == 3, 4.0); await wait(3.5)
	check(b.phase == 3 and not b.lamp_on and L.candles.all(func(c): return c.light_energy < 0.05), "at %d: his lantern broken, the candles out" % Porteiro.P3)
	await shot("jazigo_6_escuro")
	await tap("draw"); await wait(1.2)
	if player.holds_lantern():
		await tap("lantern"); await wait(0.9)
	await tap("crouch"); await wait(0.8)
	put(player, Vector3(4.0, 0.05, -6.5), 0.0); await wait(0.2)
	b.heard_at = Vector3.INF
	var d0 := b.global_position.distance_to(player.global_position)
	await wait(3.0)
	check(b.heard_at == Vector3.INF and b.global_position.distance_to(player.global_position) > d0 - 0.5, "the lantern on the belt, crouched and still: he does not find you")
	await tap("crouch"); await wait(0.8)
	await tap("lantern"); await wait(0.9)
	await wait(1.5)
	check(b.heard_at != Vector3.INF and b.global_position.distance_to(player.global_position) < d0 - 0.5, "the lantern in hand: he comes for the light")
	# his death
	b.take_hit(99, "besta")
	await until(func(): return L.shut == null, 6.0); await wait(0.5)
	check(Story.has("morto:porteiro") and L.shut == null, "dead: the stair open again")
	var spoils: Array = L.find_children("*", "Pickup", true, false)
	var key: Array = spoils.filter(func(p): return p.id == "jazigo_chave")
	var heart: Array = spoils.filter(func(p): return p.id == "jazigo_coracao")
	check(key.size() == 1 and heart.size() == 1, "his keys on the floor, something shining in the coffin")
	Story.set_task("chave", "ativa"); player.max_health = Inventory.health_max()
	var hearts := player.max_health
	if heart:
		heart[0].use(player)
		var fb: bool = await until(func(): return get_tree().get_first_node_in_group("found_banner") != null, 2.0)
		await wait(0.9); await shot("jazigo_7_coracao"); await tap("interact"); await wait(0.6)
		check(fb and player.max_health == hearts + 1, "the ex-voto heart: \"Você encontrou\", one more heart")
	if key:
		key[0].use(player); await wait(0.2)
		check(Inventory.has("chave_portao") and Story.task("chave") == "feita", "the gate's key: the task done")
	player.max_health = Inventory.health_max(); player.health = player.max_health

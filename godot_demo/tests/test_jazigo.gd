# The crypt under the Moura mausoleum (scenes/interiors/jazigo.tscn, ../docs/CHAVE_DO_PORTAO.md): the arena. In at the
# grate, down the stair; the round room lit by its candles, the columns, the altar too high to climb, the coffin; the
# box of bolts at the stair's foot; back up to the cemetery.
extends AutoTest


func run() -> void:
	await wait(1.0)
	var entry: Node3D = L.room.get_node("entrada")
	check(player.is_on_floor() and player.global_position.distance_to(entry.position) < 0.3, "in at the grate, on the landing")
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

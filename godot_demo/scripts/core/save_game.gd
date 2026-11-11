# Saving the game and the return point.
# A game is: what he carries (Inventory), what the shops sold (Shop), the trunks opened (Chest), the notes read
# (NotesReader), what happened (Story), the hour (WorldTime) and the weather (Weather); and where he stands, his
# health, its max, his breath's max and the lantern (in hand / on its hook). A bolt on the rail goes back to the quiver.
#   save        at an Oratorio (a prayer, its candle lit): written to path(), read back by "Continuar" (title menu)
#               or "Carregar o jogo salvo" (pause / death menus)
#   checkpoint  the same, in memory, taken as every scene opens (and at every save): dying, "Tentar de novo" puts
#               the world back as it was when he came in, and him where he came in
# Restoring sets the statics at once and leaves the player's part in `pending` for the next Level to place him.
class_name SaveGame

const VERSION := 1

static var checkpoint := {}
static var pending := {}


static func path() -> String:  # (the tests write their own: never the player's save)
	return "user://teste.save" if SceneRouter.testing() else "user://santa_clara.save"


static func exists() -> bool:
	return not read().is_empty()


static func capture(p: Player, scene: String) -> Dictionary:
	var items := Inventory.items.duplicate()
	if p.loaded:
		items["virote"] = items.get("virote", 0) + 1
	return {"versao": VERSION, "cena": scene, "pos": p.global_position, "giro": p.rotation.y,
		"vida": p.health, "vida_max": p.max_health, "folego_max": p.stamina_max, "lamparina": p.lantern_out,
		"dinheiro": Inventory.money, "itens": items, "vendido": Shop._sold.duplicate(), "baus": Chest.opened.duplicate(),
		"notas": NotesReader.read.duplicate(), "historia": Story.marks.duplicate(true), "minutos": WorldTime.minutes,
		"clima": [Weather.rain, Weather.fog, Weather.wet, Weather.rain_from, Weather.rain_until, Weather.fog_goal, Weather._planned]}


## Writes the game; it is also the new return point. False if it could not be written.
static func save(p: Player, scene: String) -> bool:
	var d := capture(p, scene)
	var f := FileAccess.open(path(), FileAccess.WRITE)
	if f == null:
		return false
	f.store_var(d)
	checkpoint = d
	return true


## The saved game, {} if there is none (or it is from another version, or broken).
static func read() -> Dictionary:
	var f := FileAccess.open(path(), FileAccess.READ)
	if f == null:
		return {}
	var d: Variant = f.get_var(false)  # (no objects out of a file)
	return d if d is Dictionary and d.get("versao", -1) == VERSION else {}


## The world as `d` has it; the player's part waits in `pending` for the level.
static func restore(d: Dictionary) -> void:
	Inventory.money = d.dinheiro; Inventory.items = d.itens.duplicate()
	Shop._sold = d.vendido.duplicate(); Chest.opened.assign(d.baus); NotesReader.read.assign(d.notas)
	Story.marks = d.historia.duplicate(true); WorldTime.minutes = d.minutos
	var c: Array = d.clima
	Weather.reset()
	Weather.rain = c[0]; Weather.fog = c[1]; Weather.wet = c[2]; Weather.rain_from = c[3]; Weather.rain_until = c[4]
	Weather.fog_goal = c[5]; Weather._planned = c[6]
	pending = d


## Level, as it makes the player: where he starts (a game being restored in this scene: where it says).
static func start(scene: String, usual: Transform3D) -> Transform3D:
	if pending.get("cena", "") != scene:
		return usual
	return Transform3D(Basis(Vector3.UP, pending.giro), pending.pos)


## ...once he is in the tree: the rest of him, then this scene's return point.
static func settle(p: Player, scene: String) -> void:
	if pending.get("cena", "") == scene:
		p.max_health = pending.vida_max; p.health = pending.vida; p.stamina_max = pending.folego_max
		if not pending.lamparina:
			p._set_lantern(false)
	pending = {}
	checkpoint = capture(p, scene)


## The saved game, from the title or a menu: the world as it was, then its scene.
static func load_saved(from: Node) -> bool:
	var d := read()
	if d.is_empty():
		return false
	restore(d)
	SceneRouter.go_to(from, d.cena, "", 1.0, "")
	return true


## Dying: back to how this scene was when he came in.
static func retry(from: Node) -> void:
	restore(checkpoint)
	SceneRouter.go_to(from, checkpoint.cena, "", 0.6, "")

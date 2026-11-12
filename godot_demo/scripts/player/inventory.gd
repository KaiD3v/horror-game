# What the protagonist carries: money and items (ItemCatalog ids -> how many). Kept across scenes (statics, like the
# clock and the notes); a new game starts it again.
class_name Inventory

const START_MONEY := 40
const START_ITEMS := {"lamparina": 1, "virote": 6, "atadura": 1}  # of the tools, only the lantern

const BASE_HEALTH := 3         # hearts with no ex-voto
const BEADS := 4               # rosary beads (conta_terco) to one more bead of breath (HudStatus.BEAD of stamina)

static var money := START_MONEY
static var items := START_ITEMS.duplicate()


static func reset() -> void:
	money = START_MONEY; items = START_ITEMS.duplicate()


static func count(id: String) -> int:
	return items.get(id, 0)


## Whether you have it (what unlocks a weapon, a door, an offer); "" = nothing asked, always true.
static func has(id: String) -> bool:
	return id == "" or count(id) > 0


## Every tool at once: the training room, the Colônia (no way in from the village yet) and the tests.
static func give_tools() -> void:
	for id in ItemCatalog.ITEMS:
		if ItemCatalog.tool(id) and not has(id):
			add(id)


static func add(id: String, n := 1) -> void:
	items[id] = count(id) + n
	if ItemCatalog.item(id).tipo == "melhoria":
		_grow()


## His hearts and his breath, from the upgrades carried (../docs/CHAVE_DO_PORTAO.md): every scene's player is made
## with these, so they hold everywhere.
static func health_max() -> int:
	return BASE_HEALTH + count("coracao_exvoto")


static func breath_max() -> float:
	return Player.STAMINA_MAX + HudStatus.BEAD * int(count("conta_terco") / BEADS)


## What an upgrade says when it is taken.
static func upgrade_line(id: String) -> String:
	if id == "conta_terco":
		var n := count(id)
		return "O terço ficou mais comprido: mais fôlego." if n % BEADS == 0 else "Conta de terço (%d de %d)" % [n % BEADS, BEADS]
	return "Um coração a mais."


## An upgrade just taken: the player grows at once (a new heart comes in full, as in Zelda).
static func _grow() -> void:
	var p: Player = (Engine.get_main_loop() as SceneTree).get_first_node_in_group("player")
	if p == null:
		return
	var heart := health_max() > p.max_health
	var breath := breath_max() > p.stamina_max
	p.max_health = health_max(); p.stamina_max = breath_max()
	if heart:
		p.health = p.max_health
	if breath:
		p.stamina = p.stamina_max


## Takes n of an item; false (and nothing taken) if there are not that many.
static func take(id: String, n := 1) -> bool:
	if count(id) < n:
		return false
	items[id] = count(id) - n
	return true


## Pays; false (and nothing paid) if there is not enough.
static func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	return true


## The first healing item you have (ItemCatalog order), "" none.
static func first_cure() -> String:
	for id in ItemCatalog.ITEMS:
		if ItemCatalog.item(id).tipo == "cura" and count(id) > 0:
			return id
	return ""


## Uses one of an item on the player, by its tipo. False if you have none or it would do nothing.
static func use(id: String, player: Player) -> bool:
	var it := ItemCatalog.item(id)
	match it.tipo:
		"cura":
			if player.health >= player.max_health or not take(id):
				return false
			player.heal(it.cura)
			return true
	return false

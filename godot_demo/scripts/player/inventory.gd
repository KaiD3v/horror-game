# What the protagonist carries: money and items (ItemCatalog ids -> how many). Kept across scenes (statics, like the
# clock and the notes); a new game starts it again.
class_name Inventory

const START_MONEY := 40
const START_ITEMS := {"lamparina": 1, "virote": 6, "atadura": 1}  # of the tools, only the lantern

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

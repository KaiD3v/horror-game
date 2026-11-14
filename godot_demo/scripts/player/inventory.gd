# What the protagonist carries: money and items (ItemCatalog ids -> how many). Kept across scenes (statics, like the
# clock and the notes); a new game starts it again. What runs out fits only so many (ROOM, ../docs/MELHORIAS.md): what
# does not fit stays where it lies. The lantern's querosene too (fuel, lit). What runs out fits only so many (ROOM, ../docs/MELHORIAS.md): what
# does not fit stays where it lies. The lantern's querosene too (fuel, lit).
class_name Inventory

const START_MONEY := 40
const START_ITEMS := {"lamparina": 1, "virote": 6, "atadura": 1, "querosene": 1}  # of the tools, only the lantern

## How much fits: what holds each kind (ItemCatalog tipo, or "dinheiro"), biggest first, and how many; "" = what he
## starts with (a cloth tied round the bolts, his coat's pocket, his trouser pocket).
const ROOM := {
	"municao": [["bolsa_cinto", 18], ["aljava_couro", 12], ["", 6]],
	"cura": [["estojo_celina", 6], ["embornal", 4], ["", 2]],
	"dinheiro": [["capanga", 250], ["porta_niquel", 120], ["", 60]],
}
const FULL := {"municao": "Não cabe mais nenhum virote.", "cura": "Não cabe mais nenhum curativo.",
	"dinheiro": "Não cabe mais dinheiro no bolso."}
const LAMP := 300.0            # s of light in a full lantern (a game minute a second: five hours of the night)
const LAMP_UPGRADES := ["pavio_algodao", "tanque_latao", "azeite_santissimo"]

const BASE_HEALTH := 3         # hearts with no ex-voto
const BEADS := 4               # rosary beads (conta_terco) to one more bead of breath (HudStatus.BEAD of stamina)

static var money := START_MONEY
static var items := START_ITEMS.duplicate()
static var banked := 0         # money left with Seu Bento (the venda: "Deixar guardado")
static var fuel := LAMP        # s of light left in the lantern
static var lit := true


static func reset() -> void:
	money = START_MONEY; items = START_ITEMS.duplicate(); banked = 0; fuel = LAMP; lit = true


static func count(id: String) -> int:
	return items.get(id, 0)


## Whether you have it (what unlocks a weapon, a door, an offer); "" = nothing asked, always true.
static func has(id: String) -> bool:
	return id == "" or count(id) > 0


## Every tool at once, and the biggest of what holds things: the training room, the Colônia (no way in from the village
## yet) and the tests.
static func give_tools() -> void:
	for id in ItemCatalog.ITEMS:
		if ItemCatalog.tool(id) and not has(id):
			add(id)
	for kind in ROOM:
		if not has(ROOM[kind][0][0]):
			add(ROOM[kind][0][0])


## How many of a kind (ROOM) fit in what he carries.
static func cap(kind: String) -> int:
	for h in ROOM[kind]:
		if has(h[0]):
			return h[1]
	return 0


## How many more of an item he can carry (a lot: nothing limits it).
static func room(id: String) -> int:
	var kind: String = ItemCatalog.item(id).tipo
	if not ROOM.has(kind):
		return 1 << 30
	var held := 0
	for k in items:
		if ItemCatalog.item(k).tipo == kind:
			held += items[k]
	return maxi(0, cap(kind) - held)


static func money_room() -> int:
	return maxi(0, cap("dinheiro") - money)


## Puts n of an item in the bag, as many as fit (`force`: all of them: the bolt off the rail back in the quiver);
## returns how many went in.
static func add(id: String, n := 1, force := false) -> int:
	var k := n if force else mini(n, room(id))
	if k <= 0:
		return 0
	items[id] = count(id) + k
	if ItemCatalog.item(id).tipo == "melhoria":
		_grow(id)
	return k


## Money coming in, as much as fits in the purse; returns how much did.
static func earn(n: int) -> int:
	var k := mini(n, money_room())
	money += k
	return k


## Money given to him (a reward, a sale): what does not fit is left with Seu Bento. The line that says so, or "".
static func receive(n: int) -> String:
	var k := earn(n)
	if k == n:
		return ""
	banked += n - k
	return "Não cabe no bolso: %s ficam guardados com o Seu Bento." % ItemCatalog.price(n - k)


## The lantern's tank (s of light), by its upgrades; INF: it never goes out.
static func fuel_max() -> float:
	if has("azeite_santissimo"):
		return INF
	return LAMP * (1.5 if has("pavio_algodao") else 1.0) * (2.0 if has("tanque_latao") else 1.0)


## The lantern burns delta s while lit; true the moment it runs dry (and goes out).
static func burn(delta: float) -> bool:
	if not lit or is_inf(fuel_max()):
		return false
	fuel = maxf(0.0, fuel - delta)
	if fuel > 0.0:
		return false
	lit = false
	return true


## How the lantern is, in words (the notebook).
static func lamp_state() -> String:
	if is_inf(fuel_max()):
		return "não apaga"
	if fuel <= 0.0:
		return "seca"
	var f := fuel / fuel_max()
	return ("apagada, " if not lit else "") + ("cheia" if f > 0.7 else "pela metade" if f > 0.3 else "no fim")


## His hearts and his breath, from the upgrades carried (../docs/CHAVE_DO_PORTAO.md): every scene's player is made
## with these, so they hold everywhere.
static func health_max() -> int:
	return BASE_HEALTH + count("coracao_exvoto")


static func breath_max() -> float:
	return Player.STAMINA_MAX + HudStatus.BEAD * int(count("conta_terco") / BEADS)


## What an upgrade says when it is taken.
static func upgrade_line(id: String) -> String:
	match id:
		"conta_terco":
			var n := count(id)
			return "O terço ficou mais comprido: mais fôlego." if n % BEADS == 0 else "Conta de terço (%d de %d)" % [n % BEADS, BEADS]
		"pavio_algodao":
			return "Pavio novo: a lamparina dura mais."
		"tanque_latao":
			return "Tanque maior: a lamparina leva o dobro de querosene."
		"azeite_santissimo":
			return "A lamparina não apaga mais."
	return "Um coração a mais."


## An upgrade just taken: the player grows at once (a new heart comes in full, as in Zelda; a lantern's, lit and full).
static func _grow(id: String) -> void:
	if id in LAMP_UPGRADES:
		fuel = fuel_max(); lit = true
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

# Something lying about to take with E: `qtd` of an ItemCatalog item into the Inventory, or money (money()). A tool
# (one of a kind) you already have is not there any more when the scene comes back, nor anything with an `id` once
# taken (Story "pego:<id>"). Its look is whatever the level hangs under it.
class_name Pickup
extends Interactable

var item := ""
var qtd := 1
var id := ""      # one of a kind in the game: once taken, gone for good


static func make(parent: Node, at: Vector3, what: String, n := 1) -> Pickup:
	var p := Pickup.new(); p.item = what; p.qtd = n; p.position = at
	p.prompt = "E · pegar %s" % ItemCatalog.item(what).nome.to_lower()
	parent.add_child(p)
	return p


## Coins in something (`what`: "a lata"): n cruzeiros, found once.
static func money(parent: Node, at: Vector3, n: int, once: String, what: String) -> Pickup:
	var p := Pickup.new(); p.qtd = n; p.id = once; p.position = at; p.prompt = "E · pegar " + what
	parent.add_child(p)
	return p


func _ready() -> void:
	if (item != "" and ItemCatalog.tool(item) and Inventory.has(item)) or (id != "" and Story.has("pego:" + id)):
		queue_free()
		return
	super()


func _use(by: Node3D) -> void:
	if id != "":
		Story.mark("pego:" + id)
	if item == "":
		Inventory.money += qtd
		if by is Player:
			by.notice.emit("Achou: %s" % ItemCatalog.price(qtd))
	else:
		Inventory.add(item, qtd)
		if by is Player:
			by.notice.emit("Pegou: %s%s" % [ItemCatalog.item(item).nome, " (%d)" % qtd if qtd > 1 else ""])
	Audio.play2d(by, "compra", -8.0)
	queue_free()

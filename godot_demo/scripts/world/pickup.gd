# Something lying about to take with E: `qtd` of an ItemCatalog item into the Inventory, or money (money()). A tool
# (one of a kind) you already have is not there any more when the scene comes back, nor anything with an `id` once
# taken (Story "pego:<id>"). Its look is whatever the level hangs under it.
class_name Pickup
extends Interactable

var item := ""
var qtd := 1
var id := ""      # one of a kind in the game: once taken, gone for good


static func make(parent: Node, at: Vector3, what: String, n := 1, once := "") -> Pickup:
	var p := Pickup.new(); p.item = what; p.qtd = n; p.position = at; p.id = once
	p.prompt = "E · pegar %s" % ItemCatalog.item(what).nome.to_lower()
	parent.add_child(p)
	return p


## Coins in something (`what`: "a lata"): n cruzeiros, found once.
static func money(parent: Node, at: Vector3, n: int, once: String, what: String) -> Pickup:
	var p := Pickup.new(); p.qtd = n; p.id = once; p.position = at; p.prompt = "E · pegar " + what
	parent.add_child(p)
	return p


## A rosary bead (conta_terco, an upgrade): small and dark, a faint glint on it for a careful eye. Found once.
static func bead(parent: Node, at: Vector3, once: String) -> Pickup:
	var p := make(parent, at, "conta_terco", 1, once)
	if not is_instance_valid(p) or p.is_queued_for_deletion():
		return p
	var mi := MeshInstance3D.new(); p.add_child(mi); mi.position.y = 0.035
	var s := SphereMesh.new(); s.radius = 0.035; s.height = 0.06; mi.mesh = s
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.22, 0.13, 0.08)
	wood.emission_enabled = true; wood.emission = Color(1.0, 0.75, 0.45); wood.emission_energy_multiplier = 0.35
	s.material = wood
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
			by.notice.emit(Inventory.upgrade_line(item) if ItemCatalog.item(item).tipo == "melhoria"
				else "Pegou: %s%s" % [ItemCatalog.item(item).nome, " (%d)" % qtd if qtd > 1 else ""])
	Audio.play2d(by, "compra", -8.0)
	queue_free()

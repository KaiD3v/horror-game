# Something lying about to take with E: `qtd` of an ItemCatalog item into the Inventory. A tool (one of a kind) you
# already have is not there any more when the scene comes back. Its look is whatever the level hangs under it.
class_name Pickup
extends Interactable

var item := ""
var qtd := 1


static func make(parent: Node, at: Vector3, id: String, n := 1) -> Pickup:
	var p := Pickup.new(); p.item = id; p.qtd = n; p.position = at
	p.prompt = "E · pegar %s" % ItemCatalog.item(id).nome.to_lower()
	parent.add_child(p)
	return p


func _ready() -> void:
	if ItemCatalog.tool(item) and Inventory.has(item):
		queue_free()
		return
	super()


func _use(by: Node3D) -> void:
	Inventory.add(item, qtd)
	if by is Player:
		by.notice.emit("Pegou: %s%s" % [ItemCatalog.item(item).nome, " (%d)" % qtd if qtd > 1 else ""])
	Audio.play2d(by, "compra", -8.0)
	queue_free()

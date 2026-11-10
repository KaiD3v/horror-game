# What makes a villager a seller: Npc adds one when its NpcCatalog entry has "loja". E near them opens their shop.
class_name ShopCounter
extends Interactable

var shop_id := ""
var seller := ""


static func make(npc: Node3D, id: String, who: String) -> ShopCounter:
	var c := ShopCounter.new(); c.shop_id = id; c.seller = who
	c.prompt = "E · comprar com %s" % who
	c.radius = 2.4; c.height = 1.8   # across the counter
	npc.add_child(c)
	return c


func _use(_by: Node3D) -> void:
	var menu: ShopMenu = get_tree().get_first_node_in_group("shop_menu")
	menu.open(shop_id, seller)

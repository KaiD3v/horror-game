# Buying (the rules, no screen: ShopMenu shows it). A shop's offers come from ShopCatalog; what is left of each in
# stock is kept across scenes (static) and comes back with a new game.
class_name Shop

enum Result { OK, NO_MONEY, SOLD_OUT, LOCKED }

static var _sold := {}   # "<shop>/<offer index>" -> how many times it was bought


static func reset() -> void:
	_sold.clear()


static func offers(shop_id: String) -> Array:
	return ShopCatalog.shop(shop_id).itens


## How many more times an offer can be bought (-1: always). A tool you already have: 0.
static func left(shop_id: String, i: int) -> int:
	var o: Dictionary = offers(shop_id)[i]
	if ItemCatalog.tool(o.item) and Inventory.has(o.item):
		return 0
	return -1 if o.estoque < 0 else o.estoque - _sold.get("%s/%d" % [shop_id, i], 0)


static func buy(shop_id: String, i: int) -> Result:
	var o: Dictionary = offers(shop_id)[i]
	if left(shop_id, i) == 0:
		return Result.SOLD_OUT
	if not Inventory.has(o.get("requires", "")):  # bolts with no crossbow to shoot them
		return Result.LOCKED
	if not Inventory.spend(o.preco):
		return Result.NO_MONEY
	Inventory.add(o.item, o.qtd)
	var k := "%s/%d" % [shop_id, i]
	_sold[k] = _sold.get(k, 0) + 1
	return Result.OK

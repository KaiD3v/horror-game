# Every item there is: what it is called, what it says about itself and what it does (`tipo`). Inventory keeps how
# many you have; a shop (ShopCatalog) sells them. A new item = an entry here; a new kind of effect = a `tipo` that
# Inventory.use() knows.
#   tipo "municao"   ammunition, spent by a weapon (virote: one per crossbow reload)
#   tipo "cura"      used with X: heals `cura` points of health
class_name ItemCatalog

const MONEY := "Cr$"   # 1974: cruzeiros
const ITEMS := {
	"virote": {"nome": "Virote", "descricao": "Ponta de ferro para a besta. Um a cada vez que recarrega.", "tipo": "municao"},
	"atadura": {"nome": "Atadura", "descricao": "Pano limpo e iodo. Fecha um ferimento (X).", "tipo": "cura", "cura": 1},
	"garrafada": {"nome": "Garrafada de arnica", "descricao": "Cachaça curtida com arnica e ervas. Fecha dois ferimentos (X).", "tipo": "cura", "cura": 2},
}


static func item(id: String) -> Dictionary:
	return ITEMS[id]


static func price(n: int) -> String:
	return "%s %d" % [MONEY, n]

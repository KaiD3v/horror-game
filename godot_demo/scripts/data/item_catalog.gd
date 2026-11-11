# Every item there is: what it is called, what it says about itself and what it does (`tipo`). Inventory keeps how
# many you have; a shop (ShopCatalog) sells them. A new item = an entry here; a new kind of effect = a `tipo` that
# Inventory.use() knows.
#   tipo "municao"   ammunition, spent by a weapon (virote: one per crossbow reload)
#   tipo "cura"      used with F: heals `cura` points of health
#   tipo "ferramenta" never spent, one of a kind: having it is what unlocks it. The weapons (Player.WEAPON_ITEM),
#                    doors and other Interactables (`requires`), shop offers (`requires`) and enemies (`weak_to`)
#                    ask Inventory.has(id). A new key / tool = an entry here + where it is found. No code.
class_name ItemCatalog

const MONEY := "Cr$"   # 1974: cruzeiros
const ITEMS := {
	"lamparina": {"nome": "Lamparina", "descricao": "Querosene e pavio. A única luz que você leva para a noite.", "tipo": "ferramenta"},
	"facao": {"nome": "Facão", "descricao": "Lâmina de cortar cana. Corta, apara golpes (botão direito).", "tipo": "ferramenta"},
	"besta": {"nome": "Besta", "descricao": "Arma de caça, de longe e em silêncio. Atira virotes.", "tipo": "ferramenta"},
	"virote": {"nome": "Virote", "descricao": "Ponta de ferro para a besta. Um a cada vez que recarrega.", "tipo": "municao"},
	"atadura": {"nome": "Atadura", "descricao": "Pano limpo e iodo. Fecha um ferimento (X).", "tipo": "cura", "cura": 1},
	"garrafada": {"nome": "Garrafada de arnica", "descricao": "Cachaça curtida com arnica e ervas. Fecha dois ferimentos (X).", "tipo": "cura", "cura": 2},
}


static func item(id: String) -> Dictionary:
	return ITEMS[id]


static func tool(id: String) -> bool:
	return ITEMS[id].tipo == "ferramenta"


static func price(n: int) -> String:
	return "%s %d" % [MONEY, n]

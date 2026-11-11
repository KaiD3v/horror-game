# Every item there is: what it is called, what it says about itself and what it does (`tipo`). Inventory keeps how
# many you have; a shop (ShopCatalog) sells them. A new item = an entry here; a new kind of effect = a `tipo` that
# Inventory.use() knows.
#   tipo "municao"   ammunition, spent by a weapon (virote: one per crossbow reload)
#   tipo "cura"      used with F: heals `cura` points of health
#   tipo "ferramenta" never spent, one of a kind: having it is what unlocks it. The weapons (Player.WEAPON_ITEM),
#                    doors and other Interactables (`requires`), shop offers (`requires`) and enemies (`weak_to`)
#                    ask Inventory.has(id). A new tool = an entry here + where it is found. No code.
#                    The tools that open the way: pe_de_cabra (boarded doors), picareta (holes, stone rubble), corda
#                    (down and up wells, holes, high places): a door / rubble / well asks for one with `requires`.
#   tipo "chave"     a key: each opens only its own lock, and is spent on it. A lock (a door, a trunk, any
#                    Interactable) names it in `requires`; the first E with it takes it and the lock stays open for
#                    good (Story "destrancado:<id>"). A new key = an entry "chave_<lock>" here, "modelo": "chave".
# "modelo": the shape held up out of a trunk (models/props/itens.glb), when it is not the id's own.
class_name ItemCatalog

const MONEY := "Cr$"   # 1974: cruzeiros
const ITEMS := {
	"lamparina": {"nome": "Lamparina", "descricao": "Querosene e pavio. A única luz que você leva para a noite.", "tipo": "ferramenta"},
	"facao": {"nome": "Facão", "descricao": "Lâmina de cortar cana. Corta, apara golpes (botão direito).", "tipo": "ferramenta"},
	"besta": {"nome": "Besta", "descricao": "Arma de caça, de longe e em silêncio. Atira virotes.", "tipo": "ferramenta"},
	"virote": {"nome": "Virote", "descricao": "Ponta de ferro para a besta. Um a cada vez que recarrega.", "tipo": "municao"},
	"atadura": {"nome": "Atadura", "descricao": "Pano limpo e iodo. Fecha um ferimento (F).", "tipo": "cura", "cura": 1},
	"garrafada": {"nome": "Garrafada de arnica", "descricao": "Cachaça curtida com arnica e ervas. Fecha dois ferimentos (F).", "tipo": "cura", "cura": 2},
	"pe_de_cabra": {"nome": "Pé de cabra", "descricao": "Ferro dobrado na ponta. Arranca as tábuas pregadas numa porta.", "tipo": "ferramenta"},
	"picareta": {"nome": "Picareta", "descricao": "Cabo de pau e ferro de duas pontas. Cava buracos e quebra entulho de pedra.", "tipo": "ferramenta"},
	"corda": {"nome": "Corda", "descricao": "Sisal trançado, uns vinte metros. Para descer e subir por poços, buracos e barrancos.", "tipo": "ferramenta"},
	"chave_cadeado": {"nome": "Chave do cadeado", "descricao": "Pequena, de latão. Abre o cadeado da porta da sala de treino.", "tipo": "chave", "modelo": "chave"},
	"chave_sacristia": {"nome": "Chave da sacristia", "descricao": "Ferro velho, um barbante vermelho na argola. Abre só a porta da sacristia.", "tipo": "chave", "modelo": "chave"},
}


static func item(id: String) -> Dictionary:
	return ITEMS[id]


static func tool(id: String) -> bool:
	return ITEMS[id].tipo == "ferramenta"


static func key(id: String) -> bool:
	return id != "" and ITEMS[id].tipo == "chave"


static func price(n: int) -> String:
	return "%s %d" % [MONEY, n]

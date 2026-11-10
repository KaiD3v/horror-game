# What each shop sells (ItemCatalog items): how many come in one purchase (`qtd`), for how much (`preco`) and how many
# times it can be bought before it runs out (`estoque`, -1 = always). A shop belongs to whoever has its id in
# NpcCatalog ("loja"): that villager gets "E · comprar". A new shop = an entry here + "loja" on an NPC. No code.
class_name ShopCatalog

const SHOPS := {
	"venda": {"titulo": "Secos e Molhados", "fala": "Leva alguma coisa? Fiado não, que o caderno já está cheio.",
		"itens": [{"item": "atadura", "qtd": 1, "preco": 8, "estoque": 6},
			{"item": "garrafada", "qtd": 1, "preco": 18, "estoque": 2}]},
	"armaria": {"titulo": "Armas e Munição", "fala": "Chumbo não adianta com eles. Ponta de ferro, no peito.",
		"itens": [{"item": "virote", "qtd": 3, "preco": 9, "estoque": -1},
			{"item": "virote", "qtd": 8, "preco": 20, "estoque": 3}]},
}


static func shop(id: String) -> Dictionary:
	return SHOPS[id]

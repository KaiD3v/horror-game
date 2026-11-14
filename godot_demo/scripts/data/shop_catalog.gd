# What each shop sells (ItemCatalog items): how many come in one purchase (`qtd`), for how much (`preco`) and how many
# times it can be bought before it runs out (`estoque`, -1 = always) and what you need to have for it (`requires`,
# optional: bolts only with the crossbow). A shop belongs to whoever has its id in
# NpcCatalog ("loja"): that villager gets "E · comprar". A new shop = an entry here + "loja" on an NPC. No code.
class_name ShopCatalog

const SHOPS := {
	"venda": {"titulo": "Secos e Molhados", "fala": "Leva alguma coisa? Fiado não, que o caderno já está cheio.",
		"itens": [{"item": "atadura", "qtd": 1, "preco": 8, "estoque": 6},
			{"item": "garrafada", "qtd": 1, "preco": 18, "estoque": 2},
			{"item": "querosene", "qtd": 1, "preco": 8, "estoque": 6},   # (the truck has not come since March)
			{"item": "pavio_algodao", "qtd": 1, "preco": 12, "estoque": 1},
			{"item": "porta_niquel", "qtd": 1, "preco": 10, "estoque": 1}]},  # (../docs/MELHORIAS.md)
	"armaria": {"titulo": "Armas e Munição", "fala": "Chumbo não adianta com eles. Ponta de ferro, no peito.",
		"itens": [{"item": "virote", "qtd": 3, "preco": 9, "estoque": -1, "requires": "besta"},
			{"item": "virote", "qtd": 8, "preco": 20, "estoque": 3, "requires": "besta"},
			{"item": "bolsa_cinto", "qtd": 1, "preco": 30, "estoque": 1, "requires": "besta"}]},  # (the crossbow is not for sale: ../docs/TUTORIAL_VILAREJO.md)
	"mascate": {"titulo": "Mascate", "fala": "Tudo que a cidade tem, menos a cidade. Preço de quem tá preso: justo.",
		"itens": [{"item": "corda", "qtd": 1, "preco": 25, "estoque": 1},
			{"item": "atadura", "qtd": 2, "preco": 14, "estoque": 2},
			{"item": "virote", "qtd": 5, "preco": 12, "estoque": 2, "requires": "besta"},
			{"item": "tanque_latao", "qtd": 1, "preco": 30, "estoque": 1}]},  # (../docs/CONTEUDO_VILAREJO.md)
}


static func shop(id: String) -> Dictionary:
	return SHOPS[id]

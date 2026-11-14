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
#   tipo "melhoria"  an upgrade, Zelda style (../docs/CHAVE_DO_PORTAO.md "As melhorias"): one of a kind where it lies,
#                    never given twice. Inventory.health_max / breath_max count them: coracao_exvoto (the story's: a
#                    heart at once), conta_terco (exploration's: every Inventory.BEADS, one more bead of breath); and
#                    Inventory.fuel_max the lantern's (../docs/MELHORIAS.md): pavio_algodao, tanque_latao (sold, once),
#                    azeite_santissimo (it never goes out).
#   tipo "equipamento" carried, never spent: what holds things (Inventory.ROOM: how many bolts, cures, how much money
#                    fit), the leather quiver (quieter running).
#   tipo "combustivel" querosene: fills the lantern when it runs dry (R).
#   tipo "lembranca" something of someone's, carried to be given back (a dialogue takes it: "toma"); does nothing.
#   tipo "chave"     a key: each opens only its own lock, and is spent on it. A lock (a door, a trunk, any
#                    Interactable) names it in `requires`; the first E with it takes it and the lock stays open for
#                    good (Story "destrancado:<id>"). A new key = an entry "chave_<lock>" here, "modelo": "chave".
# "modelo": the shape held up out of a trunk (models/props/itens.glb), when it is not the id's own.
class_name ItemCatalog

const MONEY := "Cr$"   # 1974: cruzeiros
const ITEMS := {
	"lamparina": {"nome": "Lamparina", "descricao": "Querosene e pavio. A única luz que você leva para a noite. Seca e apaga; R apaga, acende, enche.", "tipo": "ferramenta"},
	"querosene": {"nome": "Querosene", "descricao": "Uma garrafa de querosene com rolha de sabugo. Enche a lamparina quando ela seca (R).", "tipo": "combustivel"},
	"facao": {"nome": "Facão", "descricao": "Lâmina de cortar cana. Corta, apara golpes (botão direito).", "tipo": "ferramenta"},
	"besta": {"nome": "Besta", "descricao": "Arma de caça, de longe e em silêncio. Atira virotes.", "tipo": "ferramenta"},
	"virote": {"nome": "Virote", "descricao": "Ponta de ferro para a besta. Um a cada vez que recarrega.", "tipo": "municao"},
	"atadura": {"nome": "Atadura", "descricao": "Pano limpo e iodo. Fecha um ferimento (F).", "tipo": "cura", "cura": 1},
	"garrafada": {"nome": "Garrafada de arnica", "descricao": "Cachaça curtida com arnica e ervas. Fecha dois ferimentos (F).", "tipo": "cura", "cura": 2},
	"pe_de_cabra": {"nome": "Pé de cabra", "descricao": "Ferro dobrado na ponta. Arranca as tábuas pregadas numa porta.", "tipo": "ferramenta"},
	"picareta": {"nome": "Picareta", "descricao": "Cabo de pau e ferro de duas pontas. Cava buracos e quebra entulho de pedra.", "tipo": "ferramenta"},
	"corda": {"nome": "Corda", "descricao": "Sisal trançado, uns vinte metros. Para descer e subir por poços, buracos e barrancos.", "tipo": "ferramenta"},
	"corda_sino": {"nome": "Corda de sino", "descricao": "Sisal grosso de amarrar carga, da venda do Bento. Para o sino da capela, mudo desde a noite da sirene.", "tipo": "chave"},
	"chave_professora": {"nome": "Chave da casa da professora", "descricao": "Pequena, de latão, num cordão de sapato. A Dona Lurdes deixou com a mãe da Cida.", "tipo": "chave", "modelo": "chave"},
	"relogio_bolso": {"nome": "Relógio de bolso", "descricao": "Prata, parado nas quatro e dez. Na tampa, por dentro: \"Ao meu Tonico. Lurdes, 1960.\"", "tipo": "lembranca"},
	"chave_enfermeira": {"nome": "Chave da casa da enfermeira", "descricao": "Uma chave comprida, enferrujada. O Bastião guardou: \"Se eu não descer, queima tudo\", ela disse.", "tipo": "chave", "modelo": "chave"},
	"cobertor": {"nome": "Cobertor de lã", "descricao": "Lã grossa, xadrez, cheirando a fumaça. Era da cama do Zé.", "tipo": "lembranca"},
	"aljava_couro": {"nome": "Aljava de couro", "descricao": "A do Tenório, de couro cru, forrada de feltro: os virotes não batem uns nos outros quando ele corre. Cabem doze.", "tipo": "equipamento"},
	"bolsa_cinto": {"nome": "Bolsa de cinto", "descricao": "Lona de caminhão costurada em três bolsos, presa no cinto. Cabem dezoito virotes.", "tipo": "equipamento"},
	"embornal": {"nome": "Embornal de pano", "descricao": "Saco de algodão cru com alça, costurado pela Firmina. Cabem quatro curativos.", "tipo": "equipamento"},
	"estojo_celina": {"nome": "Estojo da enfermeira", "descricao": "Lata branca, a cruz vermelha descascada; dentro da tampa, a caneta: Celina. Cabem seis curativos.", "tipo": "equipamento"},
	"porta_niquel": {"nome": "Porta-níquel", "descricao": "Couro de fecho de mola, que estala. Cabem Cr$ 120.", "tipo": "equipamento"},
	"capanga": {"nome": "Capanga de couro", "descricao": "Bolsa de couro de pendurar no ombro. Era do pai do Seu Bento. Cabem Cr$ 250.", "tipo": "equipamento"},
	"pavio_algodao": {"nome": "Pavio de algodão trançado", "descricao": "Grosso, trançado à mão. Queima mais devagar: a lamparina dura mais.", "tipo": "melhoria"},
	"tanque_latao": {"nome": "Tanque de latão", "descricao": "Um reservatório maior, soldado no pé da lamparina pelo Seu Dito. Leva o dobro de querosene.", "tipo": "melhoria"},
	"azeite_santissimo": {"nome": "Azeite do Santíssimo", "descricao": "Da lâmpada do sacrário, que a Firmina nunca deixou apagar. Na lamparina, não apaga mais.", "tipo": "melhoria"},
	"chave_motorista": {"nome": "Chave da casa do motorista", "descricao": "Do Seu Abílio, o motorista da Colônia. Ele deixou com o Seu Dito, pra guardar a mercadoria.", "tipo": "chave", "modelo": "chave"},
	"medalha": {"nome": "Medalha de São Cristóvão", "descricao": "Lata dourada, o santo com o Menino nas costas atravessando o rio. Protetor dos motoristas. No verso: \"Abílio\".", "tipo": "lembranca"},
	"escapulario": {"nome": "Escapulário", "descricao": "Dois quadradinhos de pano num cordão, Nossa Senhora do Carmo. No verso, a lápis: Joaquim.", "tipo": "lembranca"},
	"coracao_exvoto": {"nome": "Coração de ex-voto", "descricao": "Lata batida em forma de coração, de quem pagou promessa. Um coração a mais.", "tipo": "melhoria"},
	"conta_terco": {"nome": "Conta de terço", "descricao": "Madeira escura, gasta de tanto rezar. Quatro fazem o terço crescer: mais fôlego.", "tipo": "melhoria"},
	"chave_cadeado": {"nome": "Chave do cadeado", "descricao": "Pequena, de latão. Abre o cadeado da porta da sala de treino.", "tipo": "chave", "modelo": "chave"},
	"chave_sacristia": {"nome": "Chave da sacristia", "descricao": "Ferro velho, um barbante vermelho na argola. Abre só a porta da sacristia.", "tipo": "chave", "modelo": "chave"},
	"chave_portao": {"nome": "Chave do portão", "descricao": "Grande, de ferro, com a argola gasta. Abre o cadeado do portão da Colônia.", "tipo": "chave", "modelo": "chave"},
}


static func item(id: String) -> Dictionary:
	return ITEMS[id]


static func tool(id: String) -> bool:
	return ITEMS[id].tipo == "ferramenta"


static func key(id: String) -> bool:
	return id != "" and ITEMS[id].tipo == "chave"


static func price(n: int) -> String:
	return "%s %d" % [MONEY, n]

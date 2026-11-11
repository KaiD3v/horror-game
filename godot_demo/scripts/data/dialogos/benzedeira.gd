# Dona Firmina, the benzedeira, praying at the cruzeiro before the chapel (Dialog explains the format). Old, bent,
# the rosary never still. Her son Joaquim went up to work at the Colônia in 1972 and never came down; she stays where
# she can see its wall, and keeps the candles lit. She gives the task of the garrafada (QuestData), and with it done
# the key of the sacristy (the way down to the ossuary, ../docs/TUTORIAL_VILAREJO.md).
extends RefCounted

const ENTRADA := [
	{"se": {"sem_marca": "firmina_conheceu"}, "vai": "primeira"},
	{"se": {"noite": true}, "vai": "noite"},
	{"vai": "oi"},
]

const MENU := [
	{"texto": "Perguntar o que se fala por aí", "vai": "rumores"},
	{"texto": "Perguntar sobre ela", "vai": "ela"},
	{"texto": "Perguntar sobre a Colônia", "vai": "colonia"},
	{"texto": "Perguntar se precisa de alguma coisa", "vai": "pedido", "se": {"tarefa": ["garrafada", "nova"]}},
	{"texto": "Falar da garrafada", "vai": "lembrete", "se": {"tarefa": ["garrafada", "ativa"], "nao_tem": "garrafada"}},
	{"texto": "Entregar a garrafada", "vai": "entrega", "se": {"tarefa": ["garrafada", "ativa"], "tem": "garrafada"}},
	{"texto": "Ir embora", "vai": "fim"},
]

const NOS := {
	"primeira": {"faz": [{"marca": "firmina_conheceu"}], "fala": [
		"Ave Maria cheia de graça... Hm? Chega mais perto da vela, que eu não enxergo longe.",
		"Gente de fora. Faz tempo que ninguém sobe essa estrada. A ponte caiu, não caiu? Caiu pra ninguém descer.",
		"Eu sou a Firmina. Benzo cobreiro, quebranto, espinhela caída. Hoje em dia benzo é o vilarejo inteiro.",
	]},
	"oi": {"fala": ["Ainda de pé, menino? Deus seja louvado. Diz o que quer, que a vela não espera."]},
	"noite": {"fala": [
		"Não é hora de prosa. De noite eles descem do morro.",
		"Lá em cima a luz chama. Quando ouvir asas, pendura essa lamparina na cinta.",
		"Fica perto das velas e fala baixo. O que é?",
	]},
	"rumores": {"falas": [
		["Tem uma que anda pelos becos de noite, chorando, com uma vela na mão. Parece gente.",
			"Não deixa ela te ver. Quando ela grita, os outros vêm todos."],
		["O poço do largo secou faz um ano. Mas de noite tem barulho de balde lá dentro.",
			"Pisa macio perto dele. O que mora lá não enxerga, mas ouve até pensamento."],
		["As que ficam nos telhados são mariposa grande. Vão atrás de luz.",
			"Se precisar passar por elas, esconde a lamparina. Mas aí é você que não enxerga nada."],
	]},
	"ela": {"fala": [
		"Quarenta anos benzendo. Benzi metade dessa gente quando era criança. A outra metade eu enterrei.",
		"Meu Joaquim subiu pra trabalhar na Colônia em setenta e dois. Diziam que pagavam bem. Não desceu mais.",
		"Eu fico aqui porque daqui eu vejo o muro. Enquanto tiver vela acesa, ele sabe o caminho de casa.",
	]},
	"colonia": {"fala": [
		"Era hospital de gente doente da cabeça. Depois virou outra coisa. Começaram a levar gente que não tinha nada.",
		"Uma noite a sirene tocou até amanhecer. No outro dia o portão estava fechado com corrente, por dentro.",
		"Quem foi lá ver não voltou. Os que voltaram... não eram mais eles.",
	]},
	"pedido": {"faz": [{"tarefa": ["garrafada", "ativa"]}], "fala": [
		"Preciso, sim. O padre Anselmo guardava uma garrafada de arnica no baú, do lado do altar da capela.",
		"Eu não entro mais lá. Desde que acharam o caixão aberto, aquela porta pesa feito chumbo pra mim.",
		"Me traz a garrafada. Com ela eu fecho o teu corpo antes da noite. Vai precisar.",
	]},
	"lembrete": {"fala": ["A garrafada, menino. No baú do lado do altar. A capela é ali, a porta da torre."]},
	"entrega": {"faz": [{"toma": "garrafada"}, {"cura": true}, {"dinheiro": 20}, {"da": "chave_sacristia"},
			{"tarefa": ["garrafada", "feita"]}], "fala": [
		"Deus te pague. Fica quieto aí... São Bento, água benta, Jesus Cristo no altar...",
		"Pronto. Corpo fechado. Tuas feridas vão parar de doer um pouco.",
		"E leva essas moedas do dízimo. O padre não vai mais precisar delas.",
		"Leva a chave da sacristia também. O padre deixava comigo, que eu limpava a igreja. Eu não desço lá mais.",
	]},
}

# Dona Firmina, the benzedeira, praying at the cruzeiro before the chapel (Dialog explains the format). Old, bent,
# the rosary never still. Her son Joaquim went up to work at the Colônia in 1972 and never came down; she stays where
# she can see its wall, and keeps the candles lit. She gives the task of the garrafada (QuestData), and with it done
# the key of the sacristy (the way down to the ossuary, ../docs/TUTORIAL_VILAREJO.md).
extends RefCounted

const ENTRADA := [
	{"se": {"sem_marca": "firmina_conheceu"}, "vai": "primeira"},
	{"se": {"noite": true}, "vai": "noite"},
	{"se": {"lugar": "cemiterio", "marca": "tumulo:contou"}, "vai": "cemiterio_depois"},
	{"se": {"lugar": "cemiterio"}, "vai": "cemiterio"},
	{"se": {"lugar": "sino"}, "vai": "sino_tocando"},
	{"vai": "oi"},
]

const MENU := [
	{"texto": "Perguntar do túmulo sem nome", "vai": "tumulo", "se": {"marca": "tumulo:visto", "sem_marca": "tumulo:contou"}},
	{"texto": "Perguntar o que desce do portão", "vai": "maes", "se": {"marca": "tumulo:contou", "marca_2": "morto:porteiro", "sem_marca": "procissao:vista"}},
	{"texto": "Contar da procissão", "vai": "procissao", "se": {"marca": "procissao:vista", "sem_marca": "firmina_procissao"}},
	{"texto": "Perguntar o que se fala por aí", "vai": "rumores"},
	{"texto": "Perguntar sobre ela", "vai": "ela"},
	{"texto": "Perguntar sobre a Colônia", "vai": "colonia"},
	{"texto": "Perguntar se precisa de alguma coisa", "vai": "pedido", "se": {"tarefa": ["garrafada", "nova"]}},
	{"texto": "Perguntar pelo sino", "vai": "sino_pedido", "se": {"tarefa": [["garrafada", "feita"], ["sino", "nova"]]}},
	{"texto": "Falar do sino", "vai": "sino_lembrete", "se": {"tarefa": ["sino", "ativa"], "sem_marca": "sino:corda"}},
	{"texto": "Contar do sino", "vai": "sino_feito", "se": {"tarefa": ["sino", "ativa"], "marca": "sino:corda"}},
	{"texto": "Falar da garrafada", "vai": "lembrete", "se": {"tarefa": ["garrafada", "ativa"], "nao_tem": "garrafada"}},
	{"texto": "Entregar a garrafada", "vai": "entrega", "se": {"tarefa": ["garrafada", "ativa"], "tem": "garrafada"}},
	{"texto": "Mostrar o escapulário", "vai": "escapulario", "se": {"tem": "escapulario"}},
	{"texto": "Contar do jazigo", "vai": "severino", "se": {"marca": "morto:porteiro", "sem_marca": "firmina_severino"}},
	{"texto": "Ir embora", "vai": "fim"},
]

const NOS := {
	"primeira": {"faz": [{"marca": "firmina_conheceu"}], "fala": [
		"Ave Maria cheia de graça... Hm? Chega mais perto da vela, que eu não enxergo longe.",
		"Gente de fora. Faz tempo que ninguém sobe essa estrada. A ponte caiu, não caiu? Caiu pra ninguém descer.",
		"Eu sou a Firmina. Benzo cobreiro, quebranto, espinhela caída. Hoje em dia benzo é o vilarejo inteiro.",
	]},
	"oi": {"fala": ["Ainda de pé, menino? Deus seja louvado. Diz o que quer, que a vela não espera."]},
	"sino_pedido": {"faz": [{"tarefa": ["sino", "ativa"]}], "fala": [
		"Ouviu o sino essas noites? Não é ninguém. É o vento batendo o badalo. A corda apodreceu lá em cima.",
		"Desde a noite da sirene ninguém toca o Ângelus. Sem o Ângelus a gente não sabe quando a noite chega. Ela chega igual.",
		"Sobe lá, menino. Corda grossa o Bento tem. A torre se sobe pela portinha, dentro da capela, do lado da porta.",
	]},
	"sino_lembrete": {"fala": ["A corda, menino. O Bento tem. E a torre é pela portinha, do lado da porta da capela."]},
	"sino_feito": {"faz": [{"tarefa": ["sino", "feita"]}], "fala": [
		"Eu ouvi. Deus seja louvado, eu ouvi. Agora quem toca sou eu, às seis e às seis. Mão de velha ainda puxa corda.",
		"Lá de cima se vê tudo, não é? Até a fumaça na ruína do portão.",
		"...Aquela fumaça não é de bicho, menino. Bicho não acende fogo. Tem gente vivendo lá.",
	]},
	"sino_tocando": {"fala": ["Agora não, menino. O Ângelus não espera, e a noite também não."]},
	"tumulo": {"faz": [{"marca": "tumulo:contou"}], "fala": [
		"...Você olhou a cruz. Não tem nome, não é?",
		"Não é o meu Antero. O Antero tá lá em cima, no cemitério da Colônia. Morreu de febre, eu digo. Eu digo isso faz vinte anos.",
		"O Antero era capataz de lá. Pegava quem fugia. O doutor pagava por cabeça, e era com isso que a gente comia.",
		"Esse aqui era um menino. O Antero trouxe ele do rio, frio, e não quis levar pra cima. Eu enterrei sem saber o nome.",
		"Debaixo da cruz tem a caderneta dele. Eu nunca abri. Abre você, que eu já não tenho olho pra isso.",
	]},
	"maes": {"fala": [
		"Desde que o Severino calou, elas descem. Eu vi da janela, uma noite. Uma fila de velas, do portão pro cemitério.",
		"As mães, menino. As de lá de cima. A que chora na viela é uma delas. Vêm atrás dos filhos que a Colônia enterrou.",
		"Se for olhar, vai de noite, depois das nove. Sem luz na mão, abaixado, de longe. Se elas te virem, gritam, e a noite inteira vem.",
	]},
	"procissao": {"faz": [{"marca": "firmina_procissao"}], "fala": [
		"...Benedito. Ela escreveu Benedito?",
		"Vinte anos eu limpei o túmulo de um menino sem nome. E a mãe dele descia o morro toda noite pra procurar.",
		"Vou escrever no livro da igreja. Benedito. Pelo menos isso a gente devolve.",
	]},
	"cemiterio_depois": {"fala": ["Eu limpo o túmulo de um menino que eu não sei o nome. É o que dá pra fazer. Não me olha assim."]},
	"cemiterio": {"falas": [
		["É o meu Antero. Eu limpo, a terra suja de novo. Trinta anos assim, a gente se entende."],
		["De tarde eu venho aqui. De manhã e de noite é da Senhora, no cruzeiro. A tarde é dele."],
	]},
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
	"escapulario": {"faz": [{"toma": "escapulario"}, {"marca": "firmina_escapulario"}], "fala": [
		"Isso... isso é do meu Joaquim. Fui eu que costurei. Onde... embaixo da igreja?",
		"Então ele passou por lá. Então ele estava vivo quando passou por lá.",
		"Deixa comigo. Vou acender mais uma vela. Uma pra ele achar o caminho, e outra pra você.",
	]},
	"severino": {"faz": [{"marca": "firmina_severino"}], "fala": [
		"O Severino... Então era ele batendo lá embaixo. No começo era ele que me trazia notícia do Joaquim.",
		"Depois parou de trazer. Depois parou de descer.",
		"Vou acender uma vela pra ele também. E outra pra você, que vai subir. Deus que te leve e te traga.",
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

# Seu Bento, behind the counter of the venda (Dialog explains the format). Round, nervous, talks to keep the silence
# out; jokes that do not quite land. Keeps the fiado notebook, though nobody is left to pay. Gives the task of the
# alambique (QuestData, ../docs/TUTORIAL_VILAREJO.md "Dungeon 1") and lends the crowbar for it.
extends RefCounted

const ENTRADA := [
	{"se": {"sem_marca": "bento_conheceu"}, "vai": "primeira"},
	{"se": {"noite": true}, "vai": "noite"},
	{"se": {"lugar": "varrendo", "marca": "manha:arranhoes"}, "vai": "manha_arranhoes"},
	{"se": {"lugar": "varrendo"}, "vai": "varrendo"},
	{"se": {"lugar": "almoco"}, "vai": "almoco"},
	{"vai": "oi"},
]

const MENU := [
	{"texto": "Ver o que tem à venda", "faz": [{"loja": "venda"}]},
	{"texto": "Perguntar o que se fala por aí", "vai": "rumores"},
	{"texto": "Perguntar sobre ele", "vai": "ele"},
	{"texto": "Perguntar sobre o caderno de fiado", "vai": "fiado", "se": {"marca": "bento_conheceu"}},
	{"texto": "Perguntar se precisa de alguma coisa", "vai": "pedido", "se": {"tarefa": ["alambique", "nova"]}},
	{"texto": "Pedir uma corda grossa", "vai": "corda", "uma_vez": true,
		"se": {"tarefa": ["sino", "ativa"], "nao_tem": "corda_sino", "sem_marca": "sino:corda"}},
	{"texto": "Perguntar pelo pão", "vai": "pao_pedido", "se": {"tarefa": [["alambique", "feita"], ["pao", "nova"]]}},
	{"texto": "Falar do pão", "vai": "pao_lembrete", "se": {"tarefa": ["pao", "ativa"], "sem_marca": "cida_conheceu"}},
	{"texto": "Contar da menina no forno", "vai": "pao_contou", "se": {"tarefa": ["pao", "ativa"], "marca": "cida_conheceu"}},
	{"texto": "Dizer que foi um gato", "vai": "pao_gato", "se": {"tarefa": ["pao", "ativa"], "marca": "cida_conheceu"}},
	{"texto": "Falar do Juca", "vai": "lembrete", "se": {"tarefa": ["alambique", "ativa"], "nao_tem": "facao"}},
	{"texto": "Contar do alambique", "vai": "noticia", "se": {"tarefa": ["alambique", "ativa"], "tem": "facao"}},
	{"texto": "Ir embora", "vai": "fim"},
]

const NOS := {
	"primeira": {"faz": [{"marca": "bento_conheceu"}], "fala": [
		"Freguês! Nossa Senhora, um freguês! Entra, entra. Cuidado com o degrau, que ele morde.",
		"Bento, às ordens. Secos e molhados, pano, querosene, vela. Vela eu tenho muita. Ninguém compra mais nada.",
	]},
	"oi": {"fala": ["Voltou! Eu sabia. Quer dizer, eu rezei. Dá na mesma. O que vai levar?"]},
	"manha_arranhoes": {"fala": ["Viu a porta lá? Arranhão até a altura de um homem. De noite tava tudo quieto. Quieto demais. Eu varro e não olho."]},
	"varrendo": {"falas": [
		["Bom dia, freguês! Varro a frente todo dia. A poeira não sabe que o vilarejo acabou, e eu não conto pra ela."],
		["Varrer é bom. Quem varre a frente diz pro mundo: aqui ainda tem gente. Vai que o mundo escuta."],
	]},
	"almoco": {"falas": [
		["Senta aí. Pão com mortadela. A mortadela é a última da venda, então você não viu nada."],
		["Meio-dia eu como aqui fora, no banco. Lá dentro o relógio fica me olhando."],
	]},
	"noite": {"fala": ["Fala baixo, fala baixo. De noite eu fecho a janela e finjo que a venda é um armário."]},
	"rumores": {"falas": [
		["A ponte caiu numa noite sem chuva. O Juca jurou que ouviu serra. Serra, de madrugada!",
			"Ninguém sobe, ninguém desce. O caminhão do querosene não vem desde março."],
		["O Zé, filho da Dita, abriu a porta pra mãe dele. A mãe dele que morreu na Colônia em sessenta e nove.",
			"Eu não sei o que entrou. A casa está fechada até hoje. Eu não passo na frente."],
		["Tem noite que eu ouço criança chorando nos becos. Não tem mais criança no vilarejo.",
			"Eu ponho algodão no ouvido. Recomendo. Tenho algodão, aliás."],
	]},
	"ele": {"fala": [
		"Nasci atrás desse balcão, praticamente. Meu pai vendia pra Colônia: pão, lenha, gente pra trabalhar.",
		"Depois que fecharam lá em cima, o vilarejo foi esvaziando. Eu fiquei. Alguém tem que vender vela.",
		"E pra onde eu ia? Com essa barriga eu não desço a ravina nem rolando.",
	]},
	"pedido": {"faz": [{"tarefa": ["alambique", "ativa"]}, {"da": "pe_de_cabra"}], "fala": [
		"Preciso. Preciso de notícia do Juca, do alambique. Ele descia todo sábado com a cachaça. Faz uma semana que não desce.",
		"Foi ele que ouviu serrarem a ponte. Depois disso se trancou lá e pregou a porta do lado. Juca é teimoso.",
		"Leva o pé de cabra. Fica a leste, depois do pasto, a chaminé de tijolo. Se ele estiver bem, diz que eu mandei lembrança.",
	]},
	"lembrete": {"fala": ["O Juca, freguês. A leste, depois do pasto. A porta do lado, a pregada: o pé de cabra resolve."]},
	"noticia": {"faz": [{"dinheiro": 15}, {"tarefa": ["alambique", "feita"]}], "fala": [
		"Não estava? Só a cama e o caderno dele... Nossa Senhora.",
		"Ele dizia que eram de branco. Eu ri dele. Eu ri, freguês.",
		"Toma. É pouco, mas é o que tem. Fica com o pé de cabra também, que aqui ninguém mais vai precisar.",
	]},
	"corda": {"faz": [{"da": "corda_sino"}], "fala": [
		"Corda? Pro sino? Tenho sisal de amarrar carga, desse grosso. Ninguém mais amarra carga nenhuma.",
		"Leva, leva. Fiado eu anoto no nome do santo. Se ele pagar, ótimo.",
	]},
	"pao_pedido": {"faz": [{"tarefa": ["pao", "ativa"]}], "fala": [
		"Freguês, me diz se eu tô ficando louco. Some pão do balaio. Toda noite. Um, dois. Nunca o balaio inteiro.",
		"Bicho não é: bicho leva tudo e derruba o resto. Isso aí tem educação.",
		"Depois da chuva fica pegadinha no barro, nos fundos. Pequena. Eu não fui ver. Vai você, que eu tenho medo do que eu vou achar.",
	]},
	"pao_lembrete": {"fala": ["O pão, freguês. Depois da chuva, nos fundos. A pegadinha no barro."]},
	"pao_contou": {"faz": [{"marca": "cida:contou"}, {"tarefa": ["pao", "feita"]}], "fala": [
		"A filha do Zé? A Cida? Viva? ...No meu forno?",
		"Nossa Senhora. Eu deixava o balaio destampado e fingia que não via. Achei que era a minha cabeça.",
		"A minha Odete subiu em sessenta e oito. Hanseníase, disseram. Mancha na mão. Eu deixei levarem, freguês. Eu deixei.",
		"Essa não sobe. Vou deixar pão de propósito agora, e um cobertor. E pra você, o que levar daqui é mais barato. Não discute.",
	]},
	"pao_gato": {"faz": [{"marca": "cida:segredo"}, {"tarefa": ["pao", "feita"]}], "fala": [
		"Um gato? ...Gato que come pão e deixa pegada de gente.",
		"Tá bom. Foi um gato. Eu vou deixar o balaio destampado pro gato, então. Gato precisa comer.",
	]},
	"fiado": {"fala": [
		"O caderno? Está tudo anotado. O Zé me deve um quilo de sal. A Dita, querosene. O padre, vinho de missa.",
		"Ninguém vai pagar. Eu sei. Mas eu anoto. Enquanto eu anotar, é como se eles ainda fossem voltar.",
	]},
}

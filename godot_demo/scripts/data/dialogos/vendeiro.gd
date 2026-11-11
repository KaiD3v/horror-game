# Seu Bento, behind the counter of the venda (Dialog explains the format). Round, nervous, talks to keep the silence
# out; jokes that do not quite land. Keeps the fiado notebook, though nobody is left to pay.
extends RefCounted

const ENTRADA := [
	{"se": {"sem_marca": "bento_conheceu"}, "vai": "primeira"},
	{"se": {"noite": true}, "vai": "noite"},
	{"vai": "oi"},
]

const MENU := [
	{"texto": "Ver o que tem à venda", "faz": [{"loja": "venda"}]},
	{"texto": "Perguntar o que se fala por aí", "vai": "rumores"},
	{"texto": "Perguntar sobre ele", "vai": "ele"},
	{"texto": "Perguntar sobre o caderno de fiado", "vai": "fiado", "se": {"marca": "bento_conheceu"}},
	{"texto": "Ir embora", "vai": "fim"},
]

const NOS := {
	"primeira": {"faz": [{"marca": "bento_conheceu"}], "fala": [
		"Freguês! Nossa Senhora, um freguês! Entra, entra. Cuidado com o degrau, que ele morde.",
		"Bento, às ordens. Secos e molhados, pano, querosene, vela. Vela eu tenho muita. Ninguém compra mais nada.",
	]},
	"oi": {"fala": ["Voltou! Eu sabia. Quer dizer, eu rezei. Dá na mesma. O que vai levar?"]},
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
	"fiado": {"fala": [
		"O caderno? Está tudo anotado. O Zé me deve um quilo de sal. A Dita, querosene. O padre, vinho de missa.",
		"Ninguém vai pagar. Eu sei. Mas eu anoto. Enquanto eu anotar, é como se eles ainda fossem voltar.",
	]},
}

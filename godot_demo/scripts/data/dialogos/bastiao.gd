# Bastião, the ex-interno (Dialog explains the format; ../docs/CONTEUDO_VILAREJO.md "Bastião, o ex-interno"). Let out
# of the Colônia by the 1962 law, nowhere to go; lives in the ruin by the gate with his fire. Keeps his distance for your
# sake, not his. Knows the Colônia from inside: the children's pavilion, the old water tunnel under the wall, Dalva the
# nurse. Given the Zé's blanket he gives her key. Tenório told of him: he is gone (vilarejo.gd _bastiao).
extends RefCounted

const ENTRADA := [
	{"se": {"sem_marca": "bastiao_conheceu"}, "vai": "primeira"},
	{"se": {"tarefa": ["galinhas", "ativa"], "sem_marca": "bastiao_galinhas"}, "vai": "galinhas"},
	{"vai": "oi"},
]

const MENU := [
	{"texto": "Perguntar da Colônia", "vai": "colonia"},
	{"texto": "Perguntar das crianças", "vai": "criancas", "se": {"marca": "bastiao:colonia"}},
	{"texto": "Perguntar da enfermeira", "vai": "dalva", "se": {"marca": "bastiao:colonia"}},
	{"texto": "Dar o cobertor", "vai": "cobertor", "se": {"tem": "cobertor", "sem_marca": "bastiao:ajudou"}},
	{"texto": "Ir embora", "vai": "fim"},
]

const NOS := {
	"primeira": {"faz": [{"marca": "bastiao_conheceu"}], "fala": [
		"Para aí. Não chega mais perto. ...Não é por mim. É por você. Lá embaixo dizem que pega.",
		"Não sou deles, não. Deles você não ia ver a cara. A minha é feia, mas é de gente.",
		"Bastião. Fui o 0412 da Colônia. Em sessenta e dois a lei abriu o portão. Abriu e pronto. Pra onde eu ia?",
	]},
	"galinhas": {"faz": [{"marca": "bastiao_galinhas"}], "fala": [
		"O Tenório te mandou. ...As galinhas.",
		"Eu pego uma, às vezes. Ele tem vinte. Eu não tenho nada. O frio aqui em cima é que mata, não a fome.",
		"Pode atirar. Ou pode ir embora e dizer que não achou nada. Eu não vou pedir.",
	]},
	"oi": {"falas": [
		["Senta do outro lado do fogo. Assim tá bom."],
		["Ainda vivo? Lá embaixo eles caçam quem acende luz. Eu acendo assim mesmo."],
	]},
	"colonia": {"faz": [{"marca": "bastiao:colonia"}], "fala": [
		"Trinta anos lá dentro. Os pavilhões dos homens, das mulheres, e o das crianças, longe dos dois.",
		"O portão você conhece. Mas tem outro caminho: o túnel velho da água, que passa embaixo do muro e sai na cisterna da vila.",
		"Desabou faz tempo. Com uma picareta, quem sabe.",
	]},
	"criancas": {"fala": [
		"Os filhos dos internos nasciam e iam pro pavilhão das crianças. No mesmo dia. A mãe não pegava no colo.",
		"Diziam pra eles que os pais morreram. E pros pais, que os filhos morreram. Era mais fácil pra todo mundo. Pros doutores.",
		"...Você tem a cara de quem já ouviu isso. Desculpa.",
	]},
	"dalva": {"fala": [
		"A Dalva. A enfermeira. Morava aqui embaixo, na casa vermelha perto do portão, e subia todo dia.",
		"Era boa. Trazia carta escondida. Depois do soro do doutor ela parou de falar. Andava na ponta do pé.",
		"Se você encontrar ela lá em cima... olha pra ela. Ela não gosta de ser esquecida no escuro.",
	]},
	"cobertor": {"faz": [{"marca": "bastiao:ajudou"}, {"toma": "cobertor"}, {"da": "chave_enfermeira"}], "fala": [
		"...Pra mim?",
		"Faz trinta anos que ninguém me dá uma coisa sem jogar de longe.",
		"Toma. A chave da casa da Dalva. Ela me deu antes de subir a última vez: \"Se eu não descer, queima tudo.\" Eu não tive coragem.",
		"Vai você. Lê o que ela deixou. Alguém tem que saber.",
	]},
}

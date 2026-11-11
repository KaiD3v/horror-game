# Tenório, behind the counter of the armaria (Dialog explains the format). An old hunter of the serra, few words, a
# milky eye under the scar a jaguar left him. He has fought the things from the hill and knows what kills them.
extends RefCounted

const ENTRADA := [
	{"se": {"sem_marca": "tenorio_conheceu"}, "vai": "primeira"},
	{"vai": "oi"},
]

const MENU := [
	{"texto": "Ver o que tem à venda", "faz": [{"loja": "armaria"}]},
	{"texto": "Perguntar o que se fala por aí", "vai": "rumores"},
	{"texto": "Perguntar sobre ele", "vai": "ele"},
	{"texto": "Perguntar como se mata aquilo", "vai": "matar"},
	{"texto": "Ir embora", "vai": "fim"},
]

const NOS := {
	"primeira": {"faz": [{"marca": "tenorio_conheceu"}], "fala": [
		"...",
		"Fecha a porta. Não, deixa encostada. Se eu precisar sair correndo, não quero ficar puxando trinco.",
		"Tenório. Armas e munição. Fiado não, que aqui não tem amanhã.",
	]},
	"oi": {"fala": ["Hm. Vivo ainda. O que vai ser?"]},
	"rumores": {"falas": [
		["Bento acha que eu não durmo. Eu durmo. De olho aberto. O bom."],
		["O padre achou o caixão vazio e a terra mexida por dentro. Foi embora no outro dia.",
			"Eu fui no cemitério com a espingarda. Achei pegada descalça. Indo pro morro."],
		["Tem algo andando em cima dos telhados. Leve. Bate as asas que nem mariposa.",
			"Chumbo atravessa e ela nem sente. Ponta de ferro ela sente."],
	]},
	"ele": {"fala": [
		"Cacei onça nessa serra trinta anos. Uma me deixou isso aqui no olho. Foi a última que eu matei.",
		"Vendia cartucho pra gente da Colônia caçar no fim de semana. Os doutores. Atiravam mal.",
		"Fiquei porque alguém tem que vender o que mata eles. E porque não tenho pra onde ir.",
	]},
	"matar": {"fala": [
		"Chumbo não adianta. Eu gastei duas caixas num só. Ele levantou.",
		"Lâmina e ponta de virote. No peito, de perto. A besta é melhor: não faz barulho, não chama os outros.",
		"E se for a comprida, de branco... aquela não anda enquanto a luz estiver nela. Não tira a luz de cima.",
	]},
}

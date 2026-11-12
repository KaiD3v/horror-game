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
	{"texto": "Perguntar por uma besta", "vai": "besta", "se": {"nao_tem": "facao", "tarefa": ["besta", "nova"]}},
	{"texto": "Perguntar por uma besta", "vai": "besta_conta", "se": {"tem": "facao", "nao_tem": "besta", "tarefa": ["besta", "nova"]}},
	{"texto": "Falar da besta", "vai": "besta_lembrete", "se": {"nao_tem": "besta", "tarefa": ["besta", "ativa"]}},
	{"texto": "Mostrar a besta", "vai": "besta_achou", "se": {"tem": "besta", "sem_marca": "tenorio_besta"}},
	{"texto": "Perguntar pela chave do portão", "vai": "chave_lembrete", "se": {"tarefa": ["chave", "ativa"], "nao_tem": "chave_portao"}},
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
		["Quando ela armar o golpe, ergue o facão na frente da cara. Aço aguenta o tranco.",
			"Pela frente. Pelas costas o facão não te salva de nada."],
	]},
	"ele": {"fala": [
		"Cacei onça nessa serra trinta anos. Uma me deixou isso aqui no olho. Foi a última que eu matei.",
		"Vendia cartucho pra gente da Colônia caçar no fim de semana. Os doutores. Atiravam mal.",
		"Fiquei porque alguém tem que vender o que mata eles. E porque não tenho pra onde ir.",
	]},
	"besta": {"fala": [
		"Besta? Tinha uma. Boa, de caçar veado. Não vendo mais.",
		"Ficou lá embaixo, junto com o que eu não quero lembrar.",
		"Arruma uma lâmina primeiro. Sem lâmina você não volta de onde ela está.",
	]},
	"besta_conta": {"faz": [{"tarefa": ["besta", "ativa"]}], "fala": [
		"Facão na cinta. Hm. Então escuta.",
		"Fui atrás do rapaz da Firmina. Entrei pela sacristia, desci no ossuário. Lá embaixo tem uma coisa cega que me ouviu antes de eu ver ela.",
		"Larguei a besta, larguei tudo, e subi pela corda do poço. A besta é tua, se buscar. A chave da sacristia é com a Firmina.",
		"E não corre lá dentro. Osso no chão é sino.",
	]},
	"besta_lembrete": {"fala": ["Sacristia, ossuário, besta. A chave é com a Firmina. E pisa macio, que aquilo ouve."]},
	"besta_achou": {"faz": [{"marca": "tenorio_besta"}, {"tarefa": ["besta", "feita"]}, {"tarefa": ["chave", "ativa"]}], "fala": [
		"Voltou. E com ela. ...Eu não voltei lá, sabe. Nem pra buscar.",
		"Fica. Virote eu vendo, que eu não sou santo. Mira no peito e não erra a primeira, que a segunda demora.",
		"Você quer subir. Eu sei. Então escuta: a chave do portão ficava com o Severino, o porteiro de lá de cima.",
		"Na noite da sirene ele desceu com o molho de chaves na cinta e se trancou no jazigo dos Moura, no fundo do cemitério.",
		"Eu ouço ele lá embaixo, batendo nas paredes. A corrente da grade é velha: o pé de cabra arrebenta. Leva tudo que tiver.",
	]},
	"chave_lembrete": {"fala": ["O jazigo dos Moura, no fundo do cemitério. Leva virote, leva atadura. E não deixa ele te pegar de frente com as duas mãos."]},
	"matar": {"fala": [
		"Chumbo não adianta. Eu gastei duas caixas num só. Ele levantou.",
		"Lâmina e ponta de virote. No peito, de perto. A besta é melhor: não faz barulho, não chama os outros.",
		"E se for a comprida, de branco... aquela não anda enquanto a luz estiver nela. Não tira a luz de cima.",
	]},
}

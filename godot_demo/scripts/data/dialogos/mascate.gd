# Seu Dito, the peddler (Dialog explains the format; ../docs/CONTEUDO_VILAREJO.md "O mascate"). Went village to village
# with his mule selling pans, cloth and thread; got stuck this side when the bridge was sawn. Camps by the ravine; on
# market days (even days) sells on the square. Cheerful the way a man is who has decided not to be afraid in front of
# you. Sells the rope (one), trades the teacher's pocket watch, and wants to go: the log over the ravine (task "tronco").
extends RefCounted

const ENTRADA := [
	{"se": {"sem_marca": "dito_conheceu"}, "vai": "primeira"},
	{"se": {"marca": "tronco:caiu"}, "vai": "vai_embora"},
	{"se": {"lugar": "largo"}, "vai": "largo"},
	{"vai": "oi"},
]

const MENU := [
	{"texto": "Ver o que tem à venda", "faz": [{"loja": "mascate"}]},
	{"texto": "Perguntar da ponte", "vai": "ponte"},
	{"texto": "Perguntar como sair daqui", "vai": "tronco_pedido", "se": {"tarefa": ["tronco", "nova"], "marca": "dito:ponte"}},
	{"texto": "Falar do tronco", "vai": "tronco_lembrete", "se": {"tarefa": ["tronco", "ativa"], "sem_marca": "tronco:caiu"}},
	{"texto": "Mostrar o relógio de bolso", "vai": "relogio_corda", "se": {"tem": "relogio_bolso", "nao_tem": "corda"}},
	{"texto": "Mostrar o relógio de bolso", "vai": "relogio_dinheiro", "se": {"tem": "relogio_bolso", "tem_tambem": "corda"}},
	{"texto": "Ir embora", "vai": "fim"},
]

const NOS := {
	"primeira": {"faz": [{"marca": "dito_conheceu"}], "fala": [
		"Ô de casa! Quer dizer, ô de barraca. Dito, mascate. Panela, linha, fazenda, agulha, remédio de dor de dente.",
		"Subi com a mula pra vender na vila e na Colônia. Na noite que eu cheguei, a ponte caiu. Faz três semanas.",
		"A mula não reclama. Eu reclamo pelos dois.",
	]},
	"oi": {"falas": [
		["Freguês! Hoje tem desconto pra quem ainda tá vivo. Quer dizer, pra todo mundo que aparece."],
		["A mula gostou de você. Ela não gosta de ninguém. Desconfio de você."],
	]},
	"largo": {"fala": ["Dia de feira! Feira de um homem só e uma mula. Chega mais, que de tarde eu volto pra barraca."]},
	"ponte": {"faz": [{"marca": "dito:ponte"}], "fala": [
		"Caiu não. Serraram. Eu ouvi a serra de madrugada, da barraca. Depois um carro preto desceu a estrada sem farol.",
		"Desceu, e não subiu do outro lado. Ouvi o barulho lá embaixo, no fundo da ravina. Ferro e vidro.",
		"Eu não desço lá. Mas se alguém tivesse uma corda boa...",
	]},
	"tronco_pedido": {"faz": [{"tarefa": ["tronco", "ativa"]}], "fala": [
		"Sair? Tem um jeito. Tá vendo do outro lado, aquele tronco em pé? O pessoal da estrada deixou pra fazer a ponte nova.",
		"Tá amarrado lá em cima por uma corda, puxando pra trás. Se a corda arrebentar, ele cai pra cá, atravessado.",
		"Eu e a mula passava por cima. Mas daqui eu não alcanço a corda, e pra atirar eu não tenho nem estilingue.",
	]},
	"tronco_lembrete": {"fala": ["A corda lá no alto do tronco, do outro lado. Um tiro bom e ele cai pra cá."]},
	"vai_embora": {"faz": [{"tarefa": ["tronco", "feita"]}], "fala": [
		"Caiu! Atravessadinho, olha lá. Parece até que foi de propósito.",
		"Amanhã cedo eu passo com a mula. Antes do sol, que é quando eles dormem.",
		"Não precisa vir se despedir. Eu deixo uma coisa pra você na barraca.",
	]},
	"relogio_corda": {"faz": [{"toma": "relogio_bolso"}, {"da": "corda"}, {"dinheiro": 5}], "fala": [
		"Deixa eu ver... Prata. Prata de verdade. \"Ao meu Tonico\". Que bonito.",
		"Isso vale a minha corda e mais um troco. Corda boa, de sisal, vinte metros. Pra descer onde ninguém desce.",
	]},
	"relogio_dinheiro": {"faz": [{"toma": "relogio_bolso"}, {"dinheiro": 25}], "fala": [
		"Prata de verdade. Corda você já tem, então é dinheiro: vinte e cinco. Não conta pro Bento que eu pago melhor.",
	]},
}

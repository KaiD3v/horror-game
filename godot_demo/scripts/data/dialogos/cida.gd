# Cida, the Zé's girl (Dialog explains the format; ../docs/CONTEUDO_VILAREJO.md "Cida, a filha do Zé"). Nine, hidden in
# the clay oven behind the venda since the night the voice called her mother. Talks low and fast, watches the road over
# your shoulder. She knows the one thing that keeps you alive at night: never open to a voice that calls your name.
# The hide-and-seek (vilarejo.gd _cida) starts from here; at its end her map, then the teacher's key.
extends RefCounted

const ENTRADA := [
	{"se": {"sem_marca": "cida_conheceu"}, "vai": "primeira"},
	{"se": {"marca": "cida:mapa", "sem_marca": "cida:chave"}, "vai": "chave"},
	{"se": {"marca": "cida:contou", "sem_marca": "cida:cobertor"}, "vai": "cobertor"},
	{"se": {"marca": "voz:abriu", "sem_marca": "cida:soube_abriu"}, "vai": "abriu"},
	{"se": {"marca": "voz:resistiu", "sem_marca": "voz:abriu", "sem_marca_2": "cida:soube_resistiu"}, "vai": "resistiu"},
	{"vai": "oi"},
]

const MENU := [
	{"texto": "Perguntar da voz", "vai": "voz"},
	{"texto": "Perguntar do pai e da mãe", "vai": "pais"},
	{"texto": "Brincar de esconde-esconde", "vai": "brincar", "se": {"noite": false, "sem_marca": "cida:mapa"}},
	{"texto": "Ir embora", "vai": "fim"},
]

const NOS := {
	"primeira": {"faz": [{"marca": "cida_conheceu"}], "fala": [
		"Não grita. ...Você não é deles, é? Deles a gente não vê. A gente só ouve.",
		"Eu sou a Cida. Filha do Zé. A casa com o sangue na porta.",
		"Eu pego o pão do Seu Bento. Só um. Ele deixa o balaio aberto... acho que ele sabe. Ou é bobo.",
	]},
	"oi": {"falas": [
		["Agachado é melhor. Em pé eles te veem de longe."],
		["Você voltou. Ninguém volta."],
	]},
	"cobertor": {"faz": [{"marca": "cida:cobertor"}], "fala": [
		"O Seu Bento deixou um cobertor no forno. E pão com manteiga. Foi você que contou, né?",
		"...Tá bom. Tá quentinho.",
	]},
	"abriu": {"faz": [{"marca": "cida:soube_abriu"}], "fala": [
		"Você abriu. Eu sei que você abriu. Tá com cheiro deles.",
		"Eu falei. Eu falei pra não abrir. ...Ainda bem que você tá aqui.",
	]},
	"resistiu": {"faz": [{"marca": "cida:soube_resistiu"}], "fala": [
		"Ontem chamaram você, né? Eu ouvi daqui do forno. Você não abriu.",
		"O pai devia ter feito igual.",
	]},
	"voz": {"fala": [
		"De noite eles chamam a gente pelo nome. Com a voz de quem a gente gosta.",
		"Chamaram a mamãe com a voz da vó. A vó morreu lá em cima, faz tempo. O pai sabia. Abriu mesmo assim.",
		"Se alguém te chamar de dentro de uma casa, não abre. Nunca abre. Nem se for a tua mãe.",
	]},
	"pais": {"fala": [
		"Eu tava embaixo da cama. Ouvi o pai abrir a porta. Ouvi a mamãe dizer \"mãe?\". Depois não ouvi mais nada.",
		"De manhã tinha sangue até a estrada. Pra cima. Pro portão.",
		"Eu vou lá buscar eles. Quando eu crescer.",
	]},
	"brincar": {"faz": [{"marca": "cida:esconde"}, {"tarefa": ["esconde", "ativa"]}], "fala": [
		"Esconde-esconde? ...Tá. Mas eu escondo e você procura. Eu digo onde, do meu jeito.",
		"Fecha o olho e conta até vinte. Não roubar!",
	], "opcoes": [{"texto": "Contar até vinte", "vai": "fim"}]},
	"chave": {"faz": [{"marca": "cida:chave"}, {"da": "chave_professora"}], "fala": [
		"Gostou do mapa? Os X é onde eu não vou. Nunca.",
		"Toma. É da casa da Dona Lurdes, a professora. Ela deixou com a mamãe quando foi pela trilha do rio. Não voltou também.",
		"A casa é a azul, lá na entrada da vila. Tem um cadeado. Eu não tenho coragem de entrar sozinha.",
	]},
}

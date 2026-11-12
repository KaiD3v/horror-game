# The notes and documents to find (TODO_ARTE "Interface e apresentação"): where each lies and what it says.
# scene: the scene file's name; at: x and z (it is dropped onto whatever is below `from` m, default 30: under a
# ceiling, start below it); yaw: the turn of the paper; paper: caderno, oficio or ficha (../tools/texturas/notas_papeis.py).
# A new note = a new entry here. NotesReader shows them, NotePaper is the one lying in the world.
class_name NotesData

const NOTES := [
	# what he brings with him (the opening shows them: Abertura; scene "": they lie nowhere)
	{"id": "obito", "scene": "", "at": Vector2.ZERO, "yaw": 0.0, "paper": "oficio",
		"title": "Ofício de óbito (1959)",
		"text": "COLÔNIA SANTA CLARA\nServiço de Profilaxia · Of. 48/59\n\nAo responsável pelo menor nº 112: comunicamos o falecimento da interna nº 0187, sua mãe, em 12/08/1959. Sepultada no cemitério da Colônia. Não há pertences a reclamar.\n\nDr. Euclides Moura, Diretor Clínico"},
	{"id": "foto", "scene": "", "at": Vector2.ZERO, "yaw": 0.0, "paper": "ficha",
		"title": "Foto da mãe (1955)",
		"text": "Foto 3x4, amarelada: ela, de cabelo preso, sem sorrir.\n\nNo verso, a lápis, a mesma letra da carta:\n\nPro meu menino.\nTua mãe, 1955."},
	{"id": "recorte", "scene": "", "at": Vector2.ZERO, "yaw": 0.0, "paper": "oficio",
		"title": "Recorte de jornal (1962)",
		"text": "Recorte de jornal · maio de 1962\n\nFIM DO ISOLAMENTO\nDecreto acaba com a internação obrigatória dos doentes de lepra. As colônias devem liberar os internos.\nNa Colônia Santa Clara, o Dr. Euclides Moura diz que os que ficaram \"não têm para onde ir\"."},
	{"id": "carta_mae", "scene": "", "at": Vector2.ZERO, "yaw": 0.0, "paper": "caderno",
		"title": "Carta da mãe (1974)",
		"text": "Meu filho,\nlembra do parlatório? Eu disse que ia te buscar. Não consegui. A você disseram que eu morri, a mim, que você tinha morrido. Era mentira.\nEstou viva. O doutor não deixa ninguém sair e dá injeção toda semana. O Bento da venda põe esta no correio.\nAgora é você que tem que vir. Antes do fim de março.\ntua mãe"},
	# Cida's map (../tools/texturas/mapa_cida.py): she gives it at the end of the hide-and-seek (vilarejo.gd _cida)
	{"id": "mapa_cida", "scene": "", "at": Vector2.ZERO, "yaw": 0.0, "paper": "mapa_cida", "title": "O mapa da Cida", "text": ""},
	# the nurse's house (../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"): her letters on the table, never sent
	{"id": "cartas_dalva", "scene": "enfermeira", "at": Vector2(0.45, -1.95), "yaw": -15.0, "from": 1.5, "paper": "caderno",
		"title": "Cartas da Dalva à mãe (1974)",
		"text": "Mãe,\no pavilhão das crianças agora são quarenta. Elas perguntam pelos pais, e o doutor manda dizer que os pais morreram. Os pais estão no pavilhão do lado.\n\nMãe,\no doutor começou o soro. Diz que tira a doença do sangue. Eu aplico de noite. Eles não dormem mais.\n\nMãe,\nhoje eu tomei também. Pra ver. Não conta pra ninguém. Não vou mais poder escrever direito, a mão já não para."},
	# Dona Lurdes's house (../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"): on her desk
	{"id": "diario_classe", "scene": "professora", "at": Vector2(0.65, -1.95), "yaw": 10.0, "from": 1.5, "paper": "caderno",
		"title": "Diário de classe (1974)",
		"text": "3ª série · Escola Isolada da Vila de Santa Clara\n\nRosinha ........ presente\nJoãozinho ...... subiu\nTiãozinho ...... subiu\nMaria do Carmo . subiu\nCida ........... presente\nZezinho ........ subiu\n\nSubiram em março, com os pais, \"para o tratamento\". Ninguém escreveu de lá.\nQuem desce agora não é mais criança.\n— L."},
	{"id": "mala", "scene": "vilarejo", "at": Vector2(2.5, 41.8), "yaw": 30.0, "paper": "caderno",
		"title": "Bilhete na mala",
		"text": "Lurdes,\na ponte caiu. Caiu de noite, sem chuva, sem nada. O Juca jura que ouviu serrarem as vigas.\nVou pela trilha do rio. Se eu não voltar até domingo, não vem atrás. Fica na venda com o Bento, de porta trancada.\nDeixei a boneca da menina. Pesa demais para carregar.\n— Tonho"},
	{"id": "escola", "scene": "vilarejo", "at": Vector2(-11.95, 37.4), "yaw": -20.0, "paper": "caderno",  # on the ruin's store
		"title": "Caderno escolar",
		"text": "Rosinha · 3ª série · 1973
Lição: escreva sobre o seu pai.
Meu pai trabalha na Colônia, na lavanderia. Ele diz que lá em cima ninguém sobe sem ser chamado.
De noite, quando o sino toca, ele fecha a janela e reza.
(a professora riscou: \"Não escreva isso.\")"},
	{"id": "casa_04", "scene": "vilarejo", "at": Vector2(6.0, 14.2), "yaw": -70.0, "paper": "caderno",
		"title": "Folha de diário",
		"text": "14 de março\nBateram na porta de novo. Três batidas, depois arrastam alguma coisa. O Zé jura que é a mãe dele, que morreu na Colônia em 69.\nPregamos as janelas. Ele chora e pede para abrir.\n\n15 de março\nO Zé abriu."},
	{"id": "portao", "scene": "vilarejo", "at": Vector2(-1.7, -58.4), "yaw": 10.0, "paper": "oficio",
		"title": "Ofício da Colônia",
		"text": "COLÔNIA SANTA CLARA\nServiço de Profilaxia\nOfício nº 117/74\n\nAos moradores da Vila:\nOs internos remanescentes estão sob tratamento e não oferecem risco.\nFica PROIBIDA a subida ao portão depois das 18 horas.\nQuem tem parente internado aguarde comunicação. Não insistam.\n\nDr. Euclides Moura\nDiretor Clínico"},
	{"id": "juca", "scene": "alambique", "from": 7.5, "at": Vector2(6.3, 2.5), "yaw": 25.0, "paper": "caderno",  # on his cot
		"title": "Diário do Juca",
		"text": "9 de março. Serraram a ponte de noite. Eu vi do morro: eram de branco, com serrote de carpinteiro, e subiram pra Colônia.
12. Preguei a porta do lado e escorei a da frente com a cana.
14. Tem coisa no telhado. Os morcegos não param quietos.
15. Bateram três vezes. Não vou abrir."},
	{"id": "ze", "scene": "casa_ze", "from": 2.4, "at": Vector2(-0.3, -0.25), "yaw": 15.0, "paper": "caderno",  # on his table
		"title": "Bilhete do Zé",
		"text": "Mãe,\nse for a senhora mesmo, diz o meu apelido.\nA Colônia mandou dizer que a senhora morreu em 69. Eu enterrei um caixão fechado.\nEla disse. Disse certinho: Zezinho.\nVou abrir."},
	{"id": "fiado", "scene": "venda", "from": 2.2, "at": Vector2(-3.0, 1.6), "yaw": 15.0, "paper": "caderno",
		"title": "Caderno de fiado",
		"text": "Fiado · março\nFirmina: querosene, vela, fumo. (levaram o filho)\nTonho: arroz, sal, 2 lt. querosene. Foi embora?\nZé da Rita: não volta.\nColônia: 20 lt. querosene, 3 cx. vela, algodão. Pago em dinheiro, de noite.\nA moça de branco que veio buscar não abriu a boca. Tinha a boca costurada, juro por Deus."},
	{"id": "tenorio", "scene": "armaria", "from": 2.2, "at": Vector2(1.4, -0.75), "yaw": -8.0, "paper": "caderno",
		"title": "Recado do Tenório",
		"text": "Quem achar isto:\no bicho da serra não cai com chumbo. Gastei duas caixas num só. Só lâmina e ponta de virote, no peito.\nA comprida, de branco, é outra coisa. Ela não anda enquanto a gente olha. Não tire a luz de cima dela. Não dê as costas.\nFui atrás do rapaz da Firmina.\n— T."},
	{"id": "padre", "scene": "capela", "from": 2.2, "at": Vector2(0.6, -5.6), "yaw": 4.0, "paper": "oficio",
		"title": "Carta do padre",
		"text": "Excelência,\nencomendei a alma de Maria das Dores na quinta. Na sexta de manhã o caixão estava aberto e vazio, e a terra do cemitério remexida por dentro.\nHá três semanas o sino da Colônia toca à meia-noite, e eles descem.\nPeço que mande alguém. Eu não subo mais.\n\nPe. Anselmo"},
	{"id": "ficha", "scene": "colonia", "from": 2.2, "at": Vector2(15.4, 9.0), "yaw": 12.0, "paper": "ficha",
		"title": "Ficha de paciente",
		"text": "FICHA Nº 0231\nPavilhão B\nNome: Celina A.\nEnfermeira-chefe\nAdmissão: voluntária, 02/1973\nTratamento: soro R-4, 12 doses\nObs.: perdeu a fala na 5ª dose (boca suturada por ordem do Dr. Moura). Fotofobia severa: a luz a paralisa. Manter o corredor escuro.\nSem família."},
]


static func note(id: String) -> Dictionary:
	for n in NOTES:
		if n.id == id:
			return n
	return {}


static func in_scene(scene: String) -> Array:
	return NOTES.filter(func(n): return n.scene == scene)

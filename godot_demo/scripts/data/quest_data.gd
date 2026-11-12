# The tasks people give you (Story keeps where each stands). A dialogue starts one ({"tarefa": [id, "ativa"]}) and ends it
# ({"tarefa": [id, "feita"]}); the HUD says so with its title. A new task = an entry here + the lines that give it.
class_name QuestData

const QUESTS := {
	"colonia": {"titulo": "Subir à Colônia",
		"descricao": "A carta da mãe veio lá de cima. O portão da Colônia fica no alto da estrada, depois da vila."},
	"alambique": {"titulo": "O alambique do Juca",
		"descricao": "Seu Bento quer saber do Juca, que não desce do alambique faz uma semana. Fica a leste da vila, depois do pasto. A porta do lado está pregada: ele emprestou o pé de cabra."},
	"besta": {"titulo": "A besta do Tenório",
		"descricao": "O Tenório largou a besta no ossuário, embaixo da capela. Desce pela sacristia (a chave é com a Dona Firmina). Lá embaixo tem uma coisa cega que ouve tudo: não correr."},
	"chave": {"titulo": "A chave do portão",
		"descricao": "O Severino, porteiro da Colônia, desceu com o molho de chaves e se trancou no jazigo dos Moura, no fundo do cemitério. A corrente da grade está podre: o pé de cabra arrebenta. Leva tudo que tiver."},
	"garrafada": {"titulo": "A garrafada do altar",
		"descricao": "Dona Firmina quer a garrafada que o padre guardava no baú ao lado do altar da capela."},
}


static func title(id: String) -> String:
	return QUESTS[id].titulo

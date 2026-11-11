# The tasks people give you (Story keeps where each stands). A dialogue starts one ({"tarefa": [id, "ativa"]}) and ends it
# ({"tarefa": [id, "feita"]}); the HUD says so with its title. A new task = an entry here + the lines that give it.
class_name QuestData

const QUESTS := {
	"garrafada": {"titulo": "A garrafada do altar",
		"descricao": "Dona Firmina quer a garrafada que o padre guardava no baú ao lado do altar da capela."},
}


static func title(id: String) -> String:
	return QUESTS[id].titulo

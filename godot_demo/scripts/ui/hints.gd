# Situational lines (../docs/TUTORIAL_VILAREJO.md): the key for something the moment the world asks for it, on the
# HUD's prompt line (under whatever E would use, which comes first), until he has done it TIMES times; then never
# again (Story "aprendeu:<acao>"). No box, no pause. A new one = an entry in TEXT, a want() where it is needed and a
# did() where he does it.
class_name Hints

const TIMES := 2
const TEXT := {
	"bloquear": "Botão direito · bloquear",     # a blow coming, the machete out (Enemy.go)
	"lamparina": "3 · pendurar a lamparina",    # the light called something (Bruxa)
	"mirar": "Botão direito · mirar",           # the crossbow out, not aimed (Player)
	"curativo": "F · curativo",                 # hurt, with something to dress it (Player)
	"agachar": "C · agachar",                   # a low way through (the level places it)
}


static func learned(action: String) -> bool:
	return Story.count("aprendeu:" + action) >= TIMES


## Show the line for `seconds` (called every frame, it stays up while the need lasts).
static func want(from: Node, action: String, seconds := 0.2) -> void:
	if learned(action) or not from.is_inside_tree():
		return
	var l := from.get_tree().get_first_node_in_group("level")
	if l is Level and l.hud:
		l.hud.hint(action, seconds)


static func did(action: String) -> void:
	Story.bump("aprendeu:" + action)

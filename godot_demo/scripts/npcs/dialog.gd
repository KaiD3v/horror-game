# One conversation with a villager: the rules, no screen (DialogBox shows it). What each one says lives in a file of its
# own, res://scripts/data/dialogos/<who>.gd (the NpcCatalog id), with three constants:
#   ENTRADA  where the talk starts: [{"se": condition, "vai": node}, ...], the first whose condition holds
#   NOS      the nodes: {id: {"fala": [page, ...] | "falas": [[pages], [pages]...] (told in turn, one each time),
#                             "faz": [actions on arriving], "opcoes": [options] (default: MENU)}}
#   MENU     the options most nodes come back to (the "hub": shop, rumours, about them, leave)
# An option: {"texto": "...", "vai": node | "fim" (closes) | "" (stays), "se": condition, "faz": [actions],
#             "uma_vez": true (gone once picked)}.
# A condition (every key must hold): "tem" / "nao_tem": an item; "marca" / "sem_marca": a Story mark;
#   "tarefa": [id, "nova" | "ativa" | "feita"] (or a list of them, all); "noite": true / false (WorldTime); "lugar": where their routine has
#   them now (NpcCatalog "rotina": "varrendo", "almoco", "portao", "varanda", "cemiterio", "cruzeiro").
# An action: "marca": name; "loja": shop id (the shop opens over the talk); "da" / "toma": item (+ "qtd");
#   "dinheiro": n; "cura": true (his wounds closed); "tarefa": [id, state] (the HUD tells it).
# A villager with no file still talks: a greeting, their shop if they have one, and goodbye.
class_name Dialog
extends RefCounted

const DIR := "res://scripts/data/dialogos/%s.gd"
const END := "fim"

var who := ""
var nome := ""
var player: Player
var entry: Array = []
var nodes := {}
var menu: Array = []
var at := ""                       # the node being said
var pages: Array = []
var page := 0


func _init(who_: String, p: Player) -> void:
	who = who_; player = p
	var info := NpcCatalog.info(who)
	nome = info.get("nome", who)
	if ResourceLoader.exists(DIR % who):
		var c: Dictionary = (load(DIR % who) as GDScript).get_script_constant_map()
		entry = c.ENTRADA; nodes = c.NOS; menu = c.MENU
	else:
		entry = [{"vai": "oi"}]; nodes = {"oi": {"fala": ["Pois não?"]}}
		menu = ([{"texto": "Ver o que tem à venda", "faz": [{"loja": info.loja}]}] if info.has("loja") else []) \
			+ [{"texto": "Ir embora", "vai": END}]


## Where the talk starts (ENTRADA).
func begin() -> void:
	enter(pick_start())


func pick_start() -> String:
	for e: Dictionary in entry:
		if holds(e.get("se", {})):
			return e.vai
	return ""


func enter(id: String) -> void:
	at = id
	var n: Dictionary = nodes[id]
	if n.has("falas"):  # told in turn, a different one each time
		var k := "falas:%s:%s" % [who, id]
		pages = n.falas[Story.count(k) % n.falas.size()]; Story.bump(k)
	else:
		pages = n.get("fala", [])
	page = 0
	_do(n.get("faz", []))


func line() -> String:
	return pages[page] if page < pages.size() else ""


## More pages to this speech before the options.
func more() -> bool:
	return page < pages.size() - 1


func next_page() -> void:
	page += 1


## The options on offer here and now.
func options() -> Array:
	return (nodes[at].get("opcoes", menu) as Array).filter(func(o: Dictionary):
		return holds(o.get("se", {})) and not (o.get("uma_vez", false) and Story.has(_once(o))))


## Picks an option: does what it says and goes where it leads. Returns what the screen must do: "" carry on,
## END close, "loja:<id>" open that shop.
func pick(o: Dictionary) -> String:
	if o.get("uma_vez", false):
		Story.mark(_once(o))
	var ui := _do(o.get("faz", []))
	var to: String = o.get("vai", "")
	if to == END:
		return END
	if to != "":
		enter(to)
	return ui


func _once(o: Dictionary) -> String:
	return "opcao:%s:%s" % [who, o.texto]


func holds(c: Dictionary) -> bool:
	for k in c:
		var v = c[k]
		var ok: bool
		match k:
			"tem", "tem_tambem": ok = Inventory.has(v)
			"nao_tem": ok = not Inventory.has(v)
			"marca": ok = Story.has(v)
			"sem_marca", "sem_marca_2": ok = not Story.has(v)
			"tarefa": ok = (v as Array).all(func(t): return Story.task(t[0]) == t[1]) if v[0] is Array else Story.task(v[0]) == v[1]
			"noite": ok = WorldTime.is_night() == v
			"lugar": ok = NpcCatalog.slot(who).get("lugar", "") == v
			_: push_error("Dialog %s: unknown condition %s" % [who, k]); ok = false
		if not ok:
			return false
	return true


func _do(actions: Array) -> String:
	var ui := ""
	for a: Dictionary in actions:
		for k in a:
			match k:
				"marca": Story.mark(a.marca)
				"loja": ui = "loja:" + a.loja
				"jogo": ui = "jogo:" + a.jogo
				"da": Inventory.add(a.da, a.get("qtd", 1))
				"toma": Inventory.take(a.toma, a.get("qtd", 1))
				"dinheiro": Inventory.money += a.dinheiro
				"cura": player.heal(player.max_health)
				"tarefa":
					Story.set_task(a.tarefa[0], a.tarefa[1])
					player.notice.emit(("Nova tarefa: %s" if a.tarefa[1] == "ativa" else "Tarefa cumprida: %s")
						% QuestData.title(a.tarefa[0]))
				"qtd": pass
				_: push_error("Dialog %s: unknown action %s" % [who, k])
	return ui

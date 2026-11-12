# The villagers (../tools/personagens/npcs -> res://models/characters/npc_<who>.glb). A level spawns one on each
# npc_<who> marker its GLB carries (Level.spawn_npcs). What makes one different from another is data:
#   nome, papel           who they are (docs/VILAREJO.md)
#   raio, altura          their collision capsule (default 0.35 x 1.7 m)
#   luz {at, cor, energia, alcance[, fica]}   a light they carry or stand by (local to them, +z = their front); fica:
#                         it stays where they first stood (Firmina's candles) when they walk off
#   som {nome, at, db, size, far}     a loop they make (res://sounds/<nome>.wav)
#   loja                  a ShopCatalog id: they sell ("Ver o que tem à venda" when you talk to them)
#   passo                 how far their Walk carries them a second at speed 1 (m/s: npc_kit.py prints the stride)
#   casa                  the scene of their npc_<who> marker (where the routine puts them when it says nothing else)
#   rotina                their day (../docs/CONTEUDO_VILAREJO.md "As rotinas"), slots by the hour they start at:
#                           de     the hour
#                           cena   the scene they are in (casa)
#                           em     a node of that scene's model (npc_<who>), or pos: a point (its y from the ground)
#                           off    an offset in that node's frame; rumo: a turn (added to the node's)
#                           faz    their animation (Idle); lugar: what Dialog's "lugar" condition reads
#                           leva   a prop in hand or by them (vassoura, lamparina)
#                           se     only with this Story mark (sem: only without it)
#                         A level puts each one where their slot is when it opens; when the hour moves on they walk
#                         there, or out by the door to another scene, or in by it (Level._routine, Npc.go).
# What they say: scripts/data/dialogos/<who>.gd (Dialog). With none they still greet you, sell and say goodbye.
# A new NPC = its model (one file in tools/personagens/npcs/) + an entry here + a marker in a level (+ their lines).
class_name NpcCatalog

const DEFAULT := {"raio": 0.35, "altura": 1.7, "passo": 1.0}
const NPCS := {
	"vendeiro": {"nome": "Seu Bento", "papel": "vende itens, atrás do balcão da venda", "loja": "venda",
		"passo": 1.07, "casa": "venda", "rotina": [
			{"de": 0},                                     # behind the counter (at night the door is shut: Door.shut)
			{"de": 6, "cena": "vilarejo", "em": "porta_venda", "off": Vector3(1.4, 0, 1.4), "rumo": 0.5,
				"faz": "Sweep", "lugar": "varrendo", "leva": "vassoura"},  # opening up: sweeping the front
			{"de": 9},
			{"de": 12, "cena": "vilarejo", "em": "banco_01", "off": Vector3(0.2, 0, -0.05), "faz": "Sit", "lugar": "almoco"},
			{"de": 13}]},                                  # (lunch on the square's bench, then back in)
	"armeiro": {"nome": "Tenório", "papel": "vende armas, atrás do balcão da armaria", "loja": "armaria",
		"passo": 1.17, "casa": "armaria", "rotina": [
			{"de": 0},
			{"de": 6, "cena": "vilarejo", "em": "portao_colonia", "off": Vector3(0.9, 0, 6.0), "rumo": PI,
				"faz": "LookUp", "lugar": "portao"},        # at the Colônia's gate at dawn, looking up (why: a later task)
			{"de": 8},
			{"de": 14, "cena": "vilarejo", "pos": Vector3(26.0, 0, -17.8), "rumo": PI, "lugar": "garrafas"},  # out back: bottles
			{"de": 17},
			{"de": 18, "cena": "vilarejo", "em": "porta_armaria", "off": Vector3(1.4, 0, -1.7), "lugar": "varanda",
				"leva": "lamparina"},                      # on his porch at nightfall, his lamp lit
			{"de": 21}]},                                  # in, and the door shut (Door.shut)
	"benzedeira": {"nome": "Dona Firmina", "papel": "benzedeira, dá tarefas, no cruzeiro em frente à capela",
		"passo": 0.97, "casa": "vilarejo", "rotina": [
			{"de": 0, "faz": "Kneel", "lugar": "cruzeiro"},  # on her knees at the cross all night
			{"de": 6, "sem": "sino:corda"},
			{"de": 6, "cena": "capela", "em": "corda_sino", "faz": "Pull", "lugar": "sino", "se": "sino:corda"},  # the Angelus
			{"de": 6.75},
			{"de": 14, "pos": Vector3(-27.0, 0, -5.8), "rumo": -PI / 2, "faz": "Kneel", "lugar": "cemiterio"},  # her husband's grave
			{"de": 16},
			{"de": 18, "faz": "Kneel", "lugar": "cruzeiro", "sem": "sino:corda"},
			{"de": 18, "cena": "capela", "em": "corda_sino", "faz": "Pull", "lugar": "sino", "se": "sino:corda"},
			{"de": 18.75, "faz": "Kneel", "lugar": "cruzeiro"}],
		"luz": {"at": Vector3(0, 0.35, 0.5), "cor": Color(1.0, 0.68, 0.35), "energia": 1.3, "alcance": 4.5, "fica": true},  # candles at her feet
		"som": {"nome": "reza", "at": Vector3(0, 1.3, 0), "db": -6.0, "size": 1.2, "far": 9.0}},  # praying under her breath
	"bastiao": {"nome": "Bastião", "papel": "ex-interno da Colônia, na ruína do portão (vilarejo.gd _bastiao)",
		"passo": 0.95},
	"cida": {"nome": "Cida", "papel": "a filha do Zé, escondida no forno atrás da venda (vilarejo.gd _cida)",
		"raio": 0.22, "altura": 1.15, "passo": 0.71},
}


static func info(who: String) -> Dictionary:
	var d := DEFAULT.duplicate()
	d.merge(NPCS.get(who, {}), true)
	return d


## Where `who` is at `hour` by their routine: the slot with its blanks filled, and "i" its index ({} with no routine).
static func slot(who: String, hour := WorldTime.hour()) -> Dictionary:
	var d := info(who)
	var r: Array = d.get("rotina", [])
	if r.is_empty():
		return {}
	var i := r.size() - 1
	while i > 0 and (r[i].de > hour or (r[i].has("se") and not Story.has(r[i].se)) or (r[i].has("sem") and Story.has(r[i].sem))):
		i -= 1
	var s := {"cena": d.get("casa", ""), "em": "npc_" + who, "off": Vector3.ZERO, "rumo": 0.0, "faz": "Idle", "lugar": "",
		"leva": ""}
	s.merge(r[i], true); s.i = i
	return s

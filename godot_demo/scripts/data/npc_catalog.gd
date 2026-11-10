# The villagers (../tools/personagens/npcs -> res://models/characters/npc_<who>.glb). A level spawns one on each
# npc_<who> marker its GLB carries (Level.spawn_npcs). What makes one different from another is data:
#   nome, papel           who they are (docs/VILAREJO.md)
#   raio, altura          their collision capsule (default 0.35 x 1.7 m)
#   luz {at, cor, energia, alcance}   a light they carry or stand by (local to them, +z = their front)
#   som {nome, at, db, size, far}     a loop they make (res://sounds/<nome>.wav)
# A new NPC = its model (one file in tools/personagens/npcs/) + an entry here + a marker in a level.
class_name NpcCatalog

const DEFAULT := {"raio": 0.35, "altura": 1.7}
const NPCS := {
	"vendeiro": {"nome": "Seu Bento", "papel": "vende itens, atrás do balcão da venda"},
	"armeiro": {"nome": "Tenório", "papel": "vende armas, atrás do balcão da armaria"},
	"benzedeira": {"nome": "Dona Firmina", "papel": "dá a missão, no cruzeiro em frente à capela",
		"luz": {"at": Vector3(0, 0.35, 0.5), "cor": Color(1.0, 0.68, 0.35), "energia": 1.3, "alcance": 4.5},  # candles at her feet
		"som": {"nome": "reza", "at": Vector3(0, 1.3, 0), "db": -6.0, "size": 1.2, "far": 9.0}},  # praying under her breath
}


static func info(who: String) -> Dictionary:
	var d := DEFAULT.duplicate()
	d.merge(NPCS.get(who, {}), true)
	return d

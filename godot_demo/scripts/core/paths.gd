# Every res:// path the game loads, in one place: scenes, models, sounds, textures, shaders, UI.
class_name Paths

const MENU := "res://scenes/menu.tscn"
const ABERTURA := "res://scenes/abertura.tscn"      # the opening, before the village (Abertura)
const VILAREJO := "res://scenes/levels/vilarejo.tscn"
const COLONIA := "res://scenes/levels/colonia.tscn"
const TREINO := "res://scenes/levels/treino.tscn"
const INTERIOR := "res://scenes/interiors/%s.tscn"   # % armaria, venda, capela

const CHARACTER := "res://models/characters/%s.glb"  # % protagonista, monster, enfermeira, npc_<who>
const LEVEL_MODEL := "res://models/levels/%s.glb"    # % vilarejo, armaria, venda, capela
const PROP := "res://models/props/%s.glb"            # % bau, itens (../tools/cenarios/bau_build.py)
const SOUND := "res://sounds/%s.wav"
const MUSIC := "res://music/%s.mp3"                 # % abertura (ElevenLabs Music, as generated: Audio.music)
const TEXTURE := "res://textures/%s.png"
const SHADER := "res://shaders/%s.gdshader"
const UI := "res://ui/%s"
const TESTS := "res://tests/test_%s.gd"              # % the scene's file name
const CAPTURES := "res://captures"


static func interior(name: String) -> String:
	return INTERIOR % name


static func character(name: String) -> String:
	return CHARACTER % name


static func shader(name: String) -> Shader:
	return load(SHADER % name)

# How the protagonist's body shows its state, with no bars (TODO_ARTE "Jogador ferido", "Stamina e vida"):
#   wound  blood spreads over his clothes and skin (shaders/sangue.gdshader), eased towards 1 - health/max;
#          at a third of his health he breathes hard (respiracao)
#   tired  from 60 % stamina down he pants (ofego), hard once winded
# Hud reads wound and tired for the screen's edges (visao.gdshader).
class_name PlayerCondition
extends Node

const BLOODY := ["coat", "coat_dark", "skin_neck", "scarf", "pants", "patch", "bandage", "skin_hand", "skin", "face",
	"hair", "leather", "boot"]   # the surfaces the blood shows on
const BLEED := 0.25          # wound per second while a new stain spreads (a hit = 1/3: ~1.3 s)
const BREATH_FADE := 0.5     # breathing fades in/out over 2 s
const PANT_FROM := 0.6       # stamina fraction where the panting starts

var player: Player
var wound := 0.0
var tired := 0.0
var blood: ShaderMaterial
var breath: AudioStreamPlayer
var pant: AudioStreamPlayer
var _breath_amp := 0.0


func _init(p: Player) -> void:
	player = p


func _ready() -> void:
	_bloody(Nodes.find_first(player.model, "MeshInstance3D"))
	breath = Audio.loop_player(self, "respiracao"); pant = Audio.loop_player(self, "ofego")


## The stains follow the skinning, so the shader needs each vertex's rest position: the mesh is rebuilt with it in
## CUSTOM0, and the blood pass goes over the BLOODY surfaces.
func _bloody(mi: MeshInstance3D) -> void:
	var src: ArrayMesh = mi.mesh
	var dst := ArrayMesh.new()
	blood = ShaderMaterial.new(); blood.shader = Paths.shader("sangue")
	for i in src.get_surface_count():
		var a := src.surface_get_arrays(i)
		var rest := PackedFloat32Array()
		for v: Vector3 in a[Mesh.ARRAY_VERTEX]:
			rest.append_array([v.x, v.y, v.z, 0.0])
		a[Mesh.ARRAY_CUSTOM0] = rest
		dst.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		var m := src.surface_get_material(i)
		if m.resource_name in BLOODY:
			m = m.duplicate(); m.next_pass = blood
		dst.surface_set_material(i, m); dst.surface_set_name(i, src.surface_get_name(i))
	mi.mesh = dst


func _process(delta: float) -> void:
	var alive := player.mode != Player.Mode.DEAD
	wound = move_toward(wound, clampf(1.0 - float(player.health) / player.max_health, 0.0, 1.0), BLEED * delta)
	blood.set_shader_parameter("wound", wound)
	var heavy := alive and player.health * 3 <= player.max_health
	_breath_amp = move_toward(_breath_amp, 1.0 if heavy else 0.0, BREATH_FADE * delta)
	Audio.fade(breath, _breath_amp, -6.0)
	var t := 1.0 if player.winded else clampf((PANT_FROM - player.stamina / Player.STAMINA_MAX) / PANT_FROM, 0.0, 1.0)
	tired = move_toward(tired, t if alive else 0.0, delta)
	Audio.fade(pant, tired, -8.0)

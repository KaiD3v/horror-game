# An interior, its own scene, Zelda style. One script for every room: a room is a .tscn (scenes/interiors/) with
# this script and its settings below. The room comes from a GLB built by ../tools/cenarios/<name>_build.py with
# vila_kit.py's Room; its markers place everything:
#   entrada          where you come in (facing into the room); entrada_<from>: where you come in by another way
#                    (SceneRouter.arriving = <from>: the ossuary's stairs into the chapel, entrada_sacristia)
#   porta            E there takes you back out (to `out_to`, the village by default) at its porta_<door>
#   npc_<who>        a villager standing there (NpcCatalog)
#   luz_<kind>[_x]   a light (LIGHT); fogao/velario/vela also sound (LOOP_AT)
#   som_<name>       a looped sound there (a clock: som_relogio)
#   teto             the ceiling (hidden for the plan capture)
# A new interior = its GLB + a .tscn with these settings + a porta_<door> marker and a DOORS entry in the village.
extends Level

@export var model := ""                 # models/levels/<model>.glb
@export var door := ""                  # the village's porta_<door> you came in by
@export var out_to := Paths.VILAREJO    # where the door (porta) leads
@export var cutaway := Vector3(0, 8.5, 6.5)  # camera for the plan capture (ceiling off)
@export var ambient := 0.28             # ambient light energy (the chapel's whitewash wants less)
@export var dim := 1.0                  # scales every lamp's energy
@export var drone := ""                 # a quiet 2D loop under the room tone (the chapel: coro)

const LOOP_AT := {"fogao": "fogo", "velario": "velas", "vela": "velas"}
const LIGHT := {  # kind: colour, energy, range
	"lamparina": [Color(1.0, 0.68, 0.36), 1.3, 5.0], "lampiao": [Color(1.0, 0.72, 0.42), 1.5, 7.5],
	"fogao": [Color(1.0, 0.42, 0.18), 1.0, 3.0], "vela": [Color(1.0, 0.62, 0.3), 0.8, 2.5],
	"janela": [Color(0.62, 0.68, 0.78), 0.5, 3.5],  # grey daylight through the fog
	"velario": [Color(1.0, 0.6, 0.28), 1.4, 4.5], "altar": [Color(1.0, 0.7, 0.42), 1.1, 6.5],
	"cirio": [Color(1.0, 0.62, 0.32), 0.9, 4.5]}  # (the crypt's thick candles: no sound, there are a dozen)
const GLOWING := ["window_in", "lampglass", "ember"]  # their own light: unshaded

var room: Node3D
var tone: AudioStreamPlayer
var lights: Array[OmniLight3D] = []
var windows: Array[OmniLight3D] = []   # the luz_janela lights: daylight, so DayCycle dims them at night
var loops: Array[AudioStreamPlayer3D] = []
var radio: AudioStreamPlayer3D          # the venda's (som_musica_venda): at 19h the Voz do Brasil (DayData.radio)
var on_air := ""


func _build() -> void:
	var atmos: Dictionary = Atmospheres.INTERIOR.duplicate(); atmos.ambient_energy = ambient
	env = Looks.environment(self, atmos)
	room = load(Paths.LEVEL_MODEL % model).instantiate(); add_child(room)
	Looks.n64(room)
	Looks.unshade(room, GLOWING)
	for m in Nodes.children_named(room, "luz_"):
		var l: Array = LIGHT[m.name.get_slice("_", 1)]
		lights.append(Looks.omni(self, m.position, l[0], l[1] * dim, l[2]))
		if m.name.get_slice("_", 1) == "janela":
			windows.append(lights[-1])
	spawn_npcs(room)
	Door.make(room.get_node("porta"), "E · sair para a rua" if out_to == Paths.VILAREJO else "E · subir", out_to, door, 1.6)


func _player_start() -> Transform3D:
	var other := "entrada_" + SceneRouter.arriving
	var entry: Node3D = room.get_node(other) if SceneRouter.arriving != "" and room.has_node(other) else room.get_node("entrada")
	return Transform3D(Basis(Vector3.UP, entry.rotation.y), entry.position + Vector3(0, 0.05, 0))  # just inside the door


func _started() -> void:  # the room tone (wind muffled by the walls), the drone, what crackles, ticks and plays in it
	var panes: Array[BaseMaterial3D] = []
	Nodes.visit_surfaces(room, func(_mi, _i, m):
		if m is BaseMaterial3D and m.resource_name == "window_in" and m not in panes:
			panes.append(m))
	day = DayCycle.indoors(self, windows, panes)  # the windows go dark at night; the rain drums on the roof
	tone = Audio.play2d(self, "casa", -12.0, true)
	if drone != "":
		Audio.play2d(self, drone, -15.0, true)
	for m in room.get_children():
		var kind: String = m.name.get_slice("_", 1)
		var n: String = LOOP_AT.get(kind, "") if m.name.begins_with("luz_") else (String(m.name).substr(4) if m.name.begins_with("som_") else "")
		if n != "":
			loops.append(Audio.play3d(self, n, (m as Node3D).position, -4.0, true, 1.5, 10.0))
		if n == "musica_venda":
			radio = loops[-1]; on_air = n


func _process(_d: float) -> void:
	if radio and DayData.radio(WorldTime.hour()) != on_air:
		on_air = DayData.radio(WorldTime.hour())
		radio.stream = Audio.sfx(on_air, true); radio.volume_db = -4.0 if on_air == "musica_venda" else -2.0; radio.play()

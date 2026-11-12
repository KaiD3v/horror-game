# The chapel (interior.gd) and its sacristy door, by the altar (../docs/TUTORIAL_VILAREJO.md "Dungeon 2"): padlocked
# (Dona Firmina's key, chave_sacristia); open, it goes down to the ossuary, whose stairs bring you back up here
# (entrada_sacristia).
extends "res://scripts/levels/interior.gd"

var sacristy: BlockedDoor
var down: Door


func _build() -> void:
	super()
	var m: Node3D = room.get_node("porta_sacristia")
	sacristy = BlockedDoor.make(self, m.position, m.rotation.y, "cadeado", "sacristia", "chave_sacristia", true)
	var spot := Node3D.new(); add_child(spot); spot.position = m.position + m.basis.z * 0.7
	down = Door.make(spot, "E · descer pela sacristia", Paths.interior("ossuario"), "sacristia", 1.2)
	down.enabled = Story.has("aberta:sacristia")
	sacristy.opened.connect(func(): down.enabled = true)
	Door.make(room.get_node("porta_torre"), "E · subir à torre", Paths.interior("torre"), "", 1.0)  # (docs/CONTEUDO_VILAREJO.md)

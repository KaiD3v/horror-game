# Dona Lurdes's house (../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"; ../tools/cenarios/professora_build.py):
# an interior like the others (interior.gd), opened with Cida's key. Her class diary on the desk (NotesData
# "diario_classe"), her husband's pocket watch on the night table (a keepsake, once).
extends "res://scripts/levels/interior.gd"


func _build() -> void:
	super()
	var m: Node3D = room.get_node("relogio")
	Pickup.make(self, m.position, "relogio_bolso", 1, "professora_relogio")

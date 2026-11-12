# The venda's cellar (../docs/CONTEUDO_VILAREJO.md "O porão da venda"; ../tools/cenarios/porao_build.py): what Bento hid
# of his wife Odete, taken up to the Colônia in 1968. Her letter on her trunk (NotesData "carta_odete", never opened),
# and two of his rolls of bandage on the shelf. Up the ladder: back into the shop.
extends "res://scripts/levels/interior.gd"


func _build() -> void:
	super()
	var aid := Pickup.make(self, Vector3(1.6, 0.53, -1.8), "atadura", 2, "porao_ataduras")
	if is_instance_valid(aid):
		aid.prompt = "E · pegar as ataduras da prateleira"


func _player_start() -> Transform3D:  # down the ladder: at its foot, facing into the cellar
	var e: Node3D = room.get_node("entrada")
	return Transform3D(Basis(Vector3.UP, 0.0), e.position + Vector3(0, 0.05, 0))

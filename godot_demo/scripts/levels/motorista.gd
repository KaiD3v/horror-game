# The driver's house (../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"; ../tools/cenarios/motorista_build.py): an
# interior like the others (interior.gd), opened with the key Seu Dito left. His trip book on the table (NotesData
# "livro_viagens"), the São Cristóvão medal in a tin under his cot (a keepsake, once).
extends "res://scripts/levels/interior.gd"


func _build() -> void:
	super()
	var m: Node3D = room.get_node("medalha")
	var p := Pickup.make(self, m.position, "medalha", 1, "motorista_medalha")
	if is_instance_valid(p):
		p.prompt = "E · pegar a lata debaixo da cama"

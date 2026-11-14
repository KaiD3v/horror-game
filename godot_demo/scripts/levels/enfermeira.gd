# Celina's house (../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"; ../tools/cenarios/enfermeira_build.py): an
# interior like the others (interior.gd), opened with the key Bastião kept. In the little suitcase by the door, packed
# and never taken, her first-aid tin (estojo_celina: six cures fit, ../docs/MELHORIAS.md).
extends "res://scripts/levels/interior.gd"

const SUITCASE := Vector3(2.3, 0.42, 1.6)


func _build() -> void:
	super()
	var p := Pickup.make(self, SUITCASE, "estojo_celina", 1, "enfermeira_estojo")
	if is_instance_valid(p) and not p.is_queued_for_deletion():
		p.prompt = "E · abrir a mala"

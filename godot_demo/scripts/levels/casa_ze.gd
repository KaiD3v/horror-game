# Zé's house (interior.gd; ../docs/TUTORIAL_VILAREJO.md "O vilarejo se abre"): and a rosary bead at the saint's feet on
# the oratório shelf (../docs/CHAVE_DO_PORTAO.md, one of the village's four).
extends "res://scripts/levels/interior.gd"


func _build() -> void:
	super()
	Pickup.bead(self, Vector3(2.8, 1.43, -0.82), "conta_ze")

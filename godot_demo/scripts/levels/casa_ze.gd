# Zé's house (interior.gd; ../docs/TUTORIAL_VILAREJO.md "O vilarejo se abre"): and a rosary bead at the saint's feet on
# the oratório shelf (../docs/CHAVE_DO_PORTAO.md, one of the village's four).
extends "res://scripts/levels/interior.gd"


func _build() -> void:
	super()
	Pickup.bead(self, Vector3(2.8, 1.43, -0.82), "conta_ze")
	var blanket := Pickup.make(self, Vector3(-2.1, 0.58, -1.4), "cobertor", 1, "ze_cobertor")  # on his bed: for Bastião
	if is_instance_valid(blanket):
		blanket.prompt = "E · pegar o cobertor da cama"

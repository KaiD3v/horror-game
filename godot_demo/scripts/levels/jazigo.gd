# The crypt under the Moura mausoleum (../docs/CHAVE_DO_PORTAO.md; ../tools/cenarios/jazigo_build.py): the arena of the
# village's last fight. An interior (interior.gd): its candles (luz_cirio_N), its way back up to the cemetery, a box of
# bolts at the stair's foot. O Porteiro comes in phase 3 of the plan.
extends "res://scripts/levels/interior.gd"

var candles: Array[OmniLight3D] = []


func _build() -> void:
	super()
	for l in lights:
		candles.append(l)
	var box: Node3D = room.get_node("virotes")
	var bolts := Pickup.make(self, box.position, "virote", 6, "jazigo_virotes")
	if is_instance_valid(bolts) and not bolts.is_queued_for_deletion():
		Looks.box(bolts, Vector3(0, 0.15, 0), Vector3(0.5, 0.3, 0.35), Color(0.4, 0.3, 0.2))

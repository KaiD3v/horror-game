# The training room: a stone floor, five pillars, a dummy to hit and the mutant past the far pillar. For trying the
# protagonist's controls and fights (tests/test_treino.gd plays it all through).
extends Level

var dummy: Dummy
var enemy: Mutante


func _init() -> void:
	title = "Sala de treino"; floor_kind = "ladrilho"; controls_extra = "H dano"


func _build() -> void:
	Inventory.give_tools()  # the training room: every weapon to try
	env = Looks.environment(self, Atmospheres.NIGHT)
	var moon: Array = Atmospheres.MOON; Looks.sky_light(self, moon[0], moon[1], moon[2])
	Looks.box(self, Vector3(0, -0.5, 0), Vector3(30, 1, 30), Looks.triplanar("stone", 0.6, Color(0.55, 0.53, 0.5)))
	for p in [Vector3(-3, 1.5, -4), Vector3(3, 1.5, -4), Vector3(-3, 1.5, 2), Vector3(3, 1.5, 2), Vector3(0, 1.5, -9)]:
		Looks.box(self, p, Vector3(0.6, 3, 0.6), Looks.triplanar("stone", 1.0, Color(0.8, 0.78, 0.75)))
	dummy = Dummy.new(); dummy.position = Vector3(0, 0, -2.6); add_child(dummy)
	enemy = Mutante.new(); add_enemy(enemy, Vector3(2.5, 0, -10), PI * 0.8)  # past the far pillar

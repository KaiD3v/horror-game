# The training room: a stone floor, five pillars, a dummy to hit and the mutant past the far pillar; to the east a
# course of the puzzle moves (push, ledge, gap, wall), to the west a flight of stairs. For trying the
# protagonist's controls and fights (tests/test_treino.gd plays it all through).
extends Level

var dummy: Dummy
var enemy: Mutante
var block: Pushable
var gap: Jumpable


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
	_course()
	_stairs()


## Off to the east, the moves for puzzles: a block to push, a ledge to haul up onto, a gap to jump to a second one, and
## a wall to climb to a high one.
func _course() -> void:
	var rock := Looks.triplanar("stone", 1.0, Color(0.7, 0.68, 0.64))
	block = Pushable.make(self, Vector3(8, 0, 4))
	Looks.box(self, Vector3(10, 0.625, -2), Vector3(3, 1.25, 2), rock)        # the ledge, its face at z = -1
	Climbable.make(self, Vector3(10, 0, -2), 0.0, 1.25, Vector2(3, 2))      # from any side
	Looks.box(self, Vector3(10, 0.625, -6), Vector3(3, 1.25, 2), rock)        # across a 2 m gap
	Climbable.make(self, Vector3(10, 0, -6), 0.0, 1.25, Vector2(3, 2))
	gap = Jumpable.make(self, Vector3(10, 1.25, -2.6), Vector3(10, 1.25, -5.4))
	var all: Node = load(Paths.PROP % "puzzle").instantiate()                  # the wall, its face at z = -8
	var wall: Node3D = all.find_child("muro", false); all.remove_child(wall); all.free()
	add_child(wall); wall.position = Vector3(6, 0, -8)
	Looks.box(self, Vector3(6, 1.75, -9.225), Vector3(2.0, 3.5, 2.35), rock)  # its body (just behind the stones) and the top
	Climbable.make(self, Vector3(6, 0, -9.225), 0.0, 3.5, Vector2(2.0, 2.35), [Vector3.BACK])  # its holds: the face only


## Off to the west: a flight of five 20 cm stairs up to a landing 1 m high, and a 60 cm block too high to step onto.
func _stairs() -> void:
	var rock := Looks.triplanar("stone", 1.0, Color(0.7, 0.68, 0.64))
	Steps.flight(self, Vector3(-9, 0, 3.5), 0.0, 5, 0.2, 0.35, 2.0, rock)
	Looks.box(self, Vector3(-9, 0.5, 1.25), Vector3(2, 1, 1), rock)
	Looks.box(self, Vector3(-12.5, 0.3, 2.5), Vector3(1.5, 0.6, 1), rock)

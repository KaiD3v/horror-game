# The chapel's bell tower, inside (../docs/CONTEUDO_VILAREJO.md "O sino da capela"; ../tools/cenarios/torre_build.py):
# in from the chapel's little door, up to the belfry. The ladder lies broken; the way up is two moves the village taught:
#   the stone counterweight (Pushable) pushed north once, under the first landing's chalked edge, and up from its top;
#   the wall with holds (puzzle.glb "muro") on the landing, to the top floor; the trapdoor there: the belfry, up on the
#   village's tower (vilarejo.gd, arriving "campanario"), and back down the same way (entrada_campanario).
extends "res://scripts/levels/interior.gd"

const LAND := 2.4            # = torre_build.py: the first landing's top, its front edge, how far back it runs
const LAND_Y := 0.5
const WY := 2.2
const TOP := 5.9             # the top floor (= LAND + the muro's 3.5), and the muro's face (Blender y)
const WALL_Y := 1.2

var block: Pushable
var hatch: Door


func _build() -> void:
	super()
	var at := func(n: String) -> Node3D: return room.get_node(n)
	# the landing as a solid box too: its GLB collider is a hollow mesh, and the stone pushed into it would find nothing
	var body := StaticBody3D.new(); add_child(body); body.position = Vector3(0, LAND / 2, -(LAND_Y + WY) / 2)
	var cs := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(4.4, LAND, WY - LAND_Y)
	cs.shape = box; body.add_child(cs)
	var lid := StaticBody3D.new(); add_child(lid); lid.position = Vector3(1.1, TOP - 0.1, -(WALL_Y + WY) / 2)  # the muro's top: walked on
	var ls := CollisionShape3D.new(); var lb := BoxShape3D.new(); lb.size = Vector3(2.2, 0.2, WY - WALL_Y); ls.shape = lb; lid.add_child(ls)
	block = Pushable.make(self, at.call("pedra").position)
	# the landing's chalked edge, from the block's top (Godot z = -Blender y)
	Climbable.make(self, Vector3(0, 1.0, -(LAND_Y + WY) / 2), 0.0, LAND - 1.0, Vector2(4.4, WY - LAND_Y), [Vector3.BACK])
	var mark: Node3D = at.call("muro")  # the wall with holds, its face to the room (south)
	var all: Node = load(Paths.PROP % "puzzle").instantiate()
	var wall: Node3D = all.find_child("muro", false); all.remove_child(wall); all.free()
	add_child(wall); wall.position = mark.position; wall.rotation.y = PI
	Climbable.make(self, mark.position - Vector3(0, 0, 1.175), 0.0, 3.5, Vector2(2.0, 2.35), [Vector3.BACK])
	hatch = Door.make(at.call("alcapao"), "E · subir ao campanário", Paths.VILAREJO, "campanario", 1.0)

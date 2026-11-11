# O alambique do Juca (../docs/TUTORIAL_VILAREJO.md "Dungeon 1"; ../tools/cenarios/alambique_build.py): the first
# dungeon, an interior like the others (interior.gd) with the route of moves laid over its markers:
#   the block (Pushable "pedra") pushed under the loft's edge, the only way up onto it (Climbable from the block's top);
#   the bats (Morcegos) over the walkway of barrels: the lantern in hand wakes them;
#   the jump over the vinhoto tank to the platform (Jumpable); the wall with holds up the tower (puzzle.glb "muro");
#   Juca's trunk with the machete on top (ChestData), his diary (NotesData), a bandage on the platform;
#   the front door, shored up inside with cane (Breakable "cana"): the machete cuts it and the front door opens, the
#   way in from then on.
# Two doors: in by the side one (porta / entrada, the village's porta_alambique_lado), or by the front once it is open
# (porta_frente / entrada_frente, the village's porta_alambique).
extends "res://scripts/levels/interior.gd"

const LOFT := 2.0           # = alambique_build.py: the loft, the walkway and the platform
const FRONT := "alambique"  # the village's door you come out of by the front
# The big masses as solid boxes too (Blender x0, x1, y0, y1, z0, z1, = alambique_build.py): their GLB colliders are
# hollow meshes, and a block pushed into one would find nothing inside it (Pushable asks for overlaps).
const SOLIDS := [[-7.0, -4.5, -1.0, 5.0, 0.0, LOFT], [-4.5, 1.0, 3.0, 5.0, 0.0, LOFT], [3.5, 7.0, 0.0, 5.0, 0.0, LOFT],
	[3.5, 7.0, -5.0, 0.0, 0.0, LOFT + 3.5], [1.0, 3.5, 2.4, 5.0, 0.0, 0.45]]

var block: Pushable
var cane: Breakable
var bats: Morcegos
var gap: Jumpable
var front: Door


func _build() -> void:
	super()
	for k in SOLIDS:  # (Blender x, y, z -> Godot x, z, -y)
		var body := StaticBody3D.new(); add_child(body)
		body.position = Vector3((k[0] + k[1]) / 2, (k[4] + k[5]) / 2, -(k[2] + k[3]) / 2)
		var cs := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(k[1] - k[0], k[5] - k[4], k[3] - k[2])
		cs.shape = box; body.add_child(cs)
	var at := func(n: String) -> Node3D: return room.get_node(n)
	block = Pushable.make(self, at.call("pedra").position)
	Climbable.make(self, Vector3(-5.75, LOFT / 2, -2.0), 0.0, LOFT / 2, Vector2(2.5, 6.0), [Vector3.RIGHT])  # from the block's top
	gap = Jumpable.make(self, Vector3(0.6, LOFT, -4.0), Vector3(3.9, LOFT, -4.0))
	var mark: Node3D = at.call("muro")
	var all: Node = load(Paths.PROP % "puzzle").instantiate()
	var wall: Node3D = all.find_child("muro", false); all.remove_child(wall); all.free()
	add_child(wall); wall.position = mark.position; wall.rotation.y = mark.rotation.y
	Climbable.make(self, mark.position + Vector3(0, 0, 1.175), 0.0, 3.5, Vector2(2.0, 2.35), [Vector3.FORWARD])  # its holds: the face only
	bats = Morcegos.new(); bats.position = at.call("morcegos").position; add_child(bats)
	var cut: Node3D = at.call("cana")
	cane = Breakable.make(self, cut.position, cut.rotation.y, "alambique_cana", "cana")
	front = Door.make(at.call("porta_frente"), "E · sair pela frente", Paths.VILAREJO, FRONT, 1.2)
	front.enabled = Story.has("quebrado:alambique_cana")
	if is_instance_valid(cane):
		cane.broken.connect(func(): front.enabled = true)
	var aid := Pickup.make(self, at.call("atadura").position, "atadura", 1, "alambique_atadura")
	if is_instance_valid(aid) and not aid.is_queued_for_deletion():
		var all_items: Node = load(Paths.PROP % "itens").instantiate()
		var roll: Node3D = all_items.find_child("atadura", false)
		if roll:
			all_items.remove_child(roll); aid.add_child(roll); roll.position.y = 0.05
		all_items.free()


func _player_start() -> Transform3D:  # in by the front door: just inside it
	if SceneRouter.arriving == FRONT:
		var e: Node3D = room.get_node("entrada_frente")
		return Transform3D(Basis(Vector3.UP, e.rotation.y), e.position + Vector3(0, 0.05, 0))
	return super()

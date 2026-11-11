# A well to go down: a stone ring, two posts and a beam. E with the rope (corda) ties it to the beam and it hangs down
# into the dark (Story "corda:<id>", for good; the rope stays his, a tool); E again and he goes down: `destino`, a
# scene. Coming back up (that scene's rope, WellBottom) puts him beside this well (Level asks arrival()).
# make(level, at, yaw, id, destino) in a level's _build.
class_name Well
extends Interactable

const RADIUS := 0.7

var id := ""
var destino := ""
var rope: Node3D


static func make(level: Node, at: Vector3, yaw: float, well_id: String, scene: String) -> Well:
	var w := Well.new(); w.id = well_id; w.destino = scene; w.position = at; w.rotation.y = yaw
	w.requires = "corda"; w.refusal = "Escuro e fundo. Sem uma corda não dá para descer."
	w.radius = 1.6; w.height = 2.0
	level.add_child(w)
	return w


## Where a level starts the player when he comes up out of the well `arrive` (an id), or `usual` if none of its wells.
static func arrival(level: Node, arrive: String, usual: Transform3D) -> Transform3D:
	for w in level.find_children("*", "Well", true, false):
		if w.id == arrive:
			var at: Vector3 = w.position + w.basis.z * (RADIUS + 0.8)
			return Transform3D(Basis(Vector3.UP, w.rotation.y), at + Vector3(0, 0.05, 0))
	return usual


func roped() -> bool:
	return Story.has("corda:" + id)


func _ready() -> void:
	super()
	var stone := Looks.triplanar("stone", 1.0, Color(0.6, 0.58, 0.54))
	for i in 10:  # the ring wall, in blocks
		var a := TAU * i / 10.0
		var b := Looks.box(self, Vector3(sin(a), 0.0, cos(a)) * (RADIUS + 0.12) + Vector3(0, 0.4, 0), Vector3(0.5, 0.8, 0.24), stone)
		b.rotation.y = a
	var dark := MeshInstance3D.new(); add_child(dark); var disc := CylinderMesh.new()  # the hole
	disc.top_radius = RADIUS; disc.bottom_radius = RADIUS; disc.height = 0.02; dark.mesh = disc; dark.position.y = 0.6
	var m := StandardMaterial3D.new(); m.albedo_color = Color.BLACK; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; disc.material = m
	var wood := Looks.triplanar("planks", 2.0, Color(0.5, 0.38, 0.28))
	for s in [-1, 1]:
		Looks.box(self, Vector3(s * (RADIUS + 0.12), 1.1, 0), Vector3(0.12, 2.2, 0.12), wood)
	Looks.box(self, Vector3(0, 2.15, 0), Vector3(RADIUS * 2 + 0.5, 0.12, 0.12), wood)  # the beam
	_update()


func _update() -> void:
	prompt = "E · descer pela corda" if roped() else "E · amarrar a corda"
	if roped() and rope == null:
		rope = MeshInstance3D.new(); add_child(rope); var c := CylinderMesh.new()
		c.top_radius = 0.02; c.bottom_radius = 0.02; c.height = 2.8; rope.mesh = c; rope.position = Vector3(0, 2.1 - 1.4, 0)
		var m := StandardMaterial3D.new(); m.albedo_color = Color(0.72, 0.6, 0.4); c.material = m
		var knot := MeshInstance3D.new(); rope.add_child(knot); var k := SphereMesh.new()
		k.radius = 0.05; k.height = 0.1; knot.mesh = k; knot.position.y = 1.4; k.material = m


func _use(by: Node3D) -> void:
	if not by is Player:
		return
	if not roped():
		Story.mark("corda:" + id)
		Audio.play2d(self, "escalar", -6.0)
		by.notice.emit("A corda está amarrada na trave.")
		_update()
		return
	Story.mark("poco:volta", [get_tree().current_scene.scene_file_path, id])  # the way back up (WellBottom)
	SceneRouter.go_to(self, destino, "", 0.6, "")

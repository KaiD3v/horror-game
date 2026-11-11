# A roadside oratório: a little wooden niche on a post, a saint inside, a candle at her feet. E: he puts away what he
# holds, prays (reza) and lights the candle; the game is saved (SaveGame) and the candle stays lit for good (Story
# "oratorio:<id>"). Where they stand: SPOTS (a new one = an entry there, no code).
class_name Oratorio
extends Interactable

# id: one of a kind; scene: the scene file's name; at: x, z (dropped onto what is below); yaw: degrees, 0 = facing +z
const SPOTS := [
	{"id": "estrada", "scene": "vilarejo", "at": Vector2(-2.8, 44.0), "yaw": 90.0},  # by the road in, facing it
	{"id": "treino", "scene": "treino", "at": Vector2(-3.0, 2.0), "yaw": 90.0},
]
const WOOD := Color(0.3, 0.19, 0.11)
const FLAME := Color(1.0, 0.68, 0.32)

var id := ""
var flame: OmniLight3D
var wick: MeshInstance3D
var praying := false


static func in_scene(scene: String) -> Array:
	return SPOTS.filter(func(o): return o.scene == scene)


static func make(level: Level, o: Dictionary) -> Oratorio:
	var r := Oratorio.new(); r.id = o.id; r.prompt = "E · rezar no oratório"; r.radius = 1.4
	level.add_child(r)
	var hit := level.ray(o.at.x, o.at.y, o.get("from", 30.0))
	r.global_position = hit.position if hit else Vector3(o.at.x, 0, o.at.y)
	r.rotation.y = deg_to_rad(o.yaw)
	return r


func _ready() -> void:
	super()
	var wood := Looks.triplanar("planks", 2.0, Color(0.75, 0.6, 0.48))
	Looks.box(self, Vector3(0, 0.6, 0), Vector3(0.12, 1.2, 0.12), wood)              # the post
	Looks.box(self, Vector3(0, 1.2, 0), Vector3(0.5, 0.04, 0.36), wood)              # the floor of the niche
	Looks.box(self, Vector3(0, 1.48, -0.16), Vector3(0.5, 0.56, 0.04), wood)         # its back
	for x in [-0.23, 0.23]:
		Looks.box(self, Vector3(x, 1.48, 0), Vector3(0.04, 0.56, 0.36), wood)        # its sides
	for s in [-1, 1]:  # the little roof, two boards
		var b := Looks.box(self, Vector3(0.14 * s, 1.83, 0.02), Vector3(0.34, 0.03, 0.46), WOOD)
		b.rotation.z = -0.6 * s
	var saint := MeshInstance3D.new(); add_child(saint); var c := CapsuleMesh.new()
	c.radius = 0.06; c.height = 0.3; saint.mesh = c; saint.position = Vector3(0, 1.37, -0.06)
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.72, 0.7, 0.62); c.material = m
	wick = MeshInstance3D.new(); add_child(wick); var cy := CylinderMesh.new()
	cy.top_radius = 0.015; cy.bottom_radius = 0.015; cy.height = 0.08; wick.mesh = cy; wick.position = Vector3(0.1, 1.26, 0.08)
	var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.9, 0.86, 0.74); cy.material = wm
	flame = Looks.omni(self, Vector3(0.1, 1.36, 0.1), FLAME, 0.0, 3.0)
	if Story.has("oratorio:" + id):
		flame.light_energy = 1.2


func _process(_delta: float) -> void:
	if flame.light_energy > 0.0:  # the candle breathes
		var t := Time.get_ticks_msec() / 1000.0
		flame.light_energy = 1.2 * (0.85 + 0.1 * sin(t * 9.0) + 0.05 * sin(t * 23.0))


func _use(by: Node3D) -> void:
	if praying or not by is Player:
		return
	_pray(by)


func _pray(p: Player) -> void:
	praying = true; p.busy = true
	await p.free_hands()
	p.velocity = Vector3.ZERO
	var tw := create_tween()  # turned to the saint
	tw.tween_property(p, "rotation:y", p.rotation.y + angle_difference(p.rotation.y, rotation.y), 0.3)  # (his front = -z, its front = +z)
	await tw.finished
	Audio.play2d(self, "reza", -8.0)
	await get_tree().create_timer(1.2).timeout
	if not Story.has("oratorio:" + id):
		Story.mark("oratorio:" + id)
		Audio.play2d(self, "lamparina", -8.0)
		flame.light_energy = 1.2
	var level: Level = get_tree().get_first_node_in_group("level")
	var ok := SaveGame.save(p, level.scene_file_path)
	p.notice.emit("Jogo salvo." if ok else "Não foi possível salvar.")
	p.busy = false; praying = false

# The bottom of a well (Well, `destino`): a round shaft of wet stone, a puddle, the rope he came down by hanging from
# the light far above; a tunnel mouth in the wall, blocked for now. E at the rope climbs back up to the well he came
# down (Story "poco:volta": its scene and id; Level puts him beside it, Well.arrival).
extends Level

const SHAFT := 2.2      # radius
var rope: Interactable


func _init() -> void:
	title = "Fundo do poço"; floor_kind = "terra"


func _build() -> void:
	env = Looks.environment(self, Atmospheres.NIGHT)
	var stone := Looks.triplanar("stone", 1.0, Color(0.42, 0.42, 0.4))
	Looks.box(self, Vector3(0, -0.5, 0), Vector3(8, 1, 8), Looks.triplanar("dirt", 0.6, Color(0.4, 0.36, 0.32)))
	for i in 16:  # the shaft's wall, up into the dark
		var a := TAU * i / 16.0
		if absf(angle_difference(a, PI)) < 0.25:
			continue  # the tunnel mouth, to the north
		var b := Looks.box(self, Vector3(sin(a), 0, cos(a)) * (SHAFT + 0.25) + Vector3(0, 4, 0), Vector3(1.0, 8, 0.5), stone)
		b.rotation.y = a
	Looks.box(self, Vector3(0, 1.0, -SHAFT - 1.4), Vector3(1.4, 2.0, 0.3), Looks.triplanar("stone", 1.0, Color(0.3, 0.3, 0.29)))  # rubble in the tunnel
	var puddle := MeshInstance3D.new(); add_child(puddle); var pm := CylinderMesh.new()
	pm.top_radius = 0.9; pm.bottom_radius = 0.9; pm.height = 0.01; puddle.mesh = pm; puddle.position = Vector3(0.6, 0.005, 0.5)
	var w := StandardMaterial3D.new(); w.albedo_color = Color(0.05, 0.06, 0.07); w.roughness = 0.05; w.metallic = 0.6; pm.material = w
	Looks.omni(self, Vector3(0, 7.5, 0), Color(0.55, 0.6, 0.7), 1.2, 9.0)  # the day (or the night) far up the shaft
	var line := MeshInstance3D.new(); add_child(line); var c := CylinderMesh.new()  # the rope he came down
	c.top_radius = 0.02; c.bottom_radius = 0.02; c.height = 8.0; line.mesh = c; line.position = Vector3(-0.8, 4.0, 0.0)
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.72, 0.6, 0.4); c.material = m
	rope = Interactable.new(); rope.prompt = "E · subir pela corda"; rope.radius = 1.2; rope.position = Vector3(-0.8, 0, 0)
	add_child(rope)
	rope.used.connect(_climb_out)


func _player_start() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-0.2, 0.05, 0.3))  # beside the rope, as he lets go of it


func _climb_out(_by: Node3D) -> void:
	var back: Array = Story.marks.get("poco:volta", [Paths.TREINO, ""])
	SceneRouter.go_to(self, back[0], back[1], 0.6, "")

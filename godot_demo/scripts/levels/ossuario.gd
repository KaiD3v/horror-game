# O ossuário de Santa Clara (../docs/TUTORIAL_VILAREJO.md "Dungeon 2"; ../tools/cenarios/ossuario_build.py): the
# crossbow's dungeon, an interior (interior.gd) under the chapel, with the route laid over its markers:
#   the gallery of drawers: bones underfoot (BONES). Standing, each step cracks and the sleeper's breath, far off in the
#     cistern, rises with it (stir); crouched, hardly a sound. Nothing comes yet: it is the lesson, not the test;
#   Tenório's crossbow by his blood in the chamber; across the cut, the plank on end held by a rope (a Target): a bolt
#     in the rope and it falls across, the bridge (Story "ponte:ossuario");
#   the cistern: O Poceiro asleep (by day, until someone kills him: Story "morto:poceiro"), between the way in and the
#     rope up the well; the bottles on the walls (Targets): one smashed draws him to it. The rope goes up to the square
#     (and from then on comes down from it: Story "corda:poco_largo");
#   the tunnel north, fallen in (the pickaxe, later), and Joaquim's scapular by it.
extends "res://scripts/levels/interior.gd"

const BONES := Rect2(-1.5, -15.0, 3.0, 11.5)   # x, z (Godot) of the floor of bones
const STEP := 0.6                               # m between two cracks
const PLANK := Vector3(1.0, 0.1, 4.2)           # width, thickness, length
const BREATH_EVERY := 3.0

var plank: Node3D
var rope: Target
var bottles: Array[Target] = []
var poceiro: Poceiro
var stir := 0.0                                 # 0..1: how loud he has been on the bones, lately
var _walked := 0.0
var _last := Vector3.INF
var _breath := BREATH_EVERY


func _build() -> void:
	super()
	var at := func(n: String) -> Node3D: return room.get_node(n)
	_shape(Pickup.make(self, at.call("virotes").position, "virote", 5, "ossuario_virotes"), "virote")
	_shape(Pickup.make(self, at.call("besta").position, "besta"), "besta")
	_shape(Pickup.make(self, at.call("escapulario").position, "escapulario"), "escapulario")
	Pickup.bead(self, Vector3(-1.42, 0.37, -9.42), "conta_ossuario")  # in a low drawer of the gallery, among the bones
	HintSpot.make(self, Vector3(0, 0, -3.9), "agachar", 1.6, func(pl: Player): return pl.mode == Player.Mode.EXPLORE and not pl.crouched)
	Climbable.make(self, Vector3(0, -1.5, -16.5), 0.0, 1.5, Vector2(6.0, 3.0), [Vector3.FORWARD])  # up out of the cut, near side only
	_bridge(at.call("ponte").position, at.call("argola").position)
	for m in Nodes.children_named(room, "garrafa_"):
		var b := Target.make(self, m.position, Vector3(0.14, 0.3, 0.14), _bottle_mesh()); bottles.append(b)
		b.hit.connect(_smash.bind(b))
	Breakable.make(self, at.call("tunel").position, 0.0, "ossuario_tunel")
	var up: Node3D = at.call("corda")
	var line := MeshInstance3D.new(); add_child(line); var c := CylinderMesh.new()
	c.top_radius = 0.02; c.bottom_radius = 0.02; c.height = 6.0; line.mesh = c; line.position = up.position + Vector3(0, 3.0, 0)
	var hemp := StandardMaterial3D.new(); hemp.albedo_color = Color(0.72, 0.6, 0.4); c.material = hemp
	var climb := Interactable.new(); climb.prompt = "E · subir pela corda"; climb.radius = 1.1; up.add_child(climb)
	climb.used.connect(func(_by):
		Story.mark("corda:poco_largo")
		SceneRouter.go_to(self, Paths.VILAREJO, "poco", 0.6, ""))
	bake_navmesh({"cell": 0.25, "cell_h": 0.1, "climb": 0.4, "slope": 40.0, "aabb": AABB(Vector3(-7, -2, -39), Vector3(14, 7, 44))})
	if not Story.has("morto:poceiro") and not WorldTime.is_night():  # at night he is up in the village
		var m: Node3D = at.call("poceiro")
		poceiro = Poceiro.new(); add_enemy(poceiro, m.position, m.rotation.y)
		poceiro.asleep = true; poceiro.mouth = m.position; poceiro.beside = m.position
		poceiro.killed.connect(func(): Story.mark("morto:poceiro"))


## An item's shape from models/props/itens.glb under a Pickup (gone already: nothing).
func _shape(p: Pickup, id: String) -> void:
	if not is_instance_valid(p) or p.is_queued_for_deletion():
		return
	var all: Node = load(Paths.PROP % "itens").instantiate()
	var s: Node3D = all.find_child(ItemCatalog.item(id).get("modelo", id), false)
	if s == null:
		s = all.find_child("embrulho", false)
	all.remove_child(s); s.owner = null; all.free(); p.add_child(s); s.position.y = 0.04; s.rotation.x = -PI / 2


## The plank on its hinge at the cut's far edge, on end, and the rope from its top to the ring: a bolt in the rope and
## it falls across the cut, its top on the near edge (or it lies there already).
func _bridge(hinge: Vector3, ring: Vector3) -> void:
	plank = Node3D.new(); add_child(plank); plank.position = hinge
	Looks.box(plank, Vector3(0, PLANK.z / 2, PLANK.y / 2), Vector3(PLANK.x, PLANK.z, PLANK.y),  # (lying: its top at the floor's)
		Looks.triplanar("planks", 1.5, Color(0.5, 0.4, 0.3)))
	if Story.has("ponte:ossuario"):
		plank.rotation.x = PI / 2
		return
	var top := hinge + Vector3(0, PLANK.z, 0)
	var mid := (top + ring) / 2
	var line := CylinderMesh.new(); line.top_radius = 0.025; line.bottom_radius = 0.025; line.height = top.distance_to(ring)
	var hemp := StandardMaterial3D.new(); hemp.albedo_color = Color(0.7, 0.58, 0.38); line.material = hemp
	rope = Target.make(self, mid, Vector3(0.12, 0.12, line.height))
	rope.look_at(ring, Vector3.UP)
	var mi := MeshInstance3D.new(); mi.mesh = line; rope.add_child(mi); mi.rotation.x = PI / 2  # (a cylinder stands on Y)
	rope.hit.connect(_drop)


func _drop() -> void:
	Story.mark("ponte:ossuario")
	Audio.play3d(self, "corda_arrebentar", rope.position, 0.0, false, 4.0, 30.0)
	rope.visible = false
	var tw := create_tween()
	tw.tween_property(plank, "rotation:x", PI / 2, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): Audio.play3d(self, "tabua_cair", plank.position + Vector3(0, 0, PLANK.z), 2.0, false, 5.0, 40.0))


func _bottle_mesh() -> Mesh:
	var m := CylinderMesh.new(); m.top_radius = 0.03; m.bottom_radius = 0.06; m.height = 0.28; m.radial_segments = 8
	var glass := StandardMaterial3D.new(); glass.albedo_color = Color(0.22, 0.3, 0.2); glass.metallic = 0.3; glass.roughness = 0.2
	m.material = glass
	return m


## A bottle smashed: glass on the floor and a noise over there, which the sleeper goes to.
func _smash(b: Target) -> void:
	Audio.play3d(self, "garrafa_quebrar", b.position, 4.0, false, 6.0, 40.0)
	b.visible = false
	if is_instance_valid(poceiro) and poceiro.state != Enemy.State.DEAD:
		poceiro.hear(Vector3(b.position.x * 0.85, 0.0, b.position.z))  # (just off the wall, on the floor)


func _physics_process(delta: float) -> void:
	super(delta)
	if player == null:
		return
	stir = maxf(0.0, stir - 0.08 * delta)
	var p := player.global_position
	var on_bones := BONES.has_point(Vector2(p.x, p.z)) and player.is_on_floor()
	if on_bones and _last != Vector3.INF:
		_walked += Vector2(p.x - _last.x, p.z - _last.z).length()
		if _walked >= STEP:
			_walked = 0.0
			var loud := not player.crouched
			Audio.play3d(self, "ossos_pisar", p, -3.0 if loud else -20.0, false, 3.0 if loud else 1.0, 30.0).pitch_scale = randf_range(0.85, 1.15)
			if loud:
				stir = minf(1.0, stir + (0.35 if Vector2(player.velocity.x, player.velocity.z).length() > Player.JOG_SPEED + 0.2 else 0.18))
	_last = p
	_breath -= delta
	if _breath <= 0.0 and is_instance_valid(poceiro) and poceiro.asleep:  # far off, his breath, louder as he stirs
		_breath = BREATH_EVERY - stir * 1.5
		Audio.play3d(self, "poceiro_respira", poceiro.global_position + Vector3(0, 1.8, 0), lerpf(-14.0, 8.0, stir), false, 8.0, 60.0)
		if stir >= 0.95:  # too much: a growl down there (not yet awake)
			Audio.play3d(self, "poceiro_rugido", poceiro.global_position + Vector3(0, 1.8, 0), -2.0, false, 8.0, 60.0)
			stir = 0.6

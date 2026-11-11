# Vila de Santa Clara (../docs/VILAREJO.md): the village modelled by ../tools/cenarios/vilarejo (vilarejo.glb).
# Colliders come from the GLB's name suffixes (-col, -colonly); the navmesh is baked at load over the playable
# area. Fog does the rest: about 25 m of sight, thicker down in the valley. The GLB's markers place everything:
# spawn_jogador, spawn_mutante (the square, by the well: the tests' reference point), npc_<who>, porta_<interior>, corvo_NN, varal_*, marca_carcaca.
# Nobody hunts here by day (the Mutante first shows in the Colônia, the asylum). At night (noite, madrugada) the night mutants come (../docs/MUTANTES_NOITE.md): A Bruxa on the roof ridges, O Poceiro
# up out of the well, A Carpideira weeping down the alleys; her scream calls the other two (_alarm).
extends Level

# the road through the village (Godot x, z), south to north: puddles gather on it (Clima)
const ROAD := [Vector2(0.5, 44), Vector2(-0.5, 36), Vector2(1.0, 25), Vector2(0.5, 12), Vector2(0.7, 0), Vector2(1.4, -8),
	Vector2(1.8, -20), Vector2(-1.0, -32), Vector2(-1.3, -40), Vector2(0.3, -50)]
const PLAY := AABB(Vector3(-50, -10, -61), Vector3(100, 40, 115))  # the navmesh and the weather cover this
# What closes the map (../docs/VILAREJO.md "Bordas"): east and west a steep rocky bank, too steep to climb; north the
# Colônia's wall; south the ravine, fenced along its brink. These invisible walls only back them up, out of sight.
# (None south of the ravine: the intro walks him up the road there, and the fence keeps him out of it after.)
const WALLS := [[Vector3(-54, 0, 0), Vector3(1, 80, 200)], [Vector3(54, 0, 0), Vector3(1, 80, 200)],
	[Vector3(0, 0, -63), Vector3(200, 80, 1)]]
const GATE := "portao_colonia"  # the Colônia's gate: locked (chave_portao); open, E takes you up to the Colônia
# Doors into interiors (porta_<name> markers at the foot of the steps): E takes you in; coming out puts you back here.
const DOORS := {"armaria": "E · entrar na Armaria do Tenório", "venda": "E · entrar na Venda do Seu Bento",
	"capela": "E · entrar na capela"}
# Finish (../docs/VILAREJO.md "Acabamento"): the silhueta_* shapes get a fog-free haze so they show through the fog as
# layers, darkest nearest. [darkest colour, haze it never gets clearer than, how fast distance adds to it]
const HAZE := {"silhueta_colonia": [Color(0.09, 0.10, 0.12), 0.5, 0.012], "silhueta_perto": [Color(0.09, 0.10, 0.12), 0.66, 0.0],
	"silhueta_longe": [Color(0.09, 0.10, 0.12), 0.8, 0.0], "silhueta_luz": [Color(1.0, 0.66, 0.32), 0.3, 0.008]}

var village: Node3D
var clima: Clima
var crows: Array[Corvo] = []
var events: RandomEvents
var sun: DirectionalLight3D
var haze: Array[ShaderMaterial] = []  # the far shapes' materials (DayCycle moves their fog with the sky)
var wind: AudioStreamPlayer
var bell_at: Vector3          # up in the chapel tower
var creakers: Array[Vector3] = []
const BRUXAS := 2             # perched on the roofs each night
var bruxas: Array[Bruxa] = []
var perches: Array[Vector3] = []  # the roof ridges (found at the first nightfall, once the colliders are in)
var poceiro: Poceiro
var well_out := Vector3.INF
const WELL := Vector2(3.0, -3.0)  # the well's centre (x, z); he climbs out beside the crank's crossbar, towards the square
var carpideira: Carpideira
var alleys: Array[Vector3] = []   # where she walks: the navmesh beside each house
var night := false
var night_watch := true       # the autotest holds the night back until it tests it


func _init() -> void:
	title = "Vila de Santa Clara"; floor_kind = "terra"; controls_extra = "T +1 hora"


func _build() -> void:
	env = Looks.environment(self, Atmospheres.VILLAGE)
	var s: Array = Atmospheres.OVERCAST_SUN; sun = Looks.sky_light(self, s[0], s[1], s[2])
	village = load(Paths.LEVEL_MODEL % "vilarejo").instantiate(); add_child(village)
	Looks.n64(village)
	_finish(village)
	_bounds()
	spawn_npcs(village)
	var g := marker(GATE)
	Gate.make(self, g.position, g.rotation.y, GATE, "chave_portao", Paths.COLONIA, "E · entrar na Colônia")  # before the navmesh: its leaves cut it
	bake_navmesh({"cell": 0.25, "cell_h": 0.1, "climb": 0.4, "slope": 40.0, "aabb": PLAY})  # after the NPCs: they stand in it
	for d in DOORS:
		Door.make(marker("porta_" + d), DOORS[d], Paths.interior(d), d)


func _player_start() -> Transform3D:
	# back out of a door: in front of it, back to the door; otherwise at the road's end, facing north up it
	var at := marker("porta_" + SceneRouter.arriving) if SceneRouter.arriving in DOORS else marker("spawn_jogador")
	var yaw := at.rotation.y + PI if SceneRouter.arriving in DOORS else 0.0
	SceneRouter.arriving = ""
	return Transform3D(Basis(Vector3.UP, yaw), at.position + Vector3(0, 0.3, 0))


func _started() -> void:
	_ambience()
	_life()
	day = DayCycle.outdoors(self, env, sun, haze, clima)  # the hour and the weather light it from here on
	if Intro.pending:  # a new game: the opening (../docs/INTRODUCAO.md)
		var intro := Intro.new(self); add_child(intro); intro.run()
	elif Story.has("intro:vista"):  # the beam he climbed lies in the ravine (once the colliders are in: it asks the ground)
		(func(): marker("ponte_viga_solta").global_transform = Intro.fallen(self)).call_deferred()


func _process(_delta: float) -> void:
	if night_watch and WorldTime.is_night() != night:
		night = not night
		if night:
			_nightfall()
		else:
			for b in bruxas:
				if is_instance_valid(b):
					b.leave()
			if is_instance_valid(poceiro):
				poceiro.go_home()
			if is_instance_valid(carpideira):
				carpideira.go_home(marker("porta_capela").position)


## The bruxas settle on roofs away from the player, O Poceiro climbs out of the well, A Carpideira starts down an
## alley far from the player (last night's dead are cleared away).
func _nightfall() -> void:
	if perches.is_empty():
		for c in Nodes.children_named(village, "casa_"):
			var hit := ray(c.position.x, c.position.z)
			if hit and hit.position.y - c.position.y > 3.5:  # a roof over it (the ruins have none)
				perches.append(hit.position)
	for b in bruxas:
		if is_instance_valid(b):
			b.queue_free()
	bruxas.clear()
	if is_instance_valid(poceiro):
		poceiro.queue_free()
	if is_instance_valid(carpideira):
		carpideira.queue_free()
	if well_out == Vector3.INF:  # beside the well (its little roof covers the centre); found once, before anyone stands there
		var g: Vector3 = ground(WELL.x, WELL.y + 1.8)
		well_out = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, g)
	var mouth := Vector3(WELL.x, well_out.y + 0.85, WELL.y + 0.35)  # on the rim
	poceiro = Poceiro.new()
	add_enemy(poceiro, mouth - Vector3(0, 2.4, 0), 0.0)
	poceiro.emerge(mouth, well_out)
	if alleys.is_empty():
		var map := get_world_3d().navigation_map
		for c in Nodes.children_named(village, "casa_"):
			var a := NavigationServer3D.map_get_closest_point(map, c.position)
			if a.distance_to(c.position) < 8.0:
				alleys.append(a)
	var start := alleys.filter(func(a): return a.distance_to(player.global_position) > 18.0)
	carpideira = Carpideira.new(); carpideira.walks = alleys
	add_enemy(carpideira, start.pick_random() if start else alleys[0], randf() * TAU)
	carpideira.screamed.connect(_alarm)
	var far := perches.filter(func(p): return p.distance_to(player.global_position) > 12.0)
	far.shuffle()
	for p in far.slice(0, BRUXAS):
		var b := Bruxa.new(); b.roosts = perches
		add_enemy(b, p, randf() * TAU); b.perch_on(p)
		bruxas.append(b)


## A Carpideira screamed: O Poceiro hears it, the bruxas come to it.
func _alarm(at: Vector3) -> void:
	if is_instance_valid(poceiro) and poceiro.state != Enemy.State.DEAD:
		poceiro.hear(at)
	for b in bruxas:
		if is_instance_valid(b):
			b.call_to(at)


func marker(n: String) -> Node3D:  # the village GLB sits at the origin: its markers' positions are world positions
	return village.get_node(n)


## AO baked into the vertex colours darkens wall bases, corners and the ground round the houses; the far shapes get
## the haze (silhueta.gdshader).
func _finish(root: Node) -> void:
	var silhueta := Paths.shader("silhueta")
	Nodes.visit_surfaces(root, func(mi: MeshInstance3D, i: int, m: Material):
		if m and HAZE.has(m.resource_name):
			var h := ShaderMaterial.new(); h.shader = silhueta
			h.set_shader_parameter("dark", HAZE[m.resource_name][0]); h.set_shader_parameter("fog", Atmospheres.VILLAGE_FOG)
			h.set_shader_parameter("least", HAZE[m.resource_name][1]); h.set_shader_parameter("density", HAZE[m.resource_name][2])
			h.set_shader_parameter("light", 1.0 if m.resource_name == "silhueta_luz" else 0.0)
			mi.set_surface_override_material(i, h); haze.append(h)
		elif m is BaseMaterial3D:
			m.vertex_color_use_as_albedo = true)  # the baked AO (meshes without colours read white)


func _bounds() -> void:
	for b in WALLS:
		var body := StaticBody3D.new(); body.position = b[0]; add_child(body)
		var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = b[1]; cs.shape = bs; body.add_child(cs)


# Life and weather (../docs/VILAREJO.md "Vida e clima"): drizzle, puddles, mist banks, leaves, ash (Clima) and the
# crows on their perches (Corvo, on the corvo_NN markers).
func _life() -> void:
	clima = Clima.new(); add_child(clima)
	clima.setup(player, PackedVector2Array(ROAD), marker("casa_11").position, PLAY)
	var body: MeshInstance3D = marker("corvo_corpo"); var wing: MeshInstance3D = marker("corvo_asa")
	body.visible = false; wing.visible = false  # templates at the origin
	for c in Nodes.children_named(village, "corvo_"):
		if c.name.get_slice("_", 1).is_valid_int():
			var crow := Corvo.new(); crow.transform = c.transform; add_child(crow)
			crow.player = player; crow.setup(body.mesh, wing.mesh)
			crows.append(crow)


# --- sound: wind always (Dona Firmina's prayer comes with her, NpcCatalog); now and then crows in the dead trees, a
# dog far off towards the Colônia, a creak from the shop sign or a clothesline, and the chapel bell, which nobody rings
func _ambience() -> void:
	wind = Audio.play2d(self, "vento", -9.0, true)
	var chapel := marker("porta_capela")
	bell_at = chapel.position - chapel.basis.z * 2.5 + Vector3(0, 9.2, 0)
	var shop := marker("porta_armaria")
	creakers.append(shop.position - shop.basis.z * 0.95 + Vector3(0, 2.3, 0))  # the board on its chains
	for c in Nodes.children_named(village, "varal_"):
		creakers.append(c.position + Vector3(0, 1.8, 0))
	events = RandomEvents.new(); add_child(events)
	events.add("corvo", Vector2(4, 10), Vector2(8, 20), _crow)
	events.add("rangido", Vector2(6, 14), Vector2(6, 16), _creak)
	events.add("cao", Vector2(25, 45), Vector2(45, 90), _dog)
	events.add("sino", Vector2(40, 70), Vector2(90, 160), _bell)


func _crow() -> AudioStreamPlayer3D:  # near the carcass in the pasture: from it; otherwise up in the trees round you
	var p := player.global_position
	var carcass := marker("marca_carcaca").position
	var at := carcass + Vector3(0, 0.6, 0)
	if carcass.distance_to(p) >= 30.0:
		var a := randf() * TAU; var r := randf_range(12, 30)
		at = p + Vector3(cos(a) * r, 7, sin(a) * r)
	return Audio.play3d(self, "corvo_%d" % randi_range(1, 3), at, 2.0, false, 8.0, 90.0)


func _dog() -> AudioStreamPlayer3D:  # far up the hill, past the Colônia's wall
	return Audio.play3d(self, "cao", Vector3(player.global_position.x + randf_range(-30, 30), 10, -95), 8.0, false, 30.0, 220.0)


func _creak() -> AudioStreamPlayer3D:
	var near := creakers.filter(func(c): return c.distance_to(player.global_position) < 25.0)
	return null if near.is_empty() else Audio.play3d(self, "rangido_%d" % randi_range(1, 2), near.pick_random(), 0.0, false, 3.0, 25.0)


func _bell() -> AudioStreamPlayer3D:  # three tolls, four seconds apart; O Poceiro goes to it
	if is_instance_valid(poceiro) and poceiro.state != Enemy.State.DEAD:
		poceiro.hear(marker("porta_capela").position)
	for i in [1, 2]:
		get_tree().create_timer(4.0 * i).timeout.connect(func(): Audio.play3d(self, "sino", bell_at, 8.0, false, 25.0, 220.0))
	return Audio.play3d(self, "sino", bell_at, 8.0, false, 25.0, 220.0)

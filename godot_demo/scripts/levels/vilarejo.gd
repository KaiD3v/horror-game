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
const THEME := "vilarejo"       # its music (music/vilarejo.mp3, ../docs/VILAREJO.md "Sons"): by day only, low, looping
const THEME_DB := -12.0         # (the track itself is quiet: about half the opening's level)
const GATE := "portao_colonia"  # the Colônia's gate: locked (chave_portao); open, E takes you up to the Colônia
# Doors into interiors (porta_<name> markers at the foot of the steps): E takes you in; coming out puts you back here.
# The ruin by the way in, a classroom of the moves (../docs/TUTORIAL_VILAREJO.md "A ruína"): its numbers are
# ../tools/cenarios/vilarejo/construcoes.py AULA, in the ruin's own frame (Blender: x across, y back from the door, z up).
const AULA := "casa_01"
const AULA_FLOOR := 0.9                 # the plank floor (the hole in it goes down to the ground)
const AULA_PIT := Vector2(-1.05, 0.45)  # y: the hole
const AULA_LOFT := Vector2(1.4, 0.7)    # y of the stone store's face, its height over the floor
const AULA_BREACH := Vector2(0.4, 2.0)  # x: the back wall fallen to the store
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
const BRUXAS := 2             # perched on the roofs each night (one, before he has the machete: roster())
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
	_classroom()
	var g := marker(GATE)
	Gate.make(self, g.position, g.rotation.y, GATE, "chave_portao", Paths.COLONIA, "E · entrar na Colônia")  # before the navmesh: its leaves cut it
	bake_navmesh({"cell": 0.25, "cell_h": 0.1, "climb": 0.4, "slope": 40.0, "aabb": PLAY})  # after the NPCs: they stand in it
	for d in DOORS:
		Door.make(marker("porta_" + d), DOORS[d], Paths.interior(d), d)
	_alambique()
	var ze := marker("parede_casa_ze")  # Zé's house, nailed up after they took him
	_nailed(ze.position, ze.rotation.y, marker("porta_casa_ze"), "casa_ze", "E · entrar na casa do Zé", Paths.interior("casa_ze"))
	_finds.call_deferred()  # (they stand on the ground: once the colliders are in)
	var well := marker("porta_poco")  # the ossuary's rope up the well (../docs/TUTORIAL_VILAREJO.md "Dungeon 2"): once
	var down := Door.make(well, "E · descer pela corda", Paths.interior("ossuario"), "poco", 1.4)  # tied, a way back down
	down.enabled = Story.has("corda:poco_largo")


func _player_start() -> Transform3D:
	# back out of a door (any porta_<arriving>): in front of it, back to the door; otherwise at the road's end, facing
	# north up it
	var out := SceneRouter.arriving != "" and village.has_node("porta_" + SceneRouter.arriving)
	var at := marker("porta_" + SceneRouter.arriving) if out else marker("spawn_jogador")
	var yaw := at.rotation.y + PI if out else 0.0
	SceneRouter.arriving = ""
	return Transform3D(Basis(Vector3.UP, yaw), at.position + Vector3(0, 0.3, 0))


func _started() -> void:
	_ambience()
	_life()
	day = DayCycle.outdoors(self, env, sun, haze, clima)  # the hour and the weather light it from here on
	if Intro.pending:  # a new game: the opening (../docs/INTRODUCAO.md); then the theme
		var intro := Intro.new(self); add_child(intro); intro.finished.connect(theme); intro.run()
	elif not WorldTime.is_night():
		theme()
	elif Story.has("intro:vista"):  # the beam he climbed lies in the ravine (once the colliders are in: it asks the ground)
		(func(): marker("ponte_viga_solta").global_transform = Intro.fallen(self)).call_deferred()


func _process(_delta: float) -> void:
	# (not before the navigation map has synced: the night's places come from it. Arriving at night, up the well's rope
	# or out of a door, the first frames have none yet)
	if night_watch and WorldTime.is_night() != night and NavigationServer3D.map_get_iteration_id(get_world_3d().navigation_map) > 0:
		night = not night
		if night:
			_nightfall()
			Audio.music_stop(6.0)  # the night has no music: only them
		else:
			theme()
			for b in bruxas:
				if is_instance_valid(b):
					b.leave()
			if is_instance_valid(poceiro):
				poceiro.go_home()
			if is_instance_valid(carpideira):
				carpideira.go_home(marker("porta_capela").position)


## Who comes out tonight (../docs/TUTORIAL_VILAREJO.md "As noites"): each when he has the answer to it. With nothing,
## one Bruxa (hang the lantern up and she cannot find you); with the machete, both and O Poceiro; with the crossbow,
## A Carpideira too (killed from afar, in silence).
static func roster() -> Dictionary:
	var blade := Inventory.has("facao")
	return {"bruxas": BRUXAS if blade else 1, "poceiro": blade and not Story.has("morto:poceiro"),  # (killed in the ossuary)
		"carpideira": Inventory.has("besta")}


## The bruxas settle on roofs away from the player, O Poceiro climbs out of the well, A Carpideira starts down an
## alley far from the player (last night's dead are cleared away); who of them comes: roster().
func _nightfall() -> void:
	var who := roster()
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
	if who.poceiro:
		poceiro = Poceiro.new()
		add_enemy(poceiro, mouth - Vector3(0, 2.4, 0), 0.0)
		poceiro.emerge(mouth, well_out)
	if alleys.is_empty():
		var map := get_world_3d().navigation_map
		for c in Nodes.children_named(village, "casa_"):
			var a := NavigationServer3D.map_get_closest_point(map, c.position)
			if a.distance_to(c.position) < 8.0:
				alleys.append(a)
		if alleys.size() < 3:  # (nothing found: try again the next night)
			alleys.clear()
	if who.carpideira and not alleys.is_empty():
		var start := alleys.filter(func(a): return a.distance_to(player.global_position) > 18.0)
		carpideira = Carpideira.new(); carpideira.walks = alleys
		add_enemy(carpideira, start.pick_random() if start else alleys[0], randf() * TAU)
		carpideira.screamed.connect(_alarm)
	var far := perches.filter(func(p): return p.distance_to(player.global_position) > 12.0)
	far.shuffle()
	for p in far.slice(0, who.bruxas):
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


## The village's theme, coming in slowly under the wind (already on: left as it is).
func theme() -> void:
	Audio.music_play(self, THEME, THEME_DB, 8.0, true)


func _exit_tree() -> void:  # through a door: the theme stays out here (an interior has its own sound)
	if Audio.music_name == THEME:
		Audio.music_stop(1.0)


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


## A door nailed up (the crowbar): the planks on the wall at `wall`, and once they are off, E at `door` goes in.
func _nailed(wall: Vector3, yaw: float, door: Node3D, id: String, text: String, scene: String) -> void:
	var nailed := BlockedDoor.make(self, wall, yaw, "tabuas", id, "", true)
	var into := Door.make(door, text, scene, id, 1.6)
	into.enabled = Story.has("aberta:" + id)
	nailed.opened.connect(func(): into.enabled = true)


## Juca's still (../docs/TUTORIAL_VILAREJO.md "Dungeon 1"; casa_16): its side door nailed up (the crowbar, from Seu
## Bento), in by it once open; its front door shored up from inside, until the machete cuts the cane in there.
func _alambique() -> void:
	var side := marker("porta_alambique_lado")
	_nailed(side.position - side.basis.z * 0.95, side.rotation.y, side, "alambique_lado", "E · entrar no alambique",
		Paths.interior("alambique"))
	var front := marker("porta_alambique")
	if Story.has("quebrado:alambique_cana"):
		Door.make(front, "E · entrar no alambique", Paths.interior("alambique"), "alambique", 1.6)
	else:
		var shut := Interactable.new(); shut.prompt = "E · abrir a porta"; shut.radius = 1.4; front.add_child(shut)
		shut.used.connect(func(by): by.notice.emit("Trancada por dentro. Tem coisa pesada escorada do outro lado."))


# What the machete and the crossbow open round the village (../docs/TUTORIAL_VILAREJO.md "O vilarejo se abre"): each
# a find, taken once (Story "pego:<id>"). [id, x, z, yaw of its front, [item ("" = cruzeiros), how many]]
const THICKETS := [["moita_queimada", -26.0, 11.6, 0.0, ["", 10]],   # behind the burnt house
	["moita_cemiterio", -31.0, -18.4, PI, ["virote", 4]],          # behind the cemetery's north wall
	["moita_casa04", 14.6, 15.0, -PI / 2, ["atadura", 2]],         # behind Zé's house
	["moita_alambique", 43.5, 16.4, 0.0, ["", 6]]]                 # by the still, on its south side
# [id, where its rope is tied (the thing hangs 0.75 m under), what hangs, [item, how many]]
const HANGING := [["lata_espantalho", Vector3(30.6, 3.1, 26.6), "lata", ["", 8]],   # a bird-scarer's pole by the scarecrow
	["trouxa_torre", Vector3.INF, "trouxa", ["atadura", 2]]]                        # (INF: at the chapel tower's window)


# A raised tomb in the cemetery's south-west corner, 2 m (no climbing it from the ground), its east edge chalked, a
# rosary bead in the vase on top (../docs/CHAVE_DO_PORTAO.md); a block to push against it: x, z of each.
const TOMB := Vector2(-35.0, -3.5)
const TOMB_BLOCK := Vector2(-31.7, -3.5)


func _tomb() -> void:
	var g := ground(TOMB.x, TOMB.y)
	var stone := Looks.triplanar("stone", 1.0, Color(0.62, 0.6, 0.56))
	Looks.box(self, g + Vector3(0, 0.95, 0), Vector3(1.6, 2.1, 2.2), stone)
	Looks.box(self, g + Vector3(0, 2.03, 0), Vector3(1.8, 0.1, 2.4), stone)                       # its lid
	Looks.box(self, g + Vector3(0.905, 1.97, 0), Vector3(0.02, 0.12, 2.4), Color(0.92, 0.9, 0.84))  # chalk
	Looks.box(self, g + Vector3(-0.35, 2.2, 0.3), Vector3(0.16, 0.24, 0.16), Color(0.45, 0.4, 0.36))  # a vase
	Climbable.make(self, g + Vector3(0, 1.0, 0), 0.0, 1.08, Vector2(1.8, 2.4), [Vector3.RIGHT])  # from a block's top
	Pickup.bead(self, g + Vector3(-0.2, 2.09, -0.15), "conta_cemiterio")
	Pushable.make(self, ground(TOMB_BLOCK.x, TOMB_BLOCK.y))


## The thickets (Breakable "mato") with what they hide behind them, and the things hung up high (a Target: the rope)
## that fall when a bolt cuts it; what was found but not taken lies where it fell.
func _finds() -> void:
	_tomb()
	for t in THICKETS:
		var g := ground(t[1], t[2]); var yaw: float = t[3]
		var behind := g + Basis(Vector3.UP, yaw) * Vector3(0, 0.05, -0.5)
		if Story.has("quebrado:" + t[0]):
			_find(t[0], behind, t[4])
		else:
			var b := Breakable.make(self, g, yaw, t[0], "mato")
			b.broken.connect(_find.bind(t[0], behind, t[4]))
	for h in HANGING:
		var top: Vector3 = h[1]
		if top == Vector3.INF:
			var door := marker("porta_capela")
			top = door.position - door.basis.z * 0.75 + door.basis.x * 1.1 + Vector3(0, 5.6, 0)  # (the tower's face is 1.1 m in;
			# off to the side of the door, so that where it falls is not the door's)
		var under := ground(top.x, top.z, top.y - 0.6)
		if h[2] == "lata":  # the pole it hangs from (tins clank on it in the wind: they scare the birds)
			var wood := Color(0.35, 0.27, 0.2)
			Looks.box(self, Vector3(top.x - 0.5, (top.y + 0.1 + under.y) / 2, top.z), Vector3(0.07, top.y + 0.1 - under.y, 0.07), wood)
			Looks.box(self, top + Vector3(-0.25, 0.05, 0), Vector3(0.55, 0.05, 0.05), wood)
		var lies := under + Vector3(0, 0.05, 0)
		if Story.has("derrubado:" + h[0]):
			_find(h[0], lies, h[3])
			continue
		var thing := _hung(h[2]); add_child(thing); thing.position = top - Vector3(0, 0.75, 0)
		var rope := Target.make(self, top - Vector3(0, 0.25, 0), Vector3(0.12, 0.5, 0.12), _rope_mesh())
		rope.hit.connect(_drop.bind(h, rope, thing, top, lies))


func _drop(h: Array, rope: Target, thing: Node3D, top: Vector3, lies: Vector3) -> void:
	Story.mark("derrubado:" + h[0]); rope.visible = false
	Audio.play3d(self, "corda_arrebentar", top, -2.0, false, 4.0, 30.0)
	var tw := create_tween()
	tw.tween_property(thing, "position", lies + Vector3(0, 0.1, 0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		Audio.play3d(self, "tabua_cair", lies, -6.0, false, 3.0, 25.0)
		thing.queue_free(); _find(h[0], lies, h[3]))


## What a thicket or a rope gave: lying there to take, once.
func _find(id: String, at: Vector3, what: Array) -> void:
	var p := Pickup.money(self, at, what[1], id, "o achado") if what[0] == "" else Pickup.make(self, at, what[0], what[1], id)
	if not is_instance_valid(p) or p.is_queued_for_deletion():
		return
	var all: Node = load(Paths.PROP % "itens").instantiate()
	var s: Node3D = all.find_child(what[0] if what[0] != "" else "embrulho", false)
	if s == null:
		s = all.find_child("embrulho", false)
	all.remove_child(s); s.owner = null; all.free(); p.add_child(s)


func _hung(kind: String) -> Node3D:  # a rusty tin, or a cloth bundle tied up
	var n := Node3D.new(); var mi := MeshInstance3D.new(); n.add_child(mi)
	var mat := StandardMaterial3D.new()
	if kind == "lata":
		var c := CylinderMesh.new(); c.top_radius = 0.07; c.bottom_radius = 0.07; c.height = 0.16; mi.mesh = c
		mat.albedo_color = Color(0.45, 0.28, 0.16); mat.metallic = 0.5
	else:
		var s := SphereMesh.new(); s.radius = 0.2; s.height = 0.34; mi.mesh = s
		mat.albedo_color = Color(0.62, 0.55, 0.45)
	mi.material_override = mat
	return n


func _rope_mesh() -> Mesh:
	var c := CylinderMesh.new(); c.top_radius = 0.012; c.bottom_radius = 0.012; c.height = 0.5
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.7, 0.58, 0.38); c.material = m
	return c

## The classroom ruin's moves: up out of the hole either side, the jump across it, up onto the store and down off its
## back through the breach, "C · agachar" at the door (a ceiling slab down across it), and a tin with coins and a
## schoolbook up on the store.
func _classroom() -> void:
	var r: Transform3D = marker(AULA).transform
	var yaw := r.basis.get_euler().y
	var at := func(x: float, y: float, z: float) -> Vector3: return r * Vector3(x, z, -y)
	var inner := 5.4                    # between the side walls
	var f := AULA_FLOOR; var p := AULA_PIT; var l := AULA_LOFT
	Climbable.make(self, at.call(0.0, (-2.2 + p.x) / 2, 0.05), yaw, f - 0.05, Vector2(inner, p.x + 2.2), [Vector3.FORWARD])
	Climbable.make(self, at.call(0.0, (p.y + l.x) / 2, 0.05), yaw, f - 0.05, Vector2(inner, l.x - p.y), [Vector3.BACK])
	Climbable.make(self, at.call(0.0, (l.x + 2.56) / 2, f), yaw, l.y, Vector2(inner, 2.56 - l.x), [Vector3.BACK])
	Climbable.make(self, at.call((AULA_BREACH.x + AULA_BREACH.y) / 2, (l.x + 2.56) / 2, 0.0), yaw, f + l.y,
		Vector2(AULA_BREACH.y - AULA_BREACH.x, 2.56 - l.x), [Vector3.FORWARD])
	Jumpable.make(self, at.call(0.0, p.x - 0.25, f), at.call(0.0, p.y + 0.3, f))  # (by the brinks: nearer the store, E climbs it)
	HintSpot.make(self, at.call(0.0, -2.75, f), "agachar", 1.4,
		func(pl: Player): return pl.mode == Player.Mode.EXPLORE and not pl.crouched)
	var tin := Pickup.money(self, at.call(1.0, 1.9, f + l.y), 5, "aula_lata", "a lata")
	var mi := MeshInstance3D.new(); tin.add_child(mi)
	var cyl := CylinderMesh.new(); cyl.top_radius = 0.06; cyl.bottom_radius = 0.06; cyl.height = 0.12; mi.mesh = cyl
	mi.position.y = 0.06
	var rust := StandardMaterial3D.new(); rust.albedo_color = Color(0.42, 0.24, 0.14); rust.metallic = 0.4; rust.roughness = 0.7
	mi.material_override = rust


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

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
const CAM_BELFRY := {"height": 1.55, "side": 0.3, "length": 0.9, "fov": 72.0}  # up there: the view, not the roof
const BELFRY := 8.4           # the belfry's floor over the chapel's ground (construcoes.chapel(): the tower's top)
const RUIN_SMOKE := Vector3(9.0, 0, -46.0)    # Bastião's fire in the ruin by the gate (../docs/CONTEUDO_VILAREJO.md)
const QUARRY_SMOKE := Vector3(52.0, 0, -28.0)  # the quarry up on the east bank (opened later: the pickaxe)
var belfry: Transform3D       # the belfry: its middle on its floor, +z out over the square
var bell: Interactable        # the bell up there: the new rope tied, then rung
var up_top := false           # he is up in the belfry (the fog lies below)
const OVEN := Vector3(20.5, 0, -7.5)  # Cida's clay oven behind the venda (../docs/CONTEUDO_VILAREJO.md "Cida")
const PRINTS_FROM := Vector3(16.2, 0, -12.2)  # ...her small footprints in the mud from the venda's back to it
const SHY := 9.0              # how near she lets a grown man come standing, before she ducks into the oven
const CLUES := ["Tô onde a água dorme e ninguém bebe!", "Tô onde o homem de palha vigia a estrada!",
	"Tô onde a casa ainda cheira a fumaça!", "Agora uma que só eu sei: onde a gente aprendia a ler!"]
var cida: Npc
var oven_seat: Transform3D    # where she sits, on the oven's ledge by its mouth
var prints: Node3D            # her footprints (after the rain, while the bread's task is on)
var hide_left := 0.0          # she ducked into the oven: back out after this, unseen
var seek := -1                # the hide-and-seek: the round, -1 when not playing
const BASTIAO_AT := Vector3(9.0, 0, -44.9)     # by his fire in the ruin by the gate (RUIN_SMOKE), facing it
const COOP := Vector3(30.6, 0, -17.6)          # Tenório's hen coop, out the back of the armaria
const RANGE_Z := -28.0                         # ...and his bottles on the rail, 10 m north of where he stands
const BOTTLE_TIME := 18.0                      # his time for the six
var bastiao: Npc
var bottles: Array[Target] = []
var bottle_t := -1.0                           # the bottles' clock, -1 when not shooting
var bottle_bolts := 0                          # bolts in the quiver when it started (the spent ones come back)
var bottle_label: Label
const CAMP := Vector3(13.6, 0, 42.6)           # Seu Dito's camp by the ravine (../docs/CONTEUDO_VILAREJO.md "O mascate")
const LOG_FOOT := Vector3(10.5, 0, 57.0)       # the road crew's log on the far side, standing; falls north across
const LOG_LEN := 11.5
const ROPE_DOWN := Vector3(16.6, 0, 46.0)      # where the rope goes down into the ravine, by the fence
const RAVINE_Z := 51.5                         # the bottom (layout.GULLY_Y)
const CAR := Vector3(6.4, 0, 51.3)             # Dr. Euclides's car down there
var camp: Array[Node3D] = []                   # the mule, the cart, the tarp, his crate (gone with him)
var log_pivot: Node3D                          # the log, turning on its foot
var log_rope: Target
var down_rope: Interactable
const QUARRY := Vector3(47.4, 0, -28.0)        # the gallery's mouth at the foot of the east bank (the pickaxe)
const GRAVE := Vector3(-27.6, 0, -5.5)         # the nameless grave Dona Firmina tends (her "Antero": cemetery grave 2,1)
const VOICE_HOUSES := ["casa_03", "casa_05", "casa_06", "casa_09", "casa_12", "casa_13"]  # shut houses, nobody in them
const VOICE_FOR := 45.0                        # how long it calls
var grave_note: NotePaper
var voice: AudioStreamPlayer3D                 # the voice that imitates, calling from inside a shut house
var voice_door: Interactable
var voice_left := 0.0
var voice_night := -1                          # the night it came last (once a night)
var morning: Array[Node3D] = []                # what the night left, shown in the morning
var morning_day := -1
var up_rope: Interactable
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
var doors := {}                # the doors into the interiors (DOORS), by name
var radio: AudioStreamPlayer3D  # Bento's radio through his shut door, in the hour of the Voz do Brasil (DayData.radio)
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
	belfry = _belfry_at()
	_belfry()
	_classroom()
	var g := marker(GATE)
	Gate.make(self, g.position, g.rotation.y, GATE, "chave_portao", Paths.COLONIA, "E · entrar na Colônia")  # before the navmesh: its leaves cut it
	bake_navmesh({"cell": 0.25, "cell_h": 0.1, "climb": 0.4, "slope": 40.0, "aabb": PLAY})  # (the villagers walk: not in it)
	for d in DOORS:
		doors[d] = Door.make(marker("porta_" + d), DOORS[d], Paths.interior(d), d)
	# shut at night (their routines, ../docs/CONTEUDO_VILAREJO.md): Bento opens to a knock, Tenório does not
	doors.venda.hours(18, 6, "Seu Bento, lá de dentro: — Quem é? ...Ah, é você. Entra, entra, rápido!", true)
	doors.armaria.hours(21, 6, "Tenório, lá de dentro: — De noite eu não abro. Volta de manhã, se ainda tiver manhã.")
	_alambique()
	var ze := marker("parede_casa_ze")  # Zé's house, nailed up after they took him
	_nailed(ze.position, ze.rotation.y, marker("porta_casa_ze"), "casa_ze", "E · entrar na casa do Zé", Paths.interior("casa_ze"))
	_jazigo()
	_padlocked("professora", "chave_professora", "E · entrar na casa da professora")
	_padlocked("enfermeira", "chave_enfermeira", "E · entrar na casa da enfermeira")
	_padlocked("motorista", "chave_motorista", "E · entrar na casa do motorista")
	_finds.call_deferred()  # (they stand on the ground: once the colliders are in)
	var well := marker("porta_poco")  # the ossuary's rope up the well (../docs/TUTORIAL_VILAREJO.md "Dungeon 2"): once
	var down := Door.make(well, "E · descer pela corda", Paths.interior("ossuario"), "poco", 1.4)  # tied, a way back down
	down.enabled = Story.has("corda:poco_largo")


func _player_start() -> Transform3D:
	# back out of a door (any porta_<arriving>): in front of it, back to the door; otherwise at the road's end, facing
	# north up it
	if SceneRouter.arriving == "pedreira":  # out of the quarry's gallery: before its mouth, facing west
		SceneRouter.arriving = ""
		var g := ground(QUARRY.x - 1.6, QUARRY.z, 40.0)
		return Transform3D(Basis(Vector3.UP, PI / 2), g + Vector3(0, 0.3, 0))
	if SceneRouter.arriving == "campanario":  # up the tower's trapdoor: in the belfry, looking out over the square
		SceneRouter.arriving = ""
		return Transform3D(Basis(Vector3.UP, belfry.basis.get_euler().y + PI), belfry * Vector3(-0.55, 0.1, 0.8))
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


func _process(delta: float) -> void:
	_radio()
	_view(delta)
	_cida_tick(delta)
	_bottles_tick(delta)
	_dito_tick()
	_voice_tick(delta)
	_morning_tick()
	if Story.has("tumulo:contou") and grave_note == null and "caderneta_antero" not in NotesReader.read:
		grave_note = NotePaper.make(self, NotesData.note("caderneta_antero"))
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


## The Moura mausoleum (../docs/CHAVE_DO_PORTAO.md): its grate chained; before Tenório's task only a sound from
## below, after it the crowbar breaks the chain and the way goes down to the crypt.
func _jazigo() -> void:
	var wall := marker("parede_jazigo"); var spot := marker("porta_jazigo")
	var asked := Story.task("chave") != "nova" or Story.has("aberta:jazigo")
	var grate := BlockedDoor.make(self, wall.position, wall.rotation.y, "corrente", "jazigo", "", true)
	grate.enabled = asked and not Story.has("aberta:jazigo")
	var shut := Interactable.new(); shut.prompt = "E · olhar a grade"; shut.radius = 1.4; spot.add_child(shut)
	shut.enabled = not asked
	shut.used.connect(func(by): by.notice.emit("Tem alguma coisa batendo lá embaixo."))
	var down := Door.make(spot, "E · descer ao jazigo", Paths.interior("jazigo"), "jazigo", 1.6)
	down.enabled = Story.has("aberta:jazigo")
	grate.opened.connect(func(): down.enabled = true)


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


## One stroke of the bell in its tower (the Angelus: Level.angelus).
func toll() -> void:
	Audio.play3d(self, "sino", bell_at, 8.0, false, 25.0, 220.0)


# --- the belfry (../docs/CONTEUDO_VILAREJO.md "O sino da capela"): up the tower from inside the chapel (torre.gd), out
# of its trapdoor onto the tower top: open on four sides (invisible walls: a fall of 8 m), the bell, the trapdoor back
# down. Up there the fog lies below (DayCycle.clear) and two smokes show what the village hides: Bastião's fire in the
# ruin by the gate, the quarry on the east bank.
func _belfry_at() -> Transform3D:
	var door := marker("porta_capela")
	var chapel := village.find_child("capela*", false, false) as Node3D
	var c := door.position - door.basis.z * 2.5
	c.y = (chapel.global_position.y if chapel else door.position.y) + BELFRY
	return Transform3D(door.basis.orthonormalized(), c)


func _belfry() -> void:
	for w in [[Vector3(1.45, 1.0, 0), Vector3(0.12, 2.0, 3.0)], [Vector3(-1.45, 1.0, 0), Vector3(0.12, 2.0, 3.0)],
			[Vector3(0, 1.0, 1.45), Vector3(3.0, 2.0, 0.12)], [Vector3(0, 1.0, -1.45), Vector3(3.0, 2.0, 0.12)]]:
		var body := StaticBody3D.new(); add_child(body); body.transform = belfry * Transform3D(Basis(), w[0])
		var cs := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = w[1]; cs.shape = box; body.add_child(cs)
	var hatch := Node3D.new(); add_child(hatch); hatch.transform = belfry * Transform3D(Basis(), Vector3(-0.85, 0, 0.85))
	Door.make(hatch, "E · descer pelo alçapão", Paths.interior("torre"), "campanario", 0.6)
	bell = Interactable.new(); bell.radius = 1.2; bell.height = 1.8; add_child(bell)
	bell.position = belfry * Vector3(0, 0.9, 0)
	bell.used.connect(_ring)
	_bell_prompt()
	(func():
		_cida()
		_bastiao()
		_tenorio_yard()
		_mascate()
		_ravine()
		_grave()
		_quarry()
		if not Story.has("bastiao:expulso"):
			_smoke(ground(RUIN_SMOKE.x, RUIN_SMOKE.z), 6.0, true)
		_smoke(ground(QUARRY_SMOKE.x, QUARRY_SMOKE.z), 14.0, false)).call_deferred()  # (on the ground: once it is in)


func _bell_prompt() -> void:
	var tied := Story.has("sino:corda")
	bell.requires = "" if tied else "corda_sino"
	bell.refusal = "A corda apodreceu e caiu. Sem uma corda nova o sino não toca."
	bell.prompt = "E · tocar o sino" if tied else "E · amarrar a corda nova no sino"


func _ring(_by: Node3D) -> void:
	if not Story.has("sino:corda"):  # (the key-like rope is spent on it: Interactable)
		Story.mark("sino:corda")
		Audio.play3d(self, "corda_amarrar", bell.position, 0.0, false, 3.0, 20.0)
		player.notice.emit("A corda nova no sino. Agora a Dona Firmina pode tocar o Ângelus lá de baixo.")
		_bell_prompt()
		await get_tree().create_timer(1.2).timeout
	_bell()


## Up in the belfry the fog thins to a lid over the roofs; the first time, what he sees from there.
func _view(delta: float) -> void:
	up_top = player != null and player.global_position.y > belfry.origin.y - 1.0
	if day:
		day.clear = move_toward(day.clear, 1.0 if up_top else 0.0, delta / 2.5)
	if player and up_top and player.cam_override.is_empty():  # close over his shoulder, under the tower's roof
		player.cam_override = CAM_BELFRY
	elif player and not up_top and player.cam_override == CAM_BELFRY:
		player.cam_override = {}
	if up_top and not Story.has("vista:campanario"):
		Story.mark("vista:campanario")
		player.notice.emit("Daqui de cima a neblina fica embaixo. Uma fumaça na ruína perto do portão... e outra lá no morro, a leste.")


## A thread of smoke going up out of the fog (seen from afar: not fogged), and a fire's glow at its foot (`fire`).
func _smoke(at: Vector3, tall: float, fire: bool) -> void:
	var p := GPUParticles3D.new(); add_child(p); p.position = at + Vector3(0, 0.5, 0)
	p.amount = 40; p.lifetime = 9.0; p.preprocess = 9.0
	p.visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, tall + 6, 12))
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3.UP; m.spread = 6.0; m.initial_velocity_min = tall / 9.0; m.initial_velocity_max = tall / 7.0
	m.gravity = Vector3(0.25, 0, 0.1)  # (the wind leans it)
	m.scale_min = 0.8; m.scale_max = 1.2
	var grow := Curve.new(); grow.add_point(Vector2(0, 0.4)); grow.add_point(Vector2(1, 2.6)); var gt := CurveTexture.new(); gt.curve = grow
	m.scale_curve = gt
	var fade := Gradient.new(); fade.set_color(0, Color(1, 1, 1, 0.0)); fade.set_color(1, Color(1, 1, 1, 0.0))
	fade.add_point(0.15, Color(1, 1, 1, 0.5)); var ft := GradientTexture1D.new(); ft.gradient = fade; m.color_ramp = ft
	p.process_material = m
	var q := QuadMesh.new(); q.size = Vector2.ONE * maxf(1.2, tall / 5.0)
	var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true; mat.albedo_color = Color(0.22, 0.22, 0.24, 0.75); mat.disable_fog = true  # (dark: it reads against the fog)
	q.material = mat; p.draw_pass_1 = q
	if fire:
		Looks.omni(self, at + Vector3(0, 0.6, 0), Color(1.0, 0.5, 0.2), 1.6, 6.0)


# --- Cida (../docs/CONTEUDO_VILAREJO.md "Cida, a filha do Zé"): the Zé's girl, hiding in the clay oven behind the
# venda. By day she sits on its ledge by the mouth; at night she is inside. Shy: a grown man standing within SHY m and she
# ducks into the oven (crouched, she lets you come). Bento's task ("pao") points at her: after a rain her footprints run
# in the mud from the venda's back to the oven. Known, she plays hide-and-seek (her clue for each round; the fourth only
# if you kept her secret from Bento), and gives her map at the end (a note, NotesReader).
func _cida() -> void:
	var g := ground(OVEN.x, OVEN.z)
	var body := StaticBody3D.new(); add_child(body); body.position = g
	var clay := Looks.triplanar("mud", 1.0, Color(0.72, 0.5, 0.36))
	var ledge := MeshInstance3D.new(); var lm := BoxMesh.new(); lm.size = Vector3(1.9, 0.36, 1.9); lm.material = clay
	ledge.mesh = lm; ledge.position.y = 0.18; body.add_child(ledge)
	var dome := MeshInstance3D.new(); var dm := SphereMesh.new(); dm.radius = 0.8; dm.height = 0.8; dm.is_hemisphere = true
	dm.material = clay; dome.mesh = dm; dome.position.y = 0.36; body.add_child(dome)
	var mouth := MeshInstance3D.new(); var mm := BoxMesh.new(); mm.size = Vector3(0.06, 0.38, 0.46)
	var dark := StandardMaterial3D.new(); dark.albedo_color = Color(0.03, 0.025, 0.02); mm.material = dark
	mouth.mesh = mm; mouth.position = Vector3(-0.76, 0.52, 0); body.add_child(mouth)  # its mouth, to the venda (west)
	var cs := CollisionShape3D.new(); var cyl := CylinderShape3D.new(); cyl.radius = 0.9; cyl.height = 1.2
	cs.shape = cyl; cs.position.y = 0.6; body.add_child(cs)
	oven_seat = Transform3D(Basis(Vector3.UP, -PI / 2), g + Vector3(-1.02, 0, 0))  # (her front +z: turned to the west)
	cida = Npc.spawn(self, "cida", oven_seat); cida.pose({"faz": "Sit", "leva": ""})
	prints = Node3D.new(); add_child(prints)
	var mud := StandardMaterial3D.new(); mud.albedo_color = Color(0.46, 0.49, 0.53); mud.roughness = 0.05; mud.metallic = 0.3  # (filled with rain: the grey sky in them, like the puddles)
	var to := g + Vector3(-1.3, 0, -0.3); var n := 12
	for i in n:  # left, right, from the venda's back door to the oven's mouth
		var p := PRINTS_FROM.lerp(to, float(i) / (n - 1)); var dir := (to - PRINTS_FROM).normalized()
		p += Vector3(-dir.z, 0, dir.x) * (0.09 if i % 2 else -0.09)
		var f := MeshInstance3D.new(); var q := PlaneMesh.new(); q.size = Vector2(0.13, 0.26); q.material = mud; f.mesh = q
		prints.add_child(f); f.position = ground(p.x, p.z, g.y + 2.0) + Vector3(0, 0.04, 0); f.rotation.y = atan2(dir.x, dir.z)  # (under the eaves)
	prints.visible = false


func _cida_tick(delta: float) -> void:
	if not is_instance_valid(cida) or player == null:
		return
	prints.visible = Story.task("pao") == "ativa" and not Story.has("cida_conheceu") and Weather.wet > 0.25
	if seek >= 0:
		_seek_tick()
		return
	if Story.has("cida:esconde") and not Story.has("cida:mapa") and not WorldTime.is_night() and not cida.going:
		seek = 0; _seek_round()
		return
	if cida.going:
		return
	var d := Vector2(player.global_position.x - cida.global_position.x, player.global_position.z - cida.global_position.z).length()
	if cida.visible and not Story.has("cida_conheceu") and d < SHY and not player.crouched:  # a grown man: into the oven
		hide_left = 25.0
		if not Story.has("cida:fugiu"):
			Story.mark("cida:fugiu"); player.notice.emit("Uma criança? ...Sumiu para dentro do forno.")
	hide_left = maxf(0.0, hide_left - delta)
	var out := not WorldTime.is_night() and hide_left <= 0.0
	if out != cida.visible and (not out or not cida._seen_from(cida.global_position)):
		cida.visible = out
	cida.talk.enabled = cida.visible


func _seek_spots() -> Array:  # where she hides: by the trough on the square, the scarecrow, behind the burnt house,
	var map := get_world_3d().navigation_map            # in the ruin where the children learnt to read
	var near := func(n: String, off: Vector3) -> Vector3:
		var o := village.find_child(n, true, false) as Node3D
		var p := NavigationServer3D.map_get_closest_point(map, o.global_position + off)
		return ground(p.x, p.z)
	var burnt := marker("casa_11")
	return [near.call("cocho_01*", Vector3(1.4, 0, 0.6)), near.call("espantalho_01*", Vector3(0.9, 0, 0.9)),
		near.call("casa_11", -burnt.global_basis.z * 3.9), near.call(AULA, Vector3.ZERO)]


func _seek_round() -> void:
	var spot: Vector3 = _seek_spots()[seek]
	var face := player.global_position - spot; face.y = 0
	cida.visible = false  # (off to hide: found only once she is there)
	_blink(func():
		cida.global_transform = Transform3D(Basis(Vector3.UP, atan2(face.x, face.z)), spot); cida.visible = true
		cida.pose({"faz": "Kneel", "leva": ""}); cida.talk.enabled = false)
	player.notice.emit("Cida, de longe: — %s" % CLUES[seek])
	if seek == 3:  # the one only she knows: her tin of picture cards, left there
		Pickup.money(self, spot + Vector3(0.6, 0.05, 0.3), 10, "cida_esconderijo", "a lata de figurinhas")


func _seek_tick() -> void:
	var d := Vector2(player.global_position.x - cida.global_position.x, player.global_position.z - cida.global_position.z).length()
	if d > 2.0 or not cida.visible:
		return
	seek += 1
	if seek < (4 if Story.has("cida:segredo") else 3):
		player.notice.emit("Cida: — Achou! Agora conta de novo.")
		_seek_round()
		return
	seek = -1  # found the last time: her map, and back to her oven
	Story.mark("cida:mapa"); Story.set_task("esconde", "feita")
	player.notice.emit("Cida: — Achou! Ganhou. Toma, fiz pra você.")
	notes.take("mapa_cida")
	cida.talk.enabled = true
	cida.go(oven_seat, {"faz": "Sit", "leva": ""}, false, true)


## He shuts his eyes and counts: the screen goes dark a moment, and `then` happens unseen.
func _blink(then: Callable) -> void:
	var layer := CanvasLayer.new(); layer.layer = 50; add_child(layer)
	var black := ColorRect.new(); black.color = Color(0, 0, 0, 0); black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(black)
	var tw := create_tween(); tw.tween_property(black, "color:a", 1.0, 0.5); tw.tween_callback(then)
	tw.tween_interval(0.8); tw.tween_property(black, "color:a", 0.0, 0.6); tw.tween_callback(layer.queue_free)


## The padlocked houses (../docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"): Dona Lurdes's (casa_02, Cida's key),
## the nurse's (casa_14, Bastião's). The key opens the padlock, then the door takes you in.
func _padlocked(id: String, key: String, text: String) -> void:
	var w := marker("parede_" + id)
	var lock := BlockedDoor.make(self, w.position, w.rotation.y, "cadeado", id, key, true)
	var into := Door.make(marker("porta_" + id), text, Paths.interior(id), id, 1.6)
	into.enabled = Story.has("aberta:" + id)
	lock.opened.connect(func(): into.enabled = true)


# --- Bastião (../docs/CONTEUDO_VILAREJO.md "Bastião, o ex-interno"): by his fire in the ruin by the gate, on a stone,
# night and day. Told on to Tenório ("bastiao:expulso"), he is gone: the fire out, and if he had not given you the
# nurse's key, it lies in the ashes.
func _bastiao() -> void:
	var at := ground(BASTIAO_AT.x, BASTIAO_AT.z)
	if Story.has("bastiao:expulso"):
		if not Story.has("bastiao:ajudou"):
			var key := Pickup.make(self, ground(RUIN_SMOKE.x, RUIN_SMOKE.z) + Vector3(0.2, 0.03, 0.1), "chave_enfermeira", 1, "bastiao_cinzas")
			if is_instance_valid(key):
				key.prompt = "E · pegar o que ficou nas cinzas"
		return
	var stone := Looks.box(self, at + Vector3(0, 0.22, 0.12), Vector3(0.5, 0.44, 0.45), Looks.triplanar("stone", 1.0, Color(0.5, 0.48, 0.45)))
	stone.name = "pedra_bastiao"
	bastiao = Npc.spawn(self, "bastiao", Transform3D(Basis(Vector3.UP, PI), at)); bastiao.pose({"faz": "Sit", "leva": ""})
	bastiao.talk.radius = 2.6  # (across his fire: he keeps you at a distance)


# --- Tenório's yard, out the back of the armaria: the hen coop (its hens heard), the rail with the bottles
func _tenorio_yard() -> void:
	var c := ground(COOP.x, COOP.z)
	var planks := Looks.triplanar("planks", 1.0, Color(0.6, 0.5, 0.4))
	Looks.box(self, c + Vector3(0, 0.5, 0), Vector3(1.6, 1.0, 1.2), planks)
	Looks.box(self, c + Vector3(0, 1.08, 0), Vector3(1.8, 0.12, 1.4), Looks.triplanar("roof_tiles", 1.0, Color(0.9, 0.8, 0.75)))
	Audio.play3d(self, "galinhas", c + Vector3(0, 0.6, 0), -6.0, true, 2.0, 14.0)
	for x in [23.4, 28.6]:  # two posts and the rail the bottles stand on
		var p := ground(x, RANGE_Z)
		Looks.box(self, p + Vector3(0, 0.5, 0), Vector3(0.12, 1.0, 0.12), planks)
	var mid := ground(26.0, RANGE_Z)
	Looks.box(self, mid + Vector3(0, 1.02, 0), Vector3(5.4, 0.08, 0.14), planks)


# --- Seu Dito's camp by the ravine (../docs/CONTEUDO_VILAREJO.md "O mascate"): the mule (heard), his cart, the tarp, the
# crate he sits on (NpcCatalog "mascate": there, or on the square on market days). Across the ravine the road crew's log
# stands, held up by a rope at its top (a Target): cut, it falls north across (Story "tronco:caiu"), and the next morning
# he is gone over it with the mule, unseen (Story "dito:foi"): his note and the driver's key left at the camp.
func _mascate() -> void:
	var all: Node = load(Paths.PROP % "mascate").instantiate()
	var put := func(n: String, at: Vector3, yaw: float) -> Node3D:
		var o: Node3D = all.find_child(n, false); all.remove_child(o); o.owner = null; add_child(o)
		o.position = ground(at.x, at.z); o.rotation.y = yaw; Looks.n64(o)
		return o
	if not Story.has("dito:foi"):
		camp.append(put.call("mula", CAMP + Vector3(3.2, 0, 0.6), PI / 2))
		camp.append(put.call("carroca", CAMP + Vector3(-1.4, 0, 0.2), 0.3))
		camp.append(put.call("lona", CAMP + Vector3(1.0, 0, -1.6), PI))
		camp.append(Looks.box(self, ground(12.6, 44.5) + Vector3(0, 0.22, 0), Vector3(0.45, 0.44, 0.4), Looks.triplanar("planks", 1.0, Color(0.7, 0.6, 0.5))))
		camp.append(Audio.play3d(self, "mula", CAMP + Vector3(3.2, ground(CAMP.x, CAMP.z).y + 1.2, 0.6), -8.0, true, 2.0, 16.0))
	else:
		_dito_left()
	# the log: its foot on the far side; upright and leaning a little north, or fallen across
	var foot := ground(LOG_FOOT.x, LOG_FOOT.z)
	log_pivot = Node3D.new(); add_child(log_pivot); log_pivot.position = foot
	var trunk: Node3D = all.find_child("tronco", false); all.remove_child(trunk); trunk.owner = null
	log_pivot.add_child(trunk); Looks.n64(trunk)
	var stake := ground(LOG_FOOT.x, LOG_FOOT.z + 4.5)
	var stake_body := Looks.box(self, stake + Vector3(0, 0.4, 0), Vector3(0.18, 0.8, 0.18), Looks.triplanar("planks", 1.0, Color(0.6, 0.5, 0.4)))
	stake_body.name = "estaca_tronco"
	all.free()
	if Story.has("tronco:caiu"):
		log_pivot.rotation.x = _fallen_angle()
		return
	log_pivot.rotation.x = -0.1  # (leaning north: the rope at its top holds it back)
	var top := log_pivot.global_transform * Vector3(0, LOG_LEN - 0.3, 0)
	var rope := MeshInstance3D.new(); add_child(rope)
	var rm := CylinderMesh.new(); rm.top_radius = 0.02; rm.bottom_radius = 0.02; rm.height = top.distance_to(stake + Vector3(0, 0.75, 0))
	var sisal := StandardMaterial3D.new(); sisal.albedo_color = Color(0.7, 0.62, 0.42); rm.material = sisal; rope.mesh = rm
	rope.global_transform = Transform3D(Basis(), (top + stake + Vector3(0, 0.75, 0)) / 2.0)
	rope.look_at(top, Vector3.FORWARD); rope.rotate_object_local(Vector3.RIGHT, PI / 2)
	var aim := top.lerp(stake + Vector3(0, 0.75, 0), 0.12)  # (near the top: over the fence from this side)
	log_rope = Target.make(self, aim, Vector3(0.5, 0.5, 0.5))
	log_rope.hit.connect(func():
		rope.queue_free()
		Audio.play3d(self, "corda_arrebentar", aim, 4.0, false, 6.0, 40.0)
		var tw := create_tween(); tw.tween_interval(0.4)
		tw.tween_property(log_pivot, "rotation:x", _fallen_angle(), 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			Audio.play3d(self, "tronco_cair", ground(LOG_FOOT.x, LOG_FOOT.z - LOG_LEN + 1.0) + Vector3(0, 1, 0), 6.0, false, 10.0, 70.0)
			Story.mark("tronco:caiu"); Story.mark("tronco:dia", int(WorldTime.minutes / 1440.0))
			player.notice.emit("O tronco caiu atravessado na ravina. Uma ponte.")))


## How far the log turns on its foot to lie from the far bank onto this one (its top on the fence's brink).
func _fallen_angle() -> float:
	var foot := ground(LOG_FOOT.x, LOG_FOOT.z)
	var end := ground(LOG_FOOT.x, LOG_FOOT.z - LOG_LEN + 0.6)
	return -PI / 2 + asin(clampf((end.y + 0.3 - foot.y) / LOG_LEN, -1.0, 1.0))


## The morning after the log fell he goes, unseen: the camp packed up, his note and the driver's key on the ground.
func _dito_tick() -> void:
	if not Story.has("tronco:caiu") or Story.has("dito:foi") or player == null:
		return
	if int(WorldTime.minutes / 1440.0) <= int(Story.marks.get("tronco:dia", 0)) or WorldTime.hour() < 5.5:
		return
	if player.global_position.distance_to(CAMP) < 30.0:  # (not while he could be seen packing)
		return
	Story.mark("dito:foi")
	for o in camp:
		if is_instance_valid(o):
			o.queue_free()
	camp.clear()
	_dito_left()


func _dito_left() -> void:
	var n := NotesData.note("bilhete_dito").duplicate()
	if n.id not in NotesReader.read:
		NotePaper.make(self, n)
	var key := Pickup.make(self, ground(13.3, 43.0) + Vector3(0, 0.03, 0), "chave_motorista", 1, "dito_chave")
	if is_instance_valid(key):
		key.prompt = "E · pegar a chave embrulhada no bilhete"


# --- the bottom of the ravine (../docs/CONTEUDO_VILAREJO.md "O fundo da ravina"): with a rope, down from beside the camp
# (Story "corda:ravina" once tied); Dr. Euclides's car down there in the mud, his briefcase (NotesData "pasta_euclides"),
# his wallet. Walled in at both ends of the stretch; the rope back up.
func _ravine() -> void:
	var top := ground(ROPE_DOWN.x, ROPE_DOWN.z)
	var bottom := ground(ROPE_DOWN.x, RAVINE_Z - 0.6)
	down_rope = Interactable.new(); add_child(down_rope); down_rope.position = top; down_rope.radius = 1.4
	down_rope.requires = "corda"; down_rope.refusal = "Fundo demais. Sem uma corda não dá para descer."
	down_rope.prompt = "E · descer pela corda" if Story.has("corda:ravina") else "E · amarrar a corda e descer"
	down_rope.used.connect(func(_by):
		if not Story.has("corda:ravina"):
			Story.mark("corda:ravina"); Audio.play3d(self, "corda_amarrar", top, 0.0, false, 3.0, 20.0)
			_hanging_rope(top, bottom); down_rope.prompt = "E · descer pela corda"
		_blink(func(): _put_player(bottom + Vector3(0, 0.1, -0.4), PI)))
	up_rope = Interactable.new(); add_child(up_rope); up_rope.position = bottom; up_rope.radius = 1.4; up_rope.height = 2.5
	up_rope.prompt = "E · subir pela corda"
	up_rope.used.connect(func(_by): _blink(func(): _put_player(top + Vector3(0, 0.1, -0.9), 0.0)))
	if Story.has("corda:ravina"):
		_hanging_rope(top, bottom)
	for x in [2.6, 19.0]:  # the stretch of the bottom he can walk: from the bridge's rubble to past the rope
		var wall := StaticBody3D.new(); add_child(wall); wall.position = Vector3(x, bottom.y + 3.0, RAVINE_Z)
		var cs := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(0.4, 8.0, 10.0); cs.shape = box; wall.add_child(cs)
	var all: Node = load(Paths.PROP % "mascate").instantiate()
	var car: Node3D = all.find_child("carro", false); all.remove_child(car); car.owner = null; all.free()
	var body := StaticBody3D.new(); add_child(body); body.position = ground(CAR.x, CAR.z); body.rotation.y = 0.35
	body.add_child(car); Looks.n64(car)
	var cs2 := CollisionShape3D.new(); var cb := BoxShape3D.new(); cb.size = Vector3(1.7, 1.2, 4.4); cs2.shape = cb
	cs2.position.y = 0.6; body.add_child(cs2)
	Looks.omni(self, body.position + Vector3(0.5, 3.5, 0), Color(0.62, 0.66, 0.74), 1.2, 9.0)  # (the grey sky down the gap)
	var wallet := Pickup.money(self, ground(CAR.x + 1.1, CAR.z + 0.6) + Vector3(0, 0.05, 0), 20, "ravina_carteira", "a carteira do doutor")
	if is_instance_valid(wallet):
		Looks.omni(self, wallet.position + Vector3(0, 0.4, 0), Color(0.9, 0.85, 0.7), 0.6, 2.5)  # (a glint down there)


func _hanging_rope(top: Vector3, bottom: Vector3) -> void:
	var m := MeshInstance3D.new(); add_child(m)
	var c := CylinderMesh.new(); c.top_radius = 0.025; c.bottom_radius = 0.025; c.height = top.y + 1.0 - bottom.y
	var sisal := StandardMaterial3D.new(); sisal.albedo_color = Color(0.7, 0.62, 0.42); c.material = sisal; m.mesh = c
	m.position = Vector3(bottom.x, (top.y + 1.0 + bottom.y) / 2.0, (top.z + bottom.z) / 2.0)
	m.rotation.x = atan2(bottom.z - top.z, top.y + 1.0 - bottom.y)


func _put_player(at: Vector3, yaw: float) -> void:
	player.global_position = at; player.velocity = Vector3.ZERO; player.rotation.y = yaw


# --- the quarry (../docs/CONTEUDO_VILAREJO.md "A pedreira"): at the foot of the east bank, under the smoke seen from the
# belfry, a gallery's mouth in a rock face, its timber frame, a quarry cart on its side; rubble fills it (Breakable
# "entulho": the pickaxe, which comes later). Cleared, the gallery (pedreira).
func _quarry() -> void:
	var g := ground(QUARRY.x, QUARRY.z, 40.0)
	var rock := Looks.triplanar("rock", 1.0, Color(0.6, 0.57, 0.53))
	Looks.box(self, g + Vector3(1.4, 2.0, 0), Vector3(1.6, 5.0, 6.0), rock)              # the quarried face
	var planks := Looks.triplanar("planks", 1.0, Color(0.6, 0.5, 0.4))
	for dz in [-1.0, 1.0]:                                                                 # the mouth's timber frame
		Looks.box(self, g + Vector3(0.45, 1.2, dz), Vector3(0.22, 2.4, 0.22), planks)
	Looks.box(self, g + Vector3(0.45, 2.45, 0), Vector3(0.26, 0.26, 2.5), planks)
	var dark := MeshInstance3D.new(); add_child(dark); var dm := BoxMesh.new(); dm.size = Vector3(0.05, 2.3, 1.8)
	var black := StandardMaterial3D.new(); black.albedo_color = Color(0.02, 0.02, 0.02); dm.material = black; dark.mesh = dm
	dark.position = g + Vector3(0.58, 1.15, 0)
	var all: Node = load(Paths.PROP % "mascate").instantiate()
	var cart: Node3D = all.find_child("vagonete", false); all.remove_child(cart); cart.owner = null; all.free()
	add_child(cart); cart.position = ground(QUARRY.x - 1.6, QUARRY.z + 2.4, 40.0); cart.rotation.y = 0.6; Looks.n64(cart)
	var heap := Breakable.make(self, g + Vector3(0.2, 0, 0), PI / 2, "pedreira_entulho", "entulho")
	var spot := Node3D.new(); add_child(spot); spot.position = g + Vector3(-0.2, 0, 0)
	var into := Door.make(spot, "E · entrar na galeria", Paths.interior("pedreira"), "pedreira", 1.4)
	into.enabled = Story.has("quebrado:pedreira_entulho")
	if is_instance_valid(heap):
		heap.broken.connect(func(): into.enabled = true)


# --- the nameless grave (../docs/CONTEUDO_VILAREJO.md "O túmulo sem nome"): the one Dona Firmina kneels at in the
# afternoons, calling it her Antero's. A cross with no name, fresh wild flowers on the mound. Looked at (Story
# "tumulo:visto"), she can be asked; told (her talk), Antero's little book lies under the cross (NotesData).
func _grave() -> void:
	var g := ground(GRAVE.x, GRAVE.z)
	var colours := [Color(0.85, 0.75, 0.25), Color(0.9, 0.9, 0.85), Color(0.6, 0.3, 0.55), Color(0.85, 0.45, 0.2)]
	for k in 9:  # wild flowers, a small bunch
		var f := MeshInstance3D.new(); add_child(f); var m := BoxMesh.new(); m.size = Vector3(0.1, 0.07, 0.1)
		var mat := StandardMaterial3D.new(); mat.albedo_color = colours[k % colours.size()]; m.material = mat; f.mesh = m
		f.position = g + Vector3(randf_range(-0.22, 0.22), 0.42 + randf_range(0, 0.08), randf_range(0.3, 0.6))
		mat.emission_enabled = true; mat.emission = mat.albedo_color; mat.emission_energy_multiplier = 0.25  # (they catch the eye)
		var stem := MeshInstance3D.new(); add_child(stem); var sm := BoxMesh.new(); sm.size = Vector3(0.015, 0.34, 0.015)
		var green := StandardMaterial3D.new(); green.albedo_color = Color(0.25, 0.4, 0.2); sm.material = green; stem.mesh = sm
		stem.position = f.position - Vector3(0, 0.18, 0)
	var look := Interactable.new(); add_child(look); look.position = g; look.radius = 1.6; look.prompt = "E · olhar o túmulo"
	look.used.connect(func(_by):
		Story.mark("tumulo:visto")
		player.notice.emit("Uma cruz sem nome. Flores frescas, do mato: alguém vem aqui toda tarde."))


# --- the voice that imitates (../docs/CONTEUDO_VILAREJO.md "A noite"): once a night, between 20h and 3h, near a shut
# house with nobody in it, a woman's voice calls him from inside (voz_chama, muffled), and the door can be opened for
# VOICE_FOR seconds. Opened: nothing human in there; a scream, a wound (Story "voz:abriu"). Left shut: it stops
# (Story "voz:resistiu"). Cida said it: never open.
func _voice_tick(delta: float) -> void:
	if voice:
		voice_left -= delta
		if voice_left <= 0.0:
			Story.mark("voz:resistiu"); _voice_end()
		return
	var h := WorldTime.hour()
	var night_n := int((WorldTime.minutes - 12 * 60) / 1440.0)  # (a night runs from noon to noon)
	if not night or night_n == voice_night or not (h >= 20.0 or h < 3.0) or player == null or player.busy:
		return
	var best: Node3D = null; var bd := 22.0
	for n in VOICE_HOUSES:
		var house := village.find_child(n, false, false) as Node3D
		if house and house.global_position.distance_to(player.global_position) < bd:
			best = house; bd = house.global_position.distance_to(player.global_position)
	if best:
		start_voice(best)


func start_voice(house: Node3D) -> void:
	voice_night = int((WorldTime.minutes - 12 * 60) / 1440.0)  # (once a night)
	var front := house.global_basis.z.normalized()
	var from := house.global_position + Vector3(0, 1.2, 0) + front * 8.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from - front * 8.0, 1))
	var wall: Vector3 = hit.position if hit else house.global_position + front * 3.0
	voice = Audio.play3d(self, "voz_chama", wall - front * 0.6, -2.0, true, 3.0, 24.0)
	voice.attenuation_filter_cutoff_hz = 1600.0
	voice_door = Interactable.new(); add_child(voice_door); voice_door.position = Vector3(wall.x, ground(wall.x, wall.z).y, wall.z) + front * 0.4
	voice_door.radius = 1.6; voice_door.height = 2.5; voice_door.prompt = "E · abrir a porta"
	voice_door.used.connect(func(_by): _voice_opened())
	voice_left = VOICE_FOR
	player.notice.emit("De dentro da casa fechada, uma voz de mulher. Chama devagar. Parece a voz da mãe.")


func _voice_opened() -> void:
	Story.mark("voz:abriu")
	var at := voice_door.global_position
	_voice_end()
	Audio.play3d(self, "porta", at, 0.0, false, 3.0, 20.0)
	Audio.play3d(self, "bruxa_guincho", at + Vector3(0, 1.5, 0), 6.0, false, 6.0, 60.0)
	player.take_damage(1.0, null, true)
	player.notice.emit("Não tinha ninguém. Tinha alguma coisa, e ela sabia o seu nome.")


func _voice_end() -> void:
	if voice:
		voice.queue_free(); voice = null
	if voice_door:
		voice_door.queue_free(); voice_door = null


# --- the morning after (../docs/CONTEUDO_VILAREJO.md "A noite"): from 6h to 12h what the night left is there, a
# different thing each morning: scratches up a shut house's door (day even), or one of Tenório's hens torn open by his
# coop (day odd), and Bento or Tenório say so (Story "manha:arranhoes" / "manha:galinha", gone at noon).
func _morning_tick() -> void:
	var day := int(WorldTime.minutes / 1440.0)
	var h := WorldTime.hour()
	var on := day >= 1 and h >= 6.0 and h < 12.0
	if on and morning_day != day:
		_morning_clear(); morning_day = day
		var kind := "arranhoes" if day % 2 == 0 else "galinha"
		Story.mark("manha:" + kind)
		if kind == "arranhoes":
			_scratches(village.find_child(VOICE_HOUSES[day % VOICE_HOUSES.size()], false, false) as Node3D)
		else:
			_dead_hen()
	elif not on and morning_day >= 0:
		_morning_clear(); morning_day = -1


func _morning_clear() -> void:
	for n in morning:
		if is_instance_valid(n):
			n.queue_free()
	morning.clear()
	Story.marks.erase("manha:arranhoes"); Story.marks.erase("manha:galinha")


func _scratches(house: Node3D) -> void:
	if house == null:
		return
	var front := house.global_basis.z.normalized()
	var from := house.global_position + Vector3(0, 1.3, 0) + front * 8.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from - front * 8.0, 1))
	if not hit:
		return
	var d := Decal.new(); add_child(d); morning.append(d)
	d.texture_albedo = load(Paths.TEXTURE % "arranhoes"); d.size = Vector3(1.0, 0.6, 1.6)
	d.global_transform = Transform3D(Basis.looking_at(-front, Vector3.UP) * Basis(Vector3.RIGHT, PI / 2), hit.position)


func _dead_hen() -> void:
	var c := ground(COOP.x - 1.4, COOP.z + 0.6)
	var white := StandardMaterial3D.new(); white.albedo_color = Color(0.85, 0.82, 0.76)
	var red := StandardMaterial3D.new(); red.albedo_color = Color(0.45, 0.06, 0.04)
	var body := MeshInstance3D.new(); add_child(body); morning.append(body); var bm := BoxMesh.new()
	bm.size = Vector3(0.4, 0.18, 0.28); bm.material = white; body.mesh = bm; body.position = c + Vector3(0, 0.07, 0); body.rotation.y = 0.6
	var blood := MeshInstance3D.new(); add_child(blood); morning.append(blood); var pm := PlaneMesh.new()
	pm.size = Vector2(0.7, 0.5); pm.material = red; blood.mesh = pm; blood.position = c + Vector3(0.1, 0.01, 0.05)
	for k in 10:  # feathers all round
		var f := MeshInstance3D.new(); add_child(f); morning.append(f); var fm := PlaneMesh.new()
		fm.size = Vector2(0.06, 0.03); fm.material = white; f.mesh = fm
		f.position = c + Vector3(randf_range(-1.2, 1.2), 0.02, randf_range(-1.0, 1.0)); f.rotation.y = randf() * TAU


## A game started from a talk (Dialog "jogo"): Tenório's palitinho on the porch, or his bottles out the back.
func start_game(id: String) -> void:
	match id:
		"palitinho":
			var why := Palitinho.can_play()
			if why != "":
				player.notice.emit("Tenório: — " + why)
			else:
				add_child(Palitinho.new(player))
		"garrafas":
			_bottles_start()


func _bottles_start() -> void:
	if bottle_t >= 0.0:
		return
	for b in bottles:
		if is_instance_valid(b):
			b.queue_free()
	bottles.clear()
	var glass := StandardMaterial3D.new(); glass.albedo_color = Color(0.5, 0.82, 0.45, 0.9)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; glass.roughness = 0.1
	var mid := ground(26.0, RANGE_Z)
	for i in 6:
		var m := CylinderMesh.new(); m.top_radius = 0.03; m.bottom_radius = 0.055; m.height = 0.36; m.material = glass
		var t := Target.make(self, Vector3(23.9 + 0.84 * i, mid.y + 1.24, RANGE_Z), Vector3(0.12, 0.36, 0.12), m)
		t.hit.connect(_bottle_hit.bind(t))
		bottles.append(t)
	bottle_t = 0.0; bottle_bolts = Inventory.count("virote")
	if bottle_label == null:
		var layer := CanvasLayer.new(); add_child(layer)
		bottle_label = Label.new(); layer.add_child(bottle_label)
		bottle_label.anchor_left = 0.5; bottle_label.anchor_right = 0.5; bottle_label.offset_left = -160; bottle_label.offset_right = 160
		bottle_label.offset_top = 70; bottle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bottle_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	bottle_label.visible = true
	player.notice.emit("Tenório: — Seis garrafas. Dezoito segundos. Valendo!")


func _bottle_hit(t: Target) -> void:
	Audio.play3d(self, "garrafa_quebrar", t.global_position, 0.0, false, 3.0, 30.0)
	for c in t.get_children():
		if c is MeshInstance3D:
			c.visible = false


func _bottles_tick(delta: float) -> void:
	if bottle_t < 0.0:
		return
	bottle_t += delta
	var down := bottles.filter(func(b): return b.done).size()
	bottle_label.text = "Garrafas %d de 6   ·   %.1f s   (o dele: %d s)" % [down, bottle_t, int(BOTTLE_TIME)]
	if down < 6 and bottle_t < 40.0:
		return
	var t := bottle_t; bottle_t = -1.0; bottle_label.visible = false
	var spent := bottle_bolts - Inventory.count("virote")  # he picks your bolts up off the ground
	if spent > 0:
		Inventory.add("virote", spent)
	if down < 6:
		player.notice.emit("Tenório: — Acabou o tempo. Os virotes eu junto pra você.")
	elif t <= BOTTLE_TIME and not Story.has("garrafas:venceu"):
		Story.mark("garrafas:venceu"); Inventory.add("aljava_couro")
		player.notice.emit("Tenório: — %.1f segundos. ...Hm. Toma a aljava. Promessa é promessa." % t)
		FoundBanner.open(self, "aljava_couro")
	elif t <= BOTTLE_TIME:
		player.notice.emit("Tenório: — %.1f. Bom. A aljava você já tem." % t)
	else:
		player.notice.emit("Tenório: — %.1f segundos. O meu é dezoito. Ainda não, rapaz." % t)


## At 19h the Voz do Brasil through the venda's door, muffled by the boards; gone at 20h.
func _radio() -> void:
	var on := DayData.radio(WorldTime.hour()) == "voz_do_brasil"
	if on and radio == null:
		radio = Audio.play3d(self, "voz_do_brasil", marker("porta_venda").position + Vector3(0, 1.5, 0), -6.0, true, 2.0, 16.0)
		radio.attenuation_filter_cutoff_hz = 1200.0
	elif not on and radio:
		radio.queue_free(); radio = null

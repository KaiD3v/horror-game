# Base of every playable scene. It brings the parts every level shares: the player, the HUD, using things (E),
# footsteps, the notes and trunks lying here, the villagers on their markers, doors, the navmesh and ground queries, the
# pause and death menus (GameMenu) and the autotest hook (`-- --autotest` runs res://tests/test_<scene>.gd).
# A level overrides _build() (environment, geometry, NPCs, enemies, navmesh), _player_start() and _started()
# (sound, weather: once the player and the HUD exist).
class_name Level
extends Node3D

@export var title := ""            # its name (the death menu says where)
@export var floor_kind := "terra"  # footsteps: terra, madeira, ladrilho
var controls_extra := ""           # its test keys: under "Pausa" in the pause menu
var scene_id := ""                 # this scene's file name (vilarejo, armaria...): notes and tests key on it
var player: Player
var hud: Hud
var interactor: Interactor
var footsteps: Footsteps
var notes: NotesReader
var caderno: Caderno               # Tab: tasks, pockets, notes
var shop: ShopMenu                 # the shop screen, for whichever seller you talk to
var dialog: DialogBox              # talking to a villager
var wheel: WeaponWheel             # Q: what he holds
var menu: GameMenu                 # Esc: the pause menu; dying: the death menu
var env: Environment
var nav: NavigationRegion3D
var npcs := {}                     # who -> Npc
@export var bell_db := -18.0       # the chapel bell from here (the Angelus, toll()): far off; the chapel and tower louder
var day: DayCycle                  # the hour and the weather (levels that have them: vilarejo, interiors)
const FALL_Y := -60.0              # below every level's floor: whoever gets here fell out of the world
var last_floor := Vector3.ZERO     # where he last stood on something (put back there if he falls out)


func _ready() -> void:
	scene_id = scene_file_path.get_file().get_basename()
	add_to_group("level")  # navmesh source: every StaticBody3D below, on collision layer 1
	GameInput.setup()
	_build()
	var arrive := SceneRouter.arriving  # (_player_start may use it up: up out of a well is decided after)
	player = Player.new(); player.transform = SaveGame.start(scene_file_path, Well.arrival(self, arrive, _player_start()))
	SceneRouter.arriving = ""
	add_child(player)
	SaveGame.settle(player, scene_file_path)  # a restored game: his health, his lantern; and this scene's return point
	hud = Hud.new(player); add_child(hud)
	interactor = Interactor.new(player, hud); add_child(interactor)
	footsteps = Footsteps.new(player, floor_kind); add_child(footsteps)
	notes = NotesReader.new(); add_child(notes)
	caderno = Caderno.new(); add_child(caderno)
	shop = ShopMenu.new(); add_child(shop)
	dialog = DialogBox.new(); add_child(dialog)
	wheel = WeaponWheel.new(player); add_child(wheel)
	menu = GameMenu.new(player); add_child(menu)
	notes.closed.connect(func(): hud.say("%d de %d notas · no caderno (Tab)" % [NotesReader.read.size(), NotesData.NOTES.size()], 2.5))
	_place_notes.call_deferred()  # once the level's colliders are in the physics world
	_started()
	if SceneRouter.testing():
		AutoTest.attach(self)


func _build() -> void:
	pass


func _player_start() -> Transform3D:
	return Transform3D.IDENTITY


func _started() -> void:
	pass


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	_routine()
	_bells()
	if player.global_position.y > FALL_Y:
		if player.is_on_floor():  # (this frame's floor is last frame's: a teleport down there is not ground)
			last_floor = player.global_position
	else:  # through a gap nobody saw: back on his feet where he was, no harm
		player.global_position = last_floor + Vector3(0, 0.3, 0); player.velocity = Vector3.ZERO


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("debug_time") and day:  # T: an hour on (to see the day go round)
		day._step(60.0)


func _place_notes() -> void:
	for n in NotesData.in_scene(scene_id):
		if n.id not in NotesReader.read:
			NotePaper.make(self, n)
	for c in ChestData.in_scene(scene_id):  # the trunks: opened ones stay, open and empty
		Chest.make(self, c)
	for o in Oratorio.in_scene(scene_id):  # where to save
		Oratorio.make(self, o)


# --- shared building blocks ---------------------------------------------------------------------------------
## A villager on every npc_<who> marker under root; those with a routine (NpcCatalog "rotina") wherever it has them
## now, if that is here (_routine moves them on as the hours go).
func spawn_npcs(root: Node) -> void:
	npc_root = root
	for m in Nodes.children_named(root, "npc_"):
		var who := String(m.name).trim_prefix("npc_")
		if NpcCatalog.slot(who).is_empty():
			npcs[who] = Npc.spawn(self, who, m.global_transform)
	_place_routines.call_deferred()  # (they stand on the floor: once the colliders are in)


func _place_routines() -> void:
	for who in NpcCatalog.NPCS:
		var s := NpcCatalog.slot(who)
		if s.is_empty():
			continue
		routine[who] = s
		if s.cena == scene_id:
			_come(who, s, _spot(s))


var npc_root: Node                 # the model the villagers' places are named in (spawn_npcs)
var routine := {}                  # who -> the slot of their routine they are in


func _come(who: String, s: Dictionary, at: Transform3D) -> Npc:
	var n := Npc.spawn(self, who, at); npcs[who] = n
	n.gone.connect(func(): npcs.erase(who))
	if NpcCatalog.info(who).get("luz", {}).get("fica", false):
		var home := npc_root.find_child("npc_" + who, true, false) as Node3D
		n.leave_behind(home.global_transform if home else Transform3D(), home != null)  # (not here: they stayed there)
	n.pose(s)
	return n


## The hour moved them on: across this scene (walking), out of it by the door to theirs, or in from it.
func _routine() -> void:
	for who in routine:
		var was: Dictionary = routine[who]
		var s := NpcCatalog.slot(who)
		if s.get("i", -1) == was.get("i", -1):
			continue
		if s.is_empty():  # gone for good (NpcCatalog "some"): off, unseen
			routine.erase(who)
			var gone: Npc = npcs.get(who)
			if gone:
				gone.go(gone.global_transform, {}, true)
			return
		routine[who] = s
		var here: bool = s.cena == scene_id
		var n: Npc = npcs.get(who)
		if n and was.cena == scene_id:
			n.go(_spot(s) if here else _door(s.cena), s, not here)
		elif here:
			n = _come(who, s, _door(was.cena)); n.go(_spot(s), s, false, true)


## A slot's place here: its node (or point), its offset and turn, and the floor under it.
func _spot(s: Dictionary) -> Transform3D:
	var base := Transform3D(Basis(), s.get("pos", Vector3.ZERO))
	if not s.has("pos"):
		var m := npc_root.find_child(s.em, true, false) as Node3D
		if m == null:
			push_error("NPC routine: no %s in %s" % [s.em, scene_id]); return Transform3D()
		base = m.global_transform.orthonormalized()
	var at: Vector3 = base * (s.off as Vector3)
	var hit := ray(at.x, at.z, at.y + 1.6)  # (from under a porch roof, down to the boards)
	if hit and hit.position.y > at.y - 2.0:
		at = hit.position
	elif s.has("pos"):
		at = ground(at.x, at.z)
	return Transform3D(Basis(Vector3.UP, base.basis.get_euler().y + s.rumo), at)


## The Angelus (../docs/CONTEUDO_VILAREJO.md "O sino da capela"), once the bell has its rope again (Story "sino:corda"):
## at 6h and 18h, three tolls three times and then nine.
const ANGELUS := [0.0, 2.5, 5.0, 10.0, 12.5, 15.0, 20.0, 22.5, 25.0, 30.0, 32.5, 35.0, 37.5, 40.0, 42.5, 45.0, 47.5, 50.0]
var _bell_hour := -1.0


func _bells() -> void:
	var h := WorldTime.hour()
	if Story.has("sino:corda") and _bell_hour >= 0.0:
		for at in [6.0, 18.0]:
			if _bell_hour < at and h >= at and h - at < 0.5:
				angelus()
	_bell_hour = h


func angelus() -> void:
	var tw := create_tween()
	var last := 0.0
	for t: float in ANGELUS:
		tw.tween_interval(t - last); tw.tween_callback(toll); last = t


## One stroke of the bell, as heard here (the village: up in its tower).
func toll() -> void:
	Audio.play2d(self, "sino", bell_db)


## Where you go in or out to `scene`: the village's porta_<scene>, a room's porta.
func _door(scene: String) -> Transform3D:
	var d := npc_root.find_child("porta_" + scene, true, false) as Node3D
	if d == null:
		d = npc_root.find_child("porta", false, false) as Node3D
	return Transform3D(Basis(Vector3.UP, d.global_rotation.y + PI), d.global_position)


func add_enemy(e: Enemy, at: Vector3, yaw: float) -> Enemy:
	e.position = at; e.rotation.y = yaw  # bodies get their position before entering the tree: added at the
	add_child(e)                          # origin first, the physics server would still have them there
	return e


## Bakes the navmesh over every StaticBody3D in the "level" group. The agent is 2.2 m tall: the low doors keep the
## mutants out. p: cell, cell_h, climb[, slope, aabb].
func bake_navmesh(p: Dictionary) -> void:
	var map := get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, p.cell); NavigationServer3D.map_set_cell_height(map, p.cell_h)
	var nm := NavigationMesh.new()
	nm.cell_size = p.cell; nm.cell_height = p.cell_h
	nm.agent_height = 2.2; nm.agent_radius = 0.4; nm.agent_max_climb = p.climb
	nm.agent_max_slope = p.get("slope", 45.0)
	if p.has("aabb"):
		nm.filter_baking_aabb = p.aabb
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nm.geometry_source_group_name = &"level"
	nav = NavigationRegion3D.new(); nav.navigation_mesh = nm; add_child(nav)
	nav.bake_navigation_mesh(false)


func reachable(a: Vector3, b: Vector3) -> bool:
	var path := NavigationServer3D.map_get_path(get_world_3d().navigation_map, a, b, true)
	return path.size() > 0 and Vector2(path[path.size() - 1].x, path[path.size() - 1].z).distance_to(Vector2(b.x, b.z)) < 0.6


## What is straight below x, z, looking down from height `from` (collision layer 1).
func ray(x: float, z: float, from := 60.0) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, from, z), Vector3(x, from - 90.0, z), 1)
	return get_world_3d().direct_space_state.intersect_ray(q)


## The ground (or whatever stands there) under x, z.
func ground(x: float, z: float, from := 60.0) -> Vector3:
	var hit := ray(x, z, from)
	return hit.position if hit else Vector3(x, 0, z)

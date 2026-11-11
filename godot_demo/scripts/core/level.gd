# Base of every playable scene. It brings the parts every level shares: the player, the HUD, using things (E),
# footsteps, the notes and trunks lying here, the villagers on their markers, doors, the navmesh and ground queries, the
# pause and death menus (GameMenu) and the autotest hook (`-- --autotest` runs res://tests/test_<scene>.gd).
# A level overrides _build() (environment, geometry, NPCs, enemies, navmesh), _player_start() and _started()
# (sound, weather: once the player and the HUD exist).
class_name Level
extends Node3D

@export var title := ""            # the HUD's first words
@export var floor_kind := "terra"  # footsteps: terra, madeira, ladrilho
var controls_extra := ""           # added to the HUD's controls line
var scene_id := ""                 # this scene's file name (vilarejo, armaria...): notes and tests key on it
var player: Player
var hud: Hud
var interactor: Interactor
var footsteps: Footsteps
var notes: NotesReader
var shop: ShopMenu                 # the shop screen, for whichever seller you talk to
var dialog: DialogBox              # talking to a villager
var wheel: WeaponWheel             # Q: what he holds
var menu: GameMenu                 # Esc: the pause menu; dying: the death menu
var env: Environment
var nav: NavigationRegion3D
var npcs := {}                     # who -> Npc
var day: DayCycle                  # the hour and the weather (levels that have them: vilarejo, interiors)


func _ready() -> void:
	scene_id = scene_file_path.get_file().get_basename()
	add_to_group("level")  # navmesh source: every StaticBody3D below, on collision layer 1
	GameInput.setup()
	_build()
	player = Player.new(); player.transform = _player_start(); add_child(player)  # placed before it enters the tree
	hud = Hud.new(player, title, controls_extra); add_child(hud)
	interactor = Interactor.new(player, hud); add_child(interactor)
	footsteps = Footsteps.new(player, floor_kind); add_child(footsteps)
	notes = NotesReader.new(); add_child(notes)
	shop = ShopMenu.new(); add_child(shop)
	dialog = DialogBox.new(); add_child(dialog)
	wheel = WeaponWheel.new(player); add_child(wheel)
	menu = GameMenu.new(player); add_child(menu)
	notes.closed.connect(func(): hud.say("%d de %d notas · Tab relê" % [NotesReader.read.size(), NotesData.NOTES.size()], 2.5))
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


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("debug_time") and day:  # T: an hour on (to see the day go round)
		day._step(60.0)


func _place_notes() -> void:
	for n in NotesData.in_scene(scene_id):
		if n.id not in NotesReader.read:
			NotePaper.make(self, n)
	for c in ChestData.in_scene(scene_id):  # the trunks: opened ones stay, open and empty
		Chest.make(self, c)


# --- shared building blocks ---------------------------------------------------------------------------------
## A villager on every npc_<who> marker under root.
func spawn_npcs(root: Node) -> void:
	for m in Nodes.children_named(root, "npc_"):
		var who := String(m.name).trim_prefix("npc_")
		npcs[who] = Npc.spawn(self, who, m.global_transform)


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

# Colônia Santa Clara: greybox of the first slice ("Pavilhão B"), see ../docs/CENARIOS.md.
# The infirmary holds A Enfermeira (Enfermeira), too tall for its low door: shut in until the shortcut is unbolted.
# Boxes only, at real measurements. The navmesh is baked at load for an agent 2.2 m tall, so the LOW doors
# (1.9 m) keep the mutant (2.18 m) out: the church always, the infirmary until its shortcut is unbolted.
#
#                     [Igreja]            church: safe room, low side door; main door boarded up
#                        | low
#  [Portaria]--[    Pátio (yard)    ]--[Refeitório]
#                        |                  | shortcut (bolted from the infirmary side, E opens it)
#                  [Pavilhão B]===low===[Enfermaria]
#                                           |
#                                        [Usina]
extends Level

const H := 3.0                 # wall height
const T := 0.2                 # wall thickness
const DOOR := [1.4, 2.4]       # width, height
const LOW := [1.0, 1.9]        # the player (1.7 m) fits, the mutant does not
const ROOMS := {  # x0, z0, x1, z1
	"portaria": [-17, -3, -10, 3], "igreja": [-5, -19, 5, -10], "refeitorio": [10, -10, 20, 2],
	"pavilhao": [-10, 10, 10, 16], "enfermaria": [10, 2, 20, 16], "usina": [10, 16, 20, 22]}
const SHORTCUT := Vector3(15, 0, 2)

var C := {}  # scenery materials, see _materials()
var enemy: Mutante
var nurse: Enfermeira  # shut in the infirmary until you unbolt the shortcut (she can't take the low door)
var shortcut: StaticBody3D
var bolt: Interactable  # E at the shortcut: opens from the infirmary side only
var ceilings: Array[Node3D] = []
var church_told := false


func _init() -> void:
	title = "Colônia Santa Clara (greybox)"; floor_kind = "ladrilho"


func _build() -> void:
	env = Looks.environment(self, Atmospheres.COLONIA)
	var moon: Array = Atmospheres.MOON; Looks.sky_light(self, moon[0], moon[1], moon[2])
	Looks.omni(self, Vector3(0, 1.4, -17.3), Color(1.0, 0.7, 0.4), 1.4, 8.0)  # the church reads as safe from across the yard
	_materials()
	_build_rooms()
	bake_navmesh({"cell": 0.1, "cell_h": 0.05, "climb": 0.25})
	enemy = Mutante.new(); add_enemy(enemy, Vector3(-9, 0, 13), -PI / 2)  # far end of the ward
	nurse = Enfermeira.new(); add_enemy(nurse, Vector3(18, 0, 7), PI / 2)  # past the operating table, facing the low door
	bolt = Interactable.new(); bolt.prompt = "E · porta"; bolt.radius = 1.8; bolt.position = SHORTCUT; add_child(bolt)
	bolt.used.connect(_on_bolt)


func _player_start() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, -PI / 2), Vector3(-14, 0, 0))  # gatehouse, facing the yard


func _box(pos: Vector3, size: Vector3, look: Variant) -> StaticBody3D:
	return Looks.box(self, pos, size, look)


# --- geometry ----------------------------------------------------------------------------------------
func _materials() -> void:
	C = {
		"low": Looks.triplanar("paint_green", 0.5), "up": Looks.triplanar("plaster", 0.5),                  # hospital two-tone paint
		"dirt": Looks.triplanar("dirt", 0.5), "tile": Looks.triplanar("tiles"), "ceil": Looks.triplanar("ceiling"),
		"wood": Looks.triplanar("planks"), "metal": Looks.triplanar("enamel"), "bed": Looks.triplanar("linen"), "stone": Looks.triplanar("stone"),
		"bark": Looks.triplanar("bark", 2.0), "machine": Looks.triplanar("machine"), "painted": Looks.triplanar("painted_wood", 1.5)}


func _build_rooms() -> void:
	_box(Vector3(1.5, -0.5, 1.5), Vector3(60, 1, 60), C.dirt)
	for r in ROOMS.values():
		var c := Vector3((r[0] + r[2]) / 2.0, 0, (r[1] + r[3]) / 2.0)
		var s := Vector3(r[2] - r[0], 0, r[3] - r[1])
		_box(c + Vector3(0, 0.01, 0), Vector3(s.x, 0.02, s.z), C.tile)
		var lid := _box(c + Vector3(0, H + 0.1, 0), Vector3(s.x + T, 0.2, s.z + T), C.ceil)
		lid.collision_layer = 2  # the camera bumps into it, the navmesh ignores it
		ceilings.append(lid)

	_wall(-10, -10, 20, -10, [[3.0, LOW[0], LOW[1]]])               # yard / church / refectory, north line
	_wall(10, 2, 20, 2, [[SHORTCUT.x, DOOR[0], DOOR[1]]])           # refectory | infirmary: the shortcut
	_wall(-10, 10, 10, 10, [[-6.0, DOOR[0], DOOR[1]]])              # yard | ward
	_wall(-10, 16, 20, 16, [[17.0, DOOR[0], DOOR[1]]])              # ward south | infirmary | boiler room
	_wall(10, 22, 20, 22)
	_wall(-5, -19, 5, -19); _wall(-5, -19, -5, -10); _wall(5, -19, 5, -10)  # church
	_wall(-10, -10, -10, 16, [[0.0, DOOR[0], DOOR[1]]])             # yard west, gatehouse door
	_wall(10, -10, 10, 22, [[-4.0, DOOR[0], DOOR[1]], [13.0, LOW[0], LOW[1]]])  # yard east; ward -> infirmary low
	_wall(20, -10, 20, 22)
	_wall(-17, -3, -10, -3); _wall(-17, 3, -10, 3); _wall(-17, -3, -17, 3)  # gatehouse

	shortcut = _box(SHORTCUT + Vector3(0, DOOR[1] / 2, 0), Vector3(DOOR[0], DOOR[1], 0.12), C.wood)
	_props()


func _props() -> void:
	_box(Vector3(0, 1.2, -9.86), Vector3(1.4, 2.4, 0.04), C.wood)          # church main door, boarded up
	for y in [0.5, 1.2, 1.9]:
		_box(Vector3(0, y, -9.82), Vector3(1.8, 0.16, 0.05), C.wood)
	for y in [0.6, 1.4, 2.2]:                                               # outer gate, boarded up
		_box(Vector3(-16.88, y, 0), Vector3(0.05, 0.16, 2.2), C.wood)
	# yard: bandstand, trees, well, benches. They break the mutant's line of sight.
	for x in [-1.6, 1.6]:
		for z in [-1.6, 1.6]:
			_box(Vector3(x, 1.4, z), Vector3(0.3, 2.8, 0.3), C.painted)
	_box(Vector3(0, 2.95, 0), Vector3(4.2, 0.2, 4.2), C.wood)
	_box(Vector3(0, 0.15, 0), Vector3(3.4, 0.3, 3.4), C.stone)
	for p in [Vector3(-6, 0, -6), Vector3(6.5, 0, 6), Vector3(-7, 0, 5.5), Vector3(7, 0, -7.5)]:
		_box(p + Vector3(0, 1.6, 0), Vector3(0.4, 3.2, 0.4), C.bark)
	_box(Vector3(5, 0.45, -4.5), Vector3(1.3, 0.9, 1.3), C.stone)
	for p in [Vector3(-4, 0, 7.8), Vector3(4, 0, -7.8), Vector3(-7.8, 0, -3)]:
		_box(p + Vector3(0, 0.25, 0), Vector3(1.8, 0.5, 0.5) if absf(p.x) < 6 else Vector3(0.5, 0.5, 1.8), C.wood)
	_box(Vector3(-13, 0.5, -2.2), Vector3(2.2, 1.0, 0.7), C.wood)            # gatehouse desk
	for z in [-12.0, -13.4, -14.8, -16.2]:                                         # church pews, altar
		_box(Vector3(-2.3, 0.25, z), Vector3(3.0, 0.5, 0.5), C.wood)
		_box(Vector3(2.3, 0.25, z), Vector3(3.0, 0.5, 0.5), C.wood)
	_box(Vector3(0, 0.5, -18), Vector3(2.6, 1.0, 1.0), C.stone)  # altar
	for z in [-7.0, -2.5]:                                                  # refectory tables + benches
		_box(Vector3(15, 0.4, z), Vector3(6.5, 0.8, 1.0), C.wood)
		for dz in [-0.85, 0.85]:
			_box(Vector3(15, 0.22, z + dz), Vector3(6.5, 0.45, 0.35), C.wood)
	for x in [-8.5, -6.3, -4.1, -1.9, 0.3, 2.5, 4.7]:                       # ward: beds along the south wall
		_bed(Vector3(x, 0, 14.9))
	for p in [Vector3(-3, 0, 11.6), Vector3(3.6, 0, 12.4)]:                 # folding screens across the aisle
		_box(p + Vector3(0, 0.9, 0), Vector3(1.6, 1.8, 0.08), C.bed)  # linen screens
	_box(Vector3(15, 0.45, 9), Vector3(2.0, 0.9, 0.8), C.metal)              # infirmary: operating table
	for z in [4.0, 6.5, 12.0, 14.5]:
		_box(Vector3(19.4, 1.0, z), Vector3(0.8, 2.0, 1.6), C.metal)        # cabinets
	_box(Vector3(12.5, 0.42, 5), Vector3(0.7, 0.84, 1.9), C.metal)            # gurney: enamel frame
	_box(Vector3(12.5, 0.88, 5), Vector3(0.66, 0.08, 1.85), C.bed)            # and its sheet
	_box(Vector3(15, 0.9, 19.6), Vector3(3.0, 1.8, 2.0), C.machine)            # boiler room: generator
	_box(Vector3(11.5, 1.3, 20.5), Vector3(1.6, 2.6, 1.6), C.stone)          # wood furnace


func _bed(at: Vector3) -> void:
	# ward bed: enamel frame on legs, stained mattress, headboard against the wall (+z)
	_box(at + Vector3(0, 0.2, 0), Vector3(0.95, 0.4, 2.0), C.metal)
	_box(at + Vector3(0, 0.47, -0.02), Vector3(0.88, 0.14, 1.92), C.bed)
	_box(at + Vector3(0, 0.55, 0.98), Vector3(0.95, 1.1, 0.05), C.metal)
	_box(at + Vector3(0, 0.45, -0.98), Vector3(0.95, 0.5, 0.05), C.metal)


func _wall(x0: float, z0: float, x1: float, z1: float, holes := []) -> void:
	# axis-aligned wall from (x0,z0) to (x1,z1); holes = [[centre, width, height], ...] in order
	var along_x := is_equal_approx(z0, z1)
	var fixed := z0 if along_x else x0
	var cur := (x0 if along_x else z0) - T / 2
	for h in holes:
		_full(along_x, fixed, cur, h[0] - h[1] / 2)
		_seg(along_x, fixed, h[0] - h[1] / 2, h[0] + h[1] / 2, h[2], H, C.up)  # lintel
		cur = h[0] + h[1] / 2
	_full(along_x, fixed, cur, (x1 if along_x else z1) + T / 2)


func _full(along_x: bool, fixed: float, a: float, b: float) -> void:
	_seg(along_x, fixed, a, b, 0.0, 1.2, C.low)
	_seg(along_x, fixed, a, b, 1.2, H, C.up)


func _seg(along_x: bool, fixed: float, a: float, b: float, y0: float, y1: float, color: Variant) -> void:
	if b - a < 0.01:
		return
	var m := (a + b) / 2
	var pos := Vector3(m, (y0 + y1) / 2, fixed) if along_x else Vector3(fixed, (y0 + y1) / 2, m)
	_box(pos, Vector3(b - a, y1 - y0, T) if along_x else Vector3(T, y1 - y0, b - a), color)


# --- the shortcut and the church -------------------------------------------------------------------------
func _on_bolt(by: Node3D) -> void:
	if by.global_position.z > SHORTCUT.z:  # infirmary side: the bolt is here
		remove_child(shortcut); shortcut.queue_free()  # out of the tree now, or the rebake still sees it
		bolt.enabled = false
		hud.say("Você puxa o ferrolho. A porta para o refeitório está aberta.")
		nav.bake_navigation_mesh(false)  # the mutant can now come this way too
	else:
		hud.say("Trancada. O ferrolho está do outro lado.")


func _process(_delta: float) -> void:
	var r: Array = ROOMS.igreja
	var p := player.global_position
	if not church_told and p.x > r[0] and p.x < r[2] and p.z > r[1] and p.z < r[3]:
		church_told = true
		hud.say("A igreja. A porta é baixa demais para ele.")

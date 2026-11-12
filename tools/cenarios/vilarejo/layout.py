# The village's layout and its ground: roads, square, houses, chapel, cemetery, fields, and the height of
# the terrain anywhere (valley, bumps, the pads levelled under the buildings). Every part reads it.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler, noise
from vila_kit import *  # materials, mesh builder, prop pieces

R = random.Random(1975)  # the village's one random stream (call order = build order)
DOORS = {}  # house name -> its door, local x, and where you stand to go in (local, at the foot of the steps)


# --- layout (Blender XY = Godot X,-Z; +Y is north, towards the Colônia) ----------------------------------
ROADS = [[(0, -90), (0, -50), (-2, -32), (2, -14), (0, 0), (1, 20), (-2, 40), (0, 64)],          # south -> gate
         [(-90, 2), (-40, 3), (-20, 6), (0, 6), (22, 5), (42, 9), (90, 8)]]                  # the lane
SQUARE = (0.0, 6.0, 8.5)  # largo: centre, radius
WALL_Y = 60.0             # the Colônia's wall, north edge of the map
GULLY_Y = -51.5           # the ravine across the south, behind the way in: its bridge has fallen (narrative())
GULLY_DEEP = 7.0          # deep enough that the fall would kill: a fence along its north bank keeps him out (narrative())
RIM = (49.0, 55.0, 8.0)   # the bowl's rim east and west: a steep rocky bank (too steep to walk) from r0 to r1, h high
# houses: x, y, facing (0 = south, 90 = east, -90 = west, 180 = north; = the object's yaw, front is local -Y), width, depth, kind, extras
HOUSES = [
    (-10, -36, 90, 6.0, 5.0, "ruin", {"aula": True}),  # the classroom of the moves (construcoes.AULA)
    (9.5, -30, -90, 6.5, 5.5, "taipa", {"barra": "blue", "shutter": "blue", "chimney": True, "porta": "professora"}),  # Dona Lurdes's:
                                                          # padlocked (Godot: BlockedDoor, Cida's key, docs/CONTEUDO_VILAREJO.md)
    (-9.5, -20, 90, 6.0, 5.0, "wood", {"siding": "grey", "shutter": "green", "porch": True}),
    (10, -15, -88, 7.5, 5.5, "taipa", {"barra": "ochre", "shutter": "green", "porta": "casa_ze",  # the one they took: the trail
                                                                     # starts here; nailed up after (the crowbar: TUTORIAL_VILAREJO.md)
                                       "decais": [("picho_noite", "front", 0, 2.38, 3.6, 0.52, 0.02)]}),
    (-12, -4, 45, 6.0, 5.0, "taipa", {"barra": "oxblood", "shutter": "oxblood", "chimney": True}),
    (13, -1, -90, 6.0, 5.5, "wood", {"siding": "brown", "shutter": "blue", "decais": [("cartaz", "front", 1.9, 1.5, 0.32, 0.4, -0.08)]}),
    (12.5, 13, -90, 8.0, 6.5, "sobrado", {"barra": "green", "shutter": "green", "sign": "venda"}),  # Seu Bento's
    (27, 13.5, 0, 6.5, 5.0, "wood", {"siding": "red", "shutter": "ochre", "porch": True, "sign": "armaria"}),  # Tenório's
    (30, -3, 180, 7.0, 5.5, "taipa", {"barra": "blue", "shutter": "ochre", "chimney": True,
                                      "decais": [("cartaz", "front", 2.6, 1.5, 0.32, 0.4, 0.1), ("cartaz", "front", 2.95, 1.35, 0.32, 0.4, -0.05)]}),
    (41, 16, 5, 5.5, 5.0, "taipa", {"barra": "ochre", "shutter": "blue", "chained": True}),
    (-26, -7, 180, 6.5, 5.0, "wood", {"siding": "grey", "shutter": "oxblood", "burnt": True}),
    (-10, 26, 90, 6.5, 5.5, "taipa", {"barra": "green", "shutter": "green", "chimney": True}),
    (9.5, 31, -92, 6.0, 5.0, "wood", {"siding": "brown", "shutter": "green", "porch": True}),
    (-9, 43, 85, 7.0, 5.5, "taipa", {"barra": "oxblood", "shutter": "blue", "porta": "enfermeira"}),  # the Colônia's nurse's:
                                                          # padlocked (Godot: BlockedDoor, Bastião's key, docs/CONTEUDO_VILAREJO.md)
    (9, 46, -90, 6.0, 5.0, "ruin", {}),
    (43.5, -11, -90, 7.0, 6.0, "taipa", {"barra": "ochre", "shutter": "green", "chimney": True,  # Juca's still: the first
                                        "porta": "alambique", "lado": 0.8}),  # dungeon (TUTORIAL_VILAREJO.md); a side door
]
CHAPEL = (-15.5, 9.0, 90)          # facing the square
# the NPCs (npcs_build.py, placed by vilarejo.gd on these markers): x, y, facing; their stalls stand on flat pads
NPCS = {"benzedeira": (-4.5, 7.0, 0)}  # Tenório and Seu Bento are inside their shops (armaria_build.py, venda_build.py)
CEMETERY = (-31.0, 9.0, 12.0, 15.0)  # centre, size (x, y); gate on its east side, behind the chapel
JAZIGO = (-34.6, 12.8, 90, 3.2, 3.6)   # the Moura family's mausoleum at the back of it, facing the gate: x, y, facing, w, d
FIELDS = [((20, -38), (40, -38), (40, -18), (20, -18)), ((-36, 22), (-20, 22), (-20, 40), (-36, 40))]


def seg_dist(p, a, b):
    ab = b - a; t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (p - (a + ab * t)).length


def road_dist(x, y):
    p = Vector((x, y))
    d = min(seg_dist(p, Vector(a), Vector(b)) for r in ROADS for a, b in zip(r, r[1:]))
    return min(d, (p - Vector(SQUARE[:2])).length - SQUARE[2] + 2.5)


def smooth(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def valley(x, y):  # the bowl and the climb to the Colônia, no bumps; the ravine across the south
    r = (x ** 4 + (y * 0.78 if y > 0 else y) ** 4) ** 0.25  # stretched north: the hill starts past the wall
    rim = (x ** 4 + (y * 0.78 if y > 0 else y * 0.6) ** 4) ** 0.25  # the bank: none south (the ravine closes it), behind the wall north
    return (smooth(46, 78, r) * 18 + RIM[2] * smooth(RIM[0], RIM[1], rim) + 0.04 * y
            - GULLY_DEEP * smooth(4.6, 1.8, abs(y - GULLY_Y)))


def bumps(x, y):
    r = (x ** 4 + y ** 4) ** 0.25
    return noise.fractal(Vector((x * 0.035, y * 0.035, 0.5)), 1.0, 2.0, 3) * (0.7 + 3.5 * smooth(40, 75, r))


def h_road(x, y):
    w = smooth(6.0, 2.5, road_dist(x, y))
    return valley(x, y) + bumps(x, y) * (1 - w) - 0.12 * w


def local(x, y, cx, cy, yaw):
    a = -math.radians(yaw); dx, dy = x - cx, y - cy
    return dx * math.cos(a) - dy * math.sin(a), dx * math.sin(a) + dy * math.cos(a)


PADS = []  # x, y, yaw, half width, half depth, height
for hx, hy, face, w, d, kind, ex in HOUSES:
    PADS.append((hx, hy, face, w / 2 + 0.4, d / 2 + (2.6 if ex.get("porch") else 0.4), h_road(hx, hy)))
PADS.append((CHAPEL[0], CHAPEL[1], CHAPEL[2], 4.0, 9.0, h_road(CHAPEL[0], CHAPEL[1])))
PADS.append((CEMETERY[0], CEMETERY[1], 0, CEMETERY[2] / 2, CEMETERY[3] / 2, h_road(CEMETERY[0], CEMETERY[1])))


def H(x, y):
    h = h_road(x, y)
    for px, py, yaw, hw, hd, ph in PADS:
        lx, ly = local(x, y, px, py, yaw)
        out = math.hypot(max(abs(lx) - hw, 0), max(abs(ly) - hd, 0))
        h += (ph - h) * smooth(4.5, 0.0, out)
    return h

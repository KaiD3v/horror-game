# The crypt under the Moura family's mausoleum, in the cemetery (docs/CHAVE_DO_PORTAO.md): the arena of the village's
# last fight, O Porteiro's. A stair down from the grate, then one round room, 14 m across and 6 m up, read as a boss room:
#   eight stone columns in a ring (cover from what he throws),
#   twelve thick candles on iron stands round the wall (the light of the room: luz_cirio_N; he puts them out at the end),
#   the Moura drawers in the wall, the doctor's coffin open and empty in the middle,
#   the stone altar against the north wall, 2 m high (he climbs up on it; you cannot: the crossbow reaches him there),
#   a box of bolts at the foot of the stair.
# Markers for jazigo.gd: entrada / porta (the grate), escada (the stair's foot: shut once he wakes), virotes, altar,
# caixao, porteiro (where he waits), luz_cirio_N, teto. Frame: the stair comes in from the south, the room's centre at
# CENTRE.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/jazigo_build.py
#   -> blender/cenarios/jazigo.blend, godot_demo/models/levels/jazigo.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("cal", "stone", 0.8, tint=(0.6, 0.58, 0.54))
mat("gaveta", "stone", 1.0, tint=(0.12, 0.11, 0.1))
mat("granito", "stone", 0.6, tint=(0.5, 0.5, 0.48))
mat("wax", "linen", 1.0, tint=(1.05, 0.95, 0.76))
rng = random.Random("jazigo")
TOP = 3.5                                   # the grate's floor, above the room's
STEPS, RISE, RUN = 12, TOP / 12, 0.5
CENTRE = (0.0, 11.5)
R, HT = 7.0, 6.0                            # the room's radius and height
SIDES = 24


def block(b, x0, x1, y0, y1, z0, z1, m):
    bx(b, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0), m)


def marker(name, x, y, z=0.0, yaw=0.0):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = (x, y, z); e.rotation_euler.z = math.radians(yaw)


# --- the landing under the grate and the stair down ---------------------------------------------------------------
s = B()
block(s, -1.5, 1.5, -3.3, -1.5, TOP - 0.3, TOP, "granito")                     # landing
block(s, -1.5, 1.5, -3.6, -3.3, TOP, TOP + 3.0, "cal")                          # its back wall (the way out)
for sx in (-1, 1):
    block(s, sx * 1.2, sx * 1.5, -3.3, CENTRE[1] - R + 0.4, -0.3, TOP + 3.0, "cal")
for i in range(STEPS):
    y0 = -1.5 + RUN * i
    block(s, -1.2, 1.2, y0, y0 + RUN, -0.3, TOP - RISE * (i + 1), "granito")
block(s, -1.5, 1.5, -3.6, CENTRE[1] - R + 0.4, TOP + 3.0, TOP + 3.3, "cal")
obj(s, "escada-col")
door = B()
door.poly([(-0.6, -3.29, TOP), (0.6, -3.29, TOP), (0.6, -3.29, TOP + 2.2), (-0.6, -3.29, TOP + 2.2)], "pit")
obj(door, "grade_fundo")

# --- the round room ------------------------------------------------------------------------------------------------
cx, cy = CENTRE
r = B()
block(r, cx - R - 0.5, cx + R + 0.5, cy - R - 0.5, cy + R + 0.5, -0.3, 0.0, "granito")   # floor
roof = B(); block(roof, cx - R - 0.5, cx + R + 0.5, cy - R - 0.5, cy + R + 0.5, HT, HT + 0.3, "cal")  # ceiling
obj(roof, "teto-col")
for k in range(SIDES):                       # the wall, in panels, a gap to the south for the stair
    a = 2 * math.pi * (k + 0.5) / SIDES
    x, y = cx + math.sin(a) * (R + 0.2), cy - math.cos(a) * (R + 0.2)
    if abs(math.sin(a)) * (R + 0.2) < 1.3 and y < cy:
        continue
    bx(r, (x, y, HT / 2), (2 * math.pi * (R + 0.2) / SIDES + 0.05, 0.4, HT), "cal", rot=(0, 0, a))
obj(r, "cripta-col")
g = B()                                      # the drawers in the wall, three rows, a skull in some
for k in range(SIDES):
    a = 2 * math.pi * (k + 0.5) / SIDES
    if abs(math.sin(a)) * R < 2.0 and math.cos(a) > 0:
        continue  # the stair
    if abs(math.sin(a)) * R < 2.2 and math.cos(a) < 0:
        continue  # behind the altar
    for row in range(3):
        z = 0.5 + row * 0.8
        c = Vector((cx + math.sin(a) * (R - 0.01), cy - math.cos(a) * (R - 0.01), z + 0.22))
        bx(g, c, (1.0, 0.02, 0.45), "gaveta", rot=(0, 0, a))
obj(g, "gavetas")

cols = B()                                   # the ring of columns
for k in range(8):
    a = 2 * math.pi * (k + 0.5) / 8
    x, y = cx + math.sin(a) * 4.6, cy - math.cos(a) * 4.6
    block(cols, x - 0.4, x + 0.4, y - 0.4, y + 0.4, 0, HT, "granito")
    block(cols, x - 0.5, x + 0.5, y - 0.5, y + 0.5, 0, 0.3, "granito")
obj(cols, "colunas-col")

alt = B()                                    # the altar, against the north wall: too high to climb
block(alt, cx - 1.6, cx + 1.6, cy + R - 2.4, cy + R, 0, 2.0, "granito")
block(alt, cx - 1.7, cx + 1.7, cy + R - 2.5, cy + R + 0.1, 2.0, 2.15, "granito")
bx(alt, (cx, cy + R - 0.2, 3.4), (0.12, 0.1, 2.2), "iron"); bx(alt, (cx, cy + R - 0.2, 4.0), (1.0, 0.1, 0.12), "iron")
obj(alt, "altar-col")

cof = B()                                    # the doctor's coffin, open and empty
block(cof, cx - 0.45, cx + 0.45, cy - 1.1, cy + 1.1, 0, 0.12, "granito")
for x0, x1, y0, y1 in ((-0.45, -0.37, -1.1, 1.1), (0.37, 0.45, -1.1, 1.1), (-0.45, 0.45, -1.1, -1.02), (-0.45, 0.45, 1.02, 1.1)):
    block(cof, cx + x0, cx + x1, cy + y0, cy + y1, 0.12, 0.7, "planks")
block(cof, cx - 0.37, cx + 0.37, cy - 1.02, cy + 1.02, 0.12, 0.14, "pit")
bx(cof, (cx + 1.0, cy + 0.2, 0.1), (0.95, 2.2, 0.06), "planks", rot=(0.1, 0.2, 0.25))   # its lid, thrown off
obj(cof, "caixao-col")

stands = B()                                 # twelve iron stands, thick candles on them
for k in range(12):
    a = 2 * math.pi * (k + 0.5) / 12
    x, y = cx + math.sin(a) * (R - 0.7), cy - math.cos(a) * (R - 0.7)
    if y < cy - R + 1.6:
        continue
    frustum(stands, (x, y, 0), (x, y, 1.25), 0.04, 0.03, 6, "iron", caps=True)
    frustum(stands, (x, y, 1.25), (x, y, 1.3), 0.14, 0.14, 8, "iron", caps=True)
    frustum(stands, (x, y, 1.3), (x, y, 1.6), 0.06, 0.055, 8, "wax", caps=True)
    marker("luz_cirio_%02d" % k, x, y, 1.75)
obj(stands, "cirios")

marker("entrada", 0.0, -2.6, TOP)            # in at the grate, facing down the stair (+Y)
marker("porta", 0.0, -3.1, TOP)
marker("escada", 0.0, CENTRE[1] - R + 0.3)   # the foot of the stair: a fall of stone shuts it once he wakes
marker("virotes", 1.6, CENTRE[1] - R + 1.0)
marker("altar", cx, cy + R - 1.2, 2.15)      # where he stands to throw
marker("caixao", cx, cy)
marker("porteiro", cx, cy + 3.0, 0.0, 180)   # where he waits, his back to the coffin, facing the stair

tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH" for p in o.data.polygons)
print("JAZIGO objects=%d tris~%d" % (len(bpy.data.objects), tris))
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "jazigo"))
bpy.ops.export_scene.gltf(filepath=paths.level("jazigo"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)

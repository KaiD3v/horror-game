# The ossuary under Santa Clara's chapel, the second dungeon (docs/TUTORIAL_VILAREJO.md "Dungeon 2"): the crossbow's.
# One long way north from the sacristy, underground, every part a move:
#   the stairs     down from the sacristy door (a landing, an oratório on it): Tenório's spilled bolts on the steps;
#   the gallery    of drawers (niches full of bones along both walls), the floor strewn with bones: standing, every step
#                  cracks (Godot: ossuario.gd, the sleeper's breath rises with it); crouched, hardly a sound;
#   the chamber    where Tenório dropped the crossbow; across it a cut 4 m wide, 1.5 m down (too wide to jump), and on its
#                  far side a plank standing on end, held by a rope to a ring in the wall (Godot: shoot the rope, the plank
#                  falls across: the bridge);
#   the cistern    under the square's well: shallow water, the sleeper (O Poceiro by day) between you and the rope that
#                  goes up the shaft; bottles hanging on the walls (a bolt in one makes a noise over there); in the north
#                  wall, a tunnel towards the Colônia, fallen in (the pickaxe, later), and Joaquim's scapular by it.
# Frame: the landing at the south end, the way runs to +Y. Markers for ossuario.gd: entrada / porta (the sacristy's),
# entrada_poco / corda (the rope up the well), virotes, besta, ponte (the plank's hinge), argola (the rope's ring),
# garrafa_<n>, poceiro, tunel, escapulario, luz_*, teto.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/ossuario_build.py
#   -> blender/cenarios/ossuario.blend, godot_demo/models/levels/ossuario.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("cal", "stone", 0.8, tint=(0.62, 0.6, 0.55))
mat("gaveta", "stone", 1.0, tint=(0.12, 0.11, 0.1))
mat("sangue", "mud", 1.0, "top", tint=(0.35, 0.06, 0.05))
mat("agua", "mud", 2.0, "top", tint=(0.12, 0.14, 0.15))
rng = random.Random("ossuario")
TOP = 3.0                                          # the landing, under the sacristy
STEPS, RISE, RUN = 10, 0.3, 0.5
GAL = (-1.5, 1.5, 3.5, 15.0, 3.2)                  # x0, x1, y0, y1, height: the gallery of drawers
CUT = (18.0, 22.0, 1.5)                             # y0, y1, depth: the cut across the chamber
CIS = (-6.0, 6.0, 26.0, 38.0, 6.0)                  # the cistern
SHAFT = (0.0, 35.5)                                 # the well shaft over the cistern


def block(b, x0, x1, y0, y1, z0, z1, m):
    bx(b, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0), m)


def marker(name, x, y, z=0.0, yaw=0.0):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = (x, y, z); e.rotation_euler.z = math.radians(yaw)


def room(b, x0, x1, y0, y1, z0, h, open_s=None, open_n=None, floor="mud", wall="rock"):
    """Floor, ceiling and four walls of a box; open_s / open_n: (x0, x1) gaps in the south / north wall."""
    t = 0.3
    block(b, x0 - t, x1 + t, y0 - t, y1 + t, z0 - 0.3, z0, floor)
    block(b, x0 - t, x1 + t, y0 - t, y1 + t, z0 + h, z0 + h + 0.3, wall)
    for xs in ((x0 - t, x0), (x1, x1 + t)):
        block(b, xs[0], xs[1], y0, y1, z0, z0 + h, wall)
    for y, gap in ((y0, open_s), (y1, open_n)):
        ys = (y - t, y) if y == y0 else (y, y + t)
        if gap is None:
            block(b, x0 - t, x1 + t, ys[0], ys[1], z0, z0 + h, wall)
        else:
            block(b, x0 - t, gap[0], ys[0], ys[1], z0, z0 + h, wall)
            block(b, gap[1], x1 + t, ys[0], ys[1], z0, z0 + h, wall)


# --- the landing and the stairs down ----------------------------------------------------------------------------
s = B()
room(s, -1.2, 1.2, -4.0, -1.5, TOP, 3.0, open_n=(-1.2, 1.2), floor="stone", wall="cal")
for i in range(STEPS):                              # each step a solid block down to the floor
    y0 = -1.5 + RUN * i
    block(s, -1.2, 1.2, y0, y0 + RUN, -0.3, TOP - RISE * (i + 1), "stone")
for sx in (-1, 1):                                  # the stairwell's walls and its sloping roof
    block(s, sx * 1.2, sx * 1.5, -1.5, GAL[2], -0.3, TOP + 3.0, "cal")
block(s, -1.5, 1.5, -1.5, GAL[2], TOP + 3.0, TOP + 3.3, "cal")
obj(s, "escada-col")
door = B()
door.poly([(-0.45, -3.98, TOP), (0.45, -3.98, TOP), (0.45, -3.98, TOP + 2.05), (-0.45, -3.98, TOP + 2.05)], "door")
obj(door, "porta_sacristia")

# --- the gallery of drawers -----------------------------------------------------------------------------------------
g = B()
x0, x1, y0, y1, h = GAL
room(g, x0, x1, y0, y1, 0, h, open_s=(x0, x1), open_n=(x0, x1), wall="cal")
obj(g, "galeria-col")
d = B()                                             # the drawers: dark holes in rows, bones and skulls showing
for sx in (-1, 1):
    for row in range(3):
        z = 0.35 + row * 0.85
        y = y0 + 0.4
        while y < y1 - 0.6:
            xf = sx * (x1 - 0.005)
            d.poly([(xf, y, z), (xf, y + 0.55, z), (xf, y + 0.55, z + 0.5), (xf, y, z + 0.5)][:: -sx], "gaveta")
            if rng.random() < 0.55:
                bx(d, (xf - sx * 0.06, y + 0.27, z + 0.1), (0.1, 0.16, 0.14), "osso")          # a skull in it
            y += 0.75
for _ in range(90):                                 # the floor of bones (no collision: they only crack)
    x, y = rng.uniform(x0 + 0.2, x1 - 0.2), rng.uniform(y0, y1)
    bx(d, (x, y, 0.025), (0.04, rng.uniform(0.18, 0.4), 0.04), "osso", rot=(0, 0, rng.uniform(0, 3.2)))
obj(d, "gavetas")

# --- the chamber, the cut across it, the passage to the cistern ----------------------------------------------------
cy0, cy1, cd = CUT
c = B()                                             # (built by hand, not room(): its floor has the cut in it)
t = 0.3
block(c, -3.3, 3.3, GAL[3] - t, cy0, -0.3 - cd, 0, "mud")                # near floor (solid down into the cut)
block(c, -3.3, 3.3, cy1, 24.0 + t, -0.3 - cd, 0, "mud")                  # far floor
block(c, -3.3, 3.3, cy0, cy1, -0.3 - cd, -cd, "pit")                     # the bottom of the cut
block(c, -3.3, 3.3, GAL[3] - t, 24.0 + t, 4.5, 4.8, "rock")              # ceiling
for xs in ((-3.3, -3.0), (3.0, 3.3)):
    block(c, xs[0], xs[1], GAL[3], 24.0, -cd, 4.5, "rock")
for y, ys in ((GAL[3], (GAL[3] - t, GAL[3])), (24.0, (24.0, 24.0 + t))):
    block(c, -3.3, -1.5, ys[0], ys[1], 0, 4.5, "rock"); block(c, 1.5, 3.3, ys[0], ys[1], 0, 4.5, "rock")
block(c, -3.0, 3.0, cy0 - 0.01, cy0 + 0.01, -0.12, 0.0, "whitewash")    # chalk on the near edge: up out of the cut
obj(c, "camara-col")
p = B()
room(p, -1.5, 1.5, 24.0, CIS[2], 0, 3.2, open_s=(-1.5, 1.5), open_n=(-1.5, 1.5))
obj(p, "passagem-col")
mark = B()
block(mark, -2.6, -1.4, 16.0, 16.9, 0.0, 0.012, "sangue")              # where Tenório fell
block(mark, 2.9, 3.0, 21.35, 21.65, 3.45, 3.75, "iron")                 # the ring in the east wall (the rope runs across
                                                                       # in plain sight from the near side)
obj(mark, "marcas")

# --- the cistern ----------------------------------------------------------------------------------------------------
w = B()
x0, x1, y0, y1, h = CIS
room(w, x0, x1, y0, y1, 0, h, open_s=(-1.5, 1.5), floor="stone", wall="rock")
obj(w, "cisterna-col")
hole = B()                                          # the shaft: a dark disc in the ceiling, its stone ring
frustum(hole, (SHAFT[0], SHAFT[1], h - 0.02), (SHAFT[0], SHAFT[1], h + 0.02), 1.0, 1.0, 12, "pit", caps=True)
frustum(hole, (SHAFT[0], SHAFT[1], h - 0.4), (SHAFT[0], SHAFT[1], h), 1.15, 1.15, 12, "stone")
block(hole, x0 + 0.2, x1 - 0.2, y0 + 0.2, y1 - 0.2, 0.0, 0.06, "agua")  # a skin of water over the floor
for gx, gy in ((-5.85, 33.0), (5.85, 28.5)):        # the pegs the bottles hang from
    block(hole, gx - 0.15, gx + 0.15, gy - 0.03, gy + 0.03, 2.3, 2.36, "planks")
obj(hole, "poco_fundo")

# --- markers -------------------------------------------------------------------------------------------------------
marker("entrada", 0.0, -3.3, TOP)                    # in from the sacristy, facing down the stairs (+Y)
marker("porta", 0.0, -3.8, TOP)                      # E: back up into the chapel
marker("virotes", 0.4, 0.75, TOP - RISE * 5)         # on the sixth step
marker("besta", -2.0, 16.45, 0.0, 30)
marker("ponte", 0.0, CUT[1], 0.0)                    # the plank's hinge, on the far edge
marker("argola", 2.95, 21.5, 3.6)
marker("garrafa_1", -5.85, 33.0, 1.9); marker("garrafa_2", 5.85, 28.5, 1.9)
marker("poceiro", 0.0, 33.0, 0.0, 180)               # asleep, his face to the way in (10 m on: a jog over the plank does not reach him)
marker("corda", SHAFT[0], SHAFT[1], 0.0)
marker("entrada_poco", 0.6, SHAFT[1] - 0.9, 0.0, 180)  # down the rope from the square, facing back south
marker("tunel", 4.0, 37.8, 0.0)                      # Breakable "entulho": its front to the south
marker("escapulario", 2.9, 36.9, 0.0)
marker("luz_vela", 0.9, -3.6, TOP + 1.2)             # the oratório's candle on the landing
marker("luz_janela", SHAFT[0], SHAFT[1], CIS[4] - 0.5)  # the day down the shaft
marker("luz_vela_2", -2.4, 16.0, 0.3)                # Tenório's candle stub, burnt low

tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH" for p in o.data.polygons)
print("OSSUARIO objects=%d tris~%d" % (len(bpy.data.objects), tris))
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "ossuario"))
bpy.ops.export_scene.gltf(filepath=paths.level("ossuario"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)

# Juca's still (casa_16 in the village, the alambique), the first dungeon (docs/TUTORIAL_VILAREJO.md "Dungeon 1"): the
# interior as its own scene. One tall room (14 x 10 m, 8 m up) read as a route, each part a move:
#   the floor     you come in by the side door (the front one is shored up from inside with cane: the machete, later);
#                 a granite block to push (Godot: Pushable on "pedra") under the loft;
#   the loft      2 m up along the left wall (Climbable from the block's top), then the walkway of barrels along the
#                 back wall, bats under the roof over it (Godot: Morcegos on "morcegos");
#   the gap       over the vinhoto tank, a jump to the platform by the tower (Jumpable);
#   the tower     the furnace's brick mass, 5.5 m: its face from the platform is a stone wall with holds (puzzle.glb
#                 "muro" on "muro"), up to Juca's corner on top: his cot, his lamp, the trunk with the machete, his diary.
# Markers for alambique.gd: entrada / porta (the side door), entrada_frente / porta_frente (the front one), cana, pedra,
# muro, morcegos, atadura, luz_*. Interior frame as vila_kit.Room: front wall at -Y (the front door), floor z = 0.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/alambique_build.py
#   -> blender/cenarios/alambique.blend, godot_demo/models/levels/alambique.glb, renders/cenarios/alambique_corte.png
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("cobre", "machine", 1.0, tint=(0.95, 0.52, 0.3))
mat("tijolo", "stone", 0.6, tint=(0.78, 0.46, 0.34))
mat("cana", "burlap", 1.0, tint=(0.85, 0.78, 0.5))
rng = random.Random("alambique")
WX, WY, HT = 7.0, 5.0, 8.0
LOFT = 2.0                  # the loft, the walkway and the platform: 2 m (too high to haul up onto from the floor)
TOWER = LOFT + 3.5          # the tower's top: the platform + the wall with holds (puzzle_build.py muro, 3.5 m)
R_ = Room(WX, WY, HT)


def block(b, x0, x1, y0, y1, z0, z1, m):
    bx(b, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0), m)


def marker(name, x, y, z=0.0, yaw=0.0):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = (x, y, z); e.rotation_euler.z = math.radians(yaw)


# --- the room: earth floor, whitewash over an ochre band, the front door (shored up), the side door painted -----------
room = B()
R_.shell(room, "whitewash", door_w=1.2, floor="mud",
         windows=(("back", -2.0, 3.2, 1.0), ("back", 2.2, 3.2, 1.0), ("right", 2.5, 6.0, 1.0)))
R_.dado(room, "barra_ochre", h=0.8, door_w=1.2)
R_.quad(room, "left", -3.95, -3.05, 0, 2.05, "door")                   # the side door you came in by
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, beams=(-3.0, -1.0, 1.0, 3.0)); obj(roof, "teto-col")

# --- the loft along the left wall and the walkway along the back, on posts, boards on top --------------------------
loft = B()
block(loft, -WX, -4.5, -1.0, WY, 0, LOFT, "planks")                    # the loft (solid: sacks and firewood under it)
block(loft, -4.5, 1.0, 3.0, WY, 0, LOFT, "planks")                     # the walkway of barrels
for x0, x1, y0, y1 in ((-4.5, -4.42, -1.0, 3.0), (-4.5, 1.0, 2.92, 3.0)):  # the edges you climb or jump from: chalk
    block(loft, x0 - 0.01, x1 + 0.01, y0 - 0.01, y1 + 0.01, LOFT - 0.1, LOFT + 0.005, "whitewash")
for x in (-4.4, -2.0, 0.9):                                            # posts down the walkway's face
    block(loft, x - 0.08, x + 0.08, 2.84, 2.98, 0, LOFT, "fence")
block(loft, -4.48, -4.36, -0.98, -0.82, 0, LOFT, "fence")            # (one post only: the block's way along it stays clear)
obj(loft, "jirau-col")
kegs = B()
for x in (-4.0, -3.2, -1.2, -0.4):                                     # barrels against the back wall, on the walkway
    merge(kegs, k_barril(), x, WY - 0.38, LOFT, rng.uniform(0, 360))
obj(kegs, "barris-col")

# --- the vinhoto tank under the gap: a low brick rim, the dark sludge in it --------------------------------------------
tank = B()
for x0, x1, y0, y1 in ((1.0, 3.5, 2.4, 2.58), (1.0, 1.18, 2.4, WY)):
    block(tank, x0, x1, y0, y1, 0, 0.45, "tijolo")
block(tank, 1.18, 3.5, 2.58, WY, 0, 0.22, "pit")
obj(tank, "tanque-col")

# --- the platform and the tower (the furnace's brick mass); the copper still in front of it --------------------------
tower = B()
block(tower, 3.5, WX, 0.0, WY, 0, LOFT, "tijolo")                      # the platform by the tower
block(tower, 3.5, WX, -WY, 0.0, 0, TOWER, "tijolo")                    # the tower
block(tower, 3.42, 3.5, -3.2, -1.8, 0.3, 1.1, "pit")                   # the furnace's mouth, cold...
block(tower, 3.41, 3.5, -2.9, -2.1, 0.32, 0.5, "ember")                # ...but for a last ember
for x0, x1, y0, y1 in ((3.5, 3.65, -WY, 0.0), (3.5, 4.25, -0.15, 0.0), (6.25, WX, -0.15, 0.0)):  # rail round the top,
    block(tower, x0, x1, y0, y1, TOWER, TOWER + 0.95, "planks")        # open over the wall with holds
obj(tower, "torre-col")
still = B()
frustum(still, (2.3, -2.5, 0), (2.3, -2.5, 1.0), 0.62, 0.66, 10, "cobre", caps=True)          # the pot
frustum(still, (2.3, -2.5, 1.0), (2.3, -2.5, 1.45), 0.66, 0.2, 10, "cobre", caps=True)        # its dome
frustum(still, (2.3, -2.5, 1.45), (2.3, -2.5, 2.3), 0.12, 0.1, 6, "cobre", caps=True)         # the helmet
frustum(still, (2.3, -2.5, 2.3), (3.5, -2.5, 3.1), 0.08, 0.06, 6, "cobre", caps=True)         # the swan neck, into the wall
frustum(still, (2.3, -2.5, -0.05), (2.3, -2.5, 0.05), 0.75, 0.75, 10, "tijolo", caps=True)    # its brick seat
obj(still, "alambique-col")

# --- the cane press in the middle of the floor, cane lying about ------------------------------------------------------
press = B()
for x in (-0.4, 0.4):
    frustum(press, (x - 1.0, -1.6, 0), (x - 1.0, -1.6, 1.1), 0.22, 0.22, 8, "planks", caps=True)
block(press, -1.8, -0.2, -1.75, -1.45, 1.1, 1.3, "planks")
block(press, -1.06, -0.94, -1.65, -1.55, 1.3, 2.4, "planks")
block(press, -2.8, 0.8, -1.64, -1.56, 2.3, 2.4, "planks")                # the sweep the ox turned
obj(press, "moenda-col")
loose = B()
for _ in range(14):
    x, y = rng.uniform(-3.8, 1.4), rng.uniform(-4.6, 2.4)
    if abs(x) < 1.0 and y < -3.0 or (-2.6 < x < -1.4 and 0.8 < y < 2.2) or (x < -3.2 and y < -2.6):
        continue  # clear of the front door, the block and the way in
    bx(loose, (x, y, 0.03), (0.05, 1.6, 0.05), "cana", rot=(0, 0, rng.uniform(0, 3)))
obj(loose, "cana_solta")

# --- Juca's corner on the tower: his cot, a crate, his lamp (still lit) ----------------------------------------------
juca = B()
block(juca, 5.9, 6.85, -4.85, -2.95, TOWER, TOWER + 0.35, "planks")      # the cot
block(juca, 5.95, 6.8, -4.8, -3.0, TOWER + 0.35, TOWER + 0.45, "cloth_red")
block(juca, 3.8, 4.4, -4.85, -4.25, TOWER, TOWER + 0.5, "barrel")         # a crate with the lamp on it
obj(juca, "quarto-col")
lamp = B()
frustum(lamp, (4.1, -4.55, TOWER + 0.5), (4.1, -4.55, TOWER + 0.54), 0.07, 0.06, 6, "iron", caps=True)
frustum(lamp, (4.1, -4.55, TOWER + 0.54), (4.1, -4.55, TOWER + 0.68), 0.045, 0.04, 6, "lampglass", caps=True)
obj(lamp, "lamparina_juca")

# --- markers -------------------------------------------------------------------------------------------------------
marker("entrada", -6.2, -3.5, 0, -90)             # in by the side door, facing into the room
marker("porta", -6.6, -3.5)                        # E: back out of the side door
marker("entrada_frente", 0.0, -2.9)                # in by the front door (once the cane is cut), facing in
marker("porta_frente", 0.0, -4.35)
marker("cana", 0.0, -3.85, 0, 180)                 # Breakable "cana": its front towards the room
marker("pedra", -2.0, 1.5)                         # Pushable: two pushes west and it stands under the loft's edge
marker("muro", 5.25, 0.0, LOFT, 180)               # the wall with holds, its face to the platform
marker("morcegos", -2.0, 4.0, HT - 1.3)            # where the bats hang
marker("atadura", 4.6, 3.6, LOFT)                  # a bandage on the platform, after the bats
marker("luz_fogao", 3.2, -2.5, 0.5)
marker("luz_janela", -2.0, WY - 0.4, 3.7); marker("luz_janela_2", 2.2, WY - 0.4, 3.7); marker("luz_janela_3", WX - 0.4, 2.5, 6.5)
marker("luz_lamparina", 4.1, -4.55, TOWER + 0.8)

tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH" for p in o.data.polygons)
print("ALAMBIQUE objects=%d tris~%d" % (len(bpy.data.objects), tris))
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "alambique"))
bpy.ops.export_scene.gltf(filepath=paths.level("alambique"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)

# --- preview: cutaway from above the front wall, the ceiling hidden -------------------------------------------------
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x, sc.render.resolution_y = 1280, 800
sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.08, 0.08, 0.09)
for name, loc, power in (("l1", (0, 0, 7), 900), ("l2", (5, -2.5, 7.5), 300)):
    L = bpy.data.objects.new(name, bpy.data.lights.new(name, "POINT")); sc.collection.objects.link(L)
    L.location = loc; L.data.energy = power
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
bpy.data.objects["teto-col"].hide_render = True
cam.location = (0, -7, 21); cam.data.lens = 20
cam.rotation_euler = (Vector((0, 0.5, 1.0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = paths.render("cenarios", "alambique_corte.png")
bpy.ops.render.render(write_still=True)

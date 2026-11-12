# The chapel's bell tower, inside (docs/CONTEUDO_VILAREJO.md "O sino da capela"): its own scene, Zelda style
# (vila_kit.Room), through the little door in the chapel's front wall. A tall shaft of old whitewash over stone; the
# ladder that went up it lies broken on the floor. The way up is two moves the village has already taught:
#   the stone counterweight (Pushable "pedra", Godot) pushed north once, under the first landing's chalked edge (2.4 m),
#   and up from its top; then the wall with holds (puzzle.glb "muro", Godot) on the landing, 3.5 m, to the top floor,
#   where a short ladder goes up to the trapdoor: the belfry (the village scene, its tower top).
# The rotten bell rope hangs down the middle from the trapdoor, broken off halfway.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/torre_build.py
#   -> blender/cenarios/torre.blend, godot_demo/models/levels/torre.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

rng = random.Random("torre")
WX, WY, HT = 2.2, 2.2, 8.4
LAND, LAND_Y = 2.4, 0.5      # the first landing: its top, its front edge (it runs back to the wall)
TOP, WALL_Y = 5.9, 1.2       # the top floor (= LAND + the muro's 3.5), where the muro's face stands
R_ = Room(WX, WY, HT)

room = B()
R_.shell(room, "whitewash", door_w=1.0, windows=(("left", 0.0, 3.4, 0.9), ("right", -0.6, 6.4, 0.8)))
R_.dado(room, "stone", h=1.2, door_w=1.0)
for k in range(10):  # damp running down the whitewash
    side = rng.choice(("left", "right", "back")); o, u, n = R_.side(side, 0.013)
    c = o + u * rng.uniform(-1.8, 1.8) + Z * rng.uniform(1.6, 6.5)
    bx(room, c, (0.3, 0.01, rng.uniform(0.8, 2.0)) if abs(u.x) > 0.5 else (0.01, 0.3, rng.uniform(0.8, 2.0)), "pit")
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, beams=(), hole=(-1.6, -0.6, 1.2, 2.2)); obj(roof, "teto-col")

s = B()
bx(s, (0, (LAND_Y + WY) / 2, LAND / 2), (2 * WX, WY - LAND_Y, LAND), "stone")              # the first landing
bx(s, (-WX / 2, (WALL_Y + WY) / 2, TOP - 0.08), (WX, WY - WALL_Y, 0.16), "planks")         # the top floor (west of the muro)
for x in (-2.0, -0.2):                                                                      # its beams into the wall
    bx(s, (x, (WALL_Y + WY) / 2, TOP - 0.25), (0.14, WY - WALL_Y, 0.2), "planks")
obj(s, "moveis-col")

t = B()
bx(t, (0, LAND_Y - 0.005, LAND - 0.06), (2 * WX - 0.1, 0.012, 0.1), "whitewash")            # the chalked edge (cal riscada)
for k in range(9):
    bx(t, (-1.9 + 0.45 * k, LAND_Y - 0.008, LAND - 0.2), (0.03, 0.012, 0.22), "whitewash", rot=(0, 0.3, 0))
for i in range(2):                                                                          # the broken ladder on the floor
    for sx in (-0.22, 0.22):
        bx(t, (0.6 + sx + i * 0.05, -0.9 - i * 0.2, 0.05 + 0.1 * i), (0.06, 1.6, 0.06), "planks",
           rot=(0.06 * i, 0, math.radians(35 + 20 * i)))
for k in range(5):
    bx(t, (0.6 + rng.uniform(-0.6, 0.6), -1.0 + rng.uniform(-0.7, 0.7), 0.03), (0.45, 0.05, 0.04), "planks",
       rot=(0, 0, rng.uniform(0, math.pi)))
for k in range(7):                                                                          # the short ladder to the trapdoor
    bx(t, (-1.1, 1.85, TOP + 0.25 + 0.36 * k), (0.6, 0.05, 0.05), "planks")
for sx in (-1.4, -0.8):
    bx(t, (sx, 1.85, TOP + 1.25), (0.06, 0.06, 2.5), "planks")
bx(t, (-1.1, 1.7, HT + 0.02), (1.0, 1.0, 0.05), "planks")                                   # the trapdoor, propped open
frustum(t, (0, 0, HT), (0, 0, 3.4), 0.02, 0.02, 4, "burlap")                                # the rope, rotted through
for k in range(4):
    frustum(t, (0, 0, 3.4), (rng.uniform(-0.06, 0.06), rng.uniform(-0.06, 0.06), 3.15), 0.008, 0.004, 3, "burlap")
for k in range(6):                                                                          # pigeons' mess
    bx(t, (rng.uniform(-1.8, 1.8), rng.uniform(-1.9, 0.3), 0.004), (rng.uniform(0.1, 0.3), rng.uniform(0.1, 0.3), 0.006), "whitewash")
obj(t, "objetos")

for name, loc, yaw in (("entrada", (0, -1.7, 0), 0), ("porta", (0, -WY, 0), 0), ("pedra", (-1.0, -1.0, 0), 0),
                       ("muro", (1.0, WALL_Y, LAND), 0), ("alcapao", (-1.1, 1.5, TOP), 0),
                       ("entrada_campanario", (-1.1, 1.45, TOP), 180),
                       ("luz_janela", (-WX + 0.4, 0.0, 3.8), 0), ("luz_janela_b", (WX - 0.4, 0.6, 6.7), 0),
                       ("luz_vela", (-1.6, -1.8, 0.6), 0), ("luz_vela_b", (-1.8, 1.0, TOP + 0.3), 0)):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = loc; e.rotation_euler.z = math.radians(yaw)

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "torre"))
bpy.ops.export_scene.gltf(filepath=paths.level("torre"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)
print("TORRE ok")

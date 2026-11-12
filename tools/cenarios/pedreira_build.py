# The quarry's gallery (docs/CONTEUDO_VILAREJO.md "A pedreira"): behind the rubble at the mouth in the east bank (the
# pickaxe), a short gallery cut into the rock, shored with timber, running back to a chamber the Colônia used as a store:
# crates stencilled FRÁGIL, a rack of glass vials (the serum, R-4), a table with the inventory, and a brazier with its
# embers still warm (someone keeps it: the smoke seen from the belfry). Same kit as the other rooms. Godot: pedreira.gd.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/pedreira_build.py
#   -> blender/cenarios/pedreira.blend, godot_demo/models/levels/pedreira.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("vial", "window_in", 1.0, tint=(0.95, 0.35, 0.3)); mat("brasa", "mud", 1.0, tint=(1.6, 0.5, 0.2))
rng = random.Random("pedreira")
WX, WY, HT = 1.4, 5.0, 2.5
R_ = Room(WX, WY, HT)

room = B()
R_.shell(room, "rock", door_w=1.4, floor="mud")
for k in range(10):                                          # the rock face, rough: blocks jutting from the walls
    side = rng.choice(("left", "right")); o, u, n = R_.side(side)
    bx(room, o + u * rng.uniform(-4.5, 4.5) + Z * rng.uniform(0.3, 2.2) + n * 0.08, (0.2, rng.uniform(0.4, 0.9), rng.uniform(0.3, 0.7)), "rock")
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, beams=()); obj(roof, "teto-col")

f = B()
for y in (-3.0, -1.0, 1.0):                                   # timber shoring: two posts and a cap
    for sx in (-1, 1):
        bx(f, (sx * (WX - 0.12), y, HT / 2), (0.16, 0.16, HT), "planks")
    bx(f, (0, y, HT - 0.1), (2 * WX, 0.18, 0.18), "planks")
for k, (x, y) in enumerate(((-0.8, 3.6), (-0.75, 4.4), (0.85, 4.3))):   # the crates
    bx(f, (x, y, 0.25 + (0.5 if k == 1 else 0)), (0.6, 0.5, 0.5), "planks", rot=(0, 0, rng.uniform(-0.15, 0.15)))
bx(f, (0.85, 2.6, 0.72), (0.9, 0.55, 0.05), "planks")         # the table
for sx in (-1, 1):
    for sy in (-1, 1):
        bx(f, (0.85 + sx * 0.38, 2.6 + sy * 0.22, 0.36), (0.05, 0.05, 0.72), "planks")
frustum(f, (-0.7, 2.2, 0), (-0.7, 2.2, 0.45), 0.25, 0.3, 8, "iron", caps=True)   # the brazier
obj(f, "moveis-col")

t = B()
bx(t, (-0.7, 2.2, 0.46), (0.4, 0.4, 0.04), "brasa")
for k in range(12):                                           # vials on the table, in their rack
    frustum(t, (0.55 + 0.06 * (k % 6), 2.55 + 0.1 * (k // 6), 0.75), (0.55 + 0.06 * (k % 6), 2.55 + 0.1 * (k // 6), 0.86), 0.015, 0.015, 5, "vial", caps=True)
bx(t, (0.7, 2.6, 0.75), (0.42, 0.25, 0.02), "planks")
for x, y in ((-0.8, 3.6), (0.85, 4.3)):                       # FRÁGIL on the crates
    bx(t, (x, y - 0.255, 0.3), (0.36, 0.01, 0.1), "whitewash")
obj(t, "objetos")

for name, loc, yaw in (("entrada", (0, -4.2, 0), 0), ("porta", (0, -WY, 0), 0),
                       ("luz_fogao", (-0.7, 2.2, 0.6), 0), ("luz_lamparina", (0.85, 2.6, 1.2), 0)):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = loc; e.rotation_euler.z = math.radians(yaw)

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "pedreira"))
bpy.ops.export_scene.gltf(filepath=paths.level("pedreira"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)
print("PEDREIRA ok")

# Zé's house (casa_04 in the village, the one they took: docs/VILAREJO.md "Narrativa ambiental"), nailed up from outside
# after; the crowbar opens it (docs/TUTORIAL_VILAREJO.md "O vilarejo se abre"). A small room as its own scene: the bed
# pulled across the window, the table with his last note, a chair knocked over, the windows boarded from inside, the
# oratório on the wall, scratches on the inside of the door. Same kit as the other rooms. Godot: interior.gd.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/casa_ze_build.py
#   -> blender/cenarios/casa_ze.blend, godot_demo/models/levels/casa_ze.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("saint", "cloth", 1.0, tint=(0.9, 0.74, 0.62))
rng = random.Random("casa_ze")
WX, WY, HT = 3.0, 2.5, 2.8
R_ = Room(WX, WY, HT)

room = B()
R_.shell(room, "whitewash", door_w=1.0, windows=(("left", 0.4), ("right", -0.6)))
R_.dado(room, "barra_ochre", h=0.8, door_w=1.0)
for x, y, yaw in ((-WX + 0.06, 0.4, 90), (WX - 0.06, 0.6, 90)):    # boards over the windows from inside (the right wall runs -Y)
    for k in range(3):
        bx(room, (x, y, 1.25 + k * 0.35), (0.04, 1.2, 0.14), "planks", rot=(0.08 * (k - 1), 0, 0))
for k in range(9):                                                 # scratches on the inside of the door
    bx(room, (-0.35 + 0.08 * k, -WY + 0.02, 0.9 + rng.uniform(0, 0.5)), (0.012, 0.004, rng.uniform(0.25, 0.5)), "pit",
       rot=(0, rng.uniform(-0.2, 0.2), 0))
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, beams=(-1.2, 0.0, 1.2)); obj(roof, "teto-col")

f = B()
bx(f, (-2.1, 1.4, 0.25), (1.6, 1.9, 0.5), "planks", rot=(0, 0, math.radians(-12)))  # the bed, dragged askew
bx(f, (-2.1, 1.4, 0.53), (1.5, 1.8, 0.06), "cloth_white", rot=(0, 0, math.radians(-12)))
bx(f, (-0.4, 0.3, 0.74), (1.1, 0.7, 0.05), "planks")                                 # the table
for sx in (-1, 1):
    for sy in (-1, 1):
        bx(f, (-0.4 + sx * 0.48, 0.3 + sy * 0.28, 0.36), (0.05, 0.05, 0.72), "planks")
bx(f, (0.55, -0.6, 0.22), (0.42, 0.42, 0.04), "planks", rot=(math.radians(80), 0, 0.4))  # a chair on its back
bx(f, (WX - 0.2, 1.0, 1.4), (0.3, 0.5, 0.04), "planks")                             # the oratório's shelf
bx(f, (WX - 0.22, 1.0, 1.6), (0.18, 0.12, 0.36), "saint")
obj(f, "moveis-col")

for name, loc, yaw in (("entrada", (0, -1.7, 0), 0), ("porta", (0, -WY, 0), 0), ("luz_janela", (-WX + 0.4, 0.4, 1.6), 0),
                       ("luz_janela_b", (WX - 0.4, 0.6, 1.6), 0), ("luz_vela", (WX - 0.3, 1.0, 1.55), 0),
                       ("luz_lamparina", (-0.4, 0.3, 1.1), 0)):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = loc; e.rotation_euler.z = math.radians(yaw)

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "casa_ze"))
bpy.ops.export_scene.gltf(filepath=paths.level("casa_ze"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)
print("CASA_ZE ok")

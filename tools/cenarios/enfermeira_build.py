# The nurse's house (casa_14 in the village, by the gate: docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"): Dalva,
# the Colônia's nurse, who lived down here and went up every day. Padlocked; Bastião kept her key ("if I don't come
# down, burn it all"). Her room as she left it the last time: the bed, the wire hanger on the wall with no uniform on
# it, her cap on the shelf, the mirror covered with a cloth, a little suitcase packed and never taken, on the table her
# letters to her mother and a tray with an empty glass syringe. It shows the Enfermeira (docs/ENFERMEIRA.md) before
# the Colônia does. Same kit as the other rooms. Godot: interior.gd.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/enfermeira_build.py
#   -> blender/cenarios/enfermeira.blend, godot_demo/models/levels/enfermeira.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("navy", "cloth", 1.0, tint=(0.18, 0.2, 0.32)); mat("glass_s", "window_in", 1.0, tint=(0.8, 0.9, 0.9))
mat("leather", "cloth", 1.0, tint=(0.42, 0.28, 0.18))
rng = random.Random("enfermeira")
WX, WY, HT = 3.0, 2.5, 2.8
R_ = Room(WX, WY, HT)

room = B()
R_.shell(room, "whitewash", door_w=1.0, windows=(("left", 0.4), ("right", -0.6)))
R_.dado(room, "barra_oxblood", h=0.8, door_w=1.0)
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, beams=(-1.2, 0.0, 1.2)); obj(roof, "teto-col")

f = B()
bx(f, (-2.1, 1.4, 0.25), (1.6, 1.9, 0.5), "planks")                                     # the bed
bx(f, (-2.1, 1.4, 0.53), (1.5, 1.8, 0.06), "cloth_white")
bx(f, (0.6, 1.9, 0.74), (1.2, 0.6, 0.05), "planks")                                     # the table
for sx in (-1, 1):
    for sy in (-1, 1):
        bx(f, (0.6 + sx * 0.52, 1.9 + sy * 0.24, 0.36), (0.05, 0.05, 0.72), "planks")
bx(f, (0.6, 1.25, 0.24), (0.42, 0.42, 0.04), "planks")                                  # the chair
bx(f, (0.6, 1.05, 0.7), (0.42, 0.04, 0.5), "planks")
bx(f, (2.3, -1.6, 0.2), (0.6, 0.35, 0.4), "leather")                                    # the suitcase, packed, by the door
obj(f, "moveis-col")

t = B()
bx(t, (WX - 0.03, 1.2, 1.7), (0.02, 0.08, 0.04), "iron")                                # the peg, the wire hanger, empty
for a, b in (((-0.2, 1.62), (0.0, 1.72)), ((0.0, 1.72), (0.2, 1.62)), ((-0.2, 1.62), (0.2, 1.62))):
    frustum(t, (WX - 0.08, 1.2 + a[0], a[1]), (WX - 0.08, 1.2 + b[0], b[1]), 0.006, 0.006, 4, "iron")
bx(t, (WX - 0.15, -1.5, 1.5), (0.25, 0.7, 0.03), "planks")                              # the shelf, her cap on it
bx(t, (WX - 0.15, -1.5, 1.56), (0.16, 0.18, 0.08), "cloth_white"); bx(t, (WX - 0.15, -1.5, 1.565), (0.17, 0.19, 0.02), "pit")
bx(t, (-WX + 0.03, -1.0, 1.6), (0.03, 0.5, 0.65), "glass_s")                             # the mirror, a cloth over it
bx(t, (-WX + 0.06, -1.0, 1.55), (0.02, 0.56, 0.75), "navy", rot=(0.04, 0, 0))
for k in range(4):                                                                       # her letters, the tray, the syringe
    bx(t, (0.35 + 0.05 * k, 1.95 + rng.uniform(-0.05, 0.05), 0.77 + 0.004 * k), (0.2, 0.26, 0.004), "cloth_white",
       rot=(0, 0, rng.uniform(-0.3, 0.3)))
bx(t, (0.95, 1.9, 0.775), (0.3, 0.18, 0.012), "iron")
frustum(t, (0.85, 1.9, 0.8), (1.05, 1.9, 0.8), 0.015, 0.015, 6, "glass_s", caps=True)
frustum(t, (1.05, 1.9, 0.8), (1.1, 1.9, 0.8), 0.003, 0.002, 4, "iron")
bx(t, (2.3, -1.6, 0.42), (0.2, 0.05, 0.04), "iron")                                      # the suitcase's handle
obj(t, "objetos")

for name, loc, yaw in (("entrada", (0, -1.7, 0), 0), ("porta", (0, -WY, 0), 0),
                       ("luz_janela", (-WX + 0.4, 0.4, 1.6), 0), ("luz_janela_b", (WX - 0.4, -0.6, 1.6), 0),
                       ("luz_lamparina", (0.6, 1.9, 1.1), 0), ("luz_vela", (-1.05, 2.1, 0.85), 0)):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = loc; e.rotation_euler.z = math.radians(yaw)

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "enfermeira"))
bpy.ops.export_scene.gltf(filepath=paths.level("enfermeira"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)
print("ENFERMEIRA ok")

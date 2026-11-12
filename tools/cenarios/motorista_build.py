# The driver's house (casa_10 in the village, east: docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"): Seu Abílio, who
# drove the Colônia's truck up and down the road. Padlocked; he left the key with Seu Dito, the peddler ("guarda a
# mercadoria pra mim"). A single man's room: the cot, a workbench with tools and a truck tyre against it, his driver's
# cap on a nail, a calendar of the Colônia's runs on the wall, on the table his trip book (who went up and when) and,
# under the cot, a tin with a medal of São Cristóvão. Same kit as the other rooms. Godot: interior.gd.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/motorista_build.py
#   -> blender/cenarios/motorista.blend, godot_demo/models/levels/motorista.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("navy", "cloth", 1.0, tint=(0.18, 0.2, 0.3)); mat("tyre", "mud", 1.0, tint=(0.25, 0.24, 0.23))
mat("cal", "paper_procura", 1.0, tint=(1.0, 1.0, 0.95))
rng = random.Random("motorista")
WX, WY, HT = 3.0, 2.5, 2.8
R_ = Room(WX, WY, HT)

room = B()
R_.shell(room, "whitewash", door_w=1.0, windows=(("left", 0.4), ("right", -0.6)))
R_.dado(room, "barra_ochre", h=0.8, door_w=1.0)
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, beams=(-1.2, 0.0, 1.2)); obj(roof, "teto-col")

f = B()
bx(f, (-2.2, 1.5, 0.22), (1.4, 1.9, 0.44), "planks")                                     # the cot
bx(f, (-2.2, 1.5, 0.47), (1.3, 1.8, 0.06), "cloth_grey")
bx(f, (1.6, 2.05, 0.82), (2.2, 0.7, 0.06), "planks")                                     # the workbench
for x in (0.6, 2.6):
    bx(f, (x, 2.05, 0.4), (0.08, 0.6, 0.8), "planks")
bx(f, (-0.2, 0.6, 0.72), (1.0, 0.6, 0.05), "planks")                                     # the table
for sx in (-1, 1):
    for sy in (-1, 1):
        bx(f, (-0.2 + sx * 0.44, 0.6 + sy * 0.24, 0.35), (0.05, 0.05, 0.7), "planks")
frustum(f, (2.5, 1.55, 0.4), (2.5, 1.3, 0.4), 0.4, 0.4, 10, "tyre", caps=True)           # a truck tyre against the bench
obj(f, "moveis-col")

t = B()
for k in range(6):                                                                       # tools on the bench
    bx(t, (0.9 + 0.3 * k, 2.0 + rng.uniform(-0.1, 0.1), 0.86), (0.22, 0.05, 0.03), "iron", rot=(0, 0, rng.uniform(-0.5, 0.5)))
bx(t, (2.0, 2.25, 1.3), (0.6, 0.03, 0.5), "planks")                                       # a rack with spanners
bx(t, (-0.35, 0.6, 0.76), (0.3, 0.22, 0.03), "navy")                                      # the trip book
bx(t, (WX - 0.03, -1.0, 1.6), (0.02, 0.55, 0.7), "cal")                                   # the calendar
bx(t, (-WX + 0.05, 0.8, 1.7), (0.02, 0.06, 0.06), "iron")                                 # the nail, his cap on it
bx(t, (-WX + 0.12, 0.8, 1.62), (0.14, 0.22, 0.08), "navy"); bx(t, (-WX + 0.2, 0.8, 1.58), (0.06, 0.22, 0.02), "pit")
obj(t, "objetos")

for name, loc, yaw in (("entrada", (0, -1.7, 0), 0), ("porta", (0, -WY, 0), 0), ("medalha", (-2.2, 1.0, 0.06), 0),
                       ("luz_janela", (-WX + 0.4, 0.4, 1.6), 0), ("luz_janela_b", (WX - 0.4, -0.6, 1.6), 0),
                       ("luz_lamparina", (1.6, 2.0, 1.2), 0), ("luz_vela", (-0.2, 0.6, 1.0), 0)):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = loc; e.rotation_euler.z = math.radians(yaw)

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "motorista"))
bpy.ops.export_scene.gltf(filepath=paths.level("motorista"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)
print("MOTORISTA ok")

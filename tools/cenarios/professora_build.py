# Dona Lurdes's house (casa_02 in the village, by the way in: docs/CONTEUDO_VILAREJO.md "As casas acorrentadas"), the
# schoolteacher's. Padlocked from outside; the key was left with Cida's mother. A tidy room, the way she left it to go by
# the river trail and never came back: the bed made, the desk with the class diaries stacked (the names struck out,
# "subiu" written beside them), a slate with the last lesson, a shelf of books, the class photograph on the wall, her
# husband's pocket watch on the night table. Same kit as the other rooms. Godot: interior.gd.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/professora_build.py
#   -> blender/cenarios/professora.blend, godot_demo/models/levels/professora.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("slate", "stone", 1.0, tint=(0.25, 0.3, 0.27)); mat("book_r", "cloth", 1.0, tint=(0.62, 0.2, 0.16))
mat("book_b", "cloth", 1.0, tint=(0.2, 0.26, 0.5)); mat("book_g", "cloth", 1.0, tint=(0.24, 0.42, 0.26))
rng = random.Random("professora")
WX, WY, HT = 3.0, 2.5, 2.8
R_ = Room(WX, WY, HT)

room = B()
R_.shell(room, "whitewash", door_w=1.0, windows=(("left", 0.4), ("right", -0.6)))
R_.dado(room, "barra_blue", h=0.8, door_w=1.0)
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, beams=(-1.2, 0.0, 1.2)); obj(roof, "teto-col")

f = B()
bx(f, (-2.1, 1.4, 0.25), (1.6, 1.9, 0.5), "planks")                                     # the bed, made
bx(f, (-2.1, 1.4, 0.53), (1.5, 1.8, 0.06), "cloth_white")
bx(f, (-2.1, 2.15, 0.62), (1.1, 0.3, 0.12), "cloth_white")                              # the pillow
bx(f, (-1.05, 2.1, 0.3), (0.4, 0.4, 0.6), "planks")                                     # night table
bx(f, (0.9, 1.9, 0.74), (1.4, 0.65, 0.05), "planks")                                    # the desk
for sx in (-1, 1):
    for sy in (-1, 1):
        bx(f, (0.9 + sx * 0.62, 1.9 + sy * 0.26, 0.36), (0.05, 0.05, 0.72), "planks")
bx(f, (0.9, 1.25, 0.24), (0.42, 0.42, 0.04), "planks")                                  # the chair, pushed in neatly
bx(f, (0.9, 1.05, 0.7), (0.42, 0.04, 0.5), "planks")
bx(f, (WX - 0.2, -0.6, 1.0), (0.3, 1.4, 2.0), "planks")                                 # the bookshelf
obj(f, "moveis-col")

t = B()
for k in range(3):                                                                       # the class diaries, stacked
    bx(t, (0.65, 1.95, 0.78 + 0.035 * k), (0.32, 0.24, 0.03), rng.choice(("book_r", "book_b", "book_g")), rot=(0, 0, rng.uniform(-0.1, 0.1)))
bx(t, (1.25, 2.1, 0.77), (0.5, 0.03, 0.36), "slate", rot=(math.radians(-15), 0, 0))     # the slate, propped up
for k in range(4):
    bx(t, (1.1 + 0.08 * k, 2.08, 0.8 + 0.05 * k), (0.06, 0.005, 0.01), "whitewash")      # chalk
for shelf in range(4):                                                                   # books on the shelf
    z = 0.25 + 0.48 * shelf
    bx(t, (WX - 0.2, -0.6, z - 0.02), (0.3, 1.4, 0.03), "planks")
    y = -1.25
    while y < 0.05:
        w = rng.uniform(0.04, 0.08)
        bx(t, (WX - 0.22, y + w / 2, z + 0.12), (0.2, w, rng.uniform(0.18, 0.26)), rng.choice(("book_r", "book_b", "book_g")))
        y += w + 0.005
bx(t, (-WX + 0.03, -1.0, 1.75), (0.03, 0.7, 0.5), "planks")                              # the class photo, framed
bx(t, (-WX + 0.05, -1.0, 1.75), (0.01, 0.6, 0.4), "cloth_white")
for i in range(12):
    bx(t, (-WX + 0.055, -1.25 + 0.045 * (i % 6) * 2, 1.68 + 0.12 * (i // 6)), (0.005, 0.04, 0.05), "pit")
frustum(t, (-0.9, 2.15, 0.6), (-0.9, 2.15, 0.72), 0.02, 0.02, 6, "cloth_white", caps=True)  # a candle on the night table
obj(t, "objetos")

for name, loc, yaw in (("entrada", (0, -1.7, 0), 0), ("porta", (0, -WY, 0), 0), ("relogio", (-1.05, 2.1, 0.6), 0),
                       ("luz_janela", (-WX + 0.4, 0.4, 1.6), 0), ("luz_janela_b", (WX - 0.4, -0.6, 1.6), 0),
                       ("luz_lamparina", (0.9, 1.9, 1.1), 0), ("luz_vela", (-0.9, 2.15, 0.85), 0)):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = loc; e.rotation_euler.z = math.radians(yaw)

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "professora"))
bpy.ops.export_scene.gltf(filepath=paths.level("professora"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)
print("PROFESSORA ok")

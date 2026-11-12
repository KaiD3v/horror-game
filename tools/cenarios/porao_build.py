# The venda's cellar (docs/CONTEUDO_VILAREJO.md "O porão da venda"): down through the iron trapdoor in the shop's floor,
# opened with the combination Bento scratched on the counter (0612: Odete's number at the Colônia). A low stone cellar:
# shelves of preserves, sacks, and in the corner what Bento hid of his wife Odete when they took her up in 1968: her trunk
# open, a dress folded on it, her mirror, a photograph on a nail; on the trunk the letter she sent him, never opened.
# The ladder up to the trapdoor is the way out. Same kit as the other rooms. Godot: porao.gd (interior.gd).
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/porao_build.py
#   -> blender/cenarios/porao.blend, godot_demo/models/levels/porao.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("vestido", "cloth", 1.0, tint=(0.55, 0.62, 0.78)); mat("conserva", "window_in", 1.0, tint=(0.9, 0.6, 0.3))
mat("bau_couro", "cloth", 1.0, tint=(0.4, 0.27, 0.17))
rng = random.Random("porao")
WX, WY, HT = 2.4, 2.0, 2.1
R_ = Room(WX, WY, HT)

room = B()
R_.shell(room, "stone", door_w=0.01, floor="mud")          # (no door: the way in is the ladder from the trapdoor)
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, beams=(-1.0, 0.0, 1.0), hole=(-0.45, 0.45, -2.0, -1.3)); obj(roof, "teto-col")

f = B()
for zz in (0.5, 1.1, 1.7):                                   # shelves of preserves along the back wall
    bx(f, (0.6, WY - 0.2, zz), (2.6, 0.36, 0.04), "planks")
for x in (-0.65, 1.85):
    bx(f, (x, WY - 0.2, HT / 2), (0.06, 0.36, HT), "planks")
bx(f, (-1.7, 1.2, 0.25), (0.9, 0.55, 0.5), "bau_couro")       # Odete's trunk
for k in range(3):                                           # sacks of flour against the right wall
    bx(f, (WX - 0.3, -0.8 + 0.55 * k, 0.3), (0.45, 0.5, 0.6), "burlap", rot=(0, 0, rng.uniform(-0.2, 0.2)))
obj(f, "moveis-col")

t = B()
for zz in (0.5, 1.1, 1.7):                                   # the jars
    for k in range(9):
        frustum(t, (-0.5 + 0.28 * k, WY - 0.2, zz + 0.02), (-0.5 + 0.28 * k, WY - 0.2, zz + 0.2), 0.07, 0.07, 6, "conserva", caps=True)
bx(t, (-1.7, 1.2, 0.52), (0.62, 0.4, 0.05), "vestido", rot=(0, 0, 0.05))   # her dress, folded on the trunk
bx(t, (-1.3, 1.05, 0.52), (0.16, 0.22, 0.02), "window_in", rot=(0, 0, 0.3))                  # her hand mirror
bx(t, (-WX + 0.03, 1.2, 1.4), (0.02, 0.22, 0.28), "cloth_white")             # her photograph on a nail
bx(t, (-WX + 0.04, 1.2, 1.4), (0.01, 0.16, 0.2), "pit")
for k in range(7):                                           # the ladder up to the trapdoor
    bx(t, (0, -1.65, 0.25 + 0.27 * k), (0.6, 0.05, 0.05), "planks")
for sx in (-0.32, 0.32):
    bx(t, (sx, -1.65, HT / 2), (0.06, 0.06, HT + 0.2), "planks")
obj(t, "objetos")

for name, loc, yaw in (("entrada", (0, -1.0, 0), 0), ("porta", (0, -1.55, 0), 0), ("carta", (-1.75, 1.0, 0.56), 0),
                       ("luz_vela", (-1.3, 1.3, 0.8), 0), ("luz_lamparina", (0.6, 0.2, 1.8), 0)):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = loc; e.rotation_euler.z = math.radians(yaw)

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "porao"))
bpy.ops.export_scene.gltf(filepath=paths.level("porao"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)
print("PORAO ok")

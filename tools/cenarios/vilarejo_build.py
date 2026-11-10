# Vila de Santa Clara, v1 (docs/VILAREJO.md): terrain, houses, chapel, cemetery, well, fences, the Colônia's
# wall and gate, dead trees. N64-style low poly, textures from scenery_textures.py with per-face planar UVs at
# world scale (like the Colônia's triplanar). Colliders by Godot's name suffixes: "-col" (mesh + trimesh body),
# "-colonly" (trimesh body only).
# The parts live in the vilarejo/ package (one module each); this runs them in build order.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/vilarejo_build.py
#   -> blender/cenarios/vilarejo.blend, godot_demo/models/levels/vilarejo.glb
import bpy, bmesh, math, os, random
from mathutils import Vector, Matrix, Euler, noise

noise.seed_set(1975)
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # tools/cenarios: the vilarejo package
from vila_kit import *  # materials, mesh builder, prop pieces, bake_ao
from vilarejo.layout import *
from vilarejo.construcoes import *
from vilarejo.natureza import *
from vilarejo.objetos import *
from vilarejo.narrativa import *
from vilarejo import narrativa
from vilarejo.horizonte import *


# --- build ---------------------------------------------------------------------------------------------------
narrativa.TERR = terrain()
for i, (hx, hy, face, w, d, kind, ex) in enumerate(HOUSES):
    name = "casa_%02d" % (i + 1)
    hb = ruin(name, w, d) if kind == "ruin" else house(name, hx, hy, face, w, d, kind, ex)
    obj(hb, name + "-col", (hx, hy, h_road(hx, hy)), math.radians(face))
obj(chapel(), "capela-col", (CHAPEL[0], CHAPEL[1], h_road(CHAPEL[0], CHAPEL[1])), math.radians(CHAPEL[2]))
# the chapel's door is in the tower's face, 8.25 m out from the nave's centre: porta_capela at the foot of its step
_a = math.radians(CHAPEL[2]); _ly = -8.25 - 1.1
e = bpy.data.objects.new("porta_capela", None); bpy.context.collection.objects.link(e)
_x, _y = CHAPEL[0] - _ly * math.sin(_a), CHAPEL[1] + _ly * math.cos(_a)
e.location = (_x, _y, H(_x, _y)); e.rotation_euler.z = _a
b = B(); well(b, Vector((3.0, 3.0, H(3.0, 3.0)))); obj(b, "poco-col")
b = B(); colony_wall(b); obj(b, "muro_colonia-col")
b = B(); cross = B(); cemetery(b, cross); obj(b, "cemiterio_muro-col"); obj(cross, "cemiterio_cruzes")
b = B(); fences(b); obj(b, "cercas-col")
b = B(); rocks(b); obj(b, "pedras-col")
col = B(); placed = trees(col); obj(col, "troncos-colonly")
props()
VEG = vegetation(placed)
narrative()
for name, (x, y, yaw) in NPCS.items():  # markers for vilarejo.gd: npc_vendeiro, ...
    e = bpy.data.objects.new("npc_" + name, None); bpy.context.collection.objects.link(e)
    e.location = (x, y, H(x, y)); e.rotation_euler.z = math.radians(yaw)
for i, (hx, hy, face, w, d, kind, ex) in enumerate(HOUSES):  # doors you can go through: porta_<interior>
    if ex.get("sign"):
        x, y, yaw = at_house(i, *DOORS["casa_%02d" % (i + 1)])
        e = bpy.data.objects.new("porta_" + ex["sign"], None); bpy.context.collection.objects.link(e)
        e.location = (x, y, H(x, y)); e.rotation_euler.z = math.radians(yaw)  # facing like the house
for name, (x, y) in {"spawn_jogador": (0.0, -46.0), "spawn_mutante": (4.5, 1.5)}.items():  # read by vilarejo.gd
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e); e.location = (x, y, H(x, y))

ridge("silhueta_longe", 175, (44, 72), -25, 0.0, 3)
ridge("silhueta_perto", 112, (27, 40), -20, 0.55, 7)
colony()
import time; _t = time.time(); AO = bake_ao(skip_names=("capim", "samambaias"), skip_prefixes=("silhueta", "colonia_", "corvo_")); print("AO polygons=%d in %.0f s" % (AO, time.time() - _t))
tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH" and not o.name.endswith("colonly")
           for p in o.data.polygons)
print("VILAREJO trees=%d objects=%d tris~%d veg=%s" % (len(placed), len(bpy.data.objects), tris, VEG))
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "vilarejo"))
bpy.ops.export_scene.gltf(filepath=paths.level("vilarejo"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False,
                          export_vertex_color="ACTIVE")  # the baked AO (bake_ao) rides in COLOR_0

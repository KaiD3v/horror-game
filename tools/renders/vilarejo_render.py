# Preview renders of vilarejo.blend (no fog: to check the modelling). Run:
# blender -b --factory-startup blender/cenarios/vilarejo.blend --python tools/renders/vilarejo_render.py
#   ->  renders/cenarios/vilarejo_*.png (+ the prop kit lined up)
import bpy, math, os
from mathutils import Vector

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"
sc.render.resolution_x, sc.render.resolution_y = 1280, 800
sc.world = bpy.data.worlds.new("ceu"); sc.world.color = (0.30, 0.32, 0.33)
sun = bpy.data.objects.new("sol", bpy.data.lights.new("sol", "SUN")); sc.collection.objects.link(sun)
sun.data.energy = 2.5; sun.rotation_euler = (math.radians(50), 0, math.radians(30))
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam


def shoot(name, loc, at, lens):
    cam.location = loc; cam.data.lens = lens
    cam.rotation_euler = (Vector(at) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = paths.render("cenarios", "vilarejo_%s.png" % name)
    bpy.ops.render.render(write_still=True)


def ground_at(x, y):  # terrain height under x, y (ray down on the terrain mesh)
    t = bpy.data.objects["terreno-col"]
    ok, p, *_ = t.ray_cast(Vector((x, y, 100)), Vector((0, 0, -1)))
    return p.z if ok else 0.0


shoot("visao_geral", (55, -70, 55), (0, 0, 0), 28)
shoot("rua", (1.5, -44, 3.0 + ground_at(1.5, -44)), (0, -20, 2.0), 24)
for name, (x, y), (ax, ay), lens in (("largo", (6, -6), (-6, 9), 22), ("venda", (2, 6), (12, 16), 24),
                                     ("carroca", (-1, -31), (-5, -25), 24), ("espantalho", (24, -32), (30, -27), 30)):
    shoot(name, (x, y, ground_at(x, y) + 2.2), (ax, ay, ground_at(ax, ay) + 1.2), lens)

# the kit lined up in two rows on a plain floor, everything else hidden
for o in sc.objects:
    o.hide_render = o.type == "MESH"
KIT = ("barril", "caixote", "lenha", "carrinho", "banco", "cocho", "roda", "placa", "placa_vila",
       "carroca", "carroca_quebrada", "espantalho", "cruzeiro", "feno", "varal_a", "varal_b")
x, row, width = 0.0, 0, 0.0
for n in KIT:
    me = bpy.data.meshes[n]; xs = [v.co.x for v in me.vertices]
    if row == 0 and n == "carroca":
        width, x, row = x, 0.0, 1
    o = bpy.data.objects.new("kit_" + n, me); sc.collection.objects.link(o)
    o.location = (x - min(xs), 300 + row * 6, 0); x += max(xs) - min(xs) + 0.9
width = max(width, x)
bpy.ops.mesh.primitive_plane_add(size=1, location=(width / 2, 303, 0)); bpy.context.object.scale = (width + 12, 20, 1)
bpy.context.object.data.materials.append(bpy.data.materials["mud"])
shoot("kit", (width / 2, 300 - 17, 10), (width / 2, 303, 0.8), 24)

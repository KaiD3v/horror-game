# Turnaround + mood renders of the protagonist. Runs inside Blender via the Blender MCP.
import bpy, math, os
from mathutils import Vector

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
OUT = os.path.join(paths.RENDERS, "protagonista")
scene = bpy.context.scene
for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
    try:
        scene.render.engine = eng
        break
    except TypeError:
        pass
scene.render.resolution_x, scene.render.resolution_y = 360, 480
scene.render.film_transparent = False
scene.view_settings.view_transform = "Standard"
scene.eevee.taa_render_samples = 16

world = scene.world or bpy.data.worlds.new("World")
scene.world = world
try:
    world.use_nodes = True
except Exception:
    pass
bg = next(n for n in world.node_tree.nodes if n.bl_idname == "ShaderNodeBackground")


def obj(name, data):
    o = bpy.data.objects.get(name)
    if o is None:
        o = bpy.data.objects.new(name, data); scene.collection.objects.link(o)
    return o


sun = obj("sun", bpy.data.lights.get("sun") or bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 2.2; sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
moon = obj("moon_rim", bpy.data.lights.get("moon_rim") or bpy.data.lights.new("moon_rim", "SUN"))
moon.data.color = (0.45, 0.55, 0.9); moon.rotation_euler = (math.radians(60), 0, math.radians(160))
lantern = bpy.data.objects["lantern_light"]


def cam(name, loc, target, ortho=None, lens=50):
    c = obj(name, bpy.data.cameras.get(name) or bpy.data.cameras.new(name))
    c.location = loc
    c.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    if ortho:
        c.data.type = "ORTHO"; c.data.ortho_scale = ortho
    else:
        c.data.type = "PERSP"; c.data.lens = lens
    return c


views = []
for name, ang in (("front", 0), ("three_quarter", 35), ("side", 90), ("back", 180)):
    a = math.radians(ang)
    views.append(cam("CAM_" + name, (4 * math.sin(a), -4 * math.cos(a), 0.9), (0, 0, 0.9), ortho=2.0))
mood = cam("CAM_mood", (-0.3, -1.6, 1.0), (-0.08, -0.1, 1.25), lens=40)
face = cam("CAM_face", (-0.25, -1.0, 1.55), (0, 0, 1.53), lens=85)

files = []


def shot(c, dark):
    bg.inputs[0].default_value = (0.004, 0.005, 0.008, 1) if dark else (0.22, 0.22, 0.24, 1)
    bg.inputs[1].default_value = 1.0
    sun.hide_render = dark
    moon.hide_render = not dark; moon.data.energy = 0.35
    lantern.data.energy = 30 if dark else 4
    scene.camera = c
    scene.render.filepath = os.path.join(OUT, c.name[4:] + ".png")
    bpy.ops.render.render(write_still=True)
    files.append(scene.render.filepath)


for c in views + [face]:
    shot(c, dark=False)
shot(mood, dark=True)
scene.camera = views[0]
bpy.ops.wm.save_mainfile()
result = {"files": files}

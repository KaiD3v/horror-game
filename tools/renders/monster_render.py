# Turnaround + animation frames of the mutant (and the protagonist for scale). Run after monster_build.py.
# Prepend `ONLY = [...]` to render only some actions, `STILLS = False` to skip the turnaround.
import bpy, math, os
from mathutils import Vector

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
OUT = globals().get("OUT", os.path.join(paths.RENDERS, "mutante"))
os.makedirs(OUT, exist_ok=True)
scene = bpy.context.scene
for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
    try:
        scene.render.engine = eng
        break
    except TypeError:
        pass
scene.render.resolution_x, scene.render.resolution_y = 300, 400
scene.view_settings.view_transform = "Standard"
scene.eevee.taa_render_samples = 16
scene.render.fps = 30
world = scene.world or bpy.data.worlds.new("World"); scene.world = world
try:
    world.use_nodes = True
except Exception:
    pass
next(n for n in world.node_tree.nodes if n.bl_idname == "ShaderNodeBackground").inputs[0].default_value = (0.22, 0.22, 0.24, 1)
sun = bpy.data.objects.get("sun") or bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
if sun.name not in scene.collection.objects:
    scene.collection.objects.link(sun)
sun.data.energy = 2.2; sun.rotation_euler = (math.radians(50), 0, math.radians(-30))


def cam(name, ang, scale=2.7, z=1.15):
    c = bpy.data.objects.get(name) or bpy.data.objects.new(name, bpy.data.cameras.new(name))
    if c.name not in scene.collection.objects:
        scene.collection.objects.link(c)
    a = math.radians(ang); loc = Vector((5 * math.sin(a), -5 * math.cos(a), z))
    c.location = loc; c.rotation_euler = (Vector((0, 0, z)) - loc).to_track_quat("-Z", "Y").to_euler()
    c.data.type = "ORTHO"; c.data.ortho_scale = scale
    return c


views = {n: cam("CAM_" + n, a) for n, a in (("front", 0), ("three_quarter", -35), ("side", -90), ("back", 180))}
files = []


def shoot(c, path):
    scene.camera = c; scene.render.filepath = path
    bpy.ops.render.render(write_still=True); files.append(path)


arm = bpy.data.objects.get(globals().get("RIG", "MonsterRig"))
if globals().get("STILLS", True):
    if arm and arm.animation_data:
        arm.animation_data.action = None
        for pb in arm.pose.bones:
            pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
    for n, c in views.items():
        shoot(c, os.path.join(OUT, n + ".png"))
if arm:
    for act in bpy.data.actions:
        name = act.name.replace("_Loop", "")
        if "ONLY" in globals() and name not in ONLY:
            continue
        arm.animation_data.action = act
        a, b = int(act.frame_range[0]), int(act.frame_range[1])
        os.makedirs(os.path.join(OUT, name), exist_ok=True)
        for cn in ("three_quarter", "side"):
            views[cn].data.ortho_scale = 3.4 if name == "Death" else 2.7
            for f in range(a, b + 1, 2):
                scene.frame_set(f)
                shoot(views[cn], os.path.join(OUT, name, "%s_%03d.png" % (cn, f)))
            views[cn].data.ortho_scale = 2.7
result = {"renders": len(files)}

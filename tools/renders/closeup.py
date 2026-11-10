# Close-up checks of the protagonist (joints, hair, gear) in game poses. Run after render.py (its lights).
# Prepend TAG = "before" / "after" to name the outputs. -> renders/protagonista/closeup/<TAG>_<shot>.png
import bpy, os, math
from mathutils import Vector
TAG = globals().get("TAG", "now")
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
OUT = os.path.join(paths.RENDERS, "protagonista", "closeup")
os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene; arm = bpy.data.objects["Rig"]
bg = next(n for n in sc.world.node_tree.nodes if n.bl_idname == "ShaderNodeBackground")  # neutral light
bg.inputs[0].default_value = (0.22, 0.22, 0.24, 1)
bpy.data.objects["lantern_light"].data.energy = 4
bpy.data.objects["sun"].hide_render = False; bpy.data.objects["moon_rim"].hide_render = True
sc.render.resolution_x, sc.render.resolution_y = 360, 360
cam = bpy.data.objects.get("CAM_close") or bpy.data.objects.new("CAM_close", bpy.data.cameras.new("CAM_close"))
if cam.name not in sc.collection.objects:
    sc.collection.objects.link(cam)
cam.data.type = "PERSP"; cam.data.lens = 50
SHOTS = [  # name, action, frame, camera position, look-at
    ("arms_idle", "Idle_Lantern_Loop", 1, (-0.55, -1.15, 1.35), (0.0, 0.0, 1.12)),
    ("arms_guard", "Combat_Idle_Loop", 1, (0.35, -1.2, 1.35), (0.05, -0.1, 1.15)),
    ("shoulder_side", "Idle_Lantern_Loop", 1, (-1.2, -0.25, 1.35), (-0.1, 0.0, 1.15)),
    ("hair", "Idle_Lantern_Loop", 1, (0.35, -0.75, 1.95), (0.0, 0.0, 1.6)),
    ("hair_back", "Idle_Lantern_Loop", 1, (-0.3, 0.8, 1.9), (0.0, 0.0, 1.6)),
    ("gear_back", "Idle_Lantern_Loop", 1, (0.9, 0.95, 1.0), (0.12, 0.05, 0.75)),
    ("gear_side", "Idle_Lantern_Loop", 1, (1.25, -0.1, 0.95), (0.15, 0.05, 0.75)),
]
for name, act, f, pos, at in SHOTS:
    arm.animation_data.action = bpy.data.actions[act]; sc.frame_set(f)
    cam.location = pos; cam.rotation_euler = (Vector(at) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam; sc.render.filepath = os.path.join(OUT, "%s_%s.png" % (TAG, name))
    bpy.ops.render.render(write_still=True)
result = {"shots": len(SHOTS)}

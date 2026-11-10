# Renders the animation cycles (3/4 + side) to frames for preview GIFs. Run after render.py, via the Blender MCP.
import bpy, os

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
OUT = os.path.join(paths.RENDERS, "protagonista", "anims")
ACTIONS = {"Walk_Lantern_Loop": range(1, 33, 2), "Run_Lantern_Loop": range(1, 21), "Dodge_Left": range(1, 19), "Dodge_Right": range(1, 19),
           "Crouch_Down": range(1, 15), "Crouch_Idle_Loop": range(1, 91, 6), "Crouch_Walk_Loop": range(1, 49, 2), "Draw_Crossbow": range(1, 33), "Aim_Crossbow_Loop": range(1, 61, 6), "Shoot_Crossbow": range(1, 19), "Reload_Crossbow": range(1, 57), "Idle_Lantern_Loop": range(1, 121, 4), "Draw_Machete": range(1, 29),
           "Combat_Idle_Loop": range(1, 61, 4), "Attack_Slash": range(1, 25), "Attack_Overhead": range(1, 31),
           "Hit_React": range(1, 19), "Dodge_Back": range(1, 19), "Death": range(1, 46),
           "Jog_Lantern_Loop": range(1, 31, 2), "Stow_Lantern": range(1, 17), "Idle_Free_Loop": range(1, 121, 8),
           "Walk_Free_Loop": range(1, 33, 2), "Jog_Free_Loop": range(1, 31, 2), "Run_Free_Loop": range(1, 21),
           "Crouch_Down_Free": range(1, 15), "Crouch_Walk_Free_Loop": range(1, 49, 3)}
if "ONLY" in globals():  # prepend `ONLY = [...]` to render a subset (one MCP call has a 300 s limit)
    ACTIONS = {k: v for k, v in ACTIONS.items() if k in ONLY}
CAMS = globals().get("CAMS", ("three_quarter", "side"))  # prepend `CAMS = (...)` for other views
scene = bpy.context.scene
arm = bpy.data.objects["Rig"]
active = arm.animation_data.action
# neutral lighting (render.py leaves the night setup active)
bg = next(n for n in scene.world.node_tree.nodes if n.bl_idname == "ShaderNodeBackground")
bg.inputs[0].default_value = (0.22, 0.22, 0.24, 1)
bpy.data.objects["lantern_light"].data.energy = 4
bpy.data.objects["sun"].hide_render = False
bpy.data.objects["moon_rim"].hide_render = True
scene.render.resolution_x, scene.render.resolution_y = 240, 320
files = []
for act, frames in ACTIONS.items():
    arm.animation_data.action = bpy.data.actions[act]
    for c in CAMS:  # lying down needs a wider frame
        bpy.data.objects["CAM_" + c].data.ortho_scale = 3.0 if act == "Death" else 2.0
    os.makedirs(os.path.join(OUT, act), exist_ok=True)
    for cam in CAMS:
        scene.camera = bpy.data.objects["CAM_" + cam]
        for f in frames:
            scene.frame_set(f)
            scene.render.filepath = os.path.join(OUT, act, "{}_{:03d}.png".format(cam, f))
            bpy.ops.render.render(write_still=True)
            files.append(scene.render.filepath)
arm.animation_data.action = active
scene.frame_set(1)
scene.render.resolution_x, scene.render.resolution_y = 360, 480
result = {"frames": len(files)}

# The protagonist and the three NPCs side by side, same scale and light (style check).
# Run: blender -b --factory-startup --python tools/renders/npcs_lineup.py  ->  renders/npcs/npcs_lineup_{front,34}.png
import bpy, math, os
from mathutils import Vector

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sc = bpy.context.scene
for i, f in enumerate(("protagonista", "npc_vendeiro", "npc_armeiro", "npc_benzedeira")):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(paths.CHARACTERS, f + ".glb"))
    for o in set(bpy.data.objects) - before:
        if o.parent is None:
            o.location.x += (i - 1.5) * 0.9
sc.frame_set(1)
sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x, sc.render.resolution_y = 1000, 560
sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.32, 0.33, 0.35)
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sc.collection.objects.link(sun)
sun.data.energy = 3.0; sun.rotation_euler = (math.radians(55), 0, math.radians(-30))
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.lens = 50
for view, ang in (("front", 0), ("34", 30)):
    a = math.radians(ang); d = 6.5
    cam.location = (d * math.sin(a), -d * math.cos(a), 1.1)
    cam.rotation_euler = (Vector((0, 0, 0.9)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = paths.render("npcs", "npcs_lineup_%s.png" % view)
    bpy.ops.render.render(write_still=True)

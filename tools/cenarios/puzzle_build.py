# The pieces of the puzzles (Godot: pushable.gd, climbable.gd): what can be moved and what can be climbed must look it.
#   pedra  a dressed granite block, 1 m each way (= Pushable.SIZE), worn edges, moss in the cracks, a cross cut in two
#          faces; origin on the floor, centre.
#   muro   a stretch of rough stone wall 2 m wide, 3.5 m high, with stones jutting out of it and an old root down
#          its face: the holds you climb by (Climbable, kind wall). Origin at the foot of its face, centre; the face
#          looks to -Y (glTF +Z), 0.4 m thick behind it.
# Run from the project root:
#   blender -b --factory-startup --python tools/cenarios/puzzle_build.py
#   -> blender/cenarios/puzzle.blend, godot_demo/models/props/puzzle.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder

mat("granite", "stone", 0.5, tint=(0.72, 0.7, 0.66))
mat("moss", "musgo", 0.5, tint=(0.7, 0.8, 0.6))
mat("cut", "stone", 0.5, tint=(0.25, 0.24, 0.23))
mat("root", "bark", 0.5, tint=(0.55, 0.45, 0.35))
rng = random.Random("puzzle")

# --- the block: a bevelled cube (corners cut), moss along the bottom, a cross cut in front and back --------------------
b = B()
S, C = 0.5, 0.06  # half size, how much the edges are worn off
bx(b, (0, 0, S), (2 * S - 2 * C, 2 * S - 2 * C, 2 * S), "granite")
bx(b, (0, 0, S), (2 * S, 2 * S - 2 * C, 2 * S - 2 * C), "granite")
bx(b, (0, 0, S), (2 * S - 2 * C, 2 * S, 2 * S - 2 * C), "granite")
for y in (-1, 1):
    bx(b, (0, y * (S + 0.002), 0.55), (0.06, 0.004, 0.5), "cut")
    bx(b, (0, y * (S + 0.002), 0.68), (0.32, 0.004, 0.06), "cut")
for x in (-1, 1):
    for y in (-1, 1):
        bx(b, (x * 0.3, y * (S + 0.003), 0.05), (0.35, 0.006, 0.08), "moss")
pedra = obj(b, "pedra")

# --- the wall: rough blocks in courses, stones jutting out for holds, a root down its face ---------------------------
w = B()
WW, WH, WT = 2.0, 3.5, 0.4
z = 0.0
while z < WH - 0.01:  # courses of uneven stones
    h = min(rng.uniform(0.3, 0.45), WH - z); x = -WW / 2
    while x < WW / 2 - 0.01:
        l = min(rng.uniform(0.35, 0.7), WW / 2 - x)
        bx(w, (x + l / 2, WT / 2 + rng.uniform(-0.015, 0.015), z + h / 2), (l - 0.02, WT, h - 0.02), "rock")
        x += l
    z += h
bx(w, (0, WT / 2 + 0.01, WH / 2), (WW - 0.04, WT - 0.04, WH - 0.04), "cut")   # mortar behind the stones
HOLDS = [(-0.3, 0.35), (0.35, 0.6), (-0.25, 1.0), (0.3, 1.3), (-0.35, 1.65), (0.25, 1.95), (-0.2, 2.3),
         (0.35, 2.6), (-0.3, 2.95), (0.15, 3.25)]
for hx, hz in HOLDS:  # the holds: stones standing proud of the face, a lip of moss on top
    bx(w, (hx, -0.06, hz), (0.22, 0.14, 0.1), "rock", rot=(0, rng.uniform(-0.15, 0.15), 0))
    bx(w, (hx, -0.07, hz + 0.055), (0.2, 0.12, 0.012), "moss")
for i in range(9):  # an old fig root down the face, from the top
    t = i / 8
    bx(w, (0.55 + 0.1 * math.sin(t * 5), -0.035, WH - t * WH * 0.9), (0.05, 0.05, WH * 0.12), "root",
       rot=(0, 0.15 * math.cos(t * 4), 0))
bx(w, (0, WT / 2, WH + 0.04), (WW + 0.04, WT + 0.04, 0.08), "granite")       # the coping on top
muro = obj(w, "muro")

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "puzzle"))
bpy.ops.export_scene.gltf(filepath=paths.prop("puzzle"), export_format="GLB", export_yup=True)
print("PUZZLE", {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in (pedra, muro)})

# A Enfermeira: tall, gaunt, silent. Nurse's uniform of the 1970s (white dress, navy cape, cap), stockings torn,
# a gauze band over the eyes and the mouth sewn shut. A big glass syringe in the right hand, held like an ice pick;
# keys and scissors on a chain at the waist (her only sound). Walks on tiptoe. Same kit and rig style as the mutant.
# Headless: blender -b --factory-startup --python tools/personagens/enfermeira_build.py
#   -> blender/personagens/enfermeira.blend, godot_demo/models/characters/enfermeira.glb
import bpy, math, os, random, sys, importlib
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import lowpoly as lp
importlib.reload(lp)
from lowpoly import V

lp.clear_scene()
rnd = random.Random(1974)

# --- textures -------------------------------------------------------------------------------------------
W = 32
yy, xx = np.mgrid[0:W, 0:W]


def grime(lo):
    g = np.ones((W, W, 4)); g[:, :, :3] = np.array([[rnd.uniform(lo, 1.0) for _ in range(W)] for _ in range(W)])[:, :, None]
    return g


s = grime(0.86)  # the uniform: yellowed, rust and dried blood
for _ in range(6):  # small, old, brown more than red
    cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.uniform(0.7, 1.6)
    s[((xx - cx) ** 2 + (yy - cy) ** 2) < r * r, :3] = rnd.choice(((0.58, 0.36, 0.30), (0.48, 0.24, 0.22), (0.80, 0.72, 0.58)))
for _ in range(3):  # drips
    x, y = rnd.randrange(W), rnd.randrange(W)
    for _ in range(rnd.randrange(5, 11)):
        s[y % W, x % W, :3] = (0.55, 0.30, 0.27); y -= 1
STAINS = lp.new_image("stains_32", s)
GRIME = lp.new_image("grime_32", grime(0.78))

v = np.ones((W, W, 4)); v[:, :, :3] = np.array([[rnd.uniform(0.88, 1.0) for _ in range(W)] for _ in range(W)])[:, :, None]
for _ in range(5):  # veins under grey skin
    x, y = rnd.randrange(W), rnd.randrange(W)
    for _ in range(22):
        v[y % W, x % W, :3] = (0.78, 0.80, 0.92); x += rnd.choice((-1, 0, 1)); y += rnd.choice((0, 1, 1))
VEINS = lp.new_image("veins_32", v)

SKIN = np.array((0.70, 0.70, 0.66))
F = 64
f = np.ones((F, F, 4)); f[:, :, :3] = SKIN
fy, fx = np.mgrid[0:F, 0:F]


def ell(cx, cy, rx, ry, col, mix=1.0):
    m = ((fx - cx) / rx) ** 2 + ((fy - cy) / ry) ** 2 <= 1
    f[m, :3] = f[m, :3] * (1 - mix) + np.array(col) * mix


for cx in (19, 45):  # hollow cheeks
    ell(cx, 25, 6, 5, (0.50, 0.50, 0.50), 0.5)
for cx in (21, 43):  # what leaked out from under the gauze
    for y in range(24, 36):
        f[y, cx, :3] = (0.38, 0.10, 0.10)
        if y > 30:
            f[y, cx + (1 if cx < 32 else -1), :3] = (0.45, 0.16, 0.15)
f[30:33, 31:33, :3] = (0.55, 0.55, 0.53)  # nose shadow
f[16, 23:41, :3] = (0.20, 0.12, 0.14)  # the mouth, sewn shut
for x in range(24, 41, 3):
    f[14:19, x, :3] = (0.12, 0.06, 0.07)
ell(32, 16, 9, 2.2, (0.48, 0.42, 0.48), 0.35)
f[0:6, :, :3] *= 0.85
FACE = lp.new_image("enfermeira_face_64", f)

g = np.ones((4, 64, 4)); g[:, :, :3] = np.array([[rnd.uniform(0.84, 1.0) for _ in range(64)] for _ in range(4)])[:, :, None]
for cx in (3.7, 60.3, 3.7 + 64, 60.3 - 64):  # one blot per eye; the band wraps, u 0 = 1 = the front
    for y in range(4):
        d = np.abs(np.arange(64) - cx)
        g[y, d < 2.6 - 0.3 * abs(y - 1.5), :3] = (0.45, 0.12, 0.11)
GAUZE = lp.new_image("gauze_64x4", g)

M = dict(
    dress=lp.mat("n_dress", (0.82, 0.80, 0.72), tex=STAINS),
    cape=lp.mat("n_cape", (0.13, 0.15, 0.22), tex=GRIME),
    cap=lp.mat("n_cap", (0.86, 0.85, 0.80), tex=GRIME),
    stripe=lp.mat("n_stripe", (0.08, 0.08, 0.10)),
    skin=lp.mat("n_skin", SKIN, tex=VEINS),
    face=lp.mat("n_face", SKIN, face=FACE),
    gauze=lp.mat("n_gauze", (0.80, 0.78, 0.70), face=GAUZE),
    stocking=lp.mat("n_stocking", (0.62, 0.61, 0.57), tex=GRIME),
    shoe=lp.mat("n_shoe", (0.07, 0.06, 0.06)),
    hair=lp.mat("n_hair", (0.07, 0.06, 0.06)),
    nail=lp.mat("n_nail", (0.20, 0.17, 0.15)),
    glass=lp.mat("n_glass", (0.60, 0.70, 0.68), emit=0.15),  # catches the lantern
    blood=lp.mat("n_blood", (0.40, 0.04, 0.05)),
    metal=lp.mat("n_metal", (0.50, 0.50, 0.48), tex=GRIME),
)

# --- joint table (+X = her left, -Y = front, Z up). Rest: upright and stiff, arms hanging, on tiptoe. -----
J = {"pelvis": (0, 0.02, 1.10), "spine": (0, 0.02, 1.38), "chest": (0, 0.0, 1.64),
     "neck": (0, -0.02, 1.88), "skull": (0, -0.03, 2.06)}
for s_, sx in ((".L", 1), (".R", -1)):
    J.update({"sh" + s_: (sx * 0.16, 0.0, 1.61), "el" + s_: (sx * 0.20, 0.03, 1.24), "wr" + s_: (sx * 0.22, 0.0, 0.87),
              "hip" + s_: (sx * 0.09, 0.02, 1.08), "knee" + s_: (sx * 0.10, -0.02, 0.60),
              "ankle" + s_: (sx * 0.10, 0.04, 0.17), "toe" + s_: (sx * 0.10, -0.05, 0.0)})
J["tip.L"] = (0.23, -0.03, 0.60)   # long fingers, almost to the knee
J["tip.R"] = (-0.23, -0.09, 0.74)  # a fist round the syringe
BONES = {"hips": ("pelvis", "spine", None), "chest": ("spine", "chest", "hips"), "neck": ("chest", "neck", "chest"),
         "head": ("neck", "skull", "neck")}
for s_ in (".L", ".R"):
    BONES.update({"upper_arm" + s_: ("sh" + s_, "el" + s_, "chest"), "forearm" + s_: ("el" + s_, "wr" + s_, "upper_arm" + s_),
                  "hand" + s_: ("wr" + s_, "tip" + s_, "forearm" + s_),
                  "thigh" + s_: ("hip" + s_, "knee" + s_, "hips"), "shin" + s_: ("knee" + s_, "ankle" + s_, "thigh" + s_),
                  "foot" + s_: ("ankle" + s_, "toe" + s_, "shin" + s_)})


K = lp.Kit()
# torso: the uniform over a body with nothing left on it
K.tube("waist", M["dress"], "hips", J["pelvis"], J["spine"], [(0, 0.12, 0.095), (0.6, 0.085, 0.07), (1, 0.09, 0.07)], n=8)
K.tube("chest", M["dress"], "chest", J["spine"], J["chest"],
       [(0, 0.09, 0.07), (0.5, 0.13, 0.085), (0.85, 0.14, 0.085), (1, 0.07, 0.055)], n=8)
K.seg("belt", M["stripe"], "hips", V(J, "pelvis", "spine", 0.62) - Vector((0, 0, 0.02)), V(J, "pelvis", "spine", 0.62) + Vector((0, 0, 0.02)), 0.092, 0.092, n=8, flat=0.8)
for z in (1.20, 1.30, 1.42, 1.52):  # buttons
    K.box("button", M["stripe"], "chest" if z > 1.38 else "hips", (0, -0.088 if z > 1.38 else -0.075, z), (0.014, 0.008, 0.014))
K.tube("cape", M["cape"], "chest", (0, 0.015, 1.36), (0, 0.0, 1.66), [(0, 0.20, 0.135), (0.7, 0.175, 0.115), (1, 0.075, 0.065)], n=10)
K.seg("collar", M["cap"], "chest", (0, 0.0, 1.64), (0, -0.005, 1.69), 0.06, 0.045, n=8)
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.034, 0.03)

# head: small, a gauze band over the eyes, mouth sewn shut, hair in a bun under the cap
head = K.tube("head", M["skin"], "head", J["neck"], J["skull"],
              [(0, 0.045, 0.05), (0.25, 0.075, 0.085), (0.6, 0.085, 0.095), (0.9, 0.07, 0.08), (1, 0.03, 0.035)], n=10)
head.data.materials.append(M["face"])
L = (V(J, "skull") - V(J, "neck")).length
uv = head.data.uv_layers.new(name="FaceUV")
for p in head.data.polygons:
    if p.normal.y < -0.3 and 0.12 * L < p.center.z < 0.92 * L:
        p.material_index = 1
    for li in p.loop_indices:
        co = head.data.vertices[head.data.loops[li].vertex_index].co
        uv.data[li].uv = (0.5 + co.x / 0.18, co.z / L)
N = 12
band = K.tube("gauze", M["gauze"], "head", V(J, "neck", "skull", 0.52), V(J, "neck", "skull", 0.70),
              [(0, 0.091, 0.101), (1, 0.089, 0.098)], n=N, caps=False)
uv = band.data.uv_layers.new(name="FaceUV")
for p in band.data.polygons:  # u runs round the band from the front (vertex 0), v up it
    ids = [band.data.loops[li].vertex_index for li in p.loop_indices]
    wrap = any(i % N == N - 1 for i in ids)
    for li, i in zip(p.loop_indices, ids):
        k = i % N
        uv.data[li].uv = ((N if (k == 0 and wrap) else k) / N, i // N)
K.blob("hair", M["hair"], "head", V(J, "neck", "skull", 0.76) + Vector((0, 0.025, 0.0)), (0.09, 0.098, 0.08), seed=3, lump=0.08)
K.blob("bun", M["hair"], "head", V(J, "neck", "skull", 0.6) + Vector((0, 0.10, 0)), 0.05, seed=4)
K.box("cap", M["cap"], "head", V(J, "skull") + Vector((0, 0.01, 0.005)), (0.15, 0.13, 0.05), rot=(-0.35, 0, 0))
K.box("cap_fold", M["cap"], "head", V(J, "skull") + Vector((0, 0.05, 0.03)), (0.13, 0.05, 0.06), rot=(-0.6, 0, 0))
K.box("cap_stripe", M["stripe"], "head", V(J, "skull") + Vector((0, -0.055, -0.012)), (0.152, 0.012, 0.012), rot=(-0.35, 0, 0))

# arms: bone-thin and too long; short sleeves under the cape
for s_, sx in ((".L", 1), (".R", -1)):
    K.seg("sleeve", M["dress"], "upper_arm" + s_, V(J, "sh" + s_), V(J, "sh" + s_, "el" + s_, 0.45), 0.05, 0.042)
    K.seg("arm", M["skin"], "upper_arm" + s_, J["sh" + s_], J["el" + s_], 0.032, 0.026)
    K.seg("arm", M["skin"], "forearm" + s_, J["el" + s_], J["wr" + s_], 0.026, 0.019)
    K.blob("elbow", M["skin"], "forearm" + s_, V(J, "el" + s_), 0.03, seed=7)
K.seg("hand", M["skin"], "hand.L", J["wr.L"], V(J, "wr.L", "tip.L", 0.35), 0.022, 0.03, flat=0.4)
for i, dx in enumerate((-0.022, -0.007, 0.008, 0.022)):
    a = V(J, "wr.L", "tip.L", 0.3) + Vector((dx, 0, 0))
    b = V(J, "tip.L") + Vector((dx * 1.4, 0.01 * i, 0.03 * abs(i - 1.5)))
    K.spike("finger", M["skin"], "hand.L", a, b, 0.009)
    K.spike("nail", M["nail"], "hand.L", b + Vector((0, 0, 0.012)), b + Vector((0, -0.01, -0.03)), 0.006)
# right fist round a glass syringe, needle down: barrel, red inside, plunger and thumb ring above
K.seg("hand", M["skin"], "hand.R", J["wr.R"], V(J, "tip.R"), 0.024, 0.032, flat=0.6)
top = V(J, "tip.R") + Vector((0, 0, 0.11))
low = top + Vector((0, -0.05, -0.27))
K.seg("barrel", M["glass"], "hand.R", top, low, 0.026, 0.026, n=8)
K.seg("dose", M["blood"], "hand.R", top.lerp(low, 0.45), low.lerp(top, 0.04), 0.0275, 0.0275, n=8)
for t in (0.0, 0.92):  # metal collars at both ends of the barrel
    K.seg("ring", M["metal"], "hand.R", top.lerp(low, t), top.lerp(low, t + 0.08), 0.031, 0.031, n=8)
K.seg("plunger", M["metal"], "hand.R", top, top + (top - low).normalized() * 0.09, 0.008, 0.008, n=4)
K.box("thumb", M["metal"], "hand.R", top + (top - low).normalized() * 0.095, (0.05, 0.012, 0.03), rot=(0.18, 0, 0))
K.spike("needle", M["metal"], "hand.R", low, low + (low - top).normalized() * 0.14, 0.006, n=4)
for dz in (0.0, 0.03, 0.06):  # fingers round the barrel
    K.seg("grip", M["skin"], "hand.R", top.lerp(low, 0.2) + Vector((0.03, 0.0, -dz)), top.lerp(low, 0.2) + Vector((-0.01, -0.035, -dz)), 0.012, 0.011, n=4)

# skirt: stiff to the knee, split per leg so the stride does not tear through it
K.tube("skirt", M["dress"], "hips", (0, 0.02, 0.86), (0, 0.02, 1.15), [(0, 0.19, 0.165), (0.6, 0.155, 0.13), (1, 0.115, 0.092)], n=10)
for s_, sx in ((".L", 1), (".R", -1)):
    K.tube("skirt", M["dress"], {"hips": 0.45, "thigh" + s_: 0.55}, (sx * 0.085, 0.015, 0.95), (sx * 0.10, -0.005, 0.60),
           [(0, 0.115, 0.125), (1, 0.135, 0.15)], n=8)
    for i in range(3):  # torn hem
        a = math.radians(-60 + 60 * i) * sx
        K.box("hem", M["dress"], "thigh" + s_, (sx * 0.10 + 0.12 * math.sin(a), -0.005 - 0.14 * math.cos(a), 0.58 - 0.03 * i),
              (0.045, 0.01, 0.07 + 0.03 * (i % 2)), rot=(0.1, 0, a))
# the chain at her waist: keys and scissors, her only sound
chain = Vector((0.11, -0.075, 1.04))
K.seg("chain", M["metal"], "hips", chain, chain + Vector((0.01, -0.01, -0.12)), 0.006, 0.006, n=4)
for i, d in enumerate(((0.012, -0.012, -0.15), (-0.008, -0.018, -0.16), (0.02, -0.005, -0.14))):
    K.box("key", M["metal"], "hips", chain + Vector(d), (0.012, 0.004, 0.04), rot=(0.2 * i, 0, 0.3 * i - 0.3))
for dx in (-1, 1):
    K.spike("scissors", M["metal"], "hips", chain + Vector((0.0, -0.012, -0.12)),
            chain + Vector((0.025 * dx, -0.03, -0.27)), 0.008, flat=0.4)

# legs: torn stockings, grey skin through the holes, old shoes on tiptoe
for s_ in (".L", ".R"):
    K.seg("thigh", M["stocking"], "thigh" + s_, J["hip" + s_], J["knee" + s_], 0.058, 0.04)
    K.seg("shin", M["stocking"], "shin" + s_, J["knee" + s_], J["ankle" + s_], 0.04, 0.026)
    K.blob("knee", M["stocking"], "shin" + s_, V(J, "knee" + s_), 0.042, seed=11)
    K.box("tear", M["skin"], "shin" + s_, V(J, "knee" + s_, "ankle" + s_, 0.35 + 0.2 * (s_ == ".R")) + Vector((0, -0.035, 0)),
          (0.045, 0.012, 0.07), rot=(0.05, 0, 0.2))
    K.seg("foot", M["shoe"], "foot" + s_, J["ankle" + s_], J["toe" + s_], 0.03, 0.022, flat=0.8)
    K.box("heel", M["shoe"], "foot" + s_, V(J, "ankle" + s_) + Vector((0, 0.025, -0.01)), (0.04, 0.035, 0.05))

body = K.join("Enfermeira")
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
height = max(v.co.z for v in body.data.vertices)

# --- rig + animations (world-axis turns from rest: X+ upright bones lean forward / hanging bones swing back,
# Z+ turns to her left, Y+ tilts to her left) ---------------------------------------------------------------
arm = lp.armature("EnfermeiraRig", {b: (J[h], J[t], p) for b, (h, t, p) in BONES.items()}, body)
P = lp.Poser(arm, body, {"feet": lambda n: n.startswith("foot"), "body": lambda n: True})
TILT = ("head", "Y", -22)  # her head always hangs to one side

P.action("Idle", 61, loop=True)  # perfectly still; once, the head snaps to the other shoulder and back
for fr, b, sn in ((1, 0, 0), (24, 1, 0), (40, 1, 0), (42, 1, 1), (50, 1, 1), (53, 0.5, 0), (61, 0, 0)):
    P.pose(fr, [("chest", "X", 2 * b), ("head", "Y", -22 + 38 * sn), ("head", "Z", -6 * sn),
                ("upper_arm.L", "Y", -2 * b), ("upper_arm.R", "Y", 2 * b)])


def legs(front, k):
    back = ".R" if front == ".L" else ".L"
    if k == "contact":
        return [("thigh" + front, "X", -24), ("shin" + front, "X", 6), ("thigh" + back, "X", 18), ("shin" + back, "X", 14)]
    return [("thigh" + front, "X", 2), ("thigh" + back, "X", -10), ("shin" + back, "X", 42)]


P.action("Walk", 25, loop=True)  # a tiptoe stalk: legs only, the upper body glides, arms hang dead still
for fr, front, k, sgn in ((1, ".L", "contact", 1), (7, ".L", "pass", 1), (13, ".R", "contact", -1),
                          (19, ".R", "pass", -1), (25, ".L", "contact", 1)):
    P.pose(fr, [("hips", "Z", 3 * sgn), ("chest", "Z", -3 * sgn), ("chest", "X", 4), TILT,
                ("upper_arm.L", "X", 6), ("upper_arm.R", "X", 4)] + legs(front, k))
    if fr == 1:
        stride = abs(P.P["foot.L"].tail.y - P.P["foot.R"].tail.y)

P.action("Attack", 30)  # syringe up over the shoulder, stabbed down on frame 13
P.pose(1, [TILT])
P.pose(9, [("chest", "X", -10), ("chest", "Z", 12), ("upper_arm.R", "X", -140), ("upper_arm.R", "Y", 15),
           ("forearm.R", "X", -75), ("hand.R", "X", -40), ("head", "Y", -10), ("thigh.R", "X", -8)])
P.pose(13, [("chest", "X", 28), ("chest", "Z", -10), ("upper_arm.R", "X", -55), ("forearm.R", "X", -5),
            ("head", "Y", -30), ("thigh.R", "X", -28), ("shin.R", "X", 10), ("thigh.L", "X", 12)])
P.pose(20, [("chest", "X", 26), ("chest", "Z", -10), ("upper_arm.R", "X", -45), ("head", "Y", -30),
            ("thigh.R", "X", -28), ("shin.R", "X", 10), ("thigh.L", "X", 12)])
P.pose(30, [TILT])

P.action("Hit", 16)
P.pose(1, [TILT])
P.pose(4, [("chest", "X", -16), ("head", "X", -28), ("head", "Y", 25), ("upper_arm.L", "Y", -25), ("upper_arm.R", "Y", 22)])
P.pose(16, [TILT])

P.action("Death", 45)  # the knees go, then she folds over sideways, the syringe last
P.pose(1, [TILT])
P.pose(6, [("chest", "X", -16), ("head", "X", -28), ("head", "Y", 25)])
KNEEL = [("thigh.L", "X", -50), ("thigh.R", "X", -45), ("shin.L", "X", 75), ("shin.R", "X", 80)]
P.pose(16, KNEEL + [("chest", "X", 20), ("head", "X", 30), TILT], ground="body")
P.pose(28, [("hips", "Y", -60)] + KNEEL + [("chest", "X", 15), ("head", "Y", -40), ("upper_arm.R", "Y", -40)], ground="body")
DOWN = [("hips", "Y", -86)] + KNEEL + [("chest", "X", 10), ("head", "Y", -50), ("upper_arm.R", "Y", -70),
                                       ("upper_arm.L", "X", -30)]
P.pose(36, DOWN, ground="body")
P.pose(45, DOWN + [("forearm.R", "X", -20)], ground="body")

arm.animation_data.action = bpy.data.actions["Idle_Loop"]
bpy.context.scene.render.fps = 30
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("personagens", "enfermeira"))
bpy.ops.export_scene.gltf(filepath=paths.character("enfermeira"), export_format="GLB",
                          export_animations=True, export_skins=True)
result = {"tris": tris, "verts": len(body.data.vertices), "height": round(height, 3), "bones": len(arm.data.bones),
          "actions": [a.name for a in bpy.data.actions], "stride": round(stride, 3),
          "walk_speed_m_s": round(2 * stride / (24 / 30), 2)}
print("RESULT", result)

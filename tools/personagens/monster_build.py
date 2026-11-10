# The mutant: tall, almost-human biped. One joint table J drives geometry, bones and skin weights.
# Runs inside Blender via the Blender MCP; saves monster.blend and exports monster.glb.
import bpy, math, os, random, sys, importlib
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import lowpoly as lp
importlib.reload(lp)
from lowpoly import V

lp.clear_scene()
rnd = random.Random(13)

# --- textures -------------------------------------------------------------------------------------------
W = 32
yy, xx = np.mgrid[0:W, 0:W]
v = np.ones((W, W, 4))
base = np.array([[rnd.uniform(0.85, 1.0) for _ in range(W)] for _ in range(W)])
v[:, :, :3] = base[:, :, None]
for _ in range(4):  # veins: faint purple random walks
    x, y = rnd.randrange(W), rnd.randrange(W)
    for _ in range(26):
        v[y % W, x % W, :3] = (0.80, 0.72, 0.82)
        x += rnd.choice((-1, 0, 1)); y += rnd.choice((0, 1, 1))
for _ in range(8):  # sores
    cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.uniform(1, 2.5)
    v[((xx - cx) ** 2 + (yy - cy) ** 2) < r * r, :3] = (1.0, 0.62, 0.6)
VEINS = lp.new_image("veins_32", v)

g = np.ones((W, W, 4))
g[:, :, :3] = np.array([[rnd.uniform(0.78, 1.0) for _ in range(W)] for _ in range(W)])[:, :, None]
GRIME = lp.new_image("grime_32", g)

SKIN = np.array((0.62, 0.64, 0.55))
F = 64
f = np.ones((F, F, 4)); f[:, :, :3] = SKIN
fy, fx = np.mgrid[0:F, 0:F]


def ell(cx, cy, rx, ry, col):
    f[((fx - cx) / rx) ** 2 + ((fy - cy) / ry) ** 2 <= 1, :3] = col


for cx in (21, 43):  # no eyes: bruised, sunken sockets
    ell(cx, 37, 6.5, 5.0, (0.46, 0.30, 0.31))
    ell(cx, 37, 4.5, 3.4, (0.10, 0.03, 0.04))
for y in range(44, 63):  # stitched scar up the forehead
    f[y, 34, :3] = (0.24, 0.10, 0.10)
    if y % 3 == 0:
        f[y, 32:37, :3] = (0.30, 0.14, 0.13)
for x0 in (29, 34):  # nose is gone: two pits
    f[27:29, x0:x0 + 2, :3] = (0.12, 0.04, 0.05)
for _ in range(9):  # lesions
    cx, cy = rnd.randrange(6, 58), rnd.randrange(4, 60)
    ell(cx, cy, 1.6, 1.2, (0.62, 0.30, 0.30))
f[0:6, :, :3] *= 0.8
FACE = lp.new_image("monster_face_64", f)

M = dict(
    skin=lp.mat("m_skin", SKIN, tex=VEINS),
    face=lp.mat("m_face", SKIN, face=FACE),
    raw=lp.mat("m_raw", (0.55, 0.20, 0.20), tex=VEINS),
    tumor=lp.mat("m_tumor", (0.72, 0.47, 0.44), tex=VEINS),
    bone=lp.mat("m_bone", (0.80, 0.76, 0.63), tex=GRIME),
    claw=lp.mat("m_claw", (0.18, 0.15, 0.12)),
    mouth=lp.mat("m_mouth", (0.09, 0.02, 0.03)),
    rag=lp.mat("m_rag", (0.30, 0.33, 0.32), tex=GRIME),     # what is left of a hospital gown
    band=lp.mat("m_band", (0.86, 0.86, 0.80), tex=GRIME),   # patient wristband
)

# --- joint table (Blender: +X = its left, -Y = front, Z up). Rest pose = hunched, digitigrade legs. ---------
J = {
    "pelvis": (0, 0.04, 1.10), "spine": (0, 0.03, 1.42), "chest": (0, -0.06, 1.78),
    "neck": (0, -0.20, 1.94), "skull": (0, -0.30, 2.16), "jaw0": (0, -0.22, 1.97), "chin": (0, -0.37, 1.83),
    "sh.L": (0.27, -0.02, 1.74), "el.L": (0.40, 0.02, 1.34), "wr.L": (0.45, -0.04, 0.95), "tip.L": (0.48, -0.10, 0.66),
    "sh.R": (-0.33, -0.02, 1.76), "el.R": (-0.50, 0.04, 1.38), "wr.R": (-0.57, -0.04, 1.00), "tip.R": (-0.62, -0.20, 0.50),
    "ex0": (-0.15, 0.16, 1.70), "ex1": (-0.30, 0.32, 1.52), "ex2": (-0.27, 0.24, 1.30),
}
for s, sx in ((".L", 1), (".R", -1)):
    J.update({"hip" + s: (sx * 0.13, 0.05, 1.10), "knee" + s: (sx * 0.15, -0.14, 0.72),
              "hock" + s: (sx * 0.15, 0.13, 0.30), "ball" + s: (sx * 0.15, -0.03, 0.05)})

BONES = {"hips": ("pelvis", "spine", None), "chest": ("spine", "chest", "hips"), "neck": ("chest", "neck", "chest"),
         "head": ("neck", "skull", "neck"), "jaw": ("jaw0", "chin", "head"),
         "upper_arm.L": ("sh.L", "el.L", "chest"), "forearm.L": ("el.L", "wr.L", "upper_arm.L"),
         "hand.L": ("wr.L", "tip.L", "forearm.L"),
         "upper_arm.R": ("sh.R", "el.R", "chest"), "forearm.R": ("el.R", "wr.R", "upper_arm.R"),
         "claw.R": ("wr.R", "tip.R", "forearm.R"),
         "extra_upper": ("ex0", "ex1", "chest"), "extra_fore": ("ex1", "ex2", "extra_upper")}
for s in (".L", ".R"):
    BONES.update({"thigh" + s: ("hip" + s, "knee" + s, "hips"), "shin" + s: ("knee" + s, "hock" + s, "thigh" + s),
                  "foot" + s: ("hock" + s, "ball" + s, "shin" + s)})


K = lp.Kit()
# torso: starved waist, wide ribcage, too-long neck
K.tube("hips", M["skin"], "hips", J["pelvis"], J["spine"], [(0, 0.17, 0.12), (0.45, 0.115, 0.085), (1, 0.14, 0.10)], n=8)
K.tube("chest", M["skin"], "chest", J["spine"], J["chest"],
       [(0, 0.14, 0.10), (0.45, 0.23, 0.16), (0.85, 0.24, 0.15), (1, 0.15, 0.11)], n=8)
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.06, 0.05)
for s, x in (("L", 0.25), ("R", -0.30)):
    K.blob("shoulder." + s, M["skin"], "chest", (x, -0.03, 1.73), 0.08, seed=len(s) + int(x * 10))
# exposed ribs through a torn patch on its left chest
K.box("wound", M["mouth"], "chest", (0.10, -0.165, 1.60), (0.13, 0.02, 0.17), rot=(-0.25, 0, 0.1))
for i, z in enumerate((1.53, 1.58, 1.63, 1.68)):
    K.box("rib", M["bone"], "chest", (0.10, -0.172 - 0.006 * i, z), (0.11, 0.012, 0.01), rot=(-0.25, 0, 0.1 + 0.06 * i))
# bony ridge down the spine
for i, t in enumerate((0.15, 0.4, 0.65, 0.9)):
    for bone, a, b in (("hips", "pelvis", "spine"), ("chest", "spine", "chest")):
        p = V(J, a, b, t) + Vector((0, 0.10 + 0.04 * (bone == "chest") * math.sin(t * math.pi), 0))
        K.spike("ridge", M["bone"], bone, p, p + Vector((0, 0.09, 0.05)), 0.025)
# growths
for i, (loc, r) in enumerate((((-0.36, 0.04, 1.84), 0.10), ((-0.26, 0.10, 1.80), 0.075), ((-0.42, 0.0, 1.66), 0.065),
                              ((0.05, 0.13, 1.55), 0.07))):
    K.blob("tumor", M["tumor"], "chest", loc, r, seed=i)
K.blob("tumor", M["tumor"], "thigh.L", V(J, "hip.L", "knee.L", 0.5) + Vector((0.07, -0.02, 0)), 0.06, seed=9)

# head: long, eyeless skull with a painted face; the jaw hangs too low
head = K.tube("head", M["skin"], "head", J["neck"], J["skull"],
              [(0, 0.06, 0.06), (0.22, 0.10, 0.11), (0.6, 0.115, 0.13), (0.88, 0.085, 0.10), (1, 0.035, 0.045)], n=10)
head.data.materials.append(M["face"])
L = (V(J, "skull") - V(J, "neck")).length
uv = head.data.uv_layers.new(name="FaceUV")
for p in head.data.polygons:
    if p.normal.y < -0.3 and 0.12 * L < p.center.z < 0.92 * L:
        p.material_index = 1
    for li in p.loop_indices:
        co = head.data.vertices[head.data.loops[li].vertex_index].co
        uv.data[li].uv = (0.5 + co.x / 0.24, co.z / L)
K.seg("jaw", M["skin"], "jaw", J["jaw0"], J["chin"], 0.05, 0.034, flat=0.8)
K.box("mouth", M["mouth"], "head", (0, -0.27, 1.94), (0.085, 0.05, 0.06), rot=(0.5, 0, 0))
for x in (-0.035, -0.012, 0.012, 0.035):  # teeth, top and bottom
    top = Vector((x, -0.285, 1.975))
    K.spike("tooth", M["bone"], "head", top, top + Vector((0, -0.01, -0.045)), 0.008)
    low = V(J, "jaw0", "chin", 0.55) + Vector((x, -0.035, 0.01))
    K.spike("tooth", M["bone"], "jaw", low, low + Vector((0, -0.005, 0.04)), 0.007)

# left arm: thin, too long, fingers past the knee; hospital wristband
K.seg("arm", M["skin"], "upper_arm.L", J["sh.L"], J["el.L"], 0.05, 0.042)
K.seg("arm", M["skin"], "forearm.L", J["el.L"], J["wr.L"], 0.042, 0.032)
K.seg("band", M["band"], "forearm.L", V(J, "el.L", "wr.L", 0.82), V(J, "el.L", "wr.L", 0.94), 0.04, 0.04)
K.seg("hand", M["skin"], "hand.L", J["wr.L"], V(J, "wr.L", "tip.L", 0.45), 0.035, 0.045, flat=0.35)
for i, dx in enumerate((-0.03, 0.0, 0.03)):
    a = V(J, "wr.L", "tip.L", 0.4) + Vector((dx, 0, 0))
    K.spike("finger", M["skin"], "hand.L", a, V(J, "tip.L") + Vector((dx * 1.6, -0.02 * i, -0.05 * (i == 1))), 0.014)
# right arm: swollen, ends in a bone blade
K.tube("arm", M["skin"], "upper_arm.R", J["sh.R"], J["el.R"], [(0, 0.10, 0.09), (0.5, 0.12, 0.10), (1, 0.085, 0.08)])
K.tube("arm", M["skin"], "forearm.R", J["el.R"], J["wr.R"], [(0, 0.085, 0.08), (0.6, 0.095, 0.085), (1, 0.06, 0.055)])
K.spike("blade", M["bone"], "claw.R", V(J, "wr.R") + Vector((0, 0.01, 0.02)), J["tip.R"], 0.06, flat=0.3, up=(0, -1, 0))
for t, off in ((0.35, (-0.06, 0.05, 0)), (0.7, (-0.05, 0.03, 0.02))):
    p = V(J, "el.R", "wr.R", t)
    K.spike("spur", M["bone"], "forearm.R", p, p + Vector(off) * 2.2, 0.022)
# third arm, withered, out of its back
K.seg("extra", M["raw"], "extra_upper", J["ex0"], J["ex1"], 0.03, 0.025)
K.seg("extra", M["raw"], "extra_fore", J["ex1"], J["ex2"], 0.025, 0.018)
for dx in (-0.015, 0.015):
    K.spike("extra_finger", M["claw"], "extra_fore", V(J, "ex2") + Vector((dx, 0, 0)), V(J, "ex2") + Vector((dx * 2, -0.03, -0.07)), 0.008)

# legs: digitigrade, rags of the gown on the thighs
for s in (".L", ".R"):
    sx = 1 if s == ".L" else -1
    K.tube("thigh", M["skin"], "thigh" + s, J["hip" + s], J["knee" + s], [(0, 0.09, 0.09), (1, 0.065, 0.06)])
    K.seg("rag", M["rag"], "thigh" + s, J["hip" + s], V(J, "hip" + s, "knee" + s, 0.5), 0.105, 0.09)
    K.box("rag_strip", M["rag"], "thigh" + s, V(J, "hip" + s, "knee" + s, 0.62) + Vector((sx * 0.06, -0.06, 0)),
          (0.035, 0.012, 0.16), rot=(0.4, 0, sx * 0.2))
    K.seg("shin", M["skin"], "shin" + s, J["knee" + s], J["hock" + s], 0.058, 0.04)
    K.spike("spur", M["bone"], "shin" + s, V(J, "knee" + s), V(J, "knee" + s) + Vector((0, -0.07, 0.03)), 0.025)
    K.seg("foot", M["skin"], "foot" + s, J["hock" + s], J["ball" + s], 0.042, 0.032)
    for dx in (-0.035, 0.0, 0.035):
        a = V(J, "ball" + s) + Vector((dx, 0, 0))
        K.spike("toe", M["claw"], "foot" + s, a, a + Vector((dx * 0.8, -0.13, -0.035)), 0.018)
K.tube("rag", M["rag"], "hips", (0, 0.04, 0.98), (0, 0.04, 1.2), [(0, 0.20, 0.15), (1, 0.15, 0.115)], n=8)
for i in range(7):  # torn hem
    a = math.radians(-70 + i * 47)
    K.box("rag_strip", M["rag"], "hips", (0.2 * math.sin(a), 0.04 - 0.15 * math.cos(a), 0.93 - 0.04 * (i % 3)),
          (0.05, 0.012, 0.12 + 0.05 * (i % 3)), rot=(0.15, 0, a))

body = K.join("Monster")
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
height = max(v.co.z for v in body.data.vertices)

# --- rig + animations ------------------------------------------------------------------------------------
arm = lp.armature("MonsterRig", {b: (J[h], J[t], p) for b, (h, t, p) in BONES.items()}, body)
P = lp.Poser(arm, body, {"feet": lambda n: n.startswith("foot"), "body": lambda n: True})
# world-axis turns from the rest pose. X+: upright bones lean forward, hanging bones swing back;
# Z+: turns towards its left; Y+: tilts towards its left (raises the right arm sideways).

P.action("Idle", 61, loop=True)  # slow breath, one sudden head twitch
for f, b, tw in ((1, 0, 0), (16, 0.5, 0), (31, 1, 0), (33, 0.95, 1), (37, 0.85, 1), (41, 0.75, 0), (61, 0, 0)):
    P.pose(f, [("chest", "X", 4 - 5 * b), ("head", "Z", 35 * tw), ("head", "Y", -18 * tw), ("jaw", "X", 6 + 8 * b),
               ("extra_upper", "X", -20 + 45 * tw), ("upper_arm.R", "Y", 3 * b), ("upper_arm.L", "Y", -3 * b)])


def legs(front, k, strong=1.0):
    """Digitigrade gait key. k: 'contact' (front leg reaching, back leg pushing off) or 'pass'."""
    back = ".R" if front == ".L" else ".L"
    if k == "contact":
        return [("thigh" + front, "X", -28 * strong), ("shin" + front, "X", 8), ("foot" + front, "X", -15),
                ("thigh" + back, "X", 22), ("shin" + back, "X", -10), ("foot" + back, "X", 30)]
    return [("thigh" + front, "X", 5), ("thigh" + back, "X", -12), ("shin" + back, "X", 25), ("foot" + back, "X", 20)]


P.action("Walk", 41, loop=True)  # lurching limp: the right leg takes a shorter step
WALK = ((1, ".L", "contact", 1), (11, ".L", "pass", 1), (21, ".R", "contact", -1), (31, ".R", "pass", -1),
        (41, ".L", "contact", 1))
for f, front, k, sgn in WALK:
    lurch = 14 if (front == ".R" and k == "contact") else 6
    P.pose(f, [("hips", "Z", 5 * sgn), ("chest", "X", lurch), ("chest", "Z", -10 * sgn)]
           + legs(front, k, 0.65 if front == ".R" else 1.0)
           + [("head", "Z", 8 * sgn), ("head", "Y", -8 * sgn), ("jaw", "X", 10),
              ("upper_arm.L", "X", 18 * sgn), ("upper_arm.R", "X", 8 - 6 * sgn), ("extra_upper", "X", 30 * sgn)])
    if f == 1:
        stride = abs(P.P["foot.L"].tail.y - P.P["foot.R"].tail.y)

P.action("Alert", 40)  # rears up and screams when it notices you
P.pose(1, [("chest", "X", 4)])
SCREAM = [("chest", "X", -18), ("neck", "X", -20), ("head", "X", -35), ("jaw", "X", 40),
          ("upper_arm.L", "Y", -35), ("upper_arm.R", "Y", 30), ("extra_upper", "X", -40)]
for f, shake in ((10, 0), (16, 6), (22, -6), (28, 4)):
    P.pose(f, SCREAM + [("head", "Z", shake)])
P.pose(40, [("chest", "X", 4)])

P.action("Attack", 36)  # overhead claw swing, hit on frame 18
P.pose(1, [("chest", "X", 4)])
P.pose(12, [("chest", "Z", -25), ("chest", "X", -10), ("upper_arm.R", "Y", 125), ("forearm.R", "X", -30),
            ("head", "Z", -10), ("thigh.L", "X", -15)])
P.pose(18, [("chest", "Z", 30), ("chest", "X", 25), ("upper_arm.R", "X", -75), ("upper_arm.R", "Z", 25),
            ("forearm.R", "X", -10), ("head", "Z", 10), ("jaw", "X", 25), ("thigh.L", "X", -30), ("thigh.R", "X", 18)])
P.pose(24, [("chest", "Z", 40), ("chest", "X", 30), ("upper_arm.R", "X", -30), ("upper_arm.R", "Z", 55),
            ("thigh.L", "X", -30), ("thigh.R", "X", 18)])
P.pose(36, [("chest", "X", 4)])

P.action("Hit", 16)
P.pose(1, [("chest", "X", 4)])
P.pose(4, [("chest", "X", -22), ("head", "X", -30), ("head", "Z", 20), ("jaw", "X", 30),
           ("upper_arm.L", "Y", -25), ("upper_arm.R", "Y", 20), ("extra_upper", "X", -45)])
P.pose(16, [("chest", "X", 4)])

P.action("Death", 50)  # buckles at the knees, pitches forward, the third arm twitches last
P.pose(1, [("chest", "X", 4)])
P.pose(5, [("chest", "X", -22), ("head", "X", -30), ("head", "Z", 20), ("jaw", "X", 30), ("extra_upper", "X", -45)])
KNEEL = [("thigh.L", "X", -55), ("thigh.R", "X", -50), ("shin.L", "X", 20), ("shin.R", "X", 20)]
P.pose(16, KNEEL + [("chest", "X", 30), ("head", "X", 25), ("jaw", "X", 20)], ground="body")
P.pose(26, [("hips", "X", 45)] + KNEEL + [("chest", "X", 30), ("head", "X", 20), ("upper_arm.L", "X", -40),
                                           ("upper_arm.R", "X", -40)], ground="body")
DOWN = [("hips", "X", 88)] + KNEEL + [("chest", "X", 5), ("head", "Z", 50), ("jaw", "X", 35),
                                      ("upper_arm.L", "Y", -60), ("upper_arm.R", "Y", 70)]
P.pose(32, DOWN, ground="body")
P.pose(40, DOWN + [("extra_upper", "X", -35)], ground="body")
P.pose(50, DOWN, ground="body")

arm.animation_data.action = bpy.data.actions["Idle_Loop"]
bpy.context.scene.render.fps = 30
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("personagens", "monster"))
bpy.ops.export_scene.gltf(filepath=paths.character("monster"), export_format="GLB",
                          export_animations=True, export_skins=True)
result = {"tris": tris, "verts": len(body.data.vertices), "height": round(height, 3), "bones": len(arm.data.bones),
          "actions": [a.name for a in bpy.data.actions], "stride": round(stride, 3),
          "walk_speed_m_s": round(2 * stride / (40 / 30), 2)}

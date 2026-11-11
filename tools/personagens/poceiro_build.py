# O Poceiro (docs/MUTANTES_NOITE.md): the second of the village's night mutants. The well-digger who went down the
# square's well and stayed there; the one who pulls the buckets back at night. A huge hunched man, 2.3 m, blind: the
# skin has grown over his eyes; he hunts by ear, big torn ears and the head always cocked. Pale, waterlogged skin with
# green slime, a rotten work overall and rubber boots, hands the size of shovels. A rope round his waist with a tin
# bucket that clanks and sloshes as he walks (his warning, like the Enfermeira's keys).
# Same kit as the mutant (lowpoly.py). Headless: blender -b --factory-startup --python tools/personagens/poceiro_build.py
#   -> blender/personagens/poceiro.blend, godot_demo/models/characters/poceiro.glb
import bpy, math, os, random, sys, importlib
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import lowpoly as lp
importlib.reload(lp)
from lowpoly import V

lp.clear_scene()
rnd = random.Random(1977)

# --- textures -------------------------------------------------------------------------------------------
W = 32
yy, xx = np.mgrid[0:W, 0:W]


def grime(lo):
    g = np.ones((W, W, 4)); g[:, :, :3] = np.array([[rnd.uniform(lo, 1.0) for _ in range(W)] for _ in range(W)])[:, :, None]
    return g


k = grime(0.84)  # waterlogged skin: wrinkles as faint dark lines, green slime blotches
for y in range(1, W, 3):
    k[y, :, :3] *= 0.9
for _ in range(9):
    cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.uniform(1.0, 3.0)
    m_ = ((xx - cx) ** 2 + (yy - cy) ** 2) < r * r
    k[m_, :3] = k[m_, :3] * 0.6 + np.array((0.55, 0.64, 0.50)) * 0.4
SKIN_T = lp.new_image("pele_32", k)
c = grime(0.75)  # the overall: mud and slime, darker towards the hems
for _ in range(8):
    cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.uniform(1.0, 2.5)
    c[((xx - cx) ** 2 + (yy - cy) ** 2) < r * r, :3] = rnd.choice(((0.55, 0.62, 0.45), (0.5, 0.42, 0.34)))
CLOTH = lp.new_image("macacao_32", c)
GRIME = lp.new_image("grime_32", grime(0.7))

SKIN = np.array((0.64, 0.64, 0.59))
F = 64
f = np.ones((F, F, 4)); f[:, :, :3] = SKIN
fy, fx = np.mgrid[0:F, 0:F]


def ell(cx, cy, rx, ry, col, mix=1.0):
    m = ((fx - cx) / rx) ** 2 + ((fy - cy) / ry) ** 2 <= 1
    f[m, :3] = f[m, :3] * (1 - mix) + np.array(col) * mix


for cx in (21, 43):  # where the eyes were: shallow dents, skin grown over, a seam of scar
    ell(cx, 36, 7, 4.5, (0.40, 0.44, 0.40), 0.55)
    f[36, cx - 5:cx + 6, :3] = (0.33, 0.30, 0.30)
ell(32, 28, 3, 4, (0.45, 0.48, 0.44), 0.5)  # the nose, two holes
f[25, 30:32, :3] = 0.1; f[25, 33:35, :3] = 0.1
for _ in range(30):  # slime
    f[rnd.randrange(20, 60), rnd.randrange(F), :3] = (0.48, 0.62, 0.42)
FACE = lp.new_image("poceiro_face_64", f)

M = dict(
    skin=lp.mat("p_pele", SKIN, tex=SKIN_T),
    face=lp.mat("p_rosto", SKIN, face=FACE),
    cloth=lp.mat("p_macacao", (0.33, 0.36, 0.38), tex=CLOTH),
    boot=lp.mat("p_bota", (0.05, 0.05, 0.05), tex=GRIME),
    rope=lp.mat("p_corda", (0.45, 0.38, 0.26), tex=GRIME),
    tin=lp.mat("p_lata", (0.42, 0.42, 0.40), tex=GRIME),
    mouth=lp.mat("p_boca", (0.08, 0.04, 0.04)),
    tooth=lp.mat("p_dente", (0.62, 0.58, 0.42)),
    nail=lp.mat("p_unha", (0.25, 0.22, 0.18)),
    hair=lp.mat("p_cabelo", (0.10, 0.10, 0.09)),
)

# --- joint table (+X = his left, -Y = front, Z up). Rest: hunched, chest forward, head out, arms hanging. -------
J = {"pelvis": (0, 0.05, 1.12), "spine": (0, 0.02, 1.45), "chest": (0, -0.08, 1.78),
     "neck": (0, -0.18, 1.94), "skull": (0, -0.26, 2.14)}
for s_, sx in ((".L", 1), (".R", -1)):
    J.update({"sh" + s_: (sx * 0.31, -0.06, 1.80), "el" + s_: (sx * 0.42, -0.03, 1.35), "wr" + s_: (sx * 0.45, -0.08, 0.92),
              "tip" + s_: (sx * 0.47, -0.12, 0.60),
              "hip" + s_: (sx * 0.16, 0.05, 1.10), "knee" + s_: (sx * 0.19, -0.04, 0.60),
              "ankle" + s_: (sx * 0.19, 0.05, 0.12), "toe" + s_: (sx * 0.19, -0.16, 0.0)})
BONES = {"hips": ("pelvis", "spine", None), "chest": ("spine", "chest", "hips"), "neck": ("chest", "neck", "chest"),
         "head": ("neck", "skull", "neck")}
for s_ in (".L", ".R"):
    BONES.update({"upper_arm" + s_: ("sh" + s_, "el" + s_, "chest"), "forearm" + s_: ("el" + s_, "wr" + s_, "upper_arm" + s_),
                  "hand" + s_: ("wr" + s_, "tip" + s_, "forearm" + s_),
                  "thigh" + s_: ("hip" + s_, "knee" + s_, "hips"), "shin" + s_: ("knee" + s_, "ankle" + s_, "thigh" + s_),
                  "foot" + s_: ("ankle" + s_, "toe" + s_, "shin" + s_)})

K = lp.Kit()
# torso: a barrel of a body, the overall's bib over the belly, bare shoulders and back
K.tube("seat", M["cloth"], "hips", (0, 0.06, 0.93), J["pelvis"], [(0, 0.19, 0.15), (1, 0.23, 0.19)], n=12)
K.tube("belly", M["cloth"], "hips", J["pelvis"], J["spine"], [(0, 0.23, 0.19), (0.5, 0.26, 0.23, -0.03), (1, 0.245, 0.2, -0.01)], n=12)
K.tube("chest", M["skin"], "chest", J["spine"], J["chest"],
       [(0, 0.245, 0.2), (0.4, 0.28, 0.22), (0.75, 0.33, 0.21, 0.02), (0.93, 0.27, 0.17, 0.02), (1, 0.15, 0.11)], n=12)
for sx in (1, -1):  # the neck sits deep between heavy trapezius muscles
    K.blob("trap", M["skin"], "chest", (sx * 0.15, -0.04, 1.86), (0.13, 0.11, 0.08), seed=9, lump=0.1)
K.box("bib", M["cloth"], "chest", V(J, "spine", "chest", 0.35) + Vector((0, -0.2, 0)), (0.3, 0.05, 0.28), rot=(0.25, 0, 0))
for sx in (1, -1):
    K.seg("strap", M["cloth"], "chest", V(J, "spine", "chest", 0.5) + Vector((sx * 0.12, -0.21, 0.05)),
          (sx * 0.17, 0.05, 1.82), 0.025, 0.025, n=4)
K.blob("hump", M["skin"], "chest", V(J, "spine", "chest", 0.85) + Vector((0, 0.15, 0.04)), (0.25, 0.17, 0.17), seed=3, lump=0.15)
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.11, 0.09)

# head: small for the body, bald with a few lank strands, eyes grown over, big torn ears, a slack jaw
head = K.tube("head", M["skin"], "head", J["neck"], J["skull"],
              [(0, 0.085, 0.09), (0.3, 0.10, 0.11), (0.65, 0.105, 0.115), (0.92, 0.085, 0.09), (1, 0.035, 0.04)], n=10)
head.data.materials.append(M["face"])
L = (V(J, "skull") - V(J, "neck")).length
uv = head.data.uv_layers.new(name="FaceUV")
for p in head.data.polygons:
    if p.normal.y < -0.3 and 0.15 * L < p.center.z < 0.9 * L:
        p.material_index = 1
    for li in p.loop_indices:
        co = head.data.vertices[head.data.loops[li].vertex_index].co
        uv.data[li].uv = (0.5 + co.x / 0.22, co.z / L)
hd = (V(J, "skull") - V(J, "neck")).normalized()
for sx in (1, -1):  # the ears: big, flared forward, the left one torn
    ear = V(J, "neck", "skull", 0.45) + Vector((sx * 0.105, 0.02, 0))
    K.blob("ear", M["skin"], "head", ear + Vector((sx * 0.02, 0.0, 0.0)), (0.018, 0.055, 0.07), seed=40 + sx, lump=0.3)
    K.box("ear_shell", M["mouth"], "head", ear + Vector((sx * 0.03, -0.01, 0.0)), (0.006, 0.035, 0.045))
for i in range(5):  # lank strands of hair down the back of the skull
    a = V(J, "neck", "skull", 0.9) + Vector(((i - 2) * 0.03, 0.05, 0))
    K.spike("hair", M["hair"], "head", a, a + Vector(((i - 2) * 0.01, 0.12, -0.16)), 0.008, n=3)
jaw = V(J, "neck", "skull", 0.2) + Vector((0, -0.1, -0.01))
K.box("mouth", M["mouth"], "head", jaw, (0.11, 0.04, 0.05))
for i in range(5):  # teeth, broken and few
    x = -0.04 + 0.02 * i
    if i != 3:
        K.spike("tooth", M["tooth"], "head", jaw + Vector((x, -0.02, 0.025)), jaw + Vector((x, -0.025, -0.0 - 0.01 * (i % 2))), 0.007, n=3)
K.box("chin", M["skin"], "head", jaw + Vector((0, 0.0, -0.045)), (0.12, 0.08, 0.04))

# arms: bare, thick, too long; hands like shovels with broken nails
for s_, sx in ((".L", 1), (".R", -1)):
    K.blob("shoulder", M["skin"], "upper_arm" + s_, V(J, "sh" + s_), 0.11, seed=5)
    K.tube("arm", M["skin"], "upper_arm" + s_, J["sh" + s_], J["el" + s_], [(0, 0.10, 0.10), (0.35, 0.115, 0.105), (1, 0.075, 0.07)], n=8)
    K.tube("arm", M["skin"], "forearm" + s_, J["el" + s_], J["wr" + s_], [(0, 0.08, 0.075), (0.3, 0.092, 0.082), (1, 0.06, 0.052)], n=8)
    K.tube("hand", M["skin"], "hand" + s_, J["wr" + s_], V(J, "wr" + s_, "tip" + s_, 0.55),
           [(0, 0.055, 0.04), (1, 0.075, 0.035)], n=6, up=(0, 1, 0))
    for i, dy in enumerate((-0.05, -0.017, 0.017, 0.05)):
        a = V(J, "wr" + s_, "tip" + s_, 0.5) + Vector((0, dy, 0))
        b = V(J, "tip" + s_) + Vector((sx * 0.01, dy * 1.2, 0.02 * abs(i - 1.5)))
        K.seg("finger", M["skin"], "hand" + s_, a, b, 0.02, 0.015, n=4)
        K.spike("nail", M["nail"], "hand" + s_, b, b + (b - a).normalized() * 0.03, 0.012, n=3)
    K.seg("thumb", M["skin"], "hand" + s_, V(J, "wr" + s_, "tip" + s_, 0.25), V(J, "wr" + s_, "tip" + s_, 0.5) + Vector((0, -0.08, 0)), 0.022, 0.016, n=4)

# legs: the overall to the boots, rubber boots to the knee
for s_ in (".L", ".R"):
    K.seg("thigh", M["cloth"], {"thigh" + s_: 1.0}, J["hip" + s_], J["knee" + s_], 0.13, 0.1, n=8)
    K.seg("shin", M["cloth"], "shin" + s_, J["knee" + s_], V(J, "knee" + s_, "ankle" + s_, 0.3), 0.1, 0.09, n=8)
    K.seg("boot", M["boot"], "shin" + s_, V(J, "knee" + s_, "ankle" + s_, 0.25), J["ankle" + s_], 0.105, 0.085, n=8)
    K.seg("foot", M["boot"], "foot" + s_, V(J, "ankle" + s_) + Vector((0, 0.06, 0)), J["toe" + s_], 0.085, 0.065, n=6, flat=0.7)
    K.box("sole", M["boot"], "foot" + s_, V(J, "ankle" + s_, "toe" + s_, 0.5) + Vector((0, 0.02, -0.07)), (0.15, 0.3, 0.035))

# the rope round his waist and the bucket on it, at his right hip
waist = V(J, "pelvis", "spine", 0.45)
K.tube("rope", M["rope"], "hips", waist - Vector((0, 0, 0.025)), waist + Vector((0, 0, 0.025)), [(0, 0.265, 0.235), (1, 0.265, 0.235)], n=10, caps=False)
knot = waist + Vector((-0.24, -0.08, 0))
pail = knot + Vector((-0.07, -0.02, -0.36))
K.seg("rope", M["rope"], "hips", knot, pail + Vector((0, 0, 0.17)), 0.012, 0.012, n=4)
K.tube("bucket", M["tin"], "hips", pail - Vector((0, 0, 0.13)), pail + Vector((0, 0, 0.13)), [(0, 0.1, 0.1), (1, 0.13, 0.13)], n=8, caps=False)
K.tube("bucket_floor", M["tin"], "hips", pail - Vector((0, 0, 0.13)), pail - Vector((0, 0, 0.12)), [(0, 0.1, 0.1), (1, 0.1, 0.1)], n=8)
K.seg("handle", M["tin"], "hips", pail + Vector((0.12, 0, 0.13)), pail + Vector((0, 0, 0.18)), 0.006, 0.006, n=3)
K.seg("handle", M["tin"], "hips", pail + Vector((-0.12, 0, 0.13)), pail + Vector((0, 0, 0.18)), 0.006, 0.006, n=3)

body = K.join("Poceiro")
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
height = max(v.co.z for v in body.data.vertices)

# --- rig + animations: world aims, parents first (front -Y, his left +X); turns after ---------------------------
arm = lp.armature("PoceiroRig", {b: (J[h], J[t], p) for b, (h, t, p) in BONES.items()}, body)
P = lp.Poser(arm, body, {"feet": lambda n: n.startswith("foot"), "body": lambda n: True})


def rest_dir(a, b):
    return tuple(Vector(J[b]) - Vector(J[a]))


def sides(parts):
    out = []
    for bone, d in parts:
        out += [(bone + ".L", d), (bone + ".R", (-d[0], d[1], d[2]))]
    return out


SPINE = [("hips", rest_dir("pelvis", "spine")), ("chest", rest_dir("spine", "chest")), ("neck", rest_dir("chest", "neck"))]
HANG = sides([("upper_arm", (0.15, 0.06, -1)), ("forearm", (0.05, -0.12, -1)), ("hand", (0.04, -0.12, -1))])


LEFT_HANG = [a for a in HANG if a[0].endswith(".L")]


def cock(deg):  # the head cocked, listening, one ear up
    return [("head", "Y", deg)]


P.action("Idle", 61, loop=True)  # stands still, listening: the head cocked one way, slowly the other; breathes heavily
for fr, tilt, look, br in ((1, 18, 8, 0), (16, 22, 12, 1), (30, 14, 0, 0), (38, -16, -14, 0), (52, -20, -10, 1), (61, 18, 8, 0)):
    P.pose(fr, cock(tilt) + [("head", "Z", look), ("chest", "X", -3 * br)], aims=SPINE + HANG)

P.action("Listen", 45)  # froze at a sound: the head swings to it, an ear up, a hand half raised; then the other way
P.pose(1, cock(18), aims=SPINE + HANG)
P.pose(8, cock(34) + [("head", "Z", 25), ("chest", "X", 6)], aims=SPINE + LEFT_HANG +
       [("upper_arm.R", (-0.5, -0.5, -0.6)), ("forearm.R", (0.2, -0.6, 0.6)), ("hand.R", (0.2, -0.3, 0.9))])
P.pose(24, cock(34) + [("head", "Z", 25), ("chest", "X", 6)], aims=SPINE + LEFT_HANG +
       [("upper_arm.R", (-0.5, -0.5, -0.6)), ("forearm.R", (0.2, -0.6, 0.6)), ("hand.R", (0.2, -0.3, 0.9))])
P.pose(32, cock(-28) + [("head", "Z", -20), ("chest", "X", 4)], aims=SPINE + HANG)
P.pose(45, cock(18), aims=SPINE + HANG)


def legs(front, kind):
    back = ".R" if front == ".L" else ".L"
    if kind == "contact":
        return [("thigh" + front, "X", -26), ("shin" + front, "X", 8), ("thigh" + back, "X", 20), ("shin" + back, "X", 16)]
    return [("thigh" + front, "X", 4), ("thigh" + back, "X", -14), ("shin" + back, "X", 50)]


P.action("Walk", 33, loop=True)  # a heavy, lurching stride; the arms swing low, the head pushed out, cocked
for fr, front, kind, sg in ((1, ".L", "contact", 1), (9, ".L", "pass", 1), (17, ".R", "contact", -1),
                            (25, ".R", "pass", -1), (33, ".L", "contact", 1)):
    P.pose(fr, legs(front, kind) + cock(14) + [("hips", "Z", 6 * sg), ("chest", "Z", -8 * sg), ("chest", "Y", 5 * sg),
                                               ("upper_arm.L", "X", 18 * sg), ("upper_arm.R", "X", -18 * sg)],
           aims=SPINE + HANG)
    if fr == 1:
        stride = abs(P.P["foot.L"].tail.y - P.P["foot.R"].tail.y)

P.action("Attack", 36)  # both fists clasped high over the head, then down like a sledgehammer on frame 20
P.pose(1, cock(14), aims=SPINE + HANG)
UP = sides([("upper_arm", (0.15, 0.25, 1)), ("forearm", (-0.35, 0.3, 1)), ("hand", (-0.3, 0.4, 0.8))])
P.pose(12, [("chest", "X", -14), ("head", "X", -10)], aims=SPINE + UP)
P.pose(15, [("chest", "X", -18), ("head", "X", -12)], aims=SPINE + UP)
DOWN = sides([("upper_arm", (0.08, -1, -0.3)), ("forearm", (-0.15, -0.7, -1)), ("hand", (-0.2, -0.3, -1))])
SMASH = [("chest", "X", 34), ("head", "X", 10), ("thigh.L", "X", -30), ("shin.L", "X", 18), ("thigh.R", "X", 14)]
P.pose(20, SMASH, aims=SPINE + DOWN)
P.pose(27, SMASH, aims=SPINE + DOWN)
P.pose(36, cock(14), aims=SPINE + HANG)

P.action("Hit", 16)
P.pose(1, cock(14), aims=SPINE + HANG)
P.pose(5, [("chest", "X", -14), ("head", "X", -24), ("head", "Y", -20)], aims=SPINE + sides([("upper_arm", (0.5, 0.2, -1))]))
P.pose(16, cock(14), aims=SPINE + HANG)

P.action("Death", 50)  # staggers, the knees go, then he falls forward on his face
P.pose(1, cock(14), aims=SPINE + HANG)
P.pose(8, [("chest", "X", -16), ("head", "X", -26)], aims=SPINE + HANG)
KNEEL = [("thigh.L", "X", -80), ("thigh.R", "X", -75), ("shin.L", "X", 85), ("shin.R", "X", 90)]
P.pose(20, KNEEL + [("chest", "X", 20), ("head", "X", 20)], aims=SPINE + HANG, ground="body")
FLAT = [("hips", "X", 84), ("thigh.L", "X", -8), ("thigh.R", "X", -2), ("shin.L", "X", 14), ("shin.R", "X", 24),
        ("head", "Z", 70)]
P.pose(34, FLAT, aims=SPINE + sides([("upper_arm", (0.4, -0.2, -1))]), ground="body")
P.pose(50, FLAT, aims=SPINE + sides([("upper_arm", (0.6, -0.4, -1)), ("forearm", (0.3, -1, -0.3))]), ground="body")

P.action("Climb", 25, loop=True)  # hand over hand up (or down) the well's wall: one arm reaches high, the other pulls
for fr, sg in ((1, 1), (13, -1), (25, 1)):
    hi, lo = (".L", ".R") if sg > 0 else (".R", ".L")
    P.pose(fr, cock(10) + [("thigh" + hi, "X", -50), ("shin" + hi, "X", 60), ("thigh" + lo, "X", -10), ("shin" + lo, "X", 20)],
           aims=SPINE + [("upper_arm" + hi, (0.25 * (1 if hi == ".L" else -1), -0.35, 1)), ("forearm" + hi, (0, -0.4, 1)),
                         ("hand" + hi, (0, -0.5, 1)),
                         ("upper_arm" + lo, (0.4 * (1 if lo == ".L" else -1), -0.6, 0.3)), ("forearm" + lo, (0, -0.4, 1)),
                         ("hand" + lo, (0, -0.8, 0.2))], ground="body")

arm.animation_data.action = bpy.data.actions["Idle_Loop"]
bpy.context.scene.render.fps = 30
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("personagens", "poceiro"))
bpy.ops.export_scene.gltf(filepath=paths.character("poceiro"), export_format="GLB",
                          export_animations=True, export_skins=True)
result = {"tris": tris, "verts": len(body.data.vertices), "height": round(height, 3), "bones": len(arm.data.bones),
          "actions": [a.name for a in bpy.data.actions], "stride": round(stride, 3),
          "walk_speed_m_s": round(2 * stride / (32 / 30), 2)}
print("RESULT", result)

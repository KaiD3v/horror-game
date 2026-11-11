# A Bruxa (docs/MUTANTES_NOITE.md): the first of the village's night mutants. What the big black moth is called
# in the interior, the one that comes in through the window and means a death in the house. She was the woman taken
# from casa_04. Bone-thin and hunched, grey-brown skin under dust; her arms grew into moth wings: three finger bones
# fanned out from each wrist with a dusty membrane down to the thighs, an eye spot on each. Huge black eyes that
# throw the lantern back (eyeshine, the b_brilho material), plumed antennae, a curled tongue, a furry collar, rags of
# a cotton nightgown. Perches folded on the roof ridges, glides down to the light, scuttles on wrists and feet.
# Same kit as the mutant (lowpoly.py); the membrane is skinned per vertex between the arm and the body.
# Headless: blender -b --factory-startup --python tools/personagens/bruxa_build.py
#   -> blender/personagens/bruxa.blend, godot_demo/models/characters/bruxa.glb
import bpy, math, os, random, sys, importlib
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import lowpoly as lp
importlib.reload(lp)
from lowpoly import V

lp.clear_scene()
rnd = random.Random(1976)

# --- textures -------------------------------------------------------------------------------------------
W = 32
yy, xx = np.mgrid[0:W, 0:W]


def grime(lo):
    g = np.ones((W, W, 4)); g[:, :, :3] = np.array([[rnd.uniform(lo, 1.0) for _ in range(W)] for _ in range(W)])[:, :, None]
    return g


d = grime(0.8)  # skin under dust: pale powder blotches, the ribs as dark bands
for _ in range(10):
    cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.uniform(1.0, 2.5)
    d[((xx - cx) ** 2 + (yy - cy) ** 2) < r * r, :3] = 1.12
for y in range(2, W, 5):
    d[y, :, :3] *= 0.78
DUST = lp.new_image("dust_32", np.clip(d, 0, 1.2))
s = grime(0.84)  # the nightgown: old cotton, earth and blood
for _ in range(7):
    cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.uniform(0.8, 2.0)
    s[((xx - cx) ** 2 + (yy - cy) ** 2) < r * r, :3] = rnd.choice(((0.55, 0.42, 0.32), (0.45, 0.25, 0.22)))
STAINS = lp.new_image("stains_32", s)
GRIME = lp.new_image("grime_32", grime(0.75))

# the wing: dusty brown, wavy bands along the trailing edge, an eye spot (black ring, ochre ring, dark pupil, a
# white glint) like the moth's. u runs out along the wing, v up it.
WU, WV = 64, 32
wv, wu = np.mgrid[0:WV, 0:WU]
w = np.ones((WV, WU, 4)); w[:, :, :3] = np.array((0.36, 0.31, 0.26))
w[:, :, :3] *= np.array([[rnd.uniform(0.82, 1.0) for _ in range(WU)] for _ in range(WV)])[:, :, None]
band = np.sin(wu * 0.35 + wv * 0.55 + np.sin(wu * 0.2) * 2.0)
w[band > 0.75, :3] *= 0.62
w[wv < 4, :3] *= 0.55  # the dark fringe at the trailing edge
w[wv > WV - 3, :3] *= 0.7
r2 = ((wu - 30) / 1.0) ** 2 + ((wv - 17) / 0.85) ** 2
w[r2 < 81, :3] = (0.05, 0.04, 0.04)
w[r2 < 42, :3] = (0.66, 0.52, 0.30)
w[r2 < 20, :3] = (0.08, 0.06, 0.05)
w[(((wu - 28) ** 2 + (wv - 19) ** 2) < 3), :3] = (0.85, 0.82, 0.74)
WING = lp.new_image("bruxa_asa_64x32", w)

SKIN = (0.47, 0.43, 0.38)
M = dict(
    skin=lp.mat("b_pele", SKIN, tex=DUST),
    fur=lp.mat("b_pelo", (0.40, 0.35, 0.29), tex=GRIME),
    gown=lp.mat("b_camisola", (0.76, 0.72, 0.62), tex=STAINS),
    wing=lp.mat("b_asa", (1, 1, 1), face=WING),
    rib=lp.mat("b_osso", (0.30, 0.26, 0.22), tex=GRIME),
    eye=lp.mat("b_olho", (0.02, 0.02, 0.02)),
    shine=lp.mat("b_brilho", (0.95, 0.80, 0.42), emit=1.0),  # the eyeshine: vilarejo's Bruxa drives its energy
    mouth=lp.mat("b_boca", (0.12, 0.05, 0.05)),
    tongue=lp.mat("b_lingua", (0.42, 0.20, 0.20)),
    claw=lp.mat("b_garra", (0.12, 0.10, 0.08)),
)
M["wing"].use_backface_culling = False  # one sheet, seen from both sides (glTF doubleSided)

# --- joint table (+X = her left, -Y = front, Z up). Rest: upright and hunched, wings out and down. -------------
J = {"pelvis": (0, 0.03, 0.95), "spine": (0, 0.03, 1.18), "chest": (0, 0.0, 1.42),
     "neck": (0, -0.03, 1.53), "skull": (0, -0.07, 1.68)}
for s_, sx in ((".L", 1), (".R", -1)):
    J.update({"sh" + s_: (sx * 0.15, 0.0, 1.42), "el" + s_: (sx * 0.43, 0.02, 1.30), "wr" + s_: (sx * 0.70, 0.04, 1.13),
              "f1" + s_: (sx * 1.00, 0.05, 1.08), "tip" + s_: (sx * 0.97, 0.05, 0.85), "f3" + s_: (sx * 0.78, 0.05, 0.60),
              "hip" + s_: (sx * 0.09, 0.03, 0.93), "knee" + s_: (sx * 0.11, -0.04, 0.51),
              "ankle" + s_: (sx * 0.11, 0.06, 0.10), "toe" + s_: (sx * 0.11, -0.10, 0.0)})
BONES = {"hips": ("pelvis", "spine", None), "chest": ("spine", "chest", "hips"), "neck": ("chest", "neck", "chest"),
         "head": ("neck", "skull", "neck")}
for s_ in (".L", ".R"):
    BONES.update({"upper_arm" + s_: ("sh" + s_, "el" + s_, "chest"), "forearm" + s_: ("el" + s_, "wr" + s_, "upper_arm" + s_),
                  "hand" + s_: ("wr" + s_, "tip" + s_, "forearm" + s_),
                  "thigh" + s_: ("hip" + s_, "knee" + s_, "hips"), "shin" + s_: ("knee" + s_, "ankle" + s_, "thigh" + s_),
                  "foot" + s_: ("ankle" + s_, "toe" + s_, "shin" + s_)})

K = lp.Kit()
# torso: a rack of ribs under dust, the nightgown hanging off one shoulder
K.tube("waist", M["skin"], "hips", J["pelvis"], J["spine"], [(0, 0.10, 0.08), (0.6, 0.07, 0.06), (1, 0.08, 0.065)], n=8)
K.tube("chest", M["skin"], "chest", J["spine"], J["chest"], [(0, 0.08, 0.065), (0.5, 0.12, 0.085, 0.01), (0.9, 0.12, 0.08), (1, 0.06, 0.05)], n=8)
K.tube("gown", M["gown"], "chest", V(J, "spine", "chest", 0.2), V(J, "spine", "chest", 0.75),
       [(0, 0.095, 0.078), (1, 0.128, 0.09, 0.005)], n=8, caps=False)
K.seg("strap", M["gown"], "chest", (0.06, -0.075, 1.36), (0.10, -0.02, 1.43), 0.012, 0.012, n=4)
K.tube("gown", M["gown"], "hips", (0, 0.03, 0.74), (0, 0.03, 1.02), [(0, 0.17, 0.15), (0.6, 0.13, 0.11), (1, 0.10, 0.085)], n=10, caps=False)
for s_, sx in ((".L", 1), (".R", -1)):  # the skirt split per leg, its hem torn
    K.tube("gown", M["gown"], {"hips": 0.5, "thigh" + s_: 0.5}, (sx * 0.08, 0.02, 0.84), (sx * 0.10, 0.0, 0.62),
           [(0, 0.10, 0.11), (1, 0.12, 0.13)], n=8, caps=False)
    for i in range(3):
        a = math.radians(-50 + 55 * i) * sx
        K.box("hem", M["gown"], "thigh" + s_, (sx * 0.10 + 0.11 * math.sin(a), -0.12 * math.cos(a), 0.60 - 0.04 * (i % 2)),
              (0.04, 0.008, 0.06 + 0.03 * (i % 2)), rot=(0.1, 0, a))
# the collar of fur round the neck and shoulders, moth-thick
for i in range(9):
    a = math.radians(-120 + 30 * i)
    K.blob("fur", M["fur"], "chest", (0.12 * math.sin(a), 0.09 * math.cos(a) - 0.005, 1.43 + 0.02 * (i % 2)), 0.055, seed=20 + i, lump=0.3)
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.03, 0.027)

# head: small bald skull, two huge black eyes that catch the light, plumed antennae, a curled tongue
K.tube("head", M["skin"], "head", J["neck"], J["skull"],
       [(0, 0.04, 0.045), (0.3, 0.07, 0.08), (0.65, 0.08, 0.09), (0.92, 0.065, 0.075), (1, 0.03, 0.035)], n=10)
sk = V(J, "neck", "skull", 0.62)
for sx in (1, -1):
    eye = sk + Vector((sx * 0.052, -0.06, 0.0))
    K.blob("eye", M["eye"], "head", eye, (0.042, 0.04, 0.05), seed=30, lump=0.04)
    K.blob("shine", M["shine"], "head", eye + Vector((sx * 0.004, -0.03, 0.004)), (0.03, 0.016, 0.036), seed=31, lump=0.02)
    base = sk + Vector((sx * 0.03, -0.07, 0.07))
    mid = base + Vector((sx * 0.07, 0.0, 0.17))
    end = mid + Vector((sx * 0.08, 0.13, 0.06))
    K.spike("antenna", M["rib"], "head", base, mid + (mid - base).normalized() * 0.01, 0.009, n=4)
    K.spike("antenna", M["rib"], "head", mid, end, 0.008, n=4)
    for k in range(4):  # the plumes, off the shaft
        p = mid.lerp(end, 0.15 + 0.22 * k) if k else base.lerp(mid, 0.7)
        K.spike("plume", M["fur"], "head", p, p + Vector((sx * 0.05, 0.03, -0.035)), 0.007, n=3)
        K.spike("plume", M["fur"], "head", p, p + Vector((-sx * 0.01, 0.05, 0.03)), 0.007, n=3)
mouth = V(J, "neck", "skull", 0.25) + Vector((0, -0.07, 0))
K.box("mouth", M["mouth"], "head", mouth, (0.045, 0.012, 0.02))
t0 = mouth + Vector((0, -0.005, -0.01)); t1 = t0 + Vector((0, -0.02, -0.07)); t2 = t1 + Vector((0, 0.035, -0.035))
K.seg("tongue", M["tongue"], "head", t0, t1, 0.008, 0.006, n=4)
K.spike("tongue", M["tongue"], "head", t1, t2, 0.006, n=4)

# arms: bone and skin, the three wing fingers fanned out from the wrist, the membrane between them and the body
for s_, sx in ((".L", 1), (".R", -1)):
    K.seg("arm", M["skin"], "upper_arm" + s_, J["sh" + s_], J["el" + s_], 0.03, 0.022)
    K.seg("arm", M["skin"], "forearm" + s_, J["el" + s_], J["wr" + s_], 0.022, 0.017)
    K.blob("elbow", M["skin"], "forearm" + s_, V(J, "el" + s_), 0.026, seed=7)
    K.blob("wrist", M["skin"], "hand" + s_, V(J, "wr" + s_), 0.022, seed=8)
    for f in ("f1", "tip", "f3"):
        K.spike("finger", M["rib"], "hand" + s_, J["wr" + s_], J[f + s_], 0.011, n=4)
    K.spike("thumb", M["claw"], "hand" + s_, J["wr" + s_], V(J, "wr" + s_) + Vector((sx * 0.02, -0.07, 0.03)), 0.009, n=3)

# the membrane: columns from the body out to the wing tip, each with a top (on the arm) and a bottom (the trailing
# edge); a middle row between, the trailing edge scalloped between the fingers. {bone: weight} per point.
WING_COLS = [  # top point, its weights, bottom point, its weights (left side)
    ((0.16, 0.02, 1.36), {"chest": 0.7, "upper_arm": 0.3}, (0.13, 0.04, 0.72), {"hips": 0.4, "thigh": 0.6}),
    (J["el.L"], {"upper_arm": 0.5, "forearm": 0.5}, (0.40, 0.05, 0.55), {"forearm": 0.45, "hips": 0.3, "thigh": 0.25}),
    (J["wr.L"], {"forearm": 0.4, "hand": 0.6}, J["f3.L"], {"hand": 1.0}),
    (J["f1.L"], {"hand": 1.0}, J["tip.L"], {"hand": 1.0}),
]
SAG = [(0.27, 0.05, 0.70), (0.60, 0.05, 0.66), (0.86, 0.05, 0.80)]  # trailing edge between columns, pulled in


def mix(a, b, k=0.5):
    out = {}
    for src, f in ((a, 1 - k), (b, k)):
        for n, x in src.items():
            out[n] = out.get(n, 0.0) + x * f
    return out


WING_W = {}  # rounded world position -> {bone: weight}, applied after the join


def wing(s_, sx):
    import bmesh
    bm = bmesh.new(); uvs = {}
    def vert(p, wts):
        p = Vector((sx * p[0], p[1], p[2]))
        v = bm.verts.new(p)
        WING_W[tuple(round(c, 4) for c in p)] = {n + ("" if n in ("chest", "hips") else s_): x for n, x in wts.items()}
        uvs[v] = ((abs(p.x) - 0.13) / 0.87, (p.z - 0.55) / 0.55)
        return v
    cols = []
    for top, tw, bot, bw in WING_COLS:
        mid = Vector(top).lerp(Vector(bot), 0.5) + Vector((0, 0.015, 0))
        cols.append((vert(top, tw), vert(mid, mix(tw, bw)), vert(bot, bw)))
    sags = [vert(SAG[i], mix(WING_COLS[i][3], WING_COLS[i + 1][3])) for i in range(3)]
    for i in range(3):
        (t0, m0, b0), (t1, m1, b1) = cols[i], cols[i + 1]
        bm.faces.new((t0, t1, m1, m0)); bm.faces.new((m0, m1, b1, sags[i], b0))
    uv = bm.loops.layers.uv.new("FaceUV")
    for fc in bm.faces:
        for lo in fc.loops:
            lo[uv].uv = uvs[lo.vert]
    return K._obj("wing" + s_, bm, M["wing"], "hips")


for s_, sx in ((".L", 1), (".R", -1)):
    wing(s_, sx)

# legs: thin, bent; long-toed feet that grip the roof ridge
for s_, sx in ((".L", 1), (".R", -1)):
    K.seg("thigh", M["skin"], "thigh" + s_, J["hip" + s_], J["knee" + s_], 0.05, 0.032)
    K.seg("shin", M["skin"], "shin" + s_, J["knee" + s_], J["ankle" + s_], 0.032, 0.02)
    K.blob("knee", M["skin"], "shin" + s_, V(J, "knee" + s_), 0.034, seed=11)
    K.seg("foot", M["skin"], "foot" + s_, J["ankle" + s_], V(J, "ankle" + s_, "toe" + s_, 0.6), 0.025, 0.022, flat=0.6)
    for dx in (-0.028, 0.0, 0.028):
        a = V(J, "ankle" + s_, "toe" + s_, 0.55) + Vector((dx, 0, 0))
        K.spike("toe", M["claw"], "foot" + s_, a, V(J, "toe" + s_) + Vector((dx * 1.6, -0.06, -0.005)), 0.011, n=4)
    K.spike("spur", M["claw"], "foot" + s_, V(J, "ankle" + s_), V(J, "ankle" + s_) + Vector((0, 0.07, -0.08)), 0.01, n=3)

body = K.join("Bruxa")
# the membrane's own weights, point by point (the join gave its vertices all to "hips")
groups = {g.name: g for g in body.vertex_groups}
wing_mat = list(body.data.materials).index(M["wing"])
wing_verts = {i for p in body.data.polygons if p.material_index == wing_mat for i in p.vertices}
for i in wing_verts:
    co = body.data.vertices[i].co
    wts = WING_W[tuple(round(c, 4) for c in co)]
    for g in groups.values():
        g.remove([i])
    for n, x in wts.items():
        (groups.get(n) or body.vertex_groups.new(name=n)).add([i], x, "REPLACE")
        groups = {g.name: g for g in body.vertex_groups}
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
height = max(v.co.z for v in body.data.vertices)

# --- rig + animations: poses are world aims, parents first (front -Y, her left +X); turns after ------------------
arm = lp.armature("BruxaRig", {b: (J[h], J[t], p) for b, (h, t, p) in BONES.items()}, body)
P = lp.Poser(arm, body, {"feet": lambda n: n.startswith("foot"), "body": lambda n: True,
                         "limbs": lambda n: n.split(".")[0] in ("forearm", "foot")})


def both(bone, d):  # the same aim on both sides, mirrored
    return [(bone + ".L", d), (bone + ".R", (-d[0], d[1], d[2]))]


def sides(parts):
    out = []
    for bone, d in parts:
        out += both(bone, d)
    return out


CROUCH = sides([("thigh", (0.25, -1, 0.35)), ("shin", (0.05, 0.6, -1)), ("foot", (0, -1, -0.1))])
FOLD = sides([("upper_arm", (0.35, -0.5, -1)), ("forearm", (-0.55, -0.75, 0.15)), ("hand", (0.3, -0.3, 1))])
SPREAD = sides([("upper_arm", (1, 0.05, 0.5)), ("forearm", (1, 0.05, 0.1)), ("hand", (1, 0.08, -0.35))])


def spine(hips, chest, neck, head):
    return [("hips", hips), ("chest", chest), ("neck", neck), ("head", head)]


P.action("Idle", 61, loop=True)  # perched, folded in her wings like a cloak; the head turns slowly, twitches once
for fr, look, tw in ((1, 0, 0), (20, 22, 0), (38, 22, 0), (40, -8, 1), (46, -8, 1), (61, 0, 0)):
    P.pose(fr, [("head", "Z", look), ("head", "Y", 14 * tw)],
           aims=spine((0, -0.5, 1), (0, -0.9, 0.6 + 0.04 * (fr % 2)), (0, -0.8, 0.6), (0, -0.3, 1)) + CROUCH + FOLD)

P.action("Alert", 24)  # noticed the light: the head snaps up at it, the wings open
P.pose(1, aims=spine((0, -0.5, 1), (0, -0.9, 0.6), (0, -0.8, 0.6), (0, -0.3, 1)) + CROUCH + FOLD)
P.pose(7, [("head", "Y", -18)], aims=spine((0, -0.4, 1), (0, -0.7, 0.8), (0, -0.7, 0.8), (0, -0.6, 1)) + CROUCH + FOLD)
P.pose(16, aims=spine((0, -0.3, 1), (0, -0.4, 1), (0, -0.6, 0.8), (0, -0.7, 0.8)) + CROUCH + SPREAD)
P.pose(24, aims=spine((0, -0.3, 1), (0, -0.35, 1), (0, -0.6, 0.8), (0, -0.7, 0.8)) + CROUCH +
       sides([("upper_arm", (1, 0.1, 0.65)), ("forearm", (1, 0.1, 0.25)), ("hand", (1, 0.1, -0.2))]))

P.action("Fly", 21, loop=True)  # the glide: leaning into it, wings out, one slow beat; the legs trail
TRAIL = sides([("thigh", (0.08, 0.45, -1)), ("shin", (0, 1, -0.5)), ("foot", (0, 1, -0.7))])
for fr, k in ((1, 1.0), (11, -1.0), (21, 1.0)):
    P.pose(fr, aims=spine((0, -0.8, 0.6), (0, -1, 0.35), (0, -1, 0.5), (0, -1, 0.7)) + TRAIL +
           sides([("upper_arm", (1, 0.1 * k, 0.05 + 0.4 * k)), ("forearm", (1, 0.05 * k, -0.1 + 0.3 * k)),
                  ("hand", (1, 0.12, -0.45 + 0.25 * k))]), ground="body")

# the scuttle on wrists and feet, wings folded back along her: diagonal pairs (left wrist with right foot)
LOW = spine((0, -0.95, 0.3), (0, -1, 0.0), (0, -1, 0.45), (0, -0.5, 0.9))  # level as a dog, head up
ARM_FWD = [("upper_arm", (0.25, -0.55, -1)), ("forearm", (0.1, -0.25, -1)), ("hand", (0.2, 0.9, 0.45))]
ARM_BACK = [("upper_arm", (0.25, 0.15, -1)), ("forearm", (0.1, 0.45, -1)), ("hand", (0.2, 0.9, 0.3))]
ARM_UP = [("upper_arm", (0.25, -0.3, -0.8)), ("forearm", (0.1, -0.5, -0.6)), ("hand", (0.2, 0.9, 0.5))]
LEG_FWD = [("thigh", (0.2, -1, -0.25)), ("shin", (0, 0.3, -1)), ("foot", (0, -1, -0.05))]
LEG_BACK = [("thigh", (0.2, 0.3, -1)), ("shin", (0, 1, -0.2)), ("foot", (0, -0.4, -0.9))]
LEG_UP = [("thigh", (0.2, -0.9, 0.0)), ("shin", (0, 0.5, -0.8)), ("foot", (0, -1, 0.1))]


def limb(parts, s_):
    return [(b + s_, (d[0] if s_ == ".L" else -d[0], d[1], d[2])) for b, d in parts]


def gait(a, b):  # a: phase of the left wrist / right foot pair, b: the other pair
    return limb(a[0], ".L") + limb(a[1], ".R") + limb(b[0], ".R") + limb(b[1], ".L")


P.action("Walk", 17, loop=True)
for fr, a, b in ((1, (ARM_FWD, LEG_FWD), (ARM_BACK, LEG_BACK)), (5, (ARM_BACK, LEG_BACK), (ARM_UP, LEG_UP)),
                 (9, (ARM_BACK, LEG_BACK), (ARM_FWD, LEG_FWD)), (13, (ARM_UP, LEG_UP), (ARM_BACK, LEG_BACK)),
                 (17, (ARM_FWD, LEG_FWD), (ARM_BACK, LEG_BACK))):
    if fr == 5:
        a = (ARM_BACK[:1] + ARM_FWD[1:], LEG_BACK)  # passing: the planted pair under her
    if fr == 13:
        b = (ARM_BACK[:1] + ARM_FWD[1:], LEG_BACK)
    P.pose(fr, [("chest", "Z", 4 if fr in (1, 5) else -4)], aims=LOW + gait(a, b), ground="limbs")
    if fr == 1:
        stride = abs(P.P["foot.L"].tail.y - P.P["foot.R"].tail.y)

BASE = LOW + gait((ARM_BACK[:1] + ARM_FWD[1:], LEG_BACK), (ARM_BACK[:1] + ARM_FWD[1:], LEG_BACK))
P.action("Attack", 24)  # the dart's end: rears up wings wide, then both claws rake down at the light on frame 10
P.pose(1, aims=BASE, ground="limbs")
P.pose(6, aims=spine((0, -0.3, 1), (0, -0.2, 1), (0, -0.5, 0.8), (0, -0.8, 0.6)) +
       sides([("thigh", (0.2, -0.6, -0.8)), ("shin", (0, 0.4, -1)), ("foot", (0, -1, -0.1)),
              ("upper_arm", (0.8, -0.3, 0.7)), ("forearm", (0.4, -0.5, 1)), ("hand", (0.4, -0.7, 0.6))]))
STRIKE = spine((0, -0.9, 0.45), (0, -1, 0.2), (0, -1, 0.2), (0, -1, 0.3)) + \
    sides([("thigh", (0.2, 0.2, -1)), ("shin", (0, 0.9, -0.5)), ("foot", (0, -0.4, -0.9)),
           ("upper_arm", (0.3, -1, -0.15)), ("forearm", (0.1, -1, -0.45)), ("hand", (-0.1, -1, -0.6))])
P.pose(10, aims=STRIKE, ground="limbs")
P.pose(16, aims=STRIKE, ground="limbs")
P.pose(24, aims=BASE, ground="limbs")

P.action("Hit", 14)  # thrown back, wings jerk open
P.pose(1, aims=BASE, ground="limbs")
P.pose(4, [("head", "X", -25)], aims=spine((0, -0.1, 1), (0, 0.15, 1), (0, -0.2, 1), (0, 0.2, 1)) + CROUCH + SPREAD)
P.pose(14, aims=BASE, ground="limbs")

P.action("Death", 40)  # rears in pain, falls over on her back and curls her legs and wings up like a dead moth
P.pose(1, aims=BASE, ground="limbs")
P.pose(6, [("head", "X", -25)], aims=spine((0, -0.1, 1), (0, 0.15, 1), (0, -0.2, 1), (0, 0.2, 1)) + CROUCH + SPREAD, ground="feet")
CURL = sides([("thigh", (0.3, -1, 0.5)), ("shin", (0.1, 0.4, 0.2)), ("foot", (0, -0.4, 1)),
              ("upper_arm", (0.6, -0.6, -0.3)), ("forearm", (-0.2, -1, 0.3)), ("hand", (-0.2, -0.2, 1))])
P.pose(16, [("hips", "X", -50)], aims=spine((0, -0.2, 1), (0, -0.4, 1), (0, -0.5, 1), (0, -0.4, 1)) + CROUCH + SPREAD, ground="body")
P.pose(26, [("hips", "X", -92)], aims=spine((0, -0.1, 1), (0, -0.3, 1), (0, -0.4, 1), (0, 0.3, 1)) + CURL, ground="body")
P.pose(40, [("hips", "X", -92)], aims=spine((0, -0.1, 1), (0, -0.3, 1), (0, -0.4, 1), (0, 0.35, 1)) +
       sides([("thigh", (0.3, -1, 0.7)), ("shin", (0.1, 0.3, 0.5)), ("foot", (0, -0.2, 1)),
              ("upper_arm", (0.5, -0.7, -0.2)), ("forearm", (-0.3, -1, 0.5)), ("hand", (-0.2, 0, 1))]), ground="body")

arm.animation_data.action = bpy.data.actions["Idle_Loop"]
bpy.context.scene.render.fps = 30
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("personagens", "bruxa"))
bpy.ops.export_scene.gltf(filepath=paths.character("bruxa"), export_format="GLB",
                          export_animations=True, export_skins=True)
result = {"tris": tris, "verts": len(body.data.vertices), "height": round(height, 3), "bones": len(arm.data.bones),
          "actions": [a.name for a in bpy.data.actions], "stride": round(stride, 3),
          "walk_speed_m_s": round(2 * stride / (16 / 30), 2), "wing_verts": len(wing_verts)}
print("RESULT", result)

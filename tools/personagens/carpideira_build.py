# A Carpideira (docs/MUTANTES_NOITE.md): the third of the village's night mutants. The mourner hired to weep at the
# wakes, who never stopped. A thin woman in black to the ground, a black lace veil over head and shoulders, a thick
# church candle held in both hands at her chest, the wax run over her fingers and fused them to it. Under the veil the
# face is lit from below: eyes huge and lidless (she cannot close them: she is the one who sees), red-rimmed, tears of
# wax down the cheeks; a long jaw that drops to her chest when she screams. A rosary hangs from her hands.
# Same kit as the mutant (lowpoly.py). Headless: blender -b --factory-startup --python tools/personagens/carpideira_build.py
#   -> blender/personagens/carpideira.blend, godot_demo/models/characters/carpideira.glb
import bpy, bmesh, math, os, random, sys, importlib
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
import lowpoly as lp
importlib.reload(lp)
from lowpoly import V

lp.clear_scene()
rnd = random.Random(1979)

# --- textures -------------------------------------------------------------------------------------------
W = 32
yy, xx = np.mgrid[0:W, 0:W]


def grime(lo):
    g = np.ones((W, W, 4)); g[:, :, :3] = np.array([[rnd.uniform(lo, 1.0) for _ in range(W)] for _ in range(W)])[:, :, None]
    return g


d = grime(0.7)  # the mourning dress: old black crepe gone brown in the folds, dust and dried wax
for x in range(0, W, 4):
    d[:, x, :3] *= 0.8
for _ in range(10):
    d[rnd.randrange(W), rnd.randrange(W), :3] = 2.2
DRESS_T = lp.new_image("luto_32", d)
lace = np.ones((W, W, 4)) * 0.55; lace[:, :, 3] = 1  # the veil's lace: a net of light threads on black
lace[(xx % 4 == 0) | (yy % 4 == 0), :3] = 1.0
lace[((xx - 2) % 8 == 0) & ((yy - 2) % 8 == 0), :3] = 1.4  # little flowers in the net
LACE = lp.new_image("renda_32", lace)
SKIN_T = lp.new_image("pele_32", grime(0.85))
WAX_T = lp.new_image("cera_32", grime(0.88))

SKIN = np.array((0.80, 0.77, 0.72))
F = 64
f = np.ones((F, F, 4)); f[:, :, :3] = SKIN
fy, fx = np.mgrid[0:F, 0:F]


def ell(cx, cy, rx, ry, col, mix=1.0):
    m = ((fx - cx) / rx) ** 2 + ((fy - cy) / ry) ** 2 <= 1
    f[m, :3] = f[m, :3] * (1 - mix) + np.array(col) * mix


ell(32, 30, 22, 12, (0.62, 0.55, 0.52), 0.25)  # the brow and the sockets, dark with weeping
for cx in (20, 44):  # the eyes: too big, no lids, red-rimmed, a pin of a pupil that stares
    ell(cx, 38, 9, 7.5, (0.55, 0.14, 0.13))
    ell(cx, 38, 7.5, 6, (0.93, 0.90, 0.82))
    ell(cx, 38, 1.6, 1.6, (0.03, 0.02, 0.02))
    for y in range(8, 32):  # tears of wax from the lower lid down the cheek, dripping into beads
        x = cx + (1 if cx < 32 else -1) * (32 - y) // 12
        f[y, x, :3] = (0.97, 0.94, 0.82)
        if y % 7 == 0:
            f[y, x - 1:x + 2, :3] = (0.97, 0.94, 0.82)
ell(32, 24, 3, 5, (0.66, 0.60, 0.56), 0.6)  # the nose
f[9:12, 24:41, :3] = (0.22, 0.06, 0.07)  # the mouth's slit, at the bottom of the face (the jaw hangs under it)
FACE = lp.new_image("carpideira_face_64", f)

M = dict(
    dress=lp.mat("c_luto", (0.10, 0.09, 0.10), tex=DRESS_T),
    skirt=lp.mat("c_saia", (0.10, 0.09, 0.10), tex=DRESS_T),
    veil=lp.mat("c_veu", (0.07, 0.065, 0.075), tex=LACE),
    skin=lp.mat("c_pele", SKIN, tex=SKIN_T),
    face=lp.mat("c_rosto", SKIN, face=FACE),
    mouth=lp.mat("c_boca", (0.12, 0.02, 0.03)),
    tooth=lp.mat("c_dente", (0.70, 0.66, 0.52)),
    wax=lp.mat("c_cera", (0.92, 0.88, 0.74), tex=WAX_T),
    wick=lp.mat("c_pavio", (0.05, 0.04, 0.03)),
    flame=lp.mat("c_chama", (1.0, 0.72, 0.30), emit=6.0),  # the only other light in the village at night
    bead=lp.mat("c_conta", (0.20, 0.12, 0.08)),
    shoe=lp.mat("c_sapato", (0.04, 0.035, 0.035)),
    nail=lp.mat("c_unha", (0.35, 0.30, 0.26)),
)

# --- joint table (+X = her left, -Y = front, Z up). Rest: upright, head bowed a little, the candle at her chest. --
J = {"pelvis": (0, 0.01, 1.00), "spine": (0, 0.01, 1.25), "chest": (0, 0.0, 1.47),
     "neck": (0, -0.03, 1.60), "skull": (0, -0.07, 1.80), "jaw": (0, -0.06, 1.66), "chin": (0, -0.115, 1.55)}
for s_, sx in ((".L", 1), (".R", -1)):
    J.update({"sh" + s_: (sx * 0.15, 0.01, 1.45), "el" + s_: (sx * 0.17, -0.02, 1.17), "wr" + s_: (sx * 0.06, -0.20, 1.20),
              "tip" + s_: (sx * 0.025, -0.25, 1.24),
              "hip" + s_: (sx * 0.08, 0.01, 0.98), "knee" + s_: (sx * 0.09, -0.02, 0.53),
              "ankle" + s_: (sx * 0.09, 0.03, 0.08), "toe" + s_: (sx * 0.09, -0.09, 0.0)})
BONES = {"hips": ("pelvis", "spine", None), "chest": ("spine", "chest", "hips"), "neck": ("chest", "neck", "chest"),
         "head": ("neck", "skull", "neck"), "jaw": ("jaw", "chin", "head")}
for s_ in (".L", ".R"):
    BONES.update({"upper_arm" + s_: ("sh" + s_, "el" + s_, "chest"), "forearm" + s_: ("el" + s_, "wr" + s_, "upper_arm" + s_),
                  "hand" + s_: ("wr" + s_, "tip" + s_, "forearm" + s_),
                  "thigh" + s_: ("hip" + s_, "knee" + s_, "hips"), "shin" + s_: ("knee" + s_, "ankle" + s_, "thigh" + s_),
                  "foot" + s_: ("ankle" + s_, "toe" + s_, "shin" + s_)})


def cut(o, test):
    """Removes the faces of part o whose world centre passes test (an open front on a hood)."""
    bm = bmesh.new(); bm.from_mesh(o.data)
    mw = o.matrix_world
    bmesh.ops.delete(bm, geom=[fc for fc in bm.faces if test(mw @ fc.calc_center_median())], context="FACES")
    bm.to_mesh(o.data); bm.free()


K = lp.Kit()
# torso: thin, flat-chested, the black bodice buttoned to the throat, a high collar
K.tube("waist", M["dress"], "hips", J["pelvis"], J["spine"], [(0, 0.12, 0.095), (0.6, 0.085, 0.07), (1, 0.09, 0.07)], n=8)
K.tube("chest", M["dress"], "chest", J["spine"], J["chest"],
       [(0, 0.09, 0.07), (0.5, 0.115, 0.08), (0.85, 0.125, 0.08), (1, 0.07, 0.055)], n=8)
K.seg("collar", M["dress"], "neck", (0, -0.01, 1.47), (0, -0.02, 1.56), 0.05, 0.042, n=8)
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.03, 0.028)

# head: small and long, the face lit from below; the jaw is its own bone
head = K.tube("head", M["skin"], "head", J["neck"], J["skull"],
              [(0, 0.05, 0.055), (0.25, 0.07, 0.08), (0.6, 0.08, 0.09), (0.9, 0.065, 0.075), (1, 0.03, 0.035)], n=10)
head.data.materials.append(M["face"])
L = (V(J, "skull") - V(J, "neck")).length
uv = head.data.uv_layers.new(name="FaceUV")
for p in head.data.polygons:
    if p.normal.y < -0.3 and 0.2 * L < p.center.z < 0.92 * L:
        p.material_index = 1
    for li in p.loop_indices:
        co = head.data.vertices[head.data.loops[li].vertex_index].co
        uv.data[li].uv = (0.5 + co.x / 0.17, (co.z - 0.2 * L) / (0.72 * L))
K.box("mouth", M["mouth"], "head", V(J, "jaw") + Vector((0, -0.035, -0.02)), (0.06, 0.03, 0.035))  # what the jaw opens on
K.tube("jaw", M["skin"], "jaw", V(J, "jaw") + Vector((0, -0.02, 0.0)), V(J, "chin"),
       [(0, 0.055, 0.045), (0.5, 0.045, 0.035), (1, 0.025, 0.02)], n=8)
for i in range(4):  # a few long teeth in the lower jaw
    x = -0.024 + 0.016 * i
    a = V(J, "jaw", "chin", 0.15) + Vector((x, -0.06, 0.0))
    K.spike("tooth", M["tooth"], "jaw", a, a + Vector((0, 0.002, 0.028)), 0.005, n=3)

# the veil: a lace hood open on the face, falling over the shoulders and down her back to the waist
hood = K.tube("veil", M["veil"], "head", V(J, "neck", "skull", 0.1) + Vector((0, 0.02, 0)), V(J, "skull") + Vector((0, 0.01, 0.03)),
              [(0, 0.10, 0.11), (0.5, 0.098, 0.11), (0.85, 0.085, 0.095), (1, 0.004, 0.004)], n=12, caps=False)
face_c = V(J, "neck", "skull", 0.5)
cut(hood, lambda c: c.y < face_c.y - 0.05 and c.z < V(J, "skull").z - 0.015)
shawl = K.tube("shawl", M["veil"], {"chest": 0.7, "head": 0.3}, (0, 0.03, 1.10), (0, 0.0, 1.62),
               [(0, 0.17, 0.12, 0.03), (0.55, 0.21, 0.14, 0.01), (0.85, 0.19, 0.12), (1, 0.09, 0.08)], n=12, caps=False)
cut(shawl, lambda c: c.y < -0.05 and c.z < 1.42)  # open in front below the collar: the hands and the candle
K.tube("veil_back", M["veil"], {"chest": 0.6, "hips": 0.4}, (0, 0.08, 0.78), (0, 0.06, 1.12),
       [(0, 0.15, 0.03), (1, 0.16, 0.035)], n=6)

# arms: bone-thin, black sleeves to the wrist, the hands together round the candle
for s_, sx in ((".L", 1), (".R", -1)):
    K.blob("shoulder", M["dress"], "upper_arm" + s_, V(J, "sh" + s_), 0.045, seed=5)
    K.seg("sleeve", M["dress"], "upper_arm" + s_, J["sh" + s_], J["el" + s_], 0.04, 0.034)
    K.seg("sleeve", M["dress"], "forearm" + s_, J["el" + s_], V(J, "el" + s_, "wr" + s_, 0.92), 0.034, 0.03)
    K.seg("hand", M["skin"], "hand" + s_, J["wr" + s_], J["tip" + s_], 0.022, 0.026, flat=0.5)
    for i, dz in enumerate((-0.015, 0.0, 0.015, 0.03)):  # long fingers round the candle
        a = V(J, "tip" + s_) + Vector((0, 0, dz))
        b = Vector((-sx * 0.02, -0.29, 1.24 + dz))
        K.seg("finger", M["skin"], "hand" + s_, a, b, 0.008, 0.007, n=4)
        K.spike("nail", M["nail"], "hand" + s_, b, b + (b - a).normalized() * 0.015, 0.006, n=3)

# the candle: a thick church candle, the wax run down over her fingers and fused them to it; the flame on top
c_bot = Vector((0, -0.28, 1.13)); c_top = Vector((0, -0.28, 1.40))
K.seg("candle", M["wax"], "hand.R", c_bot, c_top, 0.032, 0.03, n=8)
K.seg("wick", M["wick"], "hand.R", c_top, c_top + Vector((0, 0, 0.015)), 0.004, 0.004, n=3)
K.spike("flame", M["flame"], "hand.R", c_top + Vector((0, 0, 0.01)), c_top + Vector((0, 0, 0.065)), 0.013, n=5)
for i in range(9):  # drips and lumps of wax over the rim, the fingers, the backs of the hands
    a = rnd.uniform(0, math.tau)
    z = rnd.uniform(1.18, 1.38)
    K.blob("wax", M["wax"], "hand.R", c_bot.lerp(c_top, (z - 1.13) / 0.27) + Vector((0.036 * math.cos(a), 0.03 * math.sin(a), 0)),
           (0.012, 0.012, rnd.uniform(0.02, 0.04)), seed=20 + i, lump=0.3)
for s_, sx in ((".L", 1), (".R", -1)):
    K.blob("wax", M["wax"], "hand" + s_, V(J, "wr" + s_, "tip" + s_, 0.7) + Vector((0, 0, 0.02)), (0.022, 0.02, 0.012), seed=30, lump=0.3)

# the rosary from her left hand: beads down to the knee and a little cross
r0 = V(J, "tip.L") + Vector((0.01, 0, -0.02))
for i in range(7):
    K.blob("bead", M["bead"], "hand.L", r0 + Vector((0.004 * i, 0.01 * i, -0.04 * i)), 0.009, seed=40 + i, lump=0.05)
cross = r0 + Vector((0.03, 0.07, -0.31))
K.box("cross", M["bead"], "hand.L", cross, (0.008, 0.008, 0.05))
K.box("cross", M["bead"], "hand.L", cross + Vector((0, 0, 0.01)), (0.03, 0.008, 0.008))

# the skirt: a bell of black to the floor, torn at the hem; its vertices are weighted to the legs below (after the join)
K.tube("skirt", M["skirt"], "hips", (0, 0.02, 0.03), (0, 0.01, 1.02),
       [(0, 0.27, 0.25), (0.3, 0.22, 0.20), (0.7, 0.16, 0.14), (0.9, 0.13, 0.105), (1, 0.12, 0.095)], n=14, caps=False)
for i in range(9):  # torn rags hanging from the hem
    a = math.tau * i / 9 + 0.2
    K.box("rag", M["skirt"], "hips", (0.27 * math.sin(a), 0.02 - 0.25 * math.cos(a), 0.03),
          (0.06, 0.008, 0.07 + 0.03 * (i % 3)), rot=(0.1, 0, -a))
for s_ in (".L", ".R"):  # what shows of the feet: black shoes under the hem
    K.seg("foot", M["shoe"], "foot" + s_, V(J, "ankle" + s_) + Vector((0, 0.02, -0.03)), J["toe" + s_], 0.035, 0.025, flat=0.7)
    K.seg("shin", M["shoe"], "shin" + s_, V(J, "knee" + s_, "ankle" + s_, 0.6), J["ankle" + s_], 0.03, 0.028)

body = K.join("Carpideira")
# the skirt's own weights: from the hips at the waist to the legs at the hem, each side to its own leg
groups = {g.name: g for g in body.vertex_groups}
for n in ("thigh.L", "thigh.R", "shin.L", "shin.R"):
    if n not in groups:
        groups[n] = body.vertex_groups.new(name=n)
skirt_mats = {list(body.data.materials).index(M["skirt"])}
skirt_verts = {i for p in body.data.polygons if p.material_index in skirt_mats for i in p.vertices}
for i in skirt_verts:
    co = body.data.vertices[i].co
    down = min(1.0, max(0.0, (1.0 - co.z) / 0.95))  # 0 at the waist, 1 at the hem
    left = min(1.0, max(0.0, 0.5 + co.x / 0.22))
    low = min(1.0, max(0.0, (0.55 - co.z) / 0.5)) * 0.6  # below the knee, part of it to the shin
    leg = 0.5 * down  # not more: the stride would throw the hem out like a bell
    for g in groups.values():
        g.remove([i])
    groups["hips"].add([i], 1.0 - leg, "REPLACE")
    for s_, side in ((".L", left), (".R", 1.0 - left)):
        if side * leg > 0.001:
            groups["thigh" + s_].add([i], side * leg * (1 - low), "REPLACE")
            groups["shin" + s_].add([i], side * leg * low, "REPLACE")
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
height = max(v.co.z for v in body.data.vertices)

# --- rig + animations: world aims, parents first (front -Y, her left +X); turns after ---------------------------
arm = lp.armature("CarpideiraRig", {b: (J[h], J[t], p) for b, (h, t, p) in BONES.items()}, body)
P = lp.Poser(arm, body, {"feet": lambda n: n.startswith("foot"), "body": lambda n: True})
BOW = [("neck", "X", 10), ("head", "X", 14)]  # the head bowed over the candle


def sob(k):  # a sob: the shoulders hitch up, the chest folds over the candle, the head drops
    return [("chest", "X", 5 * k), ("neck", "X", 10 + 4 * k), ("head", "X", 14 + 6 * k), ("head", "Y", -6 * k)]


P.action("Idle", 61, loop=True)  # stands weeping: sobs hitch her shoulders, the head rocks over the candle
for fr, k in ((1, 0), (6, 1), (10, 0.3), (14, 1), (18, 0.2), (24, 0.8), (34, 0), (44, 0.3), (52, 0.1), (61, 0)):
    P.pose(fr, sob(k) + [("head", "Z", 8 * math.sin(fr / 61 * math.tau))])


def legs(front, kind):
    back = ".R" if front == ".L" else ".L"
    if kind == "contact":
        return [("thigh" + front, "X", -16), ("shin" + front, "X", 4), ("thigh" + back, "X", 12), ("shin" + back, "X", 10)]
    return [("thigh" + front, "X", 2), ("thigh" + back, "X", -6), ("shin" + back, "X", 26)]


P.action("Walk", 41, loop=True)  # a procession's step, slow and small: the dress glides, the candle stays still
for fr, front, kind, sg in ((1, ".L", "contact", 1), (11, ".L", "pass", 1), (21, ".R", "contact", -1),
                            (31, ".R", "pass", -1), (41, ".L", "contact", 1)):
    P.pose(fr, legs(front, kind) + BOW + [("hips", "Z", 3 * sg), ("chest", "Z", -3 * sg), ("head", "Y", -4 * sg)])
    if fr == 1:
        stride = abs(P.P["foot.L"].tail.y - P.P["foot.R"].tail.y)

P.action("Notice", 20)  # she has seen you: the head snaps up and round, the body leans in, the candle held out
P.pose(1, BOW)
LEAN = [("chest", "X", 10), ("neck", "X", -10), ("head", "X", -8), ("head", "Y", 12)]
OUT = [("upper_arm.L", "X", -25), ("upper_arm.R", "X", -25), ("forearm.L", "X", -10), ("forearm.R", "X", -10)]
P.pose(5, LEAN + OUT)
P.pose(20, LEAN + OUT + [("head", "Y", 6)])

P.action("Scream", 60)  # the head thrown back, the jaw drops to her chest, the candle raised high over her head
P.pose(1, LEAN + OUT)
UP = [("upper_arm.L", "X", -110), ("upper_arm.R", "X", -110), ("forearm.L", "X", -20), ("forearm.R", "X", -20),
      ("hand.L", "X", 142), ("hand.R", "X", 142)]  # world turns that cancel out at the hands: the candle stays upright
OPEN = [("chest", "X", -12), ("neck", "X", -18), ("head", "X", -22), ("jaw", "X", 60)]
P.pose(8, OPEN + UP)
P.pose(14, OPEN + UP + [("head", "Y", 6)])
P.pose(40, OPEN + UP + [("head", "Y", -6), ("jaw", "X", 66)])
P.pose(50, LEAN + OUT + [("jaw", "X", 30)])
P.pose(60, LEAN + OUT)

P.action("Hit", 16)
P.pose(1, BOW)
P.pose(4, [("chest", "X", -14), ("head", "X", -26), ("head", "Y", 22), ("jaw", "X", 30)] + OUT)
P.pose(16, BOW)

P.action("Death", 50)  # the knees go, she folds over the candle and topples on her side
P.pose(1, BOW)
P.pose(6, [("chest", "X", -14), ("head", "X", -26), ("jaw", "X", 40)])
KNEEL = [("thigh.L", "X", -70), ("thigh.R", "X", -65), ("shin.L", "X", 95), ("shin.R", "X", 100)]
P.pose(18, KNEEL + [("chest", "X", 30), ("head", "X", 30), ("jaw", "X", 20)], ground="body")
P.pose(32, [("hips", "Y", -60)] + KNEEL + [("chest", "X", 25), ("head", "Y", -30), ("jaw", "X", 30)], ground="body")
DOWN = [("hips", "Y", -88)] + KNEEL + [("chest", "X", 20), ("head", "Y", -40), ("jaw", "X", 35),
                                       ("upper_arm.R", "Y", -40)]
P.pose(40, DOWN, ground="body")
P.pose(50, DOWN + [("upper_arm.L", "X", -20)], ground="body")

arm.animation_data.action = bpy.data.actions["Idle_Loop"]
bpy.context.scene.render.fps = 30
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("personagens", "carpideira"))
bpy.ops.export_scene.gltf(filepath=paths.character("carpideira"), export_format="GLB",
                          export_animations=True, export_skins=True)
result = {"tris": tris, "verts": len(body.data.vertices), "height": round(height, 3), "bones": len(arm.data.bones),
          "actions": [a.name for a in bpy.data.actions], "stride": round(stride, 3),
          "walk_speed_m_s": round(2 * stride / (40 / 30), 2), "skirt_verts": len(skirt_verts)}
print("RESULT", result)

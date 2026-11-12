# O Porteiro (docs/CHAVE_DO_PORTAO.md): the village's last fight. Severino, the Colônia's gatekeeper, who took the
# doctor's serum to last the night. Grown huge, 2.4 m, stooped; the denim uniform split down the back, the porter's cap
# still on; the face wrapped in bandages like an inmate's. In his right hand a ring of iron keys the size of a flail,
# chained to his belt (he swings it); on his chest, a lit lantern hung by a strap (his light, and his weak point:
# o_lampiao, lit in the game).
# Same kit as the other creatures (lowpoly.py). Headless:
#   blender -b --factory-startup --python tools/personagens/porteiro_build.py
#   -> blender/personagens/porteiro.blend, godot_demo/models/characters/porteiro.glb
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

W = 32
yy, xx = np.mgrid[0:W, 0:W]


def grime(lo):
    g = np.ones((W, W, 4)); g[:, :, :3] = np.array([[rnd.uniform(lo, 1.0) for _ in range(W)] for _ in range(W)])[:, :, None]
    return g


d = grime(0.8)  # denim: a weave of faint lines, dark stains
for y in range(0, W, 2):
    d[y, :, :3] *= 0.93
for _ in range(7):
    cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.uniform(1.0, 3.0)
    d[((xx - cx) ** 2 + (yy - cy) ** 2) < r * r, :3] *= 0.55
DENIM = lp.new_image("brim_32", d)
b = grime(0.82)  # bandage: wound strips, old blood seeping
for y in range(0, W, 4):
    b[y, :, :3] *= 0.8
for _ in range(5):
    cx, cy, r = rnd.randrange(W), rnd.randrange(W), rnd.uniform(1.0, 2.2)
    m_ = ((xx - cx) ** 2 + (yy - cy) ** 2) < r * r
    b[m_, :3] = b[m_, :3] * 0.4 + np.array((0.45, 0.12, 0.08)) * 0.6
BANDAGE = lp.new_image("faixa_32", b)
SKIN_T = lp.new_image("pele_porteiro_32", grime(0.8))
GRIME = lp.new_image("grime_porteiro_32", grime(0.7))

F = 64
BAND = np.array((0.78, 0.74, 0.64))
f = np.ones((F, F, 4)); f[:, :, :3] = BAND
fy, fx = np.mgrid[0:F, 0:F]
for y in range(0, F, 6):  # the strips wound round the head
    f[y:y + 1, :, :3] *= 0.75
for cx in (22, 42):  # one eye shows through a gap, the other is bandaged over, blood under it
    pass
m_ = ((fx - 42) / 6) ** 2 + ((fy - 36) / 3) ** 2 <= 1
f[m_, :3] = (0.12, 0.06, 0.05)
f[37, 40:45, :3] = (0.75, 0.62, 0.3)  # the eye's glint
m_ = ((fx - 22) / 6) ** 2 + ((fy - 34) / 4) ** 2 <= 1
f[m_, :3] = f[m_, :3] * 0.4 + np.array((0.5, 0.1, 0.08)) * 0.6
f[20:24, 26:39, :3] = (0.1, 0.05, 0.05)  # the mouth, a slit in the bandage
FACE = lp.new_image("porteiro_face_64", f)

M = dict(
    skin=lp.mat("o_pele", (0.6, 0.55, 0.5), tex=SKIN_T),
    face=lp.mat("o_rosto", BAND, face=FACE),
    band=lp.mat("o_faixa", BAND, tex=BANDAGE),
    denim=lp.mat("o_brim", (0.28, 0.33, 0.42), tex=DENIM),
    cap=lp.mat("o_quepe", (0.16, 0.18, 0.24), tex=GRIME),
    boot=lp.mat("o_bota", (0.07, 0.06, 0.05), tex=GRIME),
    iron=lp.mat("o_ferro", (0.25, 0.23, 0.22), tex=GRIME),
    brass=lp.mat("o_latao", (0.55, 0.42, 0.18), tex=GRIME),
    lamp=lp.mat("o_lampiao", (1.0, 0.75, 0.35)),
    belt=lp.mat("o_cinto", (0.18, 0.12, 0.08), tex=GRIME),
    nail=lp.mat("o_unha", (0.25, 0.22, 0.18)),
)

# --- joint table (+X = his left, -Y = front, Z up). Rest: stooped, the head pushed forward, arms hanging. --------
J = {"pelvis": (0, 0.04, 1.18), "spine": (0, 0.02, 1.52), "chest": (0, -0.06, 1.86),
     "neck": (0, -0.15, 2.03), "skull": (0, -0.21, 2.25)}
for s_, sx in ((".L", 1), (".R", -1)):
    J.update({"sh" + s_: (sx * 0.33, -0.05, 1.88), "el" + s_: (sx * 0.44, -0.02, 1.42), "wr" + s_: (sx * 0.47, -0.07, 0.98),
              "tip" + s_: (sx * 0.49, -0.11, 0.70),
              "hip" + s_: (sx * 0.17, 0.04, 1.16), "knee" + s_: (sx * 0.2, -0.04, 0.63),
              "ankle" + s_: (sx * 0.2, 0.05, 0.12), "toe" + s_: (sx * 0.2, -0.17, 0.0)})
BONES = {"hips": ("pelvis", "spine", None), "chest": ("spine", "chest", "hips"), "neck": ("chest", "neck", "chest"),
         "head": ("neck", "skull", "neck")}
for s_ in (".L", ".R"):
    BONES.update({"upper_arm" + s_: ("sh" + s_, "el" + s_, "chest"), "forearm" + s_: ("el" + s_, "wr" + s_, "upper_arm" + s_),
                  "hand" + s_: ("wr" + s_, "tip" + s_, "forearm" + s_),
                  "thigh" + s_: ("hip" + s_, "knee" + s_, "hips"), "shin" + s_: ("knee" + s_, "ankle" + s_, "thigh" + s_),
                  "foot" + s_: ("ankle" + s_, "toe" + s_, "shin" + s_)})

K = lp.Kit()
# torso: the uniform jacket, split down the back over a hunch of skin; a belt with the chain's end
K.tube("seat", M["denim"], "hips", (0, 0.05, 0.98), J["pelvis"], [(0, 0.2, 0.16), (1, 0.24, 0.2)], n=12)
K.tube("belly", M["denim"], "hips", J["pelvis"], J["spine"], [(0, 0.24, 0.2), (0.5, 0.27, 0.23, -0.02), (1, 0.26, 0.21)], n=12)
K.tube("chest", M["denim"], "chest", J["spine"], J["chest"],
       [(0, 0.26, 0.21), (0.4, 0.3, 0.23), (0.75, 0.35, 0.22, 0.02), (0.93, 0.29, 0.18, 0.02), (1, 0.16, 0.12)], n=12)
K.blob("hump", M["skin"], "chest", V(J, "spine", "chest", 0.8) + Vector((0, 0.17, 0.04)), (0.2, 0.14, 0.18), seed=7, lump=0.15)
for sx in (1, -1):
    K.blob("trap", M["denim"], "chest", (sx * 0.16, -0.03, 1.95), (0.13, 0.11, 0.08), seed=11, lump=0.08)
waist = V(J, "pelvis", "spine", 0.35)
K.tube("belt", M["belt"], "hips", waist - Vector((0, 0, 0.04)), waist + Vector((0, 0, 0.04)), [(0, 0.275, 0.235), (1, 0.275, 0.235)], n=12, caps=False)
K.box("buckle", M["brass"], "hips", waist + Vector((0, -0.24, 0)), (0.08, 0.02, 0.07))
for i in range(4):  # brass buttons down the jacket
    K.box("button", M["brass"], "chest", V(J, "spine", "chest", 0.1 + 0.25 * i) + Vector((0, -0.23 + 0.02 * i, 0)), (0.03, 0.015, 0.03))
K.seg("neck", M["band"], "neck", J["chest"], J["neck"], 0.12, 0.1)

# the head: bandaged all over, the porter's cap still on
head = K.tube("head", M["band"], "head", J["neck"], J["skull"],
              [(0, 0.09, 0.095), (0.3, 0.105, 0.115), (0.65, 0.11, 0.12), (0.92, 0.09, 0.095), (1, 0.04, 0.045)], n=10)
head.data.materials.append(M["face"])
L = (V(J, "skull") - V(J, "neck")).length
uv = head.data.uv_layers.new(name="FaceUV")
for p in head.data.polygons:
    if p.normal.y < -0.3 and 0.15 * L < p.center.z < 0.9 * L:
        p.material_index = 1
    for li in p.loop_indices:
        co = head.data.vertices[head.data.loops[li].vertex_index].co
        uv.data[li].uv = (0.5 + co.x / 0.24, co.z / L)
top = V(J, "neck", "skull", 0.92)
K.tube("cap", M["cap"], "head", top - Vector((0, 0, 0.02)), top + Vector((0, 0, 0.09)), [(0, 0.125, 0.13), (1, 0.12, 0.125)], n=10)
K.box("visor", M["cap"], "head", top + Vector((0, -0.14, -0.01)), (0.18, 0.08, 0.015), rot=(-0.25, 0, 0))
K.box("badge", M["brass"], "head", top + Vector((0, -0.125, 0.05)), (0.04, 0.01, 0.03))
for i in range(3):  # loose ends of bandage hanging at the back
    a = V(J, "neck", "skull", 0.5) + Vector(((i - 1) * 0.04, 0.1, 0))
    K.box("tail", M["band"], "head", a + Vector((0, 0.02, -0.12)), (0.03, 0.01, 0.22), rot=(0.3, 0, (i - 1) * 0.2))

# the lantern on his chest, on a strap over the shoulder
lamp = V(J, "spine", "chest", 0.55) + Vector((0, -0.27, 0))
K.box("lamp_cage", M["iron"], "chest", lamp, (0.15, 0.13, 0.2))
K.box("lamp_glass", M["lamp"], "chest", lamp + Vector((0, -0.005, 0)), (0.12, 0.13, 0.15))
K.box("lamp_top", M["iron"], "chest", lamp + Vector((0, 0, 0.12)), (0.11, 0.1, 0.04))
K.seg("strap", M["belt"], "chest", lamp + Vector((0, 0.02, 0.12)), (0.2, -0.05, 1.98), 0.02, 0.02, n=4)
K.seg("strap", M["belt"], "chest", lamp + Vector((0, 0.02, 0.12)), (-0.2, -0.05, 1.98), 0.02, 0.02, n=4)

# arms: the sleeves split, bare forearms bandaged, huge hands; the key ring in the right
for s_, sx in ((".L", 1), (".R", -1)):
    K.blob("shoulder", M["denim"], "upper_arm" + s_, V(J, "sh" + s_), 0.12, seed=5)
    K.tube("arm", M["denim"], "upper_arm" + s_, J["sh" + s_], J["el" + s_], [(0, 0.11, 0.11), (0.35, 0.12, 0.11), (1, 0.085, 0.08)], n=8)
    K.tube("arm", M["band"], "forearm" + s_, J["el" + s_], J["wr" + s_], [(0, 0.085, 0.08), (0.3, 0.095, 0.085), (1, 0.065, 0.055)], n=8)
    K.tube("hand", M["skin"], "hand" + s_, J["wr" + s_], V(J, "wr" + s_, "tip" + s_, 0.55), [(0, 0.06, 0.045), (1, 0.08, 0.04)], n=6, up=(0, 1, 0))
    for i, dy in enumerate((-0.05, -0.017, 0.017, 0.05)):
        a = V(J, "wr" + s_, "tip" + s_, 0.5) + Vector((0, dy, 0))
        tip = V(J, "tip" + s_) + Vector((sx * 0.01, dy * 1.2, 0.02 * abs(i - 1.5)))
        K.seg("finger", M["skin"], "hand" + s_, a, tip, 0.022, 0.016, n=4)
    K.seg("thumb", M["skin"], "hand" + s_, V(J, "wr" + s_, "tip" + s_, 0.25), V(J, "wr" + s_, "tip" + s_, 0.5) + Vector((0, -0.08, 0)), 0.024, 0.018, n=4)
ring = V(J, "tip.R") + Vector((0, 0, -0.22))
K.tube("ring", M["iron"], "hand.R", ring + Vector((0, 0, -0.02)), ring + Vector((0, 0, 0.02)), [(0, 0.17, 0.17), (1, 0.17, 0.17)], n=12, caps=False)
for k in range(9):  # big old keys hanging round the ring
    a = 2 * math.pi * k / 9
    p0 = ring + Vector((math.cos(a) * 0.17, math.sin(a) * 0.17, 0))
    p1 = p0 + Vector((math.cos(a) * 0.05, math.sin(a) * 0.05, -0.26))
    K.seg("key", M["iron"], "hand.R", p0, p1, 0.012, 0.012, n=3)
    K.box("bit", M["iron"], "hand.R", p1 + Vector((0, 0, 0.03)), (0.05, 0.015, 0.06))
K.seg("chain", M["iron"], "hand.R", V(J, "tip.R"), ring + Vector((0, 0, 0.17)), 0.015, 0.015, n=3)

# legs: uniform trousers, boots
for s_ in (".L", ".R"):
    K.seg("thigh", M["denim"], {"thigh" + s_: 1.0}, J["hip" + s_], J["knee" + s_], 0.14, 0.11, n=8)
    K.seg("shin", M["denim"], "shin" + s_, J["knee" + s_], V(J, "knee" + s_, "ankle" + s_, 0.4), 0.11, 0.095, n=8)
    K.seg("boot", M["boot"], "shin" + s_, V(J, "knee" + s_, "ankle" + s_, 0.35), J["ankle" + s_], 0.11, 0.09, n=8)
    K.seg("foot", M["boot"], "foot" + s_, V(J, "ankle" + s_) + Vector((0, 0.06, 0)), J["toe" + s_], 0.09, 0.07, n=6, flat=0.7)
    K.box("sole", M["boot"], "foot" + s_, V(J, "ankle" + s_, "toe" + s_, 0.5) + Vector((0, 0.02, -0.075)), (0.16, 0.32, 0.035))

body = K.join("Porteiro")
tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
height = max(v.co.z for v in body.data.vertices)

# --- rig + animations -------------------------------------------------------------------------------------------
arm = lp.armature("PorteiroRig", {b: (J[h], J[t], p) for b, (h, t, p) in BONES.items()}, body)
P = lp.Poser(arm, body, {"feet": lambda n: n.startswith("foot"), "body": lambda n: True})


def rest_dir(a, b):
    return tuple(Vector(J[b]) - Vector(J[a]))


def sides(parts):
    out = []
    for bone, d_ in parts:
        out += [(bone + ".L", d_), (bone + ".R", (-d_[0], d_[1], d_[2]))]
    return out


SPINE = [("hips", rest_dir("pelvis", "spine")), ("chest", rest_dir("spine", "chest")), ("neck", rest_dir("chest", "neck"))]
HANG = sides([("upper_arm", (0.15, 0.06, -1)), ("forearm", (0.05, -0.12, -1)), ("hand", (0.04, -0.12, -1))])
LEFT = [a for a in HANG if a[0].endswith(".L")]
RIGHT = [a for a in HANG if a[0].endswith(".R")]

P.action("Idle", 61, loop=True)  # heavy breathing, the keys swaying; the head turns slowly
for fr, br, look in ((1, 0, 0), (16, 1, 8), (31, 0, 0), (46, 1, -8), (61, 0, 0)):
    P.pose(fr, [("chest", "X", -4 * br), ("head", "Z", look), ("upper_arm.R", "Y", 6 * br)], aims=SPINE + HANG)


def legs(front, kind):
    back = ".R" if front == ".L" else ".L"
    if kind == "contact":
        return [("thigh" + front, "X", -26), ("shin" + front, "X", 8), ("thigh" + back, "X", 20), ("shin" + back, "X", 16)]
    return [("thigh" + front, "X", 4), ("thigh" + back, "X", -14), ("shin" + back, "X", 50)]


P.action("Walk", 33, loop=True)  # a heavy tread, the keys swinging out at each step
for fr, front, kind, sg in ((1, ".L", "contact", 1), (9, ".L", "pass", 1), (17, ".R", "contact", -1),
                            (25, ".R", "pass", -1), (33, ".L", "contact", 1)):
    P.pose(fr, legs(front, kind) + [("hips", "Z", 5 * sg), ("chest", "Z", -7 * sg), ("upper_arm.L", "X", 16 * sg),
                                    ("upper_arm.R", "X", -16 * sg)], aims=SPINE + HANG)
    if fr == 1:
        stride = abs(P.P["foot.L"].tail.y - P.P["foot.R"].tail.y)

P.action("Attack", 36)  # the side swing: the keys drawn back to his right, swept across in front on frame 18
P.pose(1, [], aims=SPINE + HANG)
BACK = [("upper_arm.R", (-0.9, 0.5, -0.1)), ("forearm.R", (-0.8, 0.6, 0.0)), ("hand.R", (-0.7, 0.7, 0.0))]
P.pose(11, [("chest", "Z", -30), ("hips", "Z", -10)], aims=SPINE + LEFT + BACK)
ACROSS = [("upper_arm.R", (0.4, -1, -0.1)), ("forearm.R", (0.9, -0.5, -0.1)), ("hand.R", (1, -0.2, -0.1))]
P.pose(18, [("chest", "Z", 30), ("hips", "Z", 10), ("thigh.R", "X", -20)], aims=SPINE + LEFT + ACROSS)
P.pose(24, [("chest", "Z", 34), ("hips", "Z", 12)], aims=SPINE + LEFT + ACROSS)
P.pose(36, [], aims=SPINE + HANG)

P.action("Smash", 60)  # both hands high (the keys jangle: the warning), down on frame 28; stuck on the floor till 56
UP = sides([("upper_arm", (0.15, 0.25, 1)), ("forearm", (-0.35, 0.3, 1)), ("hand", (-0.3, 0.4, 0.8))])
P.pose(1, [], aims=SPINE + HANG)
P.pose(18, [("chest", "X", -18), ("head", "X", -12)], aims=SPINE + UP)
P.pose(24, [("chest", "X", -22), ("head", "X", -14)], aims=SPINE + UP)
DOWN = sides([("upper_arm", (0.08, -1, -0.5)), ("forearm", (-0.1, -0.5, -1)), ("hand", (-0.1, -0.2, -1))])
SLAM = [("chest", "X", 48), ("head", "X", 12), ("thigh.L", "X", -40), ("shin.L", "X", 40), ("thigh.R", "X", 20), ("shin.R", "X", 30)]
P.pose(28, SLAM, aims=SPINE + DOWN)
P.pose(52, SLAM + [("head", "Z", 10)], aims=SPINE + DOWN)
P.pose(60, [], aims=SPINE + HANG)

P.action("Throw", 36)  # stoops, tears a stone up, throws it overhand on frame 22
P.pose(1, [], aims=SPINE + HANG)
REACH = [("chest", "X", 50), ("thigh.L", "X", -40), ("shin.L", "X", 50), ("thigh.R", "X", -30), ("shin.R", "X", 45)]
P.pose(9, REACH, aims=SPINE + LEFT + [("upper_arm.R", (-0.2, -0.5, -1)), ("forearm.R", (0, -0.4, -1)), ("hand.R", (0, -0.2, -1))])
COCK = [("upper_arm.R", (-0.5, 0.6, 0.6)), ("forearm.R", (-0.3, 0.7, 0.6)), ("hand.R", (-0.2, 0.6, 0.8))]
P.pose(17, [("chest", "X", -20), ("chest", "Z", -20)], aims=SPINE + LEFT + COCK)
OUT = [("upper_arm.R", (-0.2, -1, 0.4)), ("forearm.R", (0, -1, 0.2)), ("hand.R", (0, -1, 0.0))]
P.pose(22, [("chest", "X", 25), ("chest", "Z", 20)], aims=SPINE + LEFT + OUT)
P.pose(36, [], aims=SPINE + HANG)

P.action("Roar", 45)  # woken, or wounded into a new rage: the head back, arms out, the chest heaving
P.pose(1, [], aims=SPINE + HANG)
OPEN = sides([("upper_arm", (1, -0.3, -0.2)), ("forearm", (1, -0.4, 0.1)), ("hand", (1, -0.3, 0.2))])
P.pose(12, [("chest", "X", -20), ("head", "X", -30)], aims=SPINE + OPEN)
P.pose(34, [("chest", "X", -24), ("head", "X", -34)], aims=SPINE + OPEN)
P.pose(45, [], aims=SPINE + HANG)

P.action("Jump", 24)  # crouch, spring (up onto the altar, or down off it), the landing in the knees
CROUCH = [("thigh.L", "X", -50), ("shin.L", "X", 70), ("thigh.R", "X", -50), ("shin.R", "X", 70), ("chest", "X", 25)]
P.pose(1, [], aims=SPINE + HANG)
P.pose(6, CROUCH, aims=SPINE + HANG, ground="feet")
P.pose(12, [("thigh.L", "X", -60), ("shin.L", "X", 60), ("thigh.R", "X", -20), ("shin.R", "X", 30)], aims=SPINE + UP)
P.pose(20, CROUCH, aims=SPINE + HANG, ground="feet")
P.pose(24, [], aims=SPINE + HANG)

P.action("Hit", 16)
P.pose(1, [], aims=SPINE + HANG)
P.pose(5, [("chest", "X", -14), ("head", "X", -24), ("head", "Y", -20)], aims=SPINE + sides([("upper_arm", (0.5, 0.2, -1))]))
P.pose(16, [], aims=SPINE + HANG)

P.action("Death", 50)  # to his knees, the keys falling from his hand, then down on his face
P.pose(1, [], aims=SPINE + HANG)
P.pose(8, [("chest", "X", -16), ("head", "X", -26)], aims=SPINE + HANG)
KNEEL = [("thigh.L", "X", -80), ("thigh.R", "X", -75), ("shin.L", "X", 85), ("shin.R", "X", 90)]
P.pose(22, KNEEL + [("chest", "X", 20), ("head", "X", 20)], aims=SPINE + HANG, ground="body")
FLAT = [("hips", "X", 84), ("thigh.L", "X", -8), ("thigh.R", "X", -2), ("shin.L", "X", 14), ("shin.R", "X", 24), ("head", "Z", 70)]
P.pose(36, FLAT, aims=SPINE + sides([("upper_arm", (0.4, -0.2, -1))]), ground="body")
P.pose(50, FLAT, aims=SPINE + sides([("upper_arm", (0.6, -0.4, -1)), ("forearm", (0.3, -1, -0.3))]), ground="body")

arm.animation_data.action = bpy.data.actions["Idle_Loop"]
bpy.context.scene.render.fps = 30
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("personagens", "porteiro"))
bpy.ops.export_scene.gltf(filepath=paths.character("porteiro"), export_format="GLB",
                          export_animations=True, export_skins=True)
result = {"tris": tris, "verts": len(body.data.vertices), "height": round(height, 3), "bones": len(arm.data.bones),
          "actions": [a.name for a in bpy.data.actions], "stride": round(stride, 3),
          "walk_speed_m_s": round(2 * stride / (32 / 30), 2)}
print("RESULT", result)

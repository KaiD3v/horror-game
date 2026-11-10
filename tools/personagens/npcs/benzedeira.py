# Dona Firmina, the healer (quest giver): bent, praying with a rosary, candles burning at her feet
# Run alone: blender -b --factory-startup --python tools/personagens/npcs/benzedeira.py (or all: npcs_build.py)
#   -> blender/npcs/benzedeira.blend, godot_demo/models/characters/npc_benzedeira.glb, renders/npcs/npc_benzedeira_{front,34}.png
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "comum"))  # tools/comum
from npc_kit import *

lp.clear_scene()
SKIN = (0.66, 0.49, 0.38)
fc = Face(SKIN, 3)
for cx in (15, 48):
    fc.blend(cx, 22, 7, 5, (0.70, 0.44, 0.38), 0.25)               # a little colour in the cheeks
for y, a in ((40, 0.25), (43, 0.2), (46, 0.15)):                  # forehead lines
    for x in range(18, 47):
        fc.px(x, y + (1 if 28 < x < 36 else 0), np.array(SKIN) * (1 - a))
fc.eyes((0.30, 0.24, 0.18), open_=2.4, bags=0.6)
fc.brows((0.78, 0.76, 0.72), raise_inner=2, y0=37, thick=1)       # thin white brows, worried
for i in range(8):                                                  # deep lines from the nose to the mouth
    fc.px(25 - i // 3, 21 - i, np.array(SKIN) * 0.65); fc.px(39 + i // 3, 21 - i, np.array(SKIN) * 0.65)
for cx in (14, 50):                                                 # crow's feet
    for k in range(3):
        fc.px(cx + (1 if cx > 32 else -1) * k, 31 + k - 1, np.array(SKIN) * 0.7)
fc.nose((0.62, 0.40, 0.32), 0.2)
fc.mouth((0.30, 0.17, 0.15), (0.42, 0.26, 0.22), down=1, w=3)
for x in range(26, 39, 3):                                          # pursed lip lines
    fc.px(x, 13, np.array(SKIN) * 0.75)
fc.px(41, 17, (0.22, 0.14, 0.10)); fc.px(42, 17, (0.22, 0.14, 0.10))  # a mole
fc.f[54:64, 12:52, :3] = (0.82, 0.80, 0.76)                         # white hair under the scarf edge
FACE = fc.image("benzedeira_face_64")
G = grime(31)
M = dict(skin=lp.mat("b_skin", SKIN, tex=G), face=lp.mat("b_face", SKIN, face=FACE),
         dress=lp.mat("b_dress", (0.10, 0.09, 0.09), tex=grime(32, 0.7)), shawl=lp.mat("b_shawl", (0.22, 0.20, 0.19), tex=grime(33, 0.7)),
         scarf=lp.mat("b_scarf", (0.07, 0.07, 0.08), tex=G), shoe=lp.mat("b_shoe", (0.08, 0.07, 0.06)),
         stocking=lp.mat("b_stocking", (0.16, 0.14, 0.13)), bead=lp.mat("b_bead", (0.62, 0.58, 0.50)),
         cross=lp.mat("b_cross", (0.68, 0.60, 0.34)), wax=lp.mat("b_wax", (0.86, 0.83, 0.72), tex=G),
         flame=lp.mat("b_flame", (1.0, 0.72, 0.30), emit=4.0))
J = {"pelvis": (0, 0.03, 0.84), "spine": (0, 0.02, 1.03), "chest": (0, -0.10, 1.21), "neck": (0, -0.17, 1.27),
     "skull": (0, -0.24, 1.46)}  # bent: the chest well forward, the head pushed out and down
sides(J, {"hip": (0.08, 0.03, 0.83), "knee": (0.08, 0.0, 0.46), "ank": (0.08, 0.03, 0.08), "toe": (0.08, -0.09, 0.03),
          "sh": (0.16, -0.08, 1.19), "el": (0.17, -0.18, 1.0), "wr": (0.035, -0.31, 1.07), "tip": (0.02, -0.34, 1.17)})
K = lp.Kit()
K.tube("skirt", M["dress"], "hips", (0, 0.03, 0.14), J["spine"],
       [(0, 0.26, 0.23, -0.02), (0.35, 0.22, 0.2), (0.78, 0.18, 0.16), (1, 0.15, 0.12, -0.02)], n=10)
K.tube("bodice", M["dress"], "chest", J["spine"], J["chest"], [(0, 0.15, 0.12), (0.6, 0.155, 0.13), (1, 0.12, 0.10)], n=8)
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.05, 0.045)
# shawl over the shoulders and arms down to the elbows, fringed
K.tube("shawl", M["shawl"], "chest", (0, -0.07, 0.98), (0, -0.16, 1.31),
       [(0, 0.27, 0.17, 0.03), (0.4, 0.25, 0.16, 0.02), (0.85, 0.15, 0.12), (1, 0.08, 0.08)], n=10)  # open look: flat in front
for i in range(12):
    a = 2 * math.pi * (i + 0.5) / 12
    if math.sin(a) < -0.55:
        continue  # front opening where the hands come out
    K.box("fringe", M["shawl"], "chest", (0.27 * math.cos(a), -0.03 + 0.17 * math.sin(a), 0.95), (0.025, 0.01, 0.09),
          rot=(0, 0, a + math.pi / 2))
head(K, J, M["skin"], M["face"], [(0, 0.06, 0.065), (0.15, 0.08, 0.085), (0.5, 0.092, 0.1), (0.85, 0.088, 0.095), (1, 0.045, 0.05)])
# the headscarf: a hood round the back of the head, the face looking out of it; knot under the chin
K.tube("scarf", M["scarf"], "head", V(J, "neck", "skull", -0.05), V(J, "neck", "skull", 1.06),
       [(0, 0.08, 0.08, 0.03), (0.3, 0.105, 0.105, 0.035), (0.6, 0.11, 0.11, 0.032), (0.9, 0.095, 0.095, 0.03), (1, 0.05, 0.05, 0.02)], n=10)
K.box("knot", M["scarf"], "head", V(J, "neck") + Vector((0, -0.06, -0.01)), (0.05, 0.04, 0.05))
for s in (".L", ".R"):  # legs hidden: only black stockings and shoes below the hem
    K.seg("stocking", M["stocking"], "shin" + s, V(J, "knee" + s, "ank" + s, 0.6), V(J, "ank" + s), 0.045, 0.04)
limbs(K, J, M, M["shawl"], M["dress"], None, M["shoe"], upper_r=0.05, hand_flat=0.45, hand_up=(0, 1, 0))
# rosary hanging from the joined hands, a little cross at the bottom
for s, sx in ((".L", 1), (".R", -1)):
    for i in range(6):
        t = i / 5
        p = V(J, "wr" + s) + Vector((sx * 0.03 * math.sin(t * math.pi), -0.02, -0.04 - 0.14 * t))
        K.box("bead", M["bead"], "hand.L", p, (0.014, 0.014, 0.014))
c = V(J, "wr.L") + Vector((-0.035, -0.02, -0.25))
K.box("cross", M["cross"], "hand.L", c, (0.012, 0.008, 0.06)); K.box("cross", M["cross"], "hand.L", c + Vector((0, 0, 0.012)), (0.035, 0.008, 0.012))
# candles on the ground before her (not skinned: a separate object)
cb = lp.Kit()
for i, (x, y, h) in enumerate(((0.12, -0.42, 0.16), (-0.02, -0.48, 0.11), (-0.14, -0.40, 0.19), (0.05, -0.56, 0.08), (-0.08, -0.62, 0.13))):
    cb.seg("candle", M["wax"], "none", (x, y, 0), (x, y, h), 0.018, 0.018, n=6)
    cb.spike("flame", M["flame"], "none", (x, y, h + 0.005), (x, y, h + 0.05), 0.012, n=4)
    cb.box("drip", M["wax"], "none", (x, y, 0.005), (0.06, 0.06, 0.01), rot=(0, 0, i))
candles = cb.join("velas")
candles.vertex_groups.clear()
finish("benzedeira", K, J, [
    (f, [("chest", "X", 4 * b), ("head", "X", 7 * b), ("neck", "X", 3 * b), ("hips", "X", 1.5 * b)])
    for f, b in ((1, 0), (11, 1), (21, 0.2), (31, 1), (41, 0), (51, 0.8), (61, 0))], extras=[candles], head_scale=1.15)

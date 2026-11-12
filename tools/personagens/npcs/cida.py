# Cida, the Zé's girl (docs/CONTEUDO_VILAREJO.md "Cida, a filha do Zé"): nine, the one the voice did not get (she was
# under the bed). Lives hidden in the clay oven behind the venda. Small and thin in a faded flowered dress gone grey with
# soot, two braids coming undone, barefoot, dirty knees; her hands held together in front of her, watchful.
# Run alone: blender -b --factory-startup --python tools/personagens/npcs/cida.py (or all: npcs_build.py)
#   -> blender/npcs/cida.blend, godot_demo/models/characters/npc_cida.glb, renders/npcs/npc_cida_{front,34}.png
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "comum"))  # tools/comum
from npc_kit import *

lp.clear_scene()
SKIN = (0.62, 0.45, 0.34)
HAIR = (0.12, 0.09, 0.07)
fc = Face(SKIN, 9)
for cx in (15, 48):
    fc.blend(cx, 22, 7, 5, (0.70, 0.46, 0.38), 0.3)                 # round cheeks
fc.blend(40, 26, 5, 3, (0.30, 0.24, 0.20), 0.35)                    # a smudge of soot
fc.eyes((0.20, 0.13, 0.09), open_=3.2, bags=0.3)                   # big dark eyes, wide open
fc.brows(HAIR, raise_inner=1, y0=38, thick=1)
fc.nose((0.66, 0.44, 0.36), 0.1)
fc.mouth((0.40, 0.22, 0.20), (0.58, 0.36, 0.32), down=0, w=2)      # small, shut tight
fc.f[50:64, :, :3] = HAIR                                           # hair parted in the middle
for y in range(50, 64):
    fc.px(32, y, np.array(HAIR) * 2.2)
FACE = fc.image("cida_face_64")
G = grime(51)
M = dict(skin=lp.mat("c_skin", SKIN, tex=G), face=lp.mat("c_face", SKIN, face=FACE),
         dress=lp.mat("c_dress", (0.62, 0.56, 0.42), tex=grime(52, 0.62)), flower=lp.mat("c_flower", (0.55, 0.30, 0.26)),
         hair=lp.mat("c_hair", HAIR, tex=G), ribbon=lp.mat("c_ribbon", (0.58, 0.14, 0.12)),
         feet=lp.mat("c_feet", (0.42, 0.32, 0.25), tex=G))
J = {"pelvis": (0, 0.0, 0.62), "spine": (0, 0.0, 0.76), "chest": (0, -0.01, 0.9), "neck": (0, -0.01, 0.96),
     "skull": (0, -0.02, 1.12)}
sides(J, {"hip": (0.06, 0.0, 0.61), "knee": (0.06, -0.01, 0.34), "ank": (0.06, 0.01, 0.06), "toe": (0.06, -0.07, 0.02),
          "sh": (0.11, 0.0, 0.92), "el": (0.13, -0.04, 0.73), "wr": (0.05, -0.13, 0.62), "tip": (0.03, -0.15, 0.56)})
K = lp.Kit()
K.tube("dress", M["dress"], "hips", (0, 0.0, 0.36), J["spine"],           # to the knee
       [(0, 0.17, 0.15, -0.01), (0.4, 0.15, 0.13), (0.8, 0.12, 0.10), (1, 0.11, 0.09)], n=10)
K.tube("bodice", M["dress"], "chest", J["spine"], J["chest"], [(0, 0.11, 0.09), (0.6, 0.115, 0.095), (1, 0.09, 0.075)], n=8)
for i in range(9):                                                         # faded flowers on the skirt
    a = 2 * math.pi * i / 9 + 0.3
    K.box("flower", M["flower"], "hips", (0.155 * math.cos(a), 0.135 * math.sin(a), 0.42 + 0.06 * (i % 3)), (0.025, 0.01, 0.025),
          rot=(0, 0, a + math.pi / 2))
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.035, 0.032)
head(K, J, M["skin"], M["face"], [(0, 0.055, 0.06), (0.15, 0.075, 0.08), (0.5, 0.085, 0.09), (0.85, 0.08, 0.085), (1, 0.04, 0.045)])
K.tube("hair", M["hair"], "head", V(J, "neck", "skull", 0.3), V(J, "neck", "skull", 1.06),
       [(0, 0.08, 0.085, 0.02), (0.4, 0.09, 0.095, 0.02), (0.8, 0.086, 0.09, 0.012), (1, 0.045, 0.045)], n=10)
for sx in (1, -1):                                                         # two braids coming undone, red ribbons
    top = V(J, "neck", "skull", 0.35) + Vector((sx * 0.075, 0.03, 0))
    K.seg("braid", M["hair"], "head", top, top + Vector((sx * 0.02, 0.02, -0.17)), 0.022, 0.016)
    K.box("ribbon", M["ribbon"], "head", top + Vector((sx * 0.02, 0.02, -0.17)), (0.04, 0.02, 0.02))
ears(K, J, M["skin"])
for s in (".L", ".R"):                                                     # bare legs below the hem, dirty knees
    K.seg("shin", M["skin"], "shin" + s, V(J, "knee" + s, "ank" + s, -0.05), V(J, "ank" + s), 0.032, 0.026)
limbs(K, J, M, M["dress"], M["skin"], None, M["feet"], upper_r=0.032, hand_flat=0.5)
finish("cida", K, J, [
    (f, [("chest", "X", 2 * b), ("head", "Z", 14 * lk), ("head", "X", 4 * b), ("hips", "Y", 2 * sw)])  # looking round her
    for f, b, lk, sw in ((1, 0, 0, 0), (16, 1, 0.6, 0.5), (31, 0.3, -0.5, 1), (46, 0.8, 0, 0.5), (61, 0, 0, 0))],
    head_scale=1.3)

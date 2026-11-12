# Bastião, the ex-interno (docs/CONTEUDO_VILAREJO.md "Bastião, o ex-interno"): let out of the Colônia by the 1962 law
# with nowhere to go, he lives in the ruin by the gate, by his fire. Old, thin, stooped; Hansen's disease on him the
# way it was in those years: hands wrapped in strips of cloth, the eyebrows gone, pale patches on the face. A brown hood
# round his head and a patched burlap vest over a light long-sleeved shirt, dark trousers, feet wrapped. Not a monster: a man.
# Run alone: blender -b --factory-startup --python tools/personagens/npcs/bastiao.py (or all: npcs_build.py)
#   -> blender/npcs/bastiao.blend, godot_demo/models/characters/npc_bastiao.glb, renders/npcs/npc_bastiao_{front,34}.png
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "comum"))  # tools/comum
from npc_kit import *

lp.clear_scene()
SKIN = (0.55, 0.40, 0.31)
fc = Face(SKIN, 13)
for cx, cy, r in ((16, 40, 6), (45, 22, 5), (30, 46, 4)):              # pale patches
    fc.blend(cx, cy, r, r * 0.8, (0.70, 0.56, 0.47), 0.45)
fc.eyes((0.28, 0.24, 0.20), open_=2.0, bags=0.9)                     # tired eyes; no brows (madarosis)
fc.nose((0.52, 0.36, 0.30), 0.25)
fc.mouth((0.30, 0.18, 0.15), (0.42, 0.28, 0.24), down=1, w=3)
for x in range(18, 47, 3):                                            # a grey stubble
    for y in range(3, 11, 3):
        fc.px(x + (y % 2), y, (0.42, 0.40, 0.38))
FACE = fc.image("bastiao_face_64")
G = grime(61, 0.72)
M = dict(skin=lp.mat("bs_skin", SKIN, tex=G), face=lp.mat("bs_face", SKIN, face=FACE),
         shirt=lp.mat("bs_shirt", (0.66, 0.62, 0.52), tex=grime(62, 0.6)), pants=lp.mat("bs_pants", (0.30, 0.27, 0.22), tex=G),
         hood=lp.mat("bs_hood", (0.36, 0.25, 0.15), tex=grime(63, 0.65)), patch=lp.mat("bs_patch", (0.55, 0.45, 0.32), tex=G),
         wrap=lp.mat("bs_wrap", (0.70, 0.66, 0.56), tex=G))
J = {"pelvis": (0, 0.02, 0.88), "spine": (0, 0.0, 1.08), "chest": (0, -0.07, 1.28), "neck": (0, -0.12, 1.36),
     "skull": (0, -0.17, 1.55)}  # stooped
sides(J, {"hip": (0.09, 0.02, 0.87), "knee": (0.09, -0.01, 0.48), "ank": (0.09, 0.02, 0.08), "toe": (0.09, -0.1, 0.03),
          "sh": (0.17, -0.06, 1.27), "el": (0.2, -0.1, 1.02), "wr": (0.13, -0.24, 0.92), "tip": (0.1, -0.28, 0.85)})
K = lp.Kit()
K.tube("hips", M["pants"], "hips", J["pelvis"], J["spine"], [(0, 0.15, 0.12), (1, 0.14, 0.11)], n=8)
K.tube("shirt", M["shirt"], "chest", (0, 0.0, 0.95), J["chest"], [(0, 0.16, 0.12, -0.01), (0.5, 0.155, 0.115), (1, 0.12, 0.10)], n=8)
# the vest over it, burlap, open at the neck, patched (the drawing he was redone from: a hood and a vest, 2026-11-12)
K.tube("vest", M["hood"], "chest", (0, 0.0, 0.9), V(J, "spine", "chest", 0.95), [(0, 0.175, 0.135, -0.01), (0.5, 0.17, 0.13), (1, 0.15, 0.115)], n=8)
for x, z, w, h in ((-0.07, 1.0, 0.09, 0.08), (0.08, 1.16, 0.07, 0.06), (0.1, 0.96, 0.06, 0.07)):
    K.box("patch", M["patch"], "chest", (x, -0.142 if z < 1.1 else -0.152, z), (w, 0.012, h))
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.045, 0.04)
head(K, J, M["skin"], M["face"], [(0, 0.06, 0.065), (0.15, 0.08, 0.085), (0.5, 0.09, 0.098), (0.85, 0.085, 0.092), (1, 0.045, 0.05)])
ears(K, J, M["skin"])
# the hood: a loose shell round the whole head, set back so the face looks out of its opening, a peak falling back at
# the crown; its lower edge spreads over the shoulders (the cowl)
K.tube("hood", M["hood"], "head", V(J, "neck", "skull", -0.2), V(J, "neck", "skull", 1.18),
       [(0, 0.13, 0.11, 0.08), (0.2, 0.125, 0.12, 0.078), (0.55, 0.13, 0.13, 0.075), (0.85, 0.12, 0.12, 0.07),
        (1, 0.05, 0.06, 0.07)], n=12)
crown = V(J, "neck", "skull", 1.0) + Vector((0, 0.07, 0))
K.spike("peak", M["hood"], "head", crown, crown + Vector((0, 0.12, -0.08)), 0.06, n=6)
K.tube("cowl", M["hood"], "chest", V(J, "chest", "neck", 0.2), V(J, "chest", "neck", 1.0),
       [(0, 0.2, 0.15, 0.02), (0.6, 0.16, 0.13, 0.025), (1, 0.12, 0.11, 0.03)], n=10)
limbs(K, J, M, M["shirt"], M["shirt"], M["pants"], M["wrap"], upper_r=0.045, thigh_r=0.08)  # long light sleeves
for s in (".L", ".R"):                                               # the hands wrapped in strips of cloth
    K.seg("wrap", M["wrap"], "hand" + s, V(J, "wr" + s), V(J, "wr" + s, "tip" + s, 0.9), 0.04, 0.035)
    K.seg("cuff", M["shirt"], "forearm" + s, V(J, "el" + s, "wr" + s, 0.85), V(J, "wr" + s), 0.04, 0.038)
finish("bastiao", K, J, [
    (f, [("chest", "X", 2.5 * b), ("head", "X", 4 * b), ("head", "Z", -8 * lk)])
    for f, b, lk in ((1, 0, 0), (16, 1, 0.3), (31, 0.2, 1), (46, 1, 0.5), (61, 0, 0))], head_scale=1.15)

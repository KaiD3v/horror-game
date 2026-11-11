# His mother, in 1955 (the opening's memory, docs/INTRODUCAO.md): an interned woman of about thirty, upright and thin,
# in the Colônia's pale gown, dark hair pulled back in a bun, the patient's band on her wrist, cloth slippers.
# Run alone: blender -b --factory-startup --python tools/personagens/npcs/mae.py (or all: npcs_build.py)
#   -> blender/npcs/mae.blend, godot_demo/models/characters/npc_mae.glb, renders/npcs/npc_mae_{front,34}.png
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "comum"))  # tools/comum
from npc_kit import *

lp.clear_scene()
SKIN = (0.72, 0.55, 0.43)
HAIR = (0.10, 0.08, 0.07)
fc = Face(SKIN, 7)
for cx in (15, 48):
    fc.blend(cx, 24, 6, 6, (0.62, 0.48, 0.40), 0.3)                 # hollow cheeks
fc.eyes((0.22, 0.15, 0.10), open_=2.6, bags=0.85)                  # dark eyes, tired underneath
fc.brows(HAIR, raise_inner=2, y0=37, thick=1)                      # thin, lifted at the middle: sorrow
fc.nose((0.68, 0.48, 0.40), 0.15)
fc.mouth((0.40, 0.22, 0.20), (0.55, 0.34, 0.30), down=1, w=3)
fc.f[52:64, :, :3] = HAIR                                           # her hair, parted, pulled back
for y in range(52, 64):
    fc.px(32, y, np.array(HAIR) * 2.2)
FACE = fc.image("mae_face_64")
G = grime(41)
M = dict(skin=lp.mat("mae_skin", SKIN, tex=G), face=lp.mat("mae_face", SKIN, face=FACE),
         gown=lp.mat("mae_gown", (0.78, 0.80, 0.76), tex=grime(42, 0.72)), hair=lp.mat("mae_hair", HAIR, tex=G),
         band=lp.mat("mae_band", (0.86, 0.84, 0.78)), shoe=lp.mat("mae_shoe", (0.46, 0.42, 0.38), tex=G))
J = {"pelvis": (0, 0.0, 0.86), "spine": (0, 0.0, 1.05), "chest": (0, 0.0, 1.24), "neck": (0, 0.0, 1.33),
     "skull": (0, -0.01, 1.52)}
sides(J, {"hip": (0.08, 0.0, 0.85), "knee": (0.08, -0.01, 0.47), "ank": (0.08, 0.02, 0.07), "toe": (0.08, -0.09, 0.03),
          "sh": (0.15, 0.0, 1.27), "el": (0.18, 0.02, 1.02), "wr": (0.19, -0.01, 0.8), "tip": (0.19, -0.02, 0.71)})
K = lp.Kit()
K.tube("gown", M["gown"], "hips", (0, 0.0, 0.34), J["spine"],          # loose to below the knee
       [(0, 0.21, 0.17, -0.01), (0.4, 0.19, 0.155), (0.8, 0.16, 0.13), (1, 0.14, 0.11)], n=10)
K.tube("bodice", M["gown"], "chest", J["spine"], J["chest"], [(0, 0.14, 0.11), (0.6, 0.15, 0.12), (1, 0.12, 0.095)], n=8)
K.tube("collar", M["gown"], "chest", V(J, "spine", "chest", 0.9), J["chest"], [(0, 0.13, 0.1), (1, 0.08, 0.07)], n=8)
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.045, 0.04)
head(K, J, M["skin"], M["face"], [(0, 0.055, 0.06), (0.15, 0.075, 0.08), (0.5, 0.085, 0.092), (0.85, 0.08, 0.087), (1, 0.04, 0.045)])
K.tube("hair", M["hair"], "head", V(J, "neck", "skull", 0.35), V(J, "neck", "skull", 1.05),  # close round the back of the head
       [(0, 0.08, 0.085, 0.02), (0.4, 0.092, 0.097, 0.018), (0.8, 0.088, 0.09, 0.012), (1, 0.05, 0.05)], n=10)
K.box("bun", M["hair"], "head", V(J, "neck", "skull", 0.62) + Vector((0, 0.1, 0)), (0.07, 0.05, 0.065))
ears(K, J, M["skin"])
for s in (".L", ".R"):  # bare shins below the hem
    K.seg("shin", M["skin"], "shin" + s, V(J, "knee" + s, "ank" + s, 0.25), V(J, "ank" + s), 0.04, 0.034)
limbs(K, J, M, M["gown"], M["skin"], None, M["shoe"], upper_r=0.045, hand_flat=0.5)
K.box("band", M["band"], "forearm.L", V(J, "el.L", "wr.L", 0.85), (0.06, 0.06, 0.02))  # the patient's band
finish("mae", K, J, [
    (f, [("chest", "X", 1.5 * b), ("head", "X", 2.5 * b), ("hips", "X", 0.5 * b)])
    for f, b in ((1, 0), (16, 1), (31, 0.3), (46, 0.9), (61, 0))], head_scale=1.12)

# Bastião, the ex-interno (docs/CONTEUDO_VILAREJO.md "Bastião, o ex-interno"): let out of the Colônia by the 1962 law
# with nowhere to go, he lives in the ruin by the gate, by his fire. Built after the author's reference model
# (2026-11-12): upright and lean; a thin brown hood close round the head, a small point falling back, the face looking
# out of it; the hood's cloth spread over the shoulders as a short cape, longer down the back; a vest, brown above, a paler
# patched panel below; long pale shirt sleeves; dark trousers; pale cloth-wrapped shoes. Hansen's disease the way it was
# in those years, quietly: no eyebrows, pale patches on the face, strips of cloth round the wrists. Not a monster: a man.
# Run alone: blender -b --factory-startup --python tools/personagens/npcs/bastiao.py (or all: npcs_build.py)
#   -> blender/npcs/bastiao.blend, godot_demo/models/characters/npc_bastiao.glb, renders/npcs/npc_bastiao_{front,34}.png
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "comum"))  # tools/comum
from npc_kit import *

lp.clear_scene()
SKIN = (0.70, 0.54, 0.43)
fc = Face(SKIN, 13)
for cx, cy, r in ((17, 41, 5), (46, 21, 4)):                          # two pale patches
    fc.blend(cx, cy, r, r * 0.8, (0.80, 0.66, 0.57), 0.35)
for cx in (15, 48):
    fc.blend(cx, 24, 6, 6, (0.62, 0.46, 0.38), 0.25)                 # hollow cheeks
fc.eyes((0.26, 0.20, 0.16), open_=2.2, bags=0.7)                     # tired eyes; no brows (madarosis)
fc.nose((0.64, 0.46, 0.38), 0.25)
fc.mouth((0.36, 0.22, 0.19), (0.52, 0.36, 0.31), down=1, w=3)
FACE = fc.image("bastiao_face_64")
G = grime(61, 0.72)
M = dict(skin=lp.mat("bs_skin", SKIN, tex=G), face=lp.mat("bs_face", SKIN, face=FACE),
         shirt=lp.mat("bs_shirt", (0.66, 0.63, 0.55), tex=grime(62, 0.62)),
         pants=lp.mat("bs_pants", (0.20, 0.18, 0.15), tex=G),
         hood=lp.mat("bs_hood", (0.29, 0.19, 0.11), tex=grime(63, 0.88)),  # (soft: cloth, not a block)
         vest=lp.mat("bs_vest", (0.45, 0.36, 0.25), tex=grime(64, 0.7)),
         panel=lp.mat("bs_panel", (0.58, 0.51, 0.40), tex=grime(65, 0.6)),
         wrap=lp.mat("bs_wrap", (0.68, 0.66, 0.60), tex=G))
J = {"pelvis": (0, 0.0, 0.92), "spine": (0, 0.0, 1.12), "chest": (0, -0.01, 1.33), "neck": (0, -0.02, 1.41),
     "skull": (0, -0.03, 1.60)}
sides(J, {"hip": (0.09, 0.0, 0.91), "knee": (0.095, -0.01, 0.50), "ank": (0.095, 0.02, 0.08), "toe": (0.095, -0.10, 0.03),
          "sh": (0.18, 0.0, 1.33), "el": (0.21, 0.02, 1.07), "wr": (0.17, -0.13, 0.90), "tip": (0.15, -0.19, 0.83)})
K = lp.Kit()
K.tube("hips", M["pants"], "hips", J["pelvis"], J["spine"], [(0, 0.15, 0.115), (1, 0.145, 0.11)], n=8)
# the vest over the shirt: brown, a paler patched panel low on the front
K.tube("vest", M["vest"], "chest", (0, 0.0, 0.86), (0, -0.01, 1.31),
       [(0, 0.185, 0.135), (0.45, 0.18, 0.13), (0.8, 0.17, 0.125), (1, 0.14, 0.11)], n=10)
K.box("panel", M["panel"], "hips", (0, -0.136, 0.97), (0.32, 0.012, 0.2))
K.box("patch", M["panel"], "chest", (0.07, -0.135, 1.15), (0.08, 0.012, 0.07), rot=(0, 0.1, 0))
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.045, 0.04)
head(K, J, M["skin"], M["face"], [(0, 0.06, 0.065), (0.15, 0.08, 0.085), (0.5, 0.09, 0.098), (0.85, 0.085, 0.092), (1, 0.045, 0.05)])
# (no ears: the hood covers them)
# the hood: a thin layer of cloth close round the head (a finger's width off it), its edge down to the brow and open
# round the cheeks and under the chin, a small point at the crown falling back
K.tube("hood", M["hood"], "head", V(J, "neck", "skull", 0.05), V(J, "neck", "skull", 1.35),
       [(0, 0.105, 0.09, 0.07), (0.23, 0.1, 0.105, 0.05), (0.44, 0.103, 0.112, 0.035), (0.615, 0.1, 0.11, 0.012),
        (0.746, 0.075, 0.088, 0.028), (0.846, 0.05, 0.058, 0.055), (0.96, 0.02, 0.022, 0.095), (1, 0.008, 0.008, 0.11)], n=12)
# the hood's cloth over the shoulders: a short cape, the arms coming out under it, longer down the back
K.tube("cape", M["hood"], "chest", (0, 0.03, 1.16), (0, -0.01, 1.44),
       [(0, 0.26, 0.15, 0.1), (0.5, 0.25, 0.14, 0.09), (0.82, 0.18, 0.115, 0.07), (1, 0.095, 0.075, 0.05)], n=12)
# (set back: over the shoulders and the back only, the vest open in front)
K.box("back", M["hood"], "chest", (0, 0.17, 1.02), (0.4, 0.03, 0.3), rot=(-0.12, 0, 0))
limbs(K, J, M, M["shirt"], M["shirt"], M["pants"], M["wrap"], upper_r=0.045, thigh_r=0.085)
for s in (".L", ".R"):                                               # strips of cloth round the wrists
    K.seg("wrist", M["wrap"], "forearm" + s, V(J, "el" + s, "wr" + s, 0.8), V(J, "wr" + s), 0.041, 0.039)
finish("bastiao", K, J, [
    (f, [("chest", "X", 1.5 * b), ("head", "X", 3 * b), ("head", "Z", -7 * lk)])
    for f, b, lk in ((1, 0, 0), (16, 1, 0.3), (31, 0.2, 1), (46, 1, 0.5), (61, 0, 0))], head_scale=1.15)

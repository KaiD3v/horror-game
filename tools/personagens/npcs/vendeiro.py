# Seu Bento, the shopkeeper: hands folded on his belly, waiting behind the counter
# Run alone: blender -b --factory-startup --python tools/personagens/npcs/vendeiro.py (or all: npcs_build.py)
#   -> blender/npcs/vendeiro.blend, godot_demo/models/characters/npc_vendeiro.glb, renders/npcs/npc_vendeiro_{front,34}.png
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "comum"))  # tools/comum
from npc_kit import *

lp.clear_scene()
SKIN = (0.80, 0.63, 0.53)
fc = Face(SKIN, 1)
fc.blend(32, 56, 30, 9, (0.86, 0.70, 0.60), 0.35)          # shiny bald forehead
for cx in (15, 48):
    fc.blend(cx, 22, 7, 5, (0.80, 0.48, 0.42), 0.35)        # ruddy cheeks
fc.eyes((0.30, 0.24, 0.18), open_=2.0, bags=0.75)
fc.brows((0.62, 0.60, 0.56), raise_inner=1, y0=37, thick=2)  # grey brows
fc.nose((0.82, 0.48, 0.42), 0.5)
fc.mouth((0.40, 0.22, 0.20), (0.66, 0.42, 0.38), down=0, w=3)
for cx in (20, 44):  # glasses: wire frames round both eyes, painted (the lenses are real geometry)
    for x in range(cx - 6, cx + 7):
        fc.px(x, 27, (0.30, 0.26, 0.20)); fc.px(x, 37, (0.30, 0.26, 0.20))
    for y in range(27, 38):
        fc.px(cx - 6, y, (0.30, 0.26, 0.20)); fc.px(cx + 6, y, (0.30, 0.26, 0.20))
for x in range(27, 38):
    fc.px(x, 33, (0.30, 0.26, 0.20))
for y in range(4, 9):  # double chin line
    fc.px(20 + y, y, np.array(SKIN) * 0.8); fc.px(44 - y, y, np.array(SKIN) * 0.8)
FACE = fc.image("vendeiro_face_64")
G = grime(11)
M = dict(skin=lp.mat("v_skin", SKIN, tex=G), face=lp.mat("v_face", SKIN, face=FACE),
         shirt=lp.mat("v_shirt", (0.74, 0.71, 0.62), tex=G), vest=lp.mat("v_vest", (0.24, 0.20, 0.17), tex=G),
         apron=lp.mat("v_apron", (0.64, 0.58, 0.46), tex=grime(12, 0.86)), pants=lp.mat("v_pants", (0.33, 0.30, 0.26), tex=G),
         shoe=lp.mat("v_shoe", (0.12, 0.10, 0.09)), hair=lp.mat("v_hair", (0.58, 0.57, 0.54), tex=G),
         glass=lp.mat("v_glass", (0.55, 0.62, 0.62)), wire=lp.mat("v_wire", (0.30, 0.26, 0.20)),
         pencil=lp.mat("v_pencil", (0.80, 0.62, 0.18)))
J = {"pelvis": (0, 0, 0.93), "spine": (0, 0, 1.16), "chest": (0, 0, 1.41), "neck": (0, -0.01, 1.47),
     "skull": (0, -0.01, 1.71)}
sides(J, {"sh": (0.21, 0.0, 1.38), "el": (0.25, -0.03, 1.10), "wr": (0.10, -0.30, 1.03), "tip": (0.03, -0.32, 1.0),
          "hip": (0.10, 0.0, 0.92), "knee": (0.11, -0.02, 0.50), "ank": (0.11, 0.01, 0.09), "toe": (0.11, -0.13, 0.03)})
K = lp.Kit()
belly = K.tube("belly", M["shirt"], "hips", J["pelvis"], J["spine"], [(0, 0.17, 0.14), (0.5, 0.21, 0.21, -0.05), (1, 0.20, 0.18, -0.04)], n=10)
vest = K.tube("vest", M["vest"], "chest", J["spine"], J["chest"], [(0, 0.205, 0.185, -0.04), (0.55, 0.215, 0.16, -0.01), (1, 0.15, 0.11)], n=10)
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.07, 0.065)
K.box("collar", M["shirt"], "chest", (0, -0.07, 1.43), (0.16, 0.06, 0.05), rot=(0.3, 0, 0))
for i in range(3):  # vest buttons
    K.box("button", M["wire"], "chest", (0, -0.235 + 0.03 * i, 1.22 + 0.06 * i), (0.02, 0.01, 0.02))
front(belly, M["apron"], -0.35); front(vest, M["apron"], -0.8, zmax=0.16)  # a narrow bib  # the apron painted on, over the belly
K.box("apron", M["apron"], "hips", (0, -0.17, 0.75), (0.36, 0.02, 0.40), rot=(-0.06, 0, 0))   # and hanging below it
K.box("pocket", M["apron"], "hips", (0.08, -0.185, 0.70), (0.14, 0.012, 0.12), rot=(-0.06, 0, 0))
K.box("pencil", M["pencil"], "hips", (0.06, -0.19, 0.77), (0.012, 0.012, 0.12), rot=(-0.1, 0.2, 0))
head(K, J, M["skin"], M["face"], [(0, 0.075, 0.08), (0.18, 0.10, 0.105), (0.5, 0.108, 0.115), (0.82, 0.10, 0.105), (1, 0.05, 0.055)])
ears(K, J, M["skin"])
K.tube("fringe", M["hair"], "head", V(J, "neck", "skull", 0.36), V(J, "neck", "skull", 0.70),
       [(0, 0.112, 0.112, 0.025), (1, 0.114, 0.112, 0.03)], n=10)                  # grey fringe round the back
K.box("mustache", M["hair"], "head", V(J, "neck", "skull", 0.27) + Vector((0, -0.112, 0)), (0.085, 0.03, 0.03), rot=(0.2, 0, 0))
for sx in (1, -1):  # glasses: lenses and arms
    K.box("lens", M["glass"], "head", V(J, "neck", "skull", 0.5) + Vector((sx * 0.045, -0.118, 0)), (0.045, 0.006, 0.035))
    K.box("temple", M["wire"], "head", V(J, "neck", "skull", 0.52) + Vector((sx * 0.1, -0.06, 0)), (0.006, 0.11, 0.006))
K.box("pencil_ear", M["pencil"], "head", V(J, "neck", "skull", 0.55) + Vector((0.11, 0.0, 0.01)), (0.01, 0.1, 0.01), rot=(0.4, 0, 0))
limbs(K, J, M, M["shirt"], M["skin"], M["pants"], M["shoe"], upper_r=0.056, thigh_r=0.118)  # sleeves rolled: bare forearms
for s in (".L", ".R"):
    K.seg("rolled", M["shirt"], "forearm" + s, V(J, "el" + s, "wr" + s, 0.05), V(J, "el" + s, "wr" + s, 0.22), 0.058, 0.056)
finish("vendeiro", K, J, [
    (f, [("chest", "X", -1.5 * b), ("head", "Z", 18 * lk), ("head", "X", -3 * b), ("hips", "Y", 1.5 * sw)])
    for f, b, lk, sw in ((1, 0, 0, 0), (16, 1, 0, 0.5), (31, 0, 1, 1), (41, 0.5, 1, 0.5), (51, 1, 0.3, 0), (61, 0, 0, 0))],
    head_scale=1.2)

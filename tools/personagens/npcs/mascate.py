# Seu Dito, the peddler (docs/CONTEUDO_VILAREJO.md "O mascate"): came up selling from village to village with his mule
# and got stuck this side when the bridge fell. Tall and thin, sunburnt, a straw hat, a faded striped jacket over a
# collarless shirt, trousers tucked into old boots, a bag across his chest; a sly, tired smile.
# Run alone: blender -b --factory-startup --python tools/personagens/npcs/mascate.py (or all: npcs_build.py)
#   -> blender/npcs/mascate.blend, godot_demo/models/characters/npc_mascate.glb, renders/npcs/npc_mascate_{front,34}.png
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "comum"))  # tools/comum
from npc_kit import *

lp.clear_scene()
SKIN = (0.66, 0.46, 0.33)
fc = Face(SKIN, 17)
for cx in (15, 48):
    fc.blend(cx, 22, 7, 5, (0.72, 0.44, 0.34), 0.35)                 # sunburnt cheeks
fc.eyes((0.24, 0.18, 0.12), open_=2.0, bags=0.6)
fc.brows((0.20, 0.15, 0.12), raise_inner=0, y0=37, thick=2)
fc.nose((0.62, 0.40, 0.32), 0.35)
fc.mouth((0.34, 0.20, 0.17), (0.50, 0.32, 0.28), down=0, w=4)
for x in range(23, 42):                                             # a thin moustache
    fc.px(x, 16, (0.18, 0.13, 0.10)); fc.px(x, 17, (0.18, 0.13, 0.10))
FACE = fc.image("mascate_face_64")
G = grime(71)
M = dict(skin=lp.mat("m_skin", SKIN, tex=G), face=lp.mat("m_face", SKIN, face=FACE),
         jacket=lp.mat("m_jacket", (0.46, 0.40, 0.33), tex=grime(72, 0.7)), shirt=lp.mat("m_shirt", (0.76, 0.72, 0.62), tex=G),
         pants=lp.mat("m_pants", (0.28, 0.27, 0.25), tex=G), boot=lp.mat("m_boot", (0.18, 0.13, 0.09), tex=G),
         straw=lp.mat("m_straw", (0.78, 0.68, 0.42), tex=grime(73, 0.75)), band=lp.mat("m_band", (0.3, 0.12, 0.1)),
         bag=lp.mat("m_bag", (0.42, 0.30, 0.18), tex=G), hair=lp.mat("m_hair", (0.16, 0.12, 0.10)))
J = {"pelvis": (0, 0.0, 0.98), "spine": (0, 0.0, 1.2), "chest": (0, -0.01, 1.44), "neck": (0, -0.02, 1.52),
     "skull": (0, -0.03, 1.72)}
sides(J, {"hip": (0.09, 0.0, 0.97), "knee": (0.095, -0.01, 0.53), "ank": (0.095, 0.02, 0.08), "toe": (0.095, -0.11, 0.03),
          "sh": (0.19, 0.0, 1.43), "el": (0.22, 0.02, 1.15), "wr": (0.2, -0.04, 0.9), "tip": (0.19, -0.05, 0.82)})
K = lp.Kit()
K.tube("hips", M["pants"], "hips", J["pelvis"], J["spine"], [(0, 0.15, 0.115), (1, 0.145, 0.11)], n=8)
jacket = K.tube("jacket", M["jacket"], "chest", (0, 0.0, 0.92), J["chest"],
                [(0, 0.18, 0.13), (0.4, 0.175, 0.125), (0.8, 0.17, 0.12), (1, 0.13, 0.1)], n=10)
front(jacket, M["shirt"], -0.92, zmax=0.55)                          # the shirt showing down the open front
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.045, 0.04)
head(K, J, M["skin"], M["face"], [(0, 0.06, 0.065), (0.15, 0.08, 0.085), (0.5, 0.088, 0.096), (0.85, 0.084, 0.09), (1, 0.045, 0.05)])
ears(K, J, M["skin"])
K.tube("hair", M["hair"], "head", V(J, "neck", "skull", 0.35), V(J, "neck", "skull", 0.8),
       [(0, 0.09, 0.098, 0.015), (1, 0.092, 0.1, 0.012)], n=10)
brim = V(J, "neck", "skull", 0.78)                                   # the straw hat
K.tube("brim", M["straw"], "head", brim, brim + Vector((0, 0, 0.02)), [(0, 0.22, 0.21), (1, 0.215, 0.205)], n=10)
K.tube("crown", M["straw"], "head", brim, brim + Vector((0, 0, 0.12)), [(0, 0.105, 0.11), (0.8, 0.1, 0.105), (1, 0.07, 0.075)], n=8)
K.tube("hatband", M["band"], "head", brim + Vector((0, 0, 0.015)), brim + Vector((0, 0, 0.04)), [(0, 0.107, 0.112), (1, 0.106, 0.111)], n=8, caps=False)
K.box("strap", M["bag"], "chest", (0, -0.12, 1.2), (0.04, 0.02, 0.62), rot=(0, 0.75, 0))   # the bag across his chest
K.box("bag", M["bag"], "hips", (0.2, -0.04, 0.95), (0.08, 0.26, 0.2))
limbs(K, J, M, M["jacket"], M["jacket"], M["pants"], M["boot"], upper_r=0.048, boot=1, thigh_r=0.088)
finish("mascate", K, J, [
    (f, [("chest", "X", -1.0 * b), ("head", "Z", 10 * lk), ("hips", "Y", 1.5 * sw)])
    for f, b, lk, sw in ((1, 0, 0, 0), (16, 1, 0.5, 0.5), (31, 0, 1, 1), (46, 1, 0.3, 0.5), (61, 0, 0, 0))], head_scale=1.15)

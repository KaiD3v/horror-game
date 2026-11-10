# Tenório, the weapons dealer: hand on his machete, thumb in his belt, shotgun across his back
# Run alone: blender -b --factory-startup --python tools/personagens/npcs/armeiro.py (or all: npcs_build.py)
#   -> blender/npcs/armeiro.blend, godot_demo/models/characters/npc_armeiro.glb, renders/npcs/npc_armeiro_{front,34}.png
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "comum"))  # tools/comum
from npc_kit import *

lp.clear_scene()
SKIN = (0.74, 0.56, 0.43)
fc = Face(SKIN, 2)
fc.f[0:26, :, :3] *= 0.94                                          # stubble shadow, lower face
for _ in range(110):
    x, y = fc.r.integers(6, 58), fc.r.integers(0, 22)
    fc.px(x, y, np.array(SKIN) * 0.7)
fc.eyes((0.24, 0.18, 0.12), open_=1.6, bags=0.8, milky_right=True)  # narrowed; the right one clouded
fc.brows((0.12, 0.09, 0.07), raise_inner=-2, y0=36, thick=2)        # hard, lowered brows
for i in range(14):                                                 # scar down through the clouded eye
    fc.px(16 + i // 4, 43 - i * 1.5, (0.45, 0.24, 0.20))
fc.nose((0.70, 0.45, 0.36), 0.3)
fc.mouth((0.28, 0.14, 0.12), (0.45, 0.28, 0.24), down=1, w=4)
for x in range(26, 39):                                             # thin mustache
    fc.px(x, 14, (0.12, 0.09, 0.07)); fc.px(x, 15, (0.12, 0.09, 0.07))
FACE = fc.image("armeiro_face_64")
G = grime(21)
M = dict(skin=lp.mat("a_skin", SKIN, tex=G), face=lp.mat("a_face", SKIN, face=FACE),
         poncho=lp.mat("a_poncho", (0.34, 0.16, 0.12), tex=grime(22, 0.7)), stripe=lp.mat("a_stripe", (0.62, 0.48, 0.22), tex=G),
         shirt=lp.mat("a_shirt", (0.50, 0.47, 0.40), tex=G), pants=lp.mat("a_pants", (0.20, 0.20, 0.18), tex=G),
         boot=lp.mat("a_boot", (0.28, 0.17, 0.10), tex=G), hat=lp.mat("a_hat", (0.16, 0.13, 0.11), tex=G),
         leather=lp.mat("a_leather", (0.36, 0.22, 0.12), tex=G), brass=lp.mat("a_brass", (0.72, 0.56, 0.24)),
         shell=lp.mat("a_shell", (0.58, 0.14, 0.10)), steel=lp.mat("a_steel", (0.34, 0.35, 0.36), tex=G),
         wood=lp.mat("a_wood", (0.36, 0.22, 0.12), tex=G))
J = {"pelvis": (0, 0, 1.0), "spine": (0, 0, 1.25), "chest": (0, 0, 1.51), "neck": (0, -0.01, 1.58),
     "skull": (0, -0.015, 1.82)}
sides(J, {"hip": (0.09, 0.0, 0.99), "knee": (0.10, -0.02, 0.54), "ank": (0.10, 0.01, 0.09), "toe": (0.10, -0.14, 0.03)})
J.update({"sh.L": (0.19, 0, 1.48), "el.L": (0.25, 0.04, 1.20), "wr.L": (0.22, -0.06, 0.99), "tip.L": (0.2, -0.09, 0.9),  # on the machete
          "sh.R": (-0.19, 0, 1.48), "el.R": (-0.26, 0.02, 1.21), "wr.R": (-0.14, -0.15, 1.02), "tip.R": (-0.09, -0.17, 0.95)})  # thumb in belt
K = lp.Kit()
K.tube("waist", M["shirt"], "hips", J["pelvis"], J["spine"], [(0, 0.15, 0.11), (1, 0.15, 0.11)], n=8)
K.tube("chest", M["shirt"], "chest", J["spine"], J["chest"], [(0, 0.15, 0.11), (0.6, 0.18, 0.12), (1, 0.13, 0.10)], n=8)
K.seg("neck", M["skin"], "neck", J["chest"], J["neck"], 0.055, 0.05)
K.tube("belt", M["leather"], "hips", (0, 0, 0.95), (0, 0, 1.01), [(0, 0.158, 0.118), (1, 0.158, 0.118)], n=8)
K.box("buckle", M["brass"], "hips", (0, -0.12, 0.98), (0.05, 0.015, 0.04))
# the poncho: shoulders to just below the waist, a stripe near the hem, a slit for the head
K.tube("poncho", M["poncho"], "chest", (0, 0, 1.06), (0, 0, 1.6),
       [(0, 0.40, 0.30), (0.12, 0.39, 0.29), (0.17, 0.39, 0.29), (0.7, 0.27, 0.19), (0.92, 0.14, 0.12), (1, 0.08, 0.08)], n=8)
K.tube("stripe", M["stripe"], "chest", (0, 0, 1.11), (0, 0, 1.15), [(0, 0.395, 0.295), (1, 0.385, 0.288)], n=8, caps=False)
for i in range(9):  # fringe along the hem
    a = 2 * math.pi * i / 9
    K.box("fringe", M["poncho"], "chest", (0.40 * math.cos(a), 0.30 * math.sin(a), 1.02), (0.03, 0.01, 0.08), rot=(0, 0, a + math.pi / 2))
# bandolier over the poncho, left shoulder to right hip, a row of red shells
p0, p1 = Vector((0.15, -0.17, 1.52)), Vector((-0.24, -0.27, 1.08))
K.seg("bandolier", M["leather"], "chest", p0, p1, 0.035, 0.035, flat=0.3, up=(0, -1, 0))
for i in range(7):
    p = p0.lerp(p1, 0.12 + i * 0.12) + Vector((0, -0.016, 0))
    K.box("shell", M["shell"], "chest", p, (0.016, 0.016, 0.045), rot=(0, -0.75, 0))
# double-barrel shotgun on his back, muzzle over the left shoulder
m0, m1 = Vector((0.20, 0.27, 1.78)), Vector((-0.14, 0.32, 1.12))
for dx in (-0.012, 0.012):
    K.seg("barrel", M["steel"], "chest", m0 + Vector((dx, 0, 0)), m0.lerp(m1, 0.62) + Vector((dx, 0, 0)), 0.012, 0.012, n=4)
K.seg("stock", M["wood"], "chest", m0.lerp(m1, 0.55), m1, 0.03, 0.045, n=4, flat=0.5)
K.seg("sling", M["leather"], "chest", Vector((0.17, 0.0, 1.56)), Vector((-0.2, 0.24, 1.2)), 0.012, 0.012, n=4)
# machete in its sheath on the left hip, his hand on the grip
K.box("sheath", M["leather"], "hips", (0.21, 0.02, 0.72), (0.05, 0.06, 0.42), rot=(0.12, 0, 0))
K.seg("grip", M["wood"], "hips", Vector((0.21, -0.01, 0.94)), Vector((0.21, -0.03, 1.04)), 0.018, 0.018, n=4)
head(K, J, M["skin"], M["face"], [(0, 0.065, 0.07), (0.15, 0.085, 0.095), (0.5, 0.097, 0.108), (0.85, 0.092, 0.1), (1, 0.05, 0.055)])
ears(K, J, M["skin"])
K.tube("hair", M["hat"], "head", V(J, "neck", "skull", 0.4), V(J, "neck", "skull", 0.82),
       [(0, 0.1, 0.1, 0.02), (1, 0.103, 0.104, 0.02)], n=10)              # dark hair under the hat
brim = V(J, "neck", "skull", 0.8)
K.tube("brim", M["hat"], "head", brim, brim + Vector((0, 0, 0.025)), [(0, 0.26, 0.25), (1, 0.25, 0.24)], n=10)
K.tube("crown", M["hat"], "head", brim, brim + Vector((0, 0, 0.14)), [(0, 0.11, 0.115), (0.8, 0.1, 0.105), (1, 0.06, 0.07)], n=8)
K.tube("hatband", M["leather"], "head", brim + Vector((0, 0, 0.02)), brim + Vector((0, 0, 0.045)),
       [(0, 0.112, 0.117), (1, 0.111, 0.116)], n=8, caps=False)
limbs(K, J, M, M["poncho"], M["shirt"], M["pants"], M["boot"], upper_r=0.05, boot=1, thigh_r=0.095)
for s in (".L", ".R"):  # tall boots up to the knee
    K.seg("bootleg", M["boot"], "shin" + s, V(J, "knee" + s, "ank" + s, 0.1), V(J, "ank" + s), 0.078, 0.064)
finish("armeiro", K, J, [
    (f, [("chest", "X", -1.2 * b), ("hips", "Y", -2.5 * sw), ("chest", "Y", 2 * sw), ("head", "Y", 4 * sw),
         ("head", "Z", -10 * lk)])
    for f, b, sw, lk in ((1, 0, 0, 0), (16, 1, 0.5, 0), (31, 0, 1, 1), (46, 1, 0.5, 1), (61, 0, 0, 0))],
    head_scale=1.18)

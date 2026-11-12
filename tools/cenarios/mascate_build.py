# The peddler's things and the ravine's (docs/CONTEUDO_VILAREJO.md "O mascate", "O fundo da ravina"), one GLB of
# separate pieces the village places (vilarejo.gd _mascate, _ravine). Each origin on the ground at its middle, its front
# to -Y (glTF +Z):
#   mula      Seu Dito's mule, standing, the pack saddle (cangalha) with two baskets, a halter rope
#   carroca   his handcart of goods: a box on two wheels, the shafts down, pans and a bolt of cloth on it
#   lona      a tarp stretched from two poles to the ground: where he sleeps
#   tronco    the log he felled to bridge the ravine, 11.5 m, its origin at its foot (it stands up along +Z)
#   carro     Dr. Euclides's car at the bottom of the ravine, a 1960s sedan on its side in the mud, a door open
# Run: blender -b --factory-startup --python tools/cenarios/mascate_build.py
#   -> blender/cenarios/mascate.blend, godot_demo/models/props/mascate.glb
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder

mat("mula", "cloth", 1.0, tint=(0.42, 0.33, 0.26)); mat("mula_escura", "cloth", 1.0, tint=(0.2, 0.16, 0.13))
mat("lona_m", "cloth", 1.0, tint=(0.45, 0.47, 0.38)); mat("cesto", "planks", 1.0, tint=(0.85, 0.7, 0.45))
mat("carro_tinta", "enamel", 1.0, tint=(0.2, 0.25, 0.32)); mat("cromo", "machine", 1.0, tint=(0.9, 0.9, 0.92))
mat("vidro", "window_in", 1.0, tint=(0.6, 0.7, 0.75))
rng = random.Random("mascate")

# --- the mule -------------------------------------------------------------------------------------------------------
m = B()
frustum(m, (0, 0.55, 1.05), (0, -0.5, 1.12), 0.27, 0.3, 8, "mula", caps=True)              # barrel
for x, y in ((-0.16, 0.42), (0.16, 0.42), (-0.16, -0.38), (0.16, -0.38)):                   # legs
    frustum(m, (x, y, 0.95), (x, y, 0.08), 0.07, 0.045, 6, "mula", caps=True)
    bx(m, (x, y - 0.01, 0.04), (0.09, 0.11, 0.08), "mula_escura")
frustum(m, (0, -0.48, 1.2), (0, -0.78, 1.62), 0.16, 0.11, 6, "mula", caps=True)             # neck
frustum(m, (0, -0.74, 1.66), (0, -1.16, 1.48), 0.11, 0.075, 6, "mula", caps=True)           # head, the long muzzle
bx(m, (0, -1.18, 1.46), (0.13, 0.08, 0.12), "mula_escura")
for sx in (-1, 1):                                                                         # the long ears
    frustum(m, (sx * 0.06, -0.72, 1.74), (sx * 0.13, -0.66, 2.0), 0.035, 0.012, 4, "mula", caps=True)
frustum(m, (0, 0.6, 1.12), (0, 0.72, 0.62), 0.03, 0.05, 4, "mula_escura", caps=True)       # tail
bx(m, (0, -0.45, 1.45), (0.04, 0.32, 0.12), "mula_escura", rot=(0.7, 0, 0))                # mane
bx(m, (0, 0.05, 1.42), (0.5, 0.6, 0.08), "planks")                                          # the pack saddle
for sx in (-1, 1):                                                                         # its two baskets
    bx(m, (sx * 0.38, 0.05, 1.2), (0.24, 0.5, 0.42), "cesto")
    bx(m, (sx * 0.38, 0.05, 1.42), (0.22, 0.46, 0.04), "lona_m")
frustum(m, (0, -1.1, 1.42), (0.3, -1.4, 0.3), 0.012, 0.012, 4, "burlap")                    # halter rope to the ground
obj(m, "mula")

# --- the handcart ------------------------------------------------------------------------------------------------------
c = B()
bx(c, (0, 0, 0.62), (1.0, 1.4, 0.06), "planks")
for sx in (-1, 1):
    bx(c, (sx * 0.5, 0, 0.8), (0.04, 1.4, 0.32), "planks")
    frustum(c, (sx * 0.58, 0.1, 0.42), (sx * 0.64, 0.1, 0.42), 0.42, 0.42, 10, "planks", caps=True)    # wheels
    frustum(c, (sx * 0.4, -0.7, 0.62), (sx * 0.35, -1.6, 0.05), 0.03, 0.03, 4, "planks", caps=True)   # shafts
bx(c, (0, 0.62, 0.8), (1.0, 0.04, 0.32), "planks")
for k in range(3):                                                                        # pans, a bolt of cloth, a sack
    frustum(c, (-0.25 + 0.2 * k, -0.2, 0.66), (-0.25 + 0.2 * k, -0.2, 0.78), 0.1, 0.11, 8, "iron", caps=True)
frustum(c, (-0.3, 0.3, 0.75), (0.3, 0.3, 0.75), 0.11, 0.11, 8, "cloth_red", caps=True)
bx(c, (0.25, 0.35, 0.82), (0.3, 0.35, 0.36), "burlap", rot=(0, 0, 0.2))
obj(c, "carroca")

# --- the tarp ------------------------------------------------------------------------------------------------------------
t = B()
for sx in (-1, 1):
    frustum(t, (sx * 1.1, -0.9, 0), (sx * 1.1, -0.9, 1.3), 0.03, 0.03, 4, "planks", caps=True)
t.poly([Vector((-1.15, -0.9, 1.3)), Vector((1.15, -0.9, 1.3)), Vector((1.15, 1.0, 0.02)), Vector((-1.15, 1.0, 0.02))], "lona_m")
t.poly([Vector((-1.15, 1.0, 0.02)), Vector((1.15, 1.0, 0.02)), Vector((1.15, -0.9, 1.3)), Vector((-1.15, -0.9, 1.3))], "lona_m")
bx(t, (0, 0.2, 0.04), (1.6, 1.6, 0.06), "cloth_grey")                                    # the blanket under it
obj(t, "lona")

# --- the log --------------------------------------------------------------------------------------------------------------
g = B()
frustum(g, (0, 0, 0), (0, 0, 11.5), 0.26, 0.2, 7, "casca_musgo", caps=True)
for k in range(4):                                                                        # broken-off branch stubs
    z = rng.uniform(2.0, 10.5); a = rng.uniform(0, 2 * math.pi)
    frustum(g, (0.2 * math.cos(a), 0.2 * math.sin(a), z), (0.55 * math.cos(a), 0.55 * math.sin(a), z + 0.3), 0.06, 0.03, 4, "casca_musgo", caps=True)
bx(g, (0, 0, 0.02), (0.5, 0.5, 0.04), "toco_top")                                          # the axe-cut foot
obj(g, "tronco")

# --- Dr. Euclides's car at the bottom of the ravine: a 1960s sedan on its wheels in the mud, nose crushed, tilted ---------
k = B()
TILT = Matrix.Rotation(math.radians(9), 4, "X") @ Matrix.Rotation(math.radians(-6), 4, "Y")
def kbx(cn, size, m_, rot=(0, 0, 0)):
    k.box(TILT @ Matrix.LocRotScale(Vector(cn), Euler(rot), Vector(size)), m_)
def kcyl(p0, p1, r, m_):
    a, b_ = TILT @ Vector(p0), TILT @ Vector(p1)
    frustum(k, tuple(a), tuple(b_), r, r, 10, m_, caps=True)
kbx((0, 0.3, 0.55), (1.7, 3.4, 0.5), "carro_tinta")                                        # the body
kbx((0, -1.75, 0.5), (1.66, 0.7, 0.42), "carro_tinta", rot=(0.25, 0, 0.08))                 # the hood, crushed and bent
kbx((0, 0.45, 0.98), (1.5, 1.7, 0.42), "carro_tinta")                                       # the cabin roof
kbx((0, -0.5, 0.95), (1.4, 0.05, 0.4), "vidro", rot=(-0.55, 0, 0))                          # windscreen (cracked dark)
kbx((0, 1.35, 0.95), (1.4, 0.05, 0.38), "vidro", rot=(0.5, 0, 0))                           # rear window
for sx in (-1, 1):
    kbx((sx * 0.76, 0.45, 0.98), (0.04, 1.5, 0.3), "vidro")                                # side windows
    for y in (-1.2, 1.35):
        kcyl((sx * 0.8, y, 0.33), (sx * 0.95, y, 0.33), 0.33, "pit")                         # wheels
        kcyl((sx * 0.94, y, 0.33), (sx * 0.96, y, 0.33), 0.17, "cromo")                      # hubcaps
    kbx((sx * 0.6, -2.12, 0.55), (0.18, 0.04, 0.14), "cromo")                              # headlights
kbx((0, 2.02, 0.45), (1.6, 0.08, 0.12), "cromo"); kbx((0, -2.15, 0.36), (1.4, 0.08, 0.1), "cromo", rot=(0, 0.2, 0))  # bumpers
kbx((1.1, 0.2, 0.75), (0.05, 1.0, 0.6), "carro_tinta", rot=(0, 0, -0.9))                     # the driver's door, open
obj(k, "carro")

# --- a quarry cart on its side by the gallery's mouth (the quarry, docs/CONTEUDO_VILAREJO.md fase 7) ----------------------
v = B()
TIP = Matrix.Rotation(math.radians(80), 4, "Y")
def vbx(cn, size, m_):
    v.box(TIP @ Matrix.LocRotScale(Vector(cn), None, Vector(size)), m_)
vbx((0, 0, 0.55), (0.8, 1.1, 0.06), "iron")
for sx in (-1, 1):
    vbx((sx * 0.4, 0, 0.75), (0.04, 1.1, 0.4), "iron"); vbx((0, sx * 0.55, 0.75), (0.8, 0.04, 0.4), "iron")
for sx in (-1, 1):
    for sy in (-1, 1):
        a_ = TIP @ Vector((sx * 0.42, sy * 0.35, 0.3)); b_ = TIP @ Vector((sx * 0.48, sy * 0.35, 0.3))
        frustum(v, tuple(a_), tuple(b_), 0.16, 0.16, 8, "iron", caps=True)
for k in range(5):
    bx(v, (rng.uniform(-0.6, 0.6), rng.uniform(-0.7, 0.7) - 0.9, 0.1), (0.25, 0.22, 0.18), "stone", rot=(0, 0, rng.uniform(0, 3)))
obj(v, "vagonete")

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "mascate"))
bpy.ops.export_scene.gltf(filepath=paths.prop("mascate"), export_format="GLB", export_yup=True)
print("MASCATE ok")

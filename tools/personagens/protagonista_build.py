# Builds the low-poly horror protagonist (N64-era look) and saves blender/personagens/protagonista.blend.
# Then protagonista_rig.py (same Blender session) rigs, animates and exports models/characters/protagonista.glb:
#   blender -b --factory-startup --python tools/personagens/protagonista_build.py --python tools/personagens/protagonista_rig.py
import bpy, bmesh, math, random, os
import numpy as np
from mathutils import Vector, Matrix

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
for coll in (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.lights,
             bpy.data.cameras, bpy.data.worlds, bpy.data.armatures, bpy.data.actions):
    for d in list(coll):
        coll.remove(d)
scene = bpy.context.scene
random.seed(7)


from lowpoly import lin, new_image  # (tools/comum/lowpoly.py)

# --- tiny textures ---------------------------------------------------------
g = np.ones((32, 32, 4))
noise = np.array([[random.uniform(0.82, 1.0) for _ in range(32)] for _ in range(32)])
for _ in range(14):  # dirt blotches
    cx, cy, r = random.randrange(32), random.randrange(32), random.uniform(1.5, 4)
    yy, xx = np.mgrid[0:32, 0:32]
    noise[((xx - cx) ** 2 + (yy - cy) ** 2) < r * r] *= 0.84
g[:, :, :3] = noise[:, :, None]
GRIME = new_image("grime_32", g)

# skin: a warmer mid tone than the old flat pale beige, and never one flat colour (that read as a placeholder):
# the face is painted with planes, flush and dirt; head, neck and hands get a 32 px skin texture like the grime
SKIN = np.array((0.78, 0.62, 0.52))
st = np.ones((32, 32, 4))
st[:, :, :3] = np.array([[random.uniform(0.93, 1.0) for _ in range(32)] for _ in range(32)])[:, :, None]
yy, xx = np.mgrid[0:32, 0:32]
for _ in range(10):  # warm blotches (blood under the skin)
    cx, cy, r = random.randrange(32), random.randrange(32), random.uniform(1.5, 3.0)
    st[((xx - cx) ** 2 + (yy - cy) ** 2) < r * r, :3] *= (1.0, 0.92, 0.9)
for _ in range(7):   # dirt
    cx, cy, r = random.randrange(32), random.randrange(32), random.uniform(1.0, 2.2)
    st[((xx - cx) ** 2 + (yy - cy) ** 2) < r * r, :3] *= 0.86
SKIN_TEX = new_image("skin_32", st)

W = 64
f = np.ones((W, W, 4)); f[:, :, :3] = SKIN
yy, xx = np.mgrid[0:W, 0:W]
f[:, :, :3] *= (0.92 + 0.10 * yy / W)[:, :, None]  # planes: jaw (row 0) a touch darker, forehead lighter


def blend(cx, cy, rx, ry, col, a):
    m = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1
    f[m, :3] = f[m, :3] * (1 - a) + np.array(col) * a


for cx in (15, 48):
    blend(cx, 24, 7, 4.5, (0.74, 0.47, 0.42), 0.22)      # cold-flushed cheeks (subtle: not a cartoon blush)
blend(31.5, 19.5, 3, 2, (0.80, 0.48, 0.42), 0.4)          # red nose tip
blend(12, 47, 6, 3, (0.42, 0.33, 0.27), 0.35)             # dirt smudge on the forehead
blend(39, 5, 4, 2.5, (0.42, 0.33, 0.27), 0.3)             # and on the chin
blend(32, 2, 30, 4, SKIN * 0.7, 0.35)                     # under-jaw shade
f[:, :, :3] *= np.array([[random.uniform(0.95, 1.0) for _ in range(W)] for _ in range(W)])[:, :, None]


def ell(cx, cy, rx, ry, col):
    f[((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1, :3] = col


def px(x, y, col):
    f[int(y), int(x), :3] = col


for cx in (20, 44):
    ell(cx, 30.5, 6.5, 4.6, SKIN * np.array((0.70, 0.62, 0.72)))  # deep eye bags
    ell(cx, 32, 4.2, 2.6, (0.86, 0.84, 0.74))                    # sclera
    ell(cx, 32, 1.7, 2.2, (0.28, 0.32, 0.33))                    # grey iris
    px(cx, 32, (0.04, 0.04, 0.05)); px(cx, 31, (0.04, 0.04, 0.05))
    px(cx + 1, 33, (0.95, 0.95, 0.92))                           # tiny highlight
    for x in range(cx - 4, cx + 5):                              # heavy upper lid
        px(x, 34, (0.16, 0.10, 0.10))
    for i, x in enumerate(range(cx - 5, cx + 6)):                # worried brows, inner end raised
        t = i / 10 if cx < 32 else 1 - i / 10
        y = 36 + round(t * 2)
        px(x, y, (0.14, 0.10, 0.09)); px(x, y + 1, (0.14, 0.10, 0.09))
for y in range(20, 26):
    px(33, y, SKIN * 0.78)                                       # nose side shadow
px(30, 20, SKIN * 0.6); px(33, 20, SKIN * 0.6)                   # nostrils
for x in range(28, 36):
    px(x, 12, (0.36, 0.19, 0.18))                                # thin mouth
px(27, 11, (0.36, 0.19, 0.18)); px(36, 11, (0.36, 0.19, 0.18))  # corners pulled down
for x in range(29, 35):
    px(x, 11, (0.62, 0.40, 0.36))                                # lower lip
f[19:25, 41:49, :3] = (0.84, 0.76, 0.60)                         # plaster on cheek
f[19:25, 41, :3] = f[19:25, 48, :3] = (0.62, 0.52, 0.40)
px(44, 22, (0.6, 0.36, 0.28)); px(45, 21, (0.6, 0.36, 0.28))     # blood through plaster
for i in range(6):
    px(11 + i, 24 - i, (0.55, 0.20, 0.18))                       # scratch
FACE = new_image("face_64", f)


# --- materials ---------------------------------------------------------------
def mat(name, rgb, grime=True, emit=0.0, image=None, tex=None):
    m = bpy.data.materials.new(name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    nt = m.node_tree
    b = next(n for n in nt.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")  # node names are localized
    b.inputs["Roughness"].default_value = 1.0
    b.inputs["Specular IOR Level"].default_value = 0.0
    col = lin(rgb) + (1.0,)
    if image is not None:
        t = nt.nodes.new("ShaderNodeTexImage"); t.image = image; t.interpolation = "Closest"
        uvn = nt.nodes.new("ShaderNodeUVMap"); uvn.uv_map = "FaceUV"  # primitives add a localized default UV map
        nt.links.new(uvn.outputs["UV"], t.inputs["Vector"])
        nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
    elif grime:
        t = nt.nodes.new("ShaderNodeTexImage"); t.image = tex or GRIME; t.interpolation = "Closest"
        uvn = nt.nodes.new("ShaderNodeUVMap"); uvn.uv_map = "GrimeUV"  # baked box projection, see the join
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = 1.0
        mix.inputs[6].default_value = col
        nt.links.new(uvn.outputs["UV"], t.inputs["Vector"])
        nt.links.new(t.outputs["Color"], mix.inputs[7])
        nt.links.new(mix.outputs[2], b.inputs["Base Color"])
    else:
        b.inputs["Base Color"].default_value = col
    if emit:
        b.inputs["Emission Color"].default_value = col
        b.inputs["Emission Strength"].default_value = emit
    m.diffuse_color = col
    return m


M = dict(
    skin=mat("skin", SKIN, tex=SKIN_TEX),
    skin_hand=mat("skin_hand", (0.72, 0.53, 0.45), tex=SKIN_TEX),   # redder and dirtier: cold, work, the lantern
    skin_neck=mat("skin_neck", (0.67, 0.52, 0.44), tex=SKIN_TEX),   # in the jaw's shade
    face=mat("face", SKIN, image=FACE),
    hair=mat("hair", (0.11, 0.09, 0.08)),
    coat=mat("coat", (0.30, 0.34, 0.23)),
    coat_dark=mat("coat_dark", (0.16, 0.18, 0.12)),
    scarf=mat("scarf", (0.50, 0.13, 0.11)),
    pants=mat("pants", (0.19, 0.21, 0.26)),
    patch=mat("patch", (0.36, 0.33, 0.27)),
    boot=mat("boot", (0.33, 0.21, 0.13)),
    sole=mat("sole", (0.10, 0.08, 0.07)),
    leather=mat("leather", (0.22, 0.13, 0.08)),
    metal=mat("metal", (0.42, 0.40, 0.35)),
    iron=mat("iron", (0.12, 0.12, 0.12)),
    bandage=mat("bandage", (0.80, 0.77, 0.66)),
    blood=mat("blood", (0.32, 0.08, 0.06), grime=False),
    glass=mat("lantern_glass", (1.0, 0.68, 0.30), grime=False, emit=6.0),
    blade=mat("blade", (0.50, 0.49, 0.45)),
    wood=mat("wood", (0.24, 0.15, 0.09)),
)

parts = []


def add(o, m):
    o.data.materials.append(m)
    parts.append(o)
    return o


def lathe(name, m, rings, n=8, loc=(0, 0, 0), rot=(0, 0, 0), caps=True):
    """rings: (z, rx, ry[, yoff[, xoff]]). Vertex 0 points to the front (-Y)."""
    bm = bmesh.new(); rows = []
    for r in rings:
        z, rx, ry = r[:3]; yo = r[3] if len(r) > 3 else 0.0; xo = r[4] if len(r) > 4 else 0.0
        rows.append([bm.verts.new((xo + rx * math.cos(-math.pi / 2 + 2 * math.pi * i / n),
                                   yo + ry * math.sin(-math.pi / 2 + 2 * math.pi * i / n), z))
                     for i in range(n)])
    for a, b in zip(rows, rows[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    if caps:
        bm.faces.new(list(reversed(rows[0]))); bm.faces.new(rows[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); scene.collection.objects.link(o)
    o.location = loc; o.rotation_euler = rot
    return add(o, m)


def box(name, m, loc, size, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name; o.scale = size
    return add(o, m)


def cone(name, m, loc, r1, r2, depth, verts=4, rot=(0, 0, 0), scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name; o.scale = scale
    return add(o, m)


# --- body ---------------------------------------------------------------------
coat = lathe("coat", M["coat"], [
    (0.45, 0.27, 0.20), (0.535, 0.25, 0.185), (0.62, 0.23, 0.17), (0.85, 0.19, 0.14), (1.00, 0.20, 0.14),
    (1.15, 0.215, 0.145), (1.27, 0.22, 0.13), (1.30, 0.18, 0.115), (1.32, 0.12, 0.09)])


def open_front(o, top=0.84, gap=0.006):
    """Overcoat skirt: open hem (no bottom cap) and slit up the front to the waist, so the two front flaps
    can part around a raised knee. The slit edges are nudged apart so skinning can tell left from right."""
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if len(f.verts) > 4 and max(v.co.z for v in f.verts) < 0.46],
                     context="FACES_ONLY")
    front = lambda v: abs(v.co.x) < 1e-4 and v.co.y < 0
    slit = [e for e in bm.edges if all(front(v) for v in e.verts) and min(v.co.z for v in e.verts) < top]
    bmesh.ops.split_edges(bm, edges=slit)
    for v in [v for v in bm.verts if front(v) and v.co.z < top]:
        side = sum(f.calc_center_median().x for f in v.link_faces)
        v.co.x = gap if side > 0 else -gap
    bm.to_mesh(o.data); bm.free()


open_front(coat)
for z in (0.97, 1.07, 1.17):
    box("button", M["iron"], (0, -0.147, z), (0.022, 0.014, 0.022))
for s in (1, -1):  # hip pockets with flaps
    box("pocket", M["coat_dark"], (s * 0.13, -0.143, 0.60), (0.09, 0.012, 0.075), rot=(-0.1, 0, s * 0.298))
    box("pocket_flap", M["coat"], (s * 0.13, -0.15, 0.635), (0.095, 0.014, 0.025), rot=(-0.1, 0, s * 0.298))

lathe("belt", M["leather"], [(0.82, 0.197, 0.147), (0.89, 0.199, 0.148)])
box("buckle", M["metal"], (0, -0.153, 0.855), (0.05, 0.012, 0.05))
lathe("neck", M["skin_neck"], [(1.30, 0.045, 0.045), (1.41, 0.042, 0.042)], n=6)
lathe("scarf", M["scarf"], [(1.29, 0.125, 0.105), (1.345, 0.105, 0.088), (1.395, 0.075, 0.07)])
box("scarf_tail", M["scarf"], (0.075, -0.15, 1.17), (0.07, 0.02, 0.27), rot=(-0.04, 0, -0.06))
box("scarf_tail_end", M["scarf"], (0.084, -0.152, 1.03), (0.06, 0.018, 0.03), rot=(-0.04, 0, 0.12))

# body under the coat: trousers' seat and crotch, so the legs grow out of a pelvis when the skirt parts
lathe("pelvis", M["pants"], [(0.58, 0.15, 0.10), (0.65, 0.165, 0.11), (0.74, 0.165, 0.115), (0.80, 0.15, 0.105)])  # ends under the belt

# legs + boots
for s in (1, -1):
    x = s * 0.10
    # knee: five rings with a slightly fuller cap (front, -y) so the blended weights bend it instead of pinching
    lathe("leg", M["pants"], [(0.28, 0.06, 0.06, 0, x), (0.38, 0.066, 0.068, 0, x), (0.42, 0.07, 0.076, -0.006, x),
                              (0.45, 0.072, 0.078, -0.008, x), (0.48, 0.073, 0.077, -0.004, x),
                              (0.52, 0.076, 0.077, 0, x), (0.62, 0.085, 0.085, 0, x), (0.72, 0.09, 0.09, 0, x)], n=6)
    lathe("sole", M["sole"], [(0.0, 0.074, 0.117, -0.04, x), (0.03, 0.075, 0.118, -0.04, x)], n=6)
    lathe("boot", M["boot"], [(0.03, 0.07, 0.112, -0.04, x), (0.09, 0.068, 0.10, -0.03, x),
                              (0.14, 0.064, 0.07, 0, x), (0.30, 0.07, 0.07, 0, x)], n=6)
    lathe("boot_cuff", M["leather"], [(0.29, 0.078, 0.078, 0, x), (0.35, 0.082, 0.082, 0, x)], n=6)
box("knee_patch", M["patch"], (0.10, -0.085, 0.44), (0.06, 0.012, 0.06), rot=(0, 0, 0.1))  # on the kneecap

# arms (T-pose). Local Z of the lathe runs from the shoulder (bone head, x 0.18) outwards: elbow at 0.30,
# wrist at 0.55. Extra rings at the shoulder cap and around the elbow give the blended weights (see weights())
# room to bend smoothly instead of hinging like separate tubes; hands are tapered mitts coming out of the cuff.
SHOULDER = [(0, 0.085, 0.08), (0.05, 0.088, 0.083), (0.12, 0.078, 0.073), (0.27, 0.067, 0.064)]
for s in (1, -1):
    rot = (0, s * math.pi / 2, 0)
    base = (s * 0.18, 0, 1.25)
    if s == -1:   # right arm: full sleeve
        lathe("sleeve", M["coat"], SHOULDER + [(0.30, 0.065, 0.062), (0.33, 0.064, 0.061), (0.50, 0.062, 0.06),
                                               (0.52, 0.075, 0.07), (0.55, 0.075, 0.07)], n=6, loc=base, rot=rot)
    else:         # left arm: sleeve rolled up, bandaged forearm
        lathe("sleeve", M["coat"], SHOULDER + [(0.30, 0.066, 0.063)], n=6, loc=base, rot=rot)
        lathe("sleeve_roll", M["coat_dark"], [(0.28, 0.076, 0.072), (0.335, 0.076, 0.072)], n=6, loc=base, rot=rot)
        lathe("forearm", M["bandage"], [(0.30, 0.052, 0.05), (0.33, 0.051, 0.049), (0.55, 0.045, 0.043)],
              n=6, loc=base, rot=rot)
        for z in (0.37, 0.44, 0.51):
            lathe("wrap", M["bandage"], [(z, 0.056, 0.054), (z + 0.02, 0.054, 0.052)], n=6, loc=base, rot=rot)
        box("blood_stain", M["blood"], (0.62, -0.01, 1.296), (0.05, 0.035, 0.008))
    # hand: rx = thickness, ry = width; the last rings curl the fingers down (+local x = down for s=1)
    lathe("hand", M["skin_hand"], [(0.52, 0.02, 0.036), (0.56, 0.021, 0.042), (0.62, 0.02, 0.045),
                              (0.66, 0.016, 0.043, 0, s * 0.008), (0.71, 0.01, 0.033, 0, s * 0.024)],
          n=6, loc=base, rot=rot)
    box("thumb", M["skin_hand"], (s * 0.755, -0.05, 1.25), (0.05, 0.025, 0.026), rot=(0, 0, -s * 0.5))

# head: low-poly lathe with a front-projected painted face
head = lathe("head", M["skin"], [
    (1.385, 0.045, 0.04, -0.035), (1.41, 0.085, 0.085, -0.015), (1.46, 0.115, 0.11, 0.0),
    (1.53, 0.13, 0.125, 0.005), (1.60, 0.128, 0.13, 0.015), (1.66, 0.10, 0.11, 0.02),
    (1.70, 0.05, 0.06, 0.02)], n=10)
head.data.materials.append(M["face"])
uv = head.data.uv_layers.new(name="FaceUV")
for p in head.data.polygons:
    if p.normal.y < -0.3 and p.center.z < 1.62:
        p.material_index = 1
    for li in p.loop_indices:
        v = head.data.vertices[head.data.loops[li].vertex_index].co
        uv.data[li].uv = (0.5 + v.x / 0.26, (v.z - 1.385) / 0.3)

hair = lathe("hair", M["hair"], [
    (1.44, 0.09, 0.06, 0.07), (1.50, 0.135, 0.095, 0.045), (1.58, 0.14, 0.142, 0.015),
    (1.64, 0.142, 0.147, 0.02), (1.70, 0.11, 0.12, 0.025), (1.735, 0.05, 0.06, 0.03)], n=10)
# messy fringe; the long lock hides the right eye
# fringe locks laid on the hair's front surface (ring at 1.58: rx .14, ry .142, y offset .015), turned to
# follow it, so the outer ones wrap round the temples instead of hanging in the air beside the face
for x, top, bottom, tilt in ((-0.08, 1.62, 1.555, 0.1), (-0.045, 1.63, 1.505, 0.12),
                             (0.0, 1.63, 1.565, 0.0), (0.045, 1.625, 1.56, -0.1), (0.08, 1.62, 1.565, -0.12)):
    y = 0.015 - 0.142 * math.sqrt(1 - (x / 0.14) ** 2) - 0.004
    yaw = math.atan2(x / 0.14 ** 2, -(y - 0.015) / 0.142 ** 2)
    cone("bang", M["hair"], (x, y, (top + bottom) / 2), 0.0, 0.032, top - bottom,
         rot=(-0.12, tilt, yaw), scale=(1, 0.45, 1))
# cowlicks: crown vertices pulled out and up (ring, column, out, up), so the spikes grow out of the hair mass
for ring, col, out, up in ((4, 3, 0.03, 0.02), (4, 6, 0.025, 0.025), (5, 2, 0.015, 0.025), (5, 7, 0.015, 0.02),
                           (3, 5, 0.025, 0.01)):
    v = hair.data.vertices[ring * 10 + col]
    r = Vector((v.co.x, v.co.y - 0.02, 0)).normalized()
    v.co += r * out + Vector((0, 0, up))

# --- gear: oil lantern on the right hip, satchel on the left ---------------------
LX, LY = -0.225, -0.10  # hung from the belt hook (front-right hip) while the crossbow is out
bpy.ops.mesh.primitive_torus_add(major_segments=6, minor_segments=3, major_radius=0.025, minor_radius=0.006,
                                 location=(LX, LY, 0.80), rotation=(math.pi / 2, 0, 0))
o = bpy.context.active_object; o.name = "lantern_ring"; add(o, M["iron"])
cone("lantern_cap", M["iron"], (LX, LY, 0.772), 0.05, 0.012, 0.035, rot=(0, 0, math.pi / 4))
box("lantern_glass", M["glass"], (LX, LY, 0.71), (0.055, 0.055, 0.085))
for dx in (-1, 1):
    for dy in (-1, 1):
        box("lantern_bar", M["iron"], (LX + dx * 0.03, LY + dy * 0.03, 0.71), (0.01, 0.01, 0.09))
box("lantern_base", M["iron"], (LX, LY, 0.66), (0.072, 0.072, 0.02))
def on_coat(ang, z, rx, ry):
    """Point on the coat's elliptical section at angle `ang` (deg, 0 = his left side, 90 = back) and its
    outward normal, for things that sit flat on the coat."""
    a = math.radians(ang); p = Vector((rx * math.cos(a), ry * math.sin(a), z))
    return p, Vector((p.x / rx ** 2, p.y / ry ** 2, 0)).normalized()


sp, sn = on_coat(130, 0.72, 0.213, 0.164)               # satchel on the back-right hip
srz = math.atan2(sn.y, sn.x)
box("satchel", M["leather"], sp + sn * 0.032, (0.06, 0.15, 0.14), rot=(0, 0, srz))
box("satchel_flap", M["boot"], sp + sn * 0.066 + Vector((0, 0, 0.035)), (0.012, 0.155, 0.08), rot=(0, 0, srz))
bp, bn = on_coat(130, 0.80, 0.198, 0.148)
box("satchel_loop", M["leather"], bp + bn * 0.008, (0.012, 0.035, 0.09), rot=(0, 0, srz))

# --- machete, sheathed on the left hip (pommel up-front, blade down-back). Built in the machete bone's
# local frame (Y = pommel->tip, X = blade thickness, edge towards -Z), then moved by SHEATH. rig.py uses the
# same pommel/tip for the "machete" bone, so keep both in sync.
POMMEL = Vector((0.215, -0.06, 0.93)); TIP = POMMEL + Vector((0.03, 0.13, -0.42)).normalized() * 0.59
_y = (TIP - POMMEL).normalized(); _x = (Vector((1, 0, 0)) - _y * _y.x).normalized()
SHEATH = Matrix((_x, _y, _x.cross(_y))).transposed().to_4x4(); SHEATH.translation = POMMEL


def sheathed(o):
    bpy.context.view_layer.update()
    o.matrix_world = SHEATH @ o.matrix_world
    return o


bm = bmesh.new(); prof = [(0.14, 0.012), (0.52, 0.014), (0.585, -0.012), (0.55, -0.045), (0.42, -0.052), (0.14, -0.032)]
fr = [bm.verts.new((0.004, y, z)) for y, z in prof]; bk = [bm.verts.new((-0.004, y, z)) for y, z in prof]
bm.faces.new(fr); bm.faces.new(list(reversed(bk)))
for i in range(len(prof)):
    j = (i + 1) % len(prof); bm.faces.new((fr[i], bk[i], bk[j], fr[j]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
me = bpy.data.meshes.new("machete_blade"); bm.to_mesh(me); bm.free()
o = bpy.data.objects.new("machete_blade", me); scene.collection.objects.link(o); add(o, M["blade"]); sheathed(o)
sheathed(box("machete_handle", M["wood"], (0, 0.065, -0.008), (0.022, 0.13, 0.03)))
sheathed(box("machete_guard", M["iron"], (0, 0.137, -0.01), (0.028, 0.012, 0.052)))
sheathed(box("machete_pommel", M["iron"], (0, 0.004, -0.008), (0.026, 0.01, 0.034)))
sheathed(box("sheath", M["leather"], (0, 0.36, -0.018), (0.022, 0.46, 0.07)))
mouth = POMMEL + _y * 0.14                               # sheath strap: belt -> sheath mouth, flat on the coat
bp, bn = on_coat(math.degrees(math.atan2(mouth.y / 0.148, mouth.x / 0.198)), 0.865, 0.198, 0.148)
d = mouth + bn * 0.012 - bp; sx = d.normalized(); sy = bn.cross(sx).normalized()
bpy.ops.mesh.primitive_cube_add(size=1)
o = bpy.context.active_object; o.name = "sheath_strap"; add(o, M["leather"])
o.matrix_world = Matrix.Translation(bp + d / 2) @ Matrix((sx, sy, bn)).transposed().to_4x4() \
    @ Matrix.Diagonal((d.length + 0.02, 0.028, 0.008, 1))

box("belt_hook", M["iron"], (-0.205, -0.093, 0.835), (0.012, 0.012, 0.05), rot=(0, 0, 0.45))  # the lantern's hook

# --- hand crossbow, holstered muzzle-down on the right hip over the coat. Built in its own frame like the
# machete: Y = butt -> muzzle, Z = top of the tiller (turned towards the body), X = across the prod; rig.py
# gives it a "crossbow" bone (child of the right side flap, which it rides) with the same butt/muzzle/roll.
XB_BUTT = Vector((-0.24, 0.01, 0.84)); XB_MUZZLE = XB_BUTT + Vector((-0.13, 0.07, -1)).normalized() * 0.30
_xy = (XB_MUZZLE - XB_BUTT).normalized(); _xz = (Vector((1, 0, 0)) - _xy * _xy.x).normalized()
XBOW = Matrix((_xy.cross(_xz), _xy, _xz)).transposed().to_4x4(); XBOW.translation = XB_BUTT


def holstered(o):
    bpy.context.view_layer.update()
    o.matrix_world = XBOW @ o.matrix_world
    return o


holstered(box("xbow_stock", M["wood"], (0, 0.15, 0), (0.03, 0.30, 0.035)))
holstered(box("xbow_groove", M["iron"], (0, 0.16, 0.0185), (0.008, 0.24, 0.004)))      # bolt rail on top
holstered(box("xbow_grip", M["wood"], (0, 0.045, -0.055), (0.026, 0.045, 0.085), rot=(0.35, 0, 0)))
holstered(box("xbow_trigger", M["iron"], (0, 0.085, -0.03), (0.008, 0.012, 0.025)))
for sx in (1, -1):                                                                     # prod: two steel limbs
    holstered(box("xbow_prod", M["iron"], (sx * 0.052, 0.25, 0), (0.108, 0.016, 0.022), rot=(0, 0, -sx * 0.2)))
for sx in (1, -1):  # string in two halves: the tips stay on the prod, the middle (own bone) is drawn back to cock it
    holstered(box("xbow_string", M["bandage"], (sx * 0.05, 0.24, 0), (0.1, 0.004, 0.004)))
# the loaded bolt: hidden inside the stock until a reload lifts it onto the rail (bone "bolt.rail")
holstered(box("railbolt", M["wood"], (0, 0.16, 0), (0.008, 0.26, 0.008)))
holstered(box("railbolt", M["iron"], (0, 0.285, 0), (0.01, 0.012, 0.01)))
for rz in (0, math.pi / 2):
    holstered(box("railbolt", M["scarf"], (0, 0.05, 0), (0.002, 0.03, 0.018), rot=(0, rz, 0)))
holstered(box("xbow_stirrup", M["iron"], (0, 0.315, 0), (0.045, 0.012, 0.03)))         # foot loop to span it
for sx in (1, -1):
    holstered(box("xbow_stirrup", M["iron"], (sx * 0.02, 0.29, 0), (0.006, 0.04, 0.03)))
holstered(box("xbow_holster", M["leather"], (0, 0.06, 0), (0.045, 0.05, 0.05)))        # leather loop round the stock
bp, bn = on_coat(180, 0.855, 0.198, 0.148)                                            # ... hung from the belt
box("xbow_holster", M["leather"], bp + bn * 0.02 + Vector((0, 0.01, -0.01)), (0.035, 0.03, 0.05), rot=(0, 0, math.atan2(bn.y, bn.x)))

# --- quiver of bolts, hung from the belt on the back-left: a leather tube following the coat's flare,
# four bolts with red fletching (the scarf's red) sticking out of the mouth
qa, qn = on_coat(65, 0.84, 0.19, 0.14); qb, qbn = on_coat(65, 0.58, 0.235, 0.175)
Q0 = qb + qbn * 0.05; QL = ((qa + qn * 0.05) - Q0).length
QUIVER = Matrix.LocRotScale(Q0, ((qa + qn * 0.05) - Q0).normalized().to_track_quat("Z", "Y"), None)


def in_quiver(o):
    bpy.context.view_layer.update()
    o.matrix_world = QUIVER @ o.matrix_world
    return o


in_quiver(lathe("quiver", M["leather"], [(0, 0.03, 0.034), (QL * 0.5, 0.036, 0.04), (QL, 0.038, 0.042)], n=6))
in_quiver(lathe("quiver_band", M["boot"], [(QL - 0.035, 0.041, 0.045), (QL - 0.012, 0.041, 0.045)], n=6))
for dx, dy, h in ((-0.012, -0.01, 0.07), (0.012, -0.008, 0.055), (-0.004, 0.014, 0.065), (0.014, 0.012, 0.05)):
    in_quiver(box("bolt", M["wood"], (dx, dy, QL + h - 0.13), (0.008, 0.008, 0.26)))
    for rz in (0, math.pi / 2):
        in_quiver(box("fletch", M["scarf"], (dx, dy, QL + h - 0.025), (0.002, 0.022, 0.04), rot=(0, 0, rz)))
# the bolt he draws: hidden inside the quiver, nock just under the mouth (bone "bolt.hand", grabbed by the left hand)
in_quiver(box("handbolt", M["wood"], (0, 0, QL - 0.135), (0.008, 0.008, 0.26)))
for rz in (0, math.pi / 2):
    in_quiver(box("handbolt", M["scarf"], (0, 0, QL - 0.025), (0.002, 0.018, 0.03), rot=(0, 0, rz)))
box("quiver_strap", M["leather"], qa + qn * 0.012 + Vector((0, 0, -0.01)), (0.012, 0.03, 0.08), rot=(0, 0, math.atan2(qn.y, qn.x)))

# --- rigid N64-style skin weights, decided per part (bone names: .L = +X) ----------------
ON_COAT = {"coat", "button", "pocket", "pocket_flap", "belt", "buckle", "satchel", "satchel_flap", "satchel_loop",
           "belt_hook"}


def skirt_weights(x, y, z):
    """Skirt below the waist: front / side / back flap of each side (chains skirt.F|S|B.1|2.L|R, built in
    rig.py), blending from the hips at the waist (0.85) to bone 1 at 0.62 and bone 2 at the hem (0.45).
    The back seam is shared by both back flaps."""
    sides = [".L", ".R"] if abs(x) < 0.003 else [".L" if x > 0 else ".R"]
    a = math.degrees(math.atan2(y * 1.35, abs(x)))  # ~ the lathe column: -90 front, 0 side, +90 back
    panel = "F" if a < -22.5 else "S" if a < 22.5 else "B"
    out = {}
    for sd in sides:
        if z >= 0.62:
            w = min(1.0, (0.85 - z) / 0.23); pair = {"hips": 1 - w, "skirt.%s.1%s" % (panel, sd): w}
        else:
            w = min(1.0, (0.62 - z) / 0.17); pair = {"skirt.%s.1%s" % (panel, sd): 1 - w, "skirt.%s.2%s" % (panel, sd): w}
        for k, v in pair.items():
            if v > 0:
                out[k] = out.get(k, 0) + v / len(sides)
    return out


def weights(part, x, y, z):
    s = ".L" if x > 0 else ".R"
    if part in ("head", "hair", "bang"):
        return {"head": 1}
    if part == "neck":
        return {"neck": 1}
    if part == "scarf":
        return {"neck": 0.5, "chest": 0.5} if z > 1.37 else {"chest": 1}
    if part.startswith("scarf_tail"):
        return {"chest": 1}
    if part in ON_COAT:  # the coat, and whatever sits on it, moves exactly like the coat there
        if z < 0.84:
            return skirt_weights(x, y, z)  # skirt: flap bones
        if part == "coat" and z > 1.1 and abs(x) > 0.17:
            return {"chest": 0.7, "upper_arm" + s: 0.3}  # armpit/shoulder side follows the arm a little
        return {"chest": 1} if z >= 1.0 else {"spine": 1} if z >= 0.85 else {"hips": 1}
    if part == "sheath":  # rides the left side flap with the sheathed machete (rig.py parents it there too)
        return {"skirt.S.1.L": 1}
    if part == "xbow_string":  # middle of the string on its own bone (cocking), tips on the crossbow
        return {"xbow.string": 1} if abs((XBOW.inverted() @ Vector((x, y, z))).x) < 0.02 else {"crossbow": 1}
    if part == "railbolt":
        return {"bolt.rail": 1}
    if part == "handbolt":
        return {"bolt.hand": 1}
    if part.startswith("xbow_"):  # the holster loop on the belt half rides the flap the crossbow hangs on
        return {"hips": 0.5, "skirt.S.1.R": 0.5} if part == "xbow_holster" and z > 0.83 else {"crossbow": 1}
    if part in ("quiver", "quiver_band", "bolt", "fletch", "quiver_strap"):  # rigid: belt + a little back flap
        return {"hips": 0.6, "skirt.B.1.L": 0.4}
    if part == "sheath_strap":
        return {"hips": 1} if z >= 0.85 else {"hips": 0.5, "skirt.S.1.L": 0.5}
    if part.startswith("lantern"):
        return {"lantern": 1}
    if part.startswith("machete"):
        return {"machete": 1}
    if part in ("sleeve", "sleeve_roll", "forearm", "wrap", "blood_stain"):
        t = abs(x)
        if t < 0.23:  # shoulder: the inner ring stays half on the chest, so the joint rounds instead of hinging
            w = min(1.0, max(0.0, (t - 0.13) / 0.10)); return {"chest": 1 - w, "upper_arm" + s: w}
        if t < 0.43:
            return {"upper_arm" + s: 1}
        if t < 0.53:  # elbow: three rings blend upper arm -> forearm
            w = (t - 0.43) / 0.10; return {"upper_arm" + s: 1 - w, "forearm" + s: w}
        return {"forearm" + s: 1}
    if part in ("hand", "thumb"):  # wrist ring half on the forearm
        return {"forearm" + s: 0.5, "hand" + s: 0.5} if abs(x) < 0.715 else {"hand" + s: 1}
    if part in ("leg", "knee_patch"):  # knee (bone joint at 0.45): thigh -> shin over 0.38..0.52
        if z > 0.64:  # thigh root, inside the pelvis: half on the hips at the top ring
            h = min(0.5, (z - 0.64) / 0.08 * 0.5); return {"thigh" + s: 1 - h, "hips": h}
        w = min(1.0, max(0.0, (z - 0.38) / 0.14))
        return {k: v for k, v in (("thigh" + s, w), ("shin" + s, 1 - w)) if v > 0}
    if part == "pelvis":  # seat and crotch: hips, the lower sides pulled along by the thighs
        if z >= 0.72 or abs(x) <= 0.05:
            return {"hips": 1}
        t = min(0.5, (0.72 - z) / 0.14 * 0.5); return {"hips": 1 - t, "thigh" + s: t}
    if part in ("boot", "boot_cuff"):
        return {"shin" + s: 1} if z > 0.12 else {"foot" + s: 1}
    if part == "sole":
        return {"foot" + s: 1}
    raise KeyError(part)


bpy.context.view_layer.update()
for o in parts:
    part = o.name.split(".")[0]
    for v in o.data.vertices:
        for bone, w in weights(part, *(o.matrix_world @ v.co)).items():
            vg = o.vertex_groups.get(bone) or o.vertex_groups.new(name=bone)
            vg.add([v.index], w, "REPLACE")

# --- join into one game-ready mesh -------------------------------------------------
with bpy.context.temp_override(active_object=coat, object=coat, selected_objects=parts,
                               selected_editable_objects=parts):
    bpy.ops.object.join()
coat.name = coat.data.name = "Protagonista"
for p in coat.data.polygons:
    p.use_smooth = False

# Grime UVs: box projection (3 repeats per metre) baked into a real UV map, so engines see the same
# texture as Blender (glTF cannot carry box projection). Junk primitive UV maps are dropped.
me = coat.data
for layer in [l for l in me.uv_layers if l.name != "FaceUV"]:
    me.uv_layers.remove(layer)
grime_uv = me.uv_layers.new(name="GrimeUV")
for p in me.polygons:
    n = [abs(c) for c in p.normal]
    a, b = (1, 2) if n[0] >= max(n[1], n[2]) else (0, 2) if n[1] >= n[2] else (0, 1)
    for li in p.loop_indices:
        co = me.vertices[me.loops[li].vertex_index].co
        grime_uv.data[li].uv = (co[a] * 3, co[b] * 3)

light = bpy.data.lights.new("lantern_light", "POINT")
light.color = (1.0, 0.62, 0.28); light.energy = 25; light.shadow_soft_size = 0.02
light.use_shadow = False  # N64-style: dynamic lights never cast shadows (and the fist would block the face)
lo = bpy.data.objects.new("lantern_light", light); scene.collection.objects.link(lo)
lo.location = (LX, LY - 0.06, 0.71); lo.parent = coat

tris = sum(len(p.vertices) - 2 for p in coat.data.polygons)
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("personagens", "protagonista"))
result = {"tris": tris, "verts": len(coat.data.vertices), "materials": len(coat.data.materials)}

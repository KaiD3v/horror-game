# Shared kit for the village and its interiors (vilarejo_build.py, armaria_build.py, ...): the textured materials,
# the mesh builder (B, bx, frustum, obj: per-face planar UVs at world scale) and the prop pieces (k_*), each built
# at the origin with its front towards local -Y. Import after clearing the scene: `from vila_kit import *`.
import bpy, bmesh, math, os, random
from mathutils import Vector, Matrix, Euler

import paths
TEX = paths.TEXTURES
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))

# --- materials: texture, tile size in metres (None = fit the face), UV projection, tint -------------------
MATS = {}


def mat(name, tex, tile, mode="plane", tint=None, cutout=False, soft=False):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; bsdf = nt.nodes["Principled BSDF"]
    ti = nt.nodes.new("ShaderNodeTexImage"); ti.interpolation = "Closest"
    ti.image = bpy.data.images.load(os.path.join(TEX, tex + ".png"), check_existing=True)
    out = ti.outputs["Color"]
    if tint:  # glTF base colour factor: Mix (multiply), factor 1, colour in B
        mx = nt.nodes.new("ShaderNodeMix"); mx.data_type = "RGBA"; mx.blend_type = "MULTIPLY"
        mx.inputs[0].default_value = 1.0; mx.inputs[7].default_value = (*tint, 1.0)
        nt.links.new(out, mx.inputs[6]); out = mx.outputs[2]
    nt.links.new(out, bsdf.inputs["Base Color"])
    if cutout:  # texture alpha rounded to 0/1 -> glTF alphaMode MASK (alpha scissor in Godot)
        rnd = nt.nodes.new("ShaderNodeMath"); rnd.operation = "ROUND"
        nt.links.new(ti.outputs["Alpha"], rnd.inputs[0]); nt.links.new(rnd.outputs[0], bsdf.inputs["Alpha"])
    if soft:  # texture alpha as is -> glTF alphaMode BLEND (weathering decals fade into the wall)
        nt.links.new(ti.outputs["Alpha"], bsdf.inputs["Alpha"]); m.surface_render_method = "BLENDED"
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.1
    MATS[name] = (m, tile, mode)


mat("grass", "grass", 2.0, "top"); mat("mud", "mud", 2.0, "top"); mat("rock", "rock", 2.0)
mat("whitewash", "whitewash", 2.0); mat("stone", "stone", 1.0); mat("planks", "planks", 1.0)
mat("roof", "roof_tiles", 0.8); mat("bark", "bark", 1.0); mat("door", "door", None); mat("window", "window", None); mat("window_in", "window_in", None)
mat("iron", "machine", 1.0, tint=(0.55, 0.5, 0.45)); mat("pit", "mud", 2.0, "top", tint=(0.15, 0.13, 0.12))
mat("fence", "siding", 1.0, tint=(0.85, 0.85, 0.85))
BARRA = {"blue": (0.38, 0.5, 0.72), "ochre": (0.8, 0.6, 0.3), "green": (0.45, 0.6, 0.45), "oxblood": (0.62, 0.32, 0.28)}
for k, c in BARRA.items():
    mat("barra_" + k, "whitewash", 2.0, tint=c)
    mat("shutter_" + k, "shutter", None, tint=c)
SIDING = {"grey": (1.0, 1.0, 1.0), "brown": (0.85, 0.68, 0.52), "red": (0.85, 0.5, 0.42)}
for k, c in SIDING.items():
    mat("siding_" + k, "siding", 1.0, tint=c)
# props (the kit below)
mat("barrel", "siding", 1.0, tint=(0.8, 0.62, 0.48)); mat("burlap", "burlap", 1.0); mat("hay", "hay", 1.0)
CLOTH = {"white": (1.0, 1.0, 1.0), "blue": (0.6, 0.7, 0.88), "red": (0.88, 0.55, 0.5), "grey": (0.62, 0.6, 0.56)}
mat("cloth_dark", "cloth", 1.0, tint=(0.40, 0.36, 0.30))  # the scarecrow's rotten coat
for k, c in CLOTH.items():
    mat("cloth_" + k, "cloth", 1.0, tint=c)
mat("jar", "cloth", 1.0, tint=(0.45, 0.6, 0.48)); mat("can", "machine", 1.0, tint=(0.75, 0.32, 0.22))
mat("blade", "machine", 1.0, tint=(0.62, 0.62, 0.6))
for k in ("vila", "colonia", "cemiterio", "venda", "armaria"):
    mat("sign_" + k, "sign_" + k, None)


# --- mesh builder ---------------------------------------------------------------------------------------
class B:
    def __init__(s):
        s.v, s.f, s.m = [], [], []

    def poly(s, pts, m):
        i = len(s.v); s.v.extend(Vector(p) for p in pts); s.f.append(list(range(i, i + len(pts)))); s.m.append(m)

    def box(s, M, m):  # unit cube transformed by M
        c = [M @ Vector((x, y, z)) for x in (-.5, .5) for y in (-.5, .5) for z in (-.5, .5)]
        for q in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
            s.poly([c[i] for i in q], m)


def bx(b, c, size, m, rot=(0, 0, 0)):
    b.box(Matrix.LocRotScale(Vector(c), Euler(rot), Vector(size)), m)


def frustum(b, p0, p1, r0, r1, n, m, caps=False):
    ax = (Vector(p1) - Vector(p0)).normalized(); a = ax.orthogonal().normalized(); c = ax.cross(a)
    ring = lambda p, r: [Vector(p) + (a * math.cos(2 * math.pi * k / n) + c * math.sin(2 * math.pi * k / n)) * r for k in range(n)]
    lo = ring(p0, r0)
    if r1 <= 0.001:
        for k in range(n):
            b.poly([lo[k], lo[(k + 1) % n], p1], m)
    else:
        hi = ring(p1, r1)
        for k in range(n):
            b.poly([lo[k], lo[(k + 1) % n], hi[(k + 1) % n], hi[k]], m)
        if caps:
            b.poly(hi, m)
    if caps:
        b.poly(lo[::-1], m)


def obj(b, name, loc=(0, 0, 0), yaw=0.0):
    me = bpy.data.meshes.new(name); me.from_pydata([tuple(v) for v in b.v], [], b.f); me.update()
    names = sorted(set(b.m))
    for n in names:
        me.materials.append(MATS[n][0])
    uv = me.uv_layers.new(name="UV")
    for p, mn in zip(me.polygons, b.m):
        p.material_index = names.index(mn)
        _, tile, mode = MATS[mn]
        n = p.normal
        if mode == "top":
            ua, va = X, Y
        elif mode == "edge":  # along the face's first edge (decals that turn, strips that follow a path)
            c0 = me.vertices[me.loops[p.loop_indices[0]].vertex_index].co; c1 = me.vertices[me.loops[p.loop_indices[1]].vertex_index].co
            ua = (c1 - c0).normalized(); va = n.cross(ua)
        else:  # planar on the face: u horizontal, v up the face (siding boards stand up, roof rows run level)
            ua = Z.cross(n)
            ua = X.copy() if ua.length < 1e-4 else ua.normalized()
            va = n.cross(ua)
        co = [me.vertices[me.loops[li].vertex_index].co for li in p.loop_indices]
        uvs = [(c.dot(ua), c.dot(va)) for c in co]
        if tile is None:  # fit the face (doors, windows)
            u0, u1 = min(u for u, _ in uvs), max(u for u, _ in uvs); v0, v1 = min(v for _, v in uvs), max(v for _, v in uvs)
            uvs = [((u - u0) / (u1 - u0 or 1), (v - v0) / (v1 - v0 or 1)) for u, v in uvs]
        else:
            uvs = [(u / tile, v / tile) for u, v in uvs]
        for li, t in zip(p.loop_indices, uvs):
            uv.data[li].uv = t
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    o.location = loc; o.rotation_euler.z = yaw
    return o


def k_barril():  # bulging staves, two iron hoops, lid
    b = B()
    frustum(b, (0, 0, -0.05), (0, 0, 0.42), 0.27, 0.31, 8, "barrel", caps=True)
    frustum(b, (0, 0, 0.42), (0, 0, 0.85), 0.31, 0.27, 8, "barrel", caps=True)
    for z, r in ((0.12, 0.29), (0.68, 0.29)):
        frustum(b, (0, 0, z), (0, 0, z + 0.05), r + 0.015, r + 0.015, 8, "iron")
    return b


def k_caixote():  # crate with darker corner battens
    b = B(); bx(b, (0, 0, 0.3), (0.6, 0.6, 0.6), "planks")
    for sx in (-1, 1):
        for sy in (-1, 1):
            bx(b, (sx * 0.29, sy * 0.29, 0.3), (0.06, 0.06, 0.62), "fence")
    return b


def k_lenha():  # firewood stacked between two stakes, against a wall
    b = B(); rng = random.Random("lenha")
    for row in range(4):
        for i in range(10 - row):
            x = -0.72 + 0.08 * row + i * 0.16 + rng.uniform(-0.02, 0.02); r = rng.uniform(0.065, 0.085)
            L = rng.uniform(0.45, 0.55); z = 0.08 + row * 0.15
            frustum(b, (x, -L / 2, z), (x, L / 2, z), r, r, 5, "bark", caps=True)
    for sx in (-1, 1):
        bx(b, (sx * 0.86, 0, 0.35), (0.07, 0.07, 0.9), "planks")
    return b


def wheel(b, c, r, axis=X):
    c = Vector(c); frustum(b, c - axis * 0.05, c + axis * 0.05, r, r, 12, "planks", caps=True)
    frustum(b, c - axis * 0.11, c + axis * 0.11, 0.11, 0.11, 6, "iron", caps=True)  # hub


def k_carroca(broken=False):  # ox cart: plank bed with sides, axle, two wheels, shafts down on the ground
    b = B()
    bx(b, (0, 0.2, 0.78), (1.3, 2.4, 0.08), "planks")
    for sx in (-1, 1):
        if not (broken and sx < 0):  # the broken one lost its left wheel and side board
            bx(b, (sx * 0.62, 0.2, 0.98), (0.05, 2.4, 0.34), "planks")
            wheel(b, (sx * 0.85, 0.3, 0.62), 0.62)
        frustum(b, (sx * 0.35, -0.95, 0.76), (sx * 0.18, -3.2, 0.05), 0.05, 0.045, 4, "planks", caps=True)  # shafts
    bx(b, (0, 1.38, 0.98), (1.3, 0.05, 0.34), "planks"); bx(b, (0, -0.98, 0.98), (1.3, 0.05, 0.34), "planks")
    bx(b, (0, 0.3, 0.62), (1.7, 0.12, 0.12), "planks")  # axle
    if not broken:  # a sack left in the back
        bx(b, (0.25, 0.8, 0.95), (0.45, 0.6, 0.3), "burlap", rot=(0, 0, 0.3))
    return b


def k_roda():  # a wheel off the broken cart, lying flat
    b = B(); wheel(b, (0, 0, 0.06), 0.62, axis=Z); return b


def k_varal(seed):  # clothesline: two T posts, a wire, sheets and clothes left out for years
    b = B(); rng = random.Random(seed)
    for sx in (-2, 2):
        bx(b, (sx, 0, 0.75), (0.09, 0.09, 2.2), "planks"); bx(b, (sx, 0, 1.82), (0.08, 0.5, 0.06), "planks")
    bx(b, (0, 0, 1.8), (4.0, 0.015, 0.015), "iron")
    x = -1.7
    while x < 1.4:
        wd = rng.uniform(0.35, 0.9); L = rng.uniform(0.45, 1.1)
        bx(b, (x + wd / 2, 0, 1.79 - L / 2), (wd, 0.012, L), "cloth_" + rng.choice(list(CLOTH)),
           rot=(rng.uniform(-0.15, 0.15), 0, rng.uniform(-0.06, 0.06)))
        x += wd + rng.uniform(0.15, 0.45)
    return b


def k_espantalho():  # scarecrow: pole, old coat, drooping sleeves, sack head with stitched eyes, straw hat
    b = B()
    bx(b, (0, 0, 0.9), (0.1, 0.1, 2.6), "planks"); bx(b, (0, 0, 1.62), (1.5, 0.08, 0.08), "planks")
    bx(b, (0, 0, 1.25), (0.55, 0.28, 0.75), "cloth_dark", rot=(0, 0.04, 0))
    for sx in (-1, 1):
        bx(b, (sx * 0.5, 0, 1.52), (0.48, 0.2, 0.22), "cloth_dark", rot=(0, sx * 0.25, 0))
        bx(b, (sx * 0.15, 0.02, 0.72), (0.2, 0.2, 0.4), "cloth_dark", rot=(0.1, sx * 0.12, 0))  # torn coat tails
    frustum(b, (0, 0, 1.7), (0.08, 0, 2.12), 0.18, 0.12, 6, "burlap", caps=True)  # head, lolling
    for sx in (-1, 1):
        bx(b, (0.05 + sx * 0.07, -0.15, 1.95), (0.05, 0.03, 0.05), "pit", rot=(0, 0.6 * sx, 0))  # stitched eyes
    frustum(b, (0.07, 0, 2.08), (0.08, 0, 2.11), 0.34, 0.34, 10, "hay", caps=True)  # hat brim
    frustum(b, (0.08, 0, 2.11), (0.1, 0, 2.3), 0.16, 0.12, 8, "hay", caps=True)
    return b


def k_banco():  # square bench
    b = B(); bx(b, (0, 0, 0.45), (1.8, 0.4, 0.06), "planks"); bx(b, (0, 0.2, 0.78), (1.8, 0.04, 0.24), "planks")
    for sx in (-1, 1):
        for sy in (-1, 1):
            bx(b, (sx * 0.75, sy * 0.15, 0.2), (0.07, 0.07, 0.5), "planks")
        bx(b, (sx * 0.75, 0.2, 0.62), (0.07, 0.05, 0.4), "planks")
    return b


def k_cocho():  # stone water trough, dark water
    b = B(); bx(b, (0, 0, 0.05), (2.0, 0.7, 0.3), "stone")
    for sy in (-1, 1):
        bx(b, (0, sy * 0.3, 0.32), (2.0, 0.1, 0.55), "stone")
    for sx in (-1, 1):
        bx(b, (sx * 0.95, 0, 0.32), (0.1, 0.7, 0.55), "stone")
    b.poly([(-0.9, -0.25, 0.45), (0.9, -0.25, 0.45), (0.9, 0.25, 0.45), (-0.9, 0.25, 0.45)], "pit")
    return b


def k_cruzeiro():  # the big wooden cross in front of the chapel, a cloth over its arms
    b = B(); bx(b, (0, 0, 0.05), (1.9, 1.9, 0.5), "stone"); bx(b, (0, 0, 0.45), (1.1, 1.1, 0.4), "stone")
    bx(b, (0, 0, 2.9), (0.22, 0.22, 4.6), "planks"); bx(b, (0, 0, 4.0), (2.0, 0.2, 0.2), "planks")
    bx(b, (0, -0.12, 3.6), (0.95, 0.02, 0.85), "cloth_white", rot=(0.05, 0, 0))
    for sx in (-1, 1):
        bx(b, (sx * 0.62, -0.02, 3.55), (0.35, 0.18, 0.9), "cloth_white", rot=(0, sx * 0.08, 0))
    return b


def k_placa():  # signpost: COLÔNIA > (faces east, points north), < CEMITÉRIO (faces south, points west)
    b = B(); bx(b, (0, 0, 0.9), (0.1, 0.1, 2.4), "planks")
    for z, yaw, s, sh in ((1.9, 90, "colonia", 0.0), (1.55, 0, "cemiterio", 0.15)):
        a = math.radians(yaw); u = Vector((math.cos(a), math.sin(a), 0)); n = Vector((math.sin(a), -math.cos(a), 0))
        c = u * 0.5 * (1 if s == "colonia" else -1) + Z * z
        tl = Matrix.Rotation(sh, 3, n)  # the cemetery board hangs crooked
        bx(b, c, (0.9, 0.04, 0.22), "fence", rot=(tl @ Matrix.Rotation(a, 3, Z)).to_euler())
        b.poly([c + tl @ (u * du + Z * dz + n * 0.025) for du, dz in ((-0.43, -0.1), (0.43, -0.1), (0.43, 0.1), (-0.43, 0.1))],
               "sign_" + s)
    return b


def k_placa_vila():  # the welcome board at the village's entrance, facing the road from the south
    b = B()
    for sx in (-1, 1):
        bx(b, (sx * 1.15, 0, 1.0), (0.12, 0.12, 2.6), "planks")
    bx(b, (0, 0, 2.0), (2.5, 0.06, 0.62), "fence", rot=(0, 0.04, 0))
    tl = Matrix.Rotation(0.04, 3, Y)
    b.poly([Vector((0, 0, 2.0)) + tl @ Vector((x, -0.035, z)) for x, z in ((-1.2, -0.3), (1.2, -0.3), (1.2, 0.3), (-1.2, 0.3))],
           "sign_vila")
    return b


def k_carrinho():  # wheelbarrow
    b = B(); frustum(b, (0, -0.1, 0.32), (0, 0.5, 0.42), 0.26, 0.3, 4, "iron", caps=True)
    wheel(b, (0, -0.42, 0.2), 0.2)
    for sx in (-1, 1):
        bx(b, (sx * 0.22, 0.45, 0.4), (0.05, 1.0, 0.05), "planks", rot=(-0.15, 0, 0))
        bx(b, (sx * 0.2, 0.6, 0.17), (0.05, 0.05, 0.34), "planks")
    return b


def k_feno():  # haystack round a pole
    b = B(); frustum(b, (0, 0, -0.2), (0, 0, 1.0), 1.25, 1.45, 10, "hay")
    frustum(b, (0, 0, 1.0), (0, 0, 2.9), 1.45, 0, 10, "hay")
    frustum(b, (0, 0, 2.5), (0, 0, 3.4), 0.05, 0.04, 4, "planks", caps=True)
    return b


def k_banca_vendeiro():  # Seu Bento's counter out in front of the shop: jars, oil cans, sacks, candles
    b = B(); rng = random.Random("banca_v")
    bx(b, (0, 0, 0.87), (2.0, 0.7, 0.06), "planks")
    bx(b, (0, -0.33, 0.45), (2.0, 0.04, 0.8), "planks")          # counter front, towards the customers
    for sx in (-1, 1):
        bx(b, (sx * 0.97, 0, 0.45), (0.06, 0.7, 0.8), "planks")
    for i in range(4):
        x = -0.8 + i * 0.13
        frustum(b, (x, -0.1, 0.9), (x, -0.1, 1.04), 0.055, 0.05, 6, "jar", caps=True)
        frustum(b, (x, -0.1, 1.04), (x, -0.1, 1.07), 0.04, 0.04, 6, "iron", caps=True)  # lids
    for x in (-0.2, -0.05):
        bx(b, (x, 0.05, 1.0), (0.12, 0.12, 0.2), "can")
    for x, y in ((0.35, 0.0), (0.62, 0.08)):
        bx(b, (x, y, 0.99), (0.26, 0.22, 0.18), "burlap", rot=(0, 0, rng.uniform(-0.4, 0.4)))
    for i in range(5):
        bx(b, (0.82, -0.18 + 0.03 * i, 0.92), (0.2, 0.025, 0.025), "cloth_white", rot=(0, 0, 0.1 * i))
    return b


def k_banca_armas():  # Tenório's trestle table: machetes, a knife, an axe, a box of shells, a bundle of bolts
    b = B()
    bx(b, (0, 0, 0.78), (1.6, 0.62, 0.05), "planks")
    bx(b, (0, -0.05, 0.81), (1.5, 0.55, 0.01), "burlap")         # a sack spread for the blades
    for sx in (-1, 1):  # trestles
        for sy in (-1, 1):
            bx(b, (sx * 0.65, sy * 0.18, 0.39), (0.06, 0.06, 0.82), "planks", rot=(sy * 0.25, 0, 0))
    for i, x in enumerate((-0.55, -0.25)):  # machetes
        bx(b, (x, -0.05 + 0.08 * i, 0.825), (0.06, 0.42, 0.01), "blade", rot=(0, 0, 0.15 - 0.3 * i))
        bx(b, (x + 0.04 * (1 - 2 * i), -0.32 + 0.08 * i, 0.83), (0.035, 0.13, 0.025), "planks", rot=(0, 0, 0.15 - 0.3 * i))
    bx(b, (0.05, -0.1, 0.825), (0.03, 0.2, 0.01), "blade"); bx(b, (0.05, -0.25, 0.83), (0.03, 0.1, 0.02), "planks")  # knife
    bx(b, (0.35, 0.0, 0.83), (0.04, 0.55, 0.035), "planks", rot=(0, 0, 0.4))                                         # axe
    bx(b, (0.24, 0.24, 0.835), (0.14, 0.05, 0.11), "blade", rot=(0, 0, 0.4))
    bx(b, (0.62, -0.1, 0.87), (0.16, 0.12, 0.1), "can")                                                              # shells
    for i in range(5):  # crossbow bolts, red fletching
        y = 0.05 + 0.02 * i
        bx(b, (0.55, y, 0.82), (0.26, 0.008, 0.008), "planks", rot=(0, 0, 0.05 * i))
        bx(b, (0.68, y, 0.825), (0.04, 0.004, 0.02), "cloth_red", rot=(0, 0, 0.05 * i))
    return b


# --- interiors (their own scenes, Zelda style): a room seen from inside, the way out in its front wall (-Y) -------
mat("forro", "ceiling", 1.0); mat("lampglass", "cloth", 1.0, tint=(1.0, 0.85, 0.55))
mat("ember", "mud", 1.0, "top", tint=(2.0, 0.7, 0.25))


def merge(dst, src, x, y, z=0.0, yaw=0.0, s=1.0):
    """Copy a kit piece (built at the origin) into dst at x, y, z turned by yaw degrees, scaled by s."""
    M = Matrix.LocRotScale(Vector((x, y, z)), Euler((0, 0, math.radians(yaw))), Vector((s, s, s)))
    i = len(dst.v)
    dst.v.extend(M @ v for v in src.v); dst.f.extend([k + i for k in f] for f in src.f); dst.m.extend(src.m)


class Room:
    """wx, wy: half width (x) and half depth (y), ht: height, t: wall thickness; the floor is at z = 0."""

    def __init__(s, wx, wy, ht, t=0.15):
        s.wx, s.wy, s.ht, s.t = wx, wy, ht, t

    def side(s, side, e=0.0):  # a point on the inside face of a wall, its horizontal axis u, its normal into the room
        return {"front": (Vector((0, -s.wy + e, 0)), -X, Y), "back": (Vector((0, s.wy - e, 0)), X, -Y),
                "left": (Vector((-s.wx + e, 0, 0)), Y, X), "right": (Vector((s.wx - e, 0, 0)), -Y, -X)}[side]

    def quad(s, b, side, u0, u1, z0, z1, m, e=0.01):
        """A quad on the inside of a wall, facing into the room (front: u runs along -x)."""
        o, u, n = s.side(side, e)
        b.poly([o + u * a + Z * c for a, c in ((u0, z0), (u1, z0), (u1, z1), (u0, z1))], m)
        return o, u, n

    def window(s, b, side, u, z0=1.0, h=1.1):
        o, uu, n = s.quad(b, side, u - 0.45, u + 0.45, z0, z0 + h, "window_in")
        bx(b, o + uu * u + n * 0.07 + Z * (z0 - 0.04), (0.16, 1.0, 0.06) if abs(uu.y) > 0.5 else (1.0, 0.16, 0.06), "planks")

    def shell(s, b, wall, door_w=1.0, leaves=1, windows=(), back_doors=(), floor="planks"):
        """Floor, walls, the way out (door_w wide, centred in the front wall, recessed), shut doors in the back wall
        (their x), windows ((side, u), ...), skirting boards."""
        wx, wy, ht, t = s.wx, s.wy, s.ht, s.t
        bx(b, (0, 0, -0.05), (2 * wx + 2 * t, 2 * wy + 2 * t, 0.1), floor)
        for sx in (-1, 1):
            bx(b, (sx * (wx + t / 2), 0, ht / 2), (t, 2 * wy + 2 * t, ht), wall)
        bx(b, (0, wy + t / 2, ht / 2), (2 * wx, t, ht), wall)
        h = door_w / 2 + 0.05
        for x0, x1 in ((-wx, -h), (h, wx)):
            bx(b, ((x0 + x1) / 2, -wy - t / 2, ht / 2), (x1 - x0, t, ht), wall)
        dh = 2.1 if leaves == 1 else 2.3
        bx(b, (0, -wy - t / 2, (dh + 0.05 + ht) / 2), (2 * h, t, ht - dh - 0.05), wall)
        lw = door_w / leaves
        for k in range(leaves):
            u0 = -door_w / 2 + k * lw
            s.quad(b, "front", u0, u0 + lw, 0, dh, "door", e=-0.06)
        for x in back_doors:
            s.quad(b, "back", x - 0.45, x + 0.45, 0, 2.05, "door")
        for w in windows:  # (side, u[, z0, height])
            s.window(b, *w)
        for side in ("front", "back", "left", "right"):  # skirting
            o, u, n = s.side(side)
            L = 2 * (wx if abs(u.x) > 0.5 else wy)
            bx(b, o + n * 0.02 + Z * 0.06, (L, 0.04, 0.12) if abs(u.x) > 0.5 else (0.04, L, 0.12), "planks")

    def dado(s, b, m, h=0.9, door_w=1.6):
        """A painted band along the foot of the walls (under the windows), broken by the way out."""
        for side in ("front", "back", "left", "right"):
            o, u, n = s.side(side, 0.012)
            L = 2 * (s.wx if abs(u.x) > 0.5 else s.wy)
            for a0, a1 in (((-L / 2, -door_w / 2 - 0.05), (door_w / 2 + 0.05, L / 2)) if side == "front" else ((-L / 2, L / 2),)):
                c = o + u * ((a0 + a1) / 2) + Z * (0.05 + h / 2)
                bx(b, c, (a1 - a0, 0.02, h) if abs(u.x) > 0.5 else (0.02, a1 - a0, h), m)

    def ceiling(s, b, beams=(-2.0, 0.0, 2.0), hole=None):
        """Board ceiling on beams; hole = (x0, x1, y0, y1) leaves an opening (a stair going up into the dark)."""
        W, D, z = s.wx + s.t, s.wy + s.t, s.ht + 0.04
        if hole is None:
            bx(b, (0, 0, z), (2 * W, 2 * D, 0.08), "forro")
        else:
            x0, x1, y0, y1 = hole
            for a, c, e, f in ((-W, x0, -D, D), (x1, W, -D, D), (x0, x1, -D, y0), (x0, x1, y1, D)):
                if c - a > 0.01 and f - e > 0.01:
                    bx(b, ((a + c) / 2, (e + f) / 2, z), (c - a, f - e, 0.08), "forro")
        for y in beams:
            bx(b, (0, y, s.ht - 0.1), (2 * s.wx, 0.18, 0.2), "planks")


# --- vegetation: dry grass and ferns (cut-out cards), dry bushes, dead/dying araucarias, stumps, fallen logs -----------
mat("capim", "capim_alto", None, cutout=True); mat("samambaia", "samambaia", None, cutout=True)
mat("araucaria_folha", "araucaria", None, cutout=True); mat("folhas_secas", "folhas_secas", None, cutout=True)
mat("toco_top", "toco", None); mat("casca_musgo", "casca_musgo", 1.0); mat("galho", "bark", 1.0, tint=(0.85, 0.82, 0.78))


def card(b, base, w, h, yaw, m, lean=0.0):
    """An upright quad (cut-out texture fitted to it), bottom edge centred on base, leaning `lean` along its normal."""
    a = math.radians(yaw); u = Vector((math.cos(a), math.sin(a), 0)); n = Vector((math.sin(a), -math.cos(a), 0))
    up = (Z + n * lean).normalized() * h; p0 = Vector(base) - u * w / 2; p1 = Vector(base) + u * w / 2
    b.poly([p0, p1, p1 + up, p0 + up], m)


def k_capim(seed):  # a tuft of tall dry grass: three crossed cards
    b = B(); rng = random.Random("capim%d" % seed); y0 = rng.uniform(0, 60)
    for k in range(3):
        card(b, (rng.uniform(-0.08, 0.08), rng.uniform(-0.08, 0.08), -0.03), rng.uniform(0.55, 0.85), rng.uniform(0.6, 1.05),
             y0 + 60 * k + rng.uniform(-12, 12), "capim", lean=rng.uniform(-0.15, 0.15))
    return b


def k_samambaia(seed):  # a clump of dried fern fronds arching out from the middle
    b = B(); rng = random.Random("samambaia%d" % seed); n = rng.randint(5, 7)
    for k in range(n):
        yaw = 360 * k / n + rng.uniform(-15, 15); a = math.radians(yaw - 90)
        base = (0.06 * math.cos(a), 0.06 * math.sin(a), -0.02)
        card(b, base, rng.uniform(0.28, 0.4), rng.uniform(0.55, 0.8), yaw, "samambaia", lean=rng.uniform(0.7, 1.3))
    return b


def k_arbusto(seed):  # a dry bush: stems fanning out of the ground, twigs, a few dead leaves still hanging on
    b = B(); rng = random.Random("arbusto%d" % seed)
    for _ in range(rng.randint(6, 9)):
        a = rng.uniform(0, 2 * math.pi); out = rng.uniform(0.25, 0.6); L = rng.uniform(0.8, 1.5)
        d = Vector((out * math.cos(a), out * math.sin(a), 1)).normalized()
        p0 = Vector((0.05 * math.cos(a), 0.05 * math.sin(a), -0.05)); p1 = p0 + d * L
        frustum(b, p0, p1, 0.028, 0.006, 4, "galho")
        for t in (0.45, 0.7):  # twigs
            q = p0.lerp(p1, t); dd = (d + Vector((rng.uniform(-0.8, 0.8), rng.uniform(-0.8, 0.8), 0.2))).normalized()
            frustum(b, q, q + dd * L * 0.35, 0.012, 0.003, 3, "galho")
        if rng.random() < 0.7:
            card(b, p1 - Vector((0, 0, 0.3)), 0.4, 0.4, math.degrees(a) + 90, "folhas_secas", lean=rng.uniform(-0.3, 0.3))
    return b


def k_araucaria(seed, alive):
    """The serra's pine, dead or dying: a tall bare trunk, and only at the top whorls of branches rising out and up
    into the flat-topped bowl (the candelabra); on the dying one dark needle tufts at the upturned ends; branches
    broken short here and there."""
    b = B(); rng = random.Random("araucaria%d" % seed); Ht = rng.uniform(10.0, 12.5)
    lean = Vector((rng.uniform(-0.04, 0.04), rng.uniform(-0.04, 0.04), 1)).normalized()
    frustum(b, (0, 0, -0.6), lean * (Ht - 0.4), 0.3, 0.09, 6, "bark")
    for w in range(4):  # whorls, longest lowest, all reaching about the same height: a flat top
        h = Ht - 3.0 + w * 0.8; base = lean * h; n = rng.randint(4, 6); spin = rng.uniform(0, 360)
        for k in range(n):
            a = math.radians(spin + 360 * k / n + rng.uniform(-12, 12))
            out = Vector((math.cos(a), math.sin(a), 0)); L = (3.0 - 0.6 * w) * rng.uniform(0.85, 1.1)
            broken = rng.random() < (0.15 if alive else 0.35)
            elbow = base + out * L * 0.55 + Vector((0, 0, L * 0.22))            # out and a little up...
            tip = elbow + out * L * 0.35 + Vector((0, 0, (Ht + 0.3 - h) * 0.75))  # ...then turning up to the top
            if broken:
                frustum(b, base, base.lerp(elbow, 0.4), 0.07, 0.035, 4, "bark"); continue
            frustum(b, base, elbow, 0.07, 0.045, 4, "bark"); frustum(b, elbow, tip, 0.045, 0.012, 4, "bark")
            if alive and rng.random() < 0.8:  # a tuft on the upturned end, two crossed cards
                for dy in (0, 90):
                    card(b, tip - Vector((0, 0, 0.55)), 1.1, 0.8, math.degrees(a) + dy, "araucaria_folha")
    return b


def stump_top(b, c, r, z, n=8):
    b.poly([Vector(c) + Vector((r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n), z)) for k in range(n)], "toco_top")


def k_toco(seed):  # a cut stump with its rings showing, roots flaring into the ground
    b = B(); rng = random.Random("toco%d" % seed); r = rng.uniform(0.22, 0.34); h = rng.uniform(0.3, 0.55)
    frustum(b, (0, 0, -0.2), (0, 0, h), r * 1.12, r, 8, "casca_musgo")
    stump_top(b, (0, 0, 0), r, h)
    for k in range(3):
        a = rng.uniform(0, 2 * math.pi); d = Vector((math.cos(a), math.sin(a), 0))
        frustum(b, d * r * 0.7 + Vector((0, 0, h * 0.4)), d * (r + 0.35) + Vector((0, 0, -0.08)), 0.09, 0.03, 4, "casca_musgo")
    return b


def k_tronco(seed):  # a fallen trunk, mossy, rings at both ends, a couple of snapped branch stubs
    b = B(); rng = random.Random("tronco%d" % seed); L = rng.uniform(3.0, 4.2); r0, r1 = 0.27, 0.18
    p0, p1 = Vector((-L / 2, 0, r0 - 0.08)), Vector((L / 2, 0, r1 - 0.08))
    frustum(b, p0, p1, r0, r1, 7, "casca_musgo")
    for p, r, sgn in ((p0, r0, -1), (p1, r1, 1)):  # ends: rings facing out
        b.poly([p + Vector((0, r * math.cos(2 * math.pi * k / 7), r * math.sin(2 * math.pi * k / 7))) for k in range(7)][::sgn], "toco_top")
    for t in (0.35, 0.7):
        q = p0.lerp(p1, t) + Vector((0, 0, 0.15))
        frustum(b, q, q + Vector((rng.uniform(-0.2, 0.2), rng.uniform(-0.3, 0.3), 0.45)), 0.05, 0.02, 4, "casca_musgo")
    return b


# --- environmental narrative (vilarejo_build.py narrative()): decals (cut-out, turned with their quad), char, bone, hide
for k in ("sangue_poca", "sangue_mancha", "sangue_arrasto", "sangue_mao", "picho_nao_subam", "picho_noite", "picho_deus",
          "picho_x", "arranhoes"):
    mat(k, k, None, "edge", cutout=True)
mat("cartaz", "paper_procura", None, "edge")
for k in ("umidade", "musgo", "escorrido", "rachadura"):  # weathering (vilarejo_build.py stains())
    mat(k, k, None, "edge", soft=True)
mat("queimado", "carvao", 1.0); mat("telha_queimada", "roof_tiles", 0.8, tint=(0.3, 0.26, 0.24))
mat("osso", "linen", 1.0, tint=(1.0, 0.92, 0.75)); mat("couro", "burlap", 1.0, tint=(0.75, 0.5, 0.35))
mat("couro_mala", "burlap", 1.0, tint=(0.55, 0.33, 0.2)); mat("corvo", "cloth", 1.0, tint=(0.07, 0.07, 0.08))


# --- ambient occlusion baked into vertex colours, for any level (Godot multiplies it over the textures) -------
AO_RAYS = [Vector(v).normalized() for v in ((0, 0, 1), (0.6, 0, 0.8), (-0.6, 0, 0.8), (0, 0.6, 0.8), (0, -0.6, 0.8),
           (0.9, 0.3, 0.3), (-0.3, 0.9, 0.3), (-0.9, -0.3, 0.3), (0.3, -0.9, 0.3), (0.65, 0.65, 0.4), (-0.65, 0.65, 0.4),
           (-0.65, -0.65, 0.4), (0.65, -0.65, 0.4), (1, 0, 0.08), (0, 1, 0.08), (-1, 0, 0.08), (0, -1, 0.08))]


def bake_ao(reach=2.5, strength=0.62, skip_names=(), skip_prefixes=()):
    """Ambient occlusion baked into vertex colours (multiplied over the textures in Godot): wall bases, corners,
    under eaves and porches, the ground round houses, trees and props. Rays over the hemisphere of each corner's face;
    shared kit meshes are skipped (one colour set cannot fit every instance) but still cast occlusion. skip_names /
    skip_prefixes: objects that neither get AO nor cast it (cut-out cards, far shapes, templates)."""
    skip = lambda o: o.name in skip_names or o.name.startswith(tuple(skip_prefixes))
    cards = [o for o in bpy.data.objects if o.type == "MESH" and skip(o)]
    for o in cards:
        o.hide_viewport = True  # cut-out cards and far shapes are not occluders
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get(); sc = bpy.context.scene; done = 0
    for o in bpy.data.objects:
        if o.type != "MESH" or skip(o) or o.name.endswith("colonly") or o.data.users > 1:
            continue
        me = o.data; M = o.matrix_world; R3 = M.to_3x3().normalized()
        col = me.color_attributes.new("Col", "BYTE_COLOR", "CORNER"); cache = {}
        for p in me.polygons:
            n = (R3 @ p.normal).normalized(); t = n.orthogonal().normalized(); bt = n.cross(t); cen = M @ p.center
            for li in p.loop_indices:
                v = M @ me.vertices[me.loops[li].vertex_index].co
                key = (round(v.x, 1), round(v.y, 1), round(v.z, 1), round(n.x, 1), round(n.y, 1), round(n.z, 1))
                if key not in cache:
                    o_ = v + (cen - v) * 0.06 + n * 0.03
                    hits = sum(sc.ray_cast(dg, o_, t * r.x + bt * r.y + n * r.z, distance=reach)[0] for r in AO_RAYS)
                    cache[key] = 1.0 - strength * hits / len(AO_RAYS)
                c = cache[key]; col.data[li].color = (c, c, c, 1.0)
            done += 1
    for o in cards:
        o.hide_viewport = False
    return done

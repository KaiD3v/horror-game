# The environmental narrative (docs/VILAREJO.md): someone was dragged up to the Colônia, the village tried to
# lock itself in. Decals hug the terrain mesh (ray cast) so they never sink into it.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler, noise
from vila_kit import *  # materials, mesh builder, prop pieces
from .layout import *
from .paredes import *
from .objetos import at_house
from .construcoes import fence_line

TERR = None  # the terrain object: the build sets it after terrain()


def ground(x, y, lift=0.035):
    ok, p, *_ = TERR.ray_cast(Vector((x, y, 200)), Vector((0, 0, -1)))
    return (p.z if ok else H(x, y)) + lift


def flat(b, c, size, yaw, m, lift=0.035):
    """A square decal lying on the ground, its corners each on the terrain."""
    a = math.radians(yaw); u = Vector((math.cos(a), math.sin(a))) * size / 2; v = Vector((-u.y, u.x))
    pts = [Vector(c[:2]) - u - v, Vector(c[:2]) + u - v, Vector(c[:2]) + u + v, Vector(c[:2]) - u + v]
    b.poly([(p.x, p.y, ground(p.x, p.y, lift)) for p in pts], m)


def strip(b, path, m, rng, step=0.7, width=(0.35, 0.55), gaps=0.25):
    """A smear dragged along `path` (x, y points): quads every `step` m, across-edge first so the texture runs
    along the drag; some segments left out (it dried in patches, rain washed some away)."""
    pts = []
    for p, q in zip(path, path[1:]):
        p, q = Vector(p), Vector(q); n = max(1, int((q - p).length / step))
        pts += [p.lerp(q, i / n) for i in range(n)]
    pts.append(Vector(path[-1]))
    for p, q in zip(pts, pts[1:]):
        if rng.random() < gaps:
            continue
        d = (q - p).normalized(); left = Vector((-d.y, d.x)) * rng.uniform(*width) / 2
        corners = [p + left, p - left, q - left, q + left]
        b.poly([(c.x, c.y, ground(c.x, c.y)) for c in corners], m)


def house_world(i, b):
    """Move a B built in house i's local frame into world coordinates (so it can join a world-space object)."""
    hx, hy, face = HOUSES[i][:3]
    M = Matrix.LocRotScale(Vector((hx, hy, h_road(hx, hy))), Euler((0, 0, math.radians(face))), None)
    b.v = [M @ v for v in b.v]
    return b


def bridge(b, rng):
    """The road's bridge over the ravine, fallen in: stone abutments, the deck's beams and planks slumped into it."""
    yN, yS, yb = GULLY_Y + 3.4, GULLY_Y - 3.4, GULLY_Y
    zN, zS, zb = H(0, yN), H(0, yS), H(0, yb)
    for y, z in ((yN + 0.6, zN), (yS - 0.6, zS)):
        bx(b, (0, y, (z + zb) / 2 - 0.3), (3.6, 1.4, z - zb + 1.4), "stone")
    for sx in (-1, 1):  # beams: from the north abutment down into the water
        frustum(b, (sx * 1.1, yN, zN - 0.05), (sx * 1.0 + rng.uniform(-0.2, 0.2), yb + 0.4, zb + 0.15), 0.12, 0.1, 6, "casca_musgo", caps=True)
    p0, p1 = Vector((0, yN, zN + 0.05)), Vector((0, yb + 0.6, zb + 0.35)); slope = math.atan2(p0.z - p1.z, p0.y - p1.y)
    for k in range(12):  # deck planks on the slumped beams, some missing, some skewed
        if rng.random() < 0.25:
            continue
        c = p0.lerp(p1, (k + 0.5) / 12)
        bx(b, c, (2.8 + rng.uniform(-0.3, 0.2), 0.24, 0.06), "planks", rot=(-slope, rng.uniform(-0.1, 0.1), rng.uniform(-0.12, 0.12)))
    for k in range(4):  # the south half: a few planks hanging off its abutment
        c = Vector((rng.uniform(-1.0, 1.0), yS - 0.1, zS - 0.5 - 0.2 * k))
        bx(b, c, (0.24, 0.06, 1.2), "planks", rot=(rng.uniform(-0.4, 0.4), rng.uniform(-0.3, 0.3), 0))
    for sx in (-1, 1):  # what is left of the railing
        bx(b, (sx * 1.5, yN - 0.1, zN + 0.5), (0.12, 0.12, 1.1), "planks", rot=(0.15, sx * 0.1, 0))
        bx(b, (sx * 1.45, yS + 0.1, zS + 0.35), (0.12, 0.12, 0.8), "planks", rot=(-0.3, 0, 0))
    for sx in (-1, 1):  # the beams' stubs on the south abutment, cut square: sawn, not broken (the intro shows them)
        bx(b, (sx * 1.1, yS + 0.35, zS - 0.08), (0.24, 0.7, 0.24), "casca_musgo")
        bx(b, (sx * 1.1, yS + 0.71, zS - 0.08), (0.22, 0.02, 0.22), "toco_top")  # the fresh cut face, pale
    e = bpy.data.objects.new("intro_serrado", None); bpy.context.collection.objects.link(e)  # Intro frames it
    e.location = (-1.1, yS + 0.72, zS - 0.08)


def loose_beam():
    """The beam he climbs up out of the ravine in the intro (Intro): leaning from the water to the north brink, its own
    object so the game can drop it into the water behind him. Origin at its top end."""
    top = Vector((-2.6, GULLY_Y + 4.1, H(-2.6, GULLY_Y + 4.1) - 0.15)); foot = Vector((-2.6, GULLY_Y + 1.2, H(-2.6, GULLY_Y + 1.2) + 0.1))
    b = B(); frustum(b, (0, 0, 0), tuple(foot - top), 0.13, 0.12, 6, "casca_musgo", caps=True)
    obj(b, "ponte_viga_solta", tuple(top))


def suitcase(b, c, yaw, rng):
    """An open suitcase dropped on the road, clothes spilled out of it."""
    M = Matrix.LocRotScale(Vector((c[0], c[1], ground(c[0], c[1], 0))), Euler((0, 0, math.radians(yaw))), None)
    b.box(M @ Matrix.LocRotScale(Vector((0, 0, 0.07)), None, Vector((0.62, 0.4, 0.14))), "couro_mala")
    b.box(M @ Matrix.LocRotScale(Vector((0, 0.32, 0.2)), Euler((-1.9, 0, 0)), Vector((0.62, 0.4, 0.06))), "couro_mala")
    for k in range(6):
        x, y = rng.uniform(-0.6, 0.9), rng.uniform(-0.9, 0.0)
        b.box(M @ Matrix.LocRotScale(Vector((x, y, 0.015)), Euler((0, 0, rng.uniform(0, 3))), Vector((rng.uniform(0.25, 0.5), rng.uniform(0.2, 0.35), 0.02))),
              rng.choice(("cloth_white", "cloth_blue", "cloth_red", "cloth_grey")))


def doll(b, c, yaw):
    """A rag doll face up on the road: red dress, white cloth limbs, stitched-on eyes."""
    M = Matrix.LocRotScale(Vector((c[0], c[1], ground(c[0], c[1], 0))), Euler((0, 0, math.radians(yaw))), None)
    for loc, size, m, rz in (((0, 0, 0.04), (0.14, 0.22, 0.06), "cloth_red", 0), ((0, 0.17, 0.05), (0.11, 0.11, 0.08), "cloth_white", 0),
                             ((-0.11, 0.05, 0.03), (0.04, 0.14, 0.04), "cloth_white", 0.5), ((0.11, 0.06, 0.03), (0.04, 0.14, 0.04), "cloth_white", -0.3),
                             ((-0.05, -0.18, 0.03), (0.045, 0.16, 0.045), "cloth_white", 0.15), ((0.05, -0.19, 0.03), (0.045, 0.16, 0.045), "cloth_white", -0.25),
                             ((-0.025, 0.2, 0.09), (0.02, 0.01, 0.02), "pit", 0), ((0.025, 0.2, 0.09), (0.02, 0.01, 0.02), "pit", 0)):
        b.box(M @ Matrix.LocRotScale(Vector(loc), Euler((0, 0, rz)), Vector(size)), m)


def carcass(b, c, yaw, rng):
    """A cow picked clean in the pasture: spine, ribs, a strip of hide, the skull with its horns, legs flung out."""
    M = Matrix.LocRotScale(Vector((c[0], c[1], ground(c[0], c[1], 0))), Euler((0, 0, math.radians(yaw))), None)
    T_ = lambda v: M @ Vector(v)
    frustum(b, T_((-0.95, 0, 0.28)), T_((0.95, 0, 0.32)), 0.06, 0.05, 5, "osso", caps=True)
    for i in range(9):
        x = -0.55 + 0.13 * i
        for s in (-1, 1):
            if rng.random() < 0.15:
                continue  # a rib gone
            pts = [T_((x, s * 0.04, 0.3)), T_((x + 0.02, s * 0.3, 0.27)), T_((x + 0.04, s * 0.42, 0.12)), T_((x + 0.05, s * 0.36, 0.02))]
            for p, q in zip(pts, pts[1:]):
                frustum(b, p, q, 0.022, 0.018, 3, "osso", caps=True)
    for s in (-1, 1):  # what is left of the hide, sagging off one side
        b.box(M @ Matrix.LocRotScale(Vector((-0.15 + 0.35 * s, -0.45, 0.06)), Euler((0.25, 0, 0.2 * s)), Vector((0.55, 0.5, 0.03))), "couro")
    b.box(M @ Matrix.LocRotScale(Vector((-1.05, 0, 0.18)), Euler((0, 0, 0)), Vector((0.3, 0.42, 0.2))), "osso")  # pelvis
    b.box(M @ Matrix.LocRotScale(Vector((1.3, 0.05, 0.12)), Euler((0, 0.15, 0.3)), Vector((0.38, 0.2, 0.2))), "osso")  # skull
    b.box(M @ Matrix.LocRotScale(Vector((1.55, 0.13, 0.08)), Euler((0, 0.3, 0.3)), Vector((0.22, 0.12, 0.1))), "osso")
    for s in (-1, 1):
        frustum(b, T_((1.2, 0.05 + s * 0.1, 0.2)), T_((1.15, 0.05 + s * 0.32, 0.38)), 0.03, 0.006, 4, "osso", caps=True)  # horns
    for x, y, a in ((-0.9, 0.5, 0.3), (-0.8, -0.6, -0.5), (0.7, 0.55, 0.9), (0.85, -0.5, -0.8)):  # legs
        frustum(b, T_((x, y * 0.6, 0.05)), T_((x + 0.6 * math.cos(a), y + 0.6 * math.sin(a), 0.04)), 0.03, 0.025, 4, "osso", caps=True)


def k_corvo():
    """A crow, ~0.4 m: body, head, beak, tail, two legs. Black."""
    b = B()
    bx(b, (0, 0, 0.2), (0.12, 0.26, 0.12), "corvo", rot=(0.25, 0, 0)); bx(b, (0, -0.15, 0.3), (0.08, 0.08, 0.08), "corvo")
    frustum(b, (0, -0.19, 0.3), (0, -0.27, 0.29), 0.022, 0.002, 4, "iron", caps=True)
    bx(b, (0, 0.17, 0.17), (0.08, 0.14, 0.03), "corvo", rot=(-0.4, 0, 0))
    for s in (-1, 1):
        bx(b, (s * 0.03, -0.02, 0.07), (0.012, 0.012, 0.12), "iron")
    return b


def k_corvo_asa():
    """One wing, spread, hinged at the origin and reaching out along +X (the other is its mirror in Godot)."""
    b = B()
    bx(b, (0.11, 0.02, 0), (0.22, 0.15, 0.012), "corvo")
    bx(b, (0.28, 0.05, 0), (0.14, 0.10, 0.01), "corvo", rot=(0, 0, -0.25))  # the fingered tip, swept back
    return b


def narrative():
    rng = random.Random("narrativa")
    deco = B()  # every decal and small story prop: one object, no collision
    # 1. the drag: a pool at casa_04's door, smears across its yard, the trail up the road to the Colônia's gate
    dx, _ = DOORS["casa_04"]; d4 = HOUSES[3][4]
    x, y, _ = at_house(3, dx, -d4 / 2 - 1.0)
    flat(deco, (x, y), 2.2, rng.uniform(0, 360), "sangue_poca")
    path = [(x, y), (5.0, -14.4), (2.4, -13.4), (1.3, -7.0), (0.7, 0.0), (1.4, 8.0), (1.8, 20.0), (-1.0, 32.0), (-1.3, 40.0),
            (0.3, 50.0), (0.5, WALL_Y - 1.0)]
    strip(deco, path, "sangue_arrasto", rng)
    for _ in range(14):  # drops and smears along the way
        i = rng.randrange(len(path) - 1); p, q = Vector(path[i]), Vector(path[i + 1])
        c = p.lerp(q, rng.random()) + Vector((rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6)))
        flat(deco, c, rng.uniform(0.3, 0.6), rng.uniform(0, 360), "sangue_mancha")
    flat(deco, (0.4, WALL_Y - 1.2), 1.8, 30, "sangue_poca")  # where it stopped, at the gate
    gate = (Vector((0, WALL_Y - 0.47, 0)), X, -Y)  # the pillars' faces (the leaves are the game's: they open)
    g = H(0, WALL_Y)
    for u, z, r in ((-2.75, 1.0, 0.2), (-2.45, 1.45, -0.3), (2.5, 0.85, 0.1), (2.8, 1.5, 0.5)):  # hands on the pillars
        wall_decal(deco, gate, u, g + z, 0.26, 0.26, "sangue_mao", rot=r)
    # 3. graffiti: on the Colônia's wall, beside its gate
    wf = (Vector((0, WALL_Y - 0.27, 0)), X, -Y)
    wall_decal(deco, wf, -7.0, H(-7.0, WALL_Y) + 1.9, 4.2, 1.05, "picho_nao_subam", rot=0.03)
    # 7. the missing: notices on the Colônia's wall by the gate, on the signpost, on a fence post, on the cemetery gate
    for k in range(7):
        u = 4.3 + 0.45 * k + rng.uniform(-0.1, 0.1)
        wall_decal(deco, wf, u, H(u, WALL_Y) + rng.uniform(1.4, 2.2), 0.32, 0.4, "cartaz", rot=rng.uniform(-0.15, 0.15))
    for (px, py), face, z in (((-3.5, -2.0 - 0.06), 0, 1.25), ((CEMETERY[0] + CEMETERY[2] / 2 + 0.2, CEMETERY[1] + 1.8), 90, 0.6)):
        a = math.radians(face); fr = (Vector((px, py, 0)), Vector((math.cos(a), math.sin(a), 0)), Vector((math.sin(a), -math.cos(a), 0)))
        wall_decal(deco, fr, 0, H(px, py) + z, 0.26, 0.33, "cartaz", rot=rng.uniform(-0.1, 0.1))
    # 5. the way out: the ravine's fallen bridge; on the road a dropped suitcase, a doll
    br = B(); bridge(br, rng); obj(br, "ponte_caida-col")
    guard = B(); grng = random.Random("ravina/cerca"); yg = GULLY_Y + 5.0  # on the brink, before the bank drops
    fence_line(guard, (-56, yg), (-2.2, yg), grng, gone=0.35)
    fence_line(guard, (2.2, yg), (56, yg), grng, gone=0.35)
    for sx in (-1, 1):  # across the road: two sawhorses and a plank between them
        x = sx * 1.3; g_ = H(x, yg)
        for s in (-1, 1):
            bx(guard, (x, yg + s * 0.25, g_ + 0.45), (0.08, 0.08, 1.0), "fence", rot=(s * 0.45, 0, 0))
        bx(guard, (x, yg, g_ + 0.85), (0.9, 0.1, 0.1), "planks")
    bx(guard, (0, yg - 0.1, H(0, yg) + 0.95), (3.6, 0.05, 0.25), "planks", rot=(0, 0.06, 0))
    wall_decal(guard, (Vector((0, yg - 0.07, 0)), -X, Y), 0.6, H(0, yg) + 0.95, 0.3, 0.38, "cartaz", rot=0.08)  # facing the village
    obj(guard, "ravina_cerca-col")
    loose_beam()
    wall = B()  # the fence's reach, no gaps, 3 m over the ground: he never falls in
    for x in range(-56, 56, 4):
        h0 = min(H(x, yg), H(x + 4, yg)); h1 = max(H(x, yg), H(x + 4, yg))
        bx(wall, (x + 2, yg, (h0 - 1 + h1 + 3) / 2), (4.02, 0.3, h1 + 3 - h0 + 1), "fence")
    obj(wall, "ravina_guarda-colonly")
    water = B()  # standing water along the bottom of the ravine
    strip(water, [(-74, GULLY_Y), (74, GULLY_Y)], "pit", random.Random(1), step=2.0, width=(2.2, 2.2), gaps=0)
    obj(water, "ravina_agua")
    suitcase(deco, (1.7, -42.3), 20, rng)
    doll(deco, (-1.9, -38.4), 140)
    # 6. the carcass in the pasture, crows on it and on the scarecrow
    cx, cy = 34.0, -33.0
    carcass(deco, (cx, cy), 35, rng)
    flat(deco, (cx, cy), 3.0, 20, "sangue_poca", lift=0.02)
    # crows: live ones (vilarejo.gd / corvo.gd flies them off when you come near). One body and one wing as
    # templates at the origin, a corvo_NN marker where each perches.
    obj(k_corvo(), "corvo_corpo"); obj(k_corvo_asa(), "corvo_asa")
    perches = [(cx + 0.2, cy + 0.1, ground(cx + 0.2, cy + 0.1, 0) + 0.36, 40), (cx - 0.4, cy - 0.2, ground(cx - 0.4, cy - 0.2, 0) + 0.33, 200),
               (cx + 1.6, cy + 0.6, ground(cx + 1.6, cy + 0.6, 0), 120), (cx - 1.2, cy + 1.0, ground(cx - 1.2, cy + 1.0, 0), 300)]
    sa = math.radians(-100)  # the scarecrow at (30, -27) facing the road: one crow on each arm
    for s in (-0.6, 0.55):
        perches.append((30.0 + s * math.cos(sa), -27.0 + s * math.sin(sa), H(30.0, -27.0) - 0.3 + 1.66, rng.uniform(0, 360)))
    for x, y in ((-0.6, 40.6), (1.2, 21.0), (-3.0, 52.0)):  # on the road, pecking at the trail
        perches.append((x, y, ground(x, y, 0), rng.uniform(0, 360)))
    for i, (x, y, z, yaw) in enumerate(perches):
        e = bpy.data.objects.new("corvo_%02d" % (i + 1), None); bpy.context.collection.objects.link(e)
        e.location = (x, y, z); e.rotation_euler.z = math.radians(yaw)
    e = bpy.data.objects.new("marca_carcaca", None); bpy.context.collection.objects.link(e)
    e.location = (cx, cy, H(cx, cy))  # vilarejo.gd: the crows call from here when you are near
    obj(deco, "narrativa")

# The buildings: houses (and their weathering), the ruin, the chapel, the well, the Colônia's wall, the
# cemetery, the fences.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler, noise
from vila_kit import *  # materials, mesh builder, prop pieces
from .layout import *
from .paredes import *


def house(name, hx, hy, face, w, d, kind, ex):
    b = B(); rng = random.Random(name)
    floors = 2 if kind == "sobrado" else 1
    plinth = 0.6 if kind == "wood" else 0.35
    Hh = 2.7 * floors; top = plinth + Hh
    wall = "siding_" + ex["siding"] if kind == "wood" else "whitewash"
    burnt = ex.get("burnt")
    if burnt:
        wall = "queimado"
    shutter = "shutter_" + ex.get("shutter", "blue")
    bx(b, (0, 0, (plinth - 1.2) / 2), (w + 0.12, d + 0.12, plinth + 1.2), "stone")  # foundation, 1.2 m into the ground
    bx(b, (0, 0, plinth + Hh / 2), (w, d, Hh), wall)
    if kind != "wood":
        bx(b, (0, 0, plinth + 0.4), (w + 0.04, d + 0.04, 0.8), "barra_" + ex["barra"])  # painted band
    if kind == "sobrado":
        bx(b, (0, 0, plinth + 2.7), (w + 0.1, d + 0.1, 0.16), "planks")  # floor beam
    pitch = rng.uniform(24, 30) if kind != "wood" else rng.uniform(32, 40)
    rh = gable_roof(b, w, d, top, pitch, 0.55 if kind == "sobrado" else 0.45, wall,
                    roof="telha_queimada" if burnt else "roof", front=not burnt)
    # door, then windows round the walls, clear of the door
    dw = 1.6 if kind == "sobrado" else 0.95
    door_x = 0.0 if kind == "sobrado" else rng.choice((-1, 1)) * rng.uniform(0.3, w / 4)
    front = wall_frame("front", w, d, 0.05 if kind != "wood" else 0.03)
    if kind == "sobrado":  # shop door: two leaves
        opening(b, front, door_x - dw / 2, door_x, plinth, plinth + 2.3, "door")
        opening(b, front, door_x, door_x + dw / 2, plinth, plinth + 2.3, "door")
        bx(b, (0, -d / 2 - 0.1, plinth + 2.55), (2.6, 0.08, 0.5), "planks")  # shop sign
        z0, y0 = plinth + 2.33, -d / 2 - 0.145
        b.poly([(-1.25, y0, z0), (1.25, y0, z0), (1.25, y0, z0 + 0.44), (-1.25, y0, z0 + 0.44)], "sign_venda")
    else:
        opening(b, front, door_x - dw / 2, door_x + dw / 2, plinth, plinth + 2.05, "pit" if burnt else "door")
        if ex.get("chained"):
            chained_door(b, w, d, door_x, plinth, rng)
    bx(b, (door_x, -d / 2 - 0.35, plinth / 2 - 0.1), (dw + 0.4, 0.6, plinth + 0.2), "stone")  # step
    side_u = ex.get("lado")  # a second door, in the left wall (u along it); DOORS[name + "_lado"]: where you stand
    if side_u is not None:
        opening(b, wall_frame("left", w, d, 0.05), side_u - 0.475, side_u + 0.475, plinth, plinth + 2.05, "door")
        bx(b, (-w / 2 - 0.35, -side_u, plinth / 2 - 0.1), (0.6, dw + 0.4, plinth + 0.2), "stone")
        DOORS[name + "_lado"] = (-w / 2 - 1.0, -side_u)
    for side, length in (("front", w), ("back", w), ("left", d), ("right", d)):
        fr = wall_frame(side, w, d, 0.05 if kind != "wood" else 0.03)
        k = max(1, int(length / 2.6))
        for fl in range(floors):
            for i in range(k):
                u = -length / 2 + length * (i + 0.5) / k
                if side == "front" and fl == 0 and abs(u - door_x) < dw / 2 + 0.8:
                    continue
                if side == "left" and fl == 0 and side_u is not None and abs(u - side_u) < dw / 2 + 0.8:
                    continue
                z0 = plinth + 2.7 * fl + 0.95
                opening(b, fr, u - 0.4, u + 0.4, z0, z0 + 1.05, "pit" if burnt else "window" if rng.random() < 0.45 else shutter, sill=True)
    if ex.get("chimney"):
        cx = rng.choice((-1, 1)) * w * 0.28
        bx(b, (cx, d / 4, top + rh * 0.5), (0.55, 0.55, rh + 1.6), wall if kind != "wood" else "stone")
        bx(b, (cx, d / 4, top + rh * 0.5 + (rh + 1.6) / 2 + 0.05), (0.7, 0.7, 0.1), "stone")
    if ex.get("porch"):  # alpendre: deck, posts, a lean-to under the eave
        pd = 2.2; pz = top - 0.35; pl = pz - pd * math.tan(math.radians(14))
        bx(b, (0, -d / 2 - pd / 2, plinth - 0.08), (w, pd, 0.16), "planks")
        for px in (-w / 2 + 0.15, 0.0, w / 2 - 0.15):
            if abs(px - door_x) > 0.6:
                bx(b, (px, -d / 2 - pd + 0.15, (plinth + pl) / 2), (0.14, 0.14, pl - plinth), "planks")
        bx(b, (0, -d / 2 - pd / 2 - 0.1, (pz + pl) / 2 + 0.06), (w + 0.3, (pd + 0.3) / math.cos(math.radians(14)), 0.1),
           "roof", rot=(math.radians(14), 0, 0))
        bx(b, (door_x, -d / 2 - pd - 0.3, plinth / 2 - 0.15), (1.0, 0.5, plinth), "stone")
        if ex.get("sign"):  # shop board hung from the porch's front edge on two chains
            y0, zc = -d / 2 - pd - 0.05, pl - 0.32
            bx(b, (door_x, y0, zc), (1.8, 0.05, 0.42), "fence")
            b.poly([(door_x - 0.86, y0 - 0.03, zc - 0.2), (door_x + 0.86, y0 - 0.03, zc - 0.2),
                    (door_x + 0.86, y0 - 0.03, zc + 0.2), (door_x - 0.86, y0 - 0.03, zc + 0.2)], "sign_" + ex["sign"])
            for sx in (-0.7, 0.7):
                bx(b, (door_x + sx, y0, (zc + 0.21 + pl) / 2), (0.02, 0.02, pl - zc - 0.21), "iron")
    for m, side, u, z, dw_, dh_, rot in ex.get("decais", ()):  # graffiti, notices
        wall_decal(b, wall_frame(side, w, d, 0.065), u, plinth + z, dw_, dh_, m, rot)
    if burnt:  # the fallen half of the roof in front: charred beams and broken tiles
        for _ in range(14):
            sz = rng.uniform(0.2, 1.6)
            bx(b, (rng.uniform(-w / 2, w / 2), rng.uniform(-d / 2 - 2.8, -d / 2 - 0.4), 0.06), (sz, rng.uniform(0.1, 0.4), 0.1),
               rng.choice(("queimado", "queimado", "telha_queimada")), rot=(rng.uniform(-0.2, 0.2), rng.uniform(-0.2, 0.2), rng.uniform(0, 3)))
    if not burnt:
        stains(b, name, kind, w, d, plinth, floors, door_x, dw)
    DOORS[name] = (door_x, -d / 2 - (2.2 if ex.get("porch") else 0.35) - 1.0)
    return b


def stains(b, name, kind, w, d, plinth, floors, door_x, dw):
    """Weathering over a house (TODO_ARTE "Acabamento do cenário"): rising damp along the walls, moss at the foot of
    the corners, dirt run down from the window sills, a crack or two in the plaster. Own rng: the house keeps its look."""
    rng = random.Random(name + "/manchas")
    e = 0.045 if kind == "wood" else 0.06  # just off the wall (windows sit at 0.03 / 0.05, graffiti at 0.065)
    sides = (("front", w), ("back", w), ("left", d), ("right", d))
    for side, length in sides:
        if kind != "wood" and rng.random() < 0.85:
            wall_decal(b, wall_frame(side, w, d, e), rng.uniform(-0.3, 0.3), plinth + 0.36, length - 0.08,
                       rng.uniform(0.55, 0.95), "umidade")
        for cu in (-length / 2 + 0.4, length / 2 - 0.4):
            if rng.random() < 0.55:  # on the foundation stones, which stand out 6 cm
                wall_decal(b, wall_frame(side, w, d, 0.075), cu + rng.uniform(-0.15, 0.15), plinth * 0.6,
                           rng.uniform(0.5, 0.9), rng.uniform(0.35, 0.55), "musgo")
        k = max(1, int(length / 2.6))
        for fl in range(floors):
            for i in range(k):
                u = -length / 2 + length * (i + 0.5) / k
                if side == "front" and fl == 0 and abs(u - door_x) < dw / 2 + 0.8:
                    continue
                if rng.random() < 0.6:  # = the windows in house(): the streaks run from their sills
                    z0 = plinth + 2.7 * fl + 0.95
                    wall_decal(b, wall_frame(side, w, d, e + 0.004), u + rng.uniform(-0.12, 0.12), z0 - 0.5,
                               rng.uniform(0.45, 0.7), rng.uniform(0.7, 0.95), "escorrido")
    if kind != "wood":
        for _ in range(rng.randint(1, 2)):
            side, length = rng.choice(sides)
            wall_decal(b, wall_frame(side, w, d, e + 0.002), rng.uniform(-length / 2 + 0.6, length / 2 - 0.6),
                       plinth + rng.uniform(1.6, 2.3), 0.7, 0.9, "rachadura", rot=rng.uniform(-0.3, 0.3))


# The ruin by the way in, a classroom of the moves (../docs/TUTORIAL_VILAREJO.md "A ruína"), in its local frame
# (front = -Y, w = 6 along x, d = 5 along y). vilarejo.gd places the climbs, the jump and the hint on these numbers.
AULA = {"floor": 0.9,                     # the raised plank floor (three steps up to the door)
        "pit": (-1.05, 0.45),             # y: where the floor fell into the crawl space, down to the ground
        "slab": (-2.2, -1.6, 1.4),        # y0, y1, how high above the floor: a piece of ceiling down across the doorway
        "loft": (1.4, 0.7),               # y: the stone grain store's face, its height over the floor
        "breach": (0.4, 2.0)}             # x: the back wall down to the store, a way out over its back


def ruin(name, w, d, aula=False):
    """Walls fallen to ragged stubs, no roof, a gap for the door, beams and rubble inside: the one you can enter.
    aula: the classroom one (AULA), raised floor fallen in the middle, a slab to crouch under, a store to climb."""
    b = B(); rng = random.Random(name); t = 0.3; plinth = 0.05  # flush with the ground: you walk straight in
    if aula:
        plinth = _classroom(b, w, d, t)
    else:
        bx(b, (0, 0, (plinth - 1.2) / 2), (w + 0.12, d + 0.12, plinth + 1.2), "stone")
        bx(b, (0, 0, plinth + 0.02), (w - 2 * t, d - 2 * t, 0.04), "planks")  # what is left of the floor
    for side, length in (("front", w), ("back", w), ("left", d), ("right", d)):
        o, u, n = wall_frame(side, w, d, -t / 2)
        k = int(length / 0.6)
        for i in range(k):
            a = -length / 2 + length * (i + 0.5) / k
            if side == "front" and abs(a) < 0.7:
                continue  # doorway
            hgt = 0.9 + 1.9 * abs(noise.noise(Vector((a * 0.6, len(side), 0.3)))) + rng.uniform(0, 0.5)
            if side == "back":
                hgt += 0.8  # the back still stands to the eaves in places
            base = plinth
            if aula and side == "back":
                if AULA["breach"][0] < -a < AULA["breach"][1]:
                    continue  # fallen down to the store: the way out
                base = plinth + AULA["loft"][1]  # standing on the store
            c = o + u * a + Z * (base + hgt / 2)
            size = (length / k + 0.01, t, hgt) if abs(u.x) > 0.5 else (t, length / k + 0.01, hgt)
            bx(b, c, size, "whitewash" if hgt > 1.2 else "barra_ochre")
    if aula:
        return b
    for _ in range(3):  # fallen roof beams
        bx(b, (rng.uniform(-w / 4, w / 4), rng.uniform(-d / 4, d / 4), plinth + 0.5),
           (0.16, d * 0.8, 0.16), "planks", rot=(rng.uniform(0.15, 0.35), 0, rng.uniform(-0.6, 0.6)))
    for _ in range(9):  # rubble and broken tiles, the way in left clear
        s = rng.uniform(0.25, 0.6); x, y = rng.uniform(-w / 2 - 1, w / 2 + 1), rng.uniform(-d / 2 - 1, d / 2 + 1)
        if abs(x) < 1.3 and y < -d / 2 + 2.5:
            continue
        bx(b, (x, y, plinth + s / 4),
           (s, s * 0.8, s * 0.5), rng.choice(("whitewash", "roof", "stone")), rot=(0, 0, rng.uniform(0, 3)))
    return b


def _classroom(b, w, d, t):
    """The classroom ruin's floor (AULA): stone footings, planks at `floor`, the hole down to the ground with broken
    boards in it, the ceiling slab on two brick stubs over the doorway, the store at the back, steps up to the door.
    The edges to climb are chalked white (the village's sign for it). Returns the floor's height."""
    F = AULA["floor"]; p0, p1 = AULA["pit"]; s0, s1, sh = AULA["slab"]; ly, lh = AULA["loft"]
    W, D = w / 2 + 0.06, d / 2 + 0.06
    def block(x0, x1, y0, y1, z0, z1, m):
        bx(b, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0), m)
    block(-W, W, -D, p0, -1.2, F - 0.02, "stone")               # footing under the front floor
    block(-W, W, p1, D, -1.2, F - 0.02, "stone")                # ...under the back one and the store
    for x0, x1 in ((-W, -w / 2 + t), (w / 2 - t, W)):           # the hole's sides
        block(x0, x1, p0, p1, -1.2, F, "stone")
    block(-w / 2 + t, w / 2 - t, p0, p1, -1.2, 0.05, "mud")     # its bottom: the ground
    # the boards left, out over the threshold: one level from the top step in (crouched under the slab there is no
    # headroom to step up even a lip: Steps)
    block(-w / 2 + t, w / 2 - t, -D + 0.3, p0, F - 0.02, F, "planks"); block(-0.8, 0.8, -D, -D + 0.3, F - 0.02, F, "planks")
    block(-w / 2 + t, w / 2 - t, p1, ly, F - 0.02, F, "planks")
    rng = random.Random("ruina/aula")
    for _ in range(5):  # boards that fell in
        bx(b, (rng.uniform(-2.2, 2.2), rng.uniform(p0 + 0.3, p1 - 0.3), 0.1), (0.22, 1.3, 0.04), "planks",
           rot=(rng.uniform(-0.15, 0.15), 0, rng.uniform(0, 3)))
    block(-w / 2 + t, w / 2 - t, ly, D, F - 0.02, F + lh, "stone")  # the store, out to the back wall's face
    for x0, x1 in ((-1.35, -1.05), (1.05, 1.35)):              # the slab's brick stubs and the slab
        block(x0, x1, s0, s1, F, F + sh, "barra_ochre")
    bx(b, (0, (s0 + s1) / 2, F + sh + 0.06), (2.8, s1 - s0, 0.12), "planks", rot=(0, 0.03, 0.02))
    for i in range(3):  # steps up to the door, 30 cm each
        y1 = -D - 0.3 * i
        block(-0.8, 0.8, y1 - 0.3, y1, -0.6, F - 0.3 * i, "stone")
    for y in (p0 - 0.005, p1 + 0.005):                          # chalk along the edges to climb
        block(-w / 2 + t, w / 2 - t, y - 0.01, y + 0.01, F - 0.12, F, "whitewash")
    block(-w / 2 + t, w / 2 - t, ly - 0.015, ly - 0.005, F + lh - 0.12, F + lh, "whitewash")
    block(AULA["breach"][0], AULA["breach"][1], D + 0.005, D + 0.015, F + lh - 0.12, F + lh, "whitewash")
    return F


def chapel():
    """Small whitewashed chapel, ochre pilasters, a bell tower over the door: the landmark in the fog."""
    b = B(); w, d, plinth, Hh = 6.5, 11.0, 0.4, 4.8; top = plinth + Hh
    bx(b, (0, 0, (plinth - 1.2) / 2), (w + 0.12, d + 0.12, plinth + 1.2), "stone")
    bx(b, (0, 0, plinth + Hh / 2), (w, d, Hh), "whitewash")
    bx(b, (0, 0, plinth + 0.45), (w + 0.04, d + 0.04, 0.9), "barra_blue")
    for sx in (-1, 1):
        for sy in (-1, 1):
            bx(b, (sx * w / 2, sy * d / 2, plinth + Hh / 2), (0.45, 0.45, Hh), "barra_ochre")  # corner pilasters
    gable_roof(b, w, d, top, 32, 0.35, "whitewash")
    for side in ("left", "right"):
        fr = wall_frame(side, w, d, 0.05)
        for u in (-2.6, 0.6, 3.4):
            opening(b, fr, u - 0.4, u + 0.4, plinth + 1.6, plinth + 3.6, "window", sill=True)
    # the tower in front of the nave, door in its face
    tw, th = 2.8, 8.2; ty = -d / 2 - tw / 2 + 0.05
    bx(b, (0, ty, (plinth - 1.2 + th) / 2), (tw, tw, th - plinth + 1.2 + plinth), "whitewash")
    bx(b, (0, ty, plinth + 0.45), (tw + 0.04, tw + 0.04, 0.9), "barra_blue")
    tf = (Vector((0, ty - tw / 2 - 0.05, 0)), X, -Y)
    opening(b, tf, -0.8, 0.0, plinth, plinth + 2.8, "door"); opening(b, tf, 0.0, 0.8, plinth, plinth + 2.8, "door")
    opening(b, tf, -0.45, 0.45, plinth + 4.2, plinth + 5.2, "window")
    wall_decal(b, (Vector((0, ty - tw / 2 - 0.065, 0)), X, -Y), 0, plinth + 3.45, 2.5, 0.42, "picho_deus", rot=-0.03)
    rng = random.Random("capela/manchas")
    for side, length in (("left", d), ("right", d), ("back", w)):
        wall_decal(b, wall_frame(side, w, d, 0.06), 0, plinth + 0.4, length - 0.6, rng.uniform(0.8, 1.1), "umidade")
        for cu in (-length / 2 + 0.6, length / 2 - 0.6):
            wall_decal(b, wall_frame(side, w, d, 0.075), cu, plinth * 0.6, 0.8, 0.45, "musgo")
        if side != "back":
            for u in (-2.6, 0.6, 3.4):
                wall_decal(b, wall_frame(side, w, d, 0.055), u + rng.uniform(-0.1, 0.1), plinth + 1.05, 0.6, 1.1, "escorrido")
    wall_decal(b, (Vector((0, ty - tw / 2 - 0.06, 0)), X, -Y), 0.9, plinth + 0.4, tw - 0.1, 0.9, "umidade")
    wall_decal(b, (Vector((0, ty - tw / 2 - 0.062, 0)), X, -Y), 0.95, plinth + 5.6, 0.8, 1.1, "rachadura", rot=0.2)
    bx(b, (0, ty - tw / 2 - 0.4, plinth / 2 - 0.1), (2.4, 0.8, plinth + 0.2), "stone")
    for sx in (-1, 1):
        for sy in (-1, 1):  # belfry: four piers, open between them
            bx(b, (sx * (tw / 2 - 0.25), ty + sy * (tw / 2 - 0.25), th + 1.0), (0.5, 0.5, 2.0), "whitewash")
    bx(b, (0, ty, th + 2.1), (tw + 0.2, tw + 0.2, 0.25), "barra_ochre")  # cornice
    a, top2 = tw / 2 + 0.25, th + 2.2
    apex = (0, ty, top2 + 2.2)
    for k in range(4):  # pyramid roof
        c0 = [(-a, -a), (a, -a), (a, a), (-a, a)][k]; c1 = [(-a, -a), (a, -a), (a, a), (-a, a)][(k + 1) % 4]
        b.poly([(c0[0], ty + c0[1], top2), (c1[0], ty + c1[1], top2), apex], "roof")
    bx(b, (0, ty, apex[2] + 0.55), (0.08, 0.08, 1.1), "iron"); bx(b, (0, ty, apex[2] + 0.75), (0.5, 0.08, 0.08), "iron")
    frustum(b, (0, ty, th + 0.55), (0, ty, th + 1.15), 0.42, 0.2, 8, "iron", caps=True)  # the bell
    bx(b, (0, ty, th + 1.25), (tw - 0.4, 0.12, 0.12), "planks")
    return b


def well(b, c):
    """Stone ring with a dark hole, two posts, a little tiled roof and a crank."""
    n, r0, r1, hh = 10, 0.95, 0.65, 0.85
    ang = [2 * math.pi * k / n for k in range(n)]
    P = lambda r, a, z: c + Vector((r * math.cos(a), r * math.sin(a), z))
    for k in range(n):
        a0, a1 = ang[k], ang[(k + 1) % n]
        b.poly([P(r0, a0, -0.5), P(r0, a1, -0.5), P(r0, a1, hh), P(r0, a0, hh)], "stone")
        b.poly([P(r0, a0, hh), P(r0, a1, hh), P(r1, a1, hh), P(r1, a0, hh)], "stone")
        b.poly([P(r1, a1, -0.6), P(r1, a0, -0.6), P(r1, a0, hh), P(r1, a1, hh)], "stone")
    b.poly([P(r1, a, -0.6) for a in ang], "pit")
    for sx in (-1, 1):
        bx(b, c + Vector((sx * 0.85, 0, 1.4)), (0.14, 0.14, 1.9), "planks")
    bx(b, c + Vector((0, 0, 1.65)), (1.9, 0.1, 0.1), "planks")
    for s in (-1, 1):
        p = math.radians(35)
        bx(b, c + Vector((0, s * 0.4, 2.45)), (2.3, 0.95, 0.07), "roof", rot=(-s * p, 0, 0))


WR = random.Random("muro/manchas")


def colony_wall(b):
    """The Colônia's wall across the north edge, following the hill, and its boarded gate on the road."""
    x = -64.0
    while x < 64:
        if abs(x + 2) < 2.5:  # gate opening between x = -2.3 and 2.3
            x += 4.0; continue
        x1 = min(x + 4, 64)
        h0 = min(H(x, WALL_Y), H(x1, WALL_Y)); h1 = max(H(x, WALL_Y), H(x1, WALL_Y))
        bx(b, ((x + x1) / 2, WALL_Y, (h0 - 0.8 + h1 + 3.4) / 2), (x1 - x + 0.02, 0.5, h1 + 3.4 - h0 + 0.8), "whitewash")
        bx(b, ((x + x1) / 2, WALL_Y, h0 + 0.3), (x1 - x + 0.04, 0.56, 1.0), "stone")
        bx(b, ((x + x1) / 2, WALL_Y, h1 + 3.45), (x1 - x + 0.04, 0.62, 0.12), "roof")
        if WR.random() < 0.75:
            wall_decal(b, (Vector((0, WALL_Y - 0.26, 0)), X, -Y), (x + x1) / 2, h0 + 1.15, x1 - x, WR.uniform(0.6, 1.0), "umidade")
        if WR.random() < 0.5:
            wall_decal(b, (Vector((0, WALL_Y - 0.29, 0)), X, -Y), WR.uniform(x + 0.6, x1 - 0.6), h0 + 0.45, WR.uniform(0.8, 1.6), 0.5, "musgo")
        x = x1
    g = H(0, WALL_Y)
    for sx in (-1, 1):
        bx(b, (sx * 2.6, WALL_Y, g + 1.8), (0.9, 0.9, 5.2), "whitewash")
        bx(b, (sx * 2.6, WALL_Y, g + 4.5), (1.1, 1.1, 0.25), "stone")
    for sx in (-1, 1):  # wall from each pillar to the first whole piece (x = 3 to 4)
        h0 = min(H(sx * 3.0, WALL_Y), H(sx * 4.0, WALL_Y)); h1 = max(H(sx * 3.0, WALL_Y), H(sx * 4.0, WALL_Y))
        bx(b, (sx * 3.5, WALL_Y, (h0 - 0.8 + h1 + 3.4) / 2), (1.04, 0.5, h1 + 3.4 - h0 + 0.8), "whitewash")
        bx(b, (sx * 3.5, WALL_Y, h0 + 0.3), (1.06, 0.56, 1.0), "stone")
        bx(b, (sx * 3.5, WALL_Y, h1 + 3.45), (1.06, 0.62, 0.12), "roof")
    # the gate itself (its two leaves, chain and padlock) is built by the game: vilarejo.gd, Gate, on this marker
    e = bpy.data.objects.new("portao_colonia", None); bpy.context.collection.objects.link(e); e.location = (0, WALL_Y, g)
    bx(b, (0, WALL_Y, g + 5.5), (5.6, 0.12, 0.12), "iron")  # iron arch
    for sx in (-1, 1):
        bx(b, (sx * 2.6, WALL_Y, g + 5.0), (0.1, 0.1, 1.0), "iron")


def cemetery(b, cem_cross):
    cx, cy, sx, sy = CEMETERY; t = 0.35
    for side in range(4):  # low stone wall in 3 m pieces following the ground, gate on the east (towards the chapel)
        a = [(cx - sx / 2, cy - sy / 2), (cx + sx / 2, cy - sy / 2), (cx + sx / 2, cy + sy / 2), (cx - sx / 2, cy + sy / 2)]
        p0, p1 = Vector(a[side]), Vector(a[(side + 1) % 4]); L = (p1 - p0).length; k = int(L / 3) + 1
        for i in range(k):
            q0, q1 = p0 + (p1 - p0) * i / k, p0 + (p1 - p0) * (i + 1) / k; m = (q0 + q1) / 2
            if side == 1 and abs(m.y - cy) < 1.5:
                continue
            g = H(m.x, m.y)
            size = (L / k + t, t, 1.6) if side % 2 == 0 else (t, L / k + t, 1.6)
            bx(b, (m.x, m.y, g + 0.2), size, "stone")
    rng = random.Random("cemiterio")
    for i in range(3):
        for j in range(5):
            x = cx - sx / 2 + 2.0 + i * 3.6 + rng.uniform(-0.3, 0.3); y = cy - sy / 2 + 1.8 + j * 2.7 + rng.uniform(-0.2, 0.2)
            g = H(x, y)
            if i == 0 and j >= 3:  # where the Moura mausoleum stands (jazigo())
                continue
            if (i, j) in ((1, 2), (2, 4)):  # the empty graves: a dark pit, the earth heaped beside it
                bx(cem_cross, (x, y - 0.3, g + 0.02), (0.8, 1.8, 0.06), "pit")
                bx(cem_cross, (x + 0.85, y - 0.3, g + 0.1), (0.6, 1.6, 0.4), "mud", rot=(0, 0.2, 0))
                continue
            bx(cem_cross, (x, y - 0.4, g + 0.08), (0.7, 1.7, 0.3), "mud")  # mound
            tilt = (rng.uniform(-0.2, 0.2), rng.uniform(-0.2, 0.2), rng.uniform(-0.3, 0.3))
            M = Matrix.LocRotScale(Vector((x, y + 0.55, g)), Euler(tilt), None)
            cem_cross.box(M @ Matrix.LocRotScale(Vector((0, 0, 0.55)), None, Vector((0.1, 0.1, 1.3))), "planks")
            cem_cross.box(M @ Matrix.LocRotScale(Vector((0, 0, 0.85)), None, Vector((0.6, 0.08, 0.1))), "planks")


mat("cal_jazigo", "whitewash", 2.0, tint=(0.6, 0.6, 0.58))  # grey, weathered


def jazigo():
    """The Moura family's mausoleum (docs/CHAVE_DO_PORTAO.md): grey stone, a pediment with a cross, an iron grate for a
    door (vilarejo.gd: the chain on it, and the way down). Local frame, front = -Y, floor at z = 0."""
    b = B(); w, d = JAZIGO[3], JAZIGO[4]; h = 2.9
    bx(b, (0, 0, -0.3), (w + 0.3, d + 0.3, 0.8), "stone")                          # plinth
    bx(b, (0, 0, h / 2 + 0.1), (w, d, h), "cal_jazigo")
    bx(b, (0, 0, h + 0.2), (w + 0.4, d + 0.4, 0.2), "stone")                       # cornice
    b.poly([(-w / 2 - 0.2, -d / 2 - 0.21, h + 0.3), (w / 2 + 0.2, -d / 2 - 0.21, h + 0.3), (0, -d / 2 - 0.21, h + 1.1)], "stone")
    b.poly([(w / 2 + 0.2, d / 2 + 0.21, h + 0.3), (-w / 2 - 0.2, d / 2 + 0.21, h + 0.3), (0, d / 2 + 0.21, h + 1.1)], "stone")
    for sx in (-1, 1):                                                                 # the roof's two slopes
        bx(b, (sx * (w / 4 + 0.05), 0, h + 0.7), (w / 2 + 0.3, d + 0.42, 0.12), "stone", rot=(0, sx * -0.46, 0))
    bx(b, (0, -d / 2 - 0.15, h + 1.55), (0.1, 0.1, 0.8), "iron"); bx(b, (0, -d / 2 - 0.15, h + 1.7), (0.45, 0.1, 0.1), "iron")
    front = wall_frame("front", w, d, 0.03)
    opening(b, front, -0.6, 0.6, 0.1, 2.3, "pit")                                     # the dark behind the grate
    for sx in (-1, 1):
        bx(b, (sx * 0.8, -d / 2 - 0.12, 1.2), (0.25, 0.25, 2.4), "stone")             # pilasters
    bx(b, (0, -d / 2 - 0.45, -0.05), (1.6, 0.6, 0.3), "stone")                         # a step
    wall_decal(b, wall_frame("front", w, d, 0.065), 0, 2.55, 1.6, 0.3, "umidade")
    return b


def fence_line(b, a, c, rng, gone=0.25):
    """Posts every ~2.2 m from a to c (x, y), two rails between them; `gone` of the spans have lost theirs."""
    a, c = Vector(a), Vector(c); k = max(1, int((c - a).length / 2.2))
    posts = []
    for i in range(k + 1):
        p = a + (c - a) * i / k; g = H(p.x, p.y)
        lean = (rng.uniform(-0.12, 0.12), rng.uniform(-0.12, 0.12), 0)
        bx(b, (p.x, p.y, g + 0.35), (0.12, 0.12, 1.4), "fence", rot=lean)
        posts.append(Vector((p.x, p.y, g)))
    for p, q in zip(posts, posts[1:]):
        if rng.random() < gone:
            continue  # rails gone
        yaw = math.atan2(q.y - p.y, q.x - p.x); L = (q - p).xy.length; tilt = math.atan2(q.z - p.z, L)
        for z in (0.45, 0.85):
            if z > 0.6 and rng.random() < 0.3:
                continue
            m = (p + q) / 2
            bx(b, (m.x, m.y, m.z + z), (L + 0.1, 0.05, 0.12), "fence", rot=(0, -tilt, yaw))


def fences(b):
    rng = random.Random("cercas")
    for field in FIELDS:
        for a, c in zip(field, field[1:] + field[:1]):
            fence_line(b, a, c, rng)

# Pieces every building is made of: a wall's frame, openings (doors, windows), gable roofs, decals laid
# on a wall (stains, graffiti, signs), a door nailed shut and chained.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler, noise
from vila_kit import *  # materials, mesh builder, prop pieces
from .layout import *


# --- buildings ---------------------------------------------------------------------------------------------
def wall_frame(side, w, d, e=0.03):
    """origin on a wall face, its horizontal axis u and outward normal n (u x Z = n). Front = -Y."""
    return {"front": (Vector((0, -d / 2 - e, 0)), X, -Y), "back": (Vector((0, d / 2 + e, 0)), -X, Y),
            "left": (Vector((-w / 2 - e, 0, 0)), -Y, -X), "right": (Vector((w / 2 + e, 0, 0)), Y, X)}[side]


def opening(b, frame, u0, u1, z0, z1, m, sill=False):
    o, u, n = frame
    b.poly([o + u * a + Z * c for a, c in ((u0, z0), (u1, z0), (u1, z1), (u0, z1))], m)
    if sill:
        c = o + u * (u0 + u1) / 2 + n * 0.06 + Z * (z0 - 0.04)
        size = (u1 - u0 + 0.16, 0.14, 0.06) if abs(u.x) > 0.5 else (0.14, u1 - u0 + 0.16, 0.06)
        bx(b, c, size, "planks")


def gable_roof(b, w, d, top, pitch, oh, wall, roof="roof", front=True):
    p = math.radians(pitch); rh = d / 2 * math.tan(p)
    for sx in (-1, 1):  # gable triangles
        pts = [(sx * w / 2, -d / 2, top), (sx * w / 2, 0, top + rh), (sx * w / 2, d / 2, top)]
        b.poly(pts if sx < 0 else pts[::-1], wall)
    run = d / 2 + oh; t = 0.12
    rng = random.Random(w * 100 + d)
    for s in (-1, 1):  # slabs resting on the wall tops, overhanging all round
        if s == -1 and not front:  # burnt: the front half fell in, its charred rafters left sticking out
            for k in range(7):
                x = -w / 2 + w * (k + 0.5) / 7; f = rng.uniform(0.3, 1.0)
                frustum(b, (x, 0, top + rh), (x, -run * f, top + rh - run * f * math.tan(p)), 0.05, 0.04, 4, "queimado", caps=True)
            continue
        nrm = Vector((0, s * math.sin(p), math.cos(p)))
        c = Vector((0, s * run / 2, top + rh - run / 2 * math.tan(p))) + nrm * t / 2
        bx(b, c, (w + 2 * oh, run / math.cos(p), t), roof, rot=(-s * p, 0, 0))
    bx(b, (0, 0, top + rh + 0.08), (w + 2 * oh, 0.22, 0.14), roof)  # ridge
    return rh


def wall_decal(b, frame, cu, cz, w, h, m, rot=0.0):
    """A decal on a wall face (frame from wall_frame: origin, u, outward n), centred at (cu, cz), turned by rot."""
    o, u, n = frame; pts = []
    for du, dz in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        x, z = du * w / 2, dz * h / 2
        x, z = x * math.cos(rot) - z * math.sin(rot), x * math.sin(rot) + z * math.cos(rot)
        pts.append(o + u * (cu + x) + Z * (cz + z))
    b.poly(pts, m)


def chained_door(b, w, d, door_x, plinth, rng):
    """Boarded in an X and chained from the outside, a padlock; claw marks in the wood; a red X beside it."""
    y = -d / 2 - 0.1; zc = plinth + 1.0
    for s in (-1, 1):
        bx(b, (door_x, y, zc), (1.25, 0.04, 0.16), "fence", rot=(0, s * 1.05, 0))  # weathered grey: stands out on the door
    bx(b, (door_x, y - 0.01, plinth + 1.7), (1.15, 0.04, 0.14), "fence", rot=(0, rng.uniform(-0.08, 0.08), 0))
    for k in range(10):  # chain across, a little slack
        x = door_x - 0.62 + 0.137 * k; sag = 0.06 * math.sin(math.pi * k / 9)
        bx(b, (x, y - 0.04, zc + 0.05 - sag), (0.1, 0.02, 0.05), "iron", rot=(0.0 if k % 2 else 1.57, 0, 0))
    bx(b, (door_x + 0.05, y - 0.06, zc - 0.07), (0.08, 0.035, 0.1), "iron")  # padlock
    front = wall_frame("front", w, d, 0.065)
    wall_decal(b, front, door_x, plinth + 0.9, 0.85, 1.3, "arranhoes")
    side = -1 if door_x > 0 else 1
    wall_decal(b, front, door_x + side * 1.05, plinth + 1.35, 0.55, 0.7, "picho_x", rot=rng.uniform(-0.1, 0.1))

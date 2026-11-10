import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler, noise
from vila_kit import *  # materials, mesh builder, prop pieces
from .layout import *

# --- beyond the fog (TODO_ARTE "Acabamento do cenário"): ridges of the serra with araucarias, the Colônia over its
# wall. Flat shapes with no texture: vilarejo.gd gives the silhueta_* materials an unshaded, fog-free haze shader,
# so they read through the fog as layers (the Colônia darkest, then the near ridge, the far one palest). ----------
for _n in ("silhueta_longe", "silhueta_perto", "silhueta_colonia", "silhueta_luz"):
    MATS[_n] = (bpy.data.materials.new(_n), 1.0, "plane")


def araucaria_sil(b, x, y, z, h, m, rng):
    """Paraná pine as a silhouette: a bare trunk, then flat bowls of branches stacked at the top (candelabra)."""
    frustum(b, (x, y, z), (x, y, z + h), 0.35 * h / 12, 0.18 * h / 12, 4, m)
    for t, r in ((0.72, 0.30), (0.84, 0.36), (0.95, 0.26)):
        c = z + h * t; R_ = h * r * rng.uniform(0.8, 1.15)
        frustum(b, (x, y, c - h * 0.04), (x, y, c + h * 0.05), R_ * 0.25, R_, 7, m, caps=True)


def ridge(name, R, top, base, trees, seed):
    """A ring of hills round the valley: a band from `base` up to a ridge line between top[0] and top[1] m."""
    rng = random.Random(seed); b = B(); N = 180; c = Vector((0, 15))
    pts = []
    for i in range(N + 1):
        a = 2 * math.pi * (i % N) / N; q = Vector((math.cos(a), math.sin(a), seed * 0.1))
        r = R * (1 + 0.06 * noise.noise(q * 2.5))
        k = 0.5 + 0.5 * max(-1.0, min(1.0, noise.fractal(q * 1.8 + Vector((seed, 0, 0)), 1.0, 2.0, 3)))
        pts.append(Vector((c.x + r * math.cos(a), c.y + r * math.sin(a), top[0] + (top[1] - top[0]) * k)))
    for p, q in zip(pts, pts[1:]):
        b.poly([(p.x, p.y, base), (q.x, q.y, base), (q.x, q.y, q.z), (p.x, p.y, p.z)], name)
        if rng.random() < trees:
            s_ = p.lerp(q, rng.random())
            araucaria_sil(b, s_.x, s_.y, s_.z - 1.5, rng.uniform(10, 18), name, rng)
    obj(b, name)


def gable(b, cx, cy, yaw, w, d, z0, h, rh, m):
    """A block with a gable roof (ridge along its x), turned by yaw degrees, sunk 6 m so the slope never shows under it."""
    M = Matrix.LocRotScale(Vector((cx, cy, 0)), Euler((0, 0, math.radians(yaw))), None)
    bx(b, M @ Vector((0, 0, z0 + h / 2 - 3)), (w, d, h + 6), m, rot=(0, 0, math.radians(yaw)))
    for sy in (-1, 1):
        b.poly([M @ Vector(p) for p in ((-w / 2 - 0.4, sy * (d / 2 + 0.4), z0 + h), (w / 2 + 0.4, sy * (d / 2 + 0.4), z0 + h),
                                        (w / 2 + 0.4, 0, z0 + h + rh), (-w / 2 - 0.4, 0, z0 + h + rh))], m)
    for sx in (-1, 1):
        b.poly([M @ Vector(p) for p in ((sx * w / 2, -d / 2, z0 + h), (sx * w / 2, d / 2, z0 + h), (sx * w / 2, 0, z0 + h + rh))], m)


def pyramid(b, cx, cy, z, half, h, m):
    q = [(cx - half, cy - half), (cx + half, cy - half), (cx + half, cy + half), (cx - half, cy + half)]
    for p0, p1 in zip(q, q[1:] + q[:1]):
        b.poly([(p0[0], p0[1], z), (p1[0], p1[1], z), (cx, cy, z + h)], m)


def colony():
    """The Colônia over its wall, the road's goal: two pavilions (the first with its clock tower), the boiler house's
    chimney, a watchtower by the gate. A light burns in the watchtower's window and one in the clock tower."""
    b = B(); lit = B(); m = "silhueta_colonia"; g = lambda x, y: valley(x, y) - 0.5
    gable(b, -12, 84, 0, 36, 11, g(-12, 84), 8.5, 3.2, m)
    tz = g(-12, 84) + 8.5
    bx(b, (-12, 84, tz + 3.5), (5, 5, 7), m); pyramid(b, -12, 84, tz + 7, 2.8, 3.5, m)  # clock tower over the middle
    lit.poly([(-12.5, 81.45, tz + 4.2), (-11.5, 81.45, tz + 4.2), (-11.5, 81.45, tz + 5.4), (-12.5, 81.45, tz + 5.4)], "silhueta_luz")
    gable(b, 21, 93, 8, 28, 10, g(21, 93), 7.0, 2.6, m)
    gable(b, -33, 86, 0, 9, 7, g(-33, 86), 5, 2, m)  # the usina, and its chimney
    frustum(b, (-33, 92, g(-33, 92) - 2), (-33, 92, g(-33, 92) + 27), 1.5, 1.0, 6, m, caps=True)
    wx, wy = 8.5, 68.5; wz = g(wx, wy)  # watchtower by the gate: four legs, cabin, pyramid roof
    for sx in (-1, 1):
        for sy in (-1, 1):
            frustum(b, (wx + sx * 1.9, wy + sy * 1.9, wz - 1), (wx + sx * 1.5, wy + sy * 1.5, wz + 12), 0.25, 0.2, 4, m, caps=True)
    bx(b, (wx, wy, wz + 13.5), (4.2, 4.2, 3.0), m); pyramid(b, wx, wy, wz + 15, 2.5, 2.5, m)
    lit.poly([(wx - 0.5, wy - 2.12, wz + 13.2), (wx + 0.5, wy - 2.12, wz + 13.2), (wx + 0.5, wy - 2.12, wz + 14.0), (wx - 0.5, wy - 2.12, wz + 14.0)], "silhueta_luz")
    rng = random.Random("colonia/arvores")
    for x, y in ((-36, 78), (3, 88), (36, 84), (-24, 98), (12, 102)):
        araucaria_sil(b, x, y, g(x, y) - 1, rng.uniform(13, 19), m, rng)
    obj(b, "colonia_silhueta"); obj(lit, "colonia_luzes")

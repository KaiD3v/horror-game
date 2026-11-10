# The ground and what grows on it: the terrain mesh, dead trees, rocks, vegetation (araucarias, stumps,
# logs, bushes, grass, ferns).
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler, noise
from vila_kit import *  # materials, mesh builder, prop pieces
from .layout import *
from .objetos import kit, place


# --- terrain: 150 x 150 m, 1.5 m grid; mud on the roads and the square, rock on the steep hills -----------
def terrain():
    b = B(); S, N = 150.0, 100; st = S / N
    hs = [[H(-S / 2 + i * st, -S / 2 + j * st) for i in range(N + 1)] for j in range(N + 1)]
    for j in range(N):
        for i in range(N):
            x0, y0 = -S / 2 + i * st, -S / 2 + j * st
            q = [(x0, y0, hs[j][i]), (x0 + st, y0, hs[j][i + 1]), (x0 + st, y0 + st, hs[j + 1][i + 1]), (x0, y0 + st, hs[j + 1][i])]
            nz = (Vector(q[1]) - Vector(q[0])).cross(Vector(q[3]) - Vector(q[0])).normalized().z
            cx, cy = x0 + st / 2, y0 + st / 2
            m = "mud" if road_dist(cx, cy) < 2.4 else "rock" if nz < 0.82 else "grass"
            b.poly(q, m)
    return obj(b, "terreno-col")


# --- dead trees: crooked recursive branches, 4 variants, instanced ---------------------------------------
def tree_mesh(seed):
    rng = random.Random(seed); b = B()

    def turn(d, lo, hi):
        p = d.orthogonal().normalized(); p.rotate(Matrix.Rotation(rng.uniform(0, 2 * math.pi), 3, d))
        return (Matrix.Rotation(math.radians(rng.uniform(lo, hi)), 3, p) @ d).normalized()

    def branch(p, d, L, r, depth):
        mid = p + d * L * 0.5
        d2 = (turn(d, 8, 22) + Vector((0, 0, rng.uniform(-0.15, 0.1)))).normalized()
        end = mid + d2 * L * 0.5
        n = 5 if r > 0.12 else 4 if r > 0.05 else 3
        if depth == 0:
            frustum(b, p, end, r, 0, 3, "bark"); return
        frustum(b, p, mid, r, r * 0.8, n, "bark"); frustum(b, mid, end, r * 0.8, r * 0.6, n, "bark")
        for i in range(rng.choice((2, 2, 3))):
            dd = turn(d2, 25, 55)
            if dd.z < -0.3:
                dd = (dd + Vector((0, 0, 0.5))).normalized()
            branch(end, dd, L * rng.uniform(0.55, 0.72), r * 0.58, depth - 1)
        if depth >= 2 and rng.random() < 0.7:  # a side branch off the middle
            branch(mid, turn(d, 50, 80), L * 0.5, r * 0.45, depth - 2)

    branch(Vector((0, 0, -0.4)), Vector((rng.uniform(-0.1, 0.1), rng.uniform(-0.1, 0.1), 1)).normalized(),
           rng.uniform(3.6, 5.2), rng.uniform(0.2, 0.3), 3)
    return b


def trees(colliders):
    meshes = [obj(tree_mesh(s), "arvore_%d" % s).data for s in range(4)]
    for o in [o for o in bpy.data.objects if o.name.startswith("arvore_")]:
        bpy.data.objects.remove(o)
    rng = random.Random("arvores"); placed = []
    tries = 0
    while len(placed) < 85 and tries < 6000:
        tries += 1
        x, y = rng.uniform(-70, 70), rng.uniform(-70, 66)
        r = (x ** 4 + y ** 4) ** 0.25
        if r < 40 and rng.random() < 0.72:
            continue  # sparse in the village, thick on the hills
        if road_dist(x, y) < 4.0 or any(abs(local(x, y, px, py, yaw)[0]) < hw + 2 and abs(local(x, y, px, py, yaw)[1]) < hd + 2
                                         for px, py, yaw, hw, hd, _ in PADS):
            continue
        if abs(y - WALL_Y) < 2.5 or any((Vector((x, y)) - q).length < 4.5 for q in placed):
            continue
        placed.append(Vector((x, y)))
        o = bpy.data.objects.new("arvore", rng.choice(meshes)); bpy.context.collection.objects.link(o)
        g = H(x, y); s = rng.uniform(0.8, 1.35)
        o.location = (x, y, g); o.rotation_euler.z = rng.uniform(0, 2 * math.pi); o.scale = (s, s, s)
        frustum(colliders, (x, y, g - 0.5), (x, y, g + 3.0), 0.3 * s, 0.2 * s, 6, "bark", caps=True)
    return placed


def rocks(b):
    rng = random.Random("pedras")
    for _ in range(26):
        a = rng.uniform(0, 2 * math.pi); r = rng.uniform(47, 70)
        x, y = r * math.cos(a), min(r * math.sin(a), WALL_Y - 4)
        if road_dist(x, y) < 5:
            continue
        bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
        s = Vector((rng.uniform(1.2, 2.8), rng.uniform(1.0, 2.2), rng.uniform(0.8, 1.6)))
        M = Matrix.LocRotScale(Vector((x, y, H(x, y) + 0.1)), Euler((0, 0, rng.uniform(0, 3))), s)
        for f in bm.faces:
            b.poly([M @ (v.co * rng.uniform(0.85, 1.1)) for v in f.verts], "rock")
        bm.free()


# --- vegetation round the village (vila_kit veg pieces): araucarias on the hills, stumps and fallen logs (solid,
# instanced), dry bushes (instanced, you push through), tall dry grass and fern clumps (merged into one mesh each)
def vegetation(trees_at):
    rng = random.Random("vegetacao")

    def free(x, y, road=2.6, pad=0.5):
        if abs(x) > 72 or not -72 < y < WALL_Y - 1.5 or road_dist(x, y) < road:
            return False
        for px, py, yaw, hw, hd, _ in PADS:
            lx, ly = local(x, y, px, py, yaw)
            if abs(lx) < hw + pad and abs(ly) < hd + pad:
                return False
        return True

    def in_field(x, y):
        return any(min(p[0] for p in f) < x < max(p[0] for p in f) and min(p[1] for p in f) < y < max(p[1] for p in f) for f in FIELDS)

    rim = lambda x, y: (x ** 4 + y ** 4) ** 0.25
    big = list(trees_at)

    def spaced(x, y, d):
        return all((Vector((x, y)) - q).length > d for q in big)

    kit("araucaria_morta", k_araucaria(1, False)); kit("araucaria_seca", k_araucaria(2, True))
    for k in range(3):
        kit("arbusto_%d" % k, k_arbusto(k))
    kit("toco_0", k_toco(0)); kit("toco_1", k_toco(1)); kit("tronco", k_tronco(0))
    counts = {}

    def scatter(name, n, test, d, **kw):
        got = tries = 0
        while got < n and tries < 6000:
            tries += 1
            x, y = rng.uniform(-68, 68), rng.uniform(-68, WALL_Y - 3)
            if test(x, y) and spaced(x, y, d):
                k = name(got) if callable(name) else name
                place(k, x, y, rng.uniform(0, 360), **kw); big.append(Vector((x, y))); got += 1
        counts[name if isinstance(name, str) else name(0).rsplit("_", 1)[0]] = got

    scatter(lambda i: "araucaria_seca" if i % 3 == 0 else "araucaria_morta", 9,
            lambda x, y: 34 < rim(x, y) < 64 and free(x, y, 4, 2), 7, dz=-0.1)
    scatter(lambda i: "toco_%d" % (i % 2), 12, lambda x, y: free(x, y, 3, 1), 3, dz=-0.05)
    scatter("tronco", 5, lambda x, y: rim(x, y) > 36 and free(x, y, 4, 1.5), 4, dz=-0.05)
    scatter(lambda i: "arbusto_%d" % (i % 3), 40,
            lambda x, y: free(x, y, 2.8, 0.3) and rng.random() < (0.7 if rim(x, y) > 38 else 0.3), 1.6, dz=-0.05, col=False)

    grass, kinds, got = B(), [k_capim(s) for s in range(4)], 0
    while got < 520:
        x, y = rng.uniform(-70, 70), rng.uniform(-70, WALL_Y - 2)
        p = 1.0 if in_field(x, y) else 0.55 if rim(x, y) > 40 else 0.22
        if rng.random() < p and free(x, y, 2.4, 0.15):
            merge(grass, rng.choice(kinds), x, y, H(x, y), rng.uniform(0, 360), rng.uniform(0.8, 1.3)); got += 1
    obj(grass, "capim")
    ferns, kinds, got = B(), [k_samambaia(s) for s in range(3)], 0
    while got < 70:  # in the shelter of trees, stumps and rocks
        q = rng.choice(big); a = rng.uniform(0, 2 * math.pi); d = rng.uniform(0.8, 2.8)
        x, y = q.x + d * math.cos(a), q.y + d * math.sin(a)
        if free(x, y, 2.4, 0.2):
            merge(ferns, rng.choice(kinds), x, y, H(x, y), rng.uniform(0, 360), rng.uniform(0.8, 1.4)); got += 1
    obj(ferns, "samambaias")
    counts.update(capim=520, samambaia=70)
    return counts

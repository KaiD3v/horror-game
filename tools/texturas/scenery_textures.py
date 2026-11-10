# Tileable N64-style scenery textures for the Colônia Santa Clara (godot_demo/colonia.gd) and the demo room.
# Run with plain Python (numpy + Pillow): writes godot_demo/textures/*.png and a preview sheet.
# Small, hand-made-looking textures sampled with nearest filtering, like the character's 32 px grime;
# every texture tiles seamlessly (all noise and strokes wrap around the edges).
import os
import numpy as np
from PIL import Image

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
OUT = paths.TEXTURES
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1974)


def vnoise(n, cells):
    """Periodic value noise in [0, 1], n x n, `cells` lattice cells across (smoothstep-interpolated)."""
    g = rng.random((cells, cells))
    x = np.arange(n) * cells / n
    i0 = np.floor(x).astype(int); i1 = (i0 + 1) % cells
    t = x - i0; t = t * t * (3 - 2 * t)
    a = g[np.ix_(i0, i0)]; b = g[np.ix_(i0, i1)]; c = g[np.ix_(i1, i0)]; d = g[np.ix_(i1, i1)]
    ty, tx = t[:, None], t[None, :]
    return (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty


def fbm(n, cells=(4, 8, 16), weights=(0.55, 0.3, 0.15)):
    return sum(w * vnoise(n, c) for c, w in zip(cells, weights))


def base(n, col, var=0.06):
    img = np.ones((n, n, 3)) * np.array(col)
    return img * (1 - var + var * 2 * fbm(n))[:, :, None]


def grain(img, amount=0.05):
    return img * (1 - amount + amount * rng.random(img.shape[:2]))[:, :, None]


def blob(img, cx, cy, r, col=None, mul=None, soft=False):
    """Wrapped disc: paints `col` or multiplies by `mul` (rgb tuple or scalar)."""
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    dx = np.minimum(abs(xx - cx), w - abs(xx - cx)); dy = np.minimum(abs(yy - cy), h - abs(yy - cy))
    d = np.sqrt(dx * dx + dy * dy) / r
    m = d <= 1
    a = np.clip(1 - d, 0, 1)[:, :, None] if soft else m[:, :, None]
    if col is not None:
        img[:] = img * (1 - a) + np.array(col) * a
    else:
        img[:] = img * (1 - a + a * np.array(mul))


def walk(img, x, y, steps, col, bias=(0.0, 1.0), wobble=0.7):
    """Wrapped random-walk stroke (cracks, streaks, grain)."""
    h, w = img.shape[:2]
    for _ in range(steps):
        img[int(y) % h, int(x) % w] = col
        x += bias[0] + rng.uniform(-wobble, wobble); y += bias[1] + rng.uniform(-wobble * 0.3, wobble * 0.3)


def save(name, img):
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, name + ".png"))
    return name


T = {}

# walls are 128 px over 2 m (same texel size as the rest) so their stains and chips do not repeat every metre
N = 128
# plaster: dirty cream, water stains running down, hairline cracks, a few peeled patches (brick-grey under)
img = base(N, (0.60, 0.57, 0.49), 0.10)
for _ in range(16):
    x = rng.integers(N); y0 = rng.integers(N)
    for k in range(rng.integers(14, 34)):  # rust/water streak, fading downwards (rows grow downwards in images)
        for w in range(rng.integers(1, 3)):
            img[(y0 + k) % N, (x + w) % N] *= 0.90 - 0.06 * (k < 4)
for _ in range(5):
    walk(img, rng.integers(N), rng.integers(N), rng.integers(18, 40), img[0, 0] * 0.6, bias=(rng.uniform(-0.4, 0.4), 1), wobble=0.4)
for _ in range(4):  # peeled patches: a few overlapping bites, darker rim
    cx, cy = rng.integers(N), rng.integers(N)
    bites = [(cx + rng.integers(-3, 4), cy + rng.integers(-2, 3), rng.uniform(1.2, 2.6)) for _ in range(4)]
    for bx, by, r in bites:
        blob(img, bx, by, r + 0.9, mul=0.84)
    for bx, by, r in bites:
        blob(img, bx, by, r, col=(0.47, 0.40, 0.34))
T["plaster"] = save("plaster", grain(img))

# hospital green paint (lower wall): chipped to the plaster, scuffed
img = base(N, (0.21, 0.31, 0.25), 0.10)
for _ in range(26):
    cx, cy = rng.integers(N), rng.integers(N); r = rng.uniform(0.8, 2.6)
    blob(img, cx, cy, r, col=(0.56, 0.53, 0.45))
for _ in range(16):  # scuffs and shoe marks
    walk(img, rng.integers(N), rng.integers(N), rng.integers(4, 10), (0.13, 0.17, 0.14), bias=(1, 0.1), wobble=0.4)
T["paint_green"] = save("paint_green", grain(img))

# hydraulic floor tiles ("ladrilho hidráulico"): 4x4 cement tiles of 16 px. Corner triangles meet the
# neighbours' into oxblood diamonds, a grey-green diamond in each centre, a thin inset border; worn, chipped
img = np.zeros((64, 64, 3))
CREAM, OX, SAGE = np.array((0.58, 0.54, 0.46)), np.array((0.44, 0.21, 0.17)), np.array((0.33, 0.37, 0.33))
yy, xx = np.mgrid[0:16, 0:16]
t = np.ones((16, 16, 3)) * CREAM
for cx in (0, 15):
    for cy in (0, 15):
        t[abs(xx - cx) + abs(yy - cy) < 6] = OX
c = abs(xx - 7.5) + abs(yy - 7.5)
t[c < 4.6] = SAGE
t[(c >= 4.6) & (c < 5.6)] = OX
t[(xx == 2) | (xx == 13) | (yy == 2) | (yy == 13)] = np.where(
    (abs(xx - 7.5) + abs(yy - 7.5) < 11)[:, :, None], t, CREAM * 0.8)[(xx == 2) | (xx == 13) | (yy == 2) | (yy == 13)]
for ty in range(4):
    for tx in range(4):
        img[ty * 16:(ty + 1) * 16, tx * 16:(tx + 1) * 16] = t * rng.uniform(0.92, 1.06)
img *= (0.86 + 0.24 * fbm(64, (2, 4, 8)))[:, :, None]   # wear: polished and dull patches
img[0::16, :] = (0.16, 0.15, 0.13); img[:, 0::16] = (0.16, 0.15, 0.13)  # grout
for _ in range(5):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(1, 2.5), col=(0.22, 0.20, 0.17))
T["tiles"] = save("tiles", grain(img, 0.06))

# yard dirt: packed earth, damp patches, pebbles, dead grass
img = base(64, (0.22, 0.19, 0.15), 0.25)
for _ in range(40):
    p = (rng.integers(64), rng.integers(64)); img[p[1], p[0]] = np.array((0.38, 0.35, 0.31)) * rng.uniform(0.8, 1.1)
for _ in range(16):
    walk(img, rng.integers(64), rng.integers(64), rng.integers(2, 5), (0.36, 0.32, 0.17), bias=(0.3, -1), wobble=0.5)
T["dirt"] = save("dirt", grain(img, 0.08))

# planks: four boards, grain, seams, knots (doors, benches, tables, pews, boarding)
img = np.zeros((64, 64, 3))
for b in range(4):
    tone = rng.uniform(0.85, 1.1)
    board = np.ones((16, 64, 3)) * np.array((0.30, 0.19, 0.11)) * tone
    for gy in range(16):
        board[gy] *= 1 + 0.10 * np.sin(np.arange(64) * 2 * np.pi / 64 * rng.integers(1, 3) + gy * 0.9)[:, None]
    for _ in range(4):
        walk(board, rng.integers(64), rng.integers(16), 40, np.array((0.20, 0.12, 0.07)) * tone, bias=(1, 0), wobble=0.25)
    if rng.random() < 0.6:
        blob(board, rng.integers(64), rng.integers(4, 12), 2.2, col=np.array((0.16, 0.10, 0.06)))
    board[0] = (0.09, 0.06, 0.04)
    img[b * 16:(b + 1) * 16] = board
T["planks"] = save("planks", grain(img, 0.07))

# ceiling boards ("forro"): narrow dark boards with damp stains
img = base(64, (0.17, 0.13, 0.10), 0.12)
img[::8] = (0.07, 0.05, 0.04)
for _ in range(3):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(5, 9), mul=(0.75, 0.78, 0.8), soft=True)
T["ceiling"] = save("ceiling", grain(img, 0.06))

# chipped white enamel over rusting steel (beds' frames, cabinets, operating table, gurney)
img = base(64, (0.60, 0.61, 0.57), 0.08)
for _ in range(7):  # a few chips, rust in them, a stained halo around
    cx, cy = rng.integers(64), rng.integers(64); r = rng.uniform(0.7, 1.8)
    blob(img, cx, cy, r + 1.5, mul=(0.88, 0.84, 0.78), soft=True); blob(img, cx, cy, r, col=(0.40, 0.22, 0.12))
for _ in range(6):
    x = rng.integers(64); y = rng.integers(64)
    for k in range(rng.integers(6, 16)):
        img[(y + k) % 64, x] *= (0.85, 0.72, 0.62)  # rust runs
T["enamel"] = save("enamel", grain(img, 0.05))

# old green machinery paint (generator, furnace door), rust at the edges of chips
img = base(64, (0.24, 0.29, 0.24), 0.12)
for _ in range(12):
    cx, cy = rng.integers(64), rng.integers(64); r = rng.uniform(1, 3.5)
    blob(img, cx, cy, r, col=(0.33, 0.20, 0.12))
T["machine"] = save("machine", grain(img, 0.06))

# stained hospital linen (mattresses, folding screens)
img = base(64, (0.58, 0.57, 0.52), 0.06)
for _ in range(4):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(4, 8), mul=(0.92, 0.84, 0.66), soft=True)  # old stains
blob(img, rng.integers(64), rng.integers(64), 3.5, mul=(0.75, 0.52, 0.45), soft=True)                   # a dried one
for _ in range(6):  # creases
    walk(img, rng.integers(64), rng.integers(64), rng.integers(12, 30), img[5, 5] * 0.85, bias=(1, rng.uniform(-0.3, 0.3)), wobble=0.3)
T["linen"] = save("linen", grain(img, 0.04))

# stone blocks with mortar (well, bandstand base, altar, furnace)
img = np.zeros((64, 64, 3))
rows = [0, 14, 30, 46, 64]
for i in range(4):
    off = 0 if i % 2 == 0 else 13
    xs = [0, 21, 44, 64]
    for j in range(3):
        tone = rng.uniform(0.8, 1.15)
        y0, y1 = rows[i], rows[i + 1]; x0, x1 = xs[j], xs[j + 1]
        for y in range(y0, y1):
            for x in range(x0, x1):
                img[y, (x + off) % 64] = np.array((0.36, 0.35, 0.33)) * tone
img *= (0.85 + 0.3 * fbm(64, (4, 8, 16)))[:, :, None]
for r in rows[:-1]:
    img[r] = (0.18, 0.17, 0.16)
for i in range(4):
    off = 0 if i % 2 == 0 else 13
    for x in (0, 21, 44):
        img[rows[i]:rows[i + 1], (x + off) % 64] = (0.18, 0.17, 0.16)
T["stone"] = save("stone", grain(img, 0.07))

# bark: dark vertical ridges
img = base(64, (0.19, 0.15, 0.12), 0.15)
for _ in range(18):
    walk(img, rng.integers(64), rng.integers(64), rng.integers(20, 50), (0.09, 0.07, 0.06), bias=(0, 1), wobble=0.6)
for _ in range(8):
    walk(img, rng.integers(64), rng.integers(64), rng.integers(10, 30), (0.30, 0.26, 0.21), bias=(0, 1), wobble=0.5)
T["bark"] = save("bark", grain(img, 0.07))

# peeling white paint on wood (bandstand columns and roof)
img = base(64, (0.62, 0.60, 0.54), 0.08)
for _ in range(10):
    cx, cy = rng.integers(64), rng.integers(64)
    for k in range(rng.integers(6, 14)):  # long peels along the grain
        blob(img, (cx + k) % 64, cy, rng.uniform(0.8, 1.8), col=(0.27, 0.18, 0.11))
T["painted_wood"] = save("painted_wood", grain(img, 0.05))

# ---------------- Vila de Santa Clara (vilarejo_build.py, docs/VILAREJO.md) ----------------
# dead grass ("capim seco"): olive-brown with straw blades and darker tufts; 64 px over 2 m
img = base(64, (0.27, 0.25, 0.16), 0.22)
img *= (0.8 + 0.4 * fbm(64, (2, 4, 8)))[:, :, None]
for _ in range(70):
    walk(img, rng.integers(64), rng.integers(64), rng.integers(2, 5),
         np.array((0.46, 0.40, 0.24)) * rng.uniform(0.8, 1.15), bias=(rng.uniform(-0.4, 0.4), -1), wobble=0.3)
for _ in range(40):
    walk(img, rng.integers(64), rng.integers(64), rng.integers(2, 4), (0.15, 0.14, 0.09), bias=(0, -1), wobble=0.3)
T["grass"] = save("grass", grain(img, 0.08))

# road mud: wet dark earth, puddles reflecting the grey sky, stones
img = base(64, (0.20, 0.16, 0.12), 0.20)
for _ in range(2):
    cx, cy = rng.integers(64), rng.integers(64); r = rng.uniform(2.5, 4)
    blob(img, cx, cy, r + 1.5, mul=0.8, soft=True)
    blob(img, cx, cy, r, col=(0.19, 0.19, 0.19))
for _ in range(30):
    p = (rng.integers(64), rng.integers(64)); img[p[1], p[0]] = np.array((0.34, 0.31, 0.27)) * rng.uniform(0.8, 1.1)
T["mud"] = save("mud", grain(img, 0.08))

# clay roof tiles ("telha capa-canal"): columns running down the slope, 4 across x 2 long tiles (32 px) in the
# 64 px tile; capa (convex, lit) and canal (concave, shaded) alternate, each tile's lip shades the one below;
# black lichen and moss
img = np.zeros((64, 64, 3))
x = np.arange(16)
for r in range(2):
    for c in range(4):
        tone = np.array((0.50, 0.26, 0.17)) * rng.uniform(0.82, 1.12)
        prof = 0.6 + 0.55 * np.sin(np.pi * (x + 0.5) / 16) if c % 2 == 0 else 0.95 - 0.45 * np.sin(np.pi * (x + 0.5) / 16)
        tile = np.ones((32, 16, 3)) * tone * prof[None, :, None]
        tile[29:] *= 0.85; tile[31] *= 0.5   # lip of this tile
        tile[0:3] *= 0.65                    # shadow of the tile above
        img[r * 32:(r + 1) * 32, c * 16:(c + 1) * 16] = tile
img *= (0.85 + 0.3 * fbm(64, (2, 4, 8)))[:, :, None]
for _ in range(9):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(1.5, 4), mul=(0.55, 0.55, 0.5), soft=True)  # lichen
for _ in range(5):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(1.5, 3), mul=(0.7, 0.85, 0.55), soft=True)  # moss
T["roof_tiles"] = save("roof_tiles", grain(img, 0.06))

# whitewash ("caiação") over adobe: dirty white, grime streaks from the eaves, bites showing the earth wall
img = base(N, (0.66, 0.65, 0.60), 0.08)
for _ in range(22):
    x0 = rng.integers(N); y0 = rng.integers(N)
    for k in range(rng.integers(16, 44)):
        img[(y0 + k) % N, x0 % N] *= 0.88; img[(y0 + k) % N, (x0 + 1) % N] *= 0.93
for _ in range(3):
    cx, cy = rng.integers(N), rng.integers(N)
    bites = [(cx + rng.integers(-4, 5), cy + rng.integers(-3, 4), rng.uniform(1.0, 2.4)) for _ in range(4)]
    for bx, by, r in bites:
        blob(img, bx, by, r + 1.0, mul=0.9)
    for bx, by, r in bites:
        blob(img, bx, by, r, col=np.array((0.44, 0.37, 0.30)) * rng.uniform(0.9, 1.1))
for _ in range(4):
    walk(img, rng.integers(N), rng.integers(N), rng.integers(20, 50), img[3, 3] * 0.62, bias=(rng.uniform(-0.5, 0.5), 1), wobble=0.45)
T["whitewash"] = save("whitewash", grain(img, 0.05))

# vertical board siding ("tábua e mata-junta"): grey weathered boards, narrow battens over the seams
img = np.zeros((64, 64, 3))
for b in range(4):
    tone = rng.uniform(0.85, 1.12)
    board = np.ones((64, 16, 3)) * np.array((0.36, 0.32, 0.27)) * tone
    for _ in range(5):
        walk(board, rng.integers(16), rng.integers(64), 50, np.array((0.25, 0.22, 0.18)) * tone, bias=(0, 1), wobble=0.2)
    if rng.random() < 0.5:
        blob(board, rng.integers(4, 12), rng.integers(64), 1.8, col=(0.15, 0.12, 0.10))
    board[:, 0:3] = np.array((0.42, 0.38, 0.32)) * tone; board[:, 3] = (0.12, 0.10, 0.08)  # batten and its shadow
    img[:, b * 16:(b + 1) * 16] = board
img *= (0.85 + 0.25 * fbm(64, (2, 4, 8)))[:, :, None]
T["siding"] = save("siding", grain(img, 0.06))

# window (fit to the window quad): wooden frame and muntins, 2 x 3 dark panes, one broken
img = np.ones((40, 32, 3)) * np.array((0.42, 0.40, 0.35))
for i, (y0, y1) in enumerate(((3, 14), (15, 26), (27, 37))):
    for j, (x0, x1) in enumerate(((3, 15), (17, 29))):
        pane = np.ones((y1 - y0, x1 - x0, 3)) * np.array((0.08, 0.09, 0.10))
        pane[1:3, 1:4] = (0.30, 0.32, 0.33)  # a glint of the sky
        if (i, j) == (1, 0):  # broken: shards round the edge, black hole in the middle
            pane[:] = (0.01, 0.01, 0.01); pane[0:3, :] = (0.16, 0.17, 0.18); pane[:, 0:2] = (0.16, 0.17, 0.18)
        img[y0:y1, x0:x1] = pane
img *= (0.9 + 0.2 * rng.random((40, 32)))[:, :, None]
T["window"] = save("window", img)

# shutter ("veneziana", fit to the window quad): two leaves of slats, peeling paint (tinted per house)
img = np.ones((40, 32, 3)) * 0.7
img[1::3] *= 0.55; img[2::3] *= 0.8                       # slats
img[:, 15:17] = 0.3; img[:, 0:2] = 0.45; img[:, 30:] = 0.45; img[0:2] = 0.45; img[38:] = 0.45
for _ in range(10):
    blob(img, rng.integers(32), rng.integers(40), rng.uniform(0.8, 2.0), col=(0.30, 0.22, 0.15))
T["shutter"] = save("shutter", grain(img, 0.06))

# door (fit to the door quad): vertical planks, Z brace, iron latch, dirt kicked up the bottom
img = np.zeros((64, 32, 3))
for b in range(4):
    img[:, b * 8:(b + 1) * 8] = np.array((0.32, 0.22, 0.14)) * rng.uniform(0.85, 1.1)
    img[:, b * 8] = (0.10, 0.07, 0.05)
for y in (8, 54):
    img[y:y + 4] = (0.27, 0.18, 0.11); img[y + 4] = (0.10, 0.07, 0.05)
for k in range(42):  # diagonal brace
    yy = 12 + k; xx = int(2 + k * 27 / 42)
    img[yy, xx:xx + 4] = (0.27, 0.18, 0.11)
img[30:34, 25:28] = (0.12, 0.12, 0.12)
img[52:] *= np.linspace(1, 0.6, 12)[:, None, None]
T["door"] = save("door", grain(img, 0.06))

# rock outcrops on the hills: grey-brown, cracks, lichen
img = base(64, (0.33, 0.31, 0.28), 0.18)
img *= (0.75 + 0.45 * fbm(64, (3, 6, 12)))[:, :, None]
for _ in range(10):
    walk(img, rng.integers(64), rng.integers(64), rng.integers(10, 30), (0.14, 0.13, 0.12), bias=(rng.uniform(-1, 1), 1), wobble=0.6)
for _ in range(8):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(1, 3), mul=(0.85, 0.9, 0.7), soft=True)
T["rock"] = save("rock", grain(img, 0.08))

# ---------------- village props (vilarejo_build.py kit) ----------------
# faded cotton (clothesline, scarecrow, the cross's cloth; tinted per use): weave, faint stripes, old stains
img = base(64, (0.66, 0.64, 0.58), 0.06)
img[:, ::2] *= 0.96; img[::2] *= 0.97
for x0 in range(0, 64, 16):
    img[:, x0:x0 + 2] *= 0.88
for _ in range(4):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(4, 9), mul=(0.9, 0.84, 0.7), soft=True)
T["cloth"] = save("cloth", grain(img, 0.05))

# burlap (the scarecrow's sack head): coarse brown weave
img = base(64, (0.42, 0.33, 0.21), 0.10)
img[::3] *= 0.75; img[:, ::3] *= 0.8
for _ in range(3):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(3, 6), mul=0.75, soft=True)
T["burlap"] = save("burlap", grain(img, 0.08))

# hay (haystacks, the scarecrow's hat): yellow-grey straw strokes, rotting darker in places
img = base(64, (0.50, 0.43, 0.25), 0.15)
for _ in range(140):
    walk(img, rng.integers(64), rng.integers(64), rng.integers(3, 8),
         np.array((0.66, 0.57, 0.33)) * rng.uniform(0.75, 1.1), bias=(rng.uniform(-0.6, 0.6), 1), wobble=0.25)
for _ in range(5):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(3, 7), mul=(0.7, 0.68, 0.62), soft=True)
T["hay"] = save("hay", grain(img, 0.07))

# painted signs (fit to the sign's face): dark boards, chipped off-white hand lettering, crisp 1-bit text
from PIL import ImageDraw, ImageFont


def sign(name, text, w, h, size):
    img = np.ones((h, w, 3)) * np.array((0.24, 0.19, 0.14))
    img *= (0.85 + 0.25 * vnoise(max(w, h), 8)[:h, :w])[:, :, None]
    for y in range(0, h, max(4, h // 3)):
        img[y] *= 0.6  # board seams
    mask = Image.new("1", (w, h)); d = ImageDraw.Draw(mask); d.fontmode = "1"
    f = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", size)
    tw, th = d.textbbox((0, 0), text, font=f)[2:]
    d.text(((w - tw) // 2, (h - th) // 2 - 1), text, font=f, fill=1)
    m = np.array(mask, dtype=bool) & (rng.random((h, w)) > 0.18)  # chipped paint
    img[m] = np.array((0.70, 0.67, 0.58)) * rng.uniform(0.85, 1.0, (m.sum(), 1))
    T[name] = save(name, grain(img, 0.06))


sign("sign_vila", "VILA DE SANTA CLARA", 160, 40, 13)
sign("sign_colonia", "COLÔNIA  >", 80, 20, 10)
sign("sign_cemiterio", "< CEMITÉRIO", 80, 20, 10)
sign("sign_venda", "SECOS E MOLHADOS", 160, 40, 14)
sign("sign_armaria", "ARMAS E MUNIÇÃO", 160, 40, 14)
sign("sign_particular", "PARTICULAR", 80, 20, 9)


def paper(name, w, h, draw):
    """Aged paper (fit to a quad), dark 1-bit ink drawn by draw(ImageDraw, font_big, font_small)."""
    img = np.ones((h, w, 3)) * np.array((0.74, 0.70, 0.60))
    img *= (0.88 + 0.12 * vnoise(max(w, h), 6)[:h, :w])[:, :, None]
    for _ in range(3):
        blob(img, rng.integers(w), rng.integers(h), rng.uniform(3, 7), mul=(0.92, 0.85, 0.7), soft=True)
    ink = Image.new("1", (w, h)); d = ImageDraw.Draw(ink); d.fontmode = "1"
    draw(d, ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 8), ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 7))
    m = np.array(ink, dtype=bool)
    img[m] = (0.16, 0.13, 0.12)
    T[name] = save(name, grain(img, 0.05))


def procura(d, fb, fs):  # missing-person notice: header, a dim photo, lines of handwriting
    d.text((4, 3), "PROCURA-SE", font=fb, fill=1)
    d.rectangle((14, 15, 49, 52), outline=1)
    for y in range(58, 76, 4):
        d.line((6, y, 58 - (y * 7) % 13, y), fill=1)


def calendario(d, fb, fs):  # 1974 calendar page: the month, the year, a grid of days, some crossed off
    d.text((14, 2), "MARÇO", font=fb, fill=1); d.text((22, 13), "1974", font=fb, fill=1)
    for r in range(5):
        for c in range(7):
            x, y = 3 + c * 8, 28 + r * 9
            d.rectangle((x, y, x + 7, y + 8), outline=1)
            if r * 7 + c < 19:
                d.line((x, y, x + 7, y + 8), fill=1)


paper("paper_procura", 64, 80, procura)
img = np.array(Image.open(os.path.join(OUT, "paper_procura.png")), dtype=float) / 255
img[16:52, 15:49] *= np.array((0.62, 0.6, 0.56))  # the photo: a grey face-shaped blur
blob(img, 32, 30, 8, mul=0.75, soft=True); blob(img, 32, 46, 13, mul=0.8, soft=True)
T["paper_procura"] = save("paper_procura", img)
paper("calendario", 60, 76, calendario)

# draughts board (fit): 8 x 8 worn red and black squares, a few pieces left on it
img = np.zeros((32, 32, 3))
for r in range(8):
    for c in range(8):
        img[r * 4:(r + 1) * 4, c * 4:(c + 1) * 4] = (0.45, 0.14, 0.11) if (r + c) % 2 else (0.10, 0.09, 0.08)
for r, c, col in ((1, 2, (0.8, 0.76, 0.66)), (2, 5, (0.8, 0.76, 0.66)), (5, 2, (0.2, 0.18, 0.16)), (6, 1, (0.2, 0.18, 0.16))):
    blob(img, c * 4 + 1.5, r * 4 + 1.5, 1.6, col=col)
T["dama"] = save("dama", grain(img, 0.08))

# window seen from inside (fit to the quad): dark frame, panes full of the grey fog outside, one broken
img = np.ones((40, 32, 3)) * np.array((0.22, 0.17, 0.12))
for i, (y0, y1) in enumerate(((3, 14), (15, 26), (27, 37))):
    for j, (x0, x1) in enumerate(((3, 15), (17, 29))):
        pane = np.ones((y1 - y0, x1 - x0, 3)) * np.array((0.56, 0.59, 0.60)) * (0.9 + 0.08 * i)
        pane[:, :, :] *= (0.94 + 0.06 * rng.random((y1 - y0, x1 - x0)))[:, :, None]
        if (i, j) == (1, 1):  # broken: shards round the edge, the dark yard behind
            pane[2:-2, 2:-2] = (0.20, 0.21, 0.22)
        img[y0:y1, x0:x1] = pane
for _ in range(6):  # dirt and cobwebs in the corners of the panes
    blob(img, rng.integers(32), rng.integers(40), rng.uniform(1, 2.5), mul=0.8, soft=True)
T["window_in"] = save("window_in", img)

# ---------------- vegetation (vila_kit.py veg pieces): cut-out cards (RGBA, alpha 0/1) and two opaque ones ----------------
def save_rgba(name, rgb, alpha):
    a = (alpha > 0.5).astype(float)[:, :, None]
    img = np.concatenate([np.clip(rgb, 0, 1), a], axis=2)
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".png"))
    T[name] = name
    return name


def blade(rgb, al, x0, y0, x1, y1, col, w=1):
    """A blade/stroke from (x0, y0) to (x1, y1), image rows grow downwards."""
    h, wd = al.shape
    n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
    for i in range(n):
        t = i / max(n - 1, 1); x = x0 + (x1 - x0) * t; y = y0 + (y1 - y0) * t
        for k in range(w if t < 0.6 else 1):
            xi, yi = int(round(x)) + k, int(round(y))
            if 0 <= xi < wd and 0 <= yi < h:
                rgb[yi, xi] = np.array(col) * (0.8 + 0.3 * (1 - t)); al[yi, xi] = 1


# tall dry grass ("capim alto"): a tuft of straw blades fanning up from the bottom edge, seed heads on some
H_, W_ = 64, 32
rgb = np.zeros((H_, W_, 3)); al = np.zeros((H_, W_))
for _ in range(26):
    x0 = rng.uniform(8, 24); top = rng.uniform(4, 30); x1 = x0 + rng.uniform(-11, 11)
    col = np.array((0.58, 0.50, 0.30)) * rng.uniform(0.7, 1.1) if rng.random() < 0.75 else (0.30, 0.27, 0.16)
    blade(rgb, al, x0, H_ - 1, x1, top, col, w=2)
    if rng.random() < 0.3:  # seed head
        for k in range(4):
            yi = int(top) + k
            if 0 <= yi < H_:
                rgb[yi, int(x1) % W_] = (0.62, 0.52, 0.34); al[yi, int(x1) % W_] = 1
rgb *= (0.65 + 0.35 * (1 - np.arange(H_) / H_))[::-1, None, None] ** 0.5  # darker at the root
save_rgba("capim_alto", rgb, al)

# dry fern frond ("samambaia"): a rachis up the middle, pinnae alternating and shrinking to the tip, rust brown
H_, W_ = 64, 32
rgb = np.zeros((H_, W_, 3)); al = np.zeros((H_, W_))
blade(rgb, al, 16, H_ - 1, 16, 2, (0.30, 0.18, 0.10), w=1)
for y in range(H_ - 6, 4, -4):
    L = 3 + 12 * (y / H_) ** 0.8
    for sx in (-1, 1):
        y_off = 2 if sx > 0 else 0
        col = np.array((0.52, 0.30, 0.15)) * rng.uniform(0.75, 1.1)
        blade(rgb, al, 16, y + y_off, 16 + sx * L, y + y_off - 3, col, w=1)
        for k in range(1, int(L), 2):  # leaflets
            xi = int(16 + sx * k); yi = int(y + y_off - 3 * k / L)
            for dy in (-1, 1):
                if 0 <= yi + dy < H_ and 0 <= xi < W_ and rng.random() < 0.85:
                    rgb[yi + dy, xi] = col * 0.9; al[yi + dy, xi] = 1
save_rgba("samambaia", rgb, al)

# araucaria foliage: the dark, stiff, upturned "bottle-brush" tufts at the branch ends, seen from the side, gappy
H_, W_ = 64, 64
rgb = np.zeros((H_, W_, 3)); al = np.zeros((H_, W_))
for _ in range(9):  # twig clusters along a curved branch end
    cx, cy = rng.uniform(10, 54), rng.uniform(26, 50)
    for _ in range(26):
        a = rng.uniform(-2.6, -0.5); L = rng.uniform(5, 13)
        col = np.array((0.13, 0.20, 0.13)) * rng.uniform(0.6, 1.3)
        blade(rgb, al, cx, cy, cx + L * np.cos(a) * 0.6, cy + L * np.sin(a), col, w=1)
for x in range(4, 60):  # the branch underneath
    y = int(50 - 14 * ((x - 32) / 28) ** 2)
    rgb[y:y + 2, x] = (0.24, 0.18, 0.13); al[y:y + 2, x] = 1
save_rgba("araucaria", rgb, al)

# dead leaves still on the twigs (for the dry bushes)
H_, W_ = 32, 32
rgb = np.zeros((H_, W_, 3)); al = np.zeros((H_, W_))
for _ in range(5):
    x0, y0 = rng.uniform(4, 28), rng.uniform(6, 30)
    blade(rgb, al, x0, y0, x0 + rng.uniform(-8, 8), y0 - rng.uniform(4, 12), (0.22, 0.17, 0.12))
for _ in range(34):
    cx, cy = rng.integers(2, 30), rng.integers(2, 30)
    col = np.array((0.45, 0.30, 0.17)) * rng.uniform(0.6, 1.2)
    for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (2, 1)):
        if rng.random() < 0.85:
            rgb[(cy + dy) % H_, (cx + dx) % W_] = col; al[(cy + dy) % H_, (cx + dx) % W_] = 1
save_rgba("folhas_secas", rgb, al)

# a cut stump's end grain: growth rings, a crack, the grey weathered rim
img = np.zeros((32, 32, 3)); yy, xx = np.mgrid[0:32, 0:32]
d = np.hypot(xx - 15.5, yy - 15.5) + 0.8 * np.sin(np.arctan2(yy - 15.5, xx - 15.5) * 3)
img[:] = np.array((0.50, 0.38, 0.25))[None, None, :] * (0.85 + 0.15 * np.cos(d * 1.6))[:, :, None]
img[d > 13.5] = (0.30, 0.27, 0.23)
for k in range(10):
    img[15 + k // 3, 15 + k] = (0.16, 0.11, 0.08)
T["toco"] = save("toco", grain(img, 0.08))

# bark with moss: the fallen logs and stumps
img = np.array(Image.open(os.path.join(OUT, "bark.png")), dtype=float)[:, :, :3] / 255
m = fbm(64, (2, 4, 8)) > 0.55
img[m] = img[m] * 0.4 + np.array((0.22, 0.30, 0.14)) * 0.6
for _ in range(40):
    p = (rng.integers(64), rng.integers(64))
    if m[p[1], p[0]]:
        img[p[1], p[0]] = (0.33, 0.42, 0.20)
T["casca_musgo"] = save("casca_musgo", grain(img, 0.06))

# ---------------- environmental narrative (vilarejo_build.py narrative()): cut-out decals and charred wood ----------------
BLOOD = np.array((0.30, 0.04, 0.03))


def splat(name, n, seed_blobs, drips=0, size=64):
    """A dried blood stain: overlapping blobs, darker where it pooled, specks flung round it."""
    rgb = np.zeros((size, size, 3)); al = np.zeros((size, size)); yy, xx = np.mgrid[0:size, 0:size]
    c = size / 2
    for _ in range(seed_blobs):
        cx, cy = c + rng.normal(0, size * 0.12), c + rng.normal(0, size * 0.12); r = rng.uniform(size * 0.08, size * 0.2)
        d = np.hypot(xx - cx, yy - cy) / r
        m = d < 1 + 0.25 * vnoise(size, 6)[:size, :size]
        al[m] = 1; rgb[m] = BLOOD * rng.uniform(0.7, 1.1)
    for _ in range(n):  # specks
        x, y = int(c + rng.normal(0, size * 0.3)), int(c + rng.normal(0, size * 0.3))
        if 0 <= x < size and 0 <= y < size:
            al[y, x] = 1; rgb[y, x] = BLOOD * 0.8
    rgb *= (0.7 + 0.5 * fbm(size, (2, 4, 8))[:size, :size])[:, :, None]
    save_rgba(name, rgb, al)


splat("sangue_poca", 60, 7)
splat("sangue_mancha", 30, 3, size=32)

# drag marks: two smeared tracks along the strip (v runs along the drag), broken, fading in and out
H_, W_ = 128, 32
rgb = np.zeros((H_, W_, 3)); al = np.zeros((H_, W_))
for x0 in (9, 22):
    w = 3 + 2 * vnoise(128, 8)[:, 0]
    keep = vnoise(128, 10)[:, 3] > 0.35
    for y in range(H_):
        if keep[y]:
            for x in range(int(x0 - w[y]), int(x0 + w[y])):
                if 0 <= x < W_ and rng.random() < 0.8:
                    al[y, x] = 1; rgb[y, x] = BLOOD * rng.uniform(0.6, 1.0)
for _ in range(30):
    x, y = rng.integers(W_), rng.integers(H_); al[y, x] = 1; rgb[y, x] = BLOOD * 0.7
save_rgba("sangue_arrasto", rgb, al)

# a bloody hand print smeared downward
H_, W_ = 32, 32
rgb = np.zeros((H_, W_, 3)); al = np.zeros((H_, W_)); yy, xx = np.mgrid[0:H_, 0:W_]
palm = ((xx - 16) / 6.5) ** 2 + ((yy - 19) / 6) ** 2 < 1
al[palm] = 1
for fx, top in ((10, 6), (14, 3), (18, 3), (22, 6)):
    al[top:15, fx - 1:fx + 1] = 1
al[17:22, 7:10] = 1  # thumb
for x in range(10, 22, 2):  # smear running down
    L = rng.integers(3, 9); al[24:24 + L, x] = 1
rgb[al > 0] = BLOOD * 0.9
save_rgba("sangue_mao", rgb, al)


def graffiti(name, text, col, w, h, size):
    """Hand-painted letters, uneven, with paint running down from them."""
    mask = Image.new("1", (w, h)); d = ImageDraw.Draw(mask); d.fontmode = "1"
    f = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", size)
    x = 3
    for ch in text:  # each letter a little off the line, like a brush in a hurry
        d.text((x, 4 + rng.integers(-1, 2)), ch, font=f, fill=1)
        x += d.textbbox((0, 0), ch, font=f)[2] + rng.integers(0, 2)
    al = np.array(mask, dtype=float)
    for xx_ in range(w):  # drips
        ys = np.nonzero(al[:, xx_])[0]
        if len(ys) and rng.random() < 0.18:
            y0 = ys.max(); L = rng.integers(3, h - y0) if h - y0 > 3 else 0
            al[y0:y0 + L, xx_] = 1
    rgb = np.ones((h, w, 3)) * np.array(col) * (0.8 + 0.3 * rng.random((h, w)))[:, :, None]
    save_rgba(name, rgb, al)


graffiti("picho_nao_subam", "NÃO SUBAM", (0.55, 0.06, 0.05), 128, 32, 20)
graffiti("picho_noite", "ELES VOLTAM À NOITE", (0.08, 0.07, 0.07), 224, 32, 16)
graffiti("picho_deus", "DEUS NOS PERDOE", (0.55, 0.06, 0.05), 192, 32, 16)
graffiti("picho_x", "X", (0.6, 0.06, 0.05), 32, 40, 34)

# claw scratches gouged into a door: pale wood showing in parallel grooves
H_, W_ = 64, 32
rgb = np.zeros((H_, W_, 3)); al = np.zeros((H_, W_))
for set_ in range(3):
    x0, y0 = rng.uniform(4, 20), rng.uniform(4, 30)
    for k in range(4):
        blade(rgb, al, x0 + 2.5 * k, y0 + k, x0 + 2.5 * k + rng.uniform(1, 4), y0 + rng.uniform(16, 28), (0.62, 0.52, 0.38))
save_rgba("arranhoes", rgb, al)

# charred wood: black, alligator-cracked, a little grey ash, warm brown where it only scorched
img = base(64, (0.08, 0.07, 0.065), 0.25)
for y in range(0, 64, 6):
    img[y, :] *= 0.4
    for x in range(rng.integers(0, 8), 64, rng.integers(6, 12)):
        img[y:y + 6, x] *= 0.45
for _ in range(5):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(4, 8), mul=(1.5, 1.45, 1.4), soft=True)  # ash, faint
for _ in range(4):
    blob(img, rng.integers(64), rng.integers(64), rng.uniform(5, 10), mul=(1.6, 1.25, 1.0), soft=True)  # only scorched
T["carvao"] = save("carvao", grain(img, 0.1))


# ---------------- weathering decals over the walls (vilarejo_build.py stains()): soft alpha, in 4 steps like the N64 ---------
def save_soft(name, rgb, alpha):
    a = (np.round(np.clip(alpha, 0, 1) * 4) / 4)[:, :, None]
    img = np.concatenate([np.clip(rgb, 0, 1), a], axis=2)
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".png"))
    return name


def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


# rising damp: a dark band up from the ground, its tide line ragged and darker, mottled
W_, H_ = 128, 32
nx = vnoise(128, 8)[0] * 0.6 + vnoise(128, 32)[0] * 0.4
yy = np.arange(H_)[:, None] * np.ones((1, W_))           # 0 = top row
line = H_ - (8 + 16 * nx)[None, :]                        # tide line, rows from the top
al = ss(line - 1, line + 5, yy) * 0.55 + np.exp(-((yy - line) / 1.2) ** 2) * 0.35
al *= 0.75 + 0.35 * fbm(128, (8, 16, 32))[:H_, :W_]
rgb = np.ones((H_, W_, 3)) * np.array((0.20, 0.21, 0.16)) * (0.8 + 0.3 * fbm(128)[:H_, :W_])[:, :, None]
save_soft("umidade", rgb, al)

# moss: green-black patches, thickest at the bottom
n = fbm(64, (4, 8, 16)); yy = np.arange(64)[:, None] / 63.0
al = ss(0.62, 0.72, n + 0.35 * yy - 0.15) * 0.95
rgb = np.ones((64, 64, 3)) * np.array((0.20, 0.27, 0.10)) * (0.6 + 0.7 * fbm(64, (8, 16, 32)))[:, :, None]
save_soft("musgo", rgb, al)

# dirt run down from a window sill: a dark lip under the sill, streaks fading as they go
al = np.zeros((64, 32)); al[0:3, 2:30] = 0.8
for _ in range(9):
    x = rng.uniform(3, 29); ln = rng.uniform(20, 62); w = rng.choice((1, 1, 2))
    for y in range(int(ln)):
        al[y, int(x):int(x) + w] = max(al[y, int(x)], 0.75 * (1 - y / ln))
        x += rng.uniform(-0.15, 0.15)
al = np.maximum(al, ss(14, 0, np.arange(64))[:, None] * 0.35 * fbm(64, (4, 8))[:, :32])
rgb = np.ones((64, 32, 3)) * np.array((0.17, 0.15, 0.12))
save_soft("escorrido", rgb, al)

# a crack in the plaster: branching, a pale chipped edge along it
al = np.zeros((64, 64)); rgb = np.ones((64, 64, 3)) * np.array((0.12, 0.11, 0.10))
def crack(x, y, steps, dx):
    for i in range(steps):
        xi, yi = int(x), int(y)
        if not (0 <= xi < 64 and 0 <= yi < 64):
            return
        al[yi, xi] = 1.0
        if xi + 1 < 64 and al[yi, xi + 1] == 0:
            al[yi, xi + 1] = 0.5; rgb[yi, xi + 1] = (0.85, 0.83, 0.78)  # chipped lime
        x += dx + rng.uniform(-0.8, 0.8); y += 1
        if rng.random() < 0.06:
            crack(x, y, int(steps * 0.5), -dx + rng.uniform(-0.5, 0.5))
crack(30, 0, 60, 0.15); crack(34, 6, 30, 0.7)
save_soft("rachadura", rgb, al)

# preview sheet
names = list(T)
sheet = Image.new("RGB", (len(names) * 192, 192))
for i, n in enumerate(names):
    im = Image.open(os.path.join(OUT, n + ".png")).resize((96, 96), Image.NEAREST)  # (128 px ones shown scaled)
    tile = Image.new("RGB", (192, 192))
    for a in (0, 96):
        for b in (0, 96):
            tile.paste(im, (a, b))  # 2x2: shows the seams are gone
    sheet.paste(tile, (i * 192, 0))
sheet.save(paths.render("texturas", "scenery_textures.png"))
print(names)

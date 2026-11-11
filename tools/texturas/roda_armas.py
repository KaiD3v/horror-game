# The weapon wheel's art (godot_demo/scripts/ui/weapon_wheel.gd), pixel art shown at 2x like the notes:
# a wooden rosary (terço) for the ring, with a carved crucifix hanging under it, and on it one little wooden
# tablet per weapon, its picture burnt in like the ex-votos of a sala de milagres. Folk Catholicism, the 1970s
# countryside: the benzedeira, the chapel of Santa Clara.
#   roda_terco.png          176 x 214  the beads and string (centre = the wheel's centre), gaps where tablets sit
#   roda_placa_<arma>.png    40 x 34   a tablet with its picture: facao, besta, picareta, lamparina
#   roda_fita.png             9 x 18   the red ribbon tied on the tablet of what is in his hands
#   roda_brilho.png          64 x 64   candlelight behind the pointed tablet (dithered, no smooth gradient)
# Seeded. Run: python tools/texturas/roda_armas.py
import os
import sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))
import paths
OUT = paths.TEXTURES
rng = np.random.default_rng(1975)

S, R = 176, 64                     # rosary image width, ring radius (texels); centre (S/2, S/2)
SH = 214                           # its height: the crucifix hangs below the ring
SLOTS = (-135, -45, 45, 135)       # tablet angles in degrees, clockwise (WeaponWheel.slice_dir): the four diagonals,
                                   # the crucifix hanging free between the bottom two
WOOD = np.array((0.52, 0.34, 0.19))
DARK = np.array((0.13, 0.08, 0.05))
BURNT = (40, 22, 12, 255)
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0


def save(name, rgba):
    Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".png"))


def bead(img, cx, cy, r, col):  # a turned wooden bead: lit from the top left, dark rim
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = np.hypot(dx, dy)
            if d > r + 0.3:
                continue
            light = 0.75 + 0.45 * (-dx - dy) / (r * 1.6)
            c = DARK if d > r - 0.5 else col * light
            if d < r * 0.45 and dx < 0 and dy < 0 and r >= 2.5:
                c = col * 1.45  # the shine
            img[y, x] = (*c, 1)


def string(img, a0, a1):  # the cord between two angles (degrees), one texel thick
    for a in np.linspace(np.radians(a0), np.radians(a1), 400):
        x, y = S / 2 + R * np.cos(a), S / 2 + R * np.sin(a)
        if img[int(y), int(x), 3] == 0:
            img[int(y), int(x)] = (0.28, 0.22, 0.16, 1)


def rosary():
    img = np.zeros((SH, S, 4))
    gap = 26  # degrees kept free around each tablet
    for i, a in enumerate(SLOTS):
        b = SLOTS[(i + 1) % len(SLOTS)] + (360 if i == len(SLOTS) - 1 else 0)
        mid = (a + b) / 2
        for t in np.arange(a + gap, b - gap + 0.1, 6.5):  # the Ave-Marias, small
            if abs(t - mid) > 5:
                tr = np.radians(t)
                bead(img, S / 2 + R * np.cos(tr), S / 2 + R * np.sin(tr), 2.8, WOOD * rng.uniform(0.9, 1.1))
        tr = np.radians(mid)  # the Pai-Nosso between, bigger
        bead(img, S / 2 + R * np.cos(tr), S / 2 + R * np.sin(tr), 4.0, WOOD * 0.85)
        string(img, a + gap - 6, b - gap + 6)
    # the crucifix hangs from the bottom: three beads down the chain, then the cross
    x0, y0 = S / 2, S / 2 + R + 5
    for k in range(3):
        bead(img, x0, y0 + k * 6, 2.6, WOOD * 0.95)
    cross = np.zeros((22, 15), bool)
    cross[:, 5:10] = True; cross[4:9, :] = True
    edge = cross & ~ndimage.binary_erosion(cross)
    cy = int(y0 + 15)
    for y, x in zip(*np.nonzero(cross)):
        grain = 0.9 + 0.1 * np.sin(y * 1.7)
        lit = 1.2 if (x in (5, 6) or y in (4, 5)) else 1.0  # bevel along the top / left of the arms
        img[cy + y, int(x0) - 7 + x] = (*(DARK if edge[y, x] else WOOD * 0.9 * grain * lit), 1)
    img[cy + 6, int(x0)] = (*WOOD * 1.5, 1)  # a worn spot where thumbs rub it
    return img


def tablet():  # rough-cut wood, the grain along it, bevelled, two nail holes
    h, w = 34, 40
    g = ndimage.gaussian_filter(rng.standard_normal((h, w)), (0.6, 5))
    g = (g - g.min()) / (g.max() - g.min())
    img = np.ones((h, w, 4))
    img[:, :, :3] = WOOD * 1.25 * (0.82 + 0.3 * g)[:, :, None] * np.array((1, 0.96, 0.9))
    yy, xx = np.mgrid[0:h, 0:w]
    corner = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy))
    cut = (np.minimum(xx, w - 1 - xx) + np.minimum(yy, h - 1 - yy)) < 3  # chamfered corners
    img[cut, 3] = 0
    img[(corner == 0) & ~cut, :3] = DARK
    img[(corner == 1) & ((xx < 3) | (yy < 3)) & ~cut, :3] *= 1.25   # bevel: lit top / left
    img[(corner == 1) & ((xx > w - 4) | (yy > h - 4)) & ~cut, :3] *= 0.6
    for x in (5, w - 6):
        img[3, x, :3] = DARK; img[3, x + 1, :3] *= 0.7
    return img


def burn(img, draw_fn):  # the picture burnt in: drawn 1-bit, then a scorched halo
    pic = Image.new("L", (img.shape[1], img.shape[0]), 0)
    draw_fn(ImageDraw.Draw(pic))
    m = np.array(pic) > 0
    halo = ndimage.binary_dilation(m) & ~m & (img[:, :, 3] > 0)
    img[halo, :3] *= 0.72
    img[m, :3] = np.array(BURNT[:3]) / 255
    return img


def facao(d):  # the machete: long blade with a hooked tip, the handle with rivets, at a slant
    d.polygon([(10, 25), (30, 8), (33, 7), (32, 10), (13, 27)], fill=1)
    d.line([(6, 29), (10, 25)], fill=1, width=3)
    d.line([(9, 24), (13, 28)], fill=1)


def besta(d):  # the crossbow from above: the bow arched across, the stock down, the string, the stirrup
    d.arc([(6, 6), (34, 22)], 190, 350, fill=1, width=2)
    d.line([(20, 7), (20, 30)], fill=1, width=2)
    d.line([(7, 12), (20, 19), (33, 12)], fill=1)
    d.rectangle([(18, 26), (22, 30)], outline=1)


def lamparina(d):  # the oil lantern: the ring to hold it, the cap, the glass with the flame, the base
    d.ellipse([(17, 5), (23, 10)], outline=1)
    d.polygon([(14, 13), (26, 13), (23, 10), (17, 10)], fill=1)
    d.rectangle([(14, 13), (26, 26)], outline=1)
    d.line([(20, 14), (20, 15)], fill=1)
    d.polygon([(19, 22), (21, 22), (22, 19), (20, 16), (18, 19)], fill=1)
    d.rectangle([(12, 27), (28, 29)], fill=1)


def picareta(d):  # the pickaxe: the haft at a slant, the iron head across its top, curved, a point each end
    d.line([(9, 29), (24, 10)], fill=1, width=3)
    d.arc([(8, 4), (38, 26)], 200, 330, fill=1, width=3)
    d.point([(9, 12), (35, 12)], fill=1)


def ribbon():  # a fita: knotted at the top, two tails hanging apart, the ends cut in a V; red gone a little brown
    img = np.zeros((18, 9, 4))
    red, shade = np.array((0.66, 0.13, 0.09)), np.array((0.38, 0.07, 0.05))
    img[0:3, 2:7] = (*shade, 1); img[1, 3:6] = (*red, 1)
    for y in range(3, 18):
        for x0, end in ((3 - (y - 3) // 6, 17), (5 + (y - 3) // 7, 15)):
            if y <= end:
                img[y, x0:x0 + 2] = (*(red if (y + x0) % 5 else shade), 1)
    img[17, 1] = 0; img[15, 6] = 0  # the V cuts
    return img


def glow():  # candlelight: amber, ordered dither towards the edge
    yy, xx = np.mgrid[0:64, 0:64]
    d = np.hypot(xx - 31.5, yy - 31.5) / 32
    a = np.clip(1 - d, 0, 1) ** 1.2
    a = np.where(a > BAYER[yy % 4, xx % 4] * 0.6, np.clip(np.ceil(a * 4) / 4, 0.25, 0.9), 0)
    img = np.zeros((64, 64, 4)); img[:, :, :3] = (1.0, 0.62, 0.28); img[:, :, 3] = a
    return img


save("roda_terco", rosary())
for name, fn in (("facao", facao), ("besta", besta), ("picareta", picareta), ("lamparina", lamparina)):
    save("roda_placa_" + name, burn(tablet(), fn))
save("roda_fita", ribbon())
save("roda_brilho", glow())
print("roda: terço, 4 placas, fita, brilho ->", OUT)

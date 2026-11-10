# Papers for the collectible notes (godot_demo/notas.gd), aged like the PROCURA-SE posters (scenery_textures.py):
#   nota_<kind>.png    210 x 270, blank, shown at 2x by the reader; the text goes over it in the game font
#   nota_<kind>_p.png  42 x 54, the same page with scribbled lines: the prop lying in the world
# kinds: caderno (a ruled notebook page, torn off), oficio (the Colônia's letterhead, folded, a stamp),
#        ficha (a patient's file card: printed boxes, the photo corner, a paper clip). Seeded. Run: python tools/texturas/notas_papeis.py
import os
import numpy as np
from PIL import Image
from scipy import ndimage

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
OUT = paths.TEXTURES
W, H = 210, 270
LINE, TOP, LEFT = 14, 34, 22  # text grid of notas.gd: 14 texel lines (28 px at 2x), from TOP, after LEFT
rng = np.random.default_rng(1975)


def noise(h, w, s):
    return ndimage.gaussian_filter(rng.standard_normal((h, w)), s, mode="wrap")


def aged(col, h=H, w=W):
    n = noise(h, w, 6); n = (n - n.min()) / (n.max() - n.min())
    img = np.ones((h, w, 3)) * np.array(col) * (0.9 + 0.1 * n)[:, :, None]
    yy, xx = np.mgrid[0:h, 0:w]
    edge = np.minimum.reduce([xx, yy, w - 1 - xx, h - 1 - yy]) / 14.0  # yellowed, darker to the edges
    img *= (0.86 + 0.14 * np.clip(edge, 0, 1))[:, :, None] * np.array((1.0, 0.98, 0.93))
    for _ in range(3):  # water / coffee stains: a ring darker than the inside
        cx, cy, r = rng.uniform(0, w), rng.uniform(0, h), rng.uniform(10, 26)
        d = np.hypot(xx - cx, yy - cy) / r
        img *= (1 - 0.06 * (d < 1) - 0.08 * np.exp(-((d - 1) * 9) ** 2))[:, :, None]
    return img, xx, yy


def grain(img, a=0.04):
    return img * (1 + a * rng.standard_normal(img.shape[:2]))[:, :, None]


def crease(img, y=None, x=None):  # a fold: a light ridge beside a dark one
    if y is not None:
        img[y] *= 0.86; img[y + 1] *= 1.06
    else:
        img[:, x] *= 0.86; img[:, x + 1] *= 1.06


def torn(img, side_left=True):  # the ragged edge where it was ripped from the notebook: transparent bites
    a = np.ones(img.shape[:2])
    depth = np.clip(2 + 3 * noise(img.shape[0], 1, 2)[:, 0] * 8, 0, 7).astype(int)
    for y, dd in enumerate(depth):
        if side_left:
            a[y, :dd] = 0
    return a


def save(name, img, alpha=None):
    rgba = np.dstack([np.clip(img, 0, 1), np.ones(img.shape[:2]) if alpha is None else alpha])
    Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".png"))
    small = Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").resize((W // 5, H // 5), Image.BOX)
    s = np.array(small, float) / 255  # the prop: scribbles where the text would be
    for y in range(TOP // 5 + 1, H // 5 - 4, 3):
        x1 = int(rng.uniform(0.55, 0.92) * (W // 5))
        s[y, LEFT // 5 + 1:x1, :3] *= 0.45
    Image.fromarray((np.clip(s, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + "_p.png"))


# caderno: ruled in faded blue, the red margin, ripped off along the left
img, xx, yy = aged((0.80, 0.77, 0.68))
for y in range(TOP + 11, H - 6, LINE):  # rules sit just under the text's baseline
    img[y] = img[y] * 0.55 + np.array((0.42, 0.50, 0.62)) * 0.45
img[:, LEFT - 6] = img[:, LEFT - 6] * 0.5 + np.array((0.62, 0.24, 0.22)) * 0.5
crease(img, y=H // 2)
save("nota_caderno", grain(img), torn(img))

# oficio: whiter bond paper, folded in three, the letterhead rule, a violet rubber stamp half off the page
img, xx, yy = aged((0.84, 0.82, 0.76))
img[TOP + 13:TOP + 15, LEFT - 8:W - LEFT + 8] *= 0.35  # rule under the letterhead (the heading is its first line)
crease(img, y=H // 3); crease(img, y=2 * H // 3)
cx, cy = W - 46, H - 40; d = np.hypot(xx - cx, yy - cy)
ring = ((np.abs(d - 22) < 1.6) | (np.abs(d - 15) < 1.0)) & (noise(H, W, 1.2) > -0.25)
img[ring] = img[ring] * 0.4 + np.array((0.36, 0.26, 0.48)) * 0.6
save("nota_oficio", grain(img))

# ficha: buff card, printed boxes in brown ink, a photo corner (grey, face-shaped blur), a rusty clip
img, xx, yy = aged((0.78, 0.70, 0.52))
ink = np.array((0.38, 0.27, 0.20))
for y in range(TOP + 11 + LINE, H - 6, LINE):
    img[y, LEFT - 4:W - LEFT + 4] = img[y, LEFT - 4:W - LEFT + 4] * 0.6 + ink * 0.4
img[TOP + 13:TOP + 15, LEFT - 4:W - LEFT + 4] = ink
px0, py0 = W - 62, TOP + 2  # the photo, top right, over the first lines
img[py0:py0 + 52, px0:px0 + 42] = np.array((0.46, 0.45, 0.42)) * (0.9 + 0.1 * noise(52, 42, 3) * 4)[:, :, None]
face = np.hypot((xx - px0 - 21) / 11, (yy - py0 - 20) / 14) < 1
img[face] *= 0.72; img[(np.hypot((xx - px0 - 21) / 18, (yy - py0 - 52) / 14) < 1) & (yy < py0 + 52) & (xx >= px0) & (xx < px0 + 42)] *= 0.78
img[py0 - 4:py0 + 20, px0 + 30:px0 + 33] = (0.42, 0.30, 0.22)  # the clip
img[py0 - 4:py0 - 2, px0 + 26:px0 + 37] = (0.42, 0.30, 0.22)
save("nota_ficha", grain(img))
print("ok: nota_caderno, nota_oficio, nota_ficha ->", OUT)

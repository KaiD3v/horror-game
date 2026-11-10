# The game's own font, "Santa Clara": a hand-drawn pixel font (N64-era UI), Portuguese accents included.
# Writes godot_demo/fonts/santa_clara.png + .fnt (BMFont text format, which Godot imports as a FontFile).
# Cell: 12 rows; caps 7 rows tall from row 3 (rows 0-1 their accents), lowercase x-height 5 (accents rows 2-3),
# descenders rows 10-11, baseline under row 9. Draw it at multiples of 12 px (12 = 1x, 24 = 2x...) to stay crisp.
# Run: python tools/texturas/fonte.py
import os
import numpy as np
from PIL import Image

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
OUT = paths.FONTS
CELL, TOP, BASE = 12, 3, 10  # rows; glyphs below start at row TOP; BASE = baseline from the top

# 9 rows each: 7 of cap height, 2 of descender. '#' ink.
G = {
    "A": ".###. #...# #...# ##### #...# #...# #...#", "B": "####. #...# #...# ####. #...# #...# ####.",
    "C": ".###. #...# #.... #.... #.... #...# .###.", "D": "###.. #..#. #...# #...# #...# #..#. ###..",
    "E": "##### #.... #.... ####. #.... #.... #####", "F": "##### #.... #.... ####. #.... #.... #....",
    "G": ".###. #...# #.... #.### #...# #...# .####", "H": "#...# #...# #...# ##### #...# #...# #...#",
    "I": "### .#. .#. .#. .#. .#. ###", "J": "..### ...#. ...#. ...#. #..#. #..#. .##..",
    "K": "#...# #..#. #.#.. ##... #.#.. #..#. #...#", "L": "#.... #.... #.... #.... #.... #.... #####",
    "M": "#...# ##.## #.#.# #.#.# #...# #...# #...#", "N": "#...# ##..# #.#.# #..## #...# #...# #...#",
    "O": ".###. #...# #...# #...# #...# #...# .###.", "P": "####. #...# #...# ####. #.... #.... #....",
    "Q": ".###. #...# #...# #...# #.#.# #..#. .##.# ....#", "R": "####. #...# #...# ####. #.#.. #..#. #...#",
    "S": ".#### #.... #.... .###. ....# ....# ####.", "T": "##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#..",
    "U": "#...# #...# #...# #...# #...# #...# .###.", "V": "#...# #...# #...# #...# #...# .#.#. ..#..",
    "W": "#...# #...# #...# #.#.# #.#.# #.#.# .#.#.", "X": "#...# #...# .#.#. ..#.. .#.#. #...# #...#",
    "Y": "#...# #...# .#.#. ..#.. ..#.. ..#.. ..#..", "Z": "##### ....# ...#. ..#.. .#... #.... #####",
    "a": "..... ..... .###. ....# .#### #...# .####", "b": "#.... #.... ####. #...# #...# #...# ####.",
    "c": ".... .... .### #... #... #... .###", "d": "....# ....# .#### #...# #...# #...# .####",
    "e": "..... ..... .###. #...# ##### #.... .###.", "f": "..## .#.. #### .#.. .#.. .#.. .#..",
    "g": "..... ..... .#### #...# #...# #...# .#### ....# .###.", "h": "#.... #.... ####. #...# #...# #...# #...#",
    "i": "# . # # # # #", "j": "..# ... ..# ..# ..# ..# ..# #.# .#.",
    "k": "#... #... #..# #.#. ##.. #.#. #..#", "l": "#. #. #. #. #. #. .#",
    "m": "..... ..... ####. #.#.# #.#.# #.#.# #.#.#", "n": ".... .... ###. #..# #..# #..# #..#",
    "o": "..... ..... .###. #...# #...# #...# .###.", "p": "..... ..... ####. #...# #...# #...# ####. #.... #....",
    "q": "..... ..... .#### #...# #...# #...# .#### ....# ....#", "r": ".... .... #.## ##.. #... #... #...",
    "s": ".... .... .### #... .##. ...# ###.", "t": ".#.. .#.. #### .#.. .#.. .#.. ..##",
    "u": ".... .... #..# #..# #..# #..# .###", "v": "..... ..... #...# #...# #...# .#.#. ..#..",
    "w": "..... ..... #...# #...# #.#.# #.#.# .#.#.", "x": "..... ..... #...# .#.#. ..#.. .#.#. #...#",
    "y": ".... .... #..# #..# #..# #..# .### ...# ###.", "z": ".... .... #### ...# ..#. .#.. ####",
    "0": ".###. #...# #..## #.#.# ##..# #...# .###.", "1": ".#. ##. .#. .#. .#. .#. ###",
    "2": ".###. #...# ....# ...#. ..#.. .#... #####", "3": "####. ....# ....# .###. ....# ....# ####.",
    "4": "...#. ..##. .#.#. #..#. ##### ...#. ...#.", "5": "##### #.... ####. ....# ....# #...# .###.",
    "6": ".###. #.... #.... ####. #...# #...# .###.", "7": "##### ....# ...#. ..#.. .#... .#... .#...",
    "8": ".###. #...# #...# .###. #...# #...# .###.", "9": ".###. #...# #...# .#### ....# ....# .###.",
    ".": ". . . . . . #", ",": ". . . . . . # #", ":": ". . . # . . #", ";": ". . . # . . # #",
    "!": "# # # # # . #", "?": ".###. #...# ....# ...#. ..#.. ..... ..#..",
    "-": "... ... ... ... ###", "–": "..... ..... ..... ..... #####", "—": "..... ..... ..... ..... #####",
    "(": ".# #. #. #. #. #. .#", ")": "#. .# .# .# .# .# #.", "\"": "#.# #.#", "'": "# #",
    "/": "..# ..# .#. .#. .#. #.. #..", "·": ". . . . #", "•": ".. .. .. ## ##", "+": "..... ..... ..#.. ..#.. ##### ..#.. ..#..",
    "<": "... ..# .#. #.. .#. ..#", ">": "... #.. .#. ..# .#. #..", "º": ".#. #.# .#.", "ª": ".#. #.# .##",
    "°": ".#. #.# .#.", "*": "..... #.#.# .###. #.#.# .....", "=": ".... .... .... #### .... ####",
    "%": "##..# ##.#. ...#. ..#.. .#... .#.## #..##", "&": ".##.. #..#. .##.. .#... #.#.# #..#. .##.#",
    "_": "..... ..... ..... ..... ..... ..... ..... #####",
}
ACCENT = {"´": ["..#", ".#."], "`": ["#..", ".#."], "^": [".#.", "#.#"], "~": ["##.#", "#.##"]}
COMPOSE = {"á": "a´", "à": "a`", "â": "a^", "ã": "a~", "é": "e´", "ê": "e^", "í": "ı´", "ó": "o´", "ô": "o^",
           "õ": "o~", "ú": "u´", "Á": "A´", "À": "A`", "Â": "A^", "Ã": "A~", "É": "E´", "Ê": "E^", "Í": "I´",
           "Ó": "O´", "Ô": "O^", "Õ": "O~", "Ú": "U´"}


def bitmap(rows):
    """The 9 design rows into a CELL-tall boolean bitmap (cap tops at row TOP)."""
    rows = rows.split(); w = len(rows[0])
    b = np.zeros((CELL, w), bool)
    for r, line in enumerate(rows):
        b[TOP + r] = [c == "#" for c in line]
    return b


GLYPHS = {k: bitmap(v) for k, v in G.items()}
GLYPHS["ı"] = bitmap(". . # # # # #")  # dotless i, for í
for ch, (base, acc) in COMPOSE.items():
    b = GLYPHS[base].copy(); a = ACCENT[acc]; aw = len(a[0])
    x0 = max(0, (b.shape[1] - aw + 1) // 2)
    if b.shape[1] < aw:  # the accent is wider than the letter (í, Í): widen the cell round it
        pad = aw - b.shape[1]; b = np.pad(b, ((0, 0), (pad // 2, pad - pad // 2))); x0 = 0
    y0 = 0 if base.isupper() else 2
    for r, line in enumerate(a):
        for c, v in enumerate(line):
            b[y0 + r, x0 + c] |= v == "#"
    GLYPHS[ch] = b
for ch, base in (("ç", "c"), ("Ç", "C")):  # the cedilla hangs under the bowl
    b = GLYPHS[base].copy(); x = b.shape[1] // 2
    b[BASE, x] = True; b[BASE + 1, x - 1] = True
    GLYPHS[ch] = b
del GLYPHS["ı"]

# pack them in rows on one sheet, a 1 px gap round each
W = 256; x = y = 1; place = {}
for ch, b in GLYPHS.items():
    if x + b.shape[1] + 1 > W:
        x = 1; y += CELL + 1
    place[ch] = (x, y); x += b.shape[1] + 1
H = 1 << int(np.ceil(np.log2(y + CELL + 1)))
sheet = np.zeros((H, W, 4), np.uint8); sheet[:, :, :3] = 255
for ch, b in GLYPHS.items():
    px, py = place[ch]
    sheet[py:py + CELL, px:px + b.shape[1], 3] = b * 255
os.makedirs(OUT, exist_ok=True)
Image.fromarray(sheet, "RGBA").save(os.path.join(OUT, "santa_clara.png"))

lines = ['info face="Santa Clara" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 '
         'padding=0,0,0,0 spacing=1,1 outline=0' % CELL,
         "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0" % (CELL + 2, BASE, W, H),
         'page id=0 file="santa_clara.png"', "chars count=%d" % (len(GLYPHS) + 1),
         "char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=4 page=0 chnl=15"]
for ch, b in GLYPHS.items():
    px, py = place[ch]
    lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
                 % (ord(ch), px, py, b.shape[1], CELL, b.shape[1] + 1))
open(os.path.join(OUT, "santa_clara.fnt"), "w", encoding="utf-8").write("\n".join(lines) + "\n")

# a specimen, 3x, for the docs
spec = "VILA DE SANTA CLARA · COLÔNIA\nNão subam. Eles voltam à noite.\nÁ À Â Ã É Ê Í Ó Ô Õ Ú Ç ç ã õ ê\n0123456789 (1974) nº 117 — ?!"
rows = spec.split("\n"); img = np.full(((CELL + 2) * len(rows) + 4, 300, 3), (188, 178, 153), np.uint8)
for r, line in enumerate(rows):
    cx = 3
    for ch in line:
        if ch == " ":
            cx += 4; continue
        b = GLYPHS[ch]; img[2 + r * (CELL + 2):2 + r * (CELL + 2) + CELL, cx:cx + b.shape[1]][b] = (40, 33, 30)
        cx += b.shape[1] + 1
Image.fromarray(img).resize((img.shape[1] * 3, img.shape[0] * 3), Image.NEAREST).save(
    paths.render("interface", "fonte_santa_clara.png"))
print("ok: %d glyphs, sheet %dx%d ->" % (len(GLYPHS), W, H), OUT)

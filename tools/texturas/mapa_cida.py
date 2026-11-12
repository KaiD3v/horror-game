# Cida's map (docs/CONTEUDO_VILAREJO.md "Cida"): the village drawn in coloured pencil by a nine-year-old on a torn
# notebook page (nota_caderno.png, notas_papeis.py), north up. The road, the square and its well, the chapel, the
# cemetery, the houses as little boxes with roofs, the gate at the top with its bars; "EU" and a heart at the oven behind
# the venda. And her fears, each a red X: the ruin by the gate (smoke), the west field where the mill's oven is, the
# ravine, and her own house (the Zé's). It marks nothing he has not seen except those fears: they are the hints.
#   -> godot_demo/textures/nota_mapa_cida.png (210 x 270, shown at 2x by NotesReader)
# Run: python tools/texturas/mapa_cida.py (after notas_papeis.py)
import os, sys, math, random
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths
import paths
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "cenarios", "vilarejo"))
R = random.Random(9)

img = Image.open(os.path.join(paths.TEXTURES, "nota_caderno.png")).convert("RGBA")
d = ImageDraw.Draw(img)
font = ImageFont.load_default()
PENCIL = {"lead": (60, 56, 64, 255), "red": (176, 40, 34, 255), "brown": (120, 82, 48, 255),
          "green": (70, 110, 60, 255), "blue": (60, 84, 150, 255), "yellow": (190, 150, 40, 255)}


def P(x, z):  # Godot x, z (x -50..50, z -62..55) -> the page, north up
    return (28 + (x + 50) * 1.6, 30 + (z + 62) * 1.85)


def line(pts, col, w=2):  # a wobbly pencil stroke, gone over twice
    for k in range(2):
        q = [(x + R.uniform(-0.8, 0.8), y + R.uniform(-0.8, 0.8)) for x, y in pts]
        d.line(q, fill=PENCIL[col], width=w)


def word(x, z, s, col="lead", dx=0, dy=0):
    px, py = P(x, z)
    d.text((px + dx, py + dy), s, fill=PENCIL[col], font=font)


def house(x, z, col="lead"):
    px, py = P(x, z)
    line([(px - 5, py), (px + 5, py), (px + 5, py + 7), (px - 5, py + 7), (px - 5, py)], col, 1)
    line([(px - 6, py), (px, py - 5), (px + 6, py)], "red", 1)


def cross(x, z, col="red", s=5):
    px, py = P(x, z)
    line([(px - s, py - s), (px + s, py + s)], col, 3); line([(px - s, py + s), (px + s, py - s)], col, 3)


# the road (Godot = Blender x, -y) and the lane
line([P(0, 50), P(-2, 32), P(2, 14), P(0, 0), P(1, -20), P(-2, -40), P(0, -60)], "brown", 3)
line([P(-50, -2), P(-40, -3), P(-20, -6), P(0, -6), P(22, -5), P(42, -9), P(50, -8)], "brown", 2)
px, py = P(0, -6); d.ellipse((px - 12, py - 10, px + 12, py + 10), outline=PENCIL["brown"], width=2)  # the square
d.ellipse((px - 3, py - 3, px + 3, py + 3), outline=PENCIL["blue"], width=2)                             # the well
# the chapel (a tall box, a cross) and the cemetery
cx, cy = P(-15.5, -9); line([(cx - 6, cy - 4), (cx + 6, cy - 4), (cx + 6, cy + 8), (cx - 6, cy + 8), (cx - 6, cy - 4)], "lead", 1)
line([(cx, cy - 13), (cx, cy - 4)], "lead", 1); line([(cx - 3, cy - 10), (cx + 3, cy - 10)], "lead", 1)
word(-15.5, -9, "IGREJA", dx=-14, dy=10)
gx, gy = P(-31, -9); line([(gx - 10, gy - 12), (gx + 10, gy - 12), (gx + 10, gy + 12), (gx - 10, gy + 12), (gx - 10, gy - 12)], "lead", 1)
for i in range(3):
    for j in range(2):
        a, b = gx - 6 + 6 * i, gy - 5 + 9 * j
        line([(a, b - 3), (a, b + 3)], "lead", 1); line([(a - 2, b - 1), (a + 2, b - 1)], "lead", 1)
# houses (layout.HOUSES, Blender x, y -> Godot x, -y): the venda bigger, labelled
for hx, hy in ((9.5, -30), (-9.5, -20), (-12, -4), (13, -1), (27, 13.5), (30, -3), (41, 16), (-26, -7), (-10, 26),
               (9.5, 31), (-9, 43), (43.5, -11), (-10, -36)):
    house(hx, -hy)
house(12.5, -13, "lead"); word(12.5, -13, "VENDA", dx=-12, dy=9)
# the gate at the top, with its bars
tx, ty = P(0, -60); line([(tx - 14, ty), (tx + 14, ty)], "lead", 2)
for k in range(5):
    line([(tx - 8 + 4 * k, ty - 6), (tx - 8 + 4 * k, ty + 2)], "lead", 1)
word(0, -60, "PORTAO", dx=-16, dy=-16)
# trees, scribbled round the edges
for _ in range(16):
    x, z = R.choice((R.uniform(-48, -38), R.uniform(38, 48))), R.uniform(-55, 45)
    px, py = P(x, z); d.ellipse((px - 4, py - 4, px + 4, py + 4), outline=PENCIL["green"], width=2)
    line([(px, py + 4), (px, py + 8)], "brown", 1)
# the ravine: a jagged line across the bottom
line([P(-45 + 6 * k, 51 + (2 if k % 2 else -1)) for k in range(16)], "lead", 2)
# where she is: EU and a heart, at the oven behind the venda
hx, hy = P(20.5, -7.5)
d.ellipse((hx - 4, hy - 3, hx + 4, hy + 4), outline=PENCIL["brown"], width=2)
word(20.5, -7.5, "EU", "blue", dx=6, dy=-6)
d.polygon([(hx + 18, hy + 3), (hx + 15, hy), (hx + 16, hy - 2), (hx + 18, hy - 1), (hx + 20, hy - 2), (hx + 21, hy), (hx + 18, hy + 3)], fill=PENCIL["red"])
# her fears: a red X each, "MEDO"
for x, z, s in ((9, -46, "MEDO"), (-28, -31, "MEDO"), (0, 51, "MEDO"), (10, 15, "CASA")):
    cross(x, z); word(x, z, s, "red", dx=7, dy=-4)
img.save(os.path.join(paths.TEXTURES, "nota_mapa_cida.png"))
small = img.resize((42, 54), Image.BOX); small.save(os.path.join(paths.TEXTURES, "nota_mapa_cida_p.png"))
print("MAPA ok")

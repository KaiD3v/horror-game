# The village chapel, inside (the tower door off the square), its own scene, Zelda style (vila_kit.Room). A small
# colonial chapel left as it was the day they stopped coming: hydraulic-tile floor, whitewash over a blue dado, tall
# windows, pews (some knocked askew, one over on its back), the Stations of the Cross up high, the altar on its step
# behind the rail, a blue and gold retable with Santa Clara in the middle niche (the village's and the Colônia's
# patron). In the aisle a wake that was never finished: a coffin on trestles, lid ajar, four tall candles. A board of
# wax ex-votos (heads, hands, legs, a heart, photographs), a rack of votive candles, the bell rope, the holy water.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/capela_build.py
#   -> blender/cenarios/capela.blend, godot_demo/models/levels/capela.glb, renders/cenarios/capela_{corte,altar}.png
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces, Room

mat("ladrilho", "tiles", 1.0, "top"); mat("gold", "enamel", 1.0, tint=(1.3, 1.0, 0.42))
mat("retab", "painted_wood", 1.0, tint=(0.36, 0.5, 0.9)); mat("niche", "painted_wood", 1.0, tint=(0.16, 0.2, 0.42))
mat("wax", "linen", 1.0, tint=(1.05, 0.95, 0.76)); mat("saint", "cloth", 1.0, tint=(0.9, 0.74, 0.62))
mat("habit", "cloth", 1.0, tint=(0.48, 0.35, 0.26)); mat("veil", "cloth", 1.0, tint=(0.14, 0.13, 0.13))
mat("coffin", "planks", 1.0, tint=(0.55, 0.42, 0.36))
rng = random.Random("capela")
WX, WY, HT = 3.5, 6.5, 5.0
R_ = Room(WX, WY, HT)
ALTAR_Y, COFFIN_Y = 4.15, 2.75  # the step / rail line, the coffin's centre


def put_m(dst, src, M):
    i = len(dst.v)
    dst.v.extend(M @ v for v in src.v); dst.f.extend([k + i for k in f] for f in src.f); dst.m.extend(src.m)


def prism(b, pts, z0, z1, m, M=Matrix()):
    """A flat-sided solid from a 2D outline (counter-clockwise, seen from above)."""
    lo = [M @ Vector((x, y, z0)) for x, y in pts]; hi = [M @ Vector((x, y, z1)) for x, y in pts]
    b.poly(lo[::-1], m); b.poly(hi, m)
    for i in range(len(pts)):
        j = (i + 1) % len(pts)
        b.poly([lo[i], lo[j], hi[j], hi[i]], m)


def candle(b, c, h=0.25, r=0.03):
    c = Vector(c)
    frustum(b, c, c + Vector((0, 0, h)), r, r, 6, "wax", caps=True)
    frustum(b, c + Vector((0, 0, h)), c + Vector((0, 0, h + 0.06)), r * 0.5, 0.002, 4, "lampglass", caps=True)


def candlestick(b, c, tall):
    c = Vector(c)
    frustum(b, c, c + Vector((0, 0, 0.05)), 0.12 if tall else 0.06, 0.1 if tall else 0.05, 8, "gold", caps=True)
    frustum(b, c + Vector((0, 0, 0.05)), c + Vector((0, 0, tall or 0.3)), 0.025, 0.02, 6, "gold", caps=True)
    top = c + Vector((0, 0, tall or 0.3))
    frustum(b, top, top + Vector((0, 0, 0.02)), 0.06, 0.06, 8, "gold", caps=True)
    candle(b, top + Vector((0, 0, 0.02)), 0.28 if tall else 0.2)


def saint(b, c, robe, s=1.0, veil=None):
    c = Vector(c)
    frustum(b, c, c + Vector((0, 0, 0.75 * s)), 0.13 * s, 0.08 * s, 8, robe, caps=True)
    frustum(b, c + Vector((0, 0, 0.75 * s)), c + Vector((0, 0, 0.87 * s)), 0.045 * s, 0.04 * s, 6, "saint", caps=True)
    if veil:
        frustum(b, c + Vector((0, 0.04 * s, 0.6 * s)), c + Vector((0, 0.035 * s, 0.9 * s)), 0.1 * s, 0.045 * s, 8, veil, caps=True)  # back: the face shows


def pew():
    b = B()
    bx(b, (0, 0, 0.45), (2.1, 0.4, 0.05), "planks"); bx(b, (0, 0.2, 0.78), (2.1, 0.04, 0.5), "planks")
    for sx in (-1, 1):
        bx(b, (sx * 1.05, 0.02, 0.45), (0.05, 0.5, 0.9), "planks")
    bx(b, (0, -0.38, 0.15), (2.0, 0.14, 0.05), "planks")  # kneeler
    return b


# --- the room ----------------------------------------------------------------------------------------------------
room = B()
R_.shell(room, "whitewash", door_w=1.6, leaves=2, floor="ladrilho",
         windows=[(side, u, 1.8, 2.0) for side in ("left", "right") for u in (-3.0, 0.0, 3.0)])
R_.dado(room, "barra_blue", door_w=1.6)
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, beams=(-5.0, -2.5, 0.0, 2.5, 5.0)); obj(roof, "teto-col")

# --- solid: the altar step and rail, the altar, the retable, pews, the coffin, the font -------------------------------
s = B()
bx(s, (0, (ALTAR_Y + WY) / 2, 0.125), (2 * WX, WY - ALTAR_Y, 0.25), "planks")             # sanctuary floor, raised
for x0, x1 in ((-WX, -0.6), (0.6, WX)):                                                     # communion rail, a gap
    bx(s, ((x0 + x1) / 2, ALTAR_Y, 0.85), (x1 - x0, 0.1, 0.06), "planks")
    x = x0 + 0.12
    while x < x1:
        frustum(s, (x, ALTAR_Y, 0.25), (x, ALTAR_Y, 0.82), 0.03, 0.025, 6, "planks", caps=True); x += 0.24
bx(s, (0, 5.6, 0.75), (2.0, 0.8, 1.0), "whitewash")                                        # the altar
bx(s, (0, 5.6, 1.26), (2.1, 0.85, 0.02), "cloth_white"); bx(s, (0, 5.18, 1.08), (2.1, 0.02, 0.36), "cloth_white")
c = Vector((0, WY - 0.08, 2.4))                                                              # the retable
bx(s, c, (4.6, 0.15, 4.3), "retab")
for x in (-2.0, -1.0, 1.0, 2.0):
    frustum(s, (x, WY - 0.24, 0.5), (x, WY - 0.24, 3.95), 0.09, 0.075, 8, "gold", caps=True)
bx(s, (0, WY - 0.24, 4.15), (4.7, 0.3, 0.3), "gold")
b2 = B()
for x, w, z0, h in ((0, 1.0, 1.55, 1.9), (-1.5, 0.6, 1.8, 1.2), (1.5, 0.6, 1.8, 1.2)):    # niches, gilt frames
    b2.poly([Vector((x + w / 2, WY - 0.17, z0)), Vector((x - w / 2, WY - 0.17, z0)), Vector((x - w / 2, WY - 0.17, z0 + h)),
             Vector((x + w / 2, WY - 0.17, z0 + h))], "niche")
    for dx, dz, sw, sh in ((0, -0.03, w + 0.1, 0.06), (0, h + 0.03, w + 0.1, 0.06), (-w / 2 - 0.03, h / 2, 0.06, h),
                           (w / 2 + 0.03, h / 2, 0.06, h)):
        bx(b2, (x + dx, WY - 0.2, z0 + dz), (sw, 0.06, sh), "gold")
    bx(b2, (x, WY - 0.3, z0 + 0.02), (w * 0.5, 0.25, 0.04), "gold")  # bracket the saint stands on
b2.poly([Vector((0.75, WY - 0.2, 4.3)), Vector((-0.75, WY - 0.2, 4.3)), Vector((0, WY - 0.2, 4.85))], "gold")  # pediment
saint(b2, (0, WY - 0.3, 1.59), "habit", 1.55, veil="veil")                                  # Santa Clara
frustum(b2, (0, WY - 0.5, 2.55), (0, WY - 0.53, 2.55), 0.09, 0.09, 10, "gold", caps=True)  # her monstrance
bx(b2, (0, WY - 0.48, 2.42), (0.025, 0.025, 0.2), "gold")
saint(b2, (-1.5, WY - 0.3, 1.84), "cloth_blue", 1.05, veil="cloth_white")
saint(b2, (1.5, WY - 0.3, 1.84), "cloth_red", 1.05)
for x in (-0.7, -0.4, 0.4, 0.7):                                                             # candlesticks on the altar
    candlestick(b2, (x, 5.75, 1.27), 0)
c = Vector((0, 5.75, 1.27))                                                                   # crucifix
bx(b2, c + Vector((0, 0, 0.03)), (0.14, 0.1, 0.06), "gold"); bx(b2, c + Vector((0, 0, 0.3)), (0.03, 0.03, 0.5), "gold")
bx(b2, c + Vector((0, 0, 0.44)), (0.24, 0.03, 0.03), "gold"); bx(b2, c + Vector((0, -0.025, 0.36)), (0.025, 0.02, 0.17), "saint")
obj(b2, "retabulo")
pw = pew()
for row in range(5):                                                                         # pews: some askew, one over
    for sx in (-1, 1):
        y = -4.0 + 1.3 * row; yaw = rng.uniform(-3, 3) + (9 if (row, sx) in ((1, -1), (3, 1)) else 0)
        if (row, sx) == (2, 1):  # knocked over onto its back
            M = Matrix.LocRotScale(Vector((sx * 1.65, y + 0.15, 0.2)), Euler((math.radians(-82), 0, math.radians(4))), None)
        else:
            M = Matrix.LocRotScale(Vector((sx * 1.65 + rng.uniform(-0.05, 0.05), y, 0)), Euler((0, 0, math.radians(yaw))), None)
        put_m(s, pw, M)
COFFIN = [(-0.22, -0.95), (0.22, -0.95), (0.3, 0.45), (0.25, 0.95), (-0.25, 0.95), (-0.3, 0.45)]
for dy in (-0.6, 0.6):                                                                        # trestles
    for t in (-0.35, 0.35):
        bx(s, (0, COFFIN_Y + dy, 0.32), (0.05, 0.05, 0.7), "planks", rot=(0, t, 0))
    bx(s, (0, COFFIN_Y + dy, 0.6), (0.55, 0.08, 0.06), "planks")
prism(s, COFFIN, 0.63, 1.03, "coffin", Matrix.Translation((0, COFFIN_Y, 0)))
FONT = Vector((-1.3, -5.3, 0))                                                                # holy water font
frustum(s, FONT, FONT + Vector((0, 0, 0.8)), 0.1, 0.08, 8, "stone", caps=True)
obj(s, "moveis-col")

# --- small things: no collision ---------------------------------------------------------------------------------------
t = B()
lid = Matrix.LocRotScale(Vector((0.07, COFFIN_Y + 0.02, 0)), Euler((0, 0, math.radians(4))), None)  # lid pushed aside
prism(t, [(x * 1.06, y * 1.03) for x, y in COFFIN], 1.03, 1.08, "coffin", lid)
bx(t, lid @ Vector((0, 0.3, 1.09)), (0.04, 0.5, 0.012), "gold", rot=(0, 0, math.radians(4)))
bx(t, lid @ Vector((0, 0.42, 1.09)), (0.24, 0.04, 0.012), "gold", rot=(0, 0, math.radians(4)))
for x, y in ((0.55, COFFIN_Y - 1.0), (-0.55, COFFIN_Y - 1.0), (0.55, COFFIN_Y + 1.0), (-0.55, COFFIN_Y + 1.0)):
    candlestick(t, (x, y, 0), 1.15)                                                           # the wake's candles
c = Vector((-2.6, 3.4, 0))                                                                     # votive rack
for k, (dz, dy) in enumerate(((0.7, -0.15), (0.85, 0.05), (1.0, 0.25))):
    bx(t, c + Vector((0, dy, dz)), (1.0, 0.22, 0.04), "iron")
    for i in range(8):
        if rng.random() < 0.8:
            candle(t, c + Vector((-0.42 + 0.12 * i, dy + rng.uniform(-0.05, 0.05), dz + 0.02)), rng.uniform(0.04, 0.12), 0.015)
for sx in (-1, 1):
    bx(t, c + Vector((sx * 0.48, 0.05, 0.5)), (0.04, 0.5, 1.0), "iron")
for i in range(6):                                                                             # wax run onto the floor
    bx(t, c + Vector((rng.uniform(-0.5, 0.5), rng.uniform(-0.3, 0.3), 0.004)), (rng.uniform(0.05, 0.15), rng.uniform(0.05, 0.12), 0.008), "wax")
# ex-votos: a board on the right wall, wax heads, hands, legs, a heart, photographs, ribbons
bx(t, (WX - 0.03, 1.5, 1.8), (0.03, 1.3, 1.5), "planks")
xw = WX - 0.08
for i in range(3):
    p = Vector((xw, 1.0 + 0.45 * i, 2.25 + rng.uniform(-0.05, 0.05)))
    frustum(t, p + Vector((0, 0, -0.07)), p + Vector((0, 0, 0.07)), 0.055, 0.045, 6, "wax", caps=True)
for i in range(4):
    bx(t, (xw, 1.0 + 0.3 * i, 1.75), (0.02, 0.08, 0.13), "wax", rot=(rng.uniform(-0.3, 0.3), 0, 0))
for i in range(3):
    p = Vector((xw, 1.15 + 0.35 * i, 1.35))
    frustum(t, p + Vector((0, 0, 0.18)), p + Vector((0, 0.02, -0.14)), 0.035, 0.025, 5, "wax", caps=True)
bx(t, (xw, 2.0, 1.75), (0.03, 0.09, 0.09), "can", rot=(math.radians(45), 0, 0))              # a heart
for i in range(5):
    y, z = 0.95 + 0.26 * i, 2.45 - 0.1 * (i % 2)
    bx(t, (xw + 0.005, y, z), (0.01, 0.12, 0.15), "cloth_white", rot=(rng.uniform(-0.2, 0.2), 0, 0))
    bx(t, (xw - 0.001, y, z + 0.01), (0.01, 0.07, 0.08), "pit")
for i in range(7):
    bx(t, (xw + 0.01, 0.95 + 0.17 * i, 1.0), (0.01, 0.04, 0.35), rng.choice(("cloth_red", "cloth_blue", "cloth_white")),
       rot=(rng.uniform(-0.15, 0.15), 0, 0))
# the Stations of the Cross, high up, seven a side
for side in ("left", "right"):
    o, u, n = R_.side(side, 0.03)
    for k in range(7):
        a = -5.0 + 1.45 * k
        if side == "right":
            a = -a
        bx(t, o + u * a + Z * 4.2, (0.3, 0.04, 0.36) if abs(u.x) > 0.5 else (0.04, 0.3, 0.36), "gold")
        bx(t, o + u * a + Z * 4.2 + n * 0.025, (0.22, 0.01, 0.28) if abs(u.x) > 0.5 else (0.01, 0.22, 0.28), "niche")
frustum(t, FONT + Vector((0, 0, 0.8)), FONT + Vector((0, 0, 0.95)), 0.17, 0.22, 8, "stone", caps=True)
t.poly([FONT + Vector((0.18 * math.cos(a), 0.18 * math.sin(a), 0.955)) for a in [2 * math.pi * k / 8 for k in range(8)]], "pit")  # water
frustum(t, (1.3, -5.6, HT), (1.3, -5.6, 1.0), 0.015, 0.015, 4, "burlap")                    # the bell rope
bx(t, (1.3, -5.6, 0.98), (0.06, 0.06, 0.1), "burlap")
obj(t, "objetos")

# the tower's little door, in the front wall right of the way in (docs/CONTEUDO_VILAREJO.md "O sino"): up the tower (torre)
tw_door = B(); R_.quad(tw_door, "front", -2.85, -1.95, 0, 2.05, "door", e=0.035); obj(tw_door, "porta_torre_folha")

# --- markers for capela.gd (interior.gd) ------------------------------------------------------------------------
sac = B()  # the sacristy's door, in the left wall by the altar (docs/TUTORIAL_VILAREJO.md "Dungeon 2"): down to the ossuary
R_.quad(sac, "left", 4.85, 5.75, 0.25, 2.3, "door", e=0.035)  # (in front of the painted band: a 2 cm box at 0.012)
obj(sac, "porta_sacristia_folha")
for name, loc, yaw in (("porta_sacristia", (-WX, 5.3, 0.25), 90), ("entrada_sacristia", (-2.7, 5.3, 0.25), -90)):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e); e.location = loc
    e.rotation_euler.z = math.radians(yaw)  # the door's front (Godot +z) into the nave; coming up, facing in
for name, loc in (("entrada", (0, -5.6, 0)), ("porta", (0, -WY, 0)), ("luz_altar", (0, 5.4, 1.9)),
                  ("luz_vela_a", (0.55, COFFIN_Y - 1.0, 1.5)), ("luz_vela_b", (-0.55, COFFIN_Y + 1.0, 1.5)),
                  ("luz_velario", (-2.6, 3.3, 1.3)), ("luz_janela_a", (-3.0, -3.0, 2.8)), ("luz_janela_b", (3.0, 0.0, 2.8)),
                  ("luz_janela_c", (-3.0, 3.0, 2.8)), ("porta_torre", (2.4, -WY, 0)), ("entrada_torre", (2.4, -5.7, 0)),
                  ("corda_sino", (1.3, -5.25, 0))):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e); e.location = loc

tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH" for p in o.data.polygons)
print("CAPELA objects=%d tris~%d" % (len(bpy.data.objects), tris))
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "capela"))
bpy.ops.export_scene.gltf(filepath=paths.level("capela"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)

# --- preview: cutaway (ceiling hidden) and the altar from the aisle -----------------------------------------------
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x, sc.render.resolution_y = 1280, 800
sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.05, 0.05, 0.06)
for name, loc, power, col in (("l1", (0, 5.0, 2.2), 120, (1, 0.7, 0.42)), ("l2", (0, COFFIN_Y, 1.6), 60, (1, 0.62, 0.3)),
                              ("l3", (-2.6, 3.3, 1.3), 40, (1, 0.6, 0.28)), ("l4", (0, -2.0, 4.0), 150, (0.7, 0.75, 0.85))):
    L = bpy.data.objects.new(name, bpy.data.lights.new(name, "POINT")); sc.collection.objects.link(L)
    L.location = loc; L.data.energy = power; L.data.color = col
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
for name, loc, at, lens in (("corte", (0, -14.5, 13.0), (0, 0.6, 0.6), 24), ("altar", (0.6, -1.5, 1.7), (0, 6.0, 2.0), 22)):
    cam.location = loc; cam.data.lens = lens
    cam.rotation_euler = (Vector(at) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    bpy.data.objects["teto-col"].hide_render = name == "corte"
    sc.render.filepath = paths.render("cenarios", "capela_%s.png" % name)
    bpy.ops.render.render(write_still=True)

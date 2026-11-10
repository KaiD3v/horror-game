# Seu Bento's shop ("Secos e Molhados", the sobrado casa_07 on the square), the interior as its own scene, Zelda
# style (vila_kit.Room). A 1970s country store: the long counter with the scales and the sweet jars, shelves to the
# ceiling behind it, open sacks of rice, beans, coffee and maize, a kerosene drum, sausages and garlic from the
# beams, a drinking corner with a draughts board, a saint's niche with a candle, the stair to the family's rooms
# nailed shut ("PARTICULAR"), and by the door a board of PROCURA-SE notices: the people who went up to the Colônia.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/venda_build.py
#   -> blender/cenarios/venda.blend, godot_demo/models/levels/venda.glb, renders/cenarios/venda_{corte,balcao}.png
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces, Room

for name, tex, tint in (("rice", "cloth", (1.0, 0.98, 0.9)), ("beans", "cloth", (0.3, 0.14, 0.11)),
                        ("coffee", "cloth", (0.34, 0.22, 0.13)), ("maize", "hay", (1.25, 1.05, 0.5)),
                        ("cheese", "cloth", (1.05, 0.86, 0.45)), ("sausage", "burlap", (1.1, 0.55, 0.4)),
                        ("bottle_green", "cloth", (0.3, 0.45, 0.32)), ("bottle_brown", "cloth", (0.45, 0.3, 0.18)),
                        ("tin", "machine", (0.75, 0.75, 0.7)), ("saint", "cloth", (0.9, 0.74, 0.62))):
    mat(name, tex, 1.0, tint=tint)
for k in ("paper_procura", "calendario", "dama", "sign_particular"):
    mat(k, k, None)
rng = random.Random("venda")
WX, WY, HT = 4.5, 3.5, 3.2
R_ = Room(WX, WY, HT)
STAIR_X, STAIR_Y0, RISE, RUN, STEPS = 3.95, -0.4, 0.34, 0.4, 9
CY = 0.9  # counter centre line


def pinned(b, c, w, h, a, m):
    """A paper (fit quad) pinned flat on the front wall's board, facing into the room, turned by a radians."""
    pts = []
    for dx, dz in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        x, z = dx * w / 2, dz * h / 2
        x, z = x * math.cos(a) - z * math.sin(a), x * math.sin(a) + z * math.cos(a)
        pts.append(Vector(c) + Vector((-x, 0, z)))  # u runs along -x on the front wall
    b.poly(pts, m)


def bottle(b, x, y, z, m):
    frustum(b, (x, y, z), (x, y, z + 0.2), 0.04, 0.04, 6, m, caps=True)
    frustum(b, (x, y, z + 0.2), (x, y, z + 0.3), 0.025, 0.014, 5, m, caps=True)


# --- the room: whitewash over a green dado (like outside), the ceiling open over the stair ---------------------------
room = B()
R_.shell(room, "whitewash", door_w=1.6, leaves=2, windows=(("front", 3.0), ("front", -3.0), ("left", -1.6)))
R_.dado(room, "barra_green", door_w=1.6)  # painted dado under the windows
obj(room, "sala-col")
roof = B(); R_.ceiling(roof, hole=(STAIR_X - 0.5, WX, STAIR_Y0 + RUN * (STEPS - 4), WY)); obj(roof, "teto-col")

# --- solid furniture: counter, shelves, stair (nailed shut), drinking corner, drum, barrels ---------------------------
s = B()
bx(s, (-0.65, CY, 0.98), (5.1, 0.64, 0.06), "planks")
bx(s, (-0.65, CY - 0.28, 0.48), (5.1, 0.06, 0.95), "siding_brown")
for x in (-3.15, 1.85):
    bx(s, (x, CY, 0.48), (0.08, 0.6, 0.95), "planks")
for zz in (0.45, 1.05, 1.65, 2.25, 2.85):  # shelves to the ceiling along the back wall
    bx(s, (-0.8, WY - 0.22, zz), (7.4, 0.4, 0.04), "planks")
for x in (-4.45, -2.6, -0.8, 1.0, 2.85):
    bx(s, (x, WY - 0.22, HT / 2), (0.06, 0.4, HT), "planks")
for k in range(STEPS):  # the stair up the right wall, into the dark
    bx(s, (STAIR_X, STAIR_Y0 + RUN * (k + 0.5), RISE * (k + 1) / 2), (0.95, RUN, RISE * (k + 1)), "planks")
bx(s, (STAIR_X - 0.5, -0.5, 0.6), (0.1, 0.1, 1.2), "planks")  # newel post, and planks nailed across
for zz, tilt in ((0.45, 0.06), (0.95, -0.05)):
    bx(s, (STAIR_X - 0.02, -0.52, zz), (1.0, 0.04, 0.16), "fence", rot=(0, tilt, 0))
c = Vector((-3.2, -1.8, 0))  # drinking corner: round table, three chairs
frustum(s, c + Vector((0, 0, 0.72)), c + Vector((0, 0, 0.77)), 0.5, 0.5, 10, "planks", caps=True)
bx(s, c + Vector((0, 0, 0.36)), (0.08, 0.08, 0.72), "planks")
for a in (20, 140, 260):
    r = math.radians(a); p = c + Vector((0.72 * math.cos(r), 0.72 * math.sin(r), 0)); yaw = r + math.pi / 2
    M = Matrix.LocRotScale(p, Euler((0, 0, yaw)), None)
    s.box(M @ Matrix.LocRotScale(Vector((0, 0, 0.45)), None, Vector((0.42, 0.42, 0.05))), "planks")
    for dx in (-0.17, 0.17):
        for dy in (-0.17, 0.17):
            s.box(M @ Matrix.LocRotScale(Vector((dx, dy, 0.22)), None, Vector((0.04, 0.04, 0.45))), "planks")
        s.box(M @ Matrix.LocRotScale(Vector((dx, 0.19, 0.7)), None, Vector((0.04, 0.04, 0.5))), "planks")
    s.box(M @ Matrix.LocRotScale(Vector((0, 0.19, 0.85)), None, Vector((0.38, 0.03, 0.12))), "planks")
c = Vector((3.85, -3.0, 0))  # kerosene drum with its hand pump
frustum(s, c, c + Vector((0, 0, 0.9)), 0.3, 0.3, 10, "can", caps=True)
bx(s, c + Vector((0, 0, 1.05)), (0.06, 0.06, 0.3), "iron"); bx(s, c + Vector((0.08, 0, 1.18)), (0.2, 0.03, 0.03), "iron")
merge(s, k_barril(), 3.0, -2.95, yaw=20)
frustum(s, (1.75, 2.45, 0.45), (2.6, 2.45, 0.45), 0.3, 0.3, 8, "barrel", caps=True)  # cachaça barrel on its cradle
for x in (1.9, 2.45):
    bx(s, (x, 2.45, 0.1), (0.08, 0.6, 0.2), "planks")
bx(s, (1.7, 2.45, 0.4), (0.06, 0.03, 0.03), "iron")
merge(s, k_caixote(), -3.9, 2.25, yaw=8); merge(s, k_caixote(), -3.85, 2.3, 0.6, yaw=-12)
obj(s, "moveis-col")

# --- small things: no collision -------------------------------------------------------------------------------
t = B()
z = 1.01
c = Vector((-0.2, CY - 0.05, z))  # the scales: base, post, beam, two pans
bx(t, c + Vector((0, 0, 0.03)), (0.3, 0.18, 0.06), "iron"); bx(t, c + Vector((0, 0, 0.2)), (0.03, 0.03, 0.3), "iron")
bx(t, c + Vector((0, 0, 0.35)), (0.42, 0.02, 0.02), "iron", rot=(0, 0.06, 0))
for dx, dz in ((-0.2, 0.3), (0.2, 0.26)):
    frustum(t, c + Vector((dx, 0, dz)), c + Vector((dx, 0, dz + 0.03)), 0.06, 0.09, 8, "tin", caps=True)
for i, m in enumerate(("cloth_red", "cloth_blue", "maize", "cloth_white")):  # sweet jars along the counter
    x = -2.7 + 0.25 * i
    frustum(t, (x, CY - 0.1, z), (x, CY - 0.1, z + 0.12), 0.07, 0.07, 6, m, caps=True)        # sweets
    frustum(t, (x, CY - 0.1, z + 0.12), (x, CY - 0.1, z + 0.24), 0.08, 0.07, 6, "jar", caps=True)
    frustum(t, (x, CY - 0.1, z + 0.24), (x, CY - 0.1, z + 0.27), 0.05, 0.05, 6, "iron", caps=True)
bx(t, (-1.2, CY, z + 0.02), (0.34, 0.24, 0.04), "burlap", rot=(0, 0, 0.12))                 # the FIADO book, open
bx(t, (-1.2, CY, z + 0.045), (0.3, 0.2, 0.01), "cloth_white", rot=(0, 0, 0.12))
frustum(t, (0.55, CY + 0.15, z + 0.08), (0.95, CY + 0.15, z + 0.08), 0.07, 0.07, 8, "cloth_white", caps=True)  # paper roll
c = Vector((1.3, CY, z))  # oil lamp
frustum(t, c, c + Vector((0, 0, 0.04)), 0.08, 0.07, 6, "iron", caps=True)
frustum(t, c + Vector((0, 0, 0.04)), c + Vector((0, 0, 0.2)), 0.05, 0.045, 6, "lampglass", caps=True)
frustum(t, c + Vector((0, 0, 0.2)), c + Vector((0, 0, 0.25)), 0.035, 0.02, 6, "iron", caps=True)
for zz in (0.45, 1.05, 1.65, 2.25, 2.85):  # the shelves, packed
    x = -4.35
    while x < 2.7:
        k = rng.random()
        if k < 0.35:
            bottle(t, x + 0.05, WY - 0.2 + rng.uniform(-0.08, 0.08), zz + 0.02, rng.choice(("bottle_green", "bottle_brown", "jar")))
            x += 0.11
        elif k < 0.6:
            bx(t, (x + 0.07, WY - 0.2, zz + 0.1), (0.13, 0.13, 0.18), rng.choice(("can", "tin")), rot=(0, 0, rng.uniform(0, 1)))
            x += 0.16
        elif k < 0.85:
            w = rng.uniform(0.18, 0.3)
            bx(t, (x + w / 2, WY - 0.2, zz + 0.12), (w, 0.22, 0.22), rng.choice(("cloth_blue", "cloth_red", "cloth_white", "burlap")),
               rot=(0, 0, rng.uniform(-0.1, 0.1)))
            x += w + 0.04
        else:
            x += rng.uniform(0.15, 0.4)  # a gap: things sold and never restocked
for side, x0 in ((-1, 2.2), (1, 2.62)):  # a ladder against the shelves
    bx(t, (x0, WY - 0.55, 1.35), (0.05, 0.05, 2.75), "planks", rot=(0.18, 0, 0))
for k in range(7):
    bx(t, (2.41, WY - 0.36 - 0.05 * k, 0.3 + 0.38 * k), (0.42, 0.04, 0.04), "planks")
for i, (x, y, m) in enumerate(((2.6, -0.5, "rice"), (2.6, -1.2, "beans"), (1.95, -0.85, "coffee"), (2.5, -1.9, "maize"))):
    frustum(t, (x, y, 0), (x, y, 0.52), 0.25, 0.22, 8, "burlap", caps=True)                # open sacks, rims rolled
    frustum(t, (x, y, 0.5), (x, y, 0.56), 0.27, 0.27, 8, "burlap")
    frustum(t, (x, y, 0.5), (x, y, 0.53), 0.22, 0.2, 8, m, caps=True)
    bx(t, (x + 0.08, y, 0.6), (0.06, 0.18, 0.05), "tin", rot=(0.6, 0, 0.5 * i))               # scoop
for i in range(3):  # cheese wheels on the barrel
    frustum(t, (3.0 + 0.05 * i, -2.95, 0.86 + 0.1 * i), (3.0 + 0.05 * i, -2.95, 0.95 + 0.1 * i), 0.15, 0.15, 8, "cheese", caps=True)
c = Vector((-3.2, -1.8, 0.77))  # on the table: a bottle, two cups, the draughts board
bottle(t, c.x + 0.2, c.y + 0.1, c.z, "jar")
for dx in (-0.15, 0.25):
    frustum(t, c + Vector((dx, -0.2, 0)), c + Vector((dx, -0.2, 0.08)), 0.03, 0.035, 6, "tin", caps=True)
t.poly([c + Vector((x, y, 0.005)) for x, y in ((-0.38, -0.08), (-0.02, -0.08), (-0.02, 0.28), (-0.38, 0.28))], "dama")
for i in range(4):  # sausages and garlic from the beam over the counter's front
    x = -2.6 + 0.35 * i
    for k in range(4):
        z0 = HT - 0.25 - 0.13 * k
        frustum(t, (x, 0.0, z0), (x + 0.01 * (k % 2), 0.0, z0 - 0.12), 0.03, 0.03, 5, "sausage", caps=True)
for x in (0.7, 1.05):
    for k in range(6):
        bx(t, (x + 0.025 * (k % 2), 0.0, HT - 0.3 - 0.07 * k), (0.055, 0.055, 0.05), "rice", rot=(0.3, 0.2, k))
for x, kind in ((-1.5, "bucket"), (1.6, "bucket"), (-0.6, "rope")):  # buckets, rope from the front beam
    if kind == "bucket":
        bx(t, (x, -2.0, HT - 0.35), (0.01, 0.01, 0.3), "iron")
        frustum(t, (x, -2.0, HT - 0.8), (x, -2.0, HT - 0.5), 0.11, 0.14, 8, "tin", caps=True)
    else:
        frustum(t, (x, -2.0, HT - 0.75), (x, -2.0, HT - 0.35), 0.16, 0.16, 8, "burlap")
c = Vector((0, -1.5, 2.4))  # hanging lamp
bx(t, c + Vector((0, 0, 0.3)), (0.01, 0.01, 0.4), "iron")
frustum(t, c, c + Vector((0, 0, 0.18)), 0.07, 0.06, 6, "lampglass", caps=True)
frustum(t, c + Vector((0, 0, 0.18)), c + Vector((0, 0, 0.26)), 0.1, 0.02, 6, "iron", caps=True)
# left wall: the calendar, the radio on its shelf, the saint's niche with a candle
R_.quad(t, "left", 0.2, 0.6, 1.5, 2.0, "calendario", e=0.02)
c = Vector((-WX + 0.08, -0.45, 1.95))  # pendulum wall clock between the window and the calendar (sounds: relogio)
bx(t, c, (0.14, 0.34, 0.88), "barrel")
frustum(t, c + Vector((0.07, 0, 0.27)), c + Vector((0.09, 0, 0.27)), 0.12, 0.12, 12, "cloth_white", caps=True)
bx(t, c + Vector((0.095, 0, 0.3)), (0.01, 0.012, 0.08), "iron"); bx(t, c + Vector((0.097, 0.03, 0.26)), (0.01, 0.06, 0.012), "iron")
bx(t, c + Vector((0.071, 0, -0.17)), (0.01, 0.2, 0.38), "pit")                      # the pendulum's window
bx(t, c + Vector((0.075, 0, -0.12)), (0.01, 0.01, 0.26), "tin"); frustum(t, c + Vector((0.07, 0, -0.27)), c + Vector((0.085, 0, -0.27)), 0.05, 0.05, 8, "tin", caps=True)
bx(t, (-WX + 0.15, 1.5, 1.45), (0.3, 0.6, 0.04), "planks")
bx(t, (-WX + 0.17, 1.5, 1.6), (0.26, 0.42, 0.26), "barrel")
bx(t, (-WX + 0.305, 1.42, 1.6), (0.01, 0.22, 0.16), "burlap"); bx(t, (-WX + 0.305, 1.65, 1.6), (0.012, 0.05, 0.05), "iron")
c = Vector((-WX + 0.15, 2.7, 1.75))
for off, size in (((0, 0, 0), (0.3, 0.4, 0.03)), ((0, 0, 0.45), (0.3, 0.4, 0.03)), ((0, -0.2, 0.22), (0.3, 0.03, 0.45)),
                  ((0, 0.2, 0.22), (0.3, 0.03, 0.45)), ((-0.14, 0, 0.22), (0.02, 0.4, 0.45))):
    bx(t, c + Vector(off), size, "barrel")
frustum(t, c + Vector((0, 0, 0.02)), c + Vector((0, 0, 0.24)), 0.06, 0.035, 6, "cloth_blue", caps=True)  # the saint
frustum(t, c + Vector((0, 0, 0.24)), c + Vector((0, 0, 0.31)), 0.03, 0.025, 6, "saint", caps=True)
frustum(t, c + Vector((0.08, -0.1, 0.02)), c + Vector((0.08, -0.1, 0.1)), 0.015, 0.015, 5, "cloth_white", caps=True)
frustum(t, c + Vector((0.08, -0.1, 0.1)), c + Vector((0.08, -0.1, 0.14)), 0.01, 0.002, 4, "lampglass", caps=True)
# by the door: a board of PROCURA-SE notices, and the stair's sign
bx(t, (1.6, -WY + 0.03, 1.75), (1.35, 0.03, 0.95), "burlap")
for i, (x, zz, a) in enumerate(((1.15, 2.0, 0.06), (1.55, 2.02, -0.04), (2.0, 1.98, 0.1), (1.3, 1.5, -0.08), (1.75, 1.52, 0.03),
                                 (2.12, 1.48, -0.12))):
    pinned(t, (x, -WY + 0.05 + 0.001 * i, zz), 0.3, 0.38, a, "paper_procura")
t.poly([Vector((STAIR_X - 0.38, -0.56, 0.86)), Vector((STAIR_X + 0.38, -0.56, 0.86)),
        Vector((STAIR_X + 0.38, -0.56, 1.05)), Vector((STAIR_X - 0.38, -0.56, 1.05))], "sign_particular")
bx(t, (-0.6, -0.2, 0.005), (2.4, 1.0, 0.01), "burlap")
obj(t, "objetos")

# --- markers for venda.gd (interior.gd) -------------------------------------------------------------------------
for name, loc in (("entrada", (0, -2.6, 0)), ("porta", (0, -WY, 0)), ("npc_vendeiro", (-0.8, 1.75, 0)),
                  ("luz_lamparina", (1.3, CY, 1.32)), ("luz_lampiao", (0, -1.5, 2.35)), ("luz_vela", (-WX + 0.3, 2.6, 1.95)),
                  ("luz_janela_a", (3.0, -2.9, 1.6)), ("luz_janela_b", (-3.0, -2.9, 1.6)), ("luz_janela_c", (-3.9, -1.6, 1.6)),
                  ("som_relogio", (-WX + 0.2, -0.45, 2.0)), ("som_musica_venda", (-WX + 0.3, 1.5, 1.6))):  # the radio
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e); e.location = loc

tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH" for p in o.data.polygons)
print("VENDA objects=%d tris~%d" % (len(bpy.data.objects), tris))
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "venda"))
bpy.ops.export_scene.gltf(filepath=paths.level("venda"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)

# --- preview: cutaway (ceiling hidden) and the counter --------------------------------------------------------------
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x, sc.render.resolution_y = 1280, 800
sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.06, 0.06, 0.07)
for name, loc, power, col in (("l1", (1.3, CY, 1.32), 60, (1, 0.7, 0.4)), ("l2", (0, -1.5, 2.3), 140, (1, 0.75, 0.45)),
                              ("l3", (-WX + 0.3, 2.6, 1.95), 15, (1, 0.6, 0.3)), ("l4", (0, -1.5, 2.8), 80, (0.75, 0.78, 0.85))):
    L = bpy.data.objects.new(name, bpy.data.lights.new(name, "POINT")); sc.collection.objects.link(L)
    L.location = loc; L.data.energy = power; L.data.color = col
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
for name, loc, at, lens in (("corte", (0, -10.5, 9.0), (0, 0.4, 0.6), 24), ("balcao", (0.8, -2.8, 1.6), (-0.6, 2.4, 1.4), 20)):
    cam.location = loc; cam.data.lens = lens
    cam.rotation_euler = (Vector(at) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    bpy.data.objects["teto-col"].hide_render = name == "corte"
    sc.render.filepath = paths.render("cenarios", "venda_%s.png" % name)
    bpy.ops.render.render(write_still=True)

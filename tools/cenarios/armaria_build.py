# Tenório's gun shop ("Armas e Munição", casa_08 in the village), the interior as its own scene, Zelda style:
# the village door brings you here, this door takes you back. A bit bigger inside than out (8 x 6.5 m) so the
# third-person camera has room. Same kit as the village (vila_kit.py). Godot: armaria.gd.
# Run (from the project root): blender -b --factory-startup --python tools/cenarios/armaria_build.py
#   -> blender/cenarios/armaria.blend, godot_demo/models/levels/armaria.glb, renders/cenarios/armaria_{corte,balcao}.png
import bpy, math, os, random, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder, prop pieces

mat("bone", "linen", 1.0, tint=(0.95, 0.88, 0.70)); mat("hide", "burlap", 1.0, tint=(0.95, 0.72, 0.5))
rng = random.Random("armaria")
WX, WY, HT = 4.0, 3.25, 3.0  # half width (x), half depth (y), height
BACK_DOOR_X = -3.0
R_ = Room(WX, WY, HT)


def gun(b, c, length=1.15):  # long gun on wall pegs, barrel to +x
    c = Vector(c)
    frustum(b, c + Vector((-0.1, 0, 0)), c + Vector((length * 0.62, 0, 0.012)), 0.024, 0.02, 5, "blade", caps=True)
    bx(b, c + Vector((-0.3, 0, -0.04)), (0.42, 0.05, 0.12), "planks", rot=(0, 0.12, 0))      # stock
    bx(b, c + Vector((0.08, 0, -0.025)), (0.28, 0.055, 0.06), "planks")                      # fore-end


# --- the room: floor, walls, ceiling and beams (solid), a back door to the store room -----------------------
room = B()
R_.shell(room, "siding_grey", door_w=1.0, back_doors=(BACK_DOOR_X,),
         windows=(("front", 2.4), ("front", -2.4), ("left", -1.8), ("right", 1.4)))  # right: clear of trap and hide
obj(room, "sala-col")
roof = B(); R_.ceiling(roof); obj(roof, "teto-col")

# --- the counter across the room; Tenório behind it ------------------------------------------------------------
cnt = B()
CY = 0.8  # counter centre line
bx(cnt, (-0.3, CY, 0.98), (5.0, 0.64, 0.06), "planks")
bx(cnt, (-0.3, CY - 0.28, 0.48), (5.0, 0.06, 0.95), "siding_red")
for x in (-2.75, 2.15):
    bx(cnt, (x, CY, 0.48), (0.08, 0.6, 0.95), "planks")
bx(cnt, (-0.3, CY - 0.33, 0.05), (5.0, 0.04, 0.1), "planks")  # kick board
obj(cnt, "balcao-col")

top = B()  # on the counter: no collision (the camera would snag on them)
z = 1.01
frustum(top, (1.6, CY, z), (1.6, CY, z + 0.04), 0.08, 0.07, 6, "iron", caps=True)          # oil lamp
frustum(top, (1.6, CY, z + 0.04), (1.6, CY, z + 0.2), 0.05, 0.045, 6, "lampglass", caps=True)
frustum(top, (1.6, CY, z + 0.2), (1.6, CY, z + 0.25), 0.035, 0.02, 6, "iron", caps=True)
for i in range(3):  # boxes of shells
    bx(top, (0.85, CY - 0.05, z + 0.05 + 0.1 * i), (0.22, 0.14, 0.1), "can", rot=(0, 0, 0.15 * i))
bx(top, (0.25, CY - 0.1, z + 0.02), (0.24, 0.05, 0.04), "iron", rot=(0, 0, 0.3))           # revolver: barrel
bx(top, (0.12, CY - 0.17, z + 0.02), (0.06, 0.1, 0.04), "planks", rot=(0, 0, 0.3))          # ... grip
bx(top, (-0.55, CY, z + 0.02), (0.34, 0.25, 0.04), "burlap", rot=(0, 0, -0.1))              # ledger
bx(top, (-0.55, CY - 0.02, z + 0.045), (0.3, 0.2, 0.01), "cloth_white", rot=(0, 0, -0.1))
bx(top, (-1.55, CY - 0.05, z + 0.005), (0.6, 0.4, 0.01), "burlap")                          # knives on a cloth
for i in range(3):
    bx(top, (-1.75 + 0.2 * i, CY - 0.05, z + 0.015), (0.04, 0.26, 0.01), "blade", rot=(0, 0, 0.1 * i - 0.1))
    bx(top, (-1.75 + 0.2 * i + 0.012 * (i - 1), CY - 0.22, z + 0.02), (0.035, 0.1, 0.02), "planks", rot=(0, 0, 0.1 * i - 0.1))
frustum(top, (-2.4, CY, z), (-2.4, CY, z + 0.16), 0.07, 0.07, 6, "jar", caps=True)          # bolts in a pot
for i in range(7):
    a = 2 * math.pi * i / 7; p = Vector((-2.4 + 0.035 * math.cos(a), CY + 0.035 * math.sin(a), z + 0.1))
    bx(top, p + Vector((0, 0, 0.14)), (0.008, 0.008, 0.28), "planks", rot=(0.1 * math.sin(a), 0.1 * math.cos(a), 0))
    bx(top, p + Vector((0, 0, 0.26)), (0.004, 0.02, 0.04), "cloth_red", rot=(0, 0, a))
frustum(top, (-0.3, CY + 0.75, 0), (-0.3, CY + 0.75, 0.62), 0.18, 0.16, 6, "planks", caps=True)  # his stool
obj(top, "balcao_objetos")

# --- back wall: guns on pegs, machetes, axes, and the trophy over them ------------------------------------------
wall = B(); ws = B()  # wall: solid; ws: small things hung on the walls (no collision)
for zg in (1.45, 1.75, 2.05):
    gun(ws, (-0.35, WY - 0.06, zg))
    for x in (-0.5, 0.35):
        bx(ws, (x, WY - 0.04, zg - 0.05), (0.04, 0.08, 0.04), "planks")
for i in range(4):  # machetes hanging blade-down from nails
    x = 1.35 + 0.28 * i
    bx(ws, (x, WY - 0.03, 1.45), (0.07, 0.015, 0.5), "blade", rot=(0, 0.05 * (i - 1.5), 0))
    bx(ws, (x, WY - 0.03, 1.78), (0.04, 0.03, 0.15), "planks")
for i, x in enumerate((-1.75, -1.35)):  # axes
    bx(ws, (x, WY - 0.04, 1.5), (0.04, 0.04, 0.75), "planks", rot=(0, 0.1 * (i - 0.5), 0))
    bx(ws, (x + 0.06, WY - 0.04, 1.82), (0.16, 0.03, 0.11), "blade")
# trophy: the skull of something that was a deer, on a wooden shield: a third eye socket, antlers grown wrong
c = Vector((-0.1, WY - 0.06, 2.6))
bx(ws, c, (0.42, 0.04, 0.5), "planks")
bx(ws, c + Vector((0, -0.14, -0.04)), (0.17, 0.24, 0.17), "bone")                          # cranium
bx(ws, c + Vector((0, -0.34, -0.1)), (0.1, 0.24, 0.09), "bone", rot=(0.25, 0, 0))           # snout
for sx, zz in ((-0.065, 0.0), (0.065, 0.0), (0.0, 0.065)):                                   # three eye sockets
    bx(ws, c + Vector((sx, -0.26, -0.03 + zz)), (0.045, 0.02, 0.045), "pit")
for sx in (-1, 1):
    base = c + Vector((sx * 0.07, -0.14, 0.05))
    tip = base + Vector((sx * 0.22, -0.05, 0.3))
    frustum(ws, base, tip, 0.022, 0.012, 4, "bone", caps=True)
    for t, off in ((0.4, (sx * 0.12, -0.08, 0.06)), (0.7, (-sx * 0.04, -0.1, 0.12)), (0.55, (sx * 0.02, 0.02, 0.16))):
        p = base.lerp(tip, t)
        frustum(ws, p, p + Vector(off), 0.012, 0.004, 4, "bone", caps=True)
frustum(ws, c + Vector((0.05, -0.12, 0.08)), c + Vector((0.12, -0.2, 0.2)), 0.015, 0.003, 4, "bone", caps=True)  # a third, stunted
# left wall: shelves of cans, jars and boxes
for zz in (0.95, 1.45, 1.95):
    bx(wall, (-WX + 0.2, 1.2, zz), (0.36, 2.6, 0.04), "planks")
    for i in range(int(rng.uniform(5, 8))):
        y = 0.05 + rng.uniform(0, 2.3); kind = rng.random()
        if kind < 0.4:
            frustum(ws, (-WX + 0.2, y, zz + 0.02), (-WX + 0.2, y, zz + 0.2), 0.06, 0.055, 6, "jar", caps=True)
        elif kind < 0.75:
            bx(ws, (-WX + 0.2, y, zz + 0.1), (0.12, 0.12, 0.18), "can", rot=(0, 0, rng.uniform(0, 1)))
        else:
            bx(ws, (-WX + 0.22, y, zz + 0.08), (0.25, 0.2, 0.14), "burlap", rot=(0, 0, rng.uniform(-0.3, 0.3)))
for y in (0.0, 2.45):
    bx(wall, (-WX + 0.2, y, 1.05), (0.36, 0.04, 2.1), "planks")
# right wall: a bear trap and a stretched hide
c = Vector((WX - 0.05, 1.0, 1.85))
frustum(ws, c + Vector((0.01, 0, 0)), c + Vector((-0.04, 0, 0)), 0.26, 0.26, 10, "iron")
for i in range(10):
    a = 2 * math.pi * i / 10; p = c + Vector((-0.03, 0.26 * math.cos(a), 0.26 * math.sin(a)))
    frustum(ws, p, p + Vector((-0.02, -0.08 * math.cos(a), -0.08 * math.sin(a))), 0.018, 0.002, 4, "iron", caps=True)
bx(ws, c + Vector((-0.02, 0, 0.32)), (0.02, 0.02, 0.12), "iron")  # nail and chain
bx(ws, (WX - 0.03, 2.35, 1.6), (0.02, 0.85, 1.05), "hide", rot=(0.12, 0, 0))
for sy, sz in ((-1, -1), (-1, 1), (1, -1), (1, 1)):  # its four legs pinned out
    bx(ws, (WX - 0.03, 2.35 + sy * 0.48, 1.6 + sz * 0.5), (0.02, 0.18, 0.12), "hide", rot=(sy * sz * 0.6, 0, 0))

# --- corners: wood stove with a glow, firewood, barrels, crates, sacks; a rug; the stain by the store room --------
c = Vector((-3.4, -2.55, 0))
bx(wall, c + Vector((0, 0, 0.42)), (0.8, 0.6, 0.84), "iron")
bx(ws, c + Vector((0, -0.31, 0.38)), (0.32, 0.02, 0.2), "ember")            # embers through the grate
frustum(wall, c + Vector((0.15, 0.1, 0.84)), c + Vector((0.15, 0.1, HT)), 0.08, 0.08, 6, "iron")
merge(wall, k_lenha(), -2.4, -2.95, yaw=0)
for x, y in ((3.45, 2.75), (2.85, 2.9), (3.5, 2.15)):
    merge(wall, k_barril(), x, y, yaw=rng.uniform(0, 360))
for x, y, zz, yaw in ((-3.5, 2.85, 0, 10), (-2.9, 2.85, 0, -8), (-3.3, 2.8, 0.6, 30), (3.45, -2.75, 0, 20)):
    merge(wall, k_caixote(), x, y, zz, yaw)
for x, y in ((2.85, -2.85), (3.3, -2.25)):
    bx(wall, (x, y, 0.16), (0.42, 0.32, 0.32), "burlap", rot=(0, 0, rng.uniform(-0.5, 0.5)))
obj(wall, "moveis-col")
bx(ws, (0, -1.3, 0.005), (2.2, 1.5, 0.01), "burlap")                          # rug
for i in range(4):                                                             # the stain before the store room
    bx(ws, (BACK_DOOR_X + rng.uniform(-0.3, 0.3), WY - 0.5 - rng.uniform(0, 0.5), 0.004),
       (rng.uniform(0.15, 0.4), rng.uniform(0.1, 0.3), 0.004), "pit", rot=(0, 0, rng.uniform(0, 3)))
# hanging lamp from the middle beam
c = Vector((0, -0.6, 2.2))
bx(ws, c + Vector((0, 0, 0.38)), (0.01, 0.01, 0.42), "iron")
frustum(ws, c, c + Vector((0, 0, 0.18)), 0.07, 0.06, 6, "lampglass", caps=True)
frustum(ws, c + Vector((0, 0, 0.18)), c + Vector((0, 0, 0.26)), 0.1, 0.02, 6, "iron", caps=True)
obj(ws, "objetos")

# --- markers for armaria.gd ------------------------------------------------------------------------------------
for name, loc, yaw in (("entrada", (0, -2.3, 0), 0), ("porta", (0, -WY, 0), 0), ("npc_armeiro", (-0.3, 1.6, 0), 0),
                       ("luz_lamparina", (1.6, CY, 1.32), 0), ("luz_lampiao", (0, -0.6, 2.1), 0),
                       ("luz_fogao", (-3.4, -2.2, 0.5), 0), ("luz_janela_a", (2.4, -2.6, 1.6), 0),
                       ("luz_janela_b", (-2.4, -2.6, 1.6), 0)):
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    e.location = loc; e.rotation_euler.z = math.radians(yaw)

tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH" for p in o.data.polygons)
print("ARMARIA objects=%d tris~%d" % (len(bpy.data.objects), tris))
bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "armaria"))
bpy.ops.export_scene.gltf(filepath=paths.level("armaria"), export_format="GLB",
                          export_yup=True, export_apply=False, use_selection=False)

# --- preview: cutaway from above the front wall (ceiling hidden), and the counter, lit by the lamps -------------
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x, sc.render.resolution_y = 1280, 800
sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.06, 0.06, 0.07)
for name, loc, power, col in (("l1", (1.6, CY, 1.32), 60, (1, 0.7, 0.4)), ("l2", (0, -0.6, 2.1), 120, (1, 0.75, 0.45)),
                              ("l3", (-3.4, -2.2, 0.5), 25, (1, 0.45, 0.2)), ("l4", (0, -1.0, 2.6), 60, (0.7, 0.75, 0.85))):
    L = bpy.data.objects.new(name, bpy.data.lights.new(name, "POINT")); sc.collection.objects.link(L)
    L.location = loc; L.data.energy = power; L.data.color = col
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
bpy.data.objects["teto-col"].hide_render = True
for name, loc, at, lens in (("corte", (0, -9.5, 8.5), (0, 0.4, 0.6), 24), ("balcao", (0.6, -2.6, 1.6), (-0.3, 2.2, 1.5), 22)):
    cam.location = loc; cam.data.lens = lens
    cam.rotation_euler = (Vector(at) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    bpy.data.objects["teto-col"].hide_render = name == "corte"
    sc.render.filepath = paths.render("cenarios", "armaria_%s.png" % name)
    bpy.ops.render.render(write_still=True)

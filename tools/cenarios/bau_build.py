# The trunks (baús) that hold what you find, and the things themselves as you hold them up (Godot: chest.gd).
#   bau.glb    a tropeiro's trunk: wood under cowhide, a barrel lid, iron bands and corners, brass tacks, a hasp.
#              Two objects: "bau" (origin on the floor, centre; front = -Y) and "tampa" (the lid, origin on its
#              hinge at the back top edge, so the game opens it by turning it round X).
#   itens.glb  one object per ItemCatalog id (and "embrulho", a cloth bundle for an id with none). Each is built in
#              the frame of the protagonist's left-hand grip bone (grip.L, protagonista_rig.py) as glTF will see
#              it: origin at the end of the handle, the item along Blender +Z (bone Y), its back / spine towards
#              Blender -Y (bone Z, the back of the hand), so the game hangs it on the bone as it is. The fist
#              closes 6 cm up the handle.
# A new item to find: a function here named after its id (and run this again). Run from the project root:
#   blender -b --factory-startup --python tools/cenarios/bau_build.py
#   -> blender/cenarios/bau.blend, godot_demo/models/props/bau.glb, godot_demo/models/props/itens.glb
import bpy, math, os, sys

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
from vila_kit import *  # materials, mesh builder

mat("hide", "burlap", 1.0, tint=(0.62, 0.42, 0.28))          # cowhide, worn
mat("hide_dark", "burlap", 1.0, tint=(0.3, 0.2, 0.15))       # its dark patches
mat("wood_in", "planks", 0.5, tint=(0.5, 0.4, 0.32))         # bare inside
mat("brass", "machine", 1.0, tint=(0.9, 0.72, 0.38))
mat("amber", "cloth", 1.0, tint=(0.55, 0.3, 0.1))
mat("cork", "burlap", 1.0, tint=(0.8, 0.6, 0.4))
mat("twine", "burlap", 1.0, tint=(0.85, 0.75, 0.55))
mat("grip", "planks", 0.3, tint=(0.45, 0.3, 0.2))

W, D, H, T = 0.78, 0.44, 0.40, 0.025   # width (x), depth (y), body height, wall
RISE, RIM, N = 0.10, 0.035, 6          # the lid's arch over its rim, segments


def arch(k):  # a point on the lid's arch, hinge frame: k 0 = front edge, N = back (the hinge)
    a = math.pi * k / N
    return Vector((0, -D / 2 - math.cos(a) * D / 2, RIM + math.sin(a) * RISE))


# --- the trunk: an open wooden box under cowhide, iron corners and bands, brass tacks, side handles -------------------
b = B()
bx(b, (0, 0, T / 2), (W, D, T), "wood_in")
for x in (-1, 1):
    bx(b, (x * (W - T) / 2, 0, H / 2), (T, D, H), "wood_in")
for y in (-1, 1):
    bx(b, (0, y * (D - T) / 2, H / 2), (W - 2 * T, T, H), "wood_in")
e = 0.004  # the hide over the outside
for y in (-1, 1):
    bx(b, (0, y * (D / 2 + e / 2), H / 2), (W, e, H - 0.01), "hide")
for x in (-1, 1):
    bx(b, (x * (W / 2 + e / 2), 0, H / 2), (e, D, H - 0.01), "hide")
for x, z, s in ((-0.2, 0.25, 0.14), (0.12, 0.12, 0.1), (0.25, 0.3, 0.08)):  # dark patches of the hide, front
    bx(b, (x, -D / 2 - e - 0.001, z), (s * 1.3, 0.002, s), "hide_dark")
for x in (-1, 1):  # iron corners and two bands round the body
    for y in (-1, 1):
        bx(b, (x * (W / 2 - 0.01), y * (D / 2 - 0.01), H / 2), (0.05, 0.05, H), "iron")
    bx(b, (x * 0.22, -D / 2 - e - 0.003, H / 2), (0.045, 0.006, H), "iron")
    bx(b, (x * 0.22, D / 2 + e + 0.003, H / 2), (0.045, 0.006, H), "iron")
    bx(b, (x * (W / 2 + e + 0.012), 0, 0.27), (0.012, 0.11, 0.02), "iron")           # handle
    for y in (-1, 1):
        bx(b, (x * (W / 2 + e + 0.006), y * 0.05, 0.27), (0.012, 0.012, 0.04), "iron")
for i in range(9):  # brass tacks along the top and bottom edges of the front
    x = -W / 2 + 0.06 + i * (W - 0.12) / 8
    for z in (0.03, H - 0.03):
        bx(b, (x, -D / 2 - e - 0.004, z), (0.014, 0.008, 0.014), "brass")
bx(b, (0, -D / 2 - e - 0.005, H - 0.07), (0.07, 0.01, 0.08), "iron")                  # the hasp's staple plate
bx(b, (0, -D / 2 - e - 0.014, H - 0.07), (0.02, 0.012, 0.03), "brass")
bau = obj(b, "bau")

# --- the lid: barrel-topped, hide over wood, iron bands over the arch, the hasp hanging off the front --------------
t = B()
for k in range(N):  # the arch, in quads across the width
    p0, p1 = arch(k), arch(k + 1)
    t.poly([Vector((-W / 2, p0.y, p0.z)), Vector((W / 2, p0.y, p0.z)), Vector((W / 2, p1.y, p1.z)), Vector((-W / 2, p1.y, p1.z))], "hide")
for x, s in ((-W / 2, 1), (W / 2, -1)):  # end caps: the arch down to the rim's foot
    pts = [Vector((x, -D, 0))] + [Vector((x, arch(k).y, arch(k).z)) for k in range(N + 1)] + [Vector((x, 0, 0))]
    t.poly(pts if s < 0 else pts[::-1], "hide")
t.poly([Vector((-W / 2, -D, 0)), Vector((-W / 2, -D, RIM)), Vector((W / 2, -D, RIM)), Vector((W / 2, -D, 0))], "hide")  # front rim
t.poly([Vector((-W / 2, 0, 0)), Vector((W / 2, 0, 0)), Vector((W / 2, 0, RIM)), Vector((-W / 2, 0, RIM))], "hide")    # back rim
t.poly([Vector((-W / 2, -D, 0)), Vector((W / 2, -D, 0)), Vector((W / 2, 0, 0)), Vector((-W / 2, 0, 0))][::-1], "wood_in")  # underside
for x in (-0.22, 0.22, -W / 2 + 0.03, W / 2 - 0.03):  # iron bands over the arch
    for k in range(N):
        p0, p1 = arch(k), arch(k + 1); m = (p0 + p1) / 2; d = p1 - p0
        n = Vector((0, -d.z, d.y)).normalized()
        bx(t, (x, m.y + n.y * 0.004, m.z + n.z * 0.004), (0.045, d.length + 0.004, 0.006), "iron",
           rot=(math.atan2(d.z, d.y), 0, 0))
    bx(t, (x, -D - 0.003, RIM / 2), (0.045, 0.006, RIM), "iron")
for i in range(9):
    x = -W / 2 + 0.06 + i * (W - 0.12) / 8
    bx(t, (x, -D - 0.004, RIM / 2), (0.014, 0.008, 0.014), "brass")
bx(t, (0, -D - 0.008, -0.03), (0.05, 0.008, 0.1), "iron")        # the hasp, hanging over the staple
tampa = obj(t, "tampa", loc=(0, D / 2, H))

# --- the things, held up (see the header for their frame) -------------------------------------------------------
GRIP = 0.06  # the fist's middle, up the handle


def facao():  # a cane machete: wooden handle with rivets, a long blade widening to the tip, the edge to +Y
    b = B()
    bx(b, (0, 0, 0.065), (0.024, 0.03, 0.13), "grip")
    for z in (0.03, 0.09):
        bx(b, (0, 0, z), (0.028, 0.008, 0.008), "brass")
    bx(b, (0, 0, 0.135), (0.012, 0.045, 0.012), "iron")
    b.poly([Vector((0, -0.015, 0.14)), Vector((0, 0.025, 0.14)), Vector((0, 0.045, 0.56)), Vector((0, -0.012, 0.6)), Vector((0, -0.02, 0.5))], "blade")
    b.poly([Vector((0.003, -0.015, 0.14)), Vector((0.003, -0.02, 0.5)), Vector((0.003, -0.012, 0.6)), Vector((0.003, 0.045, 0.56)), Vector((0.003, 0.025, 0.14))], "blade")
    return b


def besta():  # the hand crossbow held by its grip: the tiller along +Z over the back of the hand, the prod across
    b = B()
    bx(b, (0, 0, 0.06), (0.03, 0.035, 0.12), "grip")                        # pistol grip, in the fist
    bx(b, (0, -0.045, 0.14), (0.035, 0.04, 0.36), "grip")                   # tiller
    bx(b, (0, -0.07, 0.15), (0.006, 0.012, 0.3), "iron")                    # the rail
    for s in (-1, 1):                                                       # the prod, swept forward
        bx(b, (s * 0.1, -0.05, 0.3), (0.2, 0.014, 0.02), "iron", rot=(0, s * 0.25, 0))
        bx(b, (s * 0.1, -0.072, 0.2), (0.004, 0.004, 0.2), "twine", rot=(0, -s * 0.85, 0))  # the string to the catch
    bx(b, (0, -0.065, 0.11), (0.03, 0.02, 0.02), "iron")                    # the catch
    return b


def virote():  # three bolts tied together, red fletching
    b = B()
    for x, y in ((-0.008, 0), (0.008, 0), (0, -0.012)):
        bx(b, (x, y, 0.1), (0.007, 0.007, 0.28), "planks")
        bx(b, (x, y, 0.245), (0.012, 0.012, 0.02), "iron")
        bx(b, (x, y - 0.006, -0.01), (0.002, 0.014, 0.05), "cloth_red")
    bx(b, (0, -0.004, GRIP), (0.03, 0.026, 0.012), "twine")
    return b


def atadura():  # a roll of clean cloth, a little brown bottle of iodine tied to it
    b = B()
    frustum(b, (-0.035, 0, GRIP), (0.035, 0, GRIP), 0.03, 0.03, 8, "cloth_white", caps=True)
    frustum(b, (0, -0.035, GRIP + 0.03), (0, -0.035, GRIP + 0.09), 0.015, 0.015, 6, "amber", caps=True)
    frustum(b, (0, -0.035, GRIP + 0.09), (0, -0.035, GRIP + 0.11), 0.007, 0.007, 6, "cork", caps=True)
    return b


def garrafada():  # a bottle of cachaça with arnica and herbs, corked
    b = B()
    frustum(b, (0, 0, 0.0), (0, 0, 0.16), 0.034, 0.034, 8, "amber", caps=True)
    frustum(b, (0, 0, 0.16), (0, 0, 0.2), 0.034, 0.012, 8, "amber")
    frustum(b, (0, 0, 0.2), (0, 0, 0.24), 0.012, 0.012, 8, "amber")
    frustum(b, (0, 0, 0.24), (0, 0, 0.265), 0.011, 0.011, 8, "cork", caps=True)
    bx(b, (0, -0.035, 0.09), (0.04, 0.003, 0.05), "cloth_white")            # a paper label
    return b


def chave():  # an old iron key (every key: ItemCatalog "modelo"), a bit of red string through the bow
    b = B()
    frustum(b, (-0.022, 0, GRIP), (0.022, 0, GRIP), 0.02, 0.02, 8, "iron")         # the bow, a ring
    bx(b, (0, 0, GRIP + 0.07), (0.008, 0.008, 0.12), "iron")                         # the shank
    bx(b, (0, -0.012, GRIP + 0.115), (0.006, 0.02, 0.025), "iron")                   # the bit
    bx(b, (0, -0.008, GRIP + 0.13), (0.006, 0.012, 0.006), "iron")
    bx(b, (0, 0.02, GRIP - 0.01), (0.004, 0.004, 0.05), "cloth_red", rot=(0.4, 0, 0))
    return b


def pe_de_cabra():  # a crowbar: a bar of dark iron, the claw bent back at the top, the flat end at the bottom
    b = B()
    bx(b, (0, 0, 0.21), (0.016, 0.016, 0.46), "iron")
    bx(b, (0, -0.028, 0.44), (0.016, 0.07, 0.016), "iron", rot=(-0.35, 0, 0))       # the hook
    for x in (-0.005, 0.005):
        bx(b, (x, -0.06, 0.43), (0.005, 0.014, 0.035), "iron")                       # the claw's two teeth
    bx(b, (0, 0.006, -0.02), (0.02, 0.026, 0.016), "iron", rot=(-0.3, 0, 0))         # the flat end
    return b


def picareta():  # a pickaxe: a wooden handle, the iron head across its top, a point and a chisel end
    b = B()
    bx(b, (0, 0, 0.2), (0.024, 0.03, 0.44), "grip")
    bx(b, (0, 0, 0.42), (0.034, 0.04, 0.05), "iron")                                 # the eye
    for s in (-1, 1):
        frustum(b, (0, 0, 0.42), (0, s * 0.19, 0.42 - 0.03), 0.018, 0.004 if s < 0 else 0.012, 6, "iron", caps=True)
    return b


def corda():  # a coil of sisal rope, tied round its middle, the end hanging down
    b = B()
    for i in range(5):
        frustum(b, (-0.035, 0, GRIP + 0.012 * (i - 2)), (0.035, 0, GRIP + 0.012 * (i - 2)), 0.06, 0.06, 10, "twine", caps=False)
    bx(b, (0, -0.062, GRIP), (0.02, 0.012, 0.075), "burlap")                         # the tie
    bx(b, (0.02, -0.064, GRIP - 0.07), (0.012, 0.012, 0.1), "twine", rot=(0, 0.2, 0))  # the end
    return b


def embrulho():  # anything with no shape of its own yet: a cloth bundle tied with twine
    b = B()
    bx(b, (0, 0, GRIP), (0.1, 0.08, 0.1), "burlap")
    bx(b, (0, 0, GRIP), (0.104, 0.084, 0.012), "twine")
    bx(b, (0, 0, GRIP), (0.012, 0.084, 0.104), "twine")
    bx(b, (0, 0, GRIP + 0.06), (0.02, 0.02, 0.025), "twine")
    return b


items = [obj(f(), f.__name__) for f in (facao, besta, virote, atadura, garrafada, chave, pe_de_cabra, picareta, corda, embrulho)]
for o in [bau, tampa] + items:
    o.select_set(False)

bpy.ops.wm.save_as_mainfile(filepath=paths.blend("cenarios", "bau"))
for name, objs in (("bau", [bau, tampa]), ("itens", items)):
    for o in bpy.data.objects:
        o.select_set(o in objs)
    bpy.ops.export_scene.gltf(filepath=paths.prop(name), export_format="GLB", export_yup=True, use_selection=True)
tris = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in [bau, tampa] + items}
print("BAU", tris)

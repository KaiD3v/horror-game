# The prop kit (vila_kit pieces built once at the origin, front = local -Y) instanced round the village.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler, noise
from vila_kit import *  # materials, mesh builder, prop pieces
from .layout import *

KIT, PLACED = {}, {}


def kit(name, b):
    o = obj(b, name); KIT[name] = o.data; bpy.data.objects.remove(o)


def place(name, x, y, yaw=0.0, dz=0.0, tilt=(0.0, 0.0), col=True):
    """An instance of kit piece `name` on the ground at x, y; `-col` gives it a trimesh body in Godot."""
    PLACED[name] = PLACED.get(name, 0) + 1
    o = bpy.data.objects.new("%s_%02d%s" % (name, PLACED[name], "-col" if col else ""), KIT[name])
    bpy.context.collection.objects.link(o)
    o.location = (x, y, H(x, y) + dz); o.rotation_euler = (tilt[0], tilt[1], math.radians(yaw))


def at_house(i, lx, ly, turn=0.0):  # a spot in house i's frame (front = -Y) -> x, y, yaw
    hx, hy, face = HOUSES[i][:3]; a = math.radians(face)
    return hx + lx * math.cos(a) - ly * math.sin(a), hy + lx * math.sin(a) + ly * math.cos(a), face + turn


def props():
    kit("barril", k_barril()); kit("caixote", k_caixote()); kit("lenha", k_lenha())
    kit("carroca", k_carroca()); kit("carroca_quebrada", k_carroca(True)); kit("roda", k_roda())
    kit("varal_a", k_varal("a")); kit("varal_b", k_varal("b")); kit("espantalho", k_espantalho())
    kit("banco", k_banco()); kit("cocho", k_cocho()); kit("cruzeiro", k_cruzeiro()); kit("placa", k_placa())
    kit("placa_vila", k_placa_vila()); kit("carrinho", k_carrinho()); kit("feno", k_feno())
    # the square: the cross before the chapel, benches, the trough by the well, the signpost
    place("cruzeiro", -4.5, 9.0, 90, dz=-0.2)
    place("banco", 2.0, 12.6, 0); place("banco", -4.0, 0.8, 135); place("banco", 6.0, 0.5, -132)
    place("cocho", 5.6, 4.2, 90, dz=-0.1)
    place("placa", -3.5, -2.0)
    place("placa_vila", 3.6, -42.0, 0)
    # the shop: barrels, crates (one stacked), its cart along the side
    for x, y in ((8.5, 16.6), (8.4, 17.4), (8.9, 17.0)):
        place("barril", x, y, R.uniform(0, 360), dz=-0.05)
    for x, y, dz, yaw in ((8.6, 9.3, 0, 10), (8.5, 8.6, 0, -5), (8.55, 8.95, 0.6, 30)):
        place("caixote", x, y, yaw, dz=dz - 0.05)
    place("carroca", 16.5, 19.8, 200, dz=-0.05)
    # the NPCs' stalls: Seu Bento's counter before the shop door, Tenório's table on the lane with his cart
    kit("banca_vendeiro", k_banca_vendeiro()); kit("banca_armas", k_banca_armas())
    place("banca_vendeiro", 8.2, 10.75, -90, dz=-0.03)  # goods out by the shop wall, clear of its door
    # Tenório's shop (casa_08): his table out on the porch, away from the door, his cart along the side
    dx = DOORS["casa_08"][0]; w, d = HOUSES[7][3:5]
    x, y, yaw = at_house(7, -math.copysign(1.75, dx), -d / 2 - 1.0); place("banca_armas", x, y, yaw, dz=0.6)
    x, y, yaw = at_house(7, w / 2 + 1.9, 0.3, 85); place("carroca", x, y, yaw, dz=-0.05)
    # the broken cart by the road on the way in, tipped onto its axle; its wheel in the grass
    place("carroca_quebrada", -4.6, -26.0, 160, dz=-0.25, tilt=(0, -0.3)); place("roda", -6.4, -24.2, 0, dz=-0.02, col=False)
    place("carrinho", -6.3, -39.5, 30, dz=-0.03); place("caixote", -6.0, -33.8, 40, dz=-0.1)
    # firewood against the side of the houses with chimneys, rain barrels at corners, washing out the back
    for i, side in ((1, 1), (4, -1), (8, 1), (11, -1)):
        w, d = HOUSES[i][3:5]
        x, y, yaw = at_house(i, side * (w / 2 + 0.4), 0.4, 90); place("lenha", x, y, yaw, dz=-0.05)
        x, y, _ = at_house(i, -side * (w / 2 + 0.25), -d / 2 + 0.3); place("barril", x, y, R.uniform(0, 360), dz=-0.05)
    for i, k in ((2, "varal_a"), (9, "varal_b"), (12, "varal_a")):
        d = HOUSES[i][4]; x, y, yaw = at_house(i, 0.4, d / 2 + 3.2); place(k, x, y, yaw, col=False)
    # the fields: a scarecrow in the east one, haystacks in the west one
    place("espantalho", 30.0, -27.0, -100, dz=-0.3)  # watching the road
    place("feno", -28.0, 33.0, 0); place("feno", -24.0, 28.5, 70)

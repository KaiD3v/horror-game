# Armature + skin + "holding the lantern" pose. Run after build.py, inside Blender via the Blender MCP.
import bpy, os, math
from mathutils import Vector, Matrix

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))  # tools/comum: paths, kits
import paths
scene = bpy.context.scene
body = bpy.data.objects["Protagonista"]
LX, LY = -0.225, -0.10  # = build.py
XB_BUTT = Vector((-0.24, 0.01, 0.84)); XB_MUZZLE = XB_BUTT + Vector((-0.13, 0.07, -1)).normalized() * 0.30  # = build.py

# name: (head, tail, parent)   .L = character's left = +X
POMMEL = Vector((0.215, -0.06, 0.93)); TIP = POMMEL + Vector((0.03, 0.13, -0.42)).normalized() * 0.59  # = build.py
BONES = {"hips": ((0, 0, 0.85), (0, 0, 1.0), None),
         "spine": ((0, 0, 1.0), (0, 0, 1.15), "hips"),
         "chest": ((0, 0, 1.15), (0, 0, 1.32), "spine"),
         "neck": ((0, 0, 1.32), (0, 0, 1.40), "chest"),
         "head": ((0, 0, 1.40), (0, 0, 1.72), "neck"),
         "lantern": ((LX, LY, 0.80), (LX, LY, 0.64), "hips"),
         "machete": (POMMEL, TIP, "skirt.S.1.L"),   # sheathed, it rides the left side flap with the sheath
         "crossbow": (XB_BUTT, XB_MUZZLE, "skirt.S.1.R")}  # holstered on the right one
# crossbow frame (= build.py XBOW) for its string and loaded bolt, quiver frame (= build.py QUIVER) for the drawn bolt
_xy = (XB_MUZZLE - XB_BUTT).normalized(); _xz = (Vector((1, 0, 0)) - _xy * _xy.x).normalized()
XBOW_M = Matrix((_xy.cross(_xz), _xy, _xz)).transposed().to_4x4(); XBOW_M.translation = XB_BUTT


def _on_coat(ang, z, rx, ry):
    a = math.radians(ang); p = Vector((rx * math.cos(a), ry * math.sin(a), z))
    return p, Vector((p.x / rx ** 2, p.y / ry ** 2, 0)).normalized()


_qa, _qn = _on_coat(65, 0.84, 0.19, 0.14); _qb, _qbn = _on_coat(65, 0.58, 0.235, 0.175)
_Q0 = _qb + _qbn * 0.05; _QT = _qa + _qn * 0.05; _QL = (_QT - _Q0).length; _QAX = (_QT - _Q0).normalized()
BONES["xbow.string"] = (XBOW_M @ Vector((0, 0.24, 0)), XBOW_M @ Vector((0, 0.29, 0)), "crossbow")
BONES["bolt.rail"] = (XBOW_M @ Vector((0, 0.03, 0)), XBOW_M @ Vector((0, 0.29, 0)), "crossbow")
BONES["bolt.hand"] = (_Q0 + _QAX * (_QL - 0.005), _Q0 + _QAX * (_QL - 0.265), "hips")
for s, sx in ((".L", 1), (".R", -1)):
    BONES.update({
        "upper_arm" + s: ((sx * 0.18, 0, 1.25), (sx * 0.48, 0, 1.25), "chest"),
        "forearm" + s: ((sx * 0.48, 0, 1.25), (sx * 0.73, 0, 1.25), "upper_arm" + s),
        "hand" + s: ((sx * 0.73, 0, 1.25), (sx * 0.90, 0, 1.24), "forearm" + s),
        "thigh" + s: ((sx * 0.10, 0, 0.78), (sx * 0.10, 0, 0.45), "hips"),
        "shin" + s: ((sx * 0.10, 0, 0.45), (sx * 0.10, 0, 0.10), "thigh" + s),
        "foot" + s: ((sx * 0.10, 0, 0.10), (sx * 0.10, -0.13, 0.02), "shin" + s)})

# skirt flaps: front / side / back chain per side, two bones each, on the coat's surface (rings from build.py)
SKIRT_RINGS = ((0.85, 0.19, 0.14), (0.62, 0.23, 0.17), (0.45, 0.27, 0.20))  # z, rx, ry
SKIRT = []  # (bone 1, bone 2)
for s, sx in ((".L", 1), (".R", -1)):
    for panel, ang in (("F", -60), ("S", 0), ("B", 55)):
        a = math.radians(ang)
        p0, p1, p2 = (Vector((sx * rx * math.cos(a), ry * math.sin(a), z)) for z, rx, ry in SKIRT_RINGS)
        b1, b2 = "skirt.%s.1%s" % (panel, s), "skirt.%s.2%s" % (panel, s)
        BONES[b1] = (p0, p1, "hips"); BONES[b2] = (p1, p2, b1)
        SKIRT.append((b1, b2))

arm_data = bpy.data.armatures.new("Rig")
arm = bpy.data.objects.new("Rig", arm_data)
scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
for name, (h, t, _) in BONES.items():
    eb = arm_data.edit_bones.new(name); eb.head, eb.tail = h, t
for name, (_, _, p) in BONES.items():
    if p:
        arm_data.edit_bones[name].parent = arm_data.edit_bones[p]
        arm_data.edit_bones[name].use_connect = False
EB = arm_data.edit_bones
mb = EB["machete"]; y = (mb.tail - mb.head).normalized()
mb.align_roll((Vector((1, 0, 0)) - y * y.x).normalized().cross(y))  # bone Z = build.py SHEATH Z
cb = EB["crossbow"]; y = (cb.tail - cb.head).normalized()
cb.align_roll((Vector((1, 0, 0)) - y * y.x).normalized())  # bone Z = build.py XBOW Z (top of the tiller)
for n in ("xbow.string", "bolt.rail"):
    EB[n].align_roll(_xz)  # Z = top of the tiller: location (0, y, z) moves along the barrel / up off the rail
EB["bolt.hand"].align_roll((_qn - _QAX * _qn.dot(_QAX)).normalized())  # Z = out of the quiver's back
# grip.L: where the machete sits in the left fist. Handle across the palm, blade out of the thumb side
# (hand X), edge towards the palm (hand -Z), handle centre 6 cm from the pommel.
hm = EB["hand.L"].matrix; hx, hy, hz = (Vector(hm.col[i][:3]).normalized() for i in range(3))
palm = Vector(hm.translation) + hy * 0.05
g = EB.new("grip.L"); g.head = palm - hx * 0.06; g.tail = g.head + hx * mb.length
g.align_roll(hz); g.parent = EB["hand.L"]
# grip.Lc: the machete carried at ease. The handle lies diagonally across the palm (45 deg from the thumb side
# towards the fingers), so the blade runs on along the forearm, its flat facing out like the back of the hand
# and the edge down on the fingers' side
cb_, ce_ = (hx + hy).normalized(), (hy - hx).normalized()
g = EB.new("grip.Lc"); g.head = palm - cb_ * 0.06; g.tail = g.head + cb_ * mb.length
g.align_roll(-ce_); g.parent = EB["hand.L"]
# grip.bolt: a bolt pinched in the left hand, shaft along hand X like the machete, nock 3 cm behind the palm
g = EB.new("grip.bolt"); g.head = palm - hx * 0.03; g.tail = g.head + hx * 0.26
g.align_roll(hz); g.parent = EB["hand.L"]
# grip.R: the crossbow in the right fist, pistol grip in the palm: barrel along the hand (hand Y), top of the
# tiller up the back of the hand (hand Z); butt 0.5 cm ahead of the wrist, 4.5 cm above it (xbow_hold inverts it)
hm = EB["hand.R"].matrix; hx, hy, hz = (Vector(hm.col[i][:3]).normalized() for i in range(3))
g = EB.new("grip.R"); g.head = Vector(hm.translation) + hy * 0.005 + hz * 0.045; g.tail = g.head + hy * cb.length
g.align_roll(hz); g.parent = EB["hand.R"]
bpy.ops.object.mode_set(mode="OBJECT")

body.parent = arm
mod = body.modifiers.new("Armature", "ARMATURE"); mod.object = arm

light = bpy.data.objects["lantern_light"]
mw = light.matrix_world.copy()
light.parent, light.parent_type, light.parent_bone = arm, "BONE", "lantern"
bpy.context.view_layer.update()
light.matrix_world = mw

# --- pose: aim bones along world directions (armature sits at the origin) ---------------
P = arm.pose.bones
grab = P["machete"].constraints.new("COPY_TRANSFORMS")  # 0 = in the sheath, 1 = in the left hand
grab.name = "grab"; grab.target = arm; grab.subtarget = "grip.L"; grab.influence = 0
grab_c = P["machete"].constraints.new("COPY_TRANSFORMS")  # 1 = carried at ease (grip.Lc), over grab
grab_c.name = "grab_carry"; grab_c.target = arm; grab_c.subtarget = "grip.Lc"; grab_c.influence = 0
grab_x = P["crossbow"].constraints.new("COPY_TRANSFORMS")  # 0 = holstered, 1 = in the right hand
grab_x.name = "grab_xbow"; grab_x.target = arm; grab_x.subtarget = "grip.R"; grab_x.influence = 0
grab_b = P["bolt.hand"].constraints.new("COPY_TRANSFORMS")  # 0 = in the quiver, 1 = in the left hand
grab_b.name = "grab_bolt"; grab_b.target = arm; grab_b.subtarget = "grip.bolt"; grab_b.influence = 0
def verts(test):
    return [v.index for v in body.data.vertices if any(test(body.vertex_groups[g.group].name) for g in v.groups)]


GROUND = {"feet": verts(lambda n: n.startswith("foot")),                     # standing
          "legs": verts(lambda n: n.startswith(("foot", "shin"))),           # kneeling (knee or toes down)
          "body": verts(lambda n: n not in ("lantern", "machete"))}          # lying down
REST = {b.name: b.matrix_local.copy() for b in arm_data.bones}


def aim(bone, d):
    pb = P[bone]; m = pb.matrix.copy(); head = m.translation.copy()
    q = Vector(m.col[1][:3]).normalized().rotation_difference(Vector(d).normalized())
    pb.matrix = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head) @ m
    bpy.context.view_layer.update()


def turn(bone, axis, deg):
    pb = P[bone]; m = pb.matrix.copy(); head = m.translation.copy()
    pb.matrix = Matrix.Translation(head) @ Matrix.Rotation(deg * 3.14159 / 180, 4, axis) @ Matrix.Translation(-head) @ m
    bpy.context.view_layer.update()


def orient(bone, x, z):
    """Absolute rotation for a bone: X axis along x, Z as close to z as possible (head stays put)."""
    pb = P[bone]; x = Vector(x).normalized(); z = Vector(z); z = (z - x * z.dot(x)).normalized()
    pb.matrix = Matrix.Translation(pb.matrix.translation) @ Matrix((x, z.cross(x), z)).transposed().to_4x4()
    bpy.context.view_layer.update()


def hold(palm, blade, edge, pole=(1, 0.3, -0.6), side=".L"):
    """Analytic 2-bone IK for an arm: palm position, blade direction (hand X), direction the edge faces (-hand Z)."""
    x = Vector(blade).normalized(); z = -Vector(edge); z = (z - x * z.dot(x)).normalized()
    wrist = Vector(palm) - z.cross(x) * 0.05
    s0 = P["upper_arm" + side].matrix.translation.copy()
    l1, l2 = P["upper_arm" + side].length, P["forearm" + side].length
    d = wrist - s0; dist = min(d.length, l1 + l2 - 1e-4); dn = d.normalized()
    ca = max(-1.0, min(1.0, (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)))
    pv = Vector(pole); perp = (pv - dn * pv.dot(dn)).normalized()
    elbow = s0 + (dn * ca + perp * math.sqrt(1 - ca * ca)) * l1
    aim("upper_arm" + side, elbow - s0); aim("forearm" + side, wrist - elbow); orient("hand" + side, x, z)


def sheath_grip():
    """palm/blade/edge that put the fist exactly on the sheathed handle (no pop when the machete swaps)."""
    m = P["skirt.S.1.L"].matrix @ REST["skirt.S.1.L"].inverted() @ REST["machete"]
    y, z = Vector(m.col[1][:3]).normalized(), Vector(m.col[2][:3]).normalized()
    return m.translation + y * 0.06, y, -z


UPPER = [  # hunched, wary, lantern held out with the right hand, hurt left arm clutched to the belly
    ("spine", (0, -0.08, 1)), ("chest", (0, -0.22, 1)), ("neck", (0, -0.3, 1)), ("head", (0, -0.12, 1)),
    ("upper_arm.R", (-0.45, -0.45, -0.75)), ("forearm.R", (-0.05, -0.85, 0.5)), ("hand.R", (-0.05, -1, -0.05)),
    ("upper_arm.L", (0.3, -0.2, -0.95)), ("forearm.L", (-0.75, -0.6, 0.2)), ("hand.L", (-0.9, -0.35, -0.1)),
]
IDLE_LEGS = [
    ("thigh.L", (0.04, -0.3, -1)), ("shin.L", (0, 0.05, -1)), ("foot.L", (0.05, -1, -0.45)),
    ("thigh.R", (-0.03, 0.22, -1)), ("shin.R", (0, 0.4, -1)), ("foot.R", (-0.05, -1, -0.7)),
]


LEG_CAPSULES = (("thigh", 0.115, 0.35), ("shin", 0.105, 0.0))  # radius (leg + margin), start along the bone:
# the top third of the thigh sits inside the coat's waist by design, so only the rest of it pushes the flaps
DRAPE_MISSES = []  # (action, frame, bone) where no angle cleared the legs; the least-bad one was used


def leg_depth(p):
    """How deep p is inside the nearest leg capsule (<= 0: clear)."""
    worst = -1.0
    for s in (".L", ".R"):
        for bone, r, t0 in LEG_CAPSULES:
            a, b = P[bone + s].head, P[bone + s].tail
            a = a + (b - a) * t0
            ab = b - a; t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
            worst = max(worst, r - (p - (a + ab * t)).length)
    return worst


def sweep(bone, h, axis, d0, ts, stop):
    """First swing (outwards from d0) whose samples clear the legs; failing that, the one that cuts least."""
    best, best_v = d0, 1e9
    for ang in range(0, stop, 4):
        d = Matrix.Rotation(math.radians(ang), 3, axis) @ d0
        v = sum(max(0.0, leg_depth(h + d * t)) for t in ts)
        if v == 0.0:
            return d
        if v < best_v - 1e-6:
            best, best_v = d, v
    act = arm.animation_data.action
    DRAPE_MISSES.append((act.name if act else "", scene.frame_current, bone))
    return best


def drape():
    """Coat skirt vs legs. Each flap hinges outwards at the waist just enough for its upper half to clear
    both legs, then its lower half drops back towards hanging as far as the legs let it: the coat rests on a
    raised knee instead of being pierced. Hanging = the hips' down, so it also works lying down."""
    down = (P["hips"].matrix.to_3x3() @ REST["hips"].to_3x3().inverted()) @ Vector((0, 0, -1))
    for b1, b2 in SKIRT:
        rest2 = P[b2].tail - P[b2].head
        h = P[b1].head.copy(); d0 = P[b1].tail - h
        out = (d0 - down * d0.dot(down)).normalized()       # the flap's outward flare
        axis = down.cross(out)                              # + angle swings the flap outwards
        d = sweep(b1, h, axis, d0, (0.35, 0.7, 1.0), 124)
        if (d - d0).length > 1e-6:
            aim(b1, d)
        aim(b2, sweep(b2, P[b2].head.copy(), axis, rest2, (0.5, 1.0), 154))  # from hanging, rise only as needed


def pose(aims, frame, turns=(), swing=0.0, left=None, armed=0.0, ground="feet", lift=0.0, lantern=None, sway=0.0,
         right=None, xbow=0.0, cock=0.0, loaded=0.0, nock=0.0, carry=0.0):
    """Reset, aim bones, IK the left fist (left=(palm, blade, edge[, pole])), hang the lantern from the
    right fist (or place it at the world matrix `lantern`), swap the machete sheath->hand by `armed`,
    put the soles (ground="feet") or the whole body (ground="body") on the floor, raise by `lift`, key.
    right=(palm, blade, edge, pole, ".R") IKs the right fist instead; xbow swaps the crossbow holster->right hand;
    lantern="hung" leaves the lantern on its belt hook."""
    for pb in P:
        pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
    bpy.context.view_layer.update()
    for bone, d in aims:
        aim(bone, d)
    for bone, axis, deg in turns:
        turn(bone, axis, deg)
    drape()
    if left and ground == "feet":
        hold(*(left() if callable(left) else left))
    if right and ground == "feet":
        hold(*(right() if callable(right) else right))
    grab.influence = armed; grab_x.influence = xbow; grab_b.influence = nock; grab_c.influence = carry
    P["xbow.string"].location = (0, -0.17 * cock, 0)            # cocked: string back on the catch
    P["bolt.rail"].location = (0, 0.04 * loaded, 0.026 * loaded)  # loaded: up out of the stock onto the rail
    if lantern == "hung":  # on the belt hook: its rest spot, relative to the hips
        P["lantern"].matrix = P["hips"].matrix @ REST["hips"].inverted() @ REST["lantern"]
        lantern = None
    else:
        hand = P["hand.R"].matrix
        grip = hand.translation + Vector(hand.col[1][:3]).normalized() * 0.06 - Vector((0, 0, 0.03))
        P["lantern"].matrix = Matrix.Translation(grip) @ arm_data.bones["lantern"].matrix_local.to_3x3().to_4x4()
    bpy.context.view_layer.update()
    turn("lantern", "X", swing)  # pendulum around the ring, fore-aft
    turn("lantern", "Y", sway)   # and sideways
    ev = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    minz = min((ev.matrix_world @ ev.data.vertices[i].co).z for i in GROUND[ground]) - lift
    P["hips"].matrix = Matrix.Translation((0, 0, -minz)) @ P["hips"].matrix
    bpy.context.view_layer.update()
    if left and ground == "body":  # lying down: targets are on the floor, so solve after grounding
        hold(*(left() if callable(left) else left))
    if lantern is not None:  # after grounding, so the hips shift does not move it
        P["lantern"].matrix = lantern
        bpy.context.view_layer.update()
    for pb in P:
        pb.keyframe_insert("location", frame=frame)
        pb.keyframe_insert("rotation_quaternion", frame=frame)
    grab.keyframe_insert("influence", frame=frame)
    grab_x.keyframe_insert("influence", frame=frame)
    grab_b.keyframe_insert("influence", frame=frame)
    grab_c.keyframe_insert("influence", frame=frame)
    return -minz


def new_action(name):
    act = bpy.data.actions.new(name); act.use_fake_user = True
    arm.animation_data_create().action = act
    return act


# --- anxious breathing idle: 120 frames @ 30 fps = 2 breaths (30/min), one glance over the shoulder --
idle = new_action("Idle_Lantern_Loop")
GLANCE = {1: -15, 31: -15, 61: -15, 71: 30, 91: 30, 105: -15, 121: -15}  # head yaw, + = his left
SWAY = {71: 4, 91: -2, 105: 2}                                            # lantern jolts with the glance
for f, yaw in GLANCE.items():
    b = (1 - math.cos(2 * math.pi * (f - 1) / 60)) / 2                     # 0 = exhaled, 1 = full breath
    aims = [(n, (d[0], d[1] + 0.11 * b if n in ("chest", "neck", "head") else d[1], d[2])) for n, d in UPPER]
    pose(aims + IDLE_LEGS, f, swing=SWAY.get(f, 0), turns=[("head", "Z", yaw)])
idle.use_frame_range = True; idle.frame_range = (1, 120)  # frame 121 == frame 1

# --- cautious walk, in place, 32 frames @ 30 fps; F = leg in front, B = leg behind --------
CONTACT = {"thigh.F": (0, -0.45, -1), "shin.F": (0, -0.12, -1), "foot.F": (0, -1, 0.15),
           "thigh.B": (0, 0.35, -1), "shin.B": (0, 0.7, -1), "foot.B": (0, -0.45, -1)}
PASSING = {"thigh.F": (0, 0.03, -1), "shin.F": (0, 0.05, -1), "foot.F": (0, -1, -0.6),   # planted
           "thigh.B": (0, -0.3, -1), "shin.B": (0, 0.55, -1), "foot.B": (0, -1, -0.8)}  # swinging through


def legs(key, front):
    back = ".R" if front == ".L" else ".L"
    return [(b.replace(".F", front).replace(".B", back), d) for b, d in key.items()]


walk = new_action("Walk_Lantern_Loop")
WALK = [(1, CONTACT, ".L", 5, 8), (9, PASSING, ".L", 0, 0), (17, CONTACT, ".R", -5, -8),
        (25, PASSING, ".R", 0, 0), (33, CONTACT, ".L", 5, 8)]
bob = []
for frame, key, front, twist, swing in WALK:
    bob.append(pose(UPPER + legs(key, front), frame, swing=swing,
                    turns=[("chest", "Z", twist), ("head", "Z", -twist - 6)]))
    if frame == 1:  # stride = ankle distance at contact -> ground speed the game should move the root at
        stride = abs(P["foot.R"].matrix.translation.y - P["foot.L"].matrix.translation.y)
walk.use_frame_range = True; walk.frame_range = (1, 32)  # frame 33 == frame 1, so the loop is seamless

# --- panicked sprint, in place, 20 frames @ 30 fps: leaning in, lantern jolting, hurt arm still clutched ------
RUN_UP = [("spine", (0, -0.2, 1)), ("chest", (0, -0.42, 1)), ("neck", (0, -0.25, 1)), ("head", (0, -0.02, 1)),
          ("upper_arm.R", (-0.35, -0.55, -0.7)), ("forearm.R", (-0.05, -0.9, 0.35)), ("hand.R", (-0.05, -1, -0.1)),
          ("upper_arm.L", (0.3, -0.3, -0.9)), ("forearm.L", (-0.75, -0.6, 0.25)), ("hand.L", (-0.9, -0.35, -0.05))]
RUN_CONTACT = {"thigh.F": (0, -0.65, -1), "shin.F": (0, -0.2, -1), "foot.F": (0, -1, 0.1),
               "thigh.B": (0, 0.45, -1), "shin.B": (0, 1, -0.55), "foot.B": (0, -0.3, -1)}
RUN_MID = {"thigh.F": (0, -0.1, -1), "shin.F": (0, 0.3, -1), "foot.F": (0, -1, -0.35),       # loaded, knee bent
           "thigh.B": (0, -0.35, -1), "shin.B": (0, 1, -0.25), "foot.B": (0, -0.2, -1)}       # heel tucked up
RUN_FLIGHT = {"thigh.F": (0, 0.4, -1), "shin.F": (0, 0.85, -0.6), "foot.F": (0, -0.35, -1),  # pushing off behind
              "thigh.B": (0, -1, -0.7), "shin.B": (0, 0.05, -1), "foot.B": (0, -1, -0.4)}     # knee driving forward
run = new_action("Run_Lantern_Loop")
RUN = [(1, RUN_CONTACT, ".L", 10, 18, 0), (4, RUN_MID, ".L", 4, 0, 0), (7, RUN_FLIGHT, ".L", -4, -12, 0.07),
       (11, RUN_CONTACT, ".R", -10, -18, 0), (14, RUN_MID, ".R", -4, 0, 0), (17, RUN_FLIGHT, ".R", 4, 12, 0.07),
       (21, RUN_CONTACT, ".L", 10, 18, 0)]
for frame, key, front, twist, swing, lift in RUN:
    pose(RUN_UP + legs(key, front), frame, swing=swing, lift=lift,
         turns=[("chest", "Z", twist), ("head", "Z", -twist * 0.6)])
run.use_frame_range = True; run.frame_range = (1, 20)
# ground speed: how fast the planted foot slides back between contact and mid-stance
scene.frame_set(1); y1 = P["foot.L"].matrix.translation.y
scene.frame_set(4); y4 = P["foot.L"].matrix.translation.y
run_speed = (y4 - y1) / (3 / 30)

# --- the jog (the default pace: faster than the walk, no stamina) and the lantern-free set ---------------------------
# Jog, lantern in hand, 30 frames @ 30 fps: a short float between steps, torso a little forward, lantern bobbing.
JOG_UP = [("spine", (0, -0.12, 1)), ("chest", (0, -0.3, 1)), ("neck", (0, -0.28, 1)), ("head", (0, -0.08, 1)),
          ("upper_arm.R", (-0.4, -0.5, -0.75)), ("forearm.R", (-0.05, -0.88, 0.42)), ("hand.R", (-0.05, -1, -0.08)),
          ("upper_arm.L", (0.3, -0.25, -0.92)), ("forearm.L", (-0.75, -0.6, 0.22)), ("hand.L", (-0.9, -0.35, -0.08))]
JOG_CONTACT = {"thigh.F": (0, -0.42, -1), "shin.F": (0, -0.12, -1), "foot.F": (0, -1, 0.1),
               "thigh.B": (0, 0.3, -1), "shin.B": (0, 0.75, -0.85), "foot.B": (0, -0.45, -1)}
JOG_MID = {"thigh.F": (0, -0.05, -1), "shin.F": (0, 0.2, -1), "foot.F": (0, -1, -0.45),
           "thigh.B": (0, -0.3, -1), "shin.B": (0, 0.8, -0.5), "foot.B": (0, -0.3, -1)}
JOG_FLIGHT = {"thigh.F": (0, 0.3, -1), "shin.F": (0, 0.6, -0.8), "foot.F": (0, -0.4, -1),
              "thigh.B": (0, -0.7, -1), "shin.B": (0, 0.15, -1), "foot.B": (0, -1, -0.5)}
#        frame, legs,    front, chest twist, lantern swing, lift, right-arm phase (+1 = forward, free hands)
JOG = [(1, JOG_CONTACT, ".L", 7, 12, 0, 1), (5, JOG_MID, ".L", 3, 0, 0, 0.5), (10, JOG_FLIGHT, ".L", -3, -8, 0.025, -0.3),
       (16, JOG_CONTACT, ".R", -7, -12, 0, -1), (20, JOG_MID, ".R", -3, 0, 0, -0.5), (25, JOG_FLIGHT, ".R", 3, 8, 0.025, 0.3),
       (31, JOG_CONTACT, ".L", 7, 12, 0, 1)]
WALK_PHASE = {1: 1, 9: 0, 17: -1, 25: 0, 33: 1}
RUN_PHASE = {1: 1, 4: 0.5, 7: -0.3, 11: -1, 14: -0.5, 17: 0.3, 21: 1}


def no_right(up):
    return [(n, d) for n, d in up if not n.endswith(".R")]


def free_arm(a, kind):
    """The right arm with nothing in it: hanging (idle), swinging opposite the legs, bent more the faster he goes."""
    if kind == "idle":
        return [("upper_arm.R", (-0.12, -0.05, -1)), ("forearm.R", (-0.03, -0.15, -1)), ("hand.R", (-0.03, -0.12, -1))]
    if kind == "walk":
        return [("upper_arm.R", (-0.12, -0.35 * a, -1)), ("forearm.R", (-0.05, -0.3 - 0.25 * a, -1)),
                ("hand.R", (-0.05, -0.3 - 0.25 * a, -1))]
    if kind == "jog":
        return [("upper_arm.R", (-0.15, -0.5 * a, -1)), ("forearm.R", (-0.05, -0.9, -0.5 + 0.25 * a)),
                ("hand.R", (-0.05, -1, -0.25))]
    if kind == "crouch":
        return [("upper_arm.R", (-0.2, -0.45 - 0.1 * a, -1)), ("forearm.R", (-0.05, -0.65, -0.75)), ("hand.R", (0, -0.8, -0.6))]
    return [("upper_arm.R", (-0.15, -0.7 * a, -0.8)), ("forearm.R", (-0.05, -1, -0.25 + 0.2 * a)), ("hand.R", (-0.05, -1, 0.05))]


def ground_speed(a, b):  # how fast the planted left foot slides back between two keyed frames
    scene.frame_set(a); y0 = P["foot.L"].matrix.translation.y
    scene.frame_set(b); y1 = P["foot.L"].matrix.translation.y
    return (y1 - y0) / ((b - a) / 30)


jog = new_action("Jog_Lantern_Loop")
for frame, key, front, twist, swing, lift, a in JOG:
    pose(JOG_UP + legs(key, front), frame, swing=swing, lift=lift, turns=[("chest", "Z", twist), ("head", "Z", -twist * 0.7)])
jog.use_frame_range = True; jog.frame_range = (1, 30)
jog_speed = ground_speed(1, 5)

# hands free, the lantern on its belt hook (Stow_Lantern below): the same gaits, the right arm swinging
free = new_action("Idle_Free_Loop")
for f, yaw in GLANCE.items():
    b = (1 - math.cos(2 * math.pi * (f - 1) / 60)) / 2
    aims = [(n, (d[0], d[1] + 0.11 * b if n in ("chest", "neck", "head") else d[1], d[2])) for n, d in no_right(UPPER)]
    pose(aims + free_arm(0, "idle") + IDLE_LEGS, f, swing=SWAY.get(f, 0) * 0.5, turns=[("head", "Z", yaw)], lantern="hung")
free.use_frame_range = True; free.frame_range = (1, 120)
fw = new_action("Walk_Free_Loop")
for frame, key, front, twist, swing in WALK:
    pose(no_right(UPPER) + free_arm(WALK_PHASE[frame], "walk") + legs(key, front), frame, swing=swing * 0.6,
         turns=[("chest", "Z", twist), ("head", "Z", -twist - 6)], lantern="hung")
fw.use_frame_range = True; fw.frame_range = (1, 32)
fj = new_action("Jog_Free_Loop")
for frame, key, front, twist, swing, lift, a in JOG:
    pose(no_right(JOG_UP) + free_arm(a, "jog") + legs(key, front), frame, swing=swing * 0.7, lift=lift,
         turns=[("chest", "Z", twist), ("head", "Z", -twist * 0.7)], lantern="hung")
fj.use_frame_range = True; fj.frame_range = (1, 30)
fr = new_action("Run_Free_Loop")
for frame, key, front, twist, swing, lift in RUN:
    pose(no_right(RUN_UP) + free_arm(RUN_PHASE[frame], "run") + legs(key, front), frame, swing=swing * 0.8, lift=lift,
         turns=[("chest", "Z", twist), ("head", "Z", -twist * 0.6)], lantern="hung")
fr.use_frame_range = True; fr.frame_range = (1, 20)

# --- combat: machete in the LEFT (bandaged) hand, lantern stays up in the right ----------------------
GUARD_UP = [("spine", (0, -0.12, 1)), ("chest", (0, -0.25, 1)), ("neck", (0, -0.2, 1)), ("head", (0, -0.05, 1)),
            ("upper_arm.R", (-0.6, -0.45, -0.35)), ("forearm.R", (-0.15, -0.9, 0.35)), ("hand.R", (-0.1, -1, 0))]
GUARD_LEGS = [("thigh.L", (0.15, -0.35, -1)), ("shin.L", (0.05, 0.15, -1)), ("foot.L", (0.1, -1, -0.5)),
              ("thigh.R", (-0.15, 0.3, -1)), ("shin.R", (-0.05, 0.6, -1)), ("foot.R", (-0.15, -1, -0.6))]
LUNGE = [("thigh.L", (0.15, -0.6, -1)), ("shin.L", (0.05, -0.05, -1)), ("foot.L", (0.1, -1, -0.3)),
         ("thigh.R", (-0.15, 0.5, -1)), ("shin.R", (-0.05, 0.55, -1)), ("foot.R", (-0.15, -1, -0.9))]
GUARD_HAND = ((0.25, -0.3, 1.05), (0.35, -0.8, 0.45), (0, 0, -1))  # palm, blade dir, edge faces


def guard(frame, breath=0.0, swing=0.0):
    aims = [(n, (d[0], d[1] + 0.08 * breath if n in ("chest", "neck") else d[1], d[2])) for n, d in GUARD_UP]
    palm = Vector(GUARD_HAND[0]) + Vector((0, 0, 0.015 * breath))
    pose(aims + GUARD_LEGS, frame, turns=[("chest", "Z", -15), ("head", "Z", 10)],
         left=(palm,) + GUARD_HAND[1:], armed=1, swing=swing)


def act(name, last, loop=False):
    a = new_action(name); a.use_frame_range = True; a.frame_range = (1, last - 1 if loop else last)
    return a


def pulled(dist, pole):  # fist slid `dist` back out along the sheathed blade
    def f():
        palm, blade, edge = sheath_grip()
        return palm - blade * dist, blade, edge, pole
    return f


REACH_POLE = (0.6, 0.8, 0)
act("Draw_Machete", 28)  # 0.93 s; the machete swaps sheath->hand between frames 7 and 8 with the fist on it
pose(UPPER + IDLE_LEGS, 1, turns=[("head", "Z", -15)])
for f, armed in ((7, 0), (8, 1)):
    pose(UPPER + IDLE_LEGS, f, turns=[("chest", "Z", 15), ("head", "Z", -20)], left=pulled(0, REACH_POLE), armed=armed)
pose(UPPER + IDLE_LEGS, 14, turns=[("chest", "Z", 10), ("head", "Z", -10)], left=pulled(0.42, REACH_POLE), armed=1)
pose(GUARD_UP + GUARD_LEGS, 20, turns=[("chest", "Z", -5)],
     left=((0.3, -0.15, 1.4), (0.15, -0.3, 1), (0, -1, 0.2), (1, 0.3, -0.3)), armed=1, swing=-6)
guard(28)

act("Combat_Idle_Loop", 61, loop=True)  # 2 s, one tense breath
for f, b in ((1, 0), (31, 1), (61, 0)):
    guard(f, breath=b)

act("Attack_Slash", 24)  # diagonal slash, hit on frame 10
guard(1)
pose(GUARD_UP + GUARD_LEGS, 6, turns=[("chest", "Z", 15), ("head", "Z", -10)],
     left=((0.42, 0.05, 1.42), (0.35, 0.6, 0.7), (-1, -0.5, -0.3)), armed=1, swing=4)
pose(GUARD_UP + LUNGE, 10, turns=[("chest", "Z", -30), ("head", "Z", 25)],
     left=((0.0, -0.5, 1.05), (-0.6, -0.75, -0.15), (-0.7, 0.4, -0.6), (1, 0, -0.3)), armed=1, swing=-8)
pose(GUARD_UP + LUNGE, 14, turns=[("chest", "Z", -40), ("head", "Z", 30)],
     left=((-0.2, -0.3, 0.85), (-0.85, 0.15, -0.5), (-0.4, 0.8, -0.3), (1, 0, -0.3)), armed=1, swing=-10)
guard(24, swing=3)

act("Attack_Overhead", 30)  # heavy overhead chop, hit on frame 13
guard(1)
pose([("spine", (0, 0.05, 1)), ("chest", (0, 0.1, 1)), ("neck", (0, -0.1, 1)), ("head", (0, -0.15, 1))]
     + GUARD_UP[4:] + GUARD_LEGS, 9, turns=[("chest", "Z", -5)],
     left=((0.12, 0.1, 1.62), (0, 0.7, 0.45), (0, -0.45, 0.7), (1, 0, 0.5)), armed=1, swing=5)
pose([("spine", (0, -0.3, 1)), ("chest", (0, -0.5, 1)), ("neck", (0, -0.3, 1)), ("head", (0, -0.1, 1))]
     + GUARD_UP[4:] + LUNGE, 13, turns=[("chest", "Z", -10)],
     left=((0.08, -0.45, 0.98), (0, -1, -0.25), (0, 0.25, -1), (1, 0.2, -0.5)), armed=1, swing=-10)
pose([("spine", (0, -0.32, 1)), ("chest", (0, -0.52, 1)), ("neck", (0, -0.3, 1)), ("head", (0, -0.1, 1))]
     + GUARD_UP[4:] + LUNGE, 18, turns=[("chest", "Z", -10)],
     left=((0.08, -0.38, 0.78), (0, -0.75, -0.65), (0, 0.65, -0.75), (1, 0.2, -0.5)), armed=1, swing=-6)
guard(30, swing=2)

act("Hit_React", 18)  # flinch backwards
guard(1)
pose([("spine", (0, 0.1, 1)), ("chest", (0, 0.2, 1)), ("neck", (0, 0.25, 1)), ("head", (0, 0.35, 1)),
      ("upper_arm.R", (-0.7, -0.3, -0.1)), ("forearm.R", (-0.4, -0.6, 0.6)), ("hand.R", (-0.2, -1, 0.3)),
      ("thigh.L", (0.15, -0.2, -1)), ("shin.L", (0.05, 0.2, -1)), ("foot.L", (0.1, -1, -0.5)),
      ("thigh.R", (-0.15, 0.4, -1)), ("shin.R", (-0.05, 0.7, -1)), ("foot.R", (-0.15, -1, -0.6))],
     4, turns=[("chest", "Z", 10), ("head", "Z", 25)],
     left=((0.25, -0.15, 1.0), (0.3, -0.3, 1), (0, -1, 0)), armed=1, swing=12)
guard(10, swing=-6)
guard(18)

# block (RMB held): a high guard, the machete across in front of his face, the tip up to his right, the edge out
BLOCK_HAND = ((0.16, -0.34, 1.34), (-0.8, -0.3, 0.5), (0.05, -0.85, 0.5), (1, 0.1, -0.8))  # palm, blade, edge, pole


def block(frame, breath=0.0, push=0.0):  # push: 1 = knocked back by a blow on the blade
    aims = [("spine", (0, -0.16 + 0.12 * push, 1)), ("chest", (0, -0.3 + 0.3 * push + 0.06 * breath, 1)),
            ("neck", (0, -0.3 + 0.25 * push, 1)), ("head", (0, -0.2 + 0.3 * push, 1))] + GUARD_UP[4:]
    palm = Vector(BLOCK_HAND[0]) + Vector((0, 0.1 * push, 0.015 * breath - 0.04 * push))
    pose(aims + GUARD_LEGS, frame, turns=[("chest", "Z", -8 + 6 * push), ("head", "Z", 6)],
         left=(palm,) + BLOCK_HAND[1:], armed=1, swing=10 * push)


act("Block_Loop", 61, loop=True)  # 2 s, a held breath behind the blade
for f, b in ((1, 0), (31, 1), (61, 0)):
    block(f, breath=b)

act("Block_Hit", 16)  # a blow lands on the blade: knocked back, then the guard up again
block(1)
block(4, push=1)
block(9, push=0.3)
block(16)

act("Dodge_Back", 18)  # back-hop out of reach: airborne 6-10, lands 12. Move the root ~0.8 m back over 4-12.
guard(1)
pose([("spine", (0, -0.15, 1)), ("chest", (0, -0.35, 1))] + GUARD_UP[2:] +
     [("thigh.L", (0.15, -0.6, -1)), ("shin.L", (0.05, 0.5, -1)), ("foot.L", (0.1, -1, -0.5)),
      ("thigh.R", (-0.15, 0.1, -1)), ("shin.R", (-0.05, 0.9, -1)), ("foot.R", (-0.15, -1, -0.6))],
     4, turns=[("chest", "Z", -10)], left=((0.2, -0.2, 0.95), (0.3, -0.7, 0.6), (0, 0, -1)), armed=1, swing=-4)
pose([("spine", (0, -0.25, 1)), ("chest", (0, -0.45, 1)), ("neck", (0, -0.3, 1)), ("head", (0, -0.2, 1)),
      ("upper_arm.R", (-0.9, -0.3, 0.1)), ("forearm.R", (-0.5, -0.7, 0.4)), ("hand.R", (-0.2, -1, 0.1)),
      ("thigh.L", (0.15, -0.1, -1)), ("shin.L", (0.05, 0.8, -1)), ("foot.L", (0.1, -1, -0.9)),
      ("thigh.R", (-0.15, 0.6, -1)), ("shin.R", (-0.05, 0.2, -1)), ("foot.R", (-0.15, -1, -1))],
     8, turns=[("chest", "Z", -10)], left=((0.45, -0.1, 1.15), (0.6, -0.6, 0.3), (0, 0, -1), (1, 0.5, 0)),
     armed=1, swing=20, lift=0.15)
pose([("spine", (0, -0.3, 1)), ("chest", (0, -0.5, 1))] + GUARD_UP[2:] +
     [("thigh.L", (0.15, -0.7, -1)), ("shin.L", (0.05, 0.55, -1)), ("foot.L", (0.1, -1, -0.5)),
      ("thigh.R", (-0.15, 0.4, -1)), ("shin.R", (-0.05, 0.95, -0.6)), ("foot.R", (-0.15, -1, -0.3))],
     12, turns=[("chest", "Z", -15)], left=((0.25, -0.35, 0.9), (0.35, -0.8, 0.45), (0, 0, -1)), armed=1, swing=-12)
guard(18, swing=4)

# side hops (combat): s=1 = to his left (+X), s=-1 = to his right. Airborne 6-10, lands 12; the game slides
# the root ~0.8 m sideways over 4-12. Legs and torso mirror; the arms do not (machete left, lantern right).
SIDE = {  # (lead leg = the side he jumps to, trail leg), x = outwards for the lead
    "load": ([(0.15, -0.3, -1), (0.05, 0.35, -1), (0.1, -1, -0.5)],
             [(-0.25, -0.15, -1), (-0.1, 0.45, -1), (-0.1, -1, -0.55)]),
    "air": ([(0.45, -0.6, -0.75), (0.35, 0.2, -1), (0.25, -1, -0.4)],    # lead knee tucked up
            [(-0.6, 0.1, -1), (-0.6, 0.15, -1), (-0.45, -0.35, -1)]),   # trail leg straight, toe pointed
    "land": ([(0.45, -0.35, -1), (0.1, 0.4, -1), (0.15, -1, -0.5)],
             [(-0.3, 0.05, -1), (-0.15, 0.5, -1), (-0.2, -1, -0.6)])}
FLAIL_R = [("upper_arm.R", (-0.85, -0.35, 0.0)), ("forearm.R", (-0.45, -0.75, 0.3)), ("hand.R", (-0.2, -1, 0.1))]


def side_dodge(name, s):
    lead, trail = (".L", ".R") if s > 0 else (".R", ".L")

    def legs_of(key):
        a, b = SIDE[key]
        return [(n + lead, (d[0] * s, d[1], d[2])) for n, d in zip(("thigh", "shin", "foot"), a)] + \
               [(n + trail, (d[0] * s, d[1], d[2])) for n, d in zip(("thigh", "shin", "foot"), b)]

    def torso(lean):  # pelvis rolls and the body leans into the hop; the head stays level on the target
        return [("hips", (0.5 * lean * s, 0, 1)), ("spine", (0.8 * lean * s, -0.12, 1)), ("chest", (lean * s, -0.25, 1)),
                ("neck", (0.3 * lean * s, -0.2, 1)), ("head", (-0.2 * lean * s, -0.05, 1))]

    def fist(dx, dz):
        return (Vector(GUARD_HAND[0]) + Vector((dx * s, 0, dz)),) + GUARD_HAND[1:]

    tw = [("chest", "Z", -15), ("head", "Z", 10)]
    act(name, 18)
    guard(1)
    pose(torso(-0.1) + GUARD_UP[4:] + legs_of("load"), 4, turns=tw, left=fist(0.05, -0.08), armed=1, sway=-6 * s)
    pose(torso(0.6) + FLAIL_R + legs_of("air"), 8, turns=tw, left=fist(0.15, 0.05), armed=1, swing=4,
         sway=-18 * s, lift=0.15)
    pose(torso(0.35) + GUARD_UP[4:] + legs_of("land"), 12, turns=tw, left=fist(0.1, -0.1), armed=1, sway=12 * s)
    guard(18, swing=3)


side_dodge("Dodge_Left", 1)
side_dodge("Dodge_Right", -1)

# crouch (exploring): one knee down, lantern held low in front, hurt arm still clutched. Crouch_Down goes
# standing -> crouched; the game plays it backwards to stand up. Crouch_Idle loops on top of it.
CROUCH_UP = [("spine", (0, -0.45, 1)), ("chest", (0, -0.75, 1)), ("neck", (0, -0.3, 1)), ("head", (0, -0.05, 1)),
             ("upper_arm.R", (-0.3, -0.55, -0.8)), ("forearm.R", (-0.05, -0.95, 0.0)), ("hand.R", (0, -1, -0.15)),
             ("upper_arm.L", (0.3, -0.35, -0.9)), ("forearm.L", (-0.75, -0.6, 0.3)), ("hand.L", (-0.9, -0.35, 0.05))]
CROUCH_LEGS = [("thigh.L", (0.15, -1, -0.08)), ("shin.L", (0.03, -0.12, -1)), ("foot.L", (0.05, -1, -0.05)),
               ("thigh.R", (-0.1, 0.05, -1)), ("shin.R", (-0.03, 1, 0.12)), ("foot.R", (0, -0.35, -1))]  # knee down
HALF_LEGS = [("thigh.L", (0.12, -0.6, -0.8)), ("shin.L", (0.03, 0.0, -1)), ("foot.L", (0.05, -1, -0.2)),
             ("thigh.R", (-0.08, -0.1, -1)), ("shin.R", (-0.03, 0.6, -0.8)), ("foot.R", (0, -0.6, -1))]
HALF_UP = [(n, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2)) for (n, a), (_, b) in zip(UPPER, CROUCH_UP)]
act("Crouch_Down", 14)
pose(UPPER + IDLE_LEGS, 1, turns=[("head", "Z", -15)])
pose(HALF_UP + HALF_LEGS, 6, turns=[("head", "Z", -8)], swing=6, ground="legs")
pose(CROUCH_UP + CROUCH_LEGS, 11, swing=-8, ground="legs")
pose(CROUCH_UP + CROUCH_LEGS, 14, swing=3, ground="legs")

act("Crouch_Idle_Loop", 91, loop=True)  # 3 s: two shallow breaths, a look to each side
for f, b, yaw in ((1, 0, 0), (23, 1, 0), (46, 0, 25), (60, 0.6, 25), (75, 0.3, -20), (91, 0, 0)):
    aims = [(n, (d[0], d[1] + 0.08 * b if n in ("chest", "neck") else d[1], d[2])) for n, d in CROUCH_UP]
    pose(aims + CROUCH_LEGS, f, turns=[("head", "Z", yaw)], swing=2 * b, ground="legs")

# --- crouch-walk (sneaking), in place, 48 frames @ 30 fps: low on both feet, heel-first, weight rolling over a
# deeply bent support leg; same hunched torso, lantern low, as the kneel. F = leg in front, B = leg behind.
SNEAK_CONTACT = {"thigh.F": (0, -0.65, -0.8), "shin.F": (0, -0.1, -1), "foot.F": (0, -1, 0.15),
                 "thigh.B": (0, 0.12, -1), "shin.B": (0, 0.75, -0.7), "foot.B": (0, -0.4, -1)}
SNEAK_PASS = {"thigh.F": (0, -0.6, -0.8), "shin.F": (0, 0.35, -1), "foot.F": (0, -1, -0.12),   # support, loaded
              "thigh.B": (0, -0.85, -0.5), "shin.B": (0, 0.55, -1), "foot.B": (0, -1, -0.55)}  # swing leg, lifted
sneak = new_action("Crouch_Walk_Loop")
SNEAK = [(1, SNEAK_CONTACT, ".L", 6, 6), (13, SNEAK_PASS, ".L", 0, 0), (25, SNEAK_CONTACT, ".R", -6, -6),
         (37, SNEAK_PASS, ".R", 0, 0), (49, SNEAK_CONTACT, ".L", 6, 6)]
for frame, key, front, twist, swing in SNEAK:
    pose(CROUCH_UP + legs(key, front), frame, swing=swing, turns=[("chest", "Z", twist), ("head", "Z", -twist)])
    if frame == 1:
        sneak_stride = abs(P["foot.R"].matrix.translation.y - P["foot.L"].matrix.translation.y)
sneak.use_frame_range = True; sneak.frame_range = (1, 48)

# --- hand crossbow: Draw (right hand hangs the lantern on the belt hook, takes the crossbow out of the hip
# holster, raises it to a two-handed aim with the hurt left hand cupped under the grip), aim idle, shot with
# its kick. The game plays Draw backwards to holster it and take the lantern back.
def xbow_frame(butt, fwd, up=(0, 0, 1)):
    y = Vector(fwd).normalized(); z = Vector(up); z = (z - y * z.dot(y)).normalized()
    m = Matrix((y.cross(z), y, z)).transposed().to_4x4(); m.translation = Vector(butt)
    return m


def holstered_xbow():
    return P["skirt.S.1.R"].matrix @ REST["skirt.S.1.R"].inverted() @ REST["crossbow"]


def xbow_hold(m, pole=(-1, 0.3, -0.6)):
    """hold() args putting the right fist on the pistol grip of a crossbow at matrix m (inverse of grip.R)."""
    y, z = Vector(m.col[1][:3]).normalized(), Vector(m.col[2][:3]).normalized()
    return m.translation + y * 0.045 - z * 0.045, y.cross(z), -z, pole, ".R"


def support(m):
    """The hurt left hand cupped under the grip, palm up."""
    y, z = Vector(m.col[1][:3]).normalized(), Vector(m.col[2][:3]).normalized()
    return m.translation + y * 0.06 - z * 0.10, y, z, (1, 0.3, -0.6)


def pulled_xbow(dist, pole):  # fist on the grip, crossbow slid `dist` up out of the holster
    def f():
        m = holstered_xbow(); m.translation = m.translation - Vector(m.col[1][:3]).normalized() * dist
        return xbow_hold(m, pole)
    return f


AIM_UP = [("spine", (0, -0.08, 1)), ("chest", (0, -0.14, 1)), ("neck", (0, -0.1, 1)), ("head", (0, -0.22, 1))]
AIM_BUTT, AIM_FWD = Vector((-0.06, -0.42, 1.40)), Vector((0.02, -1, 0.03))


def aim_pose(frame, breath=0.0, kick=0.0, swing=0.0, loaded=0.0):
    m = xbow_frame(AIM_BUTT + Vector((0, 0.04 * kick, 0.012 * breath + 0.03 * kick)),
                   AIM_FWD + Vector((0, 0, 0.18 * kick)))
    aims = [(n, (d[0], d[1] + 0.04 * breath + 0.06 * kick if n in ("chest", "neck") else d[1], d[2])) for n, d in AIM_UP]
    pose(aims + GUARD_LEGS, frame, turns=[("chest", "Z", 12), ("head", "Z", -6)], left=support(m),
         right=xbow_hold(m), xbow=1, lantern="hung", swing=swing, cock=loaded, loaded=loaded)


HOOK = ((LX, LY, 0.84), (1, 0, 0), (0, -1, 0), (-1, 0.4, -0.3), ".R")  # right fist hanging the lantern on its hook
DRAW_UP = UPPER[:4] + UPPER[7:]  # torso and the clutched left arm; the right arm is IK'd
act("Draw_Crossbow", 32)
pose(UPPER + IDLE_LEGS, 1, turns=[("head", "Z", -15)])
for f, hung in ((9, False), (10, True)):  # lantern onto the hook, swapped with the fist right on it
    pose(DRAW_UP + IDLE_LEGS, f, turns=[("head", "Z", -30), ("chest", "Z", -8)], right=HOOK,
         lantern="hung" if hung else None, swing=6)
for f, x in ((15, 0), (16, 1)):  # fist on the holstered grip, crossbow swapped holster -> hand
    pose(DRAW_UP + IDLE_LEGS, f, turns=[("head", "Z", -25), ("chest", "Z", -10)],
         right=lambda: xbow_hold(holstered_xbow(), (-1, 0.4, -0.2)), xbow=x, lantern="hung", swing=-4)
pose(DRAW_UP + IDLE_LEGS, 21, turns=[("chest", "Z", -4)], right=pulled_xbow(0.22, (-1, 0.3, -0.3)), xbow=1,
     lantern="hung", swing=3)
pose(AIM_UP + UPPER[7:] + GUARD_LEGS, 26, turns=[("chest", "Z", 6)],  # left arm still clutched until it supports
     right=xbow_hold(xbow_frame((-0.12, -0.30, 1.18), (0.0, -1, -0.35)), (-1, 0.2, -0.6)), xbow=1, lantern="hung", swing=-3)
aim_pose(32)

# --- the lantern on its belt hook: Stow_Lantern hangs it there and drops the arm (played backwards to take it); the
# crouch set without it. Frame 1 = Idle_Lantern's first frame, the last = Idle_Free's / the kneel's first frame.
act("Stow_Lantern", 16)
pose(UPPER + IDLE_LEGS, 1, turns=[("head", "Z", -15)])
for f, hung in ((9, False), (10, True)):  # the lantern onto the hook, swapped with the fist right on it
    pose(DRAW_UP + IDLE_LEGS, f, turns=[("head", "Z", -30), ("chest", "Z", -8)], right=HOOK,
         lantern="hung" if hung else None, swing=6)
pose(no_right(UPPER) + free_arm(0, "idle") + IDLE_LEGS, 16, turns=[("head", "Z", -15)], lantern="hung", swing=-3)

act("Crouch_Down_Free", 14)
pose(no_right(UPPER) + free_arm(0, "idle") + IDLE_LEGS, 1, turns=[("head", "Z", -15)], lantern="hung")
pose(no_right(HALF_UP) + free_arm(0.5, "crouch") + HALF_LEGS, 6, turns=[("head", "Z", -8)], swing=6, ground="legs", lantern="hung")
pose(no_right(CROUCH_UP) + free_arm(0, "crouch") + CROUCH_LEGS, 11, swing=-8, ground="legs", lantern="hung")
pose(no_right(CROUCH_UP) + free_arm(0, "crouch") + CROUCH_LEGS, 14, swing=3, ground="legs", lantern="hung")
act("Crouch_Idle_Free_Loop", 91, loop=True)
for f, b, yaw in ((1, 0, 0), (23, 1, 0), (46, 0, 25), (60, 0.6, 25), (75, 0.3, -20), (91, 0, 0)):
    aims = [(n, (d[0], d[1] + 0.08 * b if n in ("chest", "neck") else d[1], d[2])) for n, d in no_right(CROUCH_UP)]
    pose(aims + free_arm(0, "crouch") + CROUCH_LEGS, f, turns=[("head", "Z", yaw)], swing=2 * b, ground="legs", lantern="hung")
fs = new_action("Crouch_Walk_Free_Loop")
for frame, key, front, twist, swing in SNEAK:
    pose(no_right(CROUCH_UP) + free_arm(1 if front == ".L" and twist else -1 if twist else 0, "crouch") + legs(key, front),
         frame, swing=swing, turns=[("chest", "Z", twist), ("head", "Z", -twist)], lantern="hung")
fs.use_frame_range = True; fs.frame_range = (1, 48)

for name, ld in (("Aim_Crossbow_Loop", 1), ("Aim_Crossbow_Empty_Loop", 0)):  # 2 s, one held breath
    act(name, 61, loop=True)
    for f, b in ((1, 0), (31, 1), (61, 0)):
        aim_pose(f, breath=b, loaded=ld)

# --- a drawn weapon carried (not raised: RMB raises it), with its own idle / walk / jog / sprint, the same legs as
# the lantern sets so the game moves him at the same speeds:
#   machete: in the left fist, the arm long and down-forward as in a normal walk, the wrist straight (the hand
#            continues the forearm, only a slight bend down to the little finger, no sideways bend); the machete
#            on its carry grip (grip.Lc), the blade running on along the forearm and out ahead, its flat to the
#            side like the hand; the arm swings with the step. Two sets: the lantern out in the right hand
#            (Machete) or on its hook with the right arm hanging free (Machete_Free)
#   crossbow: low ready, both hands on it, pointed at the ground ahead; the lantern on the hook. Whether a bolt sits
#            on the rail is laid over by the game (Carry_Crossbow[_Empty]: only the string and the rail bolt count)
CARRY_M = ((0.12, -0.3, -1), (0.04, -0.85, -0.75), (0, -0.55, 1))  # upper arm, forearm, thumb (before squaring)
CARRY_BEND = 10  # deg the fist dips towards the little finger
CARRY_X = xbow_frame((-0.14, -0.26, 1.0), (0.1, -1, -0.62))


def machete_carry(a=0.0, breath=0.0):  # a = arm phase (+1: the right arm forward, so the left one back)
    def left():  # from the shoulder as posed: elbow, wrist, then a hand on the forearm's line (hand Y = forearm)
        s0 = P["upper_arm.L"].matrix.translation.copy()
        up = Vector(CARRY_M[0]) + Vector((0, 0.3 * a, 0.01 * breath))
        fo = (Vector(CARRY_M[1]) + Vector((0, 0.25 * a, 0))).normalized()
        elbow = s0 + up.normalized() * P["upper_arm.L"].length
        wrist = elbow + fo * (P["forearm.L"].length - 1e-3)
        b = Vector(CARRY_M[2]); x0 = (b - fo * b.dot(fo)).normalized()  # thumb side, square to the forearm
        d = math.radians(CARRY_BEND)
        hy, hx = fo * math.cos(d) - x0 * math.sin(d), x0 * math.cos(d) + fo * math.sin(d)
        return wrist + hy * 0.05, hx, hy.cross(hx), elbow - (s0 + wrist) / 2  # hand X, -hand Z, pole
    return {"left": left, "armed": 1, "carry": 1}


def machete_carry_free(a=0.0, breath=0.0):
    return {**machete_carry(a, breath), "lantern": "hung"}


def xbow_carry(a=0.0, breath=0.0):
    m = Matrix.Translation((0, 0.015 * a, 0.01 * breath - 0.012 * abs(a))) @ CARRY_X
    return {"left": support(m), "right": xbow_hold(m, (-1, 0.2, -0.5)), "xbow": 1, "lantern": "hung"}


def no_arms(up):
    return [(n, d) for n, d in up if not (n.startswith(("upper_arm.", "forearm.", "hand.")))]


def carry_set(kind, hands, ups, right=None):  # ups = the torso for idle, walk, jog, run; right(phase, gait) = free arm
    def up(i, ph, gait):
        return ups[i] if right is None else no_right(ups[i]) + right(ph, gait)
    act("Idle_%s_Loop" % kind, 61, loop=True)
    for f, b in ((1, 0), (31, 1), (61, 0)):
        aims = [(n, (d[0], d[1] + 0.08 * b if n in ("chest", "neck") else d[1], d[2])) for n, d in up(0, 0, "idle")]
        pose(aims + IDLE_LEGS, f, turns=[("head", "Z", -8)], **hands(0, b))
    a = new_action("Walk_%s_Loop" % kind)
    for frame, key, front, twist, swing in WALK:
        pose(up(1, WALK_PHASE[frame], "walk") + legs(key, front), frame, swing=swing,
             turns=[("chest", "Z", twist), ("head", "Z", -twist - 6)], **hands(WALK_PHASE[frame]))
    a.use_frame_range = True; a.frame_range = (1, 32)
    a = new_action("Jog_%s_Loop" % kind)
    for frame, key, front, twist, swing, lift, ph in JOG:
        pose(up(2, ph, "jog") + legs(key, front), frame, swing=swing, lift=lift,
             turns=[("chest", "Z", twist), ("head", "Z", -twist * 0.7)], **hands(ph))
    a.use_frame_range = True; a.frame_range = (1, 30)
    a = new_action("Run_%s_Loop" % kind)
    for frame, key, front, twist, swing, lift in RUN:
        pose(up(3, RUN_PHASE[frame], "run") + legs(key, front), frame, swing=swing, lift=lift,
             turns=[("chest", "Z", twist), ("head", "Z", -twist * 0.6)], **hands(RUN_PHASE[frame]))
    a.use_frame_range = True; a.frame_range = (1, 20)


carry_set("Machete", machete_carry, [UPPER, UPPER, JOG_UP, RUN_UP])
carry_set("Machete_Free", machete_carry_free, [UPPER, UPPER, JOG_UP, RUN_UP], right=free_arm)
carry_set("Crossbow", xbow_carry, [no_arms(UPPER), no_arms(UPPER), no_arms(JOG_UP), no_arms(RUN_UP)])
for name, ld in (("Carry_Crossbow_Loop", 1), ("Carry_Crossbow_Empty_Loop", 0)):  # the bolt / string overlay
    act(name, 2)
    for f in (1, 2):
        pose(no_arms(UPPER) + IDLE_LEGS, f, cock=ld, loaded=ld, **xbow_carry())

act("Shoot_Crossbow", 18)  # loaded -> the string snaps and the bolt leaves on frame 2; kick, settle, aim (empty)
aim_pose(1, loaded=1)
aim_pose(2, kick=0.4, swing=2)
aim_pose(3, kick=1, swing=5)
aim_pose(9, kick=0.35, swing=-3)
aim_pose(18)

# Reload (single shot): lower the crossbow to the chest, the left hand draws the string back onto the catch,
# reaches back to the quiver, pulls a bolt, lays it on the rail (swapped with the rail bolt), back to the aim.
LOW = xbow_frame((-0.10, -0.32, 1.12), (0.05, -1, -0.2))
REL = lambda n: REST["crossbow"].inverted() @ REST[n]  # a crossbow part relative to the crossbow


def string_hold(m, c):  # left palm on the middle of the string, c = how far it is drawn
    s = m @ REL("xbow.string") @ Matrix.Translation((0, -0.17 * c, 0))
    x, z = Vector(m.col[0][:3]).normalized(), Vector(m.col[2][:3]).normalized()
    return s.translation + z * 0.035, x, -z, (1, 0.3, -0.6)


def quiver_bolt(out=0.0):  # the drawn bolt in the quiver (with the hips), or `out` metres pulled out of it
    b = P["hips"].matrix @ REST["hips"].inverted() @ REST["bolt.hand"]
    b.translation = b.translation - Vector(b.col[1][:3]).normalized() * out
    return b


def rail_bolt(m, lift=0.0):  # the loaded bolt's place on crossbow m (lift: hovering above the rail)
    return m @ REL("bolt.rail") @ Matrix.Translation((0, 0.04, 0.026 + lift))


def bolt_hold(b, pole=(1, 0.6, -0.2)):  # left fist pinching bolt b by the nock (inverse of grip.bolt)
    y, z = Vector(b.col[1][:3]).normalized(), Vector(b.col[2][:3]).normalized()
    return b.translation + y * 0.03, y, -z, pole


def reload_pose(frame, left, cock=1.0, nock=0.0, loaded=0.0, turns=(), swing=0.0):
    pose(AIM_UP + GUARD_LEGS, frame, turns=[("chest", "Z", 8)] + list(turns), left=left, right=xbow_hold(LOW),
         xbow=1, lantern="hung", cock=cock, nock=nock, loaded=loaded, swing=swing)


act("Reload_Crossbow", 56)
aim_pose(1)
reload_pose(7, lambda: string_hold(LOW, 0), cock=0, swing=3)
reload_pose(14, lambda: string_hold(LOW, 1), swing=-2)                         # drawn back onto the catch
look_back = [("chest", "Z", -26), ("head", "Z", 35)]
for f, n in ((22, 0), (23, 1)):                                                 # fist on the nock, bolt swapped
    reload_pose(f, lambda: bolt_hold(quiver_bolt()), nock=n, turns=look_back, swing=4)
reload_pose(30, lambda: bolt_hold(quiver_bolt(0.22)), nock=1, turns=look_back)  # pulled out
reload_pose(34, bolt_hold(xbow_frame((0.24, -0.06, 0.98), (-0.2, -1, 0.25)), (1, 0.4, -0.6)), nock=1,
            turns=[("chest", "Z", -8)])                                          # brought round by the hip
reload_pose(38, lambda: bolt_hold(rail_bolt(LOW, 0.06), (1, 0.3, -0.6)), nock=1, swing=-3)
for f, n in ((43, 1), (44, 0)):                                                 # laid on the rail, swapped
    reload_pose(f, lambda: bolt_hold(rail_bolt(LOW), (1, 0.3, -0.6)), nock=n, loaded=1 - n)
aim_pose(50, loaded=1, swing=2)
aim_pose(56, loaded=1)

# death: jolt, knees buckle, falls face down; the machete stays in the fist, the lantern rolls on its side
act("Death", 45)
KNEEL_LEGS = [("thigh.L", (0.12, -0.5, -1)), ("shin.L", (0.03, 1, -0.12)), ("foot.L", (0, 0.25, -1)),
              ("thigh.R", (-0.12, -0.35, -1)), ("shin.R", (-0.03, 1, -0.1)), ("foot.R", (0, 0.25, -1))]
PRONE_LEGS = [("thigh.L", (0.06, 1, -0.08)), ("shin.L", (0.08, 1, 0.02)), ("foot.L", (0.05, 0.25, -1)),
              ("thigh.R", (-0.06, 1, -0.08)), ("shin.R", (-0.1, 1, 0.04)), ("foot.R", (-0.05, 0.25, -1))]
ROT_LANTERN = REST["lantern"].to_3x3().to_4x4()
DROPPED = Matrix.Translation((-0.62, -0.55, 0.036)) @ Matrix.Rotation(math.radians(80), 4, "Y") \
    @ Matrix.Rotation(math.radians(25), 4, "Z") @ ROT_LANTERN
guard(1)
pose([("spine", (0, 0.1, 1)), ("chest", (0, 0.25, 1)), ("neck", (0, 0.3, 1)), ("head", (0, 0.45, 1)),
      ("upper_arm.R", (-0.7, -0.2, -0.2)), ("forearm.R", (-0.4, -0.5, 0.5)), ("hand.R", (-0.2, -1, 0.3))]
     + GUARD_LEGS, 5, turns=[("head", "Z", 20)],
     left=((0.3, -0.1, 0.95), (0.4, -0.2, 0.9), (0, -1, 0)), armed=1, swing=14)
pose([("spine", (0, -0.3, 1)), ("chest", (0, -0.5, 1)), ("neck", (0, -0.6, 1)), ("head", (0.1, -0.8, 0.5)),
      ("upper_arm.R", (-0.25, -0.15, -1)), ("forearm.R", (-0.05, -0.35, -1)), ("hand.R", (0, -0.4, -1)),
      ("upper_arm.L", (0.25, -0.2, -1)), ("forearm.L", (0.05, -0.4, -1)), ("hand.L", (0.05, -0.5, -1))]
     + KNEEL_LEGS, 14, armed=1, swing=-8, ground="body")
pose([("hips", (0, -0.6, 0.8)), ("spine", (0, -0.85, 0.5)), ("chest", (0, -1, 0.3)), ("neck", (0, -1, 0.2)),
      ("head", (0.1, -1, 0)),
      ("upper_arm.R", (-0.3, -0.8, -0.6)), ("forearm.R", (-0.1, -0.6, -0.8)), ("hand.R", (0, -0.6, -1)),
      ("upper_arm.L", (0.3, -0.8, -0.6)), ("forearm.L", (0.1, -0.6, -0.8)), ("hand.L", (0.1, -0.6, -1))]
     + KNEEL_LEGS, 19, armed=1, ground="body", lantern=DROPPED,
     left=((0.35, -0.6, 0.1), (0.5, -0.85, 0.05), (0, 0, -1), (0.6, 0, 0.8)))  # blade level as he hits the floor
for f in (24, 45):  # impact, then settle
    pose([("hips", (0, -1, 0.02)), ("spine", (0, -1, 0.04)), ("chest", (0, -1, 0.06)), ("neck", (0, -1, 0)),
          ("head", (0.05, -1, -0.15)),
          ("upper_arm.R", (-1, -0.35, -0.08)), ("forearm.R", (-0.6, -0.8, -0.05)), ("hand.R", (-0.4, -1, -0.2)),
          ("upper_arm.L", (0.45, -1, -0.08)), ("forearm.L", (0.2, -1, -0.05)), ("hand.L", (0.2, -1, -0.15))]
         + PRONE_LEGS, f, turns=[("head", "Y", 75 if f == 45 else 60)], armed=1, ground="body", lantern=DROPPED,
         left=((0.45, -0.75, 0.05), (0.6, -0.8, 0), (0.8, 0.6, 0), (0.6, 0, 0.8)))  # machete flat on the floor

# the skirt is re-draped every other frame of every action, so the flaps also clear the legs between keys
SKIRT_BONES = [b for chain in SKIRT for b in chain]
for act in bpy.data.actions:
    arm.animation_data.action = act
    for f in range(int(act.frame_range[0]), int(act.frame_range[1]) + 1, 2):
        scene.frame_set(f)
        for n in SKIRT_BONES:
            P[n].rotation_quaternion = (1, 0, 0, 0)
        bpy.context.view_layer.update()
        drape()
        for n in SKIRT_BONES:
            P[n].keyframe_insert("rotation_quaternion", frame=f)

arm.animation_data.action = idle
scene.render.fps = 30

bpy.ops.wm.save_mainfile()
bpy.ops.export_scene.gltf(filepath=paths.character("protagonista"), export_format="GLB",
                          export_lights=False, export_animations=True, export_skins=True)
result = {"bones": len(arm_data.bones), "actions": {a.name: tuple(a.frame_range) for a in bpy.data.actions},
          "hip_bob": [round(b, 3) for b in bob], "stride": round(stride, 3),
          "speed_m_s": round(2 * stride / (32 / 30), 2), "run_speed_m_s": round(run_speed, 2), "jog_speed_m_s": round(jog_speed, 2),
          "drape_misses": len(DRAPE_MISSES), "drape_miss_list": DRAPE_MISSES[:12],
          "sneak_stride": round(sneak_stride, 3), "sneak_speed_m_s": round(2 * sneak_stride / (48 / 30), 2)}

print('RIG', result)

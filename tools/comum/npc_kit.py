# The NPC kit (used by tools/personagens/npcs/<who>.py), the same N64 recipe as the mutant (lowpoly.py): one
# joint table per character drives the rigid parts, the bones and the skin weights; a 64 px painted face (Face);
# shared body pieces (head, ears, limbs, aprons); finish() rigs it, gives it a 2 s idle loop, saves the .blend,
# exports models/characters/npc_<who>.glb and renders it front and 3/4. A new NPC = a new file using this.
import bpy, math, os, random, sys
import numpy as np
from mathutils import Vector, Matrix
import paths
import lowpoly as lp
from lowpoly import V


# --- textures -------------------------------------------------------------------------------------------
def grime(seed, lo=0.8):
    r = np.random.default_rng(seed); g = np.ones((32, 32, 4))
    n = r.uniform(lo, 1.0, (32, 32)); yy, xx = np.mgrid[0:32, 0:32]
    for _ in range(12):
        cx, cy, rad = r.integers(32), r.integers(32), r.uniform(1.5, 4)
        n[((xx - cx) ** 2 + (yy - cy) ** 2) < rad * rad] *= 0.85
    g[:, :, :3] = n[:, :, None]
    return lp.new_image("grime_%d" % seed, g)


class Face:
    """64 px face painter; row 0 = chin, eyes on row 32 (cols 20 and 44), mouth on row 12."""

    def __init__(self, skin, seed):
        self.skin = np.array(skin); self.r = np.random.default_rng(seed)
        self.f = np.ones((64, 64, 4)); self.f[:, :, :3] = skin
        self.yy, self.xx = np.mgrid[0:64, 0:64]
        self.f[:, :, :3] *= (0.92 + 0.10 * self.yy / 64)[:, :, None]

    def blend(self, cx, cy, rx, ry, col, a):
        m = ((self.xx - cx) / rx) ** 2 + ((self.yy - cy) / ry) ** 2 <= 1
        self.f[m, :3] = self.f[m, :3] * (1 - a) + np.array(col) * a

    def ell(self, cx, cy, rx, ry, col):
        self.f[((self.xx - cx) / rx) ** 2 + ((self.yy - cy) / ry) ** 2 <= 1, :3] = col

    def px(self, x, y, col):
        self.f[int(y), int(x), :3] = col

    def eyes(self, iris, open_=2.6, bags=0.7, milky_right=False):
        for cx in (20, 44):
            self.ell(cx, 30.5, 6.5, 4.6, self.skin * np.array((0.78, 0.70, 0.76)) * bags / 0.7)
            self.ell(cx, 32, 4.2, open_, (0.84, 0.82, 0.74))
            if milky_right and cx == 20:  # its right eye (screen left): clouded over
                self.ell(cx, 32, 1.9, min(open_, 2.2), (0.70, 0.72, 0.72)); continue
            self.ell(cx, 32, 1.7, min(open_, 2.2), iris)
            self.px(cx, 32, (0.04, 0.04, 0.05)); self.px(cx + 1, 33, (0.95, 0.95, 0.92))

    def brows(self, col, raise_inner=0, y0=36, thick=2):
        for cx in (20, 44):
            for i, x in enumerate(range(cx - 5, cx + 6)):
                t = i / 10 if cx < 32 else 1 - i / 10
                y = y0 + round(t * raise_inner)
                for k in range(thick):
                    self.px(x, y + k, col)

    def nose(self, tip=(0.78, 0.5, 0.44), a=0.3):
        for y in range(19, 26):
            self.px(33, y, self.skin * 0.78)
        self.px(30, 20, self.skin * 0.6); self.px(33, 20, self.skin * 0.6)
        self.blend(31.5, 19.5, 3, 2, tip, a)

    def mouth(self, col, lip, down=1, w=4):
        for x in range(32 - w, 32 + w):
            self.px(x, 12, col)
        self.px(31 - w, 12 - down, col); self.px(32 + w, 12 - down, col)
        for x in range(33 - w, 31 + w):
            self.px(x, 11, lip)

    def image(self, name):
        self.f[:, :, :3] *= self.r.uniform(0.95, 1.0, (64, 64))[:, :, None]
        return lp.new_image(name, self.f)


# --- shared body pieces ---------------------------------------------------------------------------------------
def bones_for(J):
    B = {"hips": ("pelvis", "spine", None), "chest": ("spine", "chest", "hips"), "neck": ("chest", "neck", "chest"),
         "head": ("neck", "skull", "neck")}
    for s in (".L", ".R"):
        B.update({"upper_arm" + s: ("sh" + s, "el" + s, "chest"), "forearm" + s: ("el" + s, "wr" + s, "upper_arm" + s),
                  "hand" + s: ("wr" + s, "tip" + s, "forearm" + s), "thigh" + s: ("hip" + s, "knee" + s, "hips"),
                  "shin" + s: ("knee" + s, "ank" + s, "thigh" + s), "foot" + s: ("ank" + s, "toe" + s, "shin" + s)})
    return {b: (J[h], J[t], p) for b, (h, t, p) in B.items()}


def head(K, J, skin, face_mat, rings, n=10):
    h = K.tube("head", skin, "head", J["neck"], J["skull"], rings, n=n)
    h.data.materials.append(face_mat)
    L = (V(J, "skull") - V(J, "neck")).length
    uv = h.data.uv_layers.new(name="FaceUV")
    for p in h.data.polygons:
        if p.normal.y < -0.3 and 0.08 * L < p.center.z < 0.9 * L:
            p.material_index = 1
        for li in p.loop_indices:
            co = h.data.vertices[h.data.loops[li].vertex_index].co
            uv.data[li].uv = (0.5 + co.x / 0.24, co.z / L)
    return h


def ears(K, J, skin):
    for sx in (1, -1):
        p = V(J, "neck", "skull", 0.45) + Vector((sx * 0.1, 0.01, 0))
        K.box("ear", skin, "head", p, (0.025, 0.04, 0.055))


def front(o, m, ny, zmax=9.0):
    """Repaint the front faces of a part (local normal y < ny, below zmax) with material m: aprons, bibs."""
    o.data.materials.append(m); k = len(o.data.materials) - 1
    for p in o.data.polygons:
        if p.normal.y < ny and p.center.z < zmax:
            p.material_index = k


def limbs(K, J, M, sleeve, cuff, trouser, shoe, upper_r=0.052, hand_flat=0.5, hand_up=(1, 0, 0), boot=0.0, thigh_r=0.085):
    for s in (".L", ".R"):
        K.seg("upper_arm", sleeve, "upper_arm" + s, J["sh" + s], J["el" + s], upper_r, upper_r * 0.85)
        K.seg("forearm", cuff, "forearm" + s, J["el" + s], J["wr" + s], upper_r * 0.85, upper_r * 0.68)
        K.seg("hand", M["skin"], "hand" + s, J["wr" + s], J["tip" + s], 0.036, 0.03, flat=hand_flat, up=hand_up)
        if trouser is not None:
            K.seg("thigh", trouser, "thigh" + s, J["hip" + s], J["knee" + s], thigh_r, thigh_r * 0.73)
            K.seg("shin", shoe if boot else trouser, "shin" + s, J["knee" + s], J["ank" + s], thigh_r * 0.76 + 0.006 * boot,
                  thigh_r * 0.62)
        a, t = V(J, "ank" + s), V(J, "toe" + s)
        K.box("shoe", shoe, "foot" + s, (a + t) / 2 + Vector((0, 0, -0.035)), (0.1, (t - a).xy.length + 0.08, 0.08))


def finish(name, K, J, idle, extras=(), head_scale=1.0):
    """Head scaled up about the neck (the protagonist's chunkier proportions), join, rig, idle loop, save,
    export, render front and 3/4."""
    if head_scale != 1.0:
        bpy.context.view_layer.update()
        n = Vector(J["neck"]); S = Matrix.Translation(n) @ Matrix.Scale(head_scale, 4) @ Matrix.Translation(-n)
        for o in K.parts:
            if o["bone"] == "head":
                o.matrix_world = S @ o.matrix_world
        J["skull"] = tuple(n + (Vector(J["skull"]) - n) * head_scale)
    body = K.join(name)
    tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
    arm = lp.armature(name + "Rig", bones_for(J), body)
    P = lp.Poser(arm, body, {"feet": lambda n: n.startswith("foot")})
    P.action("Idle", 61, loop=True)
    for f, k in idle:
        P.pose(f, k)
    day_actions(P)  # their routine (docs/CONTEUDO_VILAREJO.md "As rotinas")
    arm.animation_data.action = bpy.data.actions["Idle_Loop"]
    for o in extras:
        tris += sum(len(p.vertices) - 2 for p in o.data.polygons)
    bpy.context.scene.render.fps = 30
    bpy.ops.wm.save_as_mainfile(filepath=paths.blend("npcs", name))
    bpy.ops.export_scene.gltf(filepath=paths.character("npc_" + name), export_format="GLB",
                              export_animations=True, export_skins=True)
    render(name)
    print("NPC %s tris=%d height=%.2f" % (name, tris, max((body.matrix_world @ v.co).z for v in body.data.vertices)))


def _legs(front, kind):  # a step: the front leg reaching, the back one pushing off (porteiro_build.py's)
    back = ".R" if front == ".L" else ".L"
    if kind == "contact":
        return [("thigh" + front, "X", -22), ("shin" + front, "X", 6), ("thigh" + back, "X", 16), ("shin" + back, "X", 14)]
    return [("thigh" + front, "X", 3), ("thigh" + back, "X", -12), ("shin" + back, "X", 42)]


def day_actions(P):
    """What they do through the day (Npc, NpcCatalog "rotina"), the same for all: the arms stay as they were built
    (folded on the belly, on the machete, joined in prayer), so no arm swing.
      Walk    a slow village walk, 32 frames (the stride is printed: Godot's NpcCatalog "passo")
      Sit     on a bench, hands where they were; Kneel  on both knees, bent forward a little
      LookUp  standing, looking up at something high (Tenório at the gate); Sweep  the arms down in front, a broom
              (Godot hangs it on hand.R) swept side to side"""
    P.action("Walk", 33, loop=True)
    for fr, fo, kind, sg in ((1, ".L", "contact", 1), (9, ".L", "pass", 1), (17, ".R", "contact", -1),
                             (25, ".R", "pass", -1), (33, ".L", "contact", 1)):
        P.pose(fr, _legs(fo, kind) + [("hips", "Z", 4 * sg), ("chest", "Z", -5 * sg), ("chest", "X", 3)])
        if fr == 1:
            print("NPC stride=%.3f" % abs(P.P["foot.L"].head.y - P.P["foot.R"].head.y))
    P.action("Sit", 61, loop=True)
    for f, b in ((1, 0), (31, 1), (61, 0)):
        P.pose(f, [("thigh.L", "X", -84), ("thigh.R", "X", -86), ("shin.L", "X", 82), ("shin.R", "X", 86),
                   ("chest", "X", 6 + 2 * b), ("head", "X", 4 + 3 * b)])
    P.action("Kneel", 61, loop=True)
    for f, b in ((1, 0), (31, 1), (61, 0)):
        P.pose(f, [("thigh.L", "X", -6), ("thigh.R", "X", -4), ("shin.L", "X", 92), ("shin.R", "X", 90),
                   ("chest", "X", 12 + 3 * b), ("head", "X", 10 + 5 * b)])
    P.action("LookUp", 61, loop=True)
    for f, b in ((1, 0), (31, 1), (61, 0)):
        P.pose(f, [("chest", "X", -4 - 1.5 * b), ("neck", "X", -10), ("head", "X", -20 - 4 * b), ("head", "Z", 6 * b)])
    P.action("Sweep", 31, loop=True)
    ARMS = [("upper_arm.R", (0.15, -0.45, -0.88)), ("forearm.R", (-0.25, -0.75, -0.6)), ("hand.R", (-0.2, -0.6, -0.78)),
            ("upper_arm.L", (-0.15, -0.45, -0.88)), ("forearm.L", (0.3, -0.75, -0.55)), ("hand.L", (0.25, -0.6, -0.75))]
    for f, sg in ((1, 1), (16, -1), (31, 1)):
        P.pose(f, [("hips", "Z", 6 * sg), ("chest", "Z", 16 * sg), ("chest", "X", 14), ("head", "X", 10)], aims=ARMS)


def render(name):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x, sc.render.resolution_y = 400, 560
    sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.32, 0.33, 0.35)
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sc.collection.objects.link(sun)
    sun.data.energy = 3.0; sun.rotation_euler = (math.radians(55), 0, math.radians(-30))
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.lens = 50
    sc.frame_set(1)
    for view, ang in (("front", 0), ("34", 35)):
        a = math.radians(ang); d = 4.2
        cam.location = (d * math.sin(a), -d * math.cos(a), 1.05)
        cam.rotation_euler = (Vector((0, 0, 0.85)) - cam.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = paths.render("npcs", "npc_%s_%s.png" % (name, view))
        bpy.ops.render.render(write_still=True)


def sides(J, d):  # mirror ".L" entries to ".R"
    for k, (x, y, z) in d.items():
        J[k + ".L"] = (x, y, z); J[k + ".R"] = (-x, y, z)

# Shared N64-style helpers for the character build scripts (tools/personagens): materials, tiny packed images, the
# Kit of rigid parts on a joint table, armature, Poser (actions and keyframes), grime UVs.
# Use:  sys.path.insert(0, <tools/comum>); import lowpoly as lp
# (the protagonist's protagonista_build.py / protagonista_rig.py predate this module and keep most of their own.)
import bpy, bmesh, math, random
import numpy as np
from mathutils import Vector, Matrix, Euler


def lin(c):
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def V(J, *k):
    """Joint k[0] of the joint table J as a Vector; with three args, the point k[2] of the way from k[0] to k[1]."""
    return Vector(J[k[0]]) if len(k) == 1 else Vector(J[k[0]]).lerp(Vector(J[k[1]]), k[2])


def clear_scene():
    for coll in (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.lights,
                 bpy.data.cameras, bpy.data.worlds, bpy.data.armatures, bpy.data.actions):
        for d in list(coll):
            coll.remove(d)


def new_image(name, px):
    """px: HxWx4 float sRGB, row 0 = bottom. Packed into the .blend, exported into the .glb."""
    h, w = px.shape[:2]
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels.foreach_set(px.astype(np.float32).ravel())
    img.pack()
    return img


def mat(name, rgb, tex=None, face=None, emit=0.0):
    """Flat, rough material. tex: tiny image multiplied over the colour through the GrimeUV map;
    face: painted image read through the FaceUV map. Node lookups by type (the UI may be localized)."""
    m = bpy.data.materials.new(name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    nt = m.node_tree
    b = next(n for n in nt.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
    b.inputs["Roughness"].default_value = 1.0
    b.inputs["Specular IOR Level"].default_value = 0.0
    col = lin(rgb) + (1.0,)
    img, uv = (face, "FaceUV") if face is not None else (tex, "GrimeUV")
    if img is not None:
        t = nt.nodes.new("ShaderNodeTexImage"); t.image = img; t.interpolation = "Closest"
        u = nt.nodes.new("ShaderNodeUVMap"); u.uv_map = uv
        nt.links.new(u.outputs["UV"], t.inputs["Vector"])
        if face is not None:
            nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
        else:
            mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
            mix.inputs[0].default_value = 1.0; mix.inputs[6].default_value = col
            nt.links.new(t.outputs["Color"], mix.inputs[7]); nt.links.new(mix.outputs[2], b.inputs["Base Color"])
    else:
        b.inputs["Base Color"].default_value = col
    if emit:
        b.inputs["Emission Color"].default_value = col; b.inputs["Emission Strength"].default_value = emit
    m.diffuse_color = col
    return m


def frame(a, b, up=(1, 0, 0)):
    """Matrix whose Z runs a->b, X follows `up`, and whose -Y is the 'front' (lathe vertex 0)."""
    a, b = Vector(a), Vector(b)
    z = (b - a).normalized(); x = Vector(up); x = (x - z * x.dot(z)).normalized()
    m = Matrix((x, z.cross(x), z)).transposed().to_4x4(); m.translation = a
    return m


class Kit:
    """Collects mesh parts, each bound to one bone (or a {bone: weight} dict), then joins them."""

    def __init__(self):
        self.parts = []

    def _obj(self, name, bm, m, bone, mw=None):
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
        if mw is not None:
            o.matrix_world = mw
        o.data.materials.append(m); o["bone"] = bone if isinstance(bone, str) else repr(bone)
        self.parts.append(o)
        return o

    def tube(self, name, m, bone, a, b, rings, n=6, up=(1, 0, 0), caps=True):
        """Low-poly tube from a to b. rings: (t 0..1, rx, ry[, yoff, xoff]); vertex 0 faces local -Y."""
        L = (Vector(b) - Vector(a)).length
        bm = bmesh.new(); rows = []
        for r in rings:
            t, rx, ry = r[:3]; yo = r[3] if len(r) > 3 else 0.0; xo = r[4] if len(r) > 4 else 0.0
            rows.append([bm.verts.new((xo + rx * math.cos(-math.pi / 2 + 2 * math.pi * i / n),
                                       yo + ry * math.sin(-math.pi / 2 + 2 * math.pi * i / n), t * L))
                         for i in range(n)])
        for p, q in zip(rows, rows[1:]):
            for i in range(n):
                j = (i + 1) % n
                bm.faces.new((p[i], p[j], q[j], q[i]))
        if caps:
            bm.faces.new(list(reversed(rows[0]))); bm.faces.new(rows[-1])
        return self._obj(name, bm, m, bone, frame(a, b, up))

    def seg(self, name, m, bone, a, b, ra, rb, n=6, flat=1.0, up=(1, 0, 0)):
        return self.tube(name, m, bone, a, b, [(0, ra, ra * flat), (1, rb, rb * flat)], n=n, up=up)

    def spike(self, name, m, bone, a, b, r, n=4, flat=1.0, up=(1, 0, 0)):
        return self.tube(name, m, bone, a, b, [(0, r, r * flat), (1, 0.002, 0.002)], n=n, up=up)

    def box(self, name, m, bone, loc, size, rot=(0, 0, 0)):
        bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0)
        return self._obj(name, bm, m, bone, Matrix.LocRotScale(Vector(loc), Euler(rot).to_quaternion(), Vector(size)))

    def blob(self, name, m, bone, loc, r, seed=0, lump=0.18):
        """Lumpy low-poly growth (subdivided icosahedron with jittered vertices)."""
        rnd = random.Random(seed)
        bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
        for v in bm.verts:
            v.co *= 1 + rnd.uniform(-lump, lump)
        r = r if isinstance(r, (tuple, list)) else (r, r, r)
        return self._obj(name, bm, m, bone, Matrix.LocRotScale(Vector(loc), None, Vector(r)))

    def join(self, name):
        """Skin weights from each part's bone, join into one mesh, flat shading, bake GrimeUV."""
        bpy.context.view_layer.update()
        for o in self.parts:
            w = o["bone"]
            w = {w: 1.0} if not w.startswith("{") else eval(w)
            for bone, val in w.items():
                vg = o.vertex_groups.get(bone) or o.vertex_groups.new(name=bone)
                vg.add([v.index for v in o.data.vertices], val, "REPLACE")
        root = bpy.data.objects.new(name, bpy.data.meshes.new(name)); bpy.context.scene.collection.objects.link(root)
        sel = self.parts + [root]
        with bpy.context.temp_override(active_object=root, object=root, selected_objects=sel,
                                       selected_editable_objects=sel):
            bpy.ops.object.join()
        me = root.data
        for p in me.polygons:
            p.use_smooth = False
        bake_grime_uv(me)
        return root


def bake_grime_uv(me, scale=3.0):
    """Box projection baked into a real UV map: glTF cannot carry Blender's box projection."""
    for layer in [l for l in me.uv_layers if l.name != "FaceUV"]:
        me.uv_layers.remove(layer)
    uv = me.uv_layers.new(name="GrimeUV")
    for p in me.polygons:
        n = [abs(c) for c in p.normal]
        a, b = (1, 2) if n[0] >= max(n[1], n[2]) else (0, 2) if n[1] >= n[2] else (0, 1)
        for li in p.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            uv.data[li].uv = (co[a] * scale, co[b] * scale)


def armature(name, bones, body):
    """bones: {name: (head, tail, parent)}. Creates the armature and skins `body` to it."""
    data = bpy.data.armatures.new(name)
    arm = bpy.data.objects.new(name, data); bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for n, (h, t, _) in bones.items():
        eb = data.edit_bones.new(n); eb.head, eb.tail = h, t
    for n, (_, _, p) in bones.items():
        if p:
            data.edit_bones[n].parent = data.edit_bones[p]
    bpy.ops.object.mode_set(mode="OBJECT")
    body.parent = arm
    mod = body.modifiers.new("Armature", "ARMATURE"); mod.object = arm
    return arm


class Poser:
    """Keys poses built from rest + world-space turns/aims, then puts the lowest vertex on the floor."""

    def __init__(self, arm, body, ground_sets):
        self.arm, self.body, self.P = arm, body, arm.pose.bones
        names = [g.name for g in body.vertex_groups]
        self.ground_sets = {k: [v.index for v in body.data.vertices if any(test(names[g.group]) for g in v.groups)]
                            for k, test in ground_sets.items()}

    @staticmethod
    def upd():
        bpy.context.view_layer.update()

    def aim(self, bone, d):
        pb = self.P[bone]; m = pb.matrix.copy(); head = m.translation.copy()
        q = Vector(m.col[1][:3]).normalized().rotation_difference(Vector(d).normalized())
        pb.matrix = Matrix.Translation(head) @ q.to_matrix().to_4x4() @ Matrix.Translation(-head) @ m
        self.upd()

    def turn(self, bone, axis, deg):
        pb = self.P[bone]; m = pb.matrix.copy(); head = m.translation.copy()
        pb.matrix = Matrix.Translation(head) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-head) @ m
        self.upd()

    def action(self, name, last, loop=False):
        """Looping actions get a _Loop suffix: Godot then loops them and strips the suffix."""
        act = bpy.data.actions.new(name + ("_Loop" if loop else "")); act.use_fake_user = True
        self.arm.animation_data_create().action = act
        act.use_frame_range = True; act.frame_range = (1, last - 1 if loop else last)
        return act

    def pose(self, frame, turns=(), aims=(), ground="feet", lift=0.0):
        for pb in self.P:
            pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
        self.upd()
        for bone, d in aims:
            self.aim(bone, d)
        for bone, axis, deg in turns:
            self.turn(bone, axis, deg)
        ev = self.body.evaluated_get(bpy.context.evaluated_depsgraph_get())
        minz = min((ev.matrix_world @ ev.data.vertices[i].co).z for i in self.ground_sets[ground]) - lift
        root = next(pb for pb in self.P if pb.parent is None)
        root.matrix = Matrix.Translation((0, 0, -minz)) @ root.matrix
        self.upd()
        for pb in self.P:
            pb.keyframe_insert("location", frame=frame)
            pb.keyframe_insert("rotation_quaternion", frame=frame)
        return -minz

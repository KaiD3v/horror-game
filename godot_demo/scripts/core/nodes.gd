# Small scene-tree helpers.
class_name Nodes


## The first node of class `cls` at or under n, depth first.
static func find_first(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := find_first(c, cls)
		if r:
			return r
	return null


## n's direct children whose name starts with prefix (the GLB markers: npc_*, luz_*, corvo_*...).
static func children_named(n: Node, prefix: String) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for c in n.get_children():
		if c is Node3D and String(c.name).begins_with(prefix):
			out.append(c)
	return out


## fn(mesh_instance, surface_index, material) for every mesh surface at or under n.
static func visit_surfaces(n: Node, fn: Callable) -> void:
	if n is MeshInstance3D and n.mesh:
		for i in n.mesh.get_surface_count():
			fn.call(n, i, n.mesh.surface_get_material(i))
	for c in n.get_children():
		visit_surfaces(c, fn)

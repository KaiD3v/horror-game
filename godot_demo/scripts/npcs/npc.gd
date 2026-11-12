# A villager in the world (NpcCatalog): solid, idling out of step with the others, with the light and the sound their
# catalog entry gives them; E talks to them (Talk -> DialogBox), their shop an option of the talk.
# Their routine (NpcCatalog "rotina", run by Level._routine): pose(slot) puts them in a slot's pose with its prop; go()
# takes them to the next one, walking a path, or (no path: an interior, or too far to be seen) unseen: they are just
# there, or gone, the moment the player is not looking at them.
class_name Npc
extends AnimatableBody3D

signal gone   # out by a door to another scene (Level forgets them)

const SEEN := 30.0       # beyond this (the fog) nobody sees them move
const TURN := 6.0        # how fast they turn to where they walk
const LAYER := 3         # their own collision layer: the player bumps into them; the mutants, the navmesh and the
                         # camera do not (they move about: no hole in the navmesh where they once stood)

var who := ""
var info: Dictionary
var anim: AnimationPlayer
var model: Node3D
var light: OmniLight3D
var voice: AudioStreamPlayer3D
var talk: Talk            # E · falar com <nome>
var slot := {}            # where the routine has them now
var prop: Node3D          # what that slot has them hold (leva)
var path := PackedVector3Array()
var goal := Transform3D() # where they are going, and facing
var going := false
var leaving := false      # ...and out through a door: gone when there
var unseen := false       # (no path: waiting until nobody looks)


static func spawn(parent: Node, who_: String, at: Transform3D) -> Npc:
	var n := Npc.new(); n.who = who_; n.name = who_; n.transform = at
	parent.add_child(n)
	return n


func _ready() -> void:
	sync_to_physics = false
	collision_layer = 0; set_collision_layer_value(LAYER, true)
	info = NpcCatalog.info(who)
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new()
	cap.radius = info.raio; cap.height = info.altura
	cs.shape = cap; cs.position.y = info.altura / 2; add_child(cs)
	model = load(Paths.character("npc_" + who)).instantiate(); add_child(model)  # faces +z
	Looks.n64(model)
	anim = Nodes.find_first(model, "AnimationPlayer")
	anim.play("Idle"); anim.seek(randf() * anim.current_animation_length, true)
	if info.has("luz"):
		var l: Dictionary = info.luz
		light = Looks.omni(self, l.at, l.cor, l.energia, l.alcance)
	talk = Talk.make(self)
	if info.has("som"):
		var s: Dictionary = info.som
		voice = Audio.play3d(self, s.nome, s.at, s.db, true, s.size, s.far)


## What stays where they stand at `home` when they walk off (Firmina's candles and their light at the cross).
func leave_behind(home: Transform3D) -> void:
	var stay := Node3D.new(); stay.name = who + "_fica"; get_parent().add_child(stay); stay.global_transform = home
	var candles := model.find_child("velas", true, false)
	if candles:
		var t: Transform3D = global_transform.affine_inverse() * candles.global_transform
		candles.get_parent().remove_child(candles); stay.add_child(candles); candles.transform = t
	if light and info.luz.get("fica", false):
		remove_child(light); stay.add_child(light)


## In the slot's pose, with its prop, standing still.
func pose(s: Dictionary) -> void:
	slot = s; going = false; unseen = false
	anim.play(s.faz, 0.4)
	if prop:
		prop.queue_free(); prop = null
	match s.leva:
		"vassoura": prop = _broom()
		"lamparina": prop = _lamp()


## Off to `to` (and its slot), or out by a door there (`leave`), or in by one (`arriving`: they stand at the door):
## walking the path when there is one in sight, otherwise unseen.
func go(to: Transform3D, s: Dictionary, leave := false, arriving := false) -> void:
	slot = s; goal = to; leaving = leave; going = true
	if prop:
		prop.queue_free(); prop = null
	var map := get_world_3d().navigation_map
	var near := _seen_from(global_position) or _seen_from(to.origin) or _near(global_position) or _near(to.origin)
	path = NavigationServer3D.map_get_path(map, global_position, to.origin, true) \
		if near and NavigationServer3D.map_get_iteration_id(map) > 0 else PackedVector3Array()
	unseen = path.size() < 2 or path[path.size() - 1].distance_to(to.origin) > 1.0
	if unseen and arriving:  # nobody walked in: they will just be there
		visible = false; global_transform = to
	if not unseen:
		anim.play("Walk", 0.3); anim.speed_scale = 1.0


func _physics_process(delta: float) -> void:
	if not going:
		return
	if unseen:  # nobody looking where they are (leaving) or where they go (arriving), or either (across): done
		var here := visible and _seen_from(global_position)
		if not here and not (not leaving and _seen_from(goal.origin)):
			visible = true; _arrive()
		return
	var to := path[0] if path.size() > 0 else goal.origin
	var d := to - global_position
	var step: float = info.passo * delta
	if d.length() <= step:
		global_position = to
		if path.size() > 0:
			path.remove_at(0)
		if path.is_empty():
			_arrive()
		return
	global_position += d.normalized() * step
	var flat := Vector2(d.x, d.z)
	if flat.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), minf(1.0, TURN * delta))


func _arrive() -> void:
	going = false
	if leaving:
		if _near(global_position):
			Audio.play3d(get_parent(), "porta", global_position, -4.0, false, 3.0, 20.0)
		gone.emit(); queue_free()
		return
	global_transform = goal
	pose(slot)


func _seen_from(p: Vector3) -> bool:  # on the player's screen and not lost in the fog
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam.global_position.distance_to(p) < SEEN and cam.is_position_in_frustum(p + Vector3(0, 1.0, 0))


func _near(p: Vector3) -> bool:
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam.global_position.distance_to(p) < SEEN


func _hand(bone: String) -> BoneAttachment3D:
	var sk: Skeleton3D = Nodes.find_first(model, "Skeleton3D")
	var b := BoneAttachment3D.new(); b.bone_name = bone; sk.add_child(b)
	return b


func _broom() -> Node3D:  # Bento's broom of straw on a stick, in his right hand, the head on the ground
	var b := _hand("hand.R")
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.45, 0.33, 0.2)
	var straw := StandardMaterial3D.new(); straw.albedo_color = Color(0.7, 0.6, 0.35)
	var stick := MeshInstance3D.new(); var c := CylinderMesh.new(); c.top_radius = 0.015; c.bottom_radius = 0.015
	c.height = 1.25; c.material = wood; stick.mesh = c; b.add_child(stick); stick.position = Vector3(0, 0.35, 0)
	var head := MeshInstance3D.new(); var h := BoxMesh.new(); h.size = Vector3(0.32, 0.22, 0.06); h.material = straw
	head.mesh = h; b.add_child(head); head.position = Vector3(0, 1.0, 0)  # (the hand bone runs down his fingers)
	return b


func _lamp() -> Node3D:  # Tenório's lamp on the porch floor beside him, lit
	var n := Node3D.new(); add_child(n); n.position = Vector3(-0.5, 0, 0.25)
	var tin := StandardMaterial3D.new(); tin.albedo_color = Color(0.3, 0.27, 0.22); tin.metallic = 0.6
	var glass := StandardMaterial3D.new(); glass.albedo_color = Color(1.0, 0.75, 0.4)
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var base := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.14, 0.05, 0.14); bm.material = tin
	base.mesh = bm; n.add_child(base); base.position.y = 0.025
	var g := MeshInstance3D.new(); var gm := CylinderMesh.new(); gm.top_radius = 0.045; gm.bottom_radius = 0.055
	gm.height = 0.16; gm.material = glass; g.mesh = gm; n.add_child(g); g.position.y = 0.13
	Looks.omni(n, Vector3(0, 0.3, 0), Color(1.0, 0.68, 0.36), 1.4, 6.0)
	return n

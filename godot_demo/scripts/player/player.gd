# The protagonist (models/characters/protagonista.glb), third person, for every level.
# Modes: EXPLORE (lantern, Idle/Walk) -> COMBAT (machete) / XBOW (crossbow) / CROUCH -> DEAD. One-shot actions
# (draw, sheathe, attacks, dodge, hit) play over the mode (PlayerAnimation). Camera over the right shoulder; drawing
# the machete eases it closer/lower, crouching drops it with his head. The coat flaps have spring physics
# (CoatPhysics); bolts fly on their own (Bolt); how hurt and tired he is shows on his body (PlayerCondition).
# Controls (GameInput): WASD jog (Ctrl walks, Shift sprints), mouse look, L lantern on the hook / in hand, C crouch,
# F draw/sheathe, LMB slash, RMB overhead chop, Space dodge (+A/D: to that side), Q crossbow (R or LMB when empty
# reloads, LMB looses), H hurt yourself (debug), Esc frees the mouse.
class_name Player
extends CharacterBody3D

signal died
signal notice(text: String)   # something to tell the player (the HUD shows it): out of bolts, healed...

const WALK_SPEED := 0.91      # Ctrl held: = Walk stride / cycle time, so the feet do not slide
const JOG_SPEED := 1.66       # the default pace, no stamina: = Jog stride / cycle time (rig.py jog_speed)
const RUN_SPEED := 2.6        # sprint
const RUN_STRIDE := 3.2       # ground speed of Run_Lantern at 1x: played slower to match RUN_SPEED
const STAMINA_MAX := 4.0      # seconds of sprint from full
const STAMINA_REGEN := 0.5    # per second, after REGEN_DELAY without sprinting (full in 8 s)
const REGEN_DELAY := 1.0
const WINDED_UNTIL := 1.5     # emptied: no sprint until stamina is back up to this
const ACCEL := 8.0            # m/s², so walk <-> sprint eases instead of snapping
const COMBAT_SPEED := 0.6
const CROUCH_SPEED := 0.67     # = Crouch_Walk stride / cycle time
const TURN_SPEED := 10.0
const MOUSE_SENS := 0.003
const DODGE_DIST := 0.8
const DODGE_FROM := 4.0 / 30.0
const DODGE_TO := 12.0 / 30.0
const DODGE_DIR := {"Dodge_Back": Vector3.BACK, "Dodge_Left": Vector3.LEFT, "Dodge_Right": Vector3.RIGHT}  # body space
const HIT_TIME := {"Attack_Slash": 10.0 / 30.0, "Attack_Overhead": 13.0 / 30.0}
const HIT_DAMAGE := {"Attack_Slash": 1, "Attack_Overhead": 2}
const HIT_RANGE := 1.6
const COMBO_FROM := 12.0 / 30.0   # LMB after this point of a slash queues the overhead chop
# Over-the-shoulder camera (right shoulder). Combat pulls in closer and further aside, so the target stays clear.
const CAM_EXPLORE := {"height": 1.55, "side": 0.45, "length": 1.7, "fov": 62.0}
const CAM_COMBAT := {"height": 1.5, "side": 0.6, "length": 1.35, "fov": 54.0}
const CAM_AIM := {"height": 1.5, "side": 0.55, "length": 1.1, "fov": 50.0}  # crossbow out: tighter, over the shoulder
const CAM_CROUCH := {"height": 1.15, "side": 0.4, "length": 1.5, "fov": 60.0}  # head drops ~0.4 m kneeling
const CAM_BLEND := 5.0        # how fast the camera eases between the framings
enum Mode { EXPLORE, COMBAT, DEAD, CROUCH, XBOW }  # = PlayerAnimation.MODE_INPUTS
const SHOT_TIME := 2.0 / 30.0       # Shoot_Crossbow: the bolt leaves on frame 2
const BOLT_RANGE := 40.0            # how far the crosshair looks for what to aim at

@export var max_health := 3
var health := 3
var stamina := STAMINA_MAX
var winded := false
var rest := 0.0           # time since the last sprint
var mode := Mode.EXPLORE
var action := ""          # one-shot playing, "" = none
var action_t := 0.0
var action_len := 0.0
var hit_done := false
var swung := false        # the swing's whoosh has played (it leads the blow a little)
var queued := ""
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var model: Node3D
var skeleton: Skeleton3D
var coat: SpringBoneSimulator3D
var loaded := false                # a bolt on the rail (single shot: reload after every shot)
var aim_anim: AnimationNodeAnimation
var tree: AnimationTree
var shot: AnimationNodeAnimation
var pivot: Node3D
var pitch: Node3D
var cam: Camera3D
var arm: SpringArm3D
var cam_now := CAM_EXPLORE.duplicate()
var lantern: OmniLight3D
var lantern_out := true    # in his right hand; false = hung on the belt hook, hands free (L)
var hook: LanternHook
var shake := 0.0
var flicker := 0.0
var condition: PlayerCondition  # blood, breathing, panting


func _ready() -> void:
	health = max_health
	add_to_group("player")
	GameInput.setup()
	var col := CollisionShape3D.new(); add_child(col)
	var cap := CapsuleShape3D.new(); cap.radius = 0.25; cap.height = 1.7
	col.shape = cap; col.position.y = 0.85

	model = load(Paths.character("protagonista")).instantiate()
	add_child(model)
	model.rotation.y = PI  # glTF faces +Z, the body's forward is -Z
	skeleton = Nodes.find_first(model, "Skeleton3D")
	tree = PlayerAnimation.build(model, Nodes.find_first(model, "AnimationPlayer"))
	shot = tree.tree_root.get_node("shot"); aim_anim = tree.tree_root.get_node("aim")
	coat = CoatPhysics.setup(skeleton)
	condition = PlayerCondition.new(self); add_child(condition)
	hook = LanternHook.new(); hook.bone = skeleton.find_bone("lantern"); hook.active = false
	skeleton.add_child(hook)

	var ba := BoneAttachment3D.new(); ba.bone_name = "lantern"; skeleton.add_child(ba)
	lantern = OmniLight3D.new(); ba.add_child(lantern)
	lantern.position = Vector3(0, 0.09, 0)  # glass centre, down the bone
	lantern.light_color = Color(1.0, 0.62, 0.28); lantern.omni_range = 7.0; lantern.omni_attenuation = 0.8
	lantern.shadow_enabled = false  # the light sits inside the lantern glass, which would block it (N64 lights had no shadows anyway)

	pivot = Node3D.new(); pivot.top_level = true; add_child(pivot)
	pitch = Node3D.new(); pivot.add_child(pitch); pitch.rotation.x = -0.25
	arm = SpringArm3D.new(); pitch.add_child(arm)
	arm.margin = 0.2; arm.collision_mask = 3;  # layer 2 = ceilings (kept out of the navmesh)
	arm.add_excluded_object(get_rid())
	cam = Camera3D.new(); arm.add_child(cam)
	_apply_cam()
	pivot.global_position = global_position + Vector3(0, cam_now.height, 0)
	pivot.rotation.y = rotation.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivot.rotation.y -= e.relative.x * MOUSE_SENS
		pitch.rotation.x = clamp(pitch.rotation.x - e.relative.y * MOUSE_SENS, -1.1, 0.35)
	elif e is InputEventMouseButton and e.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif e.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif e.is_action_pressed("debug_hurt"):
		take_damage(1)
	elif mode != Mode.DEAD:
		if e.is_action_pressed("draw"):
			toggle_weapon()
		elif e.is_action_pressed("attack"):
			attack("Attack_Slash")
		elif e.is_action_pressed("heavy"):
			attack("Attack_Overhead")
		elif e.is_action_pressed("dodge"):
			dodge()
		elif e.is_action_pressed("crouch"):
			crouch()
		elif e.is_action_pressed("crossbow"):
			toggle_crossbow()
		elif e.is_action_pressed("reload"):
			reload()
		elif e.is_action_pressed("lantern"):
			toggle_lantern()
		elif e.is_action_pressed("heal"):
			use_cure()


# --- actions ---------------------------------------------------------------------------------------
func play(n: String, backward := false) -> void:
	shot.animation = n
	shot.play_mode = AnimationNodeAnimation.PLAY_MODE_BACKWARD if backward else AnimationNodeAnimation.PLAY_MODE_FORWARD
	tree.set("parameters/action/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	action = n; action_t = 0.0; hit_done = false; swung = false; queued = ""
	action_len = tree.get_animation(n).length


func set_mode(m: Mode) -> void:
	mode = m
	tree.set("parameters/mode/transition_request", PlayerAnimation.MODE_INPUTS[m])


func toggle_weapon() -> void:
	if action != "" or mode == Mode.CROUCH or mode == Mode.XBOW:
		return
	if mode == Mode.EXPLORE:
		play("Draw_Machete"); set_mode(Mode.COMBAT)   # the one-shot hides the switch underneath
		sfx("facao_sacar", -4.0)
	else:
		play("Draw_Machete", true); set_mode(Mode.EXPLORE)  # sheathing = the draw backwards
		sfx("facao_guardar", -4.0)


func attack(n: String) -> void:
	if mode == Mode.CROUCH:
		return
	if mode == Mode.XBOW:
		if action == "" and n == "Attack_Slash":
			if loaded:
				play("Shoot_Crossbow")
			else:
				reload()
		return
	if mode == Mode.EXPLORE:
		toggle_weapon()
	elif action == "":
		play(n)
	elif action == "Attack_Slash" and action_t >= COMBO_FROM:
		queued = "Attack_Overhead"


func dodge() -> void:
	if mode == Mode.COMBAT and (action == "" or action.begins_with("Attack")):
		var side := Input.get_axis("left", "right")
		play("Dodge_Left" if side < -0.5 else "Dodge_Right" if side > 0.5 else "Dodge_Back")


func toggle_crossbow() -> void:  # exploring only; holstering = the draw backwards (the lantern back in hand)
	if action != "":
		return
	if loaded:  # it travels uncocked in the holster; a loaded bolt goes back in the quiver
		Inventory.add("virote")
	_set_loaded(false)
	if mode == Mode.EXPLORE:
		play("Draw_Crossbow"); set_mode(Mode.XBOW)
		sfx("besta_sacar", -5.0)
	elif mode == Mode.XBOW:
		play("Draw_Crossbow", true); set_mode(Mode.EXPLORE)
		sfx("besta_sacar", -5.0, 0.88)  # back into the holster: the same leather, a touch lower


func reload() -> void:
	if mode == Mode.XBOW and action == "" and not loaded:
		if not Inventory.take("virote"):  # a bolt from the quiver (Inventory), if there is one left
			notice.emit("Sem virotes.")
			return
		play("Reload_Crossbow")
		sfx("besta_recarga", -4.0)


func _set_loaded(v: bool) -> void:
	loaded = v
	aim_anim.animation = "Aim_Crossbow" if v else "Aim_Crossbow_Empty"  # the bolt on the rail, or not


func crouch() -> void:  # exploring only; standing up = Crouch_Down backwards
	if action != "":
		return
	var clip := "Crouch_Down" if lantern_out else "Crouch_Down_Free"
	if mode == Mode.EXPLORE:
		play(clip); set_mode(Mode.CROUCH)
	elif mode == Mode.CROUCH:
		play(clip, true); set_mode(Mode.EXPLORE)


func toggle_lantern() -> void:  # exploring: hang it on the belt hook (hands free) or take it back (the hang backwards)
	if action != "" or mode != Mode.EXPLORE:
		return
	play("Stow_Lantern", not lantern_out)
	lantern_out = not lantern_out
	sfx("lamparina", -6.0)
	for n in ["hands", "crouch_hands"]:
		tree.set("parameters/%s/blend_amount" % n, 0.0 if lantern_out else 1.0)


func heal(n: int) -> void:
	health = mini(max_health, health + n)


## X: dresses a wound with the first healing item carried (Inventory).
func use_cure() -> void:
	var id := Inventory.first_cure()
	if id == "":
		notice.emit("Sem curativos.")
	elif health >= max_health:
		notice.emit("Não está ferido.")
	elif Inventory.use(id, self):
		sfx("curativo", -3.0)
		notice.emit("%s · restam %d" % [ItemCatalog.item(id).nome, Inventory.count(id)])


func take_damage(n: int) -> void:
	if mode == Mode.DEAD:
		return
	health -= n
	shake = 0.25; flicker = 0.4
	sfx("dano", -2.0)
	if health <= 0:
		tree.set("parameters/action/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
		action = ""
		set_mode(Mode.DEAD)
		died.emit()
	elif mode == Mode.COMBAT:
		play("Hit_React")  # exploring: no flinch clip with the lantern pose, the shake sells it


## One of his own sounds (heard from where he is: 2D), pitch varied a little so a repeat never sounds the same.
func sfx(n: String, db := 0.0, pitch := 1.0) -> void:
	Audio.play2d(self, n, db).pitch_scale = pitch * randf_range(0.95, 1.05)


# --- per frame -------------------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	var move := Vector3.ZERO
	var speed := 0.0
	if action != "":
		_tick_action(delta)
	if action == "" and mode != Mode.DEAD:
		var input := Input.get_vector("left", "right", "forward", "back")
		move = pivot.global_basis * Vector3(input.x, 0, input.y)
		move.y = 0
		move = move.normalized() * min(input.length(), 1.0)
		if mode == Mode.CROUCH:
			speed = CROUCH_SPEED
		elif mode == Mode.COMBAT or mode == Mode.XBOW:
			speed = COMBAT_SPEED
		else:
			speed = RUN_SPEED if _sprinting(input) else (WALK_SPEED if Input.is_action_pressed("walk") else JOG_SPEED)
	_tick_stamina(delta, speed == RUN_SPEED)
	var hv := Vector3.ZERO  # actions stop you dead, as before
	if action == "":
		hv = Vector3(velocity.x, 0, velocity.z).move_toward(move * speed, ACCEL * delta)
	if DODGE_DIR.has(action) and action_t >= DODGE_FROM and action_t < DODGE_TO:
		hv = global_basis * DODGE_DIR[action] * DODGE_DIST / (DODGE_TO - DODGE_FROM)
	velocity.x = hv.x; velocity.z = hv.z
	move_and_slide()

	# facing: exploring turns towards the movement, combat faces where the camera looks (strafe)
	var target := rotation.y
	if (mode == Mode.COMBAT or mode == Mode.XBOW) and not DODGE_DIR.has(action):
		target = pivot.rotation.y
	elif move.length() > 0.1:
		target = atan2(-move.x, -move.z)
	rotation.y = lerp_angle(rotation.y, target, TURN_SPEED * delta)

	var moving := Vector2(velocity.x, velocity.z).length()
	for p in ["l", "f"]:
		tree.set("parameters/%s_explore/blend_amount" % p, clamp(moving / WALK_SPEED, 0.0, 1.0))
		tree.set("parameters/%s_jog_mix/blend_amount" % p, clamp((moving - WALK_SPEED) / (JOG_SPEED - WALK_SPEED), 0.0, 1.0))
		tree.set("parameters/%s_run_mix/blend_amount" % p, clamp((moving - JOG_SPEED) / (RUN_SPEED - JOG_SPEED), 0.0, 1.0))
		tree.set("parameters/%s_walk_ts/scale" % p, clamp(moving / WALK_SPEED, 1.0, JOG_SPEED / WALK_SPEED))
		tree.set("parameters/%s_jog_ts/scale" % p, clamp(moving / JOG_SPEED, WALK_SPEED / JOG_SPEED, RUN_SPEED / JOG_SPEED))
		tree.set("parameters/%s_run_ts/scale" % p, RUN_SPEED / RUN_STRIDE)
		tree.set("parameters/%s_crouch/blend_amount" % p, clamp(moving / CROUCH_SPEED, 0.0, 1.0))
	# hung but the clip has it in hand (machete, crossbow, death): keep it on the hook
	var own_clip := (action == "" or action == "Stow_Lantern" or action == "Crouch_Down_Free") 		and (mode == Mode.EXPLORE or mode == Mode.CROUCH)
	hook.active = not lantern_out and not own_clip
	tree.set("parameters/xbow/blend_amount", clamp(moving / COMBAT_SPEED, 0.0, 1.0) if action == "" else 0.0)
	tree.set("parameters/combat/blend_amount", clamp(moving / COMBAT_SPEED, 0.0, 1.0) if action == "" else 0.0)


func _sprinting(input: Vector2) -> bool:
	return Input.is_action_pressed("sprint") and input.length() > 0.1 and not winded and stamina > 0.0


func _tick_stamina(delta: float, sprinting: bool) -> void:
	if sprinting:
		rest = 0.0
		stamina = max(0.0, stamina - delta)
		winded = stamina == 0.0
	else:
		rest += delta
		if rest >= REGEN_DELAY:
			stamina = min(STAMINA_MAX, stamina + STAMINA_REGEN * delta)
		if winded and stamina >= WINDED_UNTIL:
			winded = false


func _tick_action(delta: float) -> void:
	action_t += delta
	if action == "Shoot_Crossbow" and not hit_done and action_t >= SHOT_TIME:
		hit_done = true
		_loose_bolt(); _set_loaded(false)
		sfx("besta_disparo", -2.0)
	if HIT_TIME.has(action) and not swung and action_t >= HIT_TIME[action] - 0.12:
		swung = true
		sfx("facao_golpe", -3.0, 0.88 if action == "Attack_Overhead" else 1.0)  # the chop from above: heavier
	if HIT_TIME.has(action) and not hit_done and action_t >= HIT_TIME[action]:
		hit_done = true
		var struck := false
		for e in get_tree().get_nodes_in_group("enemy"):
			var to: Vector3 = e.global_position - global_position
			to.y = 0
			if to.length() < HIT_RANGE and (-global_basis.z).dot(to.normalized()) > 0.4:
				e.take_hit(HIT_DAMAGE[action]); struck = true
		if struck:
			sfx("facao_acerto", -2.0)
	if action_t >= action_len:
		if action == "Reload_Crossbow":
			_set_loaded(true)
		var next := queued
		action = ""
		if next != "":
			play(next)


func _process(delta: float) -> void:
	var goal: Dictionary = CAM_COMBAT if mode == Mode.COMBAT else CAM_AIM if mode == Mode.XBOW \
		else CAM_CROUCH if mode == Mode.CROUCH else CAM_EXPLORE
	for k in goal:
		cam_now[k] = lerp(float(cam_now[k]), float(goal[k]), min(1.0, CAM_BLEND * delta))
	_apply_cam()
	pivot.global_position = pivot.global_position.lerp(global_position + Vector3(0, cam_now.height, 0), min(1.0, 10.0 * delta))
	shake = max(0.0, shake - delta)
	cam.h_offset = randf_range(-1, 1) * shake * 0.2
	cam.v_offset = randf_range(-1, 1) * shake * 0.2
	flicker = max(0.0, flicker - delta)
	var t := Time.get_ticks_msec() / 1000.0
	lantern.light_energy = 3.0 * (0.9 + 0.06 * sin(t * 13.0) + 0.04 * sin(t * 31.0)) * (0.3 if randf() < flicker else 1.0)


func _apply_cam() -> void:
	arm.position.x = cam_now.side      # pivot's +X = screen right: the character sits left of centre
	arm.spring_length = cam_now.length
	cam.fov = cam_now.fov


# --- crossbow -------------------------------------------------------------------------------------------
func _loose_bolt() -> void:
	# from the crossbow towards whatever is under the screen centre (the crosshair), up to BOLT_RANGE
	var space := get_world_3d().direct_space_state
	var from := cam.global_position; var ahead := -cam.global_basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + ahead * BOLT_RANGE, 1, [get_rid()])
	var hit := space.intersect_ray(q)
	var aim_at: Vector3 = hit.position if hit else from + ahead * BOLT_RANGE
	var xb := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("crossbow"))
	var dir := (aim_at - xb.origin).normalized()
	Bolt.fire(get_parent(), xb.origin + dir * 0.32, dir, get_rid())


func crossbow_in_hand() -> bool:
	var c := skeleton.get_bone_global_pose(skeleton.find_bone("crossbow")).origin
	var g := skeleton.get_bone_global_pose(skeleton.find_bone("grip.R")).origin
	return c.distance_to(g) < 0.03


func lantern_hung() -> bool:  # on its belt hook = its rest spot relative to the hips
	var h := skeleton.find_bone("hips"); var l := skeleton.find_bone("lantern")
	var hook := skeleton.get_bone_global_pose(h) * skeleton.get_bone_global_rest(h).affine_inverse() * skeleton.get_bone_global_rest(l)
	return skeleton.get_bone_global_pose(l).origin.distance_to(hook.origin) < 0.03


func machete_in_hand() -> bool:
	var m := skeleton.get_bone_global_pose(skeleton.find_bone("machete")).origin
	var g := skeleton.get_bone_global_pose(skeleton.find_bone("grip.L")).origin
	return m.distance_to(g) < 0.03

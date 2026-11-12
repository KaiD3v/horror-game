# The protagonist (models/characters/protagonista.glb), third person, for every level.
# Modes: EXPLORE (lantern, Idle/Walk) -> COMBAT (machete) / XBOW (crossbow) / CROUCH -> DEAD. One-shot actions
# (draw, sheathe, attacks, dodge, hit) play over the mode (PlayerAnimation), each over as much of him as it needs
# (LAYER): drawing, sheathing, reloading, shooting and the lantern leave the legs walking. Crouching (`crouched`) goes
# with any weapon: exploring it is the CROUCH mode, armed only the legs kneel. Camera over the right shoulder; drawing
# the machete eases it closer/lower, crouching drops it with his head. The coat flaps have spring physics
# (CoatPhysics); bolts fly on their own (Bolt); how hurt and tired he is shows on his body (PlayerCondition).
# Controls (GameInput): WASD jog (Ctrl walks, Shift sprints), mouse look, C crouch, 1 machete, 2 crossbow (each again:
# away), 3 lantern (armed: the weapon away; exploring: on the hook / in hand), Q the weapon wheel (WeaponWheel ->
# equip). A drawn weapon is carried low (walks, jogs, sprints freely); RMB held raises it: the machete blocks, the
# crossbow aims (strafing, the tight camera, the crosshair; only then LMB looses). LMB slash (again in its
# follow-through: the overhead chop), E locks on the nearest enemy
# ahead (armed; again releases it), Space dodge (+A/D: to that side), R or LMB when empty reloads, LMB looses,
# F dresses a wound, H hurt yourself (debug). 4: the pickaxe (held as the machete is: COMBAT with `held`). (Esc: the pause menu, GameMenu.) Swings and dodges spend stamina (COST).
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
const COST := {"Attack_Slash": 0.8, "Attack_Overhead": 1.2, "Dodge": 1.0}  # stamina, out of STAMINA_MAX
const BLOCK_SPEED := 0.4      # shuffling behind the raised machete
const BLOCK_CHIP := 0.25      # of a blow's damage that still gets through the block
const BLOCK_ARC := 0.3        # a blow is blocked when the attacker is this far in front (dot)
const BLOCK_RAISE := 8.0      # how fast the guard goes up / down (blend per second)
const LOCK_RANGE := 12.0      # E locks onto an enemy this close, ahead of the camera
const LOCK_BREAK := 16.0      # ...and lets go past this
const LOCK_TURN := 8.0        # how fast the camera swings onto it
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
const FALL_SAFE := 2.2        # m he can drop and land unhurt (off a ledge, a 2 m wall)
const FALL_PER := 1.5         # ...beyond it, a wound for every this much more (a 3.5 m wall: 1, 5 m: 2, 6.5 m: dead)
const STEP_EASE := 12.0       # 1/s: how fast the body catches up with the root after a step (Steps): quick at first
const WEAPON_ITEM := {Mode.COMBAT: "facao", Mode.XBOW: "besta"}  # what you need to have (Inventory) to hold it
const COMBO_FROM := 12.0 / 30.0   # LMB after this point of a slash queues the overhead chop
# which one-shot of PlayerAnimation plays an action: "upper" leaves him walking, "arm" only moves the lantern's arm;
# the rest ("action": attacks, dodges, flinches, crouching down) is the whole body and stops him
const LAYER := {"Draw_Machete": "upper", "Draw_Crossbow": "upper", "Reload_Crossbow": "upper",
	"Shoot_Crossbow": "upper", "Block_Hit": "upper", "Stow_Lantern": "arm"}
const SHOTS := {"arm": "shot_arm", "upper": "shot_up", "action": "shot"}
# Over-the-shoulder camera (right shoulder). Combat pulls in closer and further aside, so the target stays clear.
const CAM_EXPLORE := {"height": 1.55, "side": 0.45, "length": 1.7, "fov": 62.0}
const CAM_COMBAT := {"height": 1.5, "side": 0.6, "length": 1.35, "fov": 54.0}
const CAM_AIM := {"height": 1.5, "side": 0.55, "length": 1.1, "fov": 50.0}  # crossbow out: tighter, over the shoulder
const CAM_KNEEL := {"height": 0.95, "side": 0.0, "length": 2.1, "fov": 55.0}  # at a trunk (Chest): down with him, centred
const CAM_CLIMB := {"height": 1.4, "side": 0.0, "length": 2.8, "fov": 60.0}   # on a wall (Climbable): back, to see the holds
const CAM_CROUCH := {"height": 1.15, "side": 0.4, "length": 1.5, "fov": 60.0}  # head drops ~0.4 m kneeling
const CAM_BLEND := 5.0        # how fast the camera eases between the framings
enum Mode { EXPLORE, COMBAT, DEAD, CROUCH, XBOW, CLIMB }  # CLIMB: on a wall (Climbable)  # = PlayerAnimation.MODE_INPUTS
const SHOT_TIME := 2.0 / 30.0       # Shoot_Crossbow: the bolt leaves on frame 2
const BOLT_RANGE := 40.0            # how far the crosshair looks for what to aim at

@export var max_health := 3   # an upgrade raises it (the HUD gets another heart)
var health := 3.0           # a blocked blow takes a fraction (BLOCK_CHIP)
var stamina := STAMINA_MAX
var stamina_max := STAMINA_MAX  # an upgrade raises it (the HUD's rosary gets more beads)
var winded := false
var rest := 0.0           # time since the last sprint
var mode := Mode.EXPLORE
var crouched := false     # down on his heels: the CROUCH mode exploring, or kneeling with a weapon out
const BODY_H := 1.7       # his body's height standing...
const BODY_LOW := 1.2     # ...and crouched: he goes under what is lower than a man (the ruin's fallen ceiling)
var body: CylinderShape3D
var body_col: CollisionShape3D
var crouch_amt := 0.0     # the kneeling legs' blend under a weapon, eased
var action := ""          # one-shot playing, "" = none
var action_t := 0.0
var action_len := 0.0
var hit_done := false
var swung := false        # the swing's whoosh has played (it leads the blow a little)
var queued := ""
var fall_top := NAN        # airborne: the highest he was since he left the floor (NAN = on it)
var step_lag := 0.0       # the body's lag behind a step the root just took (eases to 0)
var walk_to := Vector3.INF  # busy, walked there by a script (Intro) at walk pace, feet and animation as usual
var busy := false         # in a scripted moment (a trunk, a push, a climb, a jump): no control, E / Q / keys do
                          # nothing, no gravity; whoever started it moves him
var cam_override := {}    # a scripted moment's camera (CAM_KNEEL...), {} = the usual
var wanted := -1          # a Mode chosen on the weapon wheel, on its way (-1 = none)
var held := "facao"       # what COMBAT holds in the left hand: the machete, or a tool held the same way (picareta)
var wanted_held := "facao"
var tool_hand: ToolInHand # holding a tool: the machete hidden, the tool where it would be
var blocking := false     # RMB held with the machete out
var aiming := false       # RMB held (or locked on) with the crossbow out
var raised := false       # the weapon up (guard / aim): strafing at combat pace; down = carried, walking freely
var raise_amt := 0.0      # carried <-> raised blend, eased
var carry_anim: AnimationNodeAnimation
var block_amt := 0.0      # the guard's blend, eased
var lock: Node3D          # the enemy the camera is locked on (E), null = free look
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var model: Node3D
var skeleton: Skeleton3D
var coat: SpringBoneSimulator3D
var loaded := false                # a bolt on the rail (single shot: reload after every shot)
var aim_anim: AnimationNodeAnimation
var tree: AnimationTree
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
	max_health = Inventory.health_max(); stamina_max = Inventory.breath_max()  # (the upgrades carried)
	health = max_health; stamina = stamina_max
	add_to_group("player")
	Steps.keep_down(self)
	GameInput.setup()
	body_col = CollisionShape3D.new(); add_child(body_col)
	body = CylinderShape3D.new(); body.radius = 0.25; body.height = BODY_H  # flat-bottomed: it stands on a stair's edge instead of rolling off it (Steps)
	body_col.shape = body; body_col.position.y = BODY_H / 2

	model = load(Paths.character("protagonista")).instantiate()
	add_child(model)
	model.rotation.y = PI  # glTF faces +Z, the body's forward is -Z
	skeleton = Nodes.find_first(model, "Skeleton3D")
	tree = PlayerAnimation.build(model, Nodes.find_first(model, "AnimationPlayer"))
	aim_anim = tree.tree_root.get_node("aim")
	carry_anim = tree.tree_root.get_node("x_carry")
	tree.set("parameters/x_low/blend_amount", 1.0)  # the carried crossbow's bolt / string: always from x_carry
	coat = CoatPhysics.setup(skeleton)
	condition = PlayerCondition.new(self); add_child(condition)
	hook = LanternHook.new(); hook.bone = skeleton.find_bone("lantern"); hook.active = false
	skeleton.add_child(hook)
	tool_hand = ToolInHand.new(); tool_hand.player = self; skeleton.add_child(tool_hand)

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
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and lock == null:
		pivot.rotation.y -= e.relative.x * MOUSE_SENS
		pitch.rotation.x = clamp(pitch.rotation.x - e.relative.y * MOUSE_SENS, -1.1, 0.35)
	elif e is InputEventMouseButton and e.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif e.is_action_pressed("debug_hurt"):
		take_damage(1)
	elif mode != Mode.DEAD and not busy:
		if e.is_action_pressed("draw"):  # 1, 2, 4: that one out, or away again if it is the one in hand
			equip(Mode.EXPLORE if mode == Mode.COMBAT and held == "facao" else Mode.COMBAT)
		elif e.is_action_pressed("pickaxe"):
			equip(Mode.EXPLORE if mode == Mode.COMBAT and held == "picareta" else Mode.COMBAT, "picareta")
		elif e.is_action_pressed("crossbow"):
			equip(Mode.EXPLORE if mode == Mode.XBOW else Mode.XBOW)
		elif e.is_action_pressed("attack"):
			attack("Attack_Slash")
		elif e.is_action_pressed("dodge"):
			dodge()
		elif e.is_action_pressed("crouch"):
			crouch()
		elif e.is_action_pressed("reload"):
			reload()
		elif e.is_action_pressed("lantern"):  # 3: the lantern on / off its hook (the crossbow needs both hands: away)
			if mode == Mode.XBOW:
				_set_lantern(true); equip(Mode.EXPLORE)
			else:
				toggle_lantern()
		elif e.is_action_pressed("heal"):
			use_cure()


# --- actions ---------------------------------------------------------------------------------------
func play(n: String, backward := false) -> void:
	var layer: String = LAYER.get(n, "action")
	var shot: AnimationNodeAnimation = tree.tree_root.get_node(SHOTS[layer])
	shot.animation = n
	shot.play_mode = AnimationNodeAnimation.PLAY_MODE_BACKWARD if backward else AnimationNodeAnimation.PLAY_MODE_FORWARD
	for l in SHOTS:  # one action at a time: the one before it stops
		tree.set("parameters/%s/request" % l, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE if l == layer else AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	action = n; action_t = 0.0; hit_done = false; swung = false; queued = ""
	action_len = tree.get_animation(n).length


## Cut whatever he is doing short (dead; a skipped cutscene).
func stop_action() -> void:
	for l in SHOTS:
		tree.set("parameters/%s/request" % l, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	action = ""


## Whether he can walk: nothing playing, or an action that leaves the legs alone (LAYER).
func legs_free() -> bool:
	return action == "" or LAYER.has(action)


## The mode with no weapon out: exploring, or crouched.
func unarmed() -> bool:
	return mode == Mode.EXPLORE or mode == Mode.CROUCH


## The lantern in his hand (not on its hook): it is never in hand with the crossbow out, both hands are on it.
func holds_lantern() -> bool:
	return lantern_out and mode != Mode.XBOW and mode != Mode.CLIMB


func set_mode(m: Mode) -> void:
	mode = m
	if m == Mode.DEAD or m == Mode.CLIMB:
		crouched = false
	tree.set("parameters/mode/transition_request", PlayerAnimation.MODE_INPUTS[m])


## What to hold (the weapon wheel, Q): whatever is in his hands goes away first (sheathe / holster / stand up),
## then the chosen one comes out, one clip after the other. EXPLORE = the lantern, no weapon. COMBAT holds `what`
## (the machete, or the pickaxe in its place).
func equip(m: Mode, what := "facao") -> void:
	var need: String = what if m == Mode.COMBAT else WEAPON_ITEM.get(m, "")
	if not Inventory.has(need):
		notice.emit("Sem %s." % ItemCatalog.item(need).nome.to_lower())
		return
	wanted = m
	if m == Mode.COMBAT:
		wanted_held = what
	_equip_next()


func _equip_next() -> void:
	if wanted < 0 or action != "" or mode == Mode.DEAD:
		return
	if (mode == wanted and (mode != Mode.COMBAT or held == wanted_held)) or (wanted == Mode.EXPLORE and unarmed()):
		wanted = -1  # (crouched: he stays down)
	elif mode == Mode.COMBAT or (unarmed() and wanted == Mode.COMBAT):
		if unarmed():
			held = wanted_held  # what comes out of the draw
		toggle_weapon()
	elif mode == Mode.XBOW or (unarmed() and wanted == Mode.XBOW):
		toggle_crossbow()


## Puts away whatever is in his hands and stands up; returns when he has (a scripted moment starts with them free).
func free_hands() -> void:
	if mode != Mode.EXPLORE:
		equip(Mode.EXPLORE)
	var t0 := Time.get_ticks_msec()
	while (mode != Mode.EXPLORE or action != "") and Time.get_ticks_msec() - t0 < 4000:
		if mode == Mode.CROUCH and action == "" and wanted < 0:
			crouch()  # ...and up on his feet
		await get_tree().process_frame


## Whether he has what that mode holds (WEAPON_ITEM, COMBAT: what it holds; the lantern / crouching: always).
func owns(m: Mode) -> bool:
	return Inventory.has(held if m == Mode.COMBAT else WEAPON_ITEM.get(m, ""))


func toggle_weapon() -> void:
	if action != "" or mode == Mode.XBOW or (unarmed() and not owns(Mode.COMBAT)):
		return
	if unarmed():
		play("Draw_Machete"); set_mode(Mode.COMBAT)   # the one-shot hides the switch underneath
		sfx("facao_sacar", -4.0)
	else:
		play("Draw_Machete", true); set_mode(_unarmed_mode())  # sheathing = the draw backwards
		sfx("facao_guardar", -4.0)


func _unarmed_mode() -> Mode:
	return Mode.CROUCH if crouched else Mode.EXPLORE


func attack(n: String) -> void:
	if mode == Mode.CROUCH:
		return
	if mode == Mode.XBOW:
		if action == "" and n == "Attack_Slash" and aiming:  # carried low it does not shoot
			if loaded:
				play("Shoot_Crossbow")
			else:
				reload()
		return
	if mode == Mode.EXPLORE:
		toggle_weapon()
	elif action == "" or action == "Block_Hit":
		if spend(COST[n]):
			crouched = false  # a swing stands him up
			play(n)
	elif action == "Attack_Slash" and action_t >= COMBO_FROM and queued == "":
		if spend(COST.Attack_Overhead):
			queued = "Attack_Overhead"


func dodge() -> void:
	if mode == Mode.COMBAT and (action == "" or action == "Block_Hit" or action.begins_with("Attack")) and spend(COST.Dodge):
		var side := Input.get_axis("left", "right")
		crouched = false
		play("Dodge_Left" if side < -0.5 else "Dodge_Right" if side > 0.5 else "Dodge_Back")


## Stamina for a swing or a dodge: false (and nothing spent) when there is not enough left. Emptying it winds him,
## like sprinting does.
func spend(cost: float) -> bool:
	if stamina < cost:
		notice.emit("Sem fôlego.")
		return false
	stamina -= cost; rest = 0.0
	winded = winded or stamina <= 0.01
	return true


## E with a weapon out: lock the camera on the nearest enemy ahead that he can see, or let go of the one locked.
## false = nothing to lock on (E is free for doors and notes).
func toggle_lock() -> bool:
	if lock:
		lock = null
		return true
	if mode != Mode.COMBAT and mode != Mode.XBOW:
		return false
	lock = lock_candidate()
	return lock != null


func lock_candidate() -> Node3D:
	var best: Node3D = null; var best_score := INF
	var ahead := -cam.global_basis.z
	for en in get_tree().get_nodes_in_group("enemy"):
		var to: Vector3 = _lock_point(en) - cam.global_position
		var d := to.length()
		var facing := ahead.dot(to / d)
		if d > LOCK_RANGE or facing < 0.5:
			continue
		var q := PhysicsRayQueryParameters3D.create(cam.global_position, _lock_point(en), 1, [get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit and hit.collider != en:
			continue  # behind a wall
		var score := d * (2.0 - facing)  # near and close to the centre of the screen
		if score < best_score:
			best = en; best_score = score
	return best


func _lock_point(en: Node3D) -> Vector3:  # its chest: where the camera (and the crosshair) settle
	return en.global_position + Vector3(0, 1.3, 0)


func _track_lock(delta: float) -> void:
	if lock and (not is_instance_valid(lock) or not lock.is_in_group("enemy") or (mode != Mode.COMBAT and mode != Mode.XBOW)
			or lock.global_position.distance_to(global_position) > LOCK_BREAK):
		lock = null
	if lock == null:
		return
	var to := _lock_point(lock) - cam.global_position
	var k := minf(1.0, LOCK_TURN * delta)
	pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-to.x, -to.z), k)
	pitch.rotation.x = lerpf(pitch.rotation.x, clampf(atan2(to.y, Vector2(to.x, to.z).length()), -1.1, 0.35), k)


func toggle_crossbow() -> void:  # unarmed only; holstering = the draw backwards (the lantern back in hand)
	if action != "" or mode == Mode.COMBAT or (unarmed() and not owns(Mode.XBOW)):
		return
	if loaded:  # it travels uncocked in the holster; a loaded bolt goes back in the quiver
		Inventory.add("virote")
	_set_loaded(false)
	if unarmed():
		play("Draw_Crossbow"); set_mode(Mode.XBOW)
		sfx("besta_sacar", -5.0)
	elif mode == Mode.XBOW:
		play("Draw_Crossbow", true); set_mode(_unarmed_mode())
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
	carry_anim.animation = "Carry_Crossbow" if v else "Carry_Crossbow_Empty"


func crouch() -> void:  # exploring: Crouch_Down (standing up = backwards); armed: the legs alone kneel / rise
	if crouched and not can_stand():
		notice.emit("Baixo demais para levantar.")
		return
	if not crouched:
		Hints.did("agachar")
	if mode == Mode.COMBAT or mode == Mode.XBOW:
		if legs_free():
			crouched = not crouched
		return
	if action != "":
		return
	var clip := "Crouch_Down" if lantern_out else "Crouch_Down_Free"
	if mode == Mode.EXPLORE:
		play(clip); set_mode(Mode.CROUCH); crouched = true
	elif mode == Mode.CROUCH:
		play(clip, true); set_mode(Mode.EXPLORE); crouched = false


## Hang it on the belt hook (the right hand free) or take it back (the hang backwards): exploring, crouched or with
## the machete in the other hand; only the right arm moves.
func toggle_lantern() -> void:
	if action != "" or not (unarmed() or mode == Mode.COMBAT):
		return
	play("Stow_Lantern", not lantern_out)
	_set_lantern(not lantern_out)
	if not lantern_out:
		Hints.did("lamparina")
	sfx("lamparina", -6.0)


func _set_lantern(out: bool) -> void:
	lantern_out = out
	for n in ["hands", "crouch_hands", "c_hands"]:
		tree.set("parameters/%s/blend_amount" % n, 0.0 if lantern_out else 1.0)


func heal(n: int) -> void:
	health = minf(max_health, health + n)


## F: dresses a wound with the first healing item carried (Inventory).
func use_cure() -> void:
	var id := Inventory.first_cure()
	if id == "":
		notice.emit("Sem curativos.")
	elif health >= max_health:
		notice.emit("Não está ferido.")
	elif Inventory.use(id, self):
		sfx("curativo", -3.0)
		Hints.did("curativo")


## A blow (from = who struck it). Blocking with it in front, the machete takes it: only BLOCK_CHIP gets through.
func take_damage(n: float, from: Node3D = null) -> void:
	if mode == Mode.DEAD:
		return
	if blocking and from and (-global_basis.z).dot((from.global_position - global_position).normalized()) > BLOCK_ARC:
		health -= n * BLOCK_CHIP
		shake = 0.12
		sfx("bloqueio", -2.0)
		play("Block_Hit")
		if health > 0.0:
			return
		n = 0.0  # ...the last of him: it still kills
	else:
		health -= n
		shake = 0.25; flicker = 0.4
		if health > 0.0 and Inventory.first_cure() != "":
			Hints.want(self, "curativo", 4.0)
		sfx("dano", -2.0)
	if health <= 0.0:
		stop_action()
		set_mode(Mode.DEAD)
		died.emit()
	elif mode == Mode.COMBAT:
		play("Hit_React")  # exploring: no flinch clip with the lantern pose, the shake sells it


## How many wounds a drop of `drop` metres costs: none up to FALL_SAFE, then one more every FALL_PER.
static func fall_damage(drop: float) -> int:
	return 0 if drop <= FALL_SAFE else int((drop - FALL_SAFE) / FALL_PER) + 1


## Down on his feet after a drop: a thud from a metre up, wounds past FALL_SAFE.
func _landed(drop: float) -> void:
	if drop < 1.0 or mode == Mode.DEAD:
		return
	sfx("pouso", -2.0); shake = maxf(shake, minf(0.3, 0.05 * drop))
	var n := fall_damage(drop)
	if n > 0:
		take_damage(n)
		notice.emit("A queda o machucou.")


## One of his own sounds (heard from where he is: 2D), pitch varied a little so a repeat never sounds the same.
func sfx(n: String, db := 0.0, pitch := 1.0) -> void:
	Audio.play2d(self, n, db).pitch_scale = pitch * randf_range(0.95, 1.05)


# --- per frame -------------------------------------------------------------------------------------
## Room over his head to stand up in (his standing body, clear of the floor, touches nothing).
func can_stand() -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var s := CylinderShape3D.new(); s.radius = body.radius; s.height = BODY_H - 0.15
	q.shape = s; q.transform = Transform3D(Basis(), global_position + Vector3(0, 0.15 + s.height / 2, 0))
	q.exclude = [get_rid()]; q.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


## His body as tall as he is now. (ponytail: a swing or a dodge stands him up even under a low ceiling; the physics
## then pushes him out of it. Guard those with can_stand() if a fight ever happens under one.)
func _fit_body() -> void:
	var h := BODY_LOW if crouched else BODY_H
	if not is_equal_approx(body.height, h):
		body.height = h; body_col.position.y = h / 2


## The situational lines (Hints) his own state asks for: the crossbow out and not aimed; and what he has just done.
func _hints(was: Array) -> void:
	if blocking and not was[0] and held == "facao":
		Hints.did("bloquear")
	if aiming and not was[1]:
		Hints.did("mirar")
	if mode == Mode.XBOW and not aiming and action == "":
		Hints.want(self, "mirar")


func _physics_process(delta: float) -> void:
	var led := busy and walk_to != Vector3.INF  # walked by a script: physics as usual, the input ignored
	_fit_body()
	if not is_on_floor() and (not busy or led):
		velocity.y -= gravity * delta
	var move := Vector3.ZERO
	var speed := 0.0
	if action != "":
		_tick_action(delta)
	var was := [blocking, aiming]
	blocking = mode == Mode.COMBAT and Input.is_action_pressed("block") and (action == "" or action == "Block_Hit")
	block_amt = move_toward(block_amt, 1.0 if blocking else 0.0, BLOCK_RAISE * delta)
	aiming = mode == Mode.XBOW and (Input.is_action_pressed("block") or lock != null)
	_hints(was)
	raised = aiming or (mode == Mode.XBOW and action == "Shoot_Crossbow") \
		or (mode == Mode.COMBAT and (blocking or lock != null or (action != "" and not LAYER.has(action))))  # mid-swing
	raise_amt = move_toward(raise_amt, 1.0 if raised else 0.0, BLOCK_RAISE * delta)
	for n in ["combat_ready", "xbow_ready"]:
		tree.set("parameters/%s/blend_amount" % n, raise_amt)
	tree.set("parameters/block/blend_amount", block_amt)
	crouch_amt = move_toward(crouch_amt, 1.0 if crouched else 0.0, BLOCK_RAISE * delta)
	tree.set("parameters/crouch_legs/blend_amount", crouch_amt)
	if legs_free() and mode != Mode.DEAD and not busy:
		var input := Input.get_vector("left", "right", "forward", "back")
		move = pivot.global_basis * Vector3(input.x, 0, input.y)
		move.y = 0
		move = move.normalized() * min(input.length(), 1.0)
		if raised:
			speed = BLOCK_SPEED if blocking else COMBAT_SPEED
			if crouched:
				speed = minf(speed, CROUCH_SPEED)
		elif crouched:
			speed = CROUCH_SPEED
		else:
			speed = RUN_SPEED if _sprinting(input) else (WALK_SPEED if Input.is_action_pressed("walk") else JOG_SPEED)
	elif led and legs_free():
		move = walk_to - global_position; move.y = 0
		move = move.normalized() if move.length() > 0.15 else Vector3.ZERO
		speed = WALK_SPEED
	_tick_stamina(delta, speed == RUN_SPEED)
	var hv := Vector3.ZERO  # whole-body actions stop you dead
	if legs_free():
		hv = Vector3(velocity.x, 0, velocity.z).move_toward(move * speed, ACCEL * delta)
	if DODGE_DIR.has(action) and action_t >= DODGE_FROM and action_t < DODGE_TO:
		hv = global_basis * DODGE_DIR[action] * DODGE_DIST / (DODGE_TO - DODGE_FROM)
	velocity.x = hv.x; velocity.z = hv.z
	if busy and not led:
		velocity = Vector3.ZERO  # moved by whoever made him busy
	else:
		var y0 := global_position.y
		Steps.up(self, delta)  # a step or a stair ahead: up onto it
		move_and_slide()
		var dy := global_position.y - y0
		if is_on_floor() and absf(dy) > 0.05 and absf(dy) <= Steps.SNAP:  # up or down a step: the body eases after
			step_lag -= dy
		if not is_on_floor():
			fall_top = global_position.y if is_nan(fall_top) else maxf(fall_top, global_position.y)
		elif not is_nan(fall_top):
			_landed(fall_top - global_position.y); fall_top = NAN
	step_lag = lerpf(step_lag, 0.0, minf(1.0, STEP_EASE * delta))
	if absf(step_lag) < 0.002:
		step_lag = 0.0
	model.position.y = step_lag

	# facing: exploring turns towards the movement, combat faces where the camera looks (strafe)
	var target := rotation.y
	if raised and not DODGE_DIR.has(action):
		target = pivot.rotation.y
	elif move.length() > 0.1:
		target = atan2(-move.x, -move.z)
	rotation.y = lerp_angle(rotation.y, target, TURN_SPEED * delta)

	var moving := Vector2(velocity.x, velocity.z).length()
	for p in ["l", "f", "c", "cf", "x"]:
		tree.set("parameters/%s_explore/blend_amount" % p, clamp(moving / WALK_SPEED, 0.0, 1.0))
		tree.set("parameters/%s_jog_mix/blend_amount" % p, clamp((moving - WALK_SPEED) / (JOG_SPEED - WALK_SPEED), 0.0, 1.0))
		tree.set("parameters/%s_run_mix/blend_amount" % p, clamp((moving - JOG_SPEED) / (RUN_SPEED - JOG_SPEED), 0.0, 1.0))
		tree.set("parameters/%s_walk_ts/scale" % p, clamp(moving / WALK_SPEED, 1.0, JOG_SPEED / WALK_SPEED))
		tree.set("parameters/%s_jog_ts/scale" % p, clamp(moving / JOG_SPEED, WALK_SPEED / JOG_SPEED, RUN_SPEED / JOG_SPEED))
		tree.set("parameters/%s_run_ts/scale" % p, RUN_SPEED / RUN_STRIDE)
		if p == "l" or p == "f" or p == "c":  # (c: the k_ legs under a weapon)
			tree.set("parameters/%s_crouch/blend_amount" % ("k" if p == "c" else p), clamp(moving / CROUCH_SPEED, 0.0, 1.0))
	# hung but the clip has it in hand (machete, crossbow, death): keep it on the hook
	var own_clip := action == "Stow_Lantern" or ((action == "" or action == "Crouch_Down_Free") and unarmed())
	hook.active = not lantern_out and not own_clip
	tree.set("parameters/xbow/blend_amount", clamp(moving / COMBAT_SPEED, 0.0, 1.0) if legs_free() else 0.0)
	tree.set("parameters/combat/blend_amount", clamp(moving / COMBAT_SPEED, 0.0, 1.0) if legs_free() else 0.0)


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
			stamina = min(stamina_max, stamina + STAMINA_REGEN * delta)
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
		for e in get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("breakable"):  # (Breakable: rock)
			var to: Vector3 = e.global_position - global_position
			to.y = 0
			if to.length() < HIT_RANGE and (-global_basis.z).dot(to.normalized()) > 0.4:
				e.take_hit(HIT_DAMAGE[action], held); struck = true
		if struck and held == "facao":  # (the rock makes its own)
			sfx("facao_acerto", -2.0)
	if action_t >= action_len:
		if action == "Reload_Crossbow":
			_set_loaded(true)
		var next := queued
		action = ""
		if next != "":
			play(next)
		else:
			_equip_next()


func _process(delta: float) -> void:
	_track_lock(delta)
	var goal: Dictionary = cam_override if not cam_override.is_empty() else CAM_COMBAT if mode == Mode.COMBAT and raised else CAM_AIM if mode == Mode.XBOW and raised \
		else CAM_CROUCH if mode == Mode.CROUCH else CAM_EXPLORE
	if crouched and mode != Mode.CROUCH and cam_override.is_empty():  # kneeling with a weapon: the camera drops with him
		goal = goal.duplicate(); goal.height -= 0.4
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


## An item's shape (models/props/itens.glb, by its ItemCatalog id or "modelo"; a cloth bundle for one with none) in
## his left hand, on grip.L as the machete sits there. Free it when done.
func hold_item(id: String) -> Node3D:
	var all: Node = load(Paths.PROP % "itens").instantiate()
	var thing: Node3D = all.find_child(ItemCatalog.item(id).get("modelo", id), false)
	if thing == null:
		thing = all.find_child("embrulho", false)
	all.remove_child(thing); all.free()
	var grip := BoneAttachment3D.new(); grip.bone_name = "grip.L"; skeleton.add_child(grip)
	grip.add_child(thing); thing.transform = Transform3D.IDENTITY
	return grip


func machete_in_hand() -> bool:  # on the fighting grip (grip.L) or the at-ease carry grip (grip.Lc)
	var m := skeleton.get_bone_global_pose(skeleton.find_bone("machete")).origin
	for g in ["grip.L", "grip.Lc"]:
		if m.distance_to(skeleton.get_bone_global_pose(skeleton.find_bone(g)).origin) < 0.03:
			return true
	return false

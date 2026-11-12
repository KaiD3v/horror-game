# O Porteiro's entrance (../docs/CHAVE_DO_PORTAO.md "A entrada"), about 11 s, the first time you step down into the
# crypt (Porteiro.introduced: a retry after a death goes straight to the fight). Four shots on the Cutscene frame
# (letterbox, a title, hold E to skip):
#   1  the stair falls in behind you: stone, dust, the camera shaking;
#   2  the dark: a slow push across the crypt, the candles low; his keys in the dark, and a riser climbing (chefe_tensao);
#   3  from below, the lantern on his chest flares alight (lampiao_acender): the bandaged shape;
#   4  he roars, and on the same instant the hit (chefe_impacto), the fight's music, and his name: O PORTEIRO.
# Played or skipped, it ends the same: the stair shut, his lantern lit, the music on, the camera back, and the fight.
class_name BossIntro
extends Cutscene

signal finished

const RISER_AT := 0.6        # s into shot 2: the riser starts, so that it cuts off on shot 4's hit

var L: Node3D                # the crypt (jazigo.gd)
var boss: Porteiro
var player: Player
var riser: AudioStreamPlayer
var hit := false             # the title's hit has happened (a skip before it still gets it)


func _init(level: Node3D, the_boss: Porteiro) -> void:
	super(level)
	L = level; boss = the_boss; player = level.player


func run() -> void:
	Porteiro.introduced = true
	player.busy = true; player.velocity = Vector3.ZERO; player.stop_action()
	L.hud.visible = false; L.menu.set_process_unhandled_input(false)
	var to := boss.global_position - player.global_position; to.y = 0
	player.rotation.y = atan2(-to.x, -to.z)
	await play([_collapse, _dark, _lamp, _name])
	_finish()


func _collapse() -> void:  # 1. behind him, the stair comes down
	var foot: Vector3 = (L.room.get_node("escada") as Node3D).position
	look(foot + Vector3(-0.7, 2.2, -4.0), foot + Vector3(0, 1.1, 0.2))  # (over his shoulder, between the columns, at it)
	fade(0.0, 0.25)
	L._shut_stair(true)
	var rubble: Node3D = L.shut
	var rest := rubble.position
	rubble.position = rest + Vector3(0, 3.5, 0)
	tw().tween_property(rubble, "position", rest, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await wait(0.45)
	_shake(0.5, 0.12)
	await wait(1.5)


func _dark() -> void:  # 2. across the crypt in the dark, towards something by the coffin; his keys
	for c in L.candles:
		tw().tween_property(c, "light_energy", c.light_energy * 0.35, 1.0)
	var at := boss.global_position + Vector3(0, 1.3, 0)
	look(Vector3(0.4, 1.5, -7.6), at)
	cam_tw().tween_property(cam, "global_position", Vector3(0.2, 1.35, -10.2), 3.0).set_trans(Tween.TRANS_SINE)
	await wait(RISER_AT)
	riser = Audio.play2d(L, "chefe_tensao", -2.0)
	await wait(0.6)
	Audio.play3d(boss, "porteiro_chaves", Vector3(0.4, 0.8, 0), 0.0, false, 4.0, 30.0)
	await wait(1.1)
	Audio.play3d(boss, "porteiro_chaves", Vector3(0.4, 0.8, 0), 2.0, false, 4.0, 30.0).pitch_scale = 0.9
	await wait(0.7)


func _lamp() -> void:  # 3. from below: his lantern flares, the bandaged face over it
	look(boss.global_position + Vector3(1.0, 0.55, 2.0), boss.global_position + Vector3(0, 1.9, 0))
	await wait(0.5)
	Audio.play3d(boss, "lampiao_acender", Vector3(0, 1.65, -0.35), 2.0, false, 4.0, 30.0)
	boss.light_lamp(1.2)
	await wait(1.6)


func _name() -> void:  # 4. the roar; the hit, the music, his name
	look(boss.global_position + Vector3(-0.5, 1.15, 2.7), boss.global_position + Vector3(0, 2.15, 0))
	cam_tw().tween_property(cam, "global_position", boss.global_position + Vector3(-0.4, 1.0, 2.3), 3.4)
	boss.ap.play("Roar", 0.2)
	await wait(0.35)
	_hit()
	await wait(3.0)
	tw().tween_property(title, "modulate:a", 0.0, 0.5); tw().tween_property(caption, "modulate:a", 0.0, 0.5)
	await wait(0.5)


func _hit() -> void:  # the impact, the music, the roar, the name, all at once
	if hit:
		return
	hit = true
	if is_instance_valid(riser):
		riser.queue_free()
	Audio.play2d(L, "chefe_impacto", 0.0)
	Audio.play3d(boss, "porteiro_rugido", Vector3(0, 2.0, 0), 6.0, false, 8.0, 50.0)
	Audio.music_play(L, L.MUSIC, L.MUSIC_DB, 0.05, true)
	title.text = "O PORTEIRO"; title.modulate.a = 0.0
	say("Severino · porteiro da Colônia Santa Clara"); caption.modulate.a = 0.0
	tw().tween_property(title, "modulate:a", 1.0, 0.15)
	tw().tween_property(caption, "modulate:a", 1.0, 0.6)
	_shake(0.6, 0.18)


func _shake(s: float, strength: float) -> void:  # the camera jolted, settling over s seconds
	var t := tw()
	for i in 6:
		var k := 1.0 - float(i) / 6.0
		t.tween_property(cam, "h_offset", randf_range(-1, 1) * strength * k, s / 12.0)
		t.tween_property(cam, "v_offset", randf_range(-1, 1) * strength * k, s / 12.0)
	t.tween_property(cam, "h_offset", 0.0, 0.05); t.tween_property(cam, "v_offset", 0.0, 0.05)


## Played or skipped: the same end, and the fight.
func _finish() -> void:
	L._shut_stair(true)
	if is_instance_valid(L.shut):
		L.shut.position.y = (L.room.get_node("escada") as Node3D).position.y + 1.6
	for c in L.candles:
		c.light_energy = 0.9 * L.dim
	if not hit:
		Audio.play2d(L, "chefe_impacto", -6.0)
		Audio.music_play(L, L.MUSIC, L.MUSIC_DB, 0.3, true)
	if is_instance_valid(riser):
		riser.queue_free()
	boss.light_lamp(0.0)
	player.busy = false
	player.cam.make_current(); cam.queue_free()
	L.hud.visible = true; L.menu.set_process_unhandled_input(true)
	boss.wake(false)
	finished.emit()
	queue_free()

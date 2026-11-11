# A villager standing in the world (NpcCatalog): solid, idling out of step with the others, with the light and the
# sound their catalog entry gives them; E talks to them (Talk -> DialogBox), their shop an option of the talk.
class_name Npc
extends StaticBody3D

var who := ""
var info: Dictionary
var anim: AnimationPlayer
var light: OmniLight3D
var voice: AudioStreamPlayer3D
var talk: Talk            # E · falar com <nome>


static func spawn(parent: Node, who_: String, at: Transform3D) -> Npc:
	var n := Npc.new(); n.who = who_; n.name = who_; n.transform = at
	parent.add_child(n)
	return n


func _ready() -> void:
	info = NpcCatalog.info(who)
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new()
	cap.radius = info.raio; cap.height = info.altura
	cs.shape = cap; cs.position.y = info.altura / 2; add_child(cs)
	var model: Node3D = load(Paths.character("npc_" + who)).instantiate(); add_child(model)  # faces +z
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

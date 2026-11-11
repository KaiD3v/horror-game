# What makes a villager someone to talk to: every Npc gets one. E near them turns the player to them and opens the
# DialogBox (what they say: Dialog, scripts/data/dialogos/<who>.gd). Their shop, if they have one, is an option there.
class_name Talk
extends Interactable

var who := ""


static func make(npc: Npc) -> Talk:
	var t := Talk.new(); t.who = npc.who
	t.prompt = "E · falar com %s" % npc.info.nome
	if npc.info.has("loja"):
		t.radius = 2.4; t.height = 1.8   # across the counter
	npc.add_child(t)
	return t


func _use(by: Node3D) -> void:
	if not by is Player:
		return
	var to := global_position - by.global_position
	by.rotation.y = atan2(-to.x, -to.z)  # facing them
	var box: DialogBox = get_tree().get_first_node_in_group("dialog_box")
	box.open(who, by)

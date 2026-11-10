# A door between scenes, Zelda style: E takes you to `scene`; `arrive` names the door you come out of there (the
# village puts you back at its porta_<arrive> marker).
class_name Door
extends Interactable

var scene := ""
var arrive := ""


static func make(at: Node3D, text: String, to_scene: String, arrive_at := "", r := 1.8) -> Door:
	var d := Door.new(); d.prompt = text; d.scene = to_scene; d.arrive = arrive_at; d.radius = r
	at.add_child(d)  # on the marker: it stands where the marker does
	return d


func _use(_by: Node3D) -> void:
	SceneRouter.go_to(self, scene, arrive)

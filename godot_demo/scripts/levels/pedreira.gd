# The quarry's gallery (../docs/CONTEUDO_VILAREJO.md "A pedreira"; ../tools/cenarios/pedreira_build.py): behind the rubble
# in the east bank (the pickaxe). The Colônia's store: the serum's inventory on the table (NotesData "inventario_soro"),
# a box of bolts, and a brazier with its embers still warm: somebody keeps it (the smoke seen from the belfry).
extends "res://scripts/levels/interior.gd"


func _build() -> void:
	super()
	var bolts := Pickup.make(self, Vector3(-0.8, 0.52, -3.6), "virote", 6, "pedreira_virotes")
	if is_instance_valid(bolts):
		bolts.prompt = "E · pegar a caixa de virotes"
	var embers := Interactable.new(); add_child(embers); embers.position = Vector3(-0.7, 0.0, -2.2)
	embers.radius = 1.2; embers.prompt = "E · olhar o braseiro"
	embers.used.connect(func(_by):
		Story.mark("pedreira:brasa")
		player.notice.emit("Brasa ainda quente, e um cobertor dobrado do lado. Alguém dorme aqui. Não é o doutor."))

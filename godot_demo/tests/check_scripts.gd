# Loads every script of the project and reports the ones that do not compile.
# Run: Godot_console.exe --headless --path godot_demo --script res://tests/check_scripts.gd
extends SceneTree


func _initialize() -> void:
	var bad := 0
	for dir in ["res://scripts", "res://tests"]:
		for f in _files(dir):
			if f.ends_with(".gd") and not f.ends_with("check_scripts.gd") and not f.ends_with("protagonista_anims.gd"):
				var s: GDScript = load(f)
				if s == null or not s.can_instantiate():
					print("BROKEN ", f); bad += 1
	print("SCRIPTS %s" % ("OK" if bad == 0 else "%d broken" % bad))
	quit()


func _files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir + "/" + d))
	return out

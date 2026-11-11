# What has happened in this game so far: marks that dialogues and places set and read (met someone, heard a rumour,
# opened a gate), and where each task stands (QuestData: nova -> ativa -> feita). Kept across scenes (statics, like the
# inventory); a new game starts it again. The one save to write later is `marks`.
class_name Story

static var marks := {}   # name -> true / a count / a task's state ("tarefa:<id>")


static func reset() -> void:
	marks.clear()


static func has(name: String) -> bool:
	return bool(marks.get(name, false))


static func mark(name: String, value: Variant = true) -> void:
	marks[name] = value


## How many times `name` has been bumped (the rumours told in turn).
static func count(name: String) -> int:
	return int(marks.get(name, 0))


static func bump(name: String) -> void:
	marks[name] = count(name) + 1


## A task's state: "nova" (not given yet), "ativa" or "feita".
static func task(id: String) -> String:
	return marks.get("tarefa:" + id, "nova")


static func set_task(id: String, state: String) -> void:
	marks["tarefa:" + id] = state

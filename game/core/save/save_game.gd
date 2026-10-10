class_name SaveGame
extends RefCounted
## Own JSON save format, versioned independently of any original game's
## file format. Writes to user:// (not res://), which is the correct
## writable, per-user location on Windows, Android and iOS alike.

const SAVE_DIR := "user://saves"
const SAVE_VERSION := 1

static func save_slot(slot: String, grid: CityGrid, budget: Budget, tick_count: int) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {
		"version": SAVE_VERSION,
		"tick_count": tick_count,
		"grid": grid.to_dict(),
		"budget": budget.to_dict(),
	}
	var path := "%s/%s.json" % [SAVE_DIR, slot]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

## Returns {} if the slot doesn't exist or is corrupt/unversioned; callers
## should treat an empty dict as "nothing to load".
static func load_slot(slot: String) -> Dictionary:
	var path := "%s/%s.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var result: Dictionary = parsed
	if int(result.get("version", -1)) != SAVE_VERSION:
		return {}

	var budget := Budget.new()
	budget.from_dict(result["budget"])
	return {
		"grid": CityGrid.from_dict(result["grid"]),
		"budget": budget,
		"tick_count": int(result.get("tick_count", 0)),
	}

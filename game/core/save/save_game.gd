class_name SaveGame
extends RefCounted
## Own JSON save format, versioned independently of any original game's
## file format. Writes to user:// (not res://), which is the correct
## writable, per-user location on Windows, Android and iOS alike.

const SAVE_DIR := "user://saves"
const SAVE_VERSION := 2 ## v1: grid+budget only. v2: + ordinances/disasters/news.

static func save_slot(slot: String, sim: CitySimulation) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {
		"version": SAVE_VERSION,
		"tick_count": sim.tick_count,
		"grid": sim.grid.to_dict(),
		"budget": sim.budget.to_dict(),
		"ordinances": sim.ordinances.to_dict(),
		"disasters_enabled": sim.disasters.enabled,
		"news": sim.news.to_dict(),
	}
	var path := "%s/%s.json" % [SAVE_DIR, slot]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

## Returns null if the slot doesn't exist, is corrupt, or was written by a
## newer save format than this code knows about. A save from an older
## version still loads: fields added since then just fall back to their
## defaults via .get() in each from_dict().
static func load_slot(slot: String) -> CitySimulation:
	var path := "%s/%s.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var result: Dictionary = parsed
	var saved_version := int(result.get("version", -1))
	if saved_version < 0 or saved_version > SAVE_VERSION:
		return null

	var budget := Budget.new()
	budget.from_dict(result["budget"])
	var ordinances := OrdinanceManager.new()
	ordinances.from_dict(result.get("ordinances", {}))
	var news := NewsFeed.new()
	news.from_dict(result.get("news", {}))

	var sim := CitySimulation.new(CityGrid.from_dict(result["grid"]), budget, ordinances, null, news)
	sim.tick_count = int(result.get("tick_count", 0))
	sim.disasters.enabled = bool(result.get("disasters_enabled", true))
	return sim

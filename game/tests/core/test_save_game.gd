extends GutTest

const TEST_SLOT := "gut_test_slot"

func after_each() -> void:
	var path := "%s/%s.json" % [SaveGame.SAVE_DIR, TEST_SLOT]
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func test_save_and_load_round_trip() -> void:
	var grid := CityGrid.new(2, 2)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.get_tile(0, 0).grow()
	var budget := Budget.new()
	budget.treasury = 1234.0

	var ok := SaveGame.save_slot(TEST_SLOT, grid, budget, 7)
	assert_true(ok)

	var loaded := SaveGame.load_slot(TEST_SLOT)
	assert_false(loaded.is_empty())

	var loaded_grid: CityGrid = loaded["grid"]
	var loaded_budget: Budget = loaded["budget"]
	assert_eq(loaded_grid.get_tile(0, 0).zone, Tile.ZoneType.RESIDENTIAL)
	assert_eq(loaded_grid.get_tile(0, 0).growth_stage, 1)
	assert_almost_eq(loaded_budget.treasury, 1234.0, 0.001)
	assert_eq(loaded["tick_count"], 7)

func test_load_missing_slot_returns_empty_dict() -> void:
	var loaded := SaveGame.load_slot("this_slot_does_not_exist")
	assert_true(loaded.is_empty())

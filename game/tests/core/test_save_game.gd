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
	var ordinances := OrdinanceManager.new()
	ordinances.set_active(OrdinanceManager.Ordinance.RECYCLING_PROGRAM, true)

	var sim := CitySimulation.new(grid, budget, ordinances)
	sim.tick_count = 7
	sim.disasters.enabled = false
	sim.news.add(3, "Evento de teste.")

	assert_true(SaveGame.save_slot(TEST_SLOT, sim))

	var loaded := SaveGame.load_slot(TEST_SLOT)
	assert_not_null(loaded)
	assert_eq(loaded.grid.get_tile(0, 0).zone, Tile.ZoneType.RESIDENTIAL)
	assert_eq(loaded.grid.get_tile(0, 0).growth_stage, 1)
	assert_almost_eq(loaded.budget.treasury, 1234.0, 0.001)
	assert_eq(loaded.tick_count, 7)
	assert_false(loaded.disasters.enabled)
	assert_true(loaded.ordinances.is_active(OrdinanceManager.Ordinance.RECYCLING_PROGRAM))
	assert_eq(loaded.news.entries.size(), 1)
	assert_eq(loaded.news.entries[0]["text"], "Evento de teste.")

func test_load_missing_slot_returns_null() -> void:
	var loaded := SaveGame.load_slot("this_slot_does_not_exist")
	assert_null(loaded)

func test_load_rejects_future_version() -> void:
	DirAccess.make_dir_recursive_absolute(SaveGame.SAVE_DIR)
	var path := "%s/%s.json" % [SaveGame.SAVE_DIR, TEST_SLOT]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SaveGame.SAVE_VERSION + 1}))
	file.close()
	assert_null(SaveGame.load_slot(TEST_SLOT))

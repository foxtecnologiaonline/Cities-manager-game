extends GutTest

func test_disabled_manager_never_triggers() -> void:
	var grid := CityGrid.new(3, 1)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.get_tile(0, 0).growth_stage = 2
	var disasters := DisasterManager.new()
	disasters.enabled = false
	var news := NewsFeed.new()
	for i in range(50): # even with many rolls, disabled means never
		disasters.maybe_trigger_random(grid, news, i)
	assert_eq(news.entries.size(), 0)
	assert_eq(grid.get_tile(0, 0).growth_stage, 2)

func test_tornado_destroys_entire_row() -> void:
	var grid := CityGrid.new(4, 3)
	for x in range(4):
		grid.set_zone(x, 1, Tile.ZoneType.RESIDENTIAL)
		grid.get_tile(x, 1).growth_stage = 2
	var disasters := DisasterManager.new()
	var news := NewsFeed.new()
	disasters.trigger_tornado(grid, news, 5, 1)
	for x in range(4):
		assert_eq(grid.get_tile(x, 1).growth_stage, 0)
	assert_eq(news.entries.size(), 1)

func test_flood_destroys_only_low_elevation_tiles_near_water() -> void:
	var grid := CityGrid.new(5, 1)
	grid.get_tile(4, 0).zone = Tile.ZoneType.WATER

	grid.set_zone(3, 0, Tile.ZoneType.RESIDENTIAL) # low elevation, near water
	grid.get_tile(3, 0).growth_stage = 2

	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL) # far from water
	grid.get_tile(0, 0).growth_stage = 2

	var disasters := DisasterManager.new()
	var news := NewsFeed.new()
	disasters.trigger_flood(grid, news, 1)

	assert_eq(grid.get_tile(3, 0).growth_stage, 0) # destroyed
	assert_eq(grid.get_tile(0, 0).growth_stage, 2) # untouched: too far from water

func test_raised_elevation_protects_from_flood() -> void:
	var grid := CityGrid.new(2, 1)
	grid.get_tile(1, 0).zone = Tile.ZoneType.WATER
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.get_tile(0, 0).growth_stage = 2
	grid.raise_elevation(0, 0, 5)

	var disasters := DisasterManager.new()
	var news := NewsFeed.new()
	disasters.trigger_flood(grid, news, 1)

	assert_eq(grid.get_tile(0, 0).growth_stage, 2) # protected by elevation

func test_fire_with_good_coverage_does_less_damage() -> void:
	var grid := CityGrid.new(1, 1)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.get_tile(0, 0).growth_stage = Tile.MAX_GROWTH_STAGE
	grid.get_tile(0, 0).fire_coverage = 0.8

	var disasters := DisasterManager.new()
	var news := NewsFeed.new()
	disasters.trigger_fire(grid, news, 1)

	assert_eq(grid.get_tile(0, 0).growth_stage, Tile.MAX_GROWTH_STAGE - 1)

func test_earthquake_damages_some_but_not_all_tiles() -> void:
	# Large sample so the "at least one, not all" check below is only
	# astronomically unlikely to fail by chance (0.85^100 ~= 1.4e-7), not a
	# real flake risk.
	var grid := CityGrid.new(100, 1)
	for x in range(100):
		grid.set_zone(x, 0, Tile.ZoneType.RESIDENTIAL)
		grid.get_tile(x, 0).growth_stage = 2

	var disasters := DisasterManager.new()
	var news := NewsFeed.new()
	disasters.trigger_earthquake(grid, news, 1)

	var damaged := 0
	for x in range(100):
		if grid.get_tile(x, 0).growth_stage < 2:
			damaged += 1
	assert_true(damaged > 0 and damaged < 100)

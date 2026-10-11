extends GutTest

func test_industrial_tile_pollutes_itself_and_falls_off_with_distance() -> void:
	var grid := CityGrid.new(10, 1)
	grid.set_zone(0, 0, Tile.ZoneType.INDUSTRIAL)
	grid.get_tile(0, 0).growth_stage = 2 # PollutionCalculator only reads growth_stage directly

	PollutionCalculator.update_all(grid)
	assert_gt(grid.get_tile(0, 0).pollution, 0.0)
	assert_gt(grid.get_tile(0, 0).pollution, grid.get_tile(1, 0).pollution)
	assert_eq(grid.get_tile(9, 0).pollution, 0.0) # out of POLLUTION_RADIUS

func test_unbuilt_industrial_tile_does_not_pollute() -> void:
	var grid := CityGrid.new(3, 1)
	grid.set_zone(0, 0, Tile.ZoneType.INDUSTRIAL) # growth_stage still 0
	PollutionCalculator.update_all(grid)
	assert_eq(grid.get_tile(0, 0).pollution, 0.0)

func test_pollution_is_capped_at_max() -> void:
	var grid := CityGrid.new(1, 1)
	grid.set_zone(0, 0, Tile.ZoneType.INDUSTRIAL)
	grid.get_tile(0, 0).growth_stage = Tile.MAX_GROWTH_STAGE
	PollutionCalculator.update_all(grid)
	assert_true(grid.get_tile(0, 0).pollution <= PollutionCalculator.MAX_POLLUTION)

extends GutTest

func test_police_coverage_falls_off_with_distance() -> void:
	var grid := CityGrid.new(10, 1)
	grid.place_special(0, 0, Tile.SpecialBuilding.POLICE_STATION)
	ServiceCoverage.update_all(grid)
	assert_almost_eq(grid.get_tile(0, 0).police_coverage, 1.0, 0.001)
	assert_gt(grid.get_tile(1, 0).police_coverage, grid.get_tile(2, 0).police_coverage)
	assert_eq(grid.get_tile(9, 0).police_coverage, 0.0) # out of POLICE_RADIUS

func test_coverage_types_are_independent() -> void:
	var grid := CityGrid.new(3, 1)
	grid.place_special(0, 0, Tile.SpecialBuilding.SCHOOL)
	ServiceCoverage.update_all(grid)
	assert_gt(grid.get_tile(0, 0).education_coverage, 0.0)
	assert_eq(grid.get_tile(0, 0).police_coverage, 0.0)
	assert_eq(grid.get_tile(0, 0).fire_coverage, 0.0)
	assert_eq(grid.get_tile(0, 0).health_coverage, 0.0)

func test_no_source_means_zero_coverage() -> void:
	var grid := CityGrid.new(3, 1)
	ServiceCoverage.update_all(grid)
	for tile in grid.get_all_tiles():
		assert_eq(tile.police_coverage, 0.0)

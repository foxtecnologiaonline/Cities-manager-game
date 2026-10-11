extends GutTest

func test_base_value_with_no_modifiers() -> void:
	var grid := CityGrid.new(1, 1)
	LandValueCalculator.update_all(grid)
	assert_almost_eq(grid.get_tile(0, 0).land_value, LandValueCalculator.BASE_VALUE, 0.001)

func test_proximity_to_water_increases_land_value() -> void:
	var grid := CityGrid.new(5, 1)
	grid.get_tile(4, 0).zone = Tile.ZoneType.WATER
	LandValueCalculator.update_all(grid)
	assert_gt(grid.get_tile(3, 0).land_value, grid.get_tile(0, 0).land_value)

func test_pollution_and_crime_reduce_land_value() -> void:
	var grid := CityGrid.new(1, 1)
	grid.get_tile(0, 0).pollution = 5.0
	grid.get_tile(0, 0).crime = 5.0
	LandValueCalculator.update_all(grid)
	assert_lt(grid.get_tile(0, 0).land_value, LandValueCalculator.BASE_VALUE)

func test_land_value_never_goes_negative() -> void:
	var grid := CityGrid.new(1, 1)
	grid.get_tile(0, 0).pollution = PollutionCalculator.MAX_POLLUTION
	grid.get_tile(0, 0).crime = CrimeCalculator.MAX_CRIME
	LandValueCalculator.update_all(grid)
	assert_eq(grid.get_tile(0, 0).land_value, 0.0)

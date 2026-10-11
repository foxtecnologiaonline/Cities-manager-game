extends GutTest

func test_populated_tile_without_police_has_crime() -> void:
	var grid := CityGrid.new(1, 1)
	grid.get_tile(0, 0).population = 100
	CrimeCalculator.update_all(grid)
	assert_gt(grid.get_tile(0, 0).crime, 0.0)

func test_empty_tile_has_no_crime() -> void:
	var grid := CityGrid.new(1, 1)
	CrimeCalculator.update_all(grid)
	assert_eq(grid.get_tile(0, 0).crime, 0.0)

func test_police_coverage_reduces_crime() -> void:
	var grid := CityGrid.new(1, 1)
	grid.get_tile(0, 0).population = 100

	CrimeCalculator.update_all(grid)
	var crime_without_police := grid.get_tile(0, 0).crime

	grid.get_tile(0, 0).police_coverage = 1.0
	CrimeCalculator.update_all(grid)
	var crime_with_police := grid.get_tile(0, 0).crime

	assert_lt(crime_with_police, crime_without_police)
	assert_almost_eq(crime_with_police, 0.0, 0.001)

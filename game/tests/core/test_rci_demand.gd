extends GutTest

func test_demand_reflects_population_and_jobs_balance() -> void:
	var grid := CityGrid.new(3, 1)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.get_tile(0, 0).population = 100
	grid.set_zone(1, 0, Tile.ZoneType.COMMERCIAL)
	grid.get_tile(1, 0).jobs = 10

	var demand := RciDemand.calculate(grid)
	assert_almost_eq(demand.residential, 10.0 - 100.0, 0.001)
	assert_almost_eq(demand.commercial, 100.0 * 0.3 - 10.0, 0.001)
	assert_almost_eq(demand.industrial, 100.0 * 0.4, 0.001)

func test_empty_grid_has_zero_demand() -> void:
	var grid := CityGrid.new(2, 2)
	var demand := RciDemand.calculate(grid)
	assert_eq(demand.residential, 0.0)
	assert_eq(demand.commercial, 0.0)
	assert_eq(demand.industrial, 0.0)

extends GutTest

func test_residential_tile_generates_tax_revenue() -> void:
	var grid := CityGrid.new(1, 1)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.get_tile(0, 0).population = 50
	var budget := Budget.new()
	var starting := budget.treasury

	var solvent := budget.apply_monthly_tick(grid)
	assert_true(solvent)
	assert_gt(budget.treasury, starting)

func test_road_and_special_buildings_cost_upkeep() -> void:
	var grid := CityGrid.new(2, 1)
	grid.set_zone(0, 0, Tile.ZoneType.ROAD)
	grid.place_special(1, 0, Tile.SpecialBuilding.POWER_PLANT)
	var budget := Budget.new()
	var starting := budget.treasury

	budget.apply_monthly_tick(grid)
	assert_lt(budget.treasury, starting)

func test_bankruptcy_returns_false() -> void:
	var grid := CityGrid.new(1, 1)
	var budget := Budget.new()
	budget.treasury = Budget.BANKRUPTCY_THRESHOLD - 1.0
	var solvent := budget.apply_monthly_tick(grid)
	assert_false(solvent)

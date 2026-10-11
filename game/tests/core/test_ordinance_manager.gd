extends GutTest

func test_inactive_by_default() -> void:
	var ordinances := OrdinanceManager.new()
	assert_false(ordinances.is_active(OrdinanceManager.Ordinance.EXTRA_PATROL))
	assert_eq(ordinances.monthly_cost(), 0.0)

func test_monthly_cost_sums_active_ordinances() -> void:
	var ordinances := OrdinanceManager.new()
	ordinances.set_active(OrdinanceManager.Ordinance.EXTRA_PATROL, true)
	ordinances.set_active(OrdinanceManager.Ordinance.RECYCLING_PROGRAM, true)
	var expected: float = (
		OrdinanceManager.MONTHLY_COST[OrdinanceManager.Ordinance.EXTRA_PATROL]
		+ OrdinanceManager.MONTHLY_COST[OrdinanceManager.Ordinance.RECYCLING_PROGRAM]
	)
	assert_almost_eq(ordinances.monthly_cost(), expected, 0.001)

func test_extra_patrol_boosts_police_coverage() -> void:
	var grid := CityGrid.new(1, 1)
	grid.get_tile(0, 0).police_coverage = 0.3
	var ordinances := OrdinanceManager.new()
	ordinances.set_active(OrdinanceManager.Ordinance.EXTRA_PATROL, true)
	ordinances.apply_police_boost(grid)
	assert_almost_eq(grid.get_tile(0, 0).police_coverage, 0.3 + OrdinanceManager.POLICE_BOOST, 0.001)

func test_recycling_program_reduces_pollution() -> void:
	var grid := CityGrid.new(1, 1)
	grid.get_tile(0, 0).pollution = 10.0
	var ordinances := OrdinanceManager.new()
	ordinances.set_active(OrdinanceManager.Ordinance.RECYCLING_PROGRAM, true)
	ordinances.apply_pollution_reduction(grid)
	assert_lt(grid.get_tile(0, 0).pollution, 10.0)

func test_tourism_tax_revenue_scales_with_commercial_jobs() -> void:
	var grid := CityGrid.new(1, 1)
	grid.set_zone(0, 0, Tile.ZoneType.COMMERCIAL)
	grid.get_tile(0, 0).jobs = 40
	var ordinances := OrdinanceManager.new()
	assert_eq(ordinances.tourism_tax_revenue(grid), 0.0) # inactive by default
	ordinances.set_active(OrdinanceManager.Ordinance.TOURISM_TAX, true)
	assert_almost_eq(ordinances.tourism_tax_revenue(grid), 40 * OrdinanceManager.TOURISM_TAX_PER_JOB, 0.001)

func test_save_and_load_round_trip() -> void:
	var ordinances := OrdinanceManager.new()
	ordinances.set_active(OrdinanceManager.Ordinance.FREE_EDUCATION, true)
	var loaded := OrdinanceManager.new()
	loaded.from_dict(ordinances.to_dict())
	assert_true(loaded.is_active(OrdinanceManager.Ordinance.FREE_EDUCATION))
	assert_false(loaded.is_active(OrdinanceManager.Ordinance.EXTRA_PATROL))

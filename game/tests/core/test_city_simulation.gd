extends GutTest

func test_zone_without_road_does_not_grow() -> void:
	var grid := CityGrid.new(2, 1)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.place_special(0, 0, Tile.SpecialBuilding.POWER_PLANT)
	grid.place_special(1, 0, Tile.SpecialBuilding.WATER_PUMP)
	var sim := CitySimulation.new(grid, Budget.new())
	sim.disasters.enabled = false # keep this test about growth, not disaster rolls
	sim.tick()
	assert_eq(grid.get_tile(0, 0).growth_stage, 0)

func test_serviced_zone_next_to_road_grows_when_demand_is_positive() -> void:
	# Layout: [residential][road][power plant][water pump][commercial w/ jobs]
	var grid := CityGrid.new(5, 1)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.set_zone(1, 0, Tile.ZoneType.ROAD)
	grid.place_special(2, 0, Tile.SpecialBuilding.POWER_PLANT)
	grid.place_special(3, 0, Tile.SpecialBuilding.WATER_PUMP)
	grid.set_zone(4, 0, Tile.ZoneType.COMMERCIAL)
	grid.get_tile(4, 0).jobs = 50 # forces residential demand > 0 with zero population

	var sim := CitySimulation.new(grid, Budget.new())
	sim.disasters.enabled = false
	sim.tick()

	assert_true(grid.get_tile(0, 0).is_serviced())
	assert_eq(grid.get_tile(0, 0).growth_stage, 1)

func test_tick_increments_month_counter() -> void:
	var grid := CityGrid.new(1, 1)
	var sim := CitySimulation.new(grid, Budget.new())
	sim.disasters.enabled = false
	sim.tick()
	sim.tick()
	assert_eq(sim.tick_count, 2)

func test_ordinance_cost_and_revenue_affect_treasury() -> void:
	var grid := CityGrid.new(1, 1)
	grid.set_zone(0, 0, Tile.ZoneType.COMMERCIAL)
	grid.get_tile(0, 0).jobs = 1000 # large, so tourism tax clearly outweighs its own upkeep (it has none)

	var ordinances := OrdinanceManager.new()
	ordinances.set_active(OrdinanceManager.Ordinance.TOURISM_TAX, true)
	var budget := Budget.new()
	var sim := CitySimulation.new(grid, budget, ordinances)
	sim.disasters.enabled = false

	var before := budget.treasury
	sim.tick()
	# Tourism tax has no monthly cost, only revenue, so treasury should rise
	# by at least the tax on 1000 jobs even after normal tax/upkeep.
	assert_gt(budget.treasury, before)

func test_milestone_announcement_is_logged_once() -> void:
	var grid := CityGrid.new(1, 1)
	grid.get_tile(0, 0).population = PopulationMilestones.AIRPORT_POPULATION
	var sim := CitySimulation.new(grid, Budget.new())
	sim.disasters.enabled = false

	sim.tick()
	sim.tick()

	var airport_news := 0
	for entry in sim.news.entries:
		if "aeroporto" in entry["text"]:
			airport_news += 1
	assert_eq(airport_news, 1) # announced once, not every tick

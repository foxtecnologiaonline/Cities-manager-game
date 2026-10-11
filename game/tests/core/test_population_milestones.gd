extends GutTest

func test_airport_locked_below_threshold() -> void:
	var grid := CityGrid.new(1, 1)
	grid.get_tile(0, 0).population = PopulationMilestones.AIRPORT_POPULATION - 1
	assert_false(PopulationMilestones.is_airport_unlocked(grid))

func test_airport_unlocked_at_threshold() -> void:
	var grid := CityGrid.new(1, 1)
	grid.get_tile(0, 0).population = PopulationMilestones.AIRPORT_POPULATION
	assert_true(PopulationMilestones.is_airport_unlocked(grid))

func test_seaport_requires_population_and_water_adjacency() -> void:
	var grid := CityGrid.new(2, 1)
	grid.get_tile(0, 0).population = PopulationMilestones.SEAPORT_POPULATION
	assert_false(PopulationMilestones.can_place_seaport(grid, 0, 0)) # no water neighbor yet
	grid.get_tile(1, 0).zone = Tile.ZoneType.WATER
	assert_true(PopulationMilestones.can_place_seaport(grid, 0, 0))

func test_seaport_blocked_below_population_even_near_water() -> void:
	var grid := CityGrid.new(2, 1)
	grid.get_tile(1, 0).zone = Tile.ZoneType.WATER
	assert_false(PopulationMilestones.can_place_seaport(grid, 0, 0))

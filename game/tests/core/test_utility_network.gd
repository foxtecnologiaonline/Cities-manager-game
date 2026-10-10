extends GutTest

func test_power_propagates_across_connected_buildable_tiles() -> void:
	var grid := CityGrid.new(5, 1)
	grid.place_special(0, 0, Tile.SpecialBuilding.POWER_PLANT)
	UtilityNetwork.update_power(grid)
	for x in range(5):
		assert_true(grid.get_tile(x, 0).has_power, "tile %d should have power" % x)

func test_power_does_not_cross_water() -> void:
	var grid := CityGrid.new(5, 1)
	grid.get_tile(2, 0).zone = Tile.ZoneType.WATER
	grid.place_special(0, 0, Tile.SpecialBuilding.POWER_PLANT)
	UtilityNetwork.update_power(grid)
	assert_true(grid.get_tile(1, 0).has_power)
	assert_false(grid.get_tile(3, 0).has_power)
	assert_false(grid.get_tile(4, 0).has_power)

func test_water_supply_is_independent_of_power() -> void:
	var grid := CityGrid.new(3, 1)
	grid.place_special(0, 0, Tile.SpecialBuilding.WATER_PUMP)
	UtilityNetwork.update_water(grid)
	assert_true(grid.get_tile(2, 0).has_water_supply)
	assert_false(grid.get_tile(2, 0).has_power)

func test_update_power_clears_stale_state_from_removed_plants() -> void:
	var grid := CityGrid.new(3, 1)
	grid.place_special(0, 0, Tile.SpecialBuilding.POWER_PLANT)
	UtilityNetwork.update_power(grid)
	grid.bulldoze(0, 0)
	UtilityNetwork.update_power(grid)
	assert_false(grid.get_tile(2, 0).has_power)

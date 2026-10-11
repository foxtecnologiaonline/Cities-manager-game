extends GutTest

func test_road_adjacent_to_dense_zone_has_high_traffic() -> void:
	var grid := CityGrid.new(2, 1)
	grid.set_zone(0, 0, Tile.ZoneType.ROAD)
	grid.set_zone(1, 0, Tile.ZoneType.RESIDENTIAL)
	grid.get_tile(1, 0).population = TrafficEstimator.CAPACITY_PER_TILE * 2.0

	TrafficEstimator.update_all(grid)
	assert_almost_eq(grid.get_tile(0, 0).traffic, 1.0, 0.001) # clamped at capacity

func test_non_transit_tile_has_no_traffic_value() -> void:
	var grid := CityGrid.new(1, 1)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.get_tile(0, 0).population = 500
	TrafficEstimator.update_all(grid)
	assert_eq(grid.get_tile(0, 0).traffic, 0.0)

func test_highway_rail_subway_all_count_as_transit() -> void:
	var grid := CityGrid.new(2, 1)
	grid.get_tile(1, 0).zone = Tile.ZoneType.COMMERCIAL
	grid.get_tile(1, 0).jobs = 50
	for zone in [Tile.ZoneType.HIGHWAY, Tile.ZoneType.RAIL, Tile.ZoneType.SUBWAY]:
		grid.get_tile(0, 0).zone = zone
		TrafficEstimator.update_all(grid)
		assert_gt(grid.get_tile(0, 0).traffic, 0.0, "zone %d should register traffic" % zone)

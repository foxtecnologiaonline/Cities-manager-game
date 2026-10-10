extends GutTest
## Requires the GUT addon (installed via the editor's AssetLib, or as a git
## submodule at game/addons/gut). Run with:
##   godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs
## Not yet executed by Claude in this session — no Godot binary is available
## in this cloud container. Run locally (or wire into CI) to verify.

func test_new_grid_has_correct_dimensions() -> void:
	var grid := CityGrid.new(10, 5)
	assert_eq(grid.width, 10)
	assert_eq(grid.height, 5)

func test_out_of_bounds_tile_is_null() -> void:
	var grid := CityGrid.new(4, 4)
	assert_null(grid.get_tile(-1, 0))
	assert_null(grid.get_tile(4, 0))

func test_set_zone_on_valid_tile() -> void:
	var grid := CityGrid.new(4, 4)
	var ok := grid.set_zone(1, 1, Tile.ZoneType.RESIDENTIAL)
	assert_true(ok)
	assert_eq(grid.get_tile(1, 1).zone, Tile.ZoneType.RESIDENTIAL)

func test_set_zone_on_water_fails() -> void:
	var grid := CityGrid.new(4, 4)
	grid.get_tile(2, 2).zone = Tile.ZoneType.WATER
	var ok := grid.set_zone(2, 2, Tile.ZoneType.COMMERCIAL)
	assert_false(ok)

func test_rezoning_resets_growth() -> void:
	var grid := CityGrid.new(2, 2)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.get_tile(0, 0).grow()
	grid.set_zone(0, 0, Tile.ZoneType.COMMERCIAL)
	assert_eq(grid.get_tile(0, 0).growth_stage, 0)

func test_bulldoze_clears_zone_and_special() -> void:
	var grid := CityGrid.new(2, 2)
	grid.place_special(0, 0, Tile.SpecialBuilding.POWER_PLANT)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	var ok := grid.bulldoze(0, 0)
	assert_true(ok)
	assert_eq(grid.get_tile(0, 0).zone, Tile.ZoneType.NONE)
	assert_eq(grid.get_tile(0, 0).special, Tile.SpecialBuilding.NONE)

func test_bulldoze_cannot_remove_water() -> void:
	var grid := CityGrid.new(2, 2)
	grid.get_tile(0, 0).zone = Tile.ZoneType.WATER
	assert_false(grid.bulldoze(0, 0))

func test_get_neighbors_count_for_corner() -> void:
	var grid := CityGrid.new(4, 4)
	var neighbors := grid.get_neighbors(0, 0)
	assert_eq(neighbors.size(), 2)

func test_get_neighbors_count_for_center() -> void:
	var grid := CityGrid.new(4, 4)
	var neighbors := grid.get_neighbors(2, 2)
	assert_eq(neighbors.size(), 4)

func test_has_road_neighbor() -> void:
	var grid := CityGrid.new(5, 1)
	grid.set_zone(2, 0, Tile.ZoneType.ROAD)
	assert_true(grid.has_road_neighbor(1, 0))
	assert_true(grid.has_road_neighbor(3, 0))
	assert_false(grid.has_road_neighbor(0, 0))

func test_count_zoned() -> void:
	var grid := CityGrid.new(3, 3)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.set_zone(1, 1, Tile.ZoneType.RESIDENTIAL)
	assert_eq(grid.count_zoned(Tile.ZoneType.RESIDENTIAL), 2)

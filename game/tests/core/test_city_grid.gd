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

func test_get_neighbors_count_for_corner() -> void:
	var grid := CityGrid.new(4, 4)
	var neighbors := grid.get_neighbors(0, 0)
	assert_eq(neighbors.size(), 2)

func test_get_neighbors_count_for_center() -> void:
	var grid := CityGrid.new(4, 4)
	var neighbors := grid.get_neighbors(2, 2)
	assert_eq(neighbors.size(), 4)

func test_count_zoned() -> void:
	var grid := CityGrid.new(3, 3)
	grid.set_zone(0, 0, Tile.ZoneType.RESIDENTIAL)
	grid.set_zone(1, 1, Tile.ZoneType.RESIDENTIAL)
	assert_eq(grid.count_zoned(Tile.ZoneType.RESIDENTIAL), 2)

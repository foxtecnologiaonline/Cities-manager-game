extends GutTest

func test_residential_growth_increases_population() -> void:
	var tile := Tile.new(0, 0)
	tile.zone = Tile.ZoneType.RESIDENTIAL
	tile.grow()
	assert_eq(tile.growth_stage, 1)
	assert_eq(tile.population, Tile.POP_PER_RESIDENTIAL_STAGE)

func test_growth_capped_at_max_stage() -> void:
	var tile := Tile.new(0, 0)
	tile.zone = Tile.ZoneType.COMMERCIAL
	for i in range(Tile.MAX_GROWTH_STAGE + 2):
		tile.grow()
	assert_eq(tile.growth_stage, Tile.MAX_GROWTH_STAGE)

func test_shrink_floors_at_zero() -> void:
	var tile := Tile.new(0, 0)
	tile.zone = Tile.ZoneType.INDUSTRIAL
	tile.shrink()
	assert_eq(tile.growth_stage, 0)
	tile.grow()
	tile.shrink()
	assert_eq(tile.growth_stage, 0)
	assert_eq(tile.jobs, 0)

func test_reset_growth_clears_population_and_jobs() -> void:
	var tile := Tile.new(0, 0)
	tile.zone = Tile.ZoneType.RESIDENTIAL
	tile.grow()
	tile.reset_growth()
	assert_eq(tile.growth_stage, 0)
	assert_eq(tile.population, 0)

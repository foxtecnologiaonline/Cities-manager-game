class_name PopulationMilestones
extends RefCounted
## Original thresholds (not copied from any specific game). Total city
## population is the sum of every tile's `population` field. Gating lives
## here rather than in CityGrid.place_special, which stays a dumb/generic
## "put a building here" call with only physical constraints (bounds,
## water) — these are game-rule constraints, checked by the caller.

const AIRPORT_POPULATION := 5000
const SEAPORT_POPULATION := 3000

static func total_population(grid: CityGrid) -> int:
	var total := 0
	for tile in grid.get_all_tiles():
		total += tile.population
	return total

static func is_airport_unlocked(grid: CityGrid) -> bool:
	return total_population(grid) >= AIRPORT_POPULATION

static func is_seaport_unlocked(grid: CityGrid) -> bool:
	return total_population(grid) >= SEAPORT_POPULATION

static func can_place_airport(grid: CityGrid, x: int, y: int) -> bool:
	return is_airport_unlocked(grid)

## Seaports also need to sit next to water, same as real ports.
static func can_place_seaport(grid: CityGrid, x: int, y: int) -> bool:
	if not is_seaport_unlocked(grid):
		return false
	for tile in grid.get_neighbors(x, y):
		if tile.zone == Tile.ZoneType.WATER:
			return true
	return false

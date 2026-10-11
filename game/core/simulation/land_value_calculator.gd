class_name LandValueCalculator
extends RefCounted
## Original formula (not copied from any specific game's numbers): rewards
## proximity to water, policing and healthcare; penalizes pollution and
## crime. Must run after ServiceCoverage, PollutionCalculator and
## CrimeCalculator in the same tick.

const WATER_PROXIMITY_RADIUS := 4.0
const WATER_BONUS := 40.0
const POLICE_BONUS := 20.0
const HEALTH_BONUS := 15.0
const POLLUTION_PENALTY := 1.5
const CRIME_PENALTY := 1.0
const BASE_VALUE := 10.0

static func update_all(grid: CityGrid) -> void:
	var water_tiles: Array[Tile] = []
	for tile in grid.get_all_tiles():
		if tile.zone == Tile.ZoneType.WATER:
			water_tiles.append(tile)

	for tile in grid.get_all_tiles():
		var value := BASE_VALUE
		value += _water_proximity_bonus(tile, water_tiles)
		value += tile.police_coverage * POLICE_BONUS
		value += tile.health_coverage * HEALTH_BONUS
		value -= tile.pollution * POLLUTION_PENALTY
		value -= tile.crime * CRIME_PENALTY
		tile.land_value = max(0.0, value)

static func _water_proximity_bonus(tile: Tile, water_tiles: Array[Tile]) -> float:
	var best := 0.0
	for water in water_tiles:
		var dist: float = Vector2(tile.x - water.x, tile.y - water.y).length()
		if dist <= WATER_PROXIMITY_RADIUS:
			var strength: float = 1.0 - dist / WATER_PROXIMITY_RADIUS
			if strength > best:
				best = strength
	return best * WATER_BONUS

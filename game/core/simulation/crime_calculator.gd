class_name CrimeCalculator
extends RefCounted
## Original formula: crime risk grows with how crowded and polluted a tile
## is, and is suppressed by police coverage. Must run after
## PollutionCalculator and ServiceCoverage in the same tick.

const BASE_CRIME_PER_CAPITA := 0.02
const POLLUTION_CRIME_FACTOR := 0.3
const MAX_CRIME := 10.0

static func update_all(grid: CityGrid) -> void:
	for tile in grid.get_all_tiles():
		if tile.population <= 0:
			tile.crime = 0.0
			continue
		var risk: float = tile.population * BASE_CRIME_PER_CAPITA
		risk += tile.pollution * POLLUTION_CRIME_FACTOR
		risk *= 1.0 - tile.police_coverage
		tile.crime = clamp(risk, 0.0, MAX_CRIME)

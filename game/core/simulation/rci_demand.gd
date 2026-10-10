class_name RciDemand
extends RefCounted
## Toy demand formula for Fase 1 — tunable constants, not a replica of any
## specific game's numbers. Positive demand for a zone type means it should
## grow next tick; negative means it should shrink.

var residential: float = 0.0
var commercial: float = 0.0
var industrial: float = 0.0

static func calculate(grid: CityGrid) -> RciDemand:
	var population := 0
	var commercial_jobs := 0
	var industrial_jobs := 0
	for tile in grid.get_all_tiles():
		population += tile.population
		if tile.zone == Tile.ZoneType.COMMERCIAL:
			commercial_jobs += tile.jobs
		elif tile.zone == Tile.ZoneType.INDUSTRIAL:
			industrial_jobs += tile.jobs

	var demand := RciDemand.new()
	# Residents want jobs; jobs want residents nearby to hire and to shop.
	demand.residential = float(commercial_jobs + industrial_jobs) - float(population)
	demand.commercial = float(population) * 0.3 - float(commercial_jobs)
	demand.industrial = float(population) * 0.4 - float(industrial_jobs)
	return demand

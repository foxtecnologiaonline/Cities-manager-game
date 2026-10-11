class_name PollutionCalculator
extends RefCounted
## Original formula (not copied from any specific game): industrial tiles
## emit pollution that falls off with distance; contributions from
## multiple polluters stack (capped), since standing next to three
## factories should feel worse than standing next to one.

const INDUSTRIAL_POLLUTION_PER_STAGE := 0.5
const POLLUTION_RADIUS := 5.0
const MAX_POLLUTION := 10.0

static func update_all(grid: CityGrid) -> void:
	var sources: Array[Tile] = []
	for tile in grid.get_all_tiles():
		if tile.zone == Tile.ZoneType.INDUSTRIAL and tile.growth_stage > 0:
			sources.append(tile)

	for tile in grid.get_all_tiles():
		if sources.is_empty():
			tile.pollution = 0.0
			continue
		var total := 0.0
		for source in sources:
			var dist: float = Vector2(tile.x - source.x, tile.y - source.y).length()
			if dist <= POLLUTION_RADIUS:
				var emitted: float = source.growth_stage * INDUSTRIAL_POLLUTION_PER_STAGE
				total += emitted * (1.0 - dist / POLLUTION_RADIUS)
		tile.pollution = min(total, MAX_POLLUTION)

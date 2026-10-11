class_name ServiceCoverage
extends RefCounted
## Fase 2: each civic service building projects a circular "effect radius"
## (the genre-standard mechanic for coverage, reimplemented with our own
## numbers) rather than needing a connected network like power/water.
## Where radii from multiple buildings of the same type overlap, a tile
## gets the strongest (closest) one.

const POLICE_RADIUS := 6.0
const FIRE_RADIUS := 6.0
const HEALTH_RADIUS := 8.0
const EDUCATION_RADIUS := 8.0

static func update_all(grid: CityGrid) -> void:
	_update_for(grid, Tile.SpecialBuilding.POLICE_STATION, POLICE_RADIUS, "police_coverage")
	_update_for(grid, Tile.SpecialBuilding.FIRE_STATION, FIRE_RADIUS, "fire_coverage")
	_update_for(grid, Tile.SpecialBuilding.HOSPITAL, HEALTH_RADIUS, "health_coverage")
	_update_for(grid, Tile.SpecialBuilding.SCHOOL, EDUCATION_RADIUS, "education_coverage")

static func _update_for(grid: CityGrid, special: int, radius: float, field: String) -> void:
	for tile in grid.get_all_tiles():
		tile.set(field, 0.0)

	var sources: Array[Tile] = []
	for tile in grid.get_all_tiles():
		if tile.special == special:
			sources.append(tile)
	if sources.is_empty():
		return

	for tile in grid.get_all_tiles():
		var best := 0.0
		for source in sources:
			var dist: float = Vector2(tile.x - source.x, tile.y - source.y).length()
			if dist <= radius:
				var strength: float = 1.0 - dist / radius
				if strength > best:
					best = strength
		tile.set(field, best)

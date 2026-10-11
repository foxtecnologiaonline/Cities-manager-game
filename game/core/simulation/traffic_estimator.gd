class_name TrafficEstimator
extends RefCounted
## Fase 2 placeholder, not a real traffic simulation: real pathfinding and
## route distribution across the network is a bigger feature, deferred.
## This estimates load on each transit tile as the combined
## population+jobs of its directly adjacent R/C/I neighbors — consistent
## with the "must be adjacent to transit" growth rule the rest of Fase 1/2
## uses, but it says nothing about congestion further down the network.

const CAPACITY_PER_TILE := 100.0

static func update_all(grid: CityGrid) -> void:
	for tile in grid.get_all_tiles():
		if not CityGrid.is_transit_zone(tile.zone):
			tile.traffic = 0.0
			continue
		var load := 0.0
		for neighbor in grid.get_neighbors(tile.x, tile.y):
			if neighbor.is_occupied_zone():
				load += neighbor.population + neighbor.jobs
		tile.traffic = clamp(load / CAPACITY_PER_TILE, 0.0, 1.0)

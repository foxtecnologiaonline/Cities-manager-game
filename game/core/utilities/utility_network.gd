class_name UtilityNetwork
extends RefCounted
## Fase 1 simplification: power/water propagate by flood-fill across any
## connected buildable (non-water) tiles reachable from a plant/pump — no
## power lines or pipes yet. Those arrive with the Fase 2 infrastructure
## pass, once the transport network itself exists.

static func update_power(grid: CityGrid) -> void:
	_propagate(grid, Tile.SpecialBuilding.POWER_PLANT, true)

static func update_water(grid: CityGrid) -> void:
	_propagate(grid, Tile.SpecialBuilding.WATER_PUMP, false)

static func _propagate(grid: CityGrid, source_special: int, is_power: bool) -> void:
	for tile in grid.get_all_tiles():
		if is_power:
			tile.has_power = false
		else:
			tile.has_water_supply = false

	var queue: Array[Tile] = []
	for tile in grid.get_all_tiles():
		if tile.special == source_special:
			if is_power:
				tile.has_power = true
			else:
				tile.has_water_supply = true
			queue.append(tile)

	var head := 0
	while head < queue.size():
		var current: Tile = queue[head]
		head += 1
		for neighbor in grid.get_neighbors(current.x, current.y):
			if not neighbor.is_buildable():
				continue
			var already_served: bool = neighbor.has_power if is_power else neighbor.has_water_supply
			if already_served:
				continue
			if is_power:
				neighbor.has_power = true
			else:
				neighbor.has_water_supply = true
			queue.append(neighbor)

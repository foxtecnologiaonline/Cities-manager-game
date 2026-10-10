class_name CitySimulation
extends RefCounted
## Ties the Fase 1 systems together: utilities, RCI growth and the budget,
## advanced one simulated month at a time.

var grid: CityGrid
var budget: Budget
var tick_count: int = 0
var last_demand: RciDemand

func _init(p_grid: CityGrid, p_budget: Budget) -> void:
	grid = p_grid
	budget = p_budget

## Advances one simulated month. Returns false if the city just went
## bankrupt (budget crossed the game-over threshold), true otherwise.
func tick() -> bool:
	tick_count += 1
	UtilityNetwork.update_power(grid)
	UtilityNetwork.update_water(grid)
	last_demand = RciDemand.calculate(grid)
	_grow_zones(last_demand)
	return budget.apply_monthly_tick(grid)

## Only tiles that are zoned R/C/I, powered+watered, and touching a road
## grow or shrink — Fase 1's stand-in for a real transport/utility network.
func _grow_zones(demand: RciDemand) -> void:
	for tile in grid.get_all_tiles():
		if not tile.is_occupied_zone():
			continue
		if not tile.is_serviced():
			continue
		if not grid.has_road_neighbor(tile.x, tile.y):
			continue
		var zone_demand := _demand_for_zone(demand, tile.zone)
		if zone_demand > 0.0:
			tile.grow()
		elif zone_demand < 0.0:
			tile.shrink()

func _demand_for_zone(demand: RciDemand, zone: int) -> float:
	match zone:
		Tile.ZoneType.RESIDENTIAL:
			return demand.residential
		Tile.ZoneType.COMMERCIAL:
			return demand.commercial
		Tile.ZoneType.INDUSTRIAL:
			return demand.industrial
		_:
			return 0.0

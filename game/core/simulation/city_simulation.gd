class_name CitySimulation
extends RefCounted
## Ties the Fase 1 + Fase 2 systems together, advancing one simulated
## month at a time: utilities -> service coverage -> pollution -> crime
## -> land value -> RCI demand/growth -> budget. The order matters: each
## stage reads fields the previous stage just wrote.

## Below this land value, a zone is considered too undesirable to grow and
## will shrink even if raw RCI demand is positive — this is what makes
## pollution/crime (via land value) actually suppress growth instead of
## only showing up on an overlay.
const MIN_DESIRABLE_LAND_VALUE := 5.0

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
	ServiceCoverage.update_all(grid)
	PollutionCalculator.update_all(grid)
	CrimeCalculator.update_all(grid)
	LandValueCalculator.update_all(grid)
	TrafficEstimator.update_all(grid)
	last_demand = RciDemand.calculate(grid)
	_grow_zones(last_demand)
	return budget.apply_monthly_tick(grid)

## Only tiles that are zoned R/C/I, powered+watered, touching transit and
## desirable enough (land value) grow; anything short of that shrinks.
func _grow_zones(demand: RciDemand) -> void:
	for tile in grid.get_all_tiles():
		if not tile.is_occupied_zone():
			continue
		if not tile.is_serviced():
			continue
		if not grid.has_transit_access(tile.x, tile.y):
			continue
		var zone_demand := _demand_for_zone(demand, tile.zone)
		var desirable := tile.land_value > MIN_DESIRABLE_LAND_VALUE
		if zone_demand > 0.0 and desirable:
			tile.grow()
		elif zone_demand < 0.0 or not desirable:
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

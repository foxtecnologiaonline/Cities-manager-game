class_name CitySimulation
extends RefCounted
## Ties the Fase 1 + 2 + 3 systems together, advancing one simulated month
## at a time: utilities -> service coverage -> ordinance modifiers ->
## pollution -> crime -> land value -> traffic -> disasters -> milestone
## announcements -> RCI demand/growth -> budget. The order matters: each
## stage reads fields an earlier stage just wrote.

## Below this land value, a zone is considered too undesirable to grow and
## will shrink even if raw RCI demand is positive — this is what makes
## pollution/crime (via land value) actually suppress growth instead of
## only showing up on an overlay.
const MIN_DESIRABLE_LAND_VALUE := 5.0

var grid: CityGrid
var budget: Budget
var ordinances: OrdinanceManager
var disasters: DisasterManager
var news: NewsFeed
var tick_count: int = 0
var last_demand: RciDemand

var _airport_announced := false
var _seaport_announced := false

func _init(
	p_grid: CityGrid,
	p_budget: Budget,
	p_ordinances: OrdinanceManager = null,
	p_disasters: DisasterManager = null,
	p_news: NewsFeed = null
) -> void:
	grid = p_grid
	budget = p_budget
	ordinances = p_ordinances if p_ordinances != null else OrdinanceManager.new()
	disasters = p_disasters if p_disasters != null else DisasterManager.new()
	news = p_news if p_news != null else NewsFeed.new()

## Advances one simulated month. Returns false if the city just went
## bankrupt (budget crossed the game-over threshold), true otherwise.
func tick() -> bool:
	tick_count += 1
	UtilityNetwork.update_power(grid)
	UtilityNetwork.update_water(grid)
	ServiceCoverage.update_all(grid)
	ordinances.apply_police_boost(grid)
	ordinances.apply_education_boost(grid)
	PollutionCalculator.update_all(grid)
	ordinances.apply_pollution_reduction(grid)
	CrimeCalculator.update_all(grid)
	LandValueCalculator.update_all(grid)
	TrafficEstimator.update_all(grid)
	disasters.maybe_trigger_random(grid, news, tick_count)
	_announce_milestones()
	last_demand = RciDemand.calculate(grid)
	_grow_zones(last_demand)
	var solvent := budget.apply_monthly_tick(grid)
	budget.treasury += ordinances.tourism_tax_revenue(grid) - ordinances.monthly_cost()
	return solvent and budget.treasury > Budget.BANKRUPTCY_THRESHOLD

func _announce_milestones() -> void:
	if not _airport_announced and PopulationMilestones.is_airport_unlocked(grid):
		_airport_announced = true
		news.add(tick_count, "Marco populacional atingido: aeroporto liberado para construcao.")
	if not _seaport_announced and PopulationMilestones.is_seaport_unlocked(grid):
		_seaport_announced = true
		news.add(tick_count, "Marco populacional atingido: porto liberado para construcao.")

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

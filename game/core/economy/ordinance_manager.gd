class_name OrdinanceManager
extends RefCounted
## Toggleable city-wide policies. Costs and effect sizes are original,
## tunable placeholder numbers — not copied from any specific game.

enum Ordinance {
	EXTRA_PATROL,
	RECYCLING_PROGRAM,
	TOURISM_TAX,
	FREE_EDUCATION,
}

const ORDINANCE_NAMES := ["Patrulha Extra", "Reciclagem", "Imposto Turistico", "Educacao Gratuita"]

const MONTHLY_COST := {
	Ordinance.EXTRA_PATROL: 80.0,
	Ordinance.RECYCLING_PROGRAM: 120.0,
	Ordinance.TOURISM_TAX: 0.0,
	Ordinance.FREE_EDUCATION: 100.0,
}

const POLICE_BOOST := 0.2
const EDUCATION_COVERAGE_BOOST := 0.2
const POLLUTION_REDUCTION_FACTOR := 0.3
const TOURISM_TAX_PER_JOB := 0.5

var active: Dictionary = {} ## Ordinance (int) -> bool

func is_active(ordinance: int) -> bool:
	return active.get(ordinance, false)

func set_active(ordinance: int, value: bool) -> void:
	active[ordinance] = value

func monthly_cost() -> float:
	var total := 0.0
	for ordinance in active:
		if active[ordinance]:
			total += MONTHLY_COST.get(ordinance, 0.0)
	return total

## Run after ServiceCoverage, before CrimeCalculator/LandValueCalculator.
func apply_police_boost(grid: CityGrid) -> void:
	if not is_active(Ordinance.EXTRA_PATROL):
		return
	for tile in grid.get_all_tiles():
		tile.police_coverage = min(1.0, tile.police_coverage + POLICE_BOOST)

## Run after ServiceCoverage, before CrimeCalculator.
func apply_education_boost(grid: CityGrid) -> void:
	if not is_active(Ordinance.FREE_EDUCATION):
		return
	for tile in grid.get_all_tiles():
		tile.education_coverage = min(1.0, tile.education_coverage + EDUCATION_COVERAGE_BOOST)

## Run after PollutionCalculator, before CrimeCalculator/LandValueCalculator.
func apply_pollution_reduction(grid: CityGrid) -> void:
	if not is_active(Ordinance.RECYCLING_PROGRAM):
		return
	for tile in grid.get_all_tiles():
		tile.pollution *= 1.0 - POLLUTION_REDUCTION_FACTOR

func tourism_tax_revenue(grid: CityGrid) -> float:
	if not is_active(Ordinance.TOURISM_TAX):
		return 0.0
	var commercial_jobs := 0
	for tile in grid.get_all_tiles():
		if tile.zone == Tile.ZoneType.COMMERCIAL:
			commercial_jobs += tile.jobs
	return commercial_jobs * TOURISM_TAX_PER_JOB

## Dictionary keys must be strings to round-trip through JSON.
func to_dict() -> Dictionary:
	var data := {}
	for ordinance in active:
		data[str(ordinance)] = active[ordinance]
	return data

func from_dict(data: Dictionary) -> void:
	active.clear()
	for key in data:
		active[int(key)] = bool(data[key])

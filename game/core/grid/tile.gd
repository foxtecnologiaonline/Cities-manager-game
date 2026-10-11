class_name Tile
extends RefCounted
## Single cell of the city grid. Engine-light on purpose: no Node/scene-tree
## dependency, so this logic is unit-testable and portable.

## Append-only: existing save files store these as raw ints, so inserting
## a value in the middle (instead of at the end) would silently corrupt
## every save made before the change.
enum ZoneType {
	NONE,
	RESIDENTIAL,
	COMMERCIAL,
	INDUSTRIAL,
	ROAD,
	WATER,
	HIGHWAY,
	RAIL,
	SUBWAY,
}

## Append-only, same reason as ZoneType.
enum SpecialBuilding {
	NONE,
	POWER_PLANT,
	WATER_PUMP,
	POLICE_STATION,
	FIRE_STATION,
	HOSPITAL,
	SCHOOL,
}

const MAX_GROWTH_STAGE := 4
const POP_PER_RESIDENTIAL_STAGE := 20
const JOBS_PER_COMMERCIAL_STAGE := 15
const JOBS_PER_INDUSTRIAL_STAGE := 25

var x: int
var y: int
var zone: int = ZoneType.NONE
var special: int = SpecialBuilding.NONE
var elevation: int = 0
var has_power: bool = false
var has_water_supply: bool = false
var land_value: float = 0.0
var pollution: float = 0.0
var crime: float = 0.0
var traffic: float = 0.0
var police_coverage: float = 0.0
var fire_coverage: float = 0.0
var health_coverage: float = 0.0
var education_coverage: float = 0.0
var growth_stage: int = 0
var population: int = 0
var jobs: int = 0

func _init(p_x: int = 0, p_y: int = 0) -> void:
	x = p_x
	y = p_y

## Water tiles (and other non-zonable terrain added later) can't be zoned
## or have special buildings placed on them.
func is_buildable() -> bool:
	return zone != ZoneType.WATER

func is_serviced() -> bool:
	return has_power and has_water_supply

func is_occupied_zone() -> bool:
	return zone == ZoneType.RESIDENTIAL or zone == ZoneType.COMMERCIAL or zone == ZoneType.INDUSTRIAL

## Grows this tile by one stage, recalculating population/jobs from the new
## stage. Returns false if already at MAX_GROWTH_STAGE.
func grow() -> bool:
	if growth_stage >= MAX_GROWTH_STAGE:
		return false
	growth_stage += 1
	_recalculate_capacity()
	return true

## Shrinks by one stage (e.g. when demand for this zone type goes negative).
## No-op at stage 0.
func shrink() -> void:
	if growth_stage <= 0:
		return
	growth_stage -= 1
	_recalculate_capacity()

## Clears growth/population/jobs — used when re-zoning or bulldozing a tile.
func reset_growth() -> void:
	growth_stage = 0
	population = 0
	jobs = 0

func _recalculate_capacity() -> void:
	match zone:
		ZoneType.RESIDENTIAL:
			population = growth_stage * POP_PER_RESIDENTIAL_STAGE
			jobs = 0
		ZoneType.COMMERCIAL:
			jobs = growth_stage * JOBS_PER_COMMERCIAL_STAGE
			population = 0
		ZoneType.INDUSTRIAL:
			jobs = growth_stage * JOBS_PER_INDUSTRIAL_STAGE
			population = 0
		_:
			population = 0
			jobs = 0

func to_dict() -> Dictionary:
	return {
		"zone": zone,
		"special": special,
		"elevation": elevation,
		"has_power": has_power,
		"has_water_supply": has_water_supply,
		"land_value": land_value,
		"pollution": pollution,
		"crime": crime,
		"traffic": traffic,
		"police_coverage": police_coverage,
		"fire_coverage": fire_coverage,
		"health_coverage": health_coverage,
		"education_coverage": education_coverage,
		"growth_stage": growth_stage,
		"population": population,
		"jobs": jobs,
	}

## JSON round-trips every number as float, so ints are cast back explicitly
## to satisfy GDScript's static typing on assignment. Fields missing from
## an older save (anything added after that save was written) fall back to
## their defaults via .get(), so old saves keep loading.
func from_dict(data: Dictionary) -> void:
	zone = int(data.get("zone", ZoneType.NONE))
	special = int(data.get("special", SpecialBuilding.NONE))
	elevation = int(data.get("elevation", 0))
	has_power = bool(data.get("has_power", false))
	has_water_supply = bool(data.get("has_water_supply", false))
	land_value = float(data.get("land_value", 0.0))
	pollution = float(data.get("pollution", 0.0))
	crime = float(data.get("crime", 0.0))
	traffic = float(data.get("traffic", 0.0))
	police_coverage = float(data.get("police_coverage", 0.0))
	fire_coverage = float(data.get("fire_coverage", 0.0))
	health_coverage = float(data.get("health_coverage", 0.0))
	education_coverage = float(data.get("education_coverage", 0.0))
	growth_stage = int(data.get("growth_stage", 0))
	population = int(data.get("population", 0))
	jobs = int(data.get("jobs", 0))

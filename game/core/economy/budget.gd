class_name Budget
extends RefCounted
## Monthly treasury: tax revenue from occupied zones minus maintenance for
## roads and special buildings. Numbers are placeholder tuning knobs, not a
## replica of any specific game's balance.

const RESIDENTIAL_TAX_PER_CAPITA := 2.0
const COMMERCIAL_TAX_PER_JOB := 3.0
const INDUSTRIAL_TAX_PER_JOB := 2.5
const ROAD_MAINTENANCE_PER_TILE := 1.0
const SPECIAL_BUILDING_MAINTENANCE := 50.0
const BANKRUPTCY_THRESHOLD := -5000.0

var treasury: float = 10000.0
var tax_rate: float = 1.0 ## global multiplier; per-zone rates come in a later pass

## Returns false once the treasury has crossed BANKRUPTCY_THRESHOLD — the
## caller treats that as game over.
func apply_monthly_tick(grid: CityGrid) -> bool:
	var revenue := 0.0
	var expenses := 0.0
	for tile in grid.get_all_tiles():
		match tile.zone:
			Tile.ZoneType.RESIDENTIAL:
				revenue += tile.population * RESIDENTIAL_TAX_PER_CAPITA * tax_rate
			Tile.ZoneType.COMMERCIAL:
				revenue += tile.jobs * COMMERCIAL_TAX_PER_JOB * tax_rate
			Tile.ZoneType.INDUSTRIAL:
				revenue += tile.jobs * INDUSTRIAL_TAX_PER_JOB * tax_rate
			Tile.ZoneType.ROAD:
				expenses += ROAD_MAINTENANCE_PER_TILE
		if tile.special != Tile.SpecialBuilding.NONE:
			expenses += SPECIAL_BUILDING_MAINTENANCE

	treasury += revenue - expenses
	return treasury > BANKRUPTCY_THRESHOLD

func to_dict() -> Dictionary:
	return {"treasury": treasury, "tax_rate": tax_rate}

func from_dict(data: Dictionary) -> void:
	treasury = float(data.get("treasury", 10000.0))
	tax_rate = float(data.get("tax_rate", 1.0))

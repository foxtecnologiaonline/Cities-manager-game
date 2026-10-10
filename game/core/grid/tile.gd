class_name Tile
extends RefCounted
## Single cell of the city grid. Engine-light on purpose: no Node/scene-tree
## dependency, so this logic is unit-testable and portable.

enum ZoneType {
	NONE,
	RESIDENTIAL,
	COMMERCIAL,
	INDUSTRIAL,
	ROAD,
	WATER,
}

var x: int
var y: int
var zone: int = ZoneType.NONE
var elevation: int = 0
var has_power: bool = false
var has_water_supply: bool = false
var land_value: float = 0.0
var pollution: float = 0.0
var growth_stage: int = 0

func _init(p_x: int, p_y: int) -> void:
	x = p_x
	y = p_y

## Water tiles (and other non-zonable terrain added later) can't be zoned.
func is_buildable() -> bool:
	return zone != ZoneType.WATER

func is_serviced() -> bool:
	return has_power and has_water_supply

class_name CityGrid
extends RefCounted
## Flat grid of Tile instances. Pure data/logic, no rendering — the Main
## scene reads this to draw, and simulation systems (economy, utilities,
## traffic) mutate it on each tick.

var width: int
var height: int
var _tiles: Array[Tile] = []

func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	_tiles.resize(width * height)
	for y in range(height):
		for x in range(width):
			_tiles[_index(x, y)] = Tile.new(x, y)

func _index(x: int, y: int) -> int:
	return y * width + x

func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func get_tile(x: int, y: int) -> Tile:
	if not is_in_bounds(x, y):
		return null
	return _tiles[_index(x, y)]

func get_all_tiles() -> Array[Tile]:
	return _tiles

## Returns false (and leaves the tile unchanged) for out-of-bounds or
## non-buildable tiles (e.g. water). Re-zoning away from the previous use
## resets any accumulated growth/population/jobs.
func set_zone(x: int, y: int, zone: int) -> bool:
	var tile := get_tile(x, y)
	if tile == null or not tile.is_buildable():
		return false
	if tile.zone != zone:
		tile.reset_growth()
	tile.zone = zone
	return true

## Clears zoning and any special building on a tile. Water tiles are
## permanent terrain in Fase 1 (no terraforming yet) and can't be bulldozed.
func bulldoze(x: int, y: int) -> bool:
	var tile := get_tile(x, y)
	if tile == null or tile.zone == Tile.ZoneType.WATER:
		return false
	tile.reset_growth()
	tile.zone = Tile.ZoneType.NONE
	tile.special = Tile.SpecialBuilding.NONE
	return true

func place_special(x: int, y: int, special: int) -> bool:
	var tile := get_tile(x, y)
	if tile == null or not tile.is_buildable():
		return false
	tile.special = special
	return true

func has_road_neighbor(x: int, y: int) -> bool:
	for tile in get_neighbors(x, y):
		if tile.zone == Tile.ZoneType.ROAD:
			return true
	return false

## 4-directional (von Neumann) neighbors, clipped to the grid bounds.
func get_neighbors(x: int, y: int) -> Array[Tile]:
	var result: Array[Tile] = []
	var offsets := [[0, -1], [0, 1], [-1, 0], [1, 0]]
	for offset in offsets:
		var nx: int = x + offset[0]
		var ny: int = y + offset[1]
		if is_in_bounds(nx, ny):
			result.append(get_tile(nx, ny))
	return result

func count_zoned(zone: int) -> int:
	var count := 0
	for tile in _tiles:
		if tile.zone == zone:
			count += 1
	return count

func to_dict() -> Dictionary:
	var tiles_data: Array = []
	for tile in _tiles:
		tiles_data.append(tile.to_dict())
	return {
		"width": width,
		"height": height,
		"tiles": tiles_data,
	}

static func from_dict(data: Dictionary) -> CityGrid:
	var grid := CityGrid.new(int(data["width"]), int(data["height"]))
	var tiles_data: Array = data["tiles"]
	for i in range(tiles_data.size()):
		grid._tiles[i].from_dict(tiles_data[i])
	return grid

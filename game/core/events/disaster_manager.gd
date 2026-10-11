class_name DisasterManager
extends RefCounted
## Original disaster set: generic genre staples (fire/flood/tornado/
## earthquake) reimplemented with our own numbers and text — not copied
## from any specific game's events, mechanics or wording.

enum Type {
	FIRE,
	FLOOD,
	TORNADO,
	EARTHQUAKE,
}

const TYPE_COUNT := 4
const RANDOM_TRIGGER_CHANCE := 0.05 ## per simulated month, when enabled
const FLOOD_WATER_RADIUS := 2.0
const FLOOD_MAX_SAFE_ELEVATION := 1 ## tiles raised above this via terraforming are flood-proof
const EARTHQUAKE_DAMAGE_CHANCE := 0.15
const GOOD_FIRE_COVERAGE := 0.5 ## above this, a fire is contained to minor damage

var enabled: bool = true
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

## Called once per simulated month. No-op (and logs nothing) when disabled
## or the random roll doesn't land.
func maybe_trigger_random(grid: CityGrid, news: NewsFeed, month: int) -> void:
	if not enabled or rng.randf() > RANDOM_TRIGGER_CHANCE:
		return
	trigger(rng.randi() % TYPE_COUNT, grid, news, month)

## Fires a specific disaster now, regardless of `enabled` — used for
## manual/debug triggers and by maybe_trigger_random.
func trigger(type: int, grid: CityGrid, news: NewsFeed, month: int) -> void:
	match type:
		Type.FIRE:
			trigger_fire(grid, news, month)
		Type.FLOOD:
			trigger_flood(grid, news, month)
		Type.TORNADO:
			trigger_tornado(grid, news, month, rng.randi() % grid.height)
		Type.EARTHQUAKE:
			trigger_earthquake(grid, news, month)

func trigger_fire(grid: CityGrid, news: NewsFeed, month: int) -> void:
	var targets: Array[Tile] = []
	for tile in grid.get_all_tiles():
		if tile.is_occupied_zone() and tile.growth_stage > 0:
			targets.append(tile)
	if targets.is_empty():
		return
	var tile: Tile = targets[rng.randi() % targets.size()]
	var severity := 1 if tile.fire_coverage > GOOD_FIRE_COVERAGE else 2
	for i in range(severity):
		tile.shrink()
	news.add(month, "Incendio atingiu uma construcao em (%d, %d)." % [tile.x, tile.y])

## Only zoned tiles close to water AND at or below FLOOD_MAX_SAFE_ELEVATION
## are destroyed — raising elevation via terraforming is the counter-play.
func trigger_flood(grid: CityGrid, news: NewsFeed, month: int) -> void:
	var water_tiles: Array[Tile] = []
	for tile in grid.get_all_tiles():
		if tile.zone == Tile.ZoneType.WATER:
			water_tiles.append(tile)
	if water_tiles.is_empty():
		return
	var hit := 0
	for tile in grid.get_all_tiles():
		if not tile.is_occupied_zone() or tile.elevation > FLOOD_MAX_SAFE_ELEVATION:
			continue
		for water in water_tiles:
			var dist: float = Vector2(tile.x - water.x, tile.y - water.y).length()
			if dist <= FLOOD_WATER_RADIUS:
				tile.reset_growth()
				hit += 1
				break
	if hit > 0:
		news.add(month, "Enchente destruiu %d construcoes em terreno baixo perto da agua." % hit)

func trigger_tornado(grid: CityGrid, news: NewsFeed, month: int, row: int) -> void:
	var hit := 0
	for x in range(grid.width):
		var tile := grid.get_tile(x, row)
		if tile != null and tile.is_occupied_zone():
			tile.reset_growth()
			hit += 1
	if hit > 0:
		news.add(month, "Tornado cruzou a linha %d da cidade e destruiu %d construcoes." % [row, hit])

func trigger_earthquake(grid: CityGrid, news: NewsFeed, month: int) -> void:
	var hit := 0
	for tile in grid.get_all_tiles():
		if tile.is_occupied_zone() and tile.growth_stage > 0 and rng.randf() < EARTHQUAKE_DAMAGE_CHANCE:
			tile.shrink()
			hit += 1
	if hit > 0:
		news.add(month, "Terremoto abalou a cidade, afetando %d construcoes." % hit)

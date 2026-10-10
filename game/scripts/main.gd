extends Node2D
## Fase 0 smoke-test scene: renders the CityGrid and lets the player paint
## residential zones with the mouse, just to prove grid + camera + input
## work end to end. Tool selection UI comes in Fase 1.

const TILE_SIZE := 32
const GRID_WIDTH := 32
const GRID_HEIGHT := 32

var grid: CityGrid

func _ready() -> void:
	grid = CityGrid.new(GRID_WIDTH, GRID_HEIGHT)
	queue_redraw()

func _draw() -> void:
	for y in range(grid.height):
		for x in range(grid.width):
			var tile := grid.get_tile(x, y)
			var color := _color_for_zone(tile.zone)
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE - 1, TILE_SIZE - 1)
			draw_rect(rect, color)

func _color_for_zone(zone: int) -> Color:
	match zone:
		Tile.ZoneType.RESIDENTIAL:
			return Color(0.2, 0.7, 0.3)
		Tile.ZoneType.COMMERCIAL:
			return Color(0.2, 0.4, 0.9)
		Tile.ZoneType.INDUSTRIAL:
			return Color(0.8, 0.7, 0.2)
		Tile.ZoneType.WATER:
			return Color(0.1, 0.3, 0.6)
		_:
			return Color(0.3, 0.3, 0.3)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var local_pos := get_global_mouse_position()
		var gx := int(local_pos.x / TILE_SIZE)
		var gy := int(local_pos.y / TILE_SIZE)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if grid.set_zone(gx, gy, Tile.ZoneType.RESIDENTIAL):
				queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if grid.set_zone(gx, gy, Tile.ZoneType.NONE):
				queue_redraw()

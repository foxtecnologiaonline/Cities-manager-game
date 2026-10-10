extends Node2D
## Fase 1 smoke-test scene: renders the grid and runs the simulation loop
## (utilities -> RCI demand/growth -> budget) so the systems in core/ can be
## seen working end to end. Dedicated build-tool UI comes in a later pass;
## for now, zoning/placing is driven directly by mouse + number keys.

const TILE_SIZE := 32
const GRID_WIDTH := 32
const GRID_HEIGHT := 32
const SAVE_SLOT := "slot1"
const TICK_INTERVAL_SECONDS := 2.0 ## 1 simulated month every 2s, fast for the demo

var grid: CityGrid
var budget: Budget
var simulation: CitySimulation
var _tick_timer: float = 0.0
var _game_over := false

@onready var hud_label: Label = $HUD/InfoLabel

func _ready() -> void:
	_start_new_game()

func _start_new_game() -> void:
	grid = CityGrid.new(GRID_WIDTH, GRID_HEIGHT)
	budget = Budget.new()
	simulation = CitySimulation.new(grid, budget)
	_game_over = false
	queue_redraw()
	_update_hud()

func _process(delta: float) -> void:
	if _game_over:
		return
	_tick_timer += delta
	if _tick_timer >= TICK_INTERVAL_SECONDS:
		_tick_timer = 0.0
		_game_over = not simulation.tick()
		queue_redraw()
		_update_hud()

func _draw() -> void:
	for y in range(grid.height):
		for x in range(grid.width):
			var tile := grid.get_tile(x, y)
			var color := _color_for_tile(tile)
			var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE - 1, TILE_SIZE - 1)
			draw_rect(rect, color)

func _color_for_tile(tile: Tile) -> Color:
	if tile.special == Tile.SpecialBuilding.POWER_PLANT:
		return Color(0.9, 0.3, 0.1)
	if tile.special == Tile.SpecialBuilding.WATER_PUMP:
		return Color(0.1, 0.6, 0.9)
	var stage_t := float(tile.growth_stage) / float(Tile.MAX_GROWTH_STAGE)
	match tile.zone:
		Tile.ZoneType.RESIDENTIAL:
			return Color(0.1, 0.4, 0.15).lerp(Color(0.4, 0.9, 0.5), stage_t)
		Tile.ZoneType.COMMERCIAL:
			return Color(0.1, 0.2, 0.5).lerp(Color(0.4, 0.6, 1.0), stage_t)
		Tile.ZoneType.INDUSTRIAL:
			return Color(0.5, 0.4, 0.05).lerp(Color(0.9, 0.8, 0.3), stage_t)
		Tile.ZoneType.ROAD:
			return Color(0.25, 0.25, 0.25)
		Tile.ZoneType.WATER:
			return Color(0.1, 0.3, 0.6)
		_:
			return Color(0.3, 0.3, 0.3)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_handle_click(event)
	elif event is InputEventKey and event.pressed:
		_handle_key(event)

func _tile_under_mouse() -> Vector2i:
	var local_pos := get_global_mouse_position()
	return Vector2i(int(local_pos.x / TILE_SIZE), int(local_pos.y / TILE_SIZE))

func _handle_click(event: InputEventMouseButton) -> void:
	var cell := _tile_under_mouse()
	var changed := false
	if event.button_index == MOUSE_BUTTON_LEFT:
		changed = grid.set_zone(cell.x, cell.y, Tile.ZoneType.RESIDENTIAL)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		changed = grid.bulldoze(cell.x, cell.y)
	if changed:
		queue_redraw()

## Demo-only hotkeys (apply at the tile under the mouse cursor):
##   1/2/3/4 = Residencial / Comercial / Industrial / Rua
##   P = usina de energia, U = estação de água
##   F5 = salvar, F9 = carregar
func _handle_key(event: InputEventKey) -> void:
	var cell := _tile_under_mouse()
	match event.keycode:
		KEY_1:
			grid.set_zone(cell.x, cell.y, Tile.ZoneType.RESIDENTIAL)
		KEY_2:
			grid.set_zone(cell.x, cell.y, Tile.ZoneType.COMMERCIAL)
		KEY_3:
			grid.set_zone(cell.x, cell.y, Tile.ZoneType.INDUSTRIAL)
		KEY_4:
			grid.set_zone(cell.x, cell.y, Tile.ZoneType.ROAD)
		KEY_P:
			grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.POWER_PLANT)
		KEY_U:
			grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.WATER_PUMP)
		KEY_F5:
			SaveGame.save_slot(SAVE_SLOT, grid, budget, simulation.tick_count)
		KEY_F9:
			_load_game()
		_:
			return
	queue_redraw()
	_update_hud()

func _load_game() -> void:
	var data := SaveGame.load_slot(SAVE_SLOT)
	if data.is_empty():
		return
	grid = data["grid"]
	budget = data["budget"]
	simulation = CitySimulation.new(grid, budget)
	simulation.tick_count = data["tick_count"]
	_game_over = false

func _update_hud() -> void:
	if hud_label == null:
		return
	var demand_text := "—"
	if simulation.last_demand != null:
		var demand := simulation.last_demand
		demand_text = "R %.0f / C %.0f / I %.0f" % [demand.residential, demand.commercial, demand.industrial]
	hud_label.text = "Mes %d | Caixa: %.0f | Demanda %s%s" % [
		simulation.tick_count,
		budget.treasury,
		demand_text,
		" | FALIDO" if _game_over else "",
	]

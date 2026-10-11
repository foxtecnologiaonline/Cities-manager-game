extends Node2D
## Fase 1 + Fase 2 smoke-test scene: renders the grid (zones or a data
## overlay) and runs the simulation loop so the systems in core/ can be
## seen working end to end. Dedicated build-tool UI comes in a later pass;
## for now, zoning/placing is driven directly by mouse + keyboard.

const TILE_SIZE := 32
const GRID_WIDTH := 32
const GRID_HEIGHT := 32
const SAVE_SLOT := "slot1"
const TICK_INTERVAL_SECONDS := 2.0 ## 1 simulated month every 2s, fast for the demo

enum OverlayMode { ZONES, LAND_VALUE, POLLUTION, CRIME, TRAFFIC }
const OVERLAY_COUNT := 5
const OVERLAY_NAMES := ["Zonas", "Valor do terreno", "Poluicao", "Criminalidade", "Trafico"]

var grid: CityGrid
var budget: Budget
var simulation: CitySimulation
var _tick_timer: float = 0.0
var _game_over := false
var _overlay_mode: int = OverlayMode.ZONES

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
	# Water is terrain, not data — always shown as water, even on an overlay.
	if tile.zone == Tile.ZoneType.WATER:
		return Color(0.1, 0.3, 0.6)
	match _overlay_mode:
		OverlayMode.LAND_VALUE:
			return _heat_color(tile.land_value, 100.0, true)
		OverlayMode.POLLUTION:
			return _heat_color(tile.pollution, PollutionCalculator.MAX_POLLUTION, false)
		OverlayMode.CRIME:
			return _heat_color(tile.crime, CrimeCalculator.MAX_CRIME, false)
		OverlayMode.TRAFFIC:
			return _heat_color(tile.traffic, 1.0, false)
		_:
			return _zone_color(tile)

## high_is_good = true for e.g. land value (high => green); false for e.g.
## pollution/crime/traffic (high => red).
func _heat_color(value: float, max_value: float, high_is_good: bool) -> Color:
	var t: float = clamp(value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	var good := Color(0.2, 0.8, 0.3)
	var bad := Color(0.85, 0.15, 0.15)
	return bad.lerp(good, t) if high_is_good else good.lerp(bad, t)

func _zone_color(tile: Tile) -> Color:
	if tile.special != Tile.SpecialBuilding.NONE:
		return _color_for_special(tile.special)
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
		Tile.ZoneType.HIGHWAY:
			return Color(0.35, 0.3, 0.1)
		Tile.ZoneType.RAIL:
			return Color(0.45, 0.45, 0.5)
		Tile.ZoneType.SUBWAY:
			return Color(0.3, 0.1, 0.4)
		_:
			return Color(0.3, 0.3, 0.3)

func _color_for_special(special: int) -> Color:
	match special:
		Tile.SpecialBuilding.POWER_PLANT:
			return Color(0.9, 0.3, 0.1)
		Tile.SpecialBuilding.WATER_PUMP:
			return Color(0.1, 0.6, 0.9)
		Tile.SpecialBuilding.POLICE_STATION:
			return Color(0.15, 0.25, 0.75)
		Tile.SpecialBuilding.FIRE_STATION:
			return Color(0.8, 0.1, 0.1)
		Tile.SpecialBuilding.HOSPITAL:
			return Color(0.95, 0.95, 0.95)
		Tile.SpecialBuilding.SCHOOL:
			return Color(0.9, 0.6, 0.1)
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
##   1/2/3/4/5/6/7 = Residencial / Comercial / Industrial / Rua / Rodovia / Trilho / Metro
##   P/U/K/F/H/O   = usina / agua / policia / bombeiros / hospital / escola
##   8             = alterna agua (terraformacao)
##   9/0           = sobe / desce elevacao
##   TAB           = alterna overlay de dados
##   F5/F9         = salvar / carregar
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
		KEY_5:
			grid.set_zone(cell.x, cell.y, Tile.ZoneType.HIGHWAY)
		KEY_6:
			grid.set_zone(cell.x, cell.y, Tile.ZoneType.RAIL)
		KEY_7:
			grid.set_zone(cell.x, cell.y, Tile.ZoneType.SUBWAY)
		KEY_P:
			grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.POWER_PLANT)
		KEY_U:
			grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.WATER_PUMP)
		KEY_K:
			grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.POLICE_STATION)
		KEY_F:
			grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.FIRE_STATION)
		KEY_H:
			grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.HOSPITAL)
		KEY_O:
			grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.SCHOOL)
		KEY_8:
			var tile := grid.get_tile(cell.x, cell.y)
			if tile != null:
				grid.terraform_set_water(cell.x, cell.y, tile.zone != Tile.ZoneType.WATER)
		KEY_9:
			grid.raise_elevation(cell.x, cell.y)
		KEY_0:
			grid.lower_elevation(cell.x, cell.y)
		KEY_TAB:
			_overlay_mode = (_overlay_mode + 1) % OVERLAY_COUNT
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
	var demand_text := "-"
	if simulation.last_demand != null:
		var demand := simulation.last_demand
		demand_text = "R %.0f / C %.0f / I %.0f" % [demand.residential, demand.commercial, demand.industrial]
	hud_label.text = "Mes %d | Caixa: %.0f | Demanda %s | Overlay: %s%s" % [
		simulation.tick_count,
		budget.treasury,
		demand_text,
		OVERLAY_NAMES[_overlay_mode],
		" | FALIDO" if _game_over else "",
	]

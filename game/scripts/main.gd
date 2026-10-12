extends Node2D
## Fase 1-4 smoke-test scene: renders the grid (zones or a data overlay)
## and runs the simulation loop so the systems in core/ can be seen
## working end to end. Build actions go through the bottom toolbar
## (scripts/toolbar.gd) and a tap, on both mouse and touch; a few things
## with no toolbar button (overlay cycling, ordinances, disasters,
## save/load) stay keyboard-only demo/debug shortcuts.

## Mirrors scripts/toolbar.gd's TOOLS table order exactly — see the
## CONTRACT note there.
enum BuildTool {
	NONE,
	ZONE_RESIDENTIAL, ZONE_COMMERCIAL, ZONE_INDUSTRIAL,
	ZONE_ROAD, ZONE_HIGHWAY, ZONE_RAIL, ZONE_SUBWAY,
	BULLDOZE,
	PLACE_POWER_PLANT, PLACE_WATER_PUMP,
	PLACE_POLICE, PLACE_FIRE, PLACE_HOSPITAL, PLACE_SCHOOL,
	PLACE_AIRPORT, PLACE_SEAPORT,
	TERRAFORM_TOGGLE_WATER, TERRAFORM_RAISE, TERRAFORM_LOWER,
}

const TILE_SIZE := 32
const GRID_WIDTH := 32
const GRID_HEIGHT := 32
const SAVE_SLOT := "slot1"
const TICK_INTERVAL_SECONDS := 2.0 ## 1 simulated month every 2s, fast for the demo

## A press that moves less than this (in screen pixels) before release
## counts as a tap/click, not a drag — drags are left alone to pan the
## camera (see scripts/camera.gd), taps apply the current tool.
const TAP_MOVE_THRESHOLD := 12.0

enum OverlayMode { ZONES, LAND_VALUE, POLLUTION, CRIME, TRAFFIC }
const OVERLAY_COUNT := 5
const OVERLAY_NAMES := ["Zonas", "Valor do terreno", "Poluicao", "Criminalidade", "Trafico"]

var grid: CityGrid
var budget: Budget
var simulation: CitySimulation
var _tick_timer: float = 0.0
var _game_over := false
var _overlay_mode: int = OverlayMode.ZONES

var _current_tool: int = BuildTool.ZONE_RESIDENTIAL
var _current_tool_label: String = "Residencial"

var _press_active := false
var _press_moved := false
var _press_screen_pos: Vector2 = Vector2.ZERO

@onready var hud_label: Label = $HUD/InfoLabel

func _ready() -> void:
	_start_new_game()

func _on_tool_selected(tool: int, label: String) -> void:
	_current_tool = tool
	_current_tool_label = label
	_update_hud()

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

## high_is_good = true for e.g. land value (high => "good" color); false
## for e.g. pollution/crime/traffic (high => "bad" color). Blue/amber
## rather than green/red on purpose: green-red is the one diverging pair
## that's hardest to tell apart for red-green color blindness (the most
## common form), so an overlay meant to be read at a glance shouldn't use it.
func _heat_color(value: float, max_value: float, high_is_good: bool) -> Color:
	var t: float = clamp(value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	var good := Color(0.15, 0.45, 0.85) # blue
	var bad := Color(0.9, 0.55, 0.05) # amber
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
		Tile.SpecialBuilding.AIRPORT:
			return Color(0.6, 0.6, 0.65)
		Tile.SpecialBuilding.SEAPORT:
			return Color(0.1, 0.45, 0.55)
		_:
			return Color(0.3, 0.3, 0.3)

## Converts a screen-space position (works for both mouse and touch) to a
## grid cell, accounting for the camera's current pan/zoom.
func _tile_at_screen_pos(screen_pos: Vector2) -> Vector2i:
	var world_pos: Vector2 = get_viewport().canvas_transform.affine_inverse() * screen_pos
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_primary_press(event.pressed, event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Desktop-only convenience; touch has no right-click equivalent —
			# select the Demolir tool from the toolbar there instead.
			_apply_action_at(BuildTool.BULLDOZE, _tile_at_screen_pos(event.position))
	elif event is InputEventScreenTouch and event.index == 0:
		_handle_primary_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and _press_active:
		_update_press_movement(event.position)
	elif event is InputEventScreenDrag and event.index == 0 and _press_active:
		_update_press_movement(event.position)
	elif event is InputEventKey and event.pressed:
		_handle_key(event)

func _handle_primary_press(pressed: bool, screen_pos: Vector2) -> void:
	if pressed:
		_press_active = true
		_press_moved = false
		_press_screen_pos = screen_pos
	else:
		if _press_active and not _press_moved:
			_apply_action_at(_current_tool, _tile_at_screen_pos(screen_pos))
		_press_active = false

func _update_press_movement(screen_pos: Vector2) -> void:
	if screen_pos.distance_to(_press_screen_pos) > TAP_MOVE_THRESHOLD:
		_press_moved = true

func _apply_action_at(tool: int, cell: Vector2i) -> void:
	var changed := false
	match tool:
		BuildTool.NONE:
			pass
		BuildTool.ZONE_RESIDENTIAL:
			changed = grid.set_zone(cell.x, cell.y, Tile.ZoneType.RESIDENTIAL)
		BuildTool.ZONE_COMMERCIAL:
			changed = grid.set_zone(cell.x, cell.y, Tile.ZoneType.COMMERCIAL)
		BuildTool.ZONE_INDUSTRIAL:
			changed = grid.set_zone(cell.x, cell.y, Tile.ZoneType.INDUSTRIAL)
		BuildTool.ZONE_ROAD:
			changed = grid.set_zone(cell.x, cell.y, Tile.ZoneType.ROAD)
		BuildTool.ZONE_HIGHWAY:
			changed = grid.set_zone(cell.x, cell.y, Tile.ZoneType.HIGHWAY)
		BuildTool.ZONE_RAIL:
			changed = grid.set_zone(cell.x, cell.y, Tile.ZoneType.RAIL)
		BuildTool.ZONE_SUBWAY:
			changed = grid.set_zone(cell.x, cell.y, Tile.ZoneType.SUBWAY)
		BuildTool.BULLDOZE:
			changed = grid.bulldoze(cell.x, cell.y)
		BuildTool.PLACE_POWER_PLANT:
			changed = grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.POWER_PLANT)
		BuildTool.PLACE_WATER_PUMP:
			changed = grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.WATER_PUMP)
		BuildTool.PLACE_POLICE:
			changed = grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.POLICE_STATION)
		BuildTool.PLACE_FIRE:
			changed = grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.FIRE_STATION)
		BuildTool.PLACE_HOSPITAL:
			changed = grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.HOSPITAL)
		BuildTool.PLACE_SCHOOL:
			changed = grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.SCHOOL)
		BuildTool.PLACE_AIRPORT:
			if PopulationMilestones.can_place_airport(grid, cell.x, cell.y):
				changed = grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.AIRPORT)
		BuildTool.PLACE_SEAPORT:
			if PopulationMilestones.can_place_seaport(grid, cell.x, cell.y):
				changed = grid.place_special(cell.x, cell.y, Tile.SpecialBuilding.SEAPORT)
		BuildTool.TERRAFORM_TOGGLE_WATER:
			var tile := grid.get_tile(cell.x, cell.y)
			if tile != null:
				changed = grid.terraform_set_water(cell.x, cell.y, tile.zone != Tile.ZoneType.WATER)
		BuildTool.TERRAFORM_RAISE:
			changed = grid.raise_elevation(cell.x, cell.y)
		BuildTool.TERRAFORM_LOWER:
			changed = grid.lower_elevation(cell.x, cell.y)
	if changed:
		queue_redraw()

## Demo/debug-only keyboard shortcuts — everything that doesn't have (or
## doesn't need) a toolbar button:
##   TAB           = alterna overlay de dados
##   Ctrl+1..4     = alterna ordenanca (patrulha / reciclagem / turismo / educacao)
##   N             = liga/desliga desastres aleatorios
##   M             = dispara um desastre aleatorio agora (ignora o toggle N)
##   F5/F9         = salvar / carregar
func _handle_key(event: InputEventKey) -> void:
	if event.ctrl_pressed:
		_handle_ordinance_toggle(event.keycode)
		return
	match event.keycode:
		KEY_TAB:
			_overlay_mode = (_overlay_mode + 1) % OVERLAY_COUNT
		KEY_N:
			simulation.disasters.enabled = not simulation.disasters.enabled
		KEY_M:
			simulation.disasters.trigger(randi() % 4, grid, simulation.news, simulation.tick_count)
		KEY_F5:
			SaveGame.save_slot(SAVE_SLOT, simulation)
		KEY_F9:
			_load_game()
		_:
			return
	queue_redraw()
	_update_hud()

func _handle_ordinance_toggle(keycode: int) -> void:
	var ordinance := -1
	match keycode:
		KEY_1:
			ordinance = OrdinanceManager.Ordinance.EXTRA_PATROL
		KEY_2:
			ordinance = OrdinanceManager.Ordinance.RECYCLING_PROGRAM
		KEY_3:
			ordinance = OrdinanceManager.Ordinance.TOURISM_TAX
		KEY_4:
			ordinance = OrdinanceManager.Ordinance.FREE_EDUCATION
		_:
			return
	var ordinances := simulation.ordinances
	ordinances.set_active(ordinance, not ordinances.is_active(ordinance))
	queue_redraw()
	_update_hud()

func _load_game() -> void:
	var sim := SaveGame.load_slot(SAVE_SLOT)
	if sim == null:
		return
	grid = sim.grid
	budget = sim.budget
	simulation = sim
	_game_over = false
	queue_redraw()
	_update_hud()

func _update_hud() -> void:
	if hud_label == null:
		return
	var demand_text := "-"
	if simulation.last_demand != null:
		var demand := simulation.last_demand
		demand_text = "R %.0f / C %.0f / I %.0f" % [demand.residential, demand.commercial, demand.industrial]

	var latest_news := "-"
	var recent := simulation.news.latest(1)
	if not recent.is_empty():
		latest_news = str(recent[0]["text"])

	var active_ordinances: Array[String] = []
	for ordinance_id in OrdinanceManager.ORDINANCE_NAMES.size():
		if simulation.ordinances.is_active(ordinance_id):
			active_ordinances.append(OrdinanceManager.ORDINANCE_NAMES[ordinance_id])
	var ordinances_text := "nenhuma"
	if not active_ordinances.is_empty():
		ordinances_text = ", ".join(PackedStringArray(active_ordinances))

	hud_label.text = "Mes %d | Caixa: %.0f | Overlay: %s%s\nFerramenta: %s | Demanda %s\n%s\nOrdenancas: %s | Desastres: %s" % [
		simulation.tick_count,
		budget.treasury,
		OVERLAY_NAMES[_overlay_mode],
		" | FALIDO" if _game_over else "",
		_current_tool_label,
		demand_text,
		latest_news,
		ordinances_text,
		"ON" if simulation.disasters.enabled else "OFF",
	]

extends GutTest
## Integration tests for the actual Main.tscn + scripts/main.gd +
## scripts/toolbar.gd wiring. Unlike tests/core/, these instantiate the
## real scene — this is where a .tscn signal-connection typo or a
## BuildTool/toolbar.gd TOOLS table mismatch would actually show up
## (scripts/camera.gd's bug was found by just loading a script; this
## covers the next layer up: does the assembled scene actually behave?).

var main: Node2D

func before_each() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	main = packed.instantiate()
	add_child_autofree(main)
	await wait_idle_frames(2)

func test_default_tool_matches_toolbar_default_selection() -> void:
	# toolbar.gd's select_tool(1) picks Residencial by default; main.gd's
	# own starting _current_tool must agree, or they'd disagree until the
	# player's first click. The CONTRACT comment in both files is the only
	# thing keeping these in sync — this is what would catch it drifting.
	assert_eq(main._current_tool, main.BuildTool.ZONE_RESIDENTIAL)

func test_pressing_toolbar_button_updates_current_tool_via_signal_wiring() -> void:
	var toolbar = main.get_node("Toolbar")
	var button: Button = toolbar._buttons[main.BuildTool.ZONE_COMMERCIAL]
	button.pressed.emit()
	assert_eq(main._current_tool, main.BuildTool.ZONE_COMMERCIAL)
	assert_eq(main._current_tool_label, "Comercial")

func test_apply_action_zones_residential() -> void:
	main._apply_action_at(main.BuildTool.ZONE_RESIDENTIAL, Vector2i(5, 5))
	assert_eq(main.grid.get_tile(5, 5).zone, Tile.ZoneType.RESIDENTIAL)

func test_apply_action_places_power_plant() -> void:
	main._apply_action_at(main.BuildTool.PLACE_POWER_PLANT, Vector2i(2, 2))
	assert_eq(main.grid.get_tile(2, 2).special, Tile.SpecialBuilding.POWER_PLANT)

func test_apply_action_terraform_toggle_water() -> void:
	main._apply_action_at(main.BuildTool.TERRAFORM_TOGGLE_WATER, Vector2i(1, 1))
	assert_eq(main.grid.get_tile(1, 1).zone, Tile.ZoneType.WATER)
	main._apply_action_at(main.BuildTool.TERRAFORM_TOGGLE_WATER, Vector2i(1, 1))
	assert_eq(main.grid.get_tile(1, 1).zone, Tile.ZoneType.NONE)

func test_apply_action_airport_blocked_without_population_milestone() -> void:
	main._apply_action_at(main.BuildTool.PLACE_AIRPORT, Vector2i(3, 3))
	assert_eq(main.grid.get_tile(3, 3).special, Tile.SpecialBuilding.NONE)

## Main.tscn's Camera2D sits at (512, 512), not the origin, so a world
## position has to go through the viewport's canvas_transform to get the
## screen position that would actually map back to it — this is also
## exactly what exercises main.gd's own _tile_at_screen_pos being
## camera-aware (the whole reason it uses canvas_transform instead of
## assuming screen == world).
func _screen_pos_for_tile(cell: Vector2i, offset_in_tile: Vector2 = Vector2(5, 5)) -> Vector2:
	var world_pos: Vector2 = Vector2(cell.x, cell.y) * main.TILE_SIZE + offset_in_tile
	return main.get_viewport().canvas_transform * world_pos

func test_tap_without_drag_applies_tool() -> void:
	main._current_tool = main.BuildTool.ZONE_ROAD
	var cell := Vector2i(4, 4)
	var screen_pos: Vector2 = _screen_pos_for_tile(cell)

	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = screen_pos
	main._unhandled_input(press)

	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = screen_pos
	main._unhandled_input(release)

	assert_eq(main.grid.get_tile(cell.x, cell.y).zone, Tile.ZoneType.ROAD)

func test_drag_past_threshold_does_not_apply_tool() -> void:
	main._current_tool = main.BuildTool.ZONE_ROAD
	var cell := Vector2i(6, 6)
	var start_pos: Vector2 = _screen_pos_for_tile(cell, Vector2.ZERO)
	var end_pos := start_pos + Vector2(50, 50) # well past TAP_MOVE_THRESHOLD

	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = start_pos
	main._unhandled_input(press)

	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = end_pos
	main._unhandled_input(drag)

	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = end_pos
	main._unhandled_input(release)

	assert_eq(main.grid.get_tile(cell.x, cell.y).zone, Tile.ZoneType.NONE)

func test_tutorial_hint_dismiss_frees_the_panel() -> void:
	var hint := main.get_node("TutorialHint")
	assert_true(is_instance_valid(hint))
	var button: Button = hint.get_node("Panel/VBoxContainer/DismissButton")
	button.pressed.emit()
	await wait_idle_frames(1)
	assert_false(is_instance_valid(hint))

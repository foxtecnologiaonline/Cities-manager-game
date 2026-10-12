extends CanvasLayer
## Bottom, horizontally-scrolling toolbar: one radio-style button per build
## tool, built at runtime from a data table instead of hand-authoring ~20
## Button nodes in the scene file. Works identically with mouse and touch
## since Godot's Control/Button input handling is already touch-native —
## no custom gesture code needed here.
##
## CONTRACT: each entry's first element is the BuildTool id and must match
## the enum order in scripts/main.gd exactly (0 = NONE, 1 = ZONE_RESIDENTIAL,
## ...). Reordering one without the other silently breaks tool selection.

signal tool_selected(tool: int, label: String)

## Touch target size: comfortably above the 44x44pt (iOS) / 48x48dp
## (Android) minimums recommended for tappable controls.
const BUTTON_MIN_SIZE := Vector2(96, 56)

## The label strings are also the localization keys (see
## localization/strings.csv) — with no translation loaded, tr() just
## returns them unchanged, so the UI defaults to this Portuguese text.
const TOOLS := [
	[0, "Inspecionar"],
	[1, "Residencial"],
	[2, "Comercial"],
	[3, "Industrial"],
	[4, "Rua"],
	[5, "Rodovia"],
	[6, "Trilho"],
	[7, "Metro"],
	[8, "Demolir"],
	[9, "Energia"],
	[10, "Agua"],
	[11, "Policia"],
	[12, "Bombeiros"],
	[13, "Hospital"],
	[14, "Escola"],
	[15, "Aeroporto"],
	[16, "Porto"],
	[17, "Alternar Agua"],
	[18, "Subir Terreno"],
	[19, "Baixar Terreno"],
]

@onready var _button_container: HBoxContainer = $ScrollContainer/HBoxContainer
var _buttons: Dictionary = {} ## BuildTool (int) -> Button
var _group := ButtonGroup.new()

func _ready() -> void:
	for entry in TOOLS:
		var tool_id: int = entry[0]
		var label: String = entry[1]
		var button := Button.new()
		button.text = tr(label)
		button.custom_minimum_size = BUTTON_MIN_SIZE
		button.toggle_mode = true
		button.button_group = _group
		button.pressed.connect(_on_button_pressed.bind(tool_id, label))
		_button_container.add_child(button)
		_buttons[tool_id] = button
	select_tool(1) # default to Residencial, matching the old demo default

func _on_button_pressed(tool_id: int, label: String) -> void:
	tool_selected.emit(tool_id, tr(label))

func select_tool(tool_id: int) -> void:
	if _buttons.has(tool_id):
		_buttons[tool_id].button_pressed = true

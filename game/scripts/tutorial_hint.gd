extends CanvasLayer
## Minimal first-run onboarding hint: one panel, one message, one dismiss
## button. Not a multi-step tutorial system — that's more than this pass
## warrants. Shown once per session (not persisted via SaveGame; it's a
## UI nicety, not game state).

@onready var _dismiss_button: Button = $Panel/VBoxContainer/DismissButton

func _ready() -> void:
	_dismiss_button.pressed.connect(_on_dismiss_pressed)

func _on_dismiss_pressed() -> void:
	hide()
	queue_free()

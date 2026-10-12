extends Camera2D
## Pan (mouse middle-drag, touch drag, trackpad pan gesture) and zoom
## (scroll wheel, pinch/magnify gesture) for the city view. Desktop- and
## touch-friendly; will need a dedicated tool-mode toggle once build tools
## also consume mouse/touch input in Fase 1.

@export var zoom_speed := 0.1
@export var min_zoom := 0.25
@export var max_zoom := 3.0
@export var pan_speed := 1.0

var _dragging := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_position := Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
			_drag_start_mouse = event.position
			_drag_start_position = position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(zoom_speed)
	elif event is InputEventMouseMotion and _dragging:
		# `is` doesn't narrow event's type here (it's ANDed with another
		# condition), so cast explicitly instead of relying on inference.
		var motion := event as InputEventMouseMotion
		var delta: Vector2 = (motion.position - _drag_start_mouse) / zoom.x
		position = _drag_start_position - delta
	elif event is InputEventMagnifyGesture:
		_apply_zoom(-(event.factor - 1.0))
	elif event is InputEventPanGesture:
		position += event.delta * pan_speed / zoom.x
	elif event is InputEventScreenDrag:
		position -= event.relative / zoom.x

func _apply_zoom(amount: float) -> void:
	var new_zoom: float = clamp(zoom.x + amount, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)

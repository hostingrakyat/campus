class_name TouchScroll
extends ScrollContainer
## Finger-friendly scrolling. Drags work even when they start on a button or card, the list keeps
## gliding with inertia, and a drag never counts as a tap: Kit buttons and tap cards check
## `gesture_was_drag` and ignore the release that ends a scroll.

const DRAG_THRESHOLD := 12.0

## True from the moment the current gesture became a drag until the next press.
static var gesture_was_drag := false
## Set by main.gd: while a modal is open only scrolls inside the top modal react.
static var modal_root: Control

var _pressing := false
var _dragging := false
var _start := Vector2.ZERO
var _start_scroll := 0.0
var _vel := 0.0
var _last_y := 0.0
var _last_t := 0


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# We implement touch dragging ourselves; keep the built-in one out of the way.
	scroll_deadzone = 100000
	get_v_scroll_bar().modulate.a = 0.5


func _on_top() -> bool:
	if modal_root == null or not is_instance_valid(modal_root):
		return true
	var top: Node = null
	for c in modal_root.get_children():
		if not c.get_meta("closing", false):
			top = c
	return top == null or top.is_ancestor_of(self)


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventMouseButton:
		var mb: InputEventMouseButton = e
		var inside := get_global_rect().has_point(mb.position)
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if inside and _on_top():
					_pressing = true
					_dragging = false
					_start = mb.position
					_start_scroll = scroll_vertical
					_vel = 0.0
					_last_y = mb.position.y
					_last_t = Time.get_ticks_msec()
			else:
				_pressing = false
				_dragging = false
		elif mb.pressed and inside and _on_top() and (mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_UP):
			_vel = 0.0
			scroll_vertical += 90 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -90
	elif e is InputEventMouseMotion and _pressing:
		var mm: InputEventMouseMotion = e
		var d := mm.position - _start
		if not _dragging and absf(d.y) > DRAG_THRESHOLD and absf(d.y) > absf(d.x):
			_dragging = true
			gesture_was_drag = true
			_start = mm.position
			_start_scroll = scroll_vertical
		if _dragging:
			scroll_vertical = int(_start_scroll - (mm.position.y - _start.y))
			var now := Time.get_ticks_msec()
			var dt := maxf(1.0, now - _last_t) / 1000.0
			_vel = lerpf(_vel, -(mm.position.y - _last_y) / dt, 0.5)
			_last_y = mm.position.y
			_last_t = now


func _process(delta: float) -> void:
	if _pressing or absf(_vel) < 20.0:
		return
	var before := scroll_vertical
	scroll_vertical = int(scroll_vertical + _vel * delta)
	_vel *= pow(0.05, delta)
	if scroll_vertical == before:
		_vel = 0.0

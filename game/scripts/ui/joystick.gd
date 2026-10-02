class_name TouchStick
extends Control
## Floating on-screen stick. A touch anywhere inside `zone` (global rect) grabs it; the base jumps
## to the finger and the knob follows. Multitouch-safe (tracks its own finger index) and also
## works with a desktop mouse. `value` is -1..1 on both axes, y pointing down.

const RADIUS := 110.0

var value := Vector2.ZERO
var zone := Rect2()
var enabled := true
var home := Vector2.ZERO

var _finger := -99
var _center := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center = home
	_knob = home


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not enabled:
		if _finger != -99:
			_release()
		return
	if e is InputEventScreenTouch:
		if e.pressed and _finger == -99 and zone.has_point(e.position):
			_grab(e.index, e.position)
		elif not e.pressed and e.index == _finger:
			_release()
	elif e is InputEventScreenDrag and e.index == _finger:
		_drag(e.position)
	elif e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and _finger == -99 and zone.has_point(e.position):
			_grab(-2, e.position)
		elif not e.pressed and _finger == -2:
			_release()
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION and _finger == -2:
		_drag(e.position)


func _grab(idx: int, p: Vector2) -> void:
	_finger = idx
	_center = p - global_position
	_knob = _center
	value = Vector2.ZERO
	queue_redraw()


func _drag(p: Vector2) -> void:
	var d := (p - global_position) - _center
	if d.length() > RADIUS:
		d = d.normalized() * RADIUS
	_knob = _center + d
	value = d / RADIUS
	queue_redraw()


func _release() -> void:
	_finger = -99
	value = Vector2.ZERO
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(c: Vector2):
		_center = c
		queue_redraw(), _center, home, 0.18)
	tw.tween_method(func(k: Vector2):
		_knob = k
		queue_redraw(), _knob, home, 0.12)


func is_held() -> bool:
	return _finger != -99


func _draw() -> void:
	var a := 1.0 if _finger != -99 else 0.75
	draw_circle(_center, RADIUS + 18.0, Color(0.1, 0.07, 0.16, 0.28 * a))
	draw_arc(_center, RADIUS + 18.0, 0.0, TAU, 48, Color(1, 1, 1, 0.75 * a), 5.0, true)
	for i in 4:
		var ang := i * PI * 0.5
		var tip := _center + Vector2(cos(ang), sin(ang)) * (RADIUS - 6.0)
		var side := Vector2(cos(ang + PI * 0.5), sin(ang + PI * 0.5)) * 12.0
		var back := _center + Vector2(cos(ang), sin(ang)) * (RADIUS - 26.0)
		draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), Color(1, 1, 1, 0.6 * a))
	draw_circle(_knob + Vector2(0, 6), 56.0, Color(0, 0, 0, 0.2))
	draw_circle(_knob, 56.0, Color("fff8ec"))
	draw_circle(_knob, 42.0, Color("ffc83d"))
	draw_circle(_knob + Vector2(-12, -14), 12.0, Color(1, 1, 1, 0.6))

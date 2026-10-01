class_name Screen
extends Control
## Base for full-screen UI states. Holds a reference to the app root.

var main: Node


func _init(m: Node) -> void:
	main = m
	Kit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Bottom sheet anchored to the screen bottom, sized to content up to max_h.
func sheet(max_h: int = 760) -> VBoxContainer:
	var p := Kit.panel(Kit.PAPER, 36, 26)
	p.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.offset_left = 0
	p.offset_right = 0
	p.offset_bottom = 30
	var st: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
	st.content_margin_bottom = 56
	p.add_theme_stylebox_override("panel", st)
	add_child(p)
	var v := Kit.vbox(16)
	p.add_child(v)
	p.custom_minimum_size.y = 0
	p.set_meta("max_h", max_h)
	p.set_meta("sheet", true)
	return v


func top_bar() -> HBoxContainer:
	var h := Kit.hbox(10)
	h.set_anchors_preset(Control.PRESET_TOP_WIDE)
	h.offset_left = 20
	h.offset_right = -20
	h.offset_top = 24
	add_child(h)
	return h

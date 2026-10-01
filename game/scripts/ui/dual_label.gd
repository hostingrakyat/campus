class_name DualLabel
extends VBoxContainer
## Two stacked lines: main language on top, the other language as a smaller subtitle.

var pair: Variant = {}
var main_label: Label
var sub_label: Label


func setup(p: Variant, size: int, color: Color, align: int, font: Font = null) -> void:
	add_theme_constant_override("separation", 2)
	main_label = Kit.label("", size, color, font, align, true)
	sub_label = Kit.label("", maxi(16, int(size * 0.74)), Color(color, 0.62), null, align, true)
	add_child(main_label)
	add_child(sub_label)
	set_pair(p)


func _ready() -> void:
	Loc.mode_changed.connect(_refresh)


func _exit_tree() -> void:
	if Loc.mode_changed.is_connected(_refresh):
		Loc.mode_changed.disconnect(_refresh)


func set_pair(p: Variant) -> void:
	pair = p
	_refresh()


func _refresh() -> void:
	main_label.text = Loc.main(pair)
	var s := Loc.sub(pair)
	sub_label.text = s
	sub_label.visible = s != ""

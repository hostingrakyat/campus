class_name ModalCard
extends PanelContainer
## Window with a title row and close button.
## layout: "full"    – fills the screen (head fixed, list scrolls, trailing items pinned at the bottom)
##         "lower"   – like full but starts lower so the 3D character stays visible (wardrobe)
##         "compact" – small centered card for confirmations

var main: Node
var body: VBoxContainer
var layout := "full"


func _init(m: Node, title_pair: Dictionary = {}, width: int = 660, closable: bool = true, layout_kind: String = "full") -> void:
	main = m
	layout = layout_kind
	set_meta("layout", layout)
	var st := Kit.card_style(Kit.PAPER, 32)
	if layout != "compact":
		st.corner_radius_bottom_left = 0
		st.corner_radius_bottom_right = 0
		st.content_margin_bottom = 34
	add_theme_stylebox_override("panel", st)
	if layout == "compact":
		custom_minimum_size = Vector2(width, 0)
	body = Kit.vbox(14)
	add_child(body)
	if not title_pair.is_empty() or closable:
		var h := Kit.hbox(10)
		body.add_child(h)
		var t := Kit.title(Loc.main(title_pair), 36)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(t)
		if closable:
			var x := Kit.button("X", Color("c9c2d6"), func(): main.close_top_modal(), 22, 56)
			x.custom_minimum_size.x = 64
			h.add_child(x)


## Scrolling list. In full-screen layouts it takes all remaining height (max_h only applies to compact).
func scroll_list(max_h: int = 760) -> VBoxContainer:
	var list := Kit.vbox(10)
	var sc := Kit.scroll(list)
	if layout == "compact":
		sc.custom_minimum_size = Vector2(0, max_h)
	else:
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(sc)
	return list


func row_card(color: Color = Color.WHITE) -> HBoxContainer:
	var p := Kit.panel(color, 22, 14)
	var st: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
	st.shadow_size = 3
	st.shadow_offset = Vector2(0, 2)
	p.add_theme_stylebox_override("panel", st)
	var h := Kit.hbox(12)
	p.add_child(h)
	return h

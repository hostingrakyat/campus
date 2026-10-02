class_name Page
extends Control
## Full-height layout used by every screen and full-screen window:
##   head   (fixed, top)
##   body   (scrolls)
##   footer (pinned to the bottom edge, always visible)
## The panel is placed purely by anchors, so it lands in the same place on every screen size and
## no animation can leave it off-screen. The Page itself (full rect) is the thing that slides.

var panel: PanelContainer
var head: VBoxContainer
var body: VBoxContainer
var footer: VBoxContainer
var scroll: TouchScroll
var top_frac := 0.0


## top_frac: where the panel starts (0 = very top, 0.4 = leave the upper 40% for the 3D scene).
func _init(frac: float = 0.0, bg: Color = Kit.PAPER, top_px: float = 0.0) -> void:
	top_frac = frac
	Kit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = frac
	panel.anchor_bottom = 1.0
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = top_px
	panel.offset_bottom = 0
	var st := Kit.card_style(bg, 36)
	st.corner_radius_bottom_left = 0
	st.corner_radius_bottom_right = 0
	st.content_margin_left = 24
	st.content_margin_right = 24
	st.content_margin_top = 22
	st.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", st)
	add_child(panel)
	var v := Kit.vbox(14)
	panel.add_child(v)
	head = Kit.vbox(12)
	v.add_child(head)
	body = Kit.vbox(12)
	scroll = Kit.scroll(body)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	footer = Kit.vbox(10)
	v.add_child(footer)


func clear() -> void:
	for box in [head, body, footer]:
		for c in box.get_children():
			c.queue_free()
	scroll.scroll_vertical = 0


## Slide up from below and fade in (the end state is always offset 0 = anchored layout).
func animate_in(delay: float = 0.0) -> void:
	Fx.slide_in(self, Vector2(0, 280), delay, 0.45)


## Slide out of view / back in (used while a week plays as a cutscene).
func slide(show_page: bool) -> void:
	var away := get_viewport_rect().size.y * (1.0 - top_frac) + 80.0
	var tw := create_tween()
	if show_page:
		visible = true
		offset_top = away
		offset_bottom = away
		tw.set_parallel(true)
		tw.tween_property(self, "offset_top", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "offset_bottom", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tw.set_parallel(true)
		tw.tween_property(self, "offset_top", away, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(self, "offset_bottom", away, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(func(): visible = false)
	await tw.finished

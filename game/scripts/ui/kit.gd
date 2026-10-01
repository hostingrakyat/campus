class_name Kit
extends RefCounted
## UI toolkit: theme, palette and widget factories. Everything is code-built so screens stay tiny.

const INK := Color("2a2238")
const INK_SOFT := Color("5d5670")
const PAPER := Color("fff8ec")
const CARD := Color("ffffff")
const BLUE := Color("2f6bff")
const YELLOW := Color("ffc83d")
const PINK := Color("ff6b9a")
const GREEN := Color("2fbf71")
const RED := Color("ff5a4e")
const PURPLE := Color("7b5cff")
const ORANGE := Color("ff9f1c")
const CYAN := Color("27c6f2")
const GOLD := Color("ffb020")

static var font_body: FontVariation
static var font_bold: FontVariation
static var font_display: FontVariation
static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var nunito: FontFile = load("res://assets/fonts/Nunito.ttf")
	var fredoka: FontFile = load("res://assets/fonts/Fredoka.ttf")
	font_body = FontVariation.new()
	font_body.base_font = nunito
	font_body.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 650}
	font_bold = FontVariation.new()
	font_bold.base_font = nunito
	font_bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 850}
	font_display = FontVariation.new()
	font_display.base_font = fredoka
	font_display.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 620}

	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 26
	t.set_color("font_color", "Label", INK)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "Button", _btn_style(BLUE, state))
	t.set_font("font", "Button", font_bold)
	t.set_font_size("font_size", "Button", 26)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.7))
	t.set_stylebox("panel", "PanelContainer", card_style(CARD))
	t.set_stylebox("panel", "Panel", card_style(CARD))
	var le := StyleBoxFlat.new()
	le.bg_color = Color("f3eee4")
	le.set_corner_radius_all(18)
	le.set_content_margin_all(16)
	le.border_color = Color("e2d8c6")
	le.set_border_width_all(3)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le)
	t.set_color("font_color", "LineEdit", INK)
	t.set_font_size("font_size", "LineEdit", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.12)
	sb.set_corner_radius_all(6)
	t.set_stylebox("scroll", "VScrollBar", sb)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0, 0, 0, 0.25)
	grab.set_corner_radius_all(6)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	_theme = t
	return t


static func _btn_style(c: Color, state: String) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	if state == "hover":
		s.bg_color = c.lightened(0.08)
	elif state == "pressed":
		s.bg_color = c.darkened(0.08)
	elif state == "disabled":
		s.bg_color = c.lerp(Color("bdb6c8"), 0.7)
	s.set_corner_radius_all(22)
	s.border_color = c.darkened(0.28)
	s.border_width_bottom = 2 if state == "pressed" else 7
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 12 + (5 if state == "pressed" else 0)
	s.content_margin_bottom = 14
	return s


static func card_style(c: Color, radius: int = 28, shadow: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(22)
	if shadow:
		s.shadow_color = Color(0.16, 0.12, 0.24, 0.18)
		s.shadow_size = 10
		s.shadow_offset = Vector2(0, 6)
	return s


static func style_button(b: Button, c: Color) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, _btn_style(c, state))
	if c.get_luminance() > 0.7:
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(k, INK)


# --- Widgets -------------------------------------------------------------------

static func label(text: String, size: int = 26, color: Color = INK, font: Font = null, align: int = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func title(text: String, size: int = 40, color: Color = INK) -> Label:
	theme()
	return label(text, size, color, font_display)


static func dual(pair: Variant, size: int = 26, color: Color = INK, align: int = HORIZONTAL_ALIGNMENT_LEFT, bold: bool = false) -> DualLabel:
	theme()
	var d := DualLabel.new()
	d.setup(pair, size, color, align, font_bold if bold else null)
	return d


## Button whose caption follows the dual-subtitle setting.
static func button(pair: Variant, color: Color = BLUE, cb: Callable = Callable(), size: int = 26, min_h: int = 0, dual_ok: bool = true) -> Button:
	theme()
	var b := Button.new()
	style_button(b, color)
	b.focus_mode = Control.FOCUS_NONE
	var txt := INK if color.get_luminance() > 0.7 else Color.WHITE
	var refresh := func():
		var main_t := Loc.main(pair)
		var sub_t := Loc.sub(pair) if dual_ok else ""
		b.text = main_t if sub_t == "" else main_t + "\n" + sub_t
		b.custom_minimum_size.y = maxi(min_h, 64 if sub_t == "" else 92)
		# Autowrapped buttons report 0 min width; give short captions their natural width
		# so they never collapse inside horizontal rows.
		var widest := 0.0
		for line in [main_t, sub_t]:
			widest = maxf(widest, font_bold.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
		b.custom_minimum_size.x = minf(widest + 48.0, 260.0)
	refresh.call()
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", txt)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Loc.mode_changed.connect(refresh)
	b.tree_exiting.connect(func():
		if Loc.mode_changed.is_connected(refresh):
			Loc.mode_changed.disconnect(refresh))
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


## Tighter padding for small buttons in rows (tabs, nav).
static func compact(b: Button, pad: int = 6) -> Button:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var st: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
		st.content_margin_left = pad
		st.content_margin_right = pad
		b.add_theme_stylebox_override(state, st)
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.clip_text = false
	return b


static func panel(color: Color = CARD, radius: int = 28, pad: int = 22) -> PanelContainer:
	theme()
	var p := PanelContainer.new()
	var st := card_style(color, radius)
	st.set_content_margin_all(pad)
	p.add_theme_stylebox_override("panel", st)
	return p


static func vbox(sep: int = 14) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 14) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func margin(node: Control, l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(node)
	return m


static func scroll(child: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s


static func spacer(h: int = 0, expand: bool = false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	if expand:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func chip(text: String, bg: Color, fg: Color = Color.WHITE, size: int = 22) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(40)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 4
	st.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", st)
	theme()
	p.add_child(label(text, size, fg, font_bold, HORIZONTAL_ALIGNMENT_CENTER))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


static func currency_chip(kind: String, amount: int, on_plus: Callable = Callable()) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1, 1, 1, 0.92)
	st.set_corner_radius_all(40)
	st.content_margin_left = 8
	st.content_margin_right = 14
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	st.shadow_color = Color(0, 0, 0, 0.12)
	st.shadow_size = 4
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := hbox(6)
	p.add_child(h)
	h.add_child(Icon.make(kind, 30))
	theme()
	var l := label(_fmt(amount), 26, INK, font_bold)
	l.name = "Amount"
	h.add_child(l)
	if on_plus.is_valid():
		var b := Button.new()
		b.text = "+"
		b.focus_mode = Control.FOCUS_NONE
		style_button(b, GREEN)
		b.add_theme_font_size_override("font_size", 24)
		b.custom_minimum_size = Vector2(40, 40)
		for state in ["normal", "hover", "pressed", "focus"]:
			var bs: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
			bs.content_margin_left = 6
			bs.content_margin_right = 6
			bs.content_margin_top = 0
			bs.content_margin_bottom = 2
			bs.border_width_bottom = 3
			b.add_theme_stylebox_override(state, bs)
		b.pressed.connect(on_plus)
		h.add_child(b)
	return p


static func bar(value: float, max_v: float, color: Color, h: int = 16) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = max_v
	pb.value = value
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, h)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.1)
	bg.set_corner_radius_all(h)
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(h)
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	return pb


static func avatar(npc_id: String, size: int = 84) -> Control:
	var npc: Dictionary = Data.NPCS.get(npc_id, Data.NPCS.narator)
	var c := Icon.new()
	c.kind = "avatar"
	c.color = npc.color
	c.text = _initials(npc.name)
	c.custom_minimum_size = Vector2(size, size)
	return c


static func _initials(n: String) -> String:
	var parts := n.replace(".", "").replace(",", "").split(" ", false)
	var out := ""
	for p in parts:
		if p.length() > 0 and p[0] == p[0].to_upper() and not ["Pak", "Bu", "Dr", "Prof", "Bang", "Mas", "MKom", "M"].has(p):
			out += p[0]
		if out.length() >= 2:
			break
	return out if out != "" else "?"


static func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out


static func fmt(n: int) -> String:
	return _fmt(n)


static func full_rect(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0
	return c


## Short human labels for stat deltas.
static func fx_text(fx: Dictionary) -> Array:
	var names := {
		"energy": Loc.T("Energi", "Energy"), "mental": Loc.T("Mental", "Mental"), "social": Loc.T("Sosial", "Social"),
		"coins": Loc.T("Koin", "Coins"), "knowledge": Loc.T("Ilmu", "Knowledge"), "tugas": Loc.T("Tugas", "Assignments"),
		"attend": Loc.T("Hadir", "Attendance"), "rel": Loc.T("Relasi Dosen", "Faculty Rapport"), "bonus": Loc.T("Nilai", "Grades"),
		"draft": Loc.T("Draf", "Draft"), "acc": Loc.T("ACC", "Approval"), "debt": Loc.T("Utang", "Debt"),
	}
	var out: Array = []
	for k in fx:
		if not names.has(k):
			continue
		var v: float = float(fx[k])
		if absf(v) < 0.05:
			continue
		var good := v > 0 if k != "debt" else v < 0
		var num := ("%+d" % int(round(v))) if absf(v) >= 1.0 or k == "coins" else ("%+.1f" % v)
		out.append({"text": "%s %s" % [num, Loc.main(names[k])], "good": good})
	return out

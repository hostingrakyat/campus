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
static var _icon_svgs: Dictionary = {}
static var _icon_cache: Dictionary = {}

## Button captions (Indonesian text, prefix match) that get an icon automatically. First match wins.
const AUTO_ICONS := [
	["X", "x"], ["Jalani Minggu", "play"], ["Jelajah", "compass"], ["Acak", "shuffle"], ["Cepat", "fast-forward"],
	["Lewati", "skip-forward"], ["Lemari", "shirt"], ["Toko", "store"], ["Kerja", "briefcase"], ["Akademik", "graduation-cap"],
	["Menu", "menu"], ["Pengaturan", "settings"], ["< Kembali", "arrow-left"], ["Lanjutkan", "play"], ["Lanjut", "arrow-right"],
	["Nonton iklan", "tv"], ["Tonton", "tv"], ["Ambil hadiah", "gift"], ["Paham", "check"], ["Selesai", "check"],
	["Dimiliki", "check"], ["Beli gaya", "shopping-bag"], ["Beli", "shopping-cart"], ["Tukar diamond", "gem"], ["Tukar", "arrow-left-right"],
	["Galeri", "trophy"], ["Judul", "house"], ["Main lagi", "rotate-ccw"], ["Mulai Kuliah Baru", "sparkles"],
	["Ya, mulai baru", "sparkles"], ["Mulai Kuliah!", "graduation-cap"], ["Mulai kuliah", "book-open"], ["Simpan", "save"],
	["Catatan konten", "life-buoy"], ["Mini-game", "gamepad-2"], ["Resign", "log-out"], ["Lamar", "file-pen"],
	["Ikut War", "swords"], ["AMBIL", "plus"], ["Coba cara lain", "refresh-cw"], ["Nggak sanggup", "frown"],
	["Ya, berhenti", "door-open"], ["Pindah prodi", "arrow-left-right"], ["Batal", "ban"], ["Nggak usah", "x"],
	["Dibayar Ortu", "users"], ["Bayar pakai tabungan", "wallet"], ["Ajukan banding", "landmark"],
	["Daftar beasiswa", "graduation-cap"], ["Pinjol", "hand-coins"], ["Cuti", "clock"],
	["Indonesia", "languages"], ["English", "languages"], ["Bahasa Indonesia", "languages"],
]


## White line icon from data/icons.json, rasterized once per pixel size (tinted where it is used).
static func ico(icon_name: String, px: int = 64) -> Texture2D:
	var key := "%s@%d" % [icon_name, px]
	if _icon_cache.has(key):
		return _icon_cache[key]
	if _icon_svgs.is_empty():
		var f := FileAccess.open("res://data/icons.json", FileAccess.READ)
		if f == null:
			push_warning("icons.json missing")
			return null
		var d: Variant = JSON.parse_string(f.get_as_text())
		_icon_svgs = d.get("icons", {}) if d is Dictionary else {}
	if not _icon_svgs.has(icon_name):
		push_warning("Unknown icon " + icon_name)
		return null
	var img := Image.new()
	if img.load_svg_from_string(_icon_svgs[icon_name], px / 24.0) != OK:
		push_warning("Bad icon svg " + icon_name)
		return null
	var tex := ImageTexture.create_from_image(img)
	_icon_cache[key] = tex
	return tex


## Icon name for a button caption (see AUTO_ICONS), or "".
static func icon_for(pair: Variant) -> String:
	var t: String = pair.get("id", "") if pair is Dictionary else str(pair)
	for e in AUTO_ICONS:
		var key: String = e[0]
		# Whole-word prefix only, so content like "Tokopedia" never picks up the "Toko" icon.
		if t.begins_with(key) and (t.length() == key.length() or not _is_letter(t[key.length()])):
			return e[1]
	return ""


static func _is_letter(ch: String) -> bool:
	return ch.to_lower() != ch.to_upper()


## Removes an automatic icon (answer choices, item names and other content buttons).
static func plain(b: Button) -> Button:
	b.icon = null
	return b


## Puts an icon on a button, tinted like its caption. top=true stacks it above the text (nav bars).
static func set_icon(b: Button, icon_name: String, size: int = 26, top: bool = false) -> void:
	var px := int(size * (1.5 if top else 1.15))
	b.icon = ico(icon_name, px * 2)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", px)
	b.add_theme_constant_override("h_separation", 10)
	var col: Color = b.get_theme_color("font_color")
	for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(k, col)
	b.add_theme_color_override("icon_disabled_color", Color(col, 0.55))
	# Make room for an icon added after the caption was measured (Kit.button sizes auto icons itself).
	if not top and b.custom_minimum_size.x > 0.0 and not b.has_meta("icon_w") and icon_for(b.text) == "":
		b.custom_minimum_size.x += px + 10
	b.set_meta("icon_w", true)
	if top:
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	else:
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if b.text.strip_edges() == "X":
		b.text = ""
		b.set_meta("close", true)


static func icon_rect(icon_name: String, px: int, color: Color) -> TextureRect:
	var r := TextureRect.new()
	r.texture = ico(icon_name, px * 2)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.modulate = color
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Icon + label in a row (stat names, chips, section headings). The label is named "Text".
static func icon_label(icon_name: String, text: String, size: int = 26, color: Color = INK, font: Font = null) -> HBoxContainer:
	var h := hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(icon_rect(icon_name, int(size * 1.1), color))
	var l := label(text, size, color, font)
	l.name = "Text"
	h.add_child(l)
	return h


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
	var icon_name := icon_for(pair)
	var refresh := func():
		var main_t := Loc.main(pair)
		var sub_t := Loc.sub(pair) if dual_ok else ""
		if icon_name != "":
			main_t = _strip_arrows(main_t)
			sub_t = _strip_arrows(sub_t)
		b.text = main_t if sub_t == "" else main_t + "\n" + sub_t
		b.custom_minimum_size.y = maxi(min_h, 64 if sub_t == "" else 92)
		# Autowrapped buttons report 0 min width; give short captions their natural width
		# so they never collapse inside horizontal rows.
		var widest := 0.0
		for line in [main_t, sub_t]:
			widest = maxf(widest, font_bold.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
		var icon_w := size * 1.15 + 10.0 if icon_name != "" else 0.0
		b.custom_minimum_size.x = minf(widest + 48.0 + icon_w, 300.0)
	refresh.call()
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", txt)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if icon_name != "":
		set_icon(b, icon_name, size)
	Loc.mode_changed.connect(refresh)
	b.tree_exiting.connect(func():
		if Loc.mode_changed.is_connected(refresh):
			Loc.mode_changed.disconnect(refresh))
	if cb.is_valid():
		on_tap(b, cb)
	return b


static func _strip_arrows(t: String) -> String:
	t = t.strip_edges()
	if t.begins_with("< "):
		t = t.substr(2)
	while t.ends_with(">"):
		t = t.trim_suffix(">").strip_edges()
	return t


## Connects a button press that is ignored when the finger was scrolling a list.
static func on_tap(b: BaseButton, cb: Callable) -> void:
	b.pressed.connect(func():
		if not TouchScroll.gesture_was_drag:
			cb.call())


## Makes any control (cards, rows) tappable: fires on release, never after a scroll drag.
static func tap(c: Control, cb: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			if not TouchScroll.gesture_was_drag and c.get_global_rect().has_point(e.global_position):
				Audio.play("click", -3.0)
				cb.call())


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
	var s := TouchScroll.new()
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


static func chip(text: String, bg: Color, fg: Color = Color.WHITE, size: int = 22, icon_name: String = "") -> PanelContainer:
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
	if icon_name != "":
		st.content_margin_left = 10
		var h := icon_label(icon_name, text, size, fg, font_bold)
		h.add_theme_constant_override("separation", 4)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		p.add_child(h)
	else:
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

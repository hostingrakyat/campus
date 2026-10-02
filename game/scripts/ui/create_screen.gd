class_name CreateScreen
extends Screen
## Character creation: name, major (prodi) and look, with a live 3D preview.

var look: Dictionary = Data.DEFAULT_LOOK.duplicate()
var prodi := "IF"
var name_edit: LineEdit
var prodi_box: HBoxContainer
var opts_box: VBoxContainer
var tabs_box: HBoxContainer
var tab := "prodi"
var carry_coins := 0


func _ready() -> void:
	carry_coins = int(get_meta("carry", 0))
	if has_meta("prodi"):
		prodi = get_meta("prodi")
	var w: CampusWorld = main.world
	w.player.teleport(w.spots.lapangan)
	w.player.rotation.y = deg_to_rad(38)
	w.focus(w.player.position + Vector3(0, 1.0, 0), 6.6, true, 0.15)
	w.set_time("siang", true)
	_rebuild_char()

	var top := top_bar()
	top.add_child(Kit.button(Loc.T("< Kembali", "< Back"), Color("8a8398"), func(): main.goto("title"), 20))
	top.add_child(Kit.spacer(0, true))

	var pg := page(0.32)
	var name_row := Kit.hbox(12)
	pg.head.add_child(name_row)
	name_row.add_child(Kit.label(Loc.main(Loc.T("Nama", "Name")), 26, Kit.INK, Kit.font_bold))
	name_edit = LineEdit.new()
	name_edit.text = ["Bima", "Ayu", "Raka", "Nisa", "Dewa", "Putri", "Fajar", "Laras"][randi() % 8]
	name_edit.max_length = 14
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_edit)

	var tabs := Kit.hbox(8)
	tabs_box = tabs
	pg.head.add_child(tabs)
	for t in [["prodi", Loc.T("Prodi", "Major")], ["skin", Loc.T("Kulit", "Skin")], ["hair", Loc.T("Rambut", "Hair")], ["top", Loc.T("Baju", "Outfit")]]:
		var key: String = t[0]
		var b := Kit.compact(Kit.button(t[1], Kit.PURPLE if key == tab else Color("c9c2d6"), func(): _set_tab(key), 20))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("tab", key)
		tabs.add_child(b)
	opts_box = pg.body
	pg.footer.add_child(Kit.button(Loc.T("Mulai Kuliah!", "Start College!"), Kit.GREEN, _start, 30, 80))
	_set_tab("prodi")


func _set_tab(key: String) -> void:
	tab = key
	for b in tabs_box.get_children():
		Kit.style_button(b, Kit.PURPLE if b.get_meta("tab") == key else Color("c9c2d6"))
	for c in opts_box.get_children():
		c.queue_free()
	match key:
		"prodi":
			for id in Data.PRODI:
				opts_box.add_child(_prodi_card(id))
		"skin":
			opts_box.add_child(_swatches(Data.SKIN_TONES, "skin"))
		"hair":
			var grid := GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			for id in ["hair_short", "hair_fringe", "hair_long", "hair_hijab", "hair_buzz", "hair_curly"]:
				if Meta.owns(id):
					grid.add_child(_item_btn(id))
			opts_box.add_child(grid)
			opts_box.add_child(_swatches(Data.HAIR_COLORS, "hair_color"))
		"top":
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			for id in Data.ITEMS:
				if Data.ITEMS[id].slot == "top" and Meta.owns(id):
					grid.add_child(_item_btn(id))
			opts_box.add_child(grid)


func _prodi_card(id: String) -> Control:
	var p: Dictionary = Data.PRODI[id]
	var sel := id == prodi
	var card := Kit.panel(p.color if sel else Color.WHITE, 24, 16)
	var h := Kit.hbox(14)
	card.add_child(h)
	var badge := Icon.make("badge", 64, p.color.darkened(0.15) if sel else p.color, id)
	h.add_child(badge)
	var col := Kit.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	var fg := Color.WHITE if sel else Kit.INK
	col.add_child(Kit.dual(p.name, 28, fg, HORIZONTAL_ALIGNMENT_LEFT, true))
	col.add_child(Kit.dual(p.tag, 20, fg))
	h.add_child(Kit.chip("UKT %s" % Kit.fmt(p.ukt), Color(0, 0, 0, 0.18) if sel else Color("f3eee4"), fg, 20))
	Kit.tap(card, func():
		prodi = id
		_rebuild_char()
		main.world.player.hop()
		_set_tab("prodi"))
	return card


func _swatches(colors: Array, key: String) -> Control:
	var h := Kit.hbox(14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in colors.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(76, 76)
		b.focus_mode = Control.FOCUS_NONE
		var st := StyleBoxFlat.new()
		st.bg_color = colors[i]
		st.set_corner_radius_all(40)
		st.border_color = Kit.INK if int(look.get(key, 0)) == i else Color.WHITE
		st.set_border_width_all(6)
		for state in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, st)
		Kit.on_tap(b, func():
			look[key] = i
			_rebuild_char()
			_set_tab(tab))
		h.add_child(b)
	return h


func _item_btn(id: String) -> Button:
	var it: Dictionary = Data.ITEMS[id]
	var on: bool = look.get(it.slot, "") == id
	var b := Kit.button(it.name, Kit.BLUE if on else Color("eae4f2"), func():
		look[it.slot] = id
		_rebuild_char()
		_set_tab(tab), 20)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _rebuild_char() -> void:
	main.world.player.build(look, prodi)


func _start() -> void:
	var n := name_edit.text.strip_edges()
	if n == "":
		n = "Mahasigma"
	Game.new_run(n, prodi, look, carry_coins)
	main.goto("ukt")

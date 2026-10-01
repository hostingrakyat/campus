class_name TitleScreen
extends Screen

var _diamonds: PanelContainer


func _ready() -> void:
	main.world.focus(Vector3(0, 0, 2), 22.0, true)
	main.world.set_time("pagi", true)
	main.world.player.build(Game.s.get("look", Data.DEFAULT_LOOK) if not Game.s.is_empty() else Data.DEFAULT_LOOK, Game.s.get("prodi", "IF"))
	main.world.player.teleport(main.world.spots.lapangan)

	var top := top_bar()
	top.add_child(Kit.spacer(0, true))
	_diamonds = Kit.currency_chip("diamond", Meta.diamonds, func(): main.open_modal(ShopPopup.new(main, "diamond")))
	top.add_child(_diamonds)
	Meta.changed.connect(_refresh_diamonds)

	var logo := Kit.vbox(0)
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo.offset_top = 120
	logo.offset_left = -330
	logo.offset_right = 330
	add_child(logo)
	var t1 := Kit.title("MAHASIGMA", 104, Color.WHITE)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_color_override("font_outline_color", Kit.INK)
	t1.add_theme_constant_override("outline_size", 22)
	t1.add_theme_color_override("font_shadow_color", Color(0.1, 0.05, 0.2, 0.35))
	t1.add_theme_constant_override("shadow_offset_y", 10)
	logo.add_child(t1)
	var t2 := Kit.title("SIMULATOR", 56, Kit.YELLOW)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_color_override("font_outline_color", Kit.INK)
	t2.add_theme_constant_override("outline_size", 16)
	logo.add_child(t2)
	var t3 := Kit.label("Sigma College Student Simulator", 26, Color.WHITE, Kit.font_bold, HORIZONTAL_ALIGNMENT_CENTER)
	t3.add_theme_color_override("font_outline_color", Kit.INK)
	t3.add_theme_constant_override("outline_size", 8)
	logo.add_child(t3)
	logo.pivot_offset = Vector2(330, 80)
	logo.scale = Vector2(0.6, 0.6)
	logo.modulate.a = 0.0
	var drop := logo.create_tween().set_parallel(true)
	drop.tween_property(logo, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.15)
	drop.tween_property(logo, "modulate:a", 1.0, 0.25).set_delay(0.15)
	var tw := create_tween().set_loops()
	tw.tween_property(logo, "rotation", 0.025, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(logo, "rotation", -0.025, 1.6).set_trans(Tween.TRANS_SINE)

	var v := sheet()
	if Game.has_run() and Game.load_run():
		var s: Dictionary = Game.s
		v.add_child(Kit.button(Loc.T("Lanjutkan · %s, Semester %d" % [s.name, s.sem], "Continue · %s, Semester %d" % [s.name, s.sem]), Kit.GREEN, func(): main.resume(), 28))
	v.add_child(Kit.button(Loc.T("Mulai Kuliah Baru", "Start New College Life"), Kit.BLUE, _new_run, 28))
	var row := Kit.hbox(12)
	v.add_child(row)
	for b in [
		Kit.button(Loc.T("Galeri Ending", "Endings"), Kit.PURPLE, func(): main.goto("gallery"), 22),
		Kit.button(Loc.T("Toko", "Shop"), Kit.ORANGE, func(): main.open_modal(ShopPopup.new(main, "style")), 22),
		Kit.button(Loc.T("Pengaturan", "Settings"), Color("8a8398"), func(): main.open_modal(SettingsPopup.new(main)), 22),
	]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	var lang := Kit.label("", 20, Kit.INK_SOFT, null, HORIZONTAL_ALIGNMENT_CENTER)
	var refresh_lang := func(): lang.text = "Bahasa / Language: %s" % Loc.main(Loc.MODE_NAMES[Loc.mode])
	refresh_lang.call()
	Loc.mode_changed.connect(refresh_lang)
	tree_exiting.connect(func(): Loc.mode_changed.disconnect(refresh_lang))
	v.add_child(lang)
	Fx.stagger(v, 0.06, 0.25)


func _exit_tree() -> void:
	if Meta.changed.is_connected(_refresh_diamonds):
		Meta.changed.disconnect(_refresh_diamonds)


func _refresh_diamonds() -> void:
	_diamonds.find_child("Amount", true, false).text = Kit.fmt(Meta.diamonds)


func _new_run() -> void:
	if Game.has_run():
		var box := Kit.panel(Kit.PAPER, 30, 26)
		box.custom_minimum_size = Vector2(600, 0)
		var v := Kit.vbox(16)
		box.add_child(v)
		v.add_child(Kit.dual(Loc.T("Mulai baru? Progres kuliah yang sekarang akan hilang.", "Start over? Your current run will be lost."), 26, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, true))
		v.add_child(Kit.button(Loc.T("Ya, mulai baru", "Yes, start over"), Kit.RED, func():
			Game.clear_run()
			main.goto("create")))
		v.add_child(Kit.button(Loc.T("Batal", "Cancel"), Color("8a8398"), func(): main.close_top_modal()))
		main.open_modal(box)
	else:
		main.goto("create")

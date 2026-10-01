class_name HudScreen
extends Screen
## Main gameplay: stats on top, the 3D campus in the middle, weekly planner at the bottom.

const SLOT_COLORS := {"pagi": Color("ffb547"), "siang": Color("27c6f2"), "malam": Color("7b5cff"), "weekend": Color("2fbf71")}

var plan: Array = []
var running := false
var stats_box: VBoxContainer
var header: HBoxContainer
var planner: VBoxContainer
var go_btn: Button
var nav: HBoxContainer


func _ready() -> void:
	plan = Sim.default_plan(Game.s)
	main.world.player.build(Game.s.look, Game.s.prodi)
	main.world.player.teleport(main.world.spots.kos)
	main.world.follow(12.0, 0.36, true)
	main.world.set_time("pagi", true)

	header = top_bar()
	var stats_panel := Kit.panel(Color(1, 1, 1, 0.9), 24, 14)
	stats_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	stats_panel.offset_left = 20
	stats_panel.offset_right = -20
	stats_panel.offset_top = 104
	add_child(stats_panel)
	stats_box = Kit.vbox(8)
	stats_panel.add_child(stats_box)

	var v := sheet()
	planner = Kit.vbox(10)
	v.add_child(planner)
	go_btn = Kit.button(Loc.T("Jalani Minggu Ini  >", "Live This Week  >"), Kit.GREEN, _run_week, 30, 84)
	v.add_child(go_btn)
	nav = Kit.hbox(8)
	v.add_child(nav)
	for n in [
		[Loc.T("Lemari", "Wardrobe"), Kit.PINK, func(): main.open_modal(WardrobePopup.new(main), true, true)],
		[Loc.T("Toko", "Shop"), Kit.ORANGE, func(): main.open_modal(ShopPopup.new(main, "style"))],
		[Loc.T("Kerja", "Jobs"), Kit.BLUE, func(): main.open_modal(JobsPopup.new(main))],
		[Loc.T("Akademik", "Academics"), Kit.PURPLE, func(): main.open_modal(AcademicPopup.new(main))],
		[Loc.T("Menu", "Menu"), Color("8a8398"), func(): main.open_modal(SettingsPopup.new(main, true))],
	]:
		var b := Kit.compact(Kit.button(n[0], n[1], n[2], 19, 64, false))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(b)
	Game.changed.connect(refresh)
	Meta.changed.connect(refresh)
	Loc.mode_changed.connect(refresh)
	refresh()
	_first_week_hint()


func _exit_tree() -> void:
	for sig in [Game.changed, Meta.changed, Loc.mode_changed]:
		if sig.is_connected(refresh):
			sig.disconnect(refresh)


func on_back() -> bool:
	main.open_modal(SettingsPopup.new(main, true))
	return true


func refresh() -> void:
	if not is_inside_tree():
		return
	var s: Dictionary = Game.s
	var look_key: String = JSON.stringify(s.look) + s.prodi
	if look_key != get_meta("look_key", ""):
		set_meta("look_key", look_key)
		main.world.player.build(s.look, s.prodi)
	for c in header.get_children():
		c.queue_free()
	header.add_child(Icon.make("badge", 64, Data.PRODI[s.prodi].color, s.prodi))
	var who := Kit.vbox(0)
	who.add_child(Kit.label(s.name, 28, Color.WHITE, Kit.font_bold))
	var when := Loc.T("Semester %d · Minggu %d/12" % [s.sem, s.week], "Semester %d · Week %d/12" % [s.sem, s.week])
	who.add_child(Kit.label(Loc.main(when), 20, Color.WHITE))
	for l in who.get_children():
		l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.16, 0.8))
		l.add_theme_constant_override("outline_size", 8)
	header.add_child(who)
	header.add_child(Kit.spacer(0, true))
	header.add_child(Kit.currency_chip("coin", s.coins))
	header.add_child(Kit.currency_chip("diamond", Meta.diamonds, _watch_for_diamonds))

	for c in stats_box.get_children():
		c.queue_free()
	var row := Kit.hbox(14)
	stats_box.add_child(row)
	row.add_child(_stat(Loc.T("Energi", "Energy"), s.energy, Kit.YELLOW))
	row.add_child(_stat(Loc.T("Mental", "Mental"), s.mental, Kit.PINK if s.mental >= Data.MENTAL_WARNING else Kit.RED))
	row.add_child(_stat(Loc.T("Sosial", "Social"), s.social, Kit.PURPLE))
	var row2 := Kit.hbox(10)
	stats_box.add_child(row2)
	var ipk_txt := "-" if s.history.is_empty() else "%.2f" % Sim.ipk(s)
	row2.add_child(Kit.chip("IPK %s" % ipk_txt, Kit.BLUE, Color.WHITE, 20))
	if Sim.has_classes(s):
		var need := ceili(Data.ATTENDANCE_MIN * Data.WEEKS_PER_SEMESTER)
		var possible: int = s.attend + (Data.WEEKS_PER_SEMESTER - s.week + 1)
		var att_col := Kit.GREEN if possible >= need + 2 else (Kit.ORANGE if possible >= need else Kit.RED)
		row2.add_child(Kit.chip(Loc.main(Loc.T("Hadir %d/%d", "Attended %d/%d")) % [s.attend, s.week - 1], att_col, Color.WHITE, 20))
	row2.add_child(Kit.chip("SKS %d/144" % Sim.sks_lulus(s), Color("5d5670"), Color.WHITE, 20))
	if s.skripsi and not s.skripsi_done:
		row2.add_child(Kit.chip(Loc.main(Loc.T("Skripsi %d%%", "Thesis %d%%")) % int(s.acc), Kit.ORANGE, Color.WHITE, 20))
	if s.job != "":
		row2.add_child(Kit.chip(Loc.main(Loc.T("Kerja", "Job")), Kit.INK_SOFT, Color.WHITE, 20))
	var warn := _warning()
	if not warn.is_empty():
		var w := Kit.panel(Color("ffe3e0"), 16, 10)
		w.add_child(Kit.dual(warn, 20, Color("b3261e"), HORIZONTAL_ALIGNMENT_LEFT, true))
		stats_box.add_child(w)
	_build_planner()


func _warning() -> Dictionary:
	var s: Dictionary = Game.s
	if s.mental < Data.MENTAL_WARNING:
		return Loc.T("Mental kritis! Pilih Konseling, Tidur, atau Nongkrong minggu ini.", "Mental health critical! Pick Counseling, Sleep or Hang Out this week.")
	if Sim.has_classes(s) and s.attend + (Data.WEEKS_PER_SEMESTER - s.week + 1) < ceili(Data.ATTENDANCE_MIN * Data.WEEKS_PER_SEMESTER):
		return Loc.T("Kehadiran di bawah 75%: semua matkul terancam E.", "Attendance below 75%: every course is at risk of an E.")
	if s.energy < 20:
		return Loc.T("Energi hampir habis. Tidur dulu biar fokus.", "Almost out of energy. Sleep so you can focus.")
	if s.coins < 0:
		return Loc.T("Koin minus! Cari kerja part-time atau tukar diamond.", "Coins negative! Find a part-time job or exchange diamonds.")
	return {}


func _stat(name: Dictionary, value: int, color: Color) -> Control:
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := Kit.hbox(4)
	h.add_child(Kit.label(Loc.main(name), 20, Kit.INK_SOFT, Kit.font_bold))
	h.add_child(Kit.spacer(0, true))
	h.add_child(Kit.label(str(value), 20, Kit.INK, Kit.font_bold))
	v.add_child(h)
	v.add_child(Kit.bar(value, 100, color, 14))
	return v


func _build_planner() -> void:
	for c in planner.get_children():
		c.queue_free()
	var s: Dictionary = Game.s
	var head := Kit.hbox(10)
	planner.add_child(head)
	head.add_child(Kit.title(Loc.main(Loc.T("Rencana Minggu %d", "Week %d Plan")) % s.week, 32))
	head.add_child(Kit.spacer(0, true))
	if Sim.is_exam_week(s) and Sim.has_classes(s):
		head.add_child(Kit.chip(Loc.main(Loc.T("MINGGU UJIAN", "EXAM WEEK")), Kit.RED, Color.WHITE, 20))
	for i in Data.SLOTS.size():
		planner.add_child(_slot_row(i))


func _slot_row(i: int) -> Control:
	var slot: String = Data.SLOTS[i]
	var a: Dictionary = Data.ACTIONS[plan[i]]
	var name_pair: Dictionary = a.name
	if plan[i] == "kerja" and Game.s.job != "":
		name_pair = Data.JOBS[Game.s.job].name
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 74 if not Loc.is_dual() else 88
	var st := Kit.card_style(Color.WHITE, 22, false)
	st.border_color = Color("ece5d8")
	st.set_border_width_all(3)
	st.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", st)
	var pressed := st.duplicate()
	pressed.bg_color = Color("f3eee4")
	b.add_theme_stylebox_override("pressed", pressed)
	var h := Kit.hbox(12)
	Kit.full_rect(h)
	h.offset_left = 12
	h.offset_right = -12
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var slot_lbl := Kit.label(Loc.main(Data.SLOT_NAMES[slot]), 18, Color.WHITE, Kit.font_bold, HORIZONTAL_ALIGNMENT_CENTER)
	var slot_chip := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = SLOT_COLORS[slot]
	cs.set_corner_radius_all(14)
	cs.set_content_margin_all(6)
	slot_chip.add_theme_stylebox_override("panel", cs)
	slot_chip.custom_minimum_size = Vector2(118, 0)
	slot_chip.add_child(slot_lbl)
	slot_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(slot_chip)
	var d := Kit.dual(name_pair, 26, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in d.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(d)
	var locked := Sim.available_actions(Game.s, slot).size() <= 1
	var arrow := Kit.label("" if locked else ">", 30, Kit.INK_SOFT, Kit.font_bold)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(arrow)
	if not locked:
		b.pressed.connect(func(): _pick(i))
	return b


func _pick(i: int) -> void:
	if running:
		return
	var picker := ActionPicker.new(main, Data.SLOTS[i], plan[i])
	picker.picked.connect(func(id: String):
		plan[i] = id
		main.close_top_modal()
		_build_planner())
	main.open_modal(picker)


func _set_busy(b: bool) -> void:
	running = b
	go_btn.disabled = b
	for n in nav.get_children():
		n.disabled = b


func _run_week() -> void:
	if running:
		return
	_set_busy(true)
	var w: CampusWorld = main.world
	var s: Dictionary = Game.s
	var job_loc: String = Data.JOBS[s.job].loc if s.job != "" else "kafe"
	var res := Game.run_week(plan)
	for entry in res.log:
		var slot: String = entry.slot
		w.set_time("siang" if slot == "weekend" else slot)
		var loc: String = job_loc if entry.action == "kerja" else Data.ACTIONS[entry.action].loc
		w.move_player(loc)
		w.follow(12.0, 0.36)
		await _wait_arrival(1.8)
		w.float_text(Kit.fx_text(entry.fx))
		if not entry.note.is_empty():
			w.player.say(Loc.main(entry.note), 2.2)
		await get_tree().create_timer(0.9).timeout
	w.set_time("pagi")
	for n in res.notes:
		main.toast(n, Kit.INK)
	refresh()
	if res.wages > 0 and int(s.week) % 3 == 0 and Ads.rewarded_left() > 0:
		await _offer_double_wages(res.wages)
	if Game.s.phase != "ending":
		var ev := Game.pick_event()
		if not ev.is_empty():
			var pop := EventPopup.new(main, ev)
			main.open_modal(pop, false)
			await pop.done
	if Game.s.phase == "ending":
		main.goto("ending")
		return
	var nxt := Game.end_week()
	if nxt == "ending":
		main.goto("ending")
		return
	if nxt == "khs":
		Ads.maybe_interstitial("semester_end")
		main.goto("khs")
		return
	if int(Game.s.week) % 4 == 1:
		Ads.maybe_interstitial("week_%d" % Game.s.week)
	plan = Sim.default_plan(Game.s)
	_set_busy(false)
	refresh()


func _wait_arrival(max_t: float) -> void:
	var t := 0.0
	while main.world.player.walking and t < max_t:
		await get_tree().process_frame
		t += get_process_delta_time()


func _offer_double_wages(wages: int) -> void:
	var box := Kit.panel(Kit.PAPER, 30, 24)
	box.custom_minimum_size = Vector2(600, 0)
	var v := Kit.vbox(14)
	box.add_child(v)
	v.add_child(Kit.dual(Loc.T("Gaji minggu ini: %d koin. Nonton iklan biar bos kasih bonus 2x?" % wages, "Wages this week: %d coins. Watch an ad for a 2x bonus?" % wages), 26, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, true))
	var finished := [false]
	v.add_child(Kit.button(Loc.T("Nonton iklan (+%d koin)" % wages, "Watch ad (+%d coins)" % wages), Kit.GREEN, func():
		main.close_top_modal()
		Ads.show_rewarded("double_wages", func(ok: bool):
			if ok:
				Game.s.coins += wages
				Game.touch()
				main.toast(Loc.T("Bonus masuk! +%d koin" % wages, "Bonus received! +%d coins" % wages), Kit.GREEN)
			finished[0] = true)))
	v.add_child(Kit.button(Loc.T("Nggak usah", "No thanks"), Color("8a8398"), func():
		main.close_top_modal()
		finished[0] = true))
	main.open_modal(box, false)
	while not finished[0]:
		await get_tree().process_frame


func _watch_for_diamonds() -> void:
	main.open_modal(ShopPopup.new(main, "diamond"))


func _first_week_hint() -> void:
	var s: Dictionary = Game.s
	if s.sem == 1 and s.week == 1 and not Meta.settings.get("hint_planner", false):
		Meta.settings["hint_planner"] = true
		Meta.save_meta()
		main.toast(Loc.T("Ketuk tiap slot untuk ganti aktivitas, lalu Jalani Minggu.", "Tap a slot to change the activity, then Live This Week."), Kit.BLUE, 4.0)

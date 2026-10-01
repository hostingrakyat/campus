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
var _w: Dictionary = {}
var _amounts: Dictionary = {}
var _hold := false


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
	_build_planner(true)
	_first_week_hint()


func _exit_tree() -> void:
	for sig in [Game.changed, Meta.changed, Loc.mode_changed]:
		if sig.is_connected(refresh):
			sig.disconnect(refresh)


func on_back() -> bool:
	main.open_modal(SettingsPopup.new(main, true))
	return true


func refresh() -> void:
	if not is_inside_tree() or _hold:
		return
	var s: Dictionary = Game.s
	var look_key: String = JSON.stringify(s.look) + s.prodi
	if look_key != get_meta("look_key", ""):
		set_meta("look_key", look_key)
		main.world.player.build(s.look, s.prodi)
	if _w.is_empty():
		_build_static()
	_w.badge.color = Data.PRODI[s.prodi].color
	_w.badge.text = s.prodi
	_w.badge.queue_redraw()
	_w.name.text = s.name
	_w.when.text = Loc.main(Loc.T("Semester %d · Minggu %d/12", "Semester %d · Week %d/12")) % [s.sem, s.week]
	_animate_amount("coins", _w.coins, int(s.coins), "coin")
	_animate_amount("diamonds", _w.diamonds, Meta.diamonds, "diamond")
	for k in ["energy", "mental", "social"]:
		var st: Dictionary = _w[k]
		var v: int = s[k]
		st.name.text = Loc.main(st.pair)
		if int(st.bar.value) != v:
			Fx.bar_to(st.bar, v)
			Fx.count(st.num, st.bar.value, v, func(x: float): return str(int(round(x))), 0.55)
			if absi(int(st.bar.value) - v) >= 8:
				Fx.pulse(st.box, 1.06)
	var mental_col := Kit.PINK if s.mental >= Data.MENTAL_WARNING else Kit.RED
	(_w.mental.bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = mental_col

	for c in _w.chips.get_children():
		c.queue_free()
	var row2: HFlowContainer = _w.chips
	var ipk_txt := "-" if s.history.is_empty() else "%.2f" % Sim.ipk(s)
	row2.add_child(Kit.chip("IPK %s" % ipk_txt, Kit.BLUE, Color.WHITE, 20))
	if Sim.has_classes(s):
		var need := ceili(Data.ATTENDANCE_MIN * Data.WEEKS_PER_SEMESTER)
		var possible: int = s.attend + (Data.WEEKS_PER_SEMESTER - s.week + 1)
		var att_col := Kit.GREEN if possible >= need + 2 else (Kit.ORANGE if possible >= need else Kit.RED)
		row2.add_child(Kit.chip(Loc.main(Loc.T("Hadir %d/%d", "Attended %d/%d")) % [s.attend, s.week - 1], att_col, Color.WHITE, 20))
		var prog := Sim.study_progress(s)
		var expect := float(s.week - 1) / Data.WEEKS_PER_SEMESTER
		for k in [["knowledge", Loc.T("Ilmu", "Study")], ["tugas", Loc.T("Tugas", "Tasks")]]:
			var v: float = prog[k[0]]
			var col := Kit.GREEN if v >= expect * 0.9 else (Kit.ORANGE if v >= expect * 0.6 else Kit.RED)
			row2.add_child(Kit.chip("%s %d%%" % [Loc.main(k[1]), int(minf(v, 1.0) * 100)], col, Color.WHITE, 20))
	else:
		row2.add_child(Kit.chip("SKS %d/144" % Sim.sks_lulus(s), Color("5d5670"), Color.WHITE, 20))
	if s.skripsi and not s.skripsi_done:
		row2.add_child(Kit.chip(Loc.main(Loc.T("Skripsi %d%%", "Thesis %d%%")) % int(s.acc), Kit.ORANGE, Color.WHITE, 20))
	if s.job != "":
		row2.add_child(Kit.chip(Loc.main(Loc.T("Kerja", "Job")), Kit.INK_SOFT, Color.WHITE, 20))
	var warn := _warning()
	var key := JSON.stringify(warn)
	if key != _w.warn_key:
		_w.warn_key = key
		for c in _w.warn.get_children():
			c.queue_free()
		_w.warn.visible = not warn.is_empty()
		if not warn.is_empty():
			_w.warn.add_child(Kit.dual(warn, 20, Color("b3261e"), HORIZONTAL_ALIGNMENT_LEFT, true))
			Fx.pop_in(_w.warn, 0.05, 0.9)
			Fx.shake(_w.warn, 6.0)
			Audio.play("error", -10.0)
	if s.mental < Data.MENTAL_WARNING:
		Audio.play_music("kampus_malam", 2.5)
	elif Audio.music_name == "kampus_malam" and main.screen_name == "week":
		Audio.play_music("kampus_pagi", 2.5)
	if not running:
		_build_planner()


## Header and stat widgets are built once so values can animate between refreshes.
func _build_static() -> void:
	var badge := Icon.make("badge", 64, Kit.BLUE, "")
	header.add_child(badge)
	var who := Kit.vbox(0)
	var nm := Kit.label("", 28, Color.WHITE, Kit.font_bold)
	var when := Kit.label("", 20, Color.WHITE)
	for l in [nm, when]:
		l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.16, 0.8))
		l.add_theme_constant_override("outline_size", 8)
		who.add_child(l)
	header.add_child(who)
	header.add_child(Kit.spacer(0, true))
	var coin_chip := Kit.currency_chip("coin", Game.s.coins)
	var dia_chip := Kit.currency_chip("diamond", Meta.diamonds, _watch_for_diamonds)
	header.add_child(coin_chip)
	header.add_child(dia_chip)
	_w = {"badge": badge, "name": nm, "when": when, "coins": coin_chip, "diamonds": dia_chip, "warn_key": "null"}
	_amounts = {"coins": int(Game.s.coins), "diamonds": Meta.diamonds}
	var row := Kit.hbox(14)
	stats_box.add_child(row)
	for k in [["energy", Loc.T("Energi", "Energy"), Kit.YELLOW], ["mental", Loc.T("Mental", "Mental"), Kit.PINK], ["social", Loc.T("Sosial", "Social"), Kit.PURPLE]]:
		var v := Kit.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := Kit.hbox(4)
		var name_l := Kit.label(Loc.main(k[1]), 20, Kit.INK_SOFT, Kit.font_bold)
		h.add_child(name_l)
		h.add_child(Kit.spacer(0, true))
		var val: int = Game.s[k[0]]
		var num := Kit.label(str(val), 20, Kit.INK, Kit.font_bold)
		h.add_child(num)
		v.add_child(h)
		var bar := Kit.bar(val, 100, k[2], 14)
		v.add_child(bar)
		row.add_child(v)
		_w[k[0]] = {"box": v, "name": name_l, "num": num, "bar": bar, "pair": k[1]}
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 6)
	stats_box.add_child(chips)
	_w["chips"] = chips
	var warn := Kit.panel(Color("ffe3e0"), 16, 10)
	warn.visible = false
	stats_box.add_child(warn)
	_w["warn"] = warn


## Counts a currency chip from its previous value; sparkle + sound when it goes up.
func _animate_amount(key: String, chip: Control, value: int, sfx: String) -> void:
	var prev: int = _amounts.get(key, value)
	_amounts[key] = value
	var l: Label = chip.find_child("Amount", true, false)
	if prev == value:
		l.text = Kit.fmt(value)
		return
	Fx.count(l, prev, value, func(x: float): return Kit.fmt(int(round(x))), 0.7)
	Fx.pulse(chip, 1.12)
	if value > prev:
		Audio.play(sfx, -6.0)


func _warning() -> Dictionary:
	var s: Dictionary = Game.s
	if s.mental < Data.MENTAL_WARNING:
		return Loc.T("Mental kritis! Pilih Konseling, Tidur, atau Nongkrong minggu ini.", "Mental health critical! Pick Counseling, Sleep or Hang Out this week.")
	if Sim.has_classes(s) and s.attend + (Data.WEEKS_PER_SEMESTER - s.week + 1) < ceili(Data.ATTENDANCE_MIN * Data.WEEKS_PER_SEMESTER):
		return Loc.T("Kehadiran di bawah 75%: semua matkul terancam E.", "Attendance below 75%: every course is at risk of an E.")
	if s.energy < 20:
		return Loc.T("Energi hampir habis. Tidur dulu biar fokus.", "Almost out of energy. Sleep so you can focus.")
	if Sim.has_classes(s) and s.week >= 5:
		var prog := Sim.study_progress(s)
		var expect := float(s.week - 1) / Data.WEEKS_PER_SEMESTER
		if minf(prog.knowledge, prog.tugas) < expect * 0.5:
			return Loc.T("Belajar/tugas tertinggal jauh. Nilai matkul terancam jeblok.", "Study/assignments are far behind. Your grades are in danger.")
	if s.coins < 0:
		return Loc.T("Koin minus! Cari kerja part-time atau tukar diamond.", "Coins negative! Find a part-time job or exchange diamonds.")
	return {}


func _build_planner(animate: bool = false) -> void:
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
	if animate:
		Fx.stagger(planner, 0.05)


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
		_build_planner()
		Audio.play("select", -4.0)
		Fx.pulse(planner.get_child(i + 1), 1.05))
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
	var disp := {"energy": s.energy, "mental": s.mental, "social": s.social, "coins": s.coins}
	_hold = true
	Audio.play("week", -4.0)
	_banner(Loc.main(Loc.T("MINGGU %d", "WEEK %d")) % s.week, Kit.INK, true)
	var res := Game.run_week(plan)
	planner.modulate = Color(1, 1, 1, 0.75)
	for idx in res.log.size():
		var entry: Dictionary = res.log[idx]
		var slot: String = entry.slot
		for r in planner.get_child_count() - 1:
			planner.get_child(r + 1).modulate.a = 1.0 if r == idx else 0.45
		Fx.pulse(planner.get_child(idx + 1), 1.04)
		w.set_time("siang" if slot == "weekend" else slot)
		var loc: String = job_loc if entry.action == "kerja" else Data.ACTIONS[entry.action].loc
		var act_name: Dictionary = Data.JOBS[s.job].name if entry.action == "kerja" and s.job != "" else Data.ACTIONS[entry.action].name
		_banner("%s · %s" % [Loc.main(Data.SLOT_NAMES[slot]), Loc.main(act_name)], SLOT_COLORS[slot])
		w.move_player(loc)
		w.follow(12.0, 0.36)
		await _wait_arrival(1.8)
		Audio.play("pop", -6.0)
		w.float_text(Kit.fx_text(entry.fx))
		for k in disp:
			if entry.fx.has(k):
				disp[k] = disp[k] + int(round(entry.fx[k])) if k == "coins" else clampi(disp[k] + int(round(entry.fx[k])), 0, 100)
		_display(disp)
		if not entry.note.is_empty():
			w.player.say(Loc.main(entry.note), 2.2)
		await get_tree().create_timer(0.9).timeout
	planner.modulate = Color.WHITE
	_hold = false
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
	_build_planner(true)


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


## Shows intermediate stat values while the week plays out slot by slot.
func _display(d: Dictionary) -> void:
	for k in ["energy", "mental", "social"]:
		var st: Dictionary = _w[k]
		var v: int = d[k]
		if int(st.bar.value) != v:
			Fx.count(st.num, st.bar.value, v, func(x: float): return str(int(round(x))), 0.45)
			Fx.bar_to(st.bar, v, 0.45)
	_animate_amount("coins", _w.coins, int(d.coins), "coin")


## Ribbon that sweeps across the screen (week number / current slot).
func _banner(text: String, color: Color, big: bool = false) -> void:
	var p := Kit.panel(color, 40, 14)
	var l := Kit.title(text, 44 if big else 30, Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	await get_tree().process_frame
	if not is_instance_valid(p):
		return
	var sz := p.get_combined_minimum_size()
	var vw := get_viewport_rect().size.x
	var y := 520.0 if big else 250.0
	p.size = sz
	p.position = Vector2(-sz.x - 20, y)
	var mid := Vector2((vw - sz.x) * 0.5, y)
	var tw := p.create_tween()
	tw.tween_property(p, "position", mid, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.7 if big else 0.9)
	tw.tween_property(p, "position", Vector2(vw + 20, y), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(p.queue_free)

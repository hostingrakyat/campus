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
var _sheet_panel: PanelContainer
var _curtain: ColorRect
var _caption: PanelContainer
var _cap_box: VBoxContainer
var _skip := false
var _sheet_home := -1.0


func _ready() -> void:
	plan = Game.suggest_plan()
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

	_curtain = Kit.full_rect(ColorRect.new())
	_curtain.color = Color(0.06, 0.05, 0.1, 0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_curtain)
	var v := sheet()
	_sheet_panel = v.get_parent()
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
	_build_caption()
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
	var shuffle := Kit.compact(Kit.button(Loc.T("Acak", "Shuffle"), Kit.PURPLE, func():
		plan = Game.suggest_plan()
		Audio.play("card", -6.0)
		_build_planner(true), 18, 48, false), 12)
	head.add_child(shuffle)
	var news := Game.ensure_week()
	if news.get("id", "normal") != "normal":
		var card := Kit.panel(Color("fff1db") if not news.get("no_class", false) else Color("ffe3e0"), 18, 12)
		var nv := Kit.vbox(2)
		card.add_child(nv)
		nv.add_child(Kit.label(Loc.main(Loc.T("KABAR MINGGU INI: ", "THIS WEEK: ")) + Loc.main(news.title), 20, Kit.ORANGE.darkened(0.25), Kit.font_bold))
		nv.add_child(Kit.dual(news.text, 18, Kit.INK_SOFT))
		planner.add_child(card)
	for i in Data.SLOTS.size():
		var row := _slot_row(i)
		row.set_meta("slot_row", i)
		planner.add_child(row)
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
		Kit.on_tap(b, func(): _pick(i))
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
		for r in planner.get_children():
			if r.get_meta("slot_row", -1) == i:
				Fx.pulse(r, 1.05))
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
	var disp := {"energy": s.energy, "mental": s.mental, "social": s.social, "coins": s.coins}
	_hold = true
	_skip = false
	Audio.play("week", -4.0)
	var res := Game.run_week(plan)
	var ctx := _ctx()
	await _sheet_slide(false)
	_banner(Loc.main(Loc.T("MINGGU %d", "WEEK %d")) % s.week, Kit.INK, true)
	await get_tree().create_timer(0.35).timeout
	for idx in res.log.size():
		var entry: Dictionary = res.log[idx]
		var slot: String = entry.slot
		await _cover(true)
		w.set_time("siang" if slot == "weekend" else slot, true)
		ctx["scene_key"] = entry.get("scene_key", "")
		var scene := w.director.scene_for(entry)
		w.director.stage(scene, ctx, 0.47)
		_show_caption(entry)
		await _cover(false)
		Audio.play("pop", -6.0)
		if not _skip:
			w.director.play_bubbles(scene, ctx)
		w.float_text(Kit.fx_text(entry.fx))
		for k in disp:
			if entry.fx.has(k):
				disp[k] = disp[k] + int(round(entry.fx[k])) if k == "coins" else clampi(disp[k] + int(round(entry.fx[k])), 0, 100)
		_display(disp)
		await _hold_scene(1.3 if Meta.settings.get("fast_scenes", false) else 2.8)
	_caption.visible = false
	_hold = false
	for n in res.notes:
		main.toast(n, Kit.INK)
	refresh()
	if res.wages > 0 and int(s.week) % 3 == 0 and Ads.rewarded_left() > 0:
		await _offer_double_wages(res.wages)
	if Game.s.phase != "ending":
		var ev := Game.pick_event()
		if not ev.is_empty():
			await _cover(true)
			var cs := Cutscene.new(main, ev, ctx)
			main.open_cutscene(cs)
			_curtain.color.a = 0.0
			await cs.done
			main.close_cutscene(cs)
			_curtain.color.a = 1.0
	await _cover(true)
	w.director.return_to_campus("kos")
	w.set_time("pagi", true)
	w.follow(12.0, 0.36, true)
	await _cover(false)
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
	plan = Game.suggest_plan()
	_set_busy(false)
	refresh()
	_build_planner(true)
	_sheet_slide(true)


## Context for casting scenes: this week's lecturer, the advisor, the job, a friend.
func _ctx() -> Dictionary:
	var s: Dictionary = Game.s
	var lect: String = Data.LECTURERS[(int(s.sem) * 13 + int(s.week) * 7) % Data.LECTURERS.size()]
	var friends := ["ambis", "beban", "senior"]
	return {"lecturer": lect, "dospem": s.get("dospem", ""), "job": s.job, "friend": friends[int(s.week) % friends.size()]}


func _cover(on: bool) -> void:
	var tw := create_tween()
	tw.tween_property(_curtain, "color:a", 1.0 if on else 0.0, 0.06 if _skip else 0.18)
	await tw.finished


func _hold_scene(t: float) -> void:
	var el := 0.0
	while el < t and not _skip:
		await get_tree().process_frame
		el += get_process_delta_time()
	if _skip:
		await get_tree().create_timer(0.08).timeout


func _sheet_slide(show_sheet: bool) -> void:
	var h := _sheet_panel.size.y + 60.0
	if not show_sheet:
		_sheet_home = _sheet_panel.position.y
	var base_y := _sheet_home
	var tw := create_tween()
	if show_sheet:
		_sheet_panel.visible = true
		tw.tween_property(_sheet_panel, "position:y", base_y, 0.35).from(base_y + h).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(_sheet_panel, "position:y", base_y + h, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): _sheet_panel.visible = false)
	await tw.finished


func _build_caption() -> void:
	_caption = Kit.panel(Kit.PAPER, 30, 20)
	_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_caption.offset_left = 14
	_caption.offset_right = -14
	_caption.offset_bottom = -26
	_caption.visible = false
	add_child(_caption)
	var v := Kit.vbox(10)
	_caption.add_child(v)
	_cap_box = Kit.vbox(8)
	v.add_child(_cap_box)
	var row := Kit.hbox(10)
	v.add_child(row)
	row.add_child(Kit.spacer(0, true))
	var fast := Kit.compact(Kit.button(Loc.T("Cepat", "Fast"), Kit.BLUE if Meta.settings.get("fast_scenes", false) else Color("c9c2d6"), Callable(), 18, 50, false), 14)
	Kit.on_tap(fast, func():
		Meta.settings["fast_scenes"] = not Meta.settings.get("fast_scenes", false)
		Meta.save_meta()
		Kit.style_button(fast, Kit.BLUE if Meta.settings.fast_scenes else Color("c9c2d6"))
		Kit.compact(fast, 14))
	row.add_child(fast)
	row.add_child(Kit.compact(Kit.button(Loc.T("Lewati  >>", "Skip  >>"), Kit.INK_SOFT, func(): _skip = true, 18, 50, false), 14))


func _show_caption(entry: Dictionary) -> void:
	for c in _cap_box.get_children():
		c.queue_free()
	var s: Dictionary = Game.s
	var slot: String = entry.slot
	var act_name: Dictionary = Data.JOBS[s.job].name if entry.action == "kerja" and s.job != "" else Data.ACTIONS[entry.action].name
	var head := Kit.hbox(10)
	head.add_child(Kit.chip(Loc.main(Data.SLOT_NAMES[slot]), SLOT_COLORS[slot], Color.WHITE, 20))
	var n := Kit.label(Loc.main(act_name), 28, Kit.INK, Kit.font_display)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(n)
	_cap_box.add_child(head)
	var v: Dictionary = entry.get("variant", {})
	var line: Dictionary = entry.note if not entry.note.is_empty() else v.get("text", {})
	if not line.is_empty():
		var d := Kit.dual(line, 23)
		_cap_box.add_child(d)
		Fx.typewriter(d.main_label, 90.0)
		if not entry.note.is_empty() and v.has("text") and entry.action != "bimbingan":
			_cap_box.add_child(Kit.dual(v.text, 19, Kit.INK_SOFT))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	for f in Kit.fx_text(entry.fx):
		chips.add_child(Kit.chip(f.text, Color("e3f7ea") if f.good else Color("ffe6e3"), Color("17643a") if f.good else Color("b3261e"), 18))
	_cap_box.add_child(chips)
	Fx.stagger(chips, 0.05, 0.3)
	if not _caption.visible:
		_caption.visible = true
		Fx.slide_in(_caption, Vector2(0, 220), 0.0, 0.35)
	else:
		Fx.pulse(_caption, 1.02)


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

class_name KrsScreen
extends Screen
## Course registration: pick courses within the SKS limit, then survive the "War KRS" on a lagging portal.
## Courses you secure in time get Class A (fair lecturer); the rest land in Class B (strict lecturer).

const WAR_TIME := 12.0
const BUSY_CHANCE := 0.42

var v: VBoxContainer
var picked: Array = []
var cls: Dictionary = {}
var time_left := 0.0
var war_on := false
var retried := false
var timer_bar: ProgressBar
var rows: Dictionary = {}
var sks_chip: PanelContainer
var go_btn: Button


func _ready() -> void:
	var w: CampusWorld = main.world
	w.player.build(Game.s.look, Game.s.prodi)
	w.player.teleport(w.spots.kos)
	w.focus(w.player.position + Vector3(0, 1.0, 0), 8.0, true, 0.12)
	w.set_time("malam", true)
	picked = Sim.default_krs(Game.s)
	v = sheet()
	_build_select()


func on_back() -> bool:
	return war_on


func _build_select() -> void:
	for c in v.get_children():
		c.queue_free()
	var s: Dictionary = Game.s
	var limit := Sim.sks_limit(s)
	var head := Kit.hbox(10)
	v.add_child(head)
	head.add_child(Kit.title(Loc.main(Loc.T("Isi KRS", "Course Registration")), 38))
	head.add_child(Kit.spacer(0, true))
	sks_chip = Kit.chip("", Kit.GREEN, Color.WHITE, 22)
	head.add_child(sks_chip)
	v.add_child(Kit.dual(Loc.T("Batas SKS ditentukan IPS semester lalu. Matkul yang belum lulus wajib diulang. Geser daftar untuk melihat semua.", "Your credit limit depends on last semester's GPA. Failed courses must be retaken. Swipe the list to see all."), 20, Kit.INK_SOFT))
	var list := Kit.vbox(8)
	var sc := Kit.scroll(list)
	sc.custom_minimum_size.y = 560
	v.add_child(sc)
	for c in Sim.krs_options(s):
		list.add_child(_course_toggle(c))
	go_btn = Kit.button(Loc.T("Ikut War KRS!", "Enter the Registration War!"), Kit.RED, _start_war, 28, 84)
	v.add_child(go_btn)
	_update_total()
	if not has_meta("shown"):
		set_meta("shown", true)
		Fx.stagger(list, 0.03, 0.2)


func _picked_sks() -> int:
	var t := 0
	for c in Sim.krs_options(Game.s):
		if picked.has(c.code):
			t += int(c.sks)
	return t


func _update_total() -> void:
	var total := _picked_sks()
	var limit := Sim.sks_limit(Game.s)
	var lbl: Label = sks_chip.get_child(0)
	lbl.text = "%d / %d SKS" % [total, limit]
	var st: StyleBoxFlat = sks_chip.get_theme_stylebox("panel").duplicate()
	st.bg_color = Kit.GREEN if total <= limit else Kit.RED
	sks_chip.add_theme_stylebox_override("panel", st)
	go_btn.disabled = total == 0 or total > limit


func _course_toggle(c: Dictionary) -> Control:
	var p := Kit.panel(Color.WHITE, 18, 12)
	var h := Kit.hbox(10)
	p.add_child(h)
	var dot := Icon.make("dot", 26, Kit.BLUE)
	h.add_child(dot)
	var n := Kit.dual(c.name, 22, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	if Game.s.grades.has(c.code):
		h.add_child(Kit.chip(Loc.main(Loc.T("Ulang", "Retake")), Kit.RED, Color.WHITE, 16))
	if c.type == "skripsi":
		h.add_child(Kit.chip(Loc.main(Loc.T("Skripsi", "Thesis")), Kit.ORANGE, Color.WHITE, 16))
	h.add_child(Kit.chip("%d SKS" % c.sks, Color("f3eee4"), Kit.INK, 18))
	var paint := func():
		var on := picked.has(c.code)
		p.add_theme_stylebox_override("panel", Kit.card_style(Color("e6efff") if on else Color.WHITE, 18))
		(p.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(12)
		dot.color = Kit.BLUE if on else Color("d5cfe0")
		dot.queue_redraw()
	paint.call()
	Kit.tap(p, func():
		if picked.has(c.code):
			picked.erase(c.code)
		else:
			picked.append(c.code)
		paint.call()
		Fx.pulse(p, 1.03)
		_update_total())
	return p


# --- War KRS minigame ----------------------------------------------------------

func _start_war() -> void:
	for c in v.get_children():
		c.queue_free()
	rows.clear()
	var portal := Kit.panel(Color("1d3fa8"), 20, 14)
	v.add_child(portal)
	var ph := Kit.vbox(4)
	portal.add_child(ph)
	ph.add_child(Kit.label("SIAKAD · KRS ONLINE", 26, Color.WHITE, Kit.font_bold))
	ph.add_child(Kit.label(Loc.main(Loc.T("Ketuk AMBIL secepatnya sebelum kelas favorit penuh!", "Tap TAKE fast before the good classes fill up!")), 20, Color(1, 1, 1, 0.85), null, HORIZONTAL_ALIGNMENT_LEFT, true))
	timer_bar = Kit.bar(WAR_TIME, WAR_TIME, Kit.YELLOW, 18)
	v.add_child(timer_bar)
	var list := Kit.vbox(8)
	var sc := Kit.scroll(list)
	sc.custom_minimum_size.y = 600
	v.add_child(sc)
	for c in Sim.krs_options(Game.s):
		if not picked.has(c.code) or cls.get(c.code, "") == "A":
			continue
		var r := Kit.panel(Color.WHITE, 16, 10)
		var h := Kit.hbox(10)
		r.add_child(h)
		var n := Kit.label(Loc.main(c.name), 22, Kit.INK, Kit.font_bold, HORIZONTAL_ALIGNMENT_LEFT, true)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		var b := Kit.button(Loc.T("AMBIL", "TAKE"), Kit.GREEN, Callable(), 22, 64)
		b.custom_minimum_size.x = 150
		var code: String = c.code
		Kit.on_tap(b, func(): _take(code, b, r))
		h.add_child(b)
		rows[code] = r
		list.add_child(r)
	Fx.stagger(list, 0.04)
	Fx.pop_in(portal, 0.0, 0.8)
	Audio.play("whoosh", -6.0)
	time_left = WAR_TIME
	war_on = true
	if rows.is_empty():
		_finish_war()


func _take(code: String, b: Button, r: PanelContainer) -> void:
	if not war_on or b.disabled or not is_instance_valid(b):
		return
	if randf() < BUSY_CHANCE:
		Audio.play("glitch", -2.0)
		Audio.play("error", -6.0)
		b.text = "503!"
		Kit.style_button(b, Kit.RED)
		b.disabled = true
		var tw := create_tween()
		var x := r.position.x
		for i in 3:
			tw.tween_property(r, "position:x", x + 10, 0.04)
			tw.tween_property(r, "position:x", x - 10, 0.04)
		tw.tween_property(r, "position:x", x, 0.04)
		await get_tree().create_timer(0.45).timeout
		if is_instance_valid(b) and war_on:
			b.disabled = false
			b.text = Loc.main(Loc.T("AMBIL", "TAKE"))
			Kit.style_button(b, Kit.GREEN)
		return
	cls[code] = "A"
	Audio.play("good", -4.0, 1.0 + 0.05 * cls.size())
	Fx.pulse(r, 1.04)
	b.disabled = true
	b.text = Loc.main(Loc.T("DAPAT", "GOT IT"))
	Kit.style_button(b, Kit.BLUE)
	r.add_theme_stylebox_override("panel", Kit.card_style(Color("e3f7ea"), 16))
	var all := true
	for k in rows:
		if cls.get(k, "") != "A":
			all = false
	if all:
		_finish_war()


func _process(delta: float) -> void:
	if not war_on:
		return
	var before := ceili(time_left)
	time_left -= delta
	timer_bar.value = maxf(0.0, time_left)
	if ceili(time_left) != before and time_left <= 5.0 and time_left > 0.0:
		Audio.play("tick", -2.0, 1.0 + (5.0 - time_left) * 0.06)
		(timer_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Kit.RED
		Fx.pulse(timer_bar, 1.03)
	if time_left <= 0.0:
		_finish_war()


func _finish_war() -> void:
	war_on = false
	Audio.play("bell", -3.0)
	for code in picked:
		if not cls.has(code):
			cls[code] = "B"
	for c in v.get_children():
		c.queue_free()
	var n_b := 0
	for code in picked:
		if cls[code] == "B":
			n_b += 1
	v.add_child(Kit.title(Loc.main(Loc.T("Hasil War KRS", "Registration War Results")), 36))
	var list := Kit.vbox(8)
	var sc := Kit.scroll(list)
	sc.custom_minimum_size.y = 460
	v.add_child(sc)
	for c in Sim.krs_options(Game.s):
		if not picked.has(c.code):
			continue
		var r := Kit.hbox(8)
		var n := Kit.label(Loc.main(c.name), 22, Kit.INK, null, HORIZONTAL_ALIGNMENT_LEFT, true)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(n)
		var good: bool = cls[c.code] == "A"
		Fx.pop_in(r, list.get_child_count() * 0.06)
		r.add_child(Kit.chip(Loc.main(Loc.T("Kelas A", "Class A")) if good else Loc.main(Loc.T("Kelas B · dosen killer", "Class B · strict lecturer")), Kit.GREEN if good else Kit.RED, Color.WHITE, 18))
		list.add_child(r)
	if n_b > 0:
		v.add_child(Kit.dual(Loc.T("Kelas sisa diajar dosen killer: nilai lebih susah.", "Leftover classes are taught by strict lecturers: harder grades."), 20, Kit.RED))
		if not retried and Ads.rewarded_left() > 0:
			v.add_child(Kit.button(Loc.T("Nonton iklan: refresh SIAKAD & coba lagi", "Watch an ad: refresh the portal & retry"), Kit.CYAN, func():
				Ads.show_rewarded("krs_retry", func(ok: bool):
					if ok:
						retried = true
						for code in cls.keys():
							if cls[code] == "B":
								cls.erase(code)
						_start_war()), 22))
	v.add_child(Kit.button(Loc.T("Mulai kuliah!", "Start the semester!"), Kit.GREEN, func():
		Game.confirm_krs(picked, cls)
		main.goto("week"), 28, 84))

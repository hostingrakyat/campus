class_name KhsScreen
extends Screen
## End-of-semester grade report (Kartu Hasil Studi): IPS, IPK, grades per course.

func _ready() -> void:
	var s: Dictionary = Game.s
	var rep: Dictionary = Game.last_report if not Game.last_report.is_empty() else s.history[-1]
	var w: CampusWorld = main.world
	w.player.build(s.look, s.prodi)
	w.player.teleport(w.spots.fakultas + Vector3(0, 0, 0.8))
	w.player.rotation.y = 0
	w.focus(w.player.position + Vector3(0, 1.0, 0), 7.0, true, 0.13)
	w.set_time("siang", true)
	var ips: float = rep.ips
	w.player.say("IPS %.2f%s" % [ips, "!!" if ips >= 3.5 else ("..." if ips < 2.5 else "")], 4.0)

	var v := sheet()
	var head := Kit.hbox(10)
	v.add_child(head)
	head.add_child(Kit.title(Loc.main(Loc.T("KHS Semester %d", "Semester %d Report")) % rep.sem, 38))
	head.add_child(Kit.spacer(0, true))
	var big := Kit.hbox(12)
	v.add_child(big)
	var ips_box := _big_stat("IPS", "0.00", _ip_color(ips))
	var ipk_box := _big_stat("IPK", "0.00", _ip_color(rep.ipk))
	big.add_child(ips_box)
	big.add_child(ipk_box)
	big.add_child(_big_stat("SKS", "%d/144" % rep.sks_total, Kit.INK_SOFT))
	var list := Kit.vbox(6)
	var sc := Kit.scroll(list)
	sc.custom_minimum_size.y = 470
	v.add_child(sc)
	for c in rep.courses:
		var r := Kit.hbox(8)
		var n := Kit.dual(c.name, 21, Kit.INK)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(n)
		r.add_child(Kit.label("%d SKS" % c.sks, 20, Kit.INK_SOFT))
		r.add_child(Kit.chip(c.letter, _grade_color(c.letter), Color.WHITE, 24))
		list.add_child(r)
		if c.get("note", "") == "absen":
			list.add_child(Kit.label(Loc.main(Loc.T("  Kehadiran < 75%, tidak boleh ikut UAS", "  Attendance < 75%, barred from the final")), 18, Kit.RED))
		elif c.get("note", "") == "tunda":
			list.add_child(Kit.label(Loc.main(Loc.T("  Skripsi berlanjut semester depan (T = tunda)", "  Thesis continues next semester (T = pending)")), 18, Kit.ORANGE))
	_reveal(list, ips_box, ipk_box, ips, rep.ipk)
	var btns := Kit.hbox(10)
	v.add_child(btns)
	if s.sem <= 4:
		var pindah := Kit.button(Loc.T("Pindah prodi?", "Switch major?"), Kit.ORANGE, _switch_major, 22)
		btns.add_child(pindah)
	var go := Kit.button(Loc.T("Lanjut  >", "Continue  >"), Kit.GREEN, func():
		if Game.after_khs() == "ending":
			main.goto("ending")
		else:
			main.goto("ukt"), 28, 84)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(go)


func on_back() -> bool:
	return true


func _big_stat(name: String, value: String, color: Color) -> Control:
	var p := Kit.panel(Color.WHITE, 22, 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := Kit.vbox(0)
	p.add_child(v)
	v.add_child(Kit.label(name, 20, Kit.INK_SOFT, Kit.font_bold, HORIZONTAL_ALIGNMENT_CENTER))
	var val := Kit.label(value, 40, color, Kit.font_display, HORIZONTAL_ALIGNMENT_CENTER)
	val.name = "Value"
	v.add_child(val)
	return p


static func _ip_color(ip: float) -> Color:
	if ip >= 3.5:
		return Kit.GREEN
	if ip >= 2.75:
		return Kit.BLUE
	if ip >= 2.0:
		return Kit.ORANGE
	return Kit.RED


static func _grade_color(letter: String) -> Color:
	match letter:
		"A", "AB":
			return Kit.GREEN
		"B", "BC":
			return Kit.BLUE
		"C":
			return Kit.ORANGE
		"T":
			return Color("8a8398")
	return Kit.RED


func _switch_major() -> void:
	var box := ModalCard.new(main, Loc.T("Pindah prodi", "Switch major"), 620)
	box.body.add_child(Kit.dual(Loc.T("Ini mengakhiri cerita di prodi sekarang (ending Pindah Prodi). Kamu mulai lagi dari semester 1 dengan koin tetap terbawa.", "This ends your story in this major (Switched Majors ending). You restart from semester 1, keeping your coins."), 22))
	for id in Data.PRODI:
		if id == Game.s.prodi:
			continue
		var pid: String = id
		box.body.add_child(Kit.button(Data.PRODI[id].name, Data.PRODI[id].color, func():
			Game.switch_major(pid)
			main.goto("ending"), 24))
	main.open_modal(box)


func _reveal(list: VBoxContainer, ips_box: Control, ipk_box: Control, ips: float, ipk: float) -> void:
	var rows := list.get_children()
	for r in rows:
		r.modulate.a = 0.0
	await get_tree().create_timer(0.35).timeout
	for i in rows.size():
		if not is_inside_tree():
			return
		Fx.pop_in(rows[i], 0.0, 0.9, 0.25)
		if rows[i] is HBoxContainer:
			Audio.play("card_place", -10.0, 1.0 + i * 0.03)
		await get_tree().create_timer(0.09).timeout
	var fmt := func(x: float): return "%.2f" % x
	Fx.count(ips_box.find_child("Value", true, false), 0.0, ips, fmt, 0.9)
	Fx.count(ipk_box.find_child("Value", true, false), 0.0, ipk, fmt, 0.9)
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	Fx.pulse(ips_box, 1.15)
	if ips >= 3.5:
		Audio.play("levelup", -3.0)
	elif ips < 2.0:
		Audio.play("fail", -4.0)
	else:
		Audio.play("confirm", -4.0)

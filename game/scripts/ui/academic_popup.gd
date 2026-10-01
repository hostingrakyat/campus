class_name AcademicPopup
extends ModalCard
## Current KRS, thesis progress and the transcript (all semesters' IPS/IPK).

func _init(m: Node) -> void:
	super(m, Loc.T("Akademik", "Academics"), 680)
	var s: Dictionary = Game.s
	var list := scroll_list(860)
	list.ready.connect(func(): Fx.stagger(list, 0.025, 0.1))
	var sum := Kit.hbox(8)
	list.add_child(sum)
	sum.add_child(Kit.chip("IPK " + ("-" if s.history.is_empty() else "%.2f" % Sim.ipk(s)), Kit.BLUE, Color.WHITE, 22))
	sum.add_child(Kit.chip("SKS %d/144" % Sim.sks_lulus(s), Kit.INK_SOFT, Color.WHITE, 22))
	sum.add_child(Kit.chip(Loc.main(Loc.T("Prodi %s", "Major: %s")) % Loc.main(Data.PRODI[s.prodi].name), Data.PRODI[s.prodi].color, Color.WHITE, 22))
	if s.skripsi:
		var sk := Kit.panel(Color("fff1db"), 20, 14)
		var sv := Kit.vbox(6)
		sk.add_child(sv)
		sv.add_child(Kit.label(Loc.main(Loc.T("Skripsi", "Thesis")) + (" · " + Data.NPCS[s.dospem].name if s.dospem != "" else ""), 24, Kit.INK, Kit.font_bold))
		if s.skripsi_done:
			sv.add_child(Kit.label(Loc.main(Loc.T("LULUS SIDANG!", "DEFENSE PASSED!")), 22, Kit.GREEN, Kit.font_bold))
		else:
			sv.add_child(Kit.label(Loc.main(Loc.T("Draf", "Draft")) + " %d%%" % int(s.draft), 20, Kit.INK_SOFT))
			sv.add_child(Kit.bar(s.draft, 100, Kit.ORANGE, 12))
			sv.add_child(Kit.label(Loc.main(Loc.T("ACC Dospem", "Advisor approval")) + " %d%%" % int(s.acc), 20, Kit.INK_SOFT))
			sv.add_child(Kit.bar(s.acc, 100, Kit.GREEN, 12))
		list.add_child(sk)
	list.add_child(Kit.title(Loc.main(Loc.T("KRS Semester Ini", "This Semester's Courses")), 28))
	for c in s.krs:
		var r := row_card()
		list.add_child(r.get_parent())
		var n := Kit.dual(c.name, 22, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(n)
		r.add_child(Kit.chip("%d SKS" % c.sks, Color("f3eee4"), Kit.INK, 18))
		r.add_child(Kit.chip(Loc.main(Loc.T("Kelas A", "Class A")) if c.cls == "A" else Loc.main(Loc.T("Kelas B (killer)", "Class B (strict)")), Kit.GREEN if c.cls == "A" else Kit.RED, Color.WHITE, 18))
	list.add_child(Kit.title(Loc.main(Loc.T("Transkrip", "Transcript")), 28))
	if s.history.is_empty():
		list.add_child(Kit.label(Loc.main(Loc.T("Belum ada nilai. Semangat semester pertama!", "No grades yet. Good luck in your first semester!")), 20, Kit.INK_SOFT))
	for h in s.history:
		var r := row_card(Color("f7f3ff"))
		list.add_child(r.get_parent())
		r.add_child(Kit.label("Sem %d" % h.sem, 22, Kit.INK, Kit.font_bold))
		if h.get("cuti", false):
			r.add_child(Kit.label(Loc.main(Loc.T("Cuti", "On leave")), 22, Kit.INK_SOFT))
			continue
		var sp := Kit.spacer(0, true)
		r.add_child(sp)
		r.add_child(Kit.label("IPS %.2f" % h.ips, 22, Kit.INK))
		r.add_child(Kit.label("IPK %.2f" % h.ipk, 22, Kit.BLUE, Kit.font_bold))

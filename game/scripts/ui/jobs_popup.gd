class_name JobsPopup
extends ModalCard
## Part-time job board. One contract at a time; its shift auto-fills that slot every week.

var list: VBoxContainer


func _init(m: Node) -> void:
	super(m, Loc.T("Papan Lowongan Part-time", "Part-time Job Board"), 680)
	body.add_child(Kit.dual(Loc.T("Shift kerja otomatis mengisi slotnya tiap minggu. Bolos kerja 3x = dipecat. Ojol bisa diambil kapan saja tanpa kontrak.", "Your shift auto-fills its slot every week. Skip 3 shifts = fired. Ride-hailing can be picked any time, no contract."), 20, Kit.INK_SOFT))
	list = scroll_list(700)
	_refresh()


func _refresh() -> void:
	for c in list.get_children():
		c.queue_free()
	var s: Dictionary = Game.s
	for id in Data.JOBS:
		var j: Dictionary = Data.JOBS[id]
		var mine: bool = s.job == id
		var p := Kit.panel(Color("e6efff") if mine else Color.WHITE, 22, 16)
		var v := Kit.vbox(6)
		p.add_child(v)
		var h := Kit.hbox(8)
		v.add_child(h)
		var n := Kit.dual(j.name, 25, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(Kit.chip(Loc.main(Data.SLOT_NAMES[j.slot]), HudScreen.SLOT_COLORS[j.slot], Color.WHITE, 18))
		v.add_child(Kit.dual(j.desc, 20, Kit.INK_SOFT))
		var chips := HFlowContainer.new()
		chips.add_theme_constant_override("h_separation", 6)
		chips.add_theme_constant_override("v_separation", 6)
		for f in Kit.fx_text({"coins": j.pay, "energy": j.energy, "mental": j.mental}):
			chips.add_child(Kit.chip(f.text, Color("e3f7ea") if f.good else Color("ffe6e3"), Color("17643a") if f.good else Color("b3261e"), 18))
		if j.slot == "pagi":
			chips.add_child(Kit.chip(Loc.main(Loc.T("BENTROK KULIAH PAGI", "CLASHES WITH MORNING CLASS")), Kit.RED, Color.WHITE, 18))
		v.add_child(chips)
		var block := Game.job_block_reason(id)
		if mine:
			v.add_child(Kit.label(Loc.main(Loc.T("Pekerjaanmu sekarang · izin %d/3", "Your current job · skipped %d/3")) % s.job_izin, 20, Kit.BLUE, Kit.font_bold))
			v.add_child(Kit.button(Loc.T("Resign", "Quit"), Kit.RED, func():
				Game.quit_job()
				_refresh(), 22))
		elif not block.is_empty():
			v.add_child(Kit.dual(block, 20, Kit.RED, HORIZONTAL_ALIGNMENT_LEFT, true))
		else:
			v.add_child(Kit.button(Loc.T("Lamar & mulai kerja" if s.job == "" else "Pindah ke sini", "Apply & start" if s.job == "" else "Switch to this job"), Kit.GREEN, func():
				Game.take_job(id)
				main.toast(Loc.T("Diterima kerja! Shift mulai minggu ini.", "Hired! Your shift starts this week."), Kit.GREEN)
				_refresh(), 22))
		list.add_child(p)

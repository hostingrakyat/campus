class_name ActionPicker
extends ModalCard

signal picked(id: String)


func _init(m: Node, slot: String, current: String) -> void:
	super(m, Loc.T("Pilih aktivitas · %s" % Data.SLOT_NAMES[slot].id, "Choose activity · %s" % Data.SLOT_NAMES[slot].en))
	var list := scroll_list(820)
	for id in Sim.available_actions(Game.s, slot):
		list.add_child(_option(id, id == current))


func _option(id: String, selected: bool) -> Control:
	var a: Dictionary = Data.ACTIONS[id]
	var name_pair: Dictionary = a.name
	var desc: Dictionary = a.desc
	var fx: Dictionary = a.fx
	if id == "kerja":
		var j: Dictionary = Data.JOBS[Game.s.job]
		name_pair = j.name
		desc = Loc.T("Shift kerja kamu. Gaji %d koin." % j.pay, "Your work shift. Pays %d coins." % j.pay)
		fx = {"coins": j.pay, "energy": j.energy, "mental": j.mental}
	var p := Kit.panel(Color("e6efff") if selected else Color.WHITE, 22, 14)
	var v := Kit.vbox(6)
	p.add_child(v)
	v.add_child(Kit.dual(name_pair, 28, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true))
	v.add_child(Kit.dual(desc, 20, Kit.INK_SOFT))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	for f in Kit.fx_text(fx):
		chips.add_child(Kit.chip(f.text, Color("e3f7ea") if f.good else Color("ffe6e3"), Color("17643a") if f.good else Color("b3261e"), 18))
	if id == "bolos":
		chips.add_child(Kit.chip(Loc.main(Loc.T("Absen bolong", "Missed attendance")), Color("ffe6e3"), Color("b3261e"), 18))
	v.add_child(chips)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			picked.emit(id))
	return p

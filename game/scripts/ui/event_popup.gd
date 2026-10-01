class_name EventPopup
extends ModalCard
## Story card: speaker, situation, choices; then the outcome.

signal done

var ev: Dictionary


func _init(m: Node, e: Dictionary) -> void:
	super(m, {}, 660, false)
	ev = e
	for c in body.get_children():
		c.queue_free()
	var s: Dictionary = Game.s
	var npc: Dictionary = Data.NPCS.get(ev.speaker, Data.NPCS.narator)
	if ev.speaker != "narator":
		var h := Kit.hbox(14)
		body.add_child(h)
		h.add_child(Kit.avatar(ev.speaker, 88))
		var who := Kit.vbox(0)
		who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		who.add_child(Kit.label(npc.name, 30, Kit.INK, Kit.font_bold))
		who.add_child(Kit.dual(npc.role, 20, Kit.INK_SOFT))
		h.add_child(who)
	var dospem_name: String = Data.NPCS[s.dospem].name if s.dospem != "" else "-"
	var text := Loc.fill(ev.text, {"name": s.name, "dospem": dospem_name})
	var bubble := Kit.panel(Color.WHITE, 24, 20)
	bubble.add_child(Kit.dual(text, 27))
	body.add_child(bubble)
	for i in ev.choices.size():
		var ch: Dictionary = ev.choices[i]
		var b := Kit.button(ch.label, [Kit.BLUE, Kit.PURPLE, Kit.ORANGE][i % 3], func(): _choose(i), 23)
		body.add_child(b)


func _choose(i: int) -> void:
	var r := Game.choose(ev, i)
	for c in body.get_children():
		c.queue_free()
	var head := Kit.title(Loc.main(Loc.T("Hasilnya...", "Outcome...")), 34, Kit.GREEN if r.success else Kit.RED)
	body.add_child(head)
	var bubble := Kit.panel(Color.WHITE, 24, 20)
	bubble.add_child(Kit.dual(r.result, 27))
	body.add_child(bubble)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	for f in Kit.fx_text(r.fx):
		chips.add_child(Kit.chip(f.text, Color("e3f7ea") if f.good else Color("ffe6e3"), Color("17643a") if f.good else Color("b3261e"), 20))
	body.add_child(chips)
	body.add_child(Kit.button(Loc.T("Lanjut", "Continue"), Kit.GREEN, func():
		main.close_top_modal()
		done.emit(), 26))

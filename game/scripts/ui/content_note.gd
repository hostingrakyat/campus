class_name ContentNote
extends PanelContainer
## First-launch note: fiction disclaimer + mental-health resources (shown once, re-openable from Settings).

var main: Node


func _init(m: Node) -> void:
	main = m
	add_theme_stylebox_override("panel", Kit.card_style(Kit.PAPER, 32))
	custom_minimum_size = Vector2(640, 0)
	var v := Kit.vbox(16)
	add_child(v)
	v.add_child(Kit.title(Loc.main(Loc.T("Sebelum mulai", "Before you start")), 40))
	v.add_child(Kit.dual(Loc.T(
		"Mahasigma Simulator adalah satire fiksi. Semua kampus, dosen, dan staf di sini rekaan; kemiripan hanya kebetulan (atau terlalu relatable).",
		"Mahasigma Simulator is fictional satire. Every campus, lecturer and staff member here is made up; any resemblance is coincidental (or just too relatable)."), 24))
	v.add_child(Kit.dual(Loc.T(
		"Game ini menyentuh tema kesehatan mental, termasuk ending yang sedih. Jaga energi & mentalmu di game, dan di dunia nyata juga.",
		"This game touches on mental health, including a sad ending. Look after your energy and mental health in the game, and in real life too."), 24))
	var help := Kit.panel(Color("e8f8ee"), 22, 18)
	help.add_child(Kit.dual(Loc.T(
		"Butuh teman cerita? Healing119: telepon 119 ext 8 atau healing119.id (Kemenkes RI). Kamu tidak sendirian.",
		"Need someone to talk to? In Indonesia: Healing119, call 119 ext 8 or visit healing119.id. Elsewhere, contact your local crisis line. You're not alone."), 23, Color("17643a")))
	v.add_child(help)
	v.add_child(Kit.button(Loc.T("Paham, ayo mulai", "Got it, let's go"), Kit.BLUE, func():
		Meta.settings["content_note_seen"] = true
		Meta.save_meta()
		main.close_top_modal()))

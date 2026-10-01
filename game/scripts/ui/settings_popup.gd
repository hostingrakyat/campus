class_name SettingsPopup
extends ModalCard
## Language (dual subtitle) settings, content note, credits, and exit-to-title in-game.

func _init(m: Node, in_game: bool = false) -> void:
	super(m, Loc.T("Pengaturan", "Settings"), 640)
	body.add_child(Kit.label(Loc.main(Loc.T("Bahasa & Subtitle", "Language & Subtitles")), 24, Kit.INK, Kit.font_bold))
	for i in Loc.MODE_NAMES.size():
		var idx := i
		body.add_child(Kit.button(Loc.MODE_NAMES[i], Kit.BLUE if Loc.mode == i else Color("ddd5e8"), func():
			Loc.set_mode(idx)
			main.close_top_modal()
			main.open_modal(SettingsPopup.new(main, in_game)), 22))
	body.add_child(Kit.button(Loc.T("Catatan konten & bantuan", "Content note & support"), Kit.GREEN, func():
		main.close_top_modal()
		main.open_modal(ContentNote.new(main)), 22))
	if in_game:
		body.add_child(Kit.button(Loc.T("Simpan & kembali ke judul", "Save & return to title"), Kit.ORANGE, func():
			Game.save_run()
			main.goto("title"), 22))
	body.add_child(Kit.label("Mahasigma Simulator v0.1.0 · Godot 4.7 · Fonts: Fredoka & Nunito (SIL OFL)", 16, Kit.INK_SOFT, null, HORIZONTAL_ALIGNMENT_CENTER, true))

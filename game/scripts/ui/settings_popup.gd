class_name SettingsPopup
extends ModalCard
## Language (dual subtitle) settings, content note, credits, and exit-to-title in-game.

func _init(m: Node, in_game: bool = false) -> void:
	super(m, Loc.T("Pengaturan", "Settings"), 640)
	body.add_child(Kit.label(Loc.main(Loc.T("Suara", "Sound")), 24, Kit.INK, Kit.font_bold))
	body.add_child(_slider(Loc.T("Musik", "Music"), "music"))
	body.add_child(_slider(Loc.T("Efek suara", "Sound effects"), "sfx"))
	body.add_child(Kit.label(Loc.main(Loc.T("Permainan", "Gameplay")), 24, Kit.INK, Kit.font_bold))
	var mg_on: bool = Meta.settings.get("minigames", true)
	body.add_child(Kit.button(Loc.T("Mini-game saat kegiatan: %s" % ("NYALA" if mg_on else "MATI"), "Activity mini-games: %s" % ("ON" if mg_on else "OFF")), Kit.PURPLE if mg_on else Color("ddd5e8"), func():
		Meta.settings["minigames"] = not Meta.settings.get("minigames", true)
		Meta.save_meta()
		main.close_top_modal()
		main.open_modal(SettingsPopup.new(main, in_game)), 22))
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
	body.add_child(Kit.label("Mahasigma Simulator v0.4.0 · Godot 4.7 · Fonts: Fredoka & Nunito (SIL OFL) · SFX: Kenney (CC0) · Musik orisinal", 16, Kit.INK_SOFT, null, HORIZONTAL_ALIGNMENT_CENTER, true))


func _slider(name: Dictionary, kind: String) -> Control:
	var h := Kit.hbox(12)
	var l := Kit.label(Loc.main(name), 22, Kit.INK)
	l.custom_minimum_size.x = 180
	h.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = Audio.volume(kind)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.custom_minimum_size.y = 48
	var track := StyleBoxFlat.new()
	track.bg_color = Color("e2d8c6")
	track.set_corner_radius_all(8)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	var fill := track.duplicate()
	fill.bg_color = Kit.GREEN if kind == "music" else Kit.BLUE
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	knob.fill(Color(0, 0, 0, 0))
	for y in 40:
		for x in 40:
			var d := Vector2(x - 19.5, y - 19.5).length()
			if d < 18:
				knob.set_pixel(x, y, Color.WHITE if d < 14 else Kit.INK)
	var tex := ImageTexture.create_from_image(knob)
	sl.add_theme_icon_override("grabber", tex)
	sl.add_theme_icon_override("grabber_highlight", tex)
	var pct := Kit.label("%d%%" % int(sl.value * 100), 20, Kit.INK_SOFT, Kit.font_bold)
	pct.custom_minimum_size.x = 64
	sl.value_changed.connect(func(v: float):
		Audio.set_volume(kind, v)
		pct.text = "%d%%" % int(v * 100)
		if kind == "sfx":
			Audio.play("tick", 0.0))
	sl.drag_ended.connect(func(_c: bool): Meta.save_meta())
	h.add_child(sl)
	h.add_child(pct)
	return h

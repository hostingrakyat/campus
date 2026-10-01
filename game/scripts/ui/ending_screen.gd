class_name EndingScreen
extends Screen
## One of 10 endings: title card, story, run stats, gallery unlock, and (for sensitive endings) support info.

const TONES := {
	"gold": Color("ffb020"), "good": Color("2fbf71"), "neutral": Color("2f6bff"),
	"bad": Color("ff5a4e"), "care": Color("33a06b"), "sad": Color("4b4e6d"),
}
const DO_REASONS := {
	"ukt": {"id": "Tidak sanggup membayar UKT", "en": "Couldn't pay the tuition"},
	"masa_studi": {"id": "Masa studi 14 semester habis", "en": "Ran out the 14-semester study limit"},
	"evaluasi": {"id": "Gagal evaluasi studi semester 4", "en": "Failed the semester-4 academic review"},
	"ips": {"id": "IPS di bawah 1.00 dua semester berturut-turut", "en": "GPA under 1.00 two semesters in a row"},
	"jual_nilai": {"id": "Terlibat kasus jual-beli nilai", "en": "Caught in a grade-buying scandal"},
}


func _ready() -> void:
	var s: Dictionary = Game.s
	var id: String = s.ending
	var e: Dictionary = Data.endings[id]
	var first := Game.finalize_ending()
	var w: CampusWorld = main.world
	var look: Dictionary = s.look.duplicate()
	var graduated := ["summa", "balance", "cumlaude", "tepat", "telat", "abadi"].has(id)
	if graduated:
		look["head"] = "head_toga"
	w.player.build(look, s.prodi)
	match id:
		"padam":
			w.set_time("malam", true)
			w.lamps_off()
			w.player.visible = false
			w.focus(w.spots.kos + Vector3(-0.8, 2.0, -3.0), 9.0, true, 0.16)
		"rawat":
			w.set_time("pagi", true)
			w.player.teleport(w.spots.rektorat + Vector3(0, 0, 1.2))
			w.focus(w.player.position + Vector3(0, 1.0, 0), 7.0, true, 0.14)
		"do":
			w.set_time("malam", true)
			w.player.teleport(w.spots.jalan)
			w.focus(w.player.position + Vector3(0, 1.0, 0), 7.0, true, 0.14)
		_:
			w.set_time("siang", true)
			w.player.teleport(w.spots.lapangan)
			w.player.rotation.y = 0
			w.focus(w.player.position + Vector3(0, 1.0, 0), 6.0, true, 0.13)
	if graduated:
		_confetti()

	var tone: Color = TONES.get(e.tone, Kit.BLUE)
	var v := sheet()
	var badge := Kit.hbox(8)
	v.add_child(badge)
	badge.add_child(Kit.chip("ENDING", tone, Color.WHITE, 20))
	if first:
		badge.add_child(Kit.chip(Loc.main(Loc.T("BARU TERBUKA!", "NEW UNLOCK!")), Kit.YELLOW, Kit.INK, 20))
	var t := Kit.title(Loc.main(e.title), 50, tone.darkened(0.1))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var prodi_name: Dictionary = Data.PRODI[s.prodi].name
	var args := {
		"name": s.name, "sem": s.sem, "ipk": "%.2f" % Sim.ipk(s), "prodi": prodi_name,
		"predikat": Sim.predikat(s), "reason": DO_REASONS.get(s.ending_reason, {"id": "", "en": ""}),
	}
	v.add_child(Kit.dual(Loc.fill(e.subtitle, args), 24, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var story := Kit.panel(Color.WHITE, 22, 18)
	var sv := Kit.vbox(10)
	story.add_child(sv)
	sv.add_child(Kit.dual(Loc.fill(e.text, args), 23))
	var sc := Kit.scroll(story)
	sc.custom_minimum_size.y = 330
	v.add_child(sc)
	if id == "padam" or id == "rawat":
		var help := Kit.panel(Color("e8f8ee"), 20, 16)
		help.add_child(Kit.dual(Loc.T(
			"Kalau kamu atau temanmu sedang merasa seperti ini, kamu tidak sendirian. Hubungi Healing119: telepon 119 ext 8 atau healing119.id. Di game ini, konseling kampus selalu gratis. Di dunia nyata pun ada yang mau mendengar.",
			"If you or a friend feel this way, you're not alone. In Indonesia, contact Healing119: call 119 ext 8 or visit healing119.id; elsewhere, reach out to your local crisis line. Campus counseling is always free in this game, and in real life someone is willing to listen too."), 21, Color("17643a")))
		v.add_child(help)
	var stats := HFlowContainer.new()
	stats.add_theme_constant_override("h_separation", 8)
	stats.add_theme_constant_override("v_separation", 8)
	v.add_child(stats)
	stats.add_child(Kit.chip("IPK %.2f" % Sim.ipk(s), Kit.BLUE, Color.WHITE, 20))
	stats.add_child(Kit.chip("Semester %d" % s.sem, Kit.INK_SOFT, Color.WHITE, 20))
	stats.add_child(Kit.chip("SKS %d" % Sim.sks_lulus(s), Kit.INK_SOFT, Color.WHITE, 20))
	stats.add_child(Kit.chip(Loc.main(Loc.T("Gaji total %s", "Total wages %s")) % Kit.fmt(s.stats.wages), Kit.GREEN, Color.WHITE, 20))
	stats.add_child(Kit.chip(Loc.main(Loc.T("Khilaf belanja %s", "Impulse buys %s")) % Kit.fmt(s.stats.spent_khilaf), Kit.PINK, Color.WHITE, 20))
	var btns := Kit.hbox(10)
	v.add_child(btns)
	var again := Kit.button(Loc.T("Main lagi", "Play again"), Kit.GREEN, func():
		if id == "pindah":
			main.goto("create", {"prodi": s.flags.get("pindah_to", "IF"), "carry": maxi(0, int(s.coins))})
		else:
			main.goto("create"), 26, 80)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(again)
	btns.add_child(Kit.button(Loc.T("Galeri", "Gallery"), Kit.PURPLE, func(): main.goto("gallery"), 22, 80))
	btns.add_child(Kit.button(Loc.T("Judul", "Title"), Color("8a8398"), func(): main.goto("title"), 22, 80))


func _exit_tree() -> void:
	main.world.player.visible = true


func on_back() -> bool:
	main.goto("title")
	return true


func _confetti() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(360, -20)
	p.amount = 90
	p.lifetime = 4.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(380, 10)
	p.direction = Vector2(0, 1)
	p.spread = 25.0
	p.gravity = Vector2(0, 180)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 200.0
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	p.scale_amount_min = 6.0
	p.scale_amount_max = 12.0
	var g := Gradient.new()
	g.set_color(0, Kit.YELLOW)
	g.add_point(0.33, Kit.PINK)
	g.add_point(0.66, Kit.CYAN)
	g.set_color(g.get_point_count() - 1, Kit.GREEN)
	p.color_initial_ramp = g
	add_child(p)

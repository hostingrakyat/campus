class_name UktScreen
extends Screen
## Start of semester: pay tuition (UKT) — parents, savings, appeal, scholarship, loan app, leave, or give up.

var v: VBoxContainer


func _ready() -> void:
	var w: CampusWorld = main.world
	w.player.build(Game.s.look, Game.s.prodi)
	w.player.teleport(w.spots.rektorat + Vector3(0, 0, 1.0))
	w.player.rotation.y = PI
	w.focus(w.player.position + Vector3(0, 1.0, 0), 8.0, true, 0.2)
	w.set_time("pagi", true)
	v = sheet()
	_build()
	for n in Game.pending_notes:
		main.toast(n, Kit.INK, 3.0)
	Game.pending_notes = []
	if Game.s.flags.get("phk_new", false):
		for ev in Data.events:
			if ev.id == "phk":
				var pop := EventPopup.new(main, ev)
				main.open_modal(pop, false)
				pop.done.connect(_build)
				break


func on_back() -> bool:
	main.open_modal(SettingsPopup.new(main, true))
	return true


func _build() -> void:
	for c in v.get_children():
		c.queue_free()
	var s: Dictionary = Game.s
	var due := Sim.ukt_due(s)
	var head := Kit.hbox(10)
	v.add_child(head)
	head.add_child(Kit.title(Loc.main(Loc.T("Semester %d dimulai!", "Semester %d begins!")) % s.sem, 38))
	head.add_child(Kit.spacer(0, true))
	head.add_child(Kit.currency_chip("coin", s.coins))
	var card := Kit.panel(Color.WHITE, 24, 18)
	v.add_child(card)
	var cv := Kit.vbox(6)
	card.add_child(cv)
	cv.add_child(Kit.label(Loc.main(Loc.T("Tagihan UKT semester ini", "This semester's tuition (UKT)")), 22, Kit.INK_SOFT))
	var amt := Kit.hbox(8)
	amt.add_child(Icon.make("coin", 48))
	amt.add_child(Kit.title(Kit.fmt(due), 52, Kit.INK))
	if s.ukt_mult < 1.0:
		amt.add_child(Kit.chip(Loc.main(Loc.T("Hasil banding", "Appeal result")), Kit.GREEN, Color.WHITE, 18))
	if due == 0:
		amt.add_child(Kit.chip(Loc.main(Loc.T("Beasiswa", "Scholarship")), Kit.GREEN, Color.WHITE, 18))
	cv.add_child(amt)
	if s.debt > 0:
		cv.add_child(Kit.label(Loc.main(Loc.T("Utang pinjol: %s koin", "Loan app debt: %s coins")) % Kit.fmt(s.debt), 20, Kit.RED, Kit.font_bold))
	if s.ukt_paid:
		var paid := Kit.label(Loc.main(Loc.T("LUNAS", "PAID")), 30, Kit.GREEN, Kit.font_bold)
		cv.add_child(paid)
		Fx.pop_in(paid, 0.1, 0.4, 0.4)
		v.add_child(Kit.button(Loc.T("Lanjut isi KRS  >", "Continue to course registration  >"), Kit.GREEN, func():
			Game.s.phase = "krs"
			Game.touch()
			main.goto("krs"), 28, 84))
		return

	var opts := Kit.vbox(10)
	v.add_child(Kit.scroll(opts))
	opts.get_parent().custom_minimum_size.y = 520
	if s.parents_pay_ukt:
		opts.add_child(_opt(Loc.T("Dibayar Ortu", "Parents pay"), Kit.GREEN, "parents"))
	else:
		opts.add_child(_opt(Loc.T("Bayar pakai tabungan (%s)" % Kit.fmt(due), "Pay from savings (%s)" % Kit.fmt(due)), Kit.GREEN, "coins", s.coins >= due))
		if not s.ukt_tried.get("banding", false) and s.ukt_mult > 0.25:
			opts.add_child(_opt(Loc.T("Ajukan banding UKT (antre 7 loket)", "Appeal the tuition (7 counters)"), Kit.BLUE, "banding"))
		if not s.ukt_tried.get("beasiswa", false):
			var min_ipk := 3.0 if s.flags.get("phk", false) else 3.5
			opts.add_child(_opt(Loc.T("Daftar beasiswa (IPK min %.2f)" % min_ipk, "Apply for scholarship (GPA %.2f+)" % min_ipk), Kit.PURPLE, "beasiswa"))
		if not s.flags.get("om_%d" % s.sem, false) and Ads.rewarded_left() > 0:
			opts.add_child(Kit.button(Loc.T("Nonton iklan: transferan dari Om (+300)", "Watch an ad: money from your uncle (+300)"), Kit.CYAN, _om, 22))
		opts.add_child(Kit.button(Loc.T("Tukar diamond jadi koin", "Exchange diamonds for coins"), Kit.CYAN, func(): main.open_modal(ShopPopup.new(main, "exchange")), 22))
		if s.debt == 0:
			opts.add_child(_opt(Loc.T("Pinjol DanaKilat (utang 150%)", "DanaKilat loan app (150% debt)"), Kit.RED, "pinjol"))
		if s.cuti_used < Data.MAX_CUTI:
			opts.add_child(_opt(Loc.T("Cuti 1 semester, kerja full-time (sisa %d)" % (Data.MAX_CUTI - s.cuti_used), "Take a leave semester, work full-time (%d left)" % (Data.MAX_CUTI - s.cuti_used)), Kit.ORANGE, "cuti"))
		opts.add_child(Kit.button(Loc.T("Nggak sanggup bayar...", "I can't pay..."), Color("8a8398"), _give_up, 20))
	if not has_meta("shown"):
		set_meta("shown", true)
		Fx.stagger(opts, 0.04, 0.15)


func _opt(label: Dictionary, color: Color, method: String, enabled: bool = true) -> Button:
	var b := Kit.button(label, color, func():
		var before: int = Game.s.coins
		var r := Game.pay_ukt(method)
		main.toast(r.msg, Kit.GREEN if r.ok else Kit.RED, 3.2)
		if r.ok:
			Audio.play("spend" if Game.s.coins < before else "confirm", -3.0)
			if Game.s.ukt_paid:
				Audio.play("levelup", -6.0)
		else:
			Audio.play("error", -4.0)
		_build(), 22)
	b.disabled = not enabled
	return b


func _om() -> void:
	Ads.show_rewarded("ukt_om", func(ok: bool):
		if ok:
			Game.s.coins += 300
			Game.s.flags["om_%d" % Game.s.sem] = true
			Game.touch()
			main.toast(Loc.T("Om transfer 300 koin. \"Belajar yang rajin ya!\"", "Uncle sent 300 coins. \"Study hard!\""), Kit.GREEN)
		_build())


func _give_up() -> void:
	var box := ModalCard.new(main, Loc.T("Yakin?", "Are you sure?"), 580)
	box.body.add_child(Kit.dual(Loc.T("Tanpa membayar UKT, status kamu jadi tidak aktif (Drop Out).", "Without paying tuition, your status becomes inactive (Dropped Out)."), 24))
	box.body.add_child(Kit.button(Loc.T("Ya, berhenti kuliah", "Yes, leave college"), Kit.RED, func():
		Game.s.ending = "do"
		Game.s.ending_reason = "ukt"
		Game.s.phase = "ending"
		main.goto("ending")))
	box.body.add_child(Kit.button(Loc.T("Coba cara lain", "Try another way"), Kit.GREEN, func(): main.close_top_modal()))
	main.open_modal(box)

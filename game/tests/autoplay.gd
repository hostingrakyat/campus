class_name Autoplay
extends RefCounted
## Drives the real UI like a (diligent but impatient) player: taps the first sensible button on every
## screen and modal until an ending appears. Catches runtime errors in UI flows.
## Run: godot --headless -- --shot=autoplay

static func run(main: Node) -> void:
	Engine.time_scale = 12.0
	var seed_txt := OS.get_environment("AUTOPLAY_SEED")
	if seed_txt != "":
		seed(int(seed_txt))
	Game.new_run("Bot", ["IF", "MN", "KD"][randi() % 3], Data.DEFAULT_LOOK)
	main.goto("ukt")
	var steps := 0
	var last_week := ""
	while steps < 80000:
		steps += 1
		await main.get_tree().process_frame
		var ad := _find_ad_close(main.get_tree().root)
		if ad:
			ad.pressed.emit()
			continue
		if main.has_modal():
			var top: Control = main._modals[-1]
			var b := _first_button(top, ["X"])
			if b:
				b.pressed.emit()
				await main.get_tree().process_frame
			continue
		var scr: Control = main.screen
		if scr is EndingScreen:
			print("AUTOPLAY ENDING: %s/%s %s sem %d ipk %.2f coins %d debt %d cuti %d steps %d" % [Game.s.ending, Game.s.ending_reason, Game.s.prodi, Game.s.sem, Sim.ipk(Game.s), Game.s.coins, Game.s.debt, Game.s.cuti_used, steps])
			break
		elif scr is UktScreen:
			var s: Dictionary = Game.s
			if s.ukt_paid:
				_press_text(scr, ["Lanjut", "Continue"])
			else:
				for m in ["parents", "coins", "beasiswa", "banding", "cuti", "pinjol"]:
					Game.pay_ukt(m)
					if Game.s.ukt_paid or Game.s.phase == "ending":
						break
				if Game.s.phase == "ending":
					main.goto("ending")
				else:
					scr._build()
				if not Game.s.ukt_paid and Game.s.phase != "ending":
					Game.s.ending = "do"
					Game.s.ending_reason = "ukt"
					Game.s.phase = "ending"
					main.goto("ending")
		elif scr is KrsScreen:
			if scr.war_on:
				for code in scr.rows:
					if scr.cls.get(code, "") != "A":
						var btn := _first_button(scr.rows[code], [])
						if btn and not btn.disabled:
							scr._take(code, btn, scr.rows[code])
			else:
				if not _press_text(scr, ["Ikut War", "Enter the"]):
					_press_text(scr, ["Mulai kuliah", "Start the semester"])
		elif scr is HudScreen:
			if scr._game:
				scr._game.bot_play()
			if not scr.running:
				var s: Dictionary = Game.s
				var tag := "%d-%d" % [s.sem, s.week]
				if tag != last_week:
					last_week = tag
					if s.job == "" and s.flags.get("phk", false):
						Game.take_job("minimarket")
					scr.plan = Sim.default_plan(s)
					if s.mental < 45 and Sim.available_actions(s, "siang").has("konseling"):
						scr.plan[1] = "konseling"
					if s.energy < 40:
						scr.plan[3] = "tidur"
					scr._run_week()
		elif scr is KhsScreen:
			_press_text(scr, ["Lanjut", "Continue"])
	Engine.time_scale = 1.0
	print("AUTOPLAY DONE steps=%d" % steps)
	main.get_tree().quit()


static func _first_button(n: Node, skip: Array) -> Button:
	for c in n.get_children():
		if c is Button and c.visible and not c.disabled and not skip.has(c.text) and not c.get_meta("close", false):
			return c
		var r := _first_button(c, skip)
		if r:
			return r
	return null


static func _press_text(n: Node, prefixes: Array) -> bool:
	for c in n.find_children("*", "Button", true, false):
		for p in prefixes:
			if c.text.begins_with(p) and not c.disabled and c.visible:
				c.pressed.emit()
				return true
	return false


static func _find_ad_close(root: Node) -> Button:
	for c in root.get_children():
		if c is CanvasLayer and c.layer == 120:
			for b in c.find_children("*", "Button", true, false):
				if b.visible:
					return b
	return null

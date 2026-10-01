class_name Shots
extends RefCounted
## Dev helper: `godot -- --shot=<scene> --out=/abs/path.png` renders one screen and quits.
## Used for automated visual checks and store screenshots.

static func run(main: Node, shot: String, out: String) -> void:
	Meta.settings["content_note_seen"] = true
	var lang := OS.get_environment("SHOT_LANG")
	if lang != "":
		Loc.set_mode(int(lang))
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var look := {"skin": 1, "hair": "hair_hijab", "hair_color": 4, "top": "top_almamater", "head": "head_none", "face": "face_round", "back": "back_ransel", "aura": "aura_none"}
	if shot.ends_with("_m"):
		look = {"skin": 2, "hair": "hair_fringe", "hair_color": 0, "top": "top_flanel", "head": "head_none", "face": "face_none", "back": "back_ransel", "aura": "aura_none"}
		shot = shot.trim_suffix("_m")
	if shot == "icon":
		await _icon(main, out)
		return
	if shot == "autoplay":
		Autoplay.run(main)
		return
	if shot == "demo":
		await _demo(main)
		return
	match shot:
		"title":
			main.goto("title")
		"note":
			main.goto("title")
			main.open_modal(ContentNote.new(main), false)
		"create":
			main.goto("create")
		"ukt", "ukt_phk", "krs", "war", "week", "weekrun", "settings", "event", "picker", "shop", "wardrobe", "jobs", "academic", "khs", "ending_balance", "ending_padam", "ending_rawat", "ending_do", "gallery":
			Game.new_run("Ayu", "IF", look)
			Game.s.coins = 1850
			Meta.diamonds = 125
			if shot == "ukt_phk":
				Game.s.sem = 3
				Game.s.history = [{"sem": 1, "ips": 3.8, "ipk": 3.8, "sks_sem": 18, "sks_total": 18, "courses": []}]
				Game.s.grades = {"IF101": {"letter": "A", "point": 4.0, "sks": 3}}
				Sim.enter_semester(Game.s)
				Game.s.phk_sem = 3
				Sim.enter_semester(Game.s)
				main.goto("ukt")
			elif shot == "ukt":
				main.goto("ukt")
			else:
				Sim.pay_ukt(Game.s, "parents", rng)
				Game.s.phase = "krs"
				if shot == "krs":
					main.goto("krs")
				elif shot == "war":
					main.goto("krs")
					await main.get_tree().process_frame
					main.screen._start_war()
				else:
					Sim.set_krs(Game.s, Sim.default_krs(Game.s), {"IF101": "A", "IF103": "B"}, rng)
					Game.s.week = 4
					Game.s.attend = 3
					Game.s.knowledge = 4.0
					Game.s.energy = 64
					Game.s.mental = 71
					Game.s.social = 48
					Game.s.job = "minimarket"
					if shot.begins_with("ending"):
						Game.s.sem = 8
						Game.s.ending = shot.trim_prefix("ending_")
						Game.s.ending_reason = "ukt"
						Game.s.social = 72
						Game.s.grades = {"IF101": {"letter": "A", "point": 4.0, "sks": 144}}
						Game.s.grades["IF102"] = {"letter": "AB", "point": 3.5, "sks": 20}
						Game.s.stats.wages = 15400
						Game.s.stats.spent_khilaf = 2350
						Game.s.phase = "ending"
						main.goto("ending")
					elif shot == "khs":
						for w in 12:
							Sim.run_week(Game.s, ["kuliah", "belajar", "tugas", "tidur"], rng)
						Game.last_report = Sim.finish_semester(Game.s, rng)
						main.goto("khs")
					elif shot == "gallery":
						Meta.endings = {"balance": {"count": 1}, "cumlaude": {"count": 2}, "do": {"count": 3}, "rawat": {"count": 1}}
						main.goto("gallery")
					else:
						Game.s.phase = "week"
						main.goto("week")
						await main.get_tree().process_frame
						match shot:
							"event":
								for ev in Data.events:
									if ev.id == "read_doang":
										main.open_modal(EventPopup.new(main, ev), false)
							"picker":
								main.screen._pick(1)
							"shop":
								main.open_modal(ShopPopup.new(main, "style"))
							"wardrobe":
								main.open_modal(WardrobePopup.new(main), true, true)
							"jobs":
								main.open_modal(JobsPopup.new(main))
							"academic":
								main.open_modal(AcademicPopup.new(main))
							"settings":
								main.open_modal(SettingsPopup.new(main, true))
							"weekrun":
								main.screen._run_week()
	var frames := int(OS.get_environment("SHOT_FRAMES")) if OS.get_environment("SHOT_FRAMES") != "" else 70
	for i in frames:
		await main.get_tree().process_frame
	var img: Image = main.get_viewport().get_texture().get_image()
	img.save_png(out if out != "" else "user://shot.png")
	print("SHOT saved ", out)
	main.get_tree().quit()


## Renders the launcher icon subject (sigma student head-and-shoulders) on a transparent background.
static func _icon(main: Node, out: String) -> void:
	main.ui.visible = false
	main.world.visible = false
	main.get_viewport().transparent_bg = true
	var stage := Node3D.new()
	main.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff3e0")
	env.environment.ambient_light_energy = 0.55
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-35), deg_to_rad(35), 0)
	sun.light_energy = 1.0
	stage.add_child(sun)
	var c := VinylChar.new()
	stage.add_child(c)
	c.build({"skin": 1, "hair": "hair_fringe", "hair_color": 0, "top": "top_hoodie_gold", "head": "head_none", "face": "face_shades", "back": "back_none", "aura": "aura_none"}, "IF")
	c.rotation.y = deg_to_rad(-14)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.0
	cam.position = Vector3(0, 1.32, 6)
	stage.add_child(cam)
	cam.make_current()
	for i in 30:
		await main.get_tree().process_frame
	c.set_process(false)
	for i in 5:
		await main.get_tree().process_frame
	var img: Image = main.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("SHOT saved ", out)
	main.get_tree().quit()


## Scripted ~40 s tour for trailers and A/V checks (use with --write-movie).
static func _demo(main: Node) -> void:
	var tree := main.get_tree()
	var wait := func(t: float): await tree.create_timer(t).timeout
	main.goto("title")
	await wait.call(3.5)
	main.goto("create")
	await wait.call(1.5)
	main.screen._set_tab("hair")
	await wait.call(1.0)
	main.screen.look["hair"] = "hair_hijab"
	main.screen.look["hair_color"] = 4
	main.screen._rebuild_char()
	main.world.player.hop()
	Audio.play("pop")
	await wait.call(1.5)
	Game.new_run("Ayu", "IF", main.screen.look)
	main.goto("ukt")
	await wait.call(1.5)
	_press(main.screen, ["Dibayar Ortu"])
	await wait.call(1.2)
	_press(main.screen, ["Lanjut"])
	await wait.call(1.2)
	_press(main.screen, ["Ikut War"])
	await wait.call(0.8)
	for code in main.screen.rows:
		var row: Control = main.screen.rows[code]
		var b: Button = row.find_children("*", "Button", true, false)[0]
		main.screen._take(code, b, row)
		await wait.call(0.35)
	await wait.call(1.5)
	_press(main.screen, ["Mulai kuliah"])
	await wait.call(1.5)
	Game.s.coins = 1650
	for i in 2:
		main.screen._run_week()
		var t := 0.0
		while t < 14.0:
			await wait.call(0.25)
			t += 0.25
			if main.has_modal():
				await wait.call(2.2)
				var top: Control = main._modals[-1]
				var btn: Button = null
				for b in top.find_children("*", "Button", true, false):
					if b.visible and not b.disabled and b.text != "X":
						btn = b
						break
				if btn:
					btn.pressed.emit()
				await wait.call(2.0)
				var top2: Control = main._modals[-1] if main.has_modal() else null
				if top2:
					for b in top2.find_children("*", "Button", true, false):
						if b.visible and b.text.begins_with("Lanjut"):
							b.pressed.emit()
				break
			if not main.screen.running:
				break
		await wait.call(1.5)
	var rng := RandomNumberGenerator.new()
	for w in 12:
		Sim.run_week(Game.s, ["kuliah", "belajar", "tugas", "tidur"], rng)
	Game.last_report = Sim.finish_semester(Game.s, rng)
	main.goto("khs")
	await wait.call(4.0)
	Game.s.sem = 8
	Game.s.social = 75
	Game.s.ending = "balance"
	Game.s.phase = "ending"
	main.goto("ending")
	await wait.call(6.0)
	tree.quit()


static func _press(n: Node, prefixes: Array) -> void:
	for b in n.find_children("*", "Button", true, false):
		for p in prefixes:
			if b.text.begins_with(p) and not b.disabled:
				b.pressed.emit()
				return

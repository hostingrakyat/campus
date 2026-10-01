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
	if shot == "autoplay":
		Autoplay.run(main)
		return
	match shot:
		"title":
			main.goto("title")
		"note":
			main.goto("title")
			main.open_modal(ContentNote.new(main), false)
		"create":
			main.goto("create")
		"ukt", "ukt_phk", "krs", "war", "week", "event", "picker", "shop", "wardrobe", "jobs", "academic", "khs", "ending_balance", "ending_padam", "ending_rawat", "ending_do", "gallery":
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
	for i in 70:
		await main.get_tree().process_frame
	var img: Image = main.get_viewport().get_texture().get_image()
	img.save_png(out if out != "" else "user://shot.png")
	print("SHOT saved ", out)
	main.get_tree().quit()

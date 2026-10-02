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
	if shot.begins_with("stage_"):
		await _stage_shot(main, shot.trim_prefix("stage_"), out)
		return
	if shot == "cutscene" or shot.begins_with("cutscene_"):
		await _cutscene_shot(main, shot.trim_prefix("cutscene_") if shot != "cutscene" else "read_doang", out)
		return
	if shot == "scrolltest":
		await _scroll_test(main)
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
										main.open_cutscene(Cutscene.new(main, ev, main.screen._ctx()))
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
	while main.screen.war_on:
		for code in main.screen.rows:
			if main.screen.cls.get(code, "") == "A" or not main.screen.war_on:
				continue
			var row: Control = main.screen.rows[code]
			var b: Button = row.find_children("*", "Button", true, false)[0]
			if not b.disabled:
				main.screen._take(code, b, row)
				await wait.call(0.3)
		await wait.call(0.2)
	await wait.call(1.8)
	_press(main.screen, ["Mulai kuliah"])
	await wait.call(1.5)
	if not (main.screen is HudScreen):
		push_error("demo: expected HUD")
		tree.quit()
		return
	Game.s.coins = 1650
	for i in 2:
		main.screen._run_week()
		await _auto_until_idle(main, 70.0)
		await wait.call(1.2)
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


## Renders one activity variant staged in its set (no UI): stage_<action>[:<variant>]
static func _stage_shot(main: Node, spec: String, out: String) -> void:
	Game.new_run("Ayu", "IF", {"skin": 1, "hair": "hair_hijab", "hair_color": 4, "top": "top_almamater", "head": "head_none", "face": "face_round", "back": "back_ransel", "aura": "aura_none"})
	Game.s.job = "barista"
	Game.s.dospem = "dosen_revisi"
	main.goto("title")
	main.ui.visible = false
	var parts := spec.split(":")
	var action: String = parts[0]
	var entry := {"action": action, "variant": {}, "scene_key": parts[1] if parts.size() > 1 else "acc"}
	for v in Data.activities.variants.get(action, []):
		if parts.size() < 2 or v.id == parts[1]:
			entry.variant = v
			break
	var w: CampusWorld = main.world
	w.set_time(OS.get_environment("SHOT_TIME") if OS.get_environment("SHOT_TIME") != "" else "siang", true)
	var scene := w.director.scene_for(entry)
	var ctx := {"lecturer": "dosen_killer", "dospem": "dosen_revisi", "job": "barista", "friend": "beban", "scene_key": entry.scene_key}
	w.director.stage(scene, ctx, 0.5)
	w.director.play_bubbles(scene, ctx)
	await _finish(main, out)


static func _cutscene_shot(main: Node, ev_id: String, out: String) -> void:
	Game.new_run("Ayu", "IF", {"skin": 1, "hair": "hair_hijab", "hair_color": 4, "top": "top_almamater", "head": "head_none", "face": "face_round", "back": "back_ransel", "aura": "aura_none"})
	Sim.pay_ukt(Game.s, "parents", RandomNumberGenerator.new())
	Sim.set_krs(Game.s, Sim.default_krs(Game.s), {}, RandomNumberGenerator.new())
	Game.s.dospem = "dosen_revisi"
	main.goto("week")
	await main.get_tree().process_frame
	for ev in Data.events:
		if ev.id == ev_id:
			var cs := Cutscene.new(main, ev, main.screen._ctx())
			main.open_cutscene(cs)
	await _finish(main, out)


static func _finish(main: Node, out: String) -> void:
	var frames := int(OS.get_environment("SHOT_FRAMES")) if OS.get_environment("SHOT_FRAMES") != "" else 70
	for i in frames:
		await main.get_tree().process_frame
	var img: Image = main.get_viewport().get_texture().get_image()
	img.save_png(out if out != "" else "user://shot.png")
	print("SHOT saved ", out)
	main.get_tree().quit()


## Simulated finger gestures on the KRS list: a swipe must scroll without toggling a course,
## a short tap must toggle exactly one course.
static func _scroll_test(main: Node) -> void:
	var tree := main.get_tree()
	Game.new_run("Tes", "KD", Data.DEFAULT_LOOK)
	Game.s.sem = 7
	Game.s.ukt_paid = true
	Game.s.phase = "krs"
	main.goto("krs")
	for i in 60:
		await tree.process_frame
	var scr: KrsScreen = main.screen
	var sc: TouchScroll = scr.find_children("*", "TouchScroll", true, false)[0]
	var r := sc.get_global_rect()
	var before_pick := scr.picked.duplicate()
	var x := r.position.x + r.size.x * 0.5
	var y0 := r.position.y + r.size.y * 0.8
	await _mouse(tree, Vector2(x, y0), true)
	for i in 12:
		await _move(tree, Vector2(x, y0 - i * 25.0))
	await _mouse(tree, Vector2(x, y0 - 300.0), false)
	for i in 20:
		await tree.process_frame
	var scrolled := sc.scroll_vertical
	var unchanged := scr.picked == before_pick
	print("SCROLLTEST swipe: scroll_vertical=%d picked_unchanged=%s" % [scrolled, unchanged])
	await _mouse(tree, Vector2(x, y0), true)
	await _mouse(tree, Vector2(x, y0), false)
	for i in 5:
		await tree.process_frame
	var toggled := scr.picked.size() != before_pick.size()
	print("SCROLLTEST tap: toggled_one=%s" % toggled)
	print("SCROLLTEST %s" % ("PASS" if scrolled > 100 and unchanged and toggled else "FAIL"))
	tree.quit()


static func _mouse(tree: SceneTree, pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)
	await tree.process_frame
	await tree.process_frame


static func _move(tree: SceneTree, pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)
	await tree.process_frame


## Plays through a running week like a reader: taps dialogue every ~2 s and picks the first choice.
static func _auto_until_idle(main: Node, max_t: float) -> void:
	var tree := main.get_tree()
	var t := 0.0
	var next_tap := 2.2
	while t < max_t:
		await tree.create_timer(0.2).timeout
		t += 0.2
		if main.has_modal():
			next_tap -= 0.2
			if next_tap <= 0.0:
				next_tap = 2.2
				var top: Control = main._modals[-1]
				for b in top.find_children("*", "Button", true, false):
					if b.visible and not b.disabled and b.text != "X":
						b.pressed.emit()
						break
		elif main.screen is HudScreen and not main.screen.running:
			return
		elif not (main.screen is HudScreen):
			return

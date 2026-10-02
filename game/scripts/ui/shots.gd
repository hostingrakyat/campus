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
	if shot == "ad" or shot == "ad_inter":
		main.goto("title")
		await main.get_tree().process_frame
		if shot == "ad":
			Ads.show_rewarded("shot", func(_ok: bool): pass)
		else:
			Ads._show_mock(false, "shot", func(_ok: bool): pass)
		await _finish(main, out)
		return
	if shot.begins_with("mg_"):
		await _minigame_shot(main, shot.trim_prefix("mg_"), out)
		return
	if shot == "explore" or shot == "exploretest":
		await _explore_shot(main, out, shot == "exploretest")
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
								main.open_modal(WardrobePopup.new(main))
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
	main.screen._run_week()
	await _auto_until_idle(main, 90.0)
	await wait.call(1.2)
	# Free roam: pet the cat, then dribble the ball into a goal.
	main.screen._start_explore()
	while main.screen._explore == null:
		await tree.process_frame
	await wait.call(1.5)
	var ex: Explorer = main.world.explorer
	for wp in [Vector3(-5.0, 0, 10.2), Vector3(-5.0, 0, 5.4), Vector3(-5.6, 0, 4.9)]:
		await _walk(ex, wp, 4.0)
	main.screen._explore._act()
	await wait.call(1.8)
	for wp in [Vector3(4.6, 0, 4.4), Vector3(4.6, 0, 1.6)]:
		await _walk(ex, wp, 5.0)
	await _walk(ex, Vector3(-1.0, 0, 1.6), 3.0)
	await wait.call(2.0)
	main.screen._explore.close()
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
	e.position = _to_window(tree, pos)
	e.global_position = e.position
	Input.parse_input_event(e)
	await tree.process_frame
	await tree.process_frame


static func _move(tree: SceneTree, pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = _to_window(tree, pos)
	e.global_position = e.position
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)
	await tree.process_frame


## Plays through a running week like a reader: taps dialogue every ~2 s and picks the first choice.
static func _auto_until_idle(main: Node, max_t: float) -> void:
	var tree := main.get_tree()
	var t := 0.0
	var next_tap := 2.2
	while t < max_t:
		if main.screen is HudScreen and main.screen._game:
			main.screen._game.bot_play()
			await tree.process_frame
			t += main.get_process_delta_time()
			continue
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


static func _week_setup(main: Node) -> void:
	Game.new_run("Ayu", "IF", {"skin": 1, "hair": "hair_hijab", "hair_color": 4, "top": "top_almamater", "head": "head_none", "face": "face_round", "back": "back_ransel", "aura": "aura_none"})
	var rng := RandomNumberGenerator.new()
	Sim.pay_ukt(Game.s, "parents", rng)
	Sim.set_krs(Game.s, Sim.default_krs(Game.s), {}, rng)
	Game.s.dospem = "dosen_revisi"
	Game.s.coins = 1650
	Game.s.week = 3
	Game.s.phase = "week"
	main.goto("week")
	await main.get_tree().process_frame


## A mini-game mid-play over its staged activity: mg_<action>[:<job>] (kind is picked like in-game).
static func _minigame_shot(main: Node, spec: String, out: String) -> void:
	await _week_setup(main)
	var parts := spec.split(":")
	var action: String = parts[0]
	if parts.size() > 1:
		Game.s.job = parts[1]
		Game.s.skripsi = true
	var hud: HudScreen = main.screen
	var w: CampusWorld = main.world
	hud._page.slide(false)
	var entry := {"action": action, "variant": {}, "scene_key": "acc", "fx": {}}
	var vs: Array = Data.activities.variants.get(action if action != "kerja" else Data.activities.variants.keys()[0], [])
	if not vs.is_empty():
		entry.variant = vs[0]
	var ctx := hud._ctx()
	w.set_time("pagi", true)
	w.director.stage(w.director.scene_for(entry), ctx, 0.47)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(OS.get_environment("SHOT_SEED")) if OS.get_environment("SHOT_SEED") != "" else 3
	var cfg := MiniGames.config_for(Game.s, entry, rng)
	print("MG kind=", cfg.get("kind", "none"))
	var g := MiniGame.new(main, cfg, ctx)
	hud.add_child(g)
	var wait_t := float(OS.get_environment("SHOT_WAIT")) if OS.get_environment("SHOT_WAIT") != "" else 2.2
	var el := 0.0
	while el < wait_t:
		await main.get_tree().process_frame
		el += main.get_process_delta_time()
		if el > 1.0 and cfg.kind in ["catch", "mash"] and randf() < 0.3:
			g.bot_play()
	var img: Image = main.get_viewport().get_texture().get_image()
	img.save_png(out if out != "" else "user://shot.png")
	print("SHOT saved ", out)
	main.get_tree().quit()


## Free-roam mode. With test=true, drives it with synthetic touches and checks the rules.
static func _explore_shot(main: Node, out: String, test: bool) -> void:
	await _week_setup(main)
	var tree := main.get_tree()
	var hud: HudScreen = main.screen
	for i in 30:
		await tree.process_frame
	hud._start_explore()
	while hud._explore == null:
		await tree.process_frame
	await tree.create_timer(0.5).timeout
	var em: ExploreMode = hud._explore
	var ex: Explorer = main.world.explorer
	var p: VinylChar = main.world.player
	if not test:
		var spot := OS.get_environment("SHOT_SPOT")
		p.position = Vector3(5.0, 0, 3.4) if spot == "" else str_to_var("Vector3(%s)" % spot)
		main.world.follow(9.0, 0.5, true)
		em.joy._grab(0, em.joy.home + em.joy.global_position)
		em.joy._drag(em.joy.home + em.joy.global_position + Vector2(-50, -70))
		await tree.create_timer(0.25).timeout
		em.joy._release()
		await tree.create_timer(1.2).timeout
		em.joy._grab(0, em.joy.home + em.joy.global_position)
		em.joy._drag(em.joy.home + em.joy.global_position + Vector2(-50, -70))
		await tree.process_frame
		await tree.process_frame
		var img: Image = main.get_viewport().get_texture().get_image()
		img.save_png(out if out != "" else "user://shot.png")
		print("SHOT saved ", out)
		tree.quit()
		return
	var ok := true
	# 1) Touch-drag on the joystick zone moves the player screen-up (away from the camera).
	var start := p.position
	var vw := main.get_viewport().get_visible_rect().size
	var t0 := Vector2(160, vw.y - 260)
	await _touch(tree, 0, t0, true)
	for i in 8:
		await _drag(tree, 0, t0 + Vector2(0, -i * 14.0))
	for i in 40:
		await tree.process_frame
	await tree.create_timer(0.6).timeout
	await _touch(tree, 0, t0 + Vector2(0, -112), false)
	var moved := p.position - start
	var up_ok := moved.length() > 1.0 and moved.x < 0.0 and moved.z < 0.0
	print("EXPLORETEST joystick moved=%s ok=%s" % [moved, up_ok])
	ok = ok and up_ok
	# 2) Walls: walking into the faculty building stops at its wall.
	p.position = Vector3(-5.5, 0, -2.0)
	for i in 90:
		ex.move = Vector2(-0.4, -1.0)
		await tree.process_frame
	await tree.create_timer(1.0).timeout
	ex.move = Vector2.ZERO
	var wall_ok := p.position.z > -3.9
	print("EXPLORETEST wall z=%.2f ok=%s" % [p.position.z, wall_ok])
	ok = ok and wall_ok
	# 3) Coins are picked up once.
	var coins0: int = Game.s.coins
	var coin_items: Array = ex.items.filter(func(it): return it.kind == "coin")
	for it in coin_items:
		p.position = it.pos
		for i in 3:
			await tree.process_frame
	var gained: int = Game.s.coins - coins0
	var coin_ok := gained == Data.EXPLORE_COIN * coin_items.size() and coin_items.size() > 0 and ex.coins_left() == 0
	print("EXPLORETEST coins %d items=%d gained=%d ok=%s" % [coins0, coin_items.size(), gained, coin_ok])
	ok = ok and coin_ok
	# 4) Pet the cat once per week; second time gives nothing.
	var m0: int = Game.s.mental
	p.position = ex._cat.position + Vector3(0.9, 0, 0)
	for i in 3:
		await tree.process_frame
	var near_cat: bool = ex.near.get("kind", "") == "cat"
	em._act()
	var m1: int = Game.s.mental
	em._act()
	var cat_ok: bool = near_cat and m1 == mini(100, m0 + 3) and Game.s.mental == m1
	print("EXPLORETEST cat near=%s mental %d->%d->%d ok=%s" % [near_cat, m0, m1, Game.s.mental, cat_ok])
	ok = ok and cat_ok
	# 5) A second finger on A works while the first one steers.
	p.position = ex._cat.position + Vector3(0.9, 0, 0)
	for i in 3:
		await tree.process_frame
	await _touch(tree, 0, t0, true)
	var acted := [false]
	ex.acted.connect(func(_it, _o): acted[0] = true, CONNECT_ONE_SHOT)
	await _touch(tree, 1, em.act_btn.get_global_rect().get_center(), true)
	await _touch(tree, 1, em.act_btn.get_global_rect().get_center(), false)
	await _touch(tree, 0, t0, false)
	print("EXPLORETEST multitouch A ok=%s" % acted[0])
	ok = ok and acted[0]
	# 6) Kick the ball into a goal.
	ex._ball.position = Vector3(1.2, 0.22, 1.6)
	p.position = Vector3(2.2, 0, 1.6)
	ex.move = Vector2.ZERO
	await tree.process_frame
	ex._ball_v = Vector3(-6, 0, 0)
	var goal := [false]
	ex.acted.connect(func(it, _o): goal[0] = it.get("kind", "") == "goal", CONNECT_ONE_SHOT)
	await tree.create_timer(1.0).timeout
	print("EXPLORETEST goal ok=%s" % goal[0])
	ok = ok and goal[0]
	# 7) Done returns to the planner.
	em.close()
	await tree.create_timer(1.0).timeout
	var back_ok: bool = hud._explore == null and not hud.running
	print("EXPLORETEST back ok=%s" % back_ok)
	ok = ok and back_ok
	print("EXPLORETEST %s" % ("PASS" if ok else "FAIL"))
	tree.quit()


static func _touch(tree: SceneTree, idx: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = _to_window(tree, pos)
	e.pressed = pressed
	Input.parse_input_event(e)
	await tree.process_frame
	await tree.process_frame


static func _drag(tree: SceneTree, idx: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = _to_window(tree, pos)
	Input.parse_input_event(e)
	await tree.process_frame


## Synthetic events are in window pixels; UI coordinates go through the stretch transform.
static func _to_window(tree: SceneTree, pos: Vector2) -> Vector2:
	return tree.root.get_final_transform() * pos


## Steers the explorer like a thumb on the stick would, until close to target.
static func _walk(ex: Explorer, target: Vector3, max_t: float) -> void:
	var tree := ex.get_tree()
	var t := 0.0
	while t < max_t:
		var d := target - ex.player.position
		d.y = 0
		if d.length() < 0.3:
			break
		var dir := d.normalized()
		ex.move = Vector2(dir.dot(ex._right), -dir.dot(ex._fwd)) * minf(1.0, d.length())
		await tree.process_frame
		t += ex.get_process_delta_time()
	ex.move = Vector2.ZERO

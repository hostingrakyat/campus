extends Node
## Headless balance test: plays many full runs with scripted strategies and reports ending distribution.
## Run: godot --headless res://tests/sim_bot.tscn

const STRATEGIES := ["rajin", "balance", "santai", "pekerja"]
const RUNS := 15

var failures := 0


func _ready() -> void:
	_unit_tests()
	for strat in STRATEGIES:
		for prodi in ["IF", "MN", "KD"]:
			var dist := {}
			var ipk_sum := 0.0
			var sem_sum := 0
			for i in RUNS:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash("%s%s%d" % [strat, prodi, i])
				var s := _play(strat, prodi, rng)
				var key: String = s.ending + ("/" + s.ending_reason if s.ending_reason != "" else "")
				dist[key] = dist.get(key, 0) + 1
				ipk_sum += Sim.ipk(s)
				if OS.get_environment("SIMDBG") != "" and i == 0:
					for h in s.history:
						var letters := []
						for c in h.courses:
							letters.append(c.letter + ("!" if c.get("note", "") != "" else ""))
						print("   sem%d ips %.2f ipk %.2f sks %d att %s %s" % [h.sem, h.ips, h.ipk, h.sks_total, str(h.get("att", "-")), " ".join(letters)])
					print("   end: %s mental %d energy %d coins %d job %s skripsi %s draft %.0f acc %.0f" % [s.ending, s.mental, s.energy, s.coins, s.job, s.skripsi, s.draft, s.acc])
				sem_sum += int(s.sem)
			print("%-8s %s  avgIPK %.2f  avgSem %.1f  %s" % [strat, prodi, ipk_sum / RUNS, float(sem_sum) / RUNS, str(dist)])
	print("UNIT FAILURES: %d" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check(cond: bool, what: String) -> void:
	if not cond:
		failures += 1
		push_error("FAIL: " + what)


func _unit_tests() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var s := Sim.new_state("Tes", "IF", Data.DEFAULT_LOOK, rng)
	Sim.enter_semester(s)
	_check(Sim.ukt_due(s) == 6500, "IF UKT is 6500")
	_check(Sim.pay_ukt(s, "parents", rng).ok, "parents pay in sem 1")
	_check(Sim.sks_limit(s) == 20, "first semester limit 20")
	var codes := Sim.default_krs(s)
	_check(codes.size() == 7, "IF sem 1 has 7 courses, got %d" % codes.size())
	Sim.set_krs(s, codes, {}, rng)
	_check(Sim.krs_sks(s) == 18, "IF sem 1 is 18 SKS")
	_check(Sim.available_actions(s, "pagi").has("kuliah"), "kuliah in pagi")
	s.week = 6
	_check(Sim.available_actions(s, "pagi") == ["ujian"], "exam week forces ujian")
	s.week = 1
	# Skipping class all semester must fail the 75% attendance rule.
	for w in 12:
		Sim.run_week(s, ["bolos", "belajar", "tugas", "tidur"], rng)
		s.week += 1
	var rep := Sim.finish_semester(s, rng)
	_check(rep.ips < 1.0, "no attendance -> failing IPS (got %.2f)" % rep.ips)
	# Crisis requires a prior warning.
	var c := Sim.new_state("Tes", "MN", Data.DEFAULT_LOOK, rng)
	c.mental = 0
	Sim._check_crisis(c)
	_check(c.ending == "" and c.mental == 5, "first collapse is held for a warning")
	c.flags["warned"] = true
	c.mental = 0
	c.social = 50
	Sim._check_crisis(c)
	_check(c.ending == "rawat", "high social -> rawat")
	# Every event's choices reference valid structure.
	for ev in Data.events:
		_check(ev.has("id") and ev.choices.size() >= 1, "event shape " + str(ev.get("id")))
		_check(Data.NPCS.has(ev.speaker), "speaker exists for " + ev.id)
	# Mini-games: every activity/job maps to a valid config; bonuses are small and never negative.
	var ms := Sim.new_state("T", "MN", Data.DEFAULT_LOOK, rng)
	ms.skripsi = true
	for a in Data.ACTIONS:
		for job in ["", "barista", "minimarket", "les", "admin_olshop", "freelance_dev", "jaga_apotek", "asdos"]:
			if a != "kerja" and job != "":
				continue
			ms.job = job
			for k in 6:
				var cfg := MiniGames.config_for(ms, {"action": a, "scene_key": "acc"}, rng)
				if cfg.is_empty():
					continue
				_check(cfg.kind in ["catch", "timing", "mash", "quiz", "chat"], "minigame kind for " + a)
				if cfg.kind == "quiz":
					for q in cfg.questions:
						_check(q.a.size() == 3 and int(q.right) >= 0 and int(q.right) < 3, "quiz shape for " + a)
				if cfg.kind == "chat":
					_check(cfg.opts.size() == 3, "chat options for " + a)
			var hi := MiniGames.bonus_fx(ms, a, 1.0)
			for k in hi:
				_check(float(hi[k]) >= 0.0, "bonus non-negative %s/%s" % [a, k])
			_check(MiniGames.bonus_fx(ms, a, 0.1).is_empty(), "no bonus for a miss " + a)
	_check(MiniGames.config_for(ms, {"action": "bimbingan", "scene_key": "ghost"}, rng).is_empty(), "no game when advisor is absent")
	# Exploration rewards: once per week, diamond once per semester.
	Game.s = Sim.new_state("T", "IF", Data.DEFAULT_LOOK, rng)
	Game.s.coins = 100
	var c1 := Game.explore_reward("coin", "c1")
	var c2 := Game.explore_reward("coin", "c1")
	_check(c1.get("coins", 0) == Data.EXPLORE_COIN and c2.is_empty() and Game.s.coins == 100 + Data.EXPLORE_COIN, "coin once")
	var d0 := Meta.diamonds
	Game.explore_reward("diamond")
	Game.explore_reward("diamond")
	_check(Meta.diamonds == d0 + 1, "diamond once per semester")
	Meta.diamonds = d0
	Game.explore_reward("cat")
	_check(Game.explore_reward("cat").is_empty(), "cat once per week")
	for i in 5:
		Game.explore_reward("chat")
	_check(Game.explore_state().chat == 5, "chat counted")
	Game.s.week += 1
	_check(not Game.explore_reward("cat").is_empty(), "cat again next week")
	_check(Game.explore_reward("coin", "c1").get("coins", 0) == Data.EXPLORE_COIN, "coins respawn next week")
	Game.s = {}


func _play(strat: String, prodi: String, rng: RandomNumberGenerator) -> Dictionary:
	var s := Sim.new_state("Bot", prodi, Data.DEFAULT_LOOK, rng)
	Sim.enter_semester(s)
	var guard := 0
	while s.phase != "ending" and guard < 400:
		guard += 1
		match s.phase:
			"ukt":
				_pay(s, strat, rng)
				if s.phase == "ending":
					break
				if s.phase == "ukt":
					continue
				Sim.set_krs(s, Sim.default_krs(s), _war(rng), rng)
			"week":
				if s.flags.get("phk", false) and s.job == "" and strat != "santai":
					s.job = "barista" if strat == "pekerja" else ("freelance_dev" if prodi == "IF" and s.sem >= 3 else "minimarket")
				var pl := _plan(s, strat)
				var wr := Sim.run_week(s, pl, rng)
				if OS.get_environment("SIMDBG") == "2" and s.skripsi and strat == "rajin" and prodi == "IF":
					var notes := []
					for l in wr.log:
						notes.append(str(l.note.get("id", "")).left(30))
					print("  S%d W%d %s draft %.0f acc %.0f ready %s done %s | %s" % [s.sem, s.week, str(pl), s.draft, s.acc, s.flags.get("sidang_ready", false), s.skripsi_done, str(notes)])
				for i in 2:
					if s.phase == "ending":
						break
					var ev := Sim.pick_event(s, rng, 0.65 if i == 0 else 0.0)
					if ev.is_empty():
						break
					var cr := Sim.apply_choice(s, ev, _safe_choice(ev, strat, rng), rng)
					if OS.get_environment("SIMDBG") == "2" and s.skripsi and strat == "rajin" and prodi == "IF":
						print("     EVENT %s ok=%s" % [ev.id, cr.success])
				if s.phase == "ending":
					break
				s.week += 1
				if s.week > Data.WEEKS_PER_SEMESTER:
					Sim.finish_semester(s, rng)
			"khs":
				if Sim.evaluate(s) == "":
					Sim.next_semester(s)
	return s


func _pay(s: Dictionary, strat: String, rng: RandomNumberGenerator) -> void:
	if s.flags.get("phk_new", false):
		s.flags.erase("phk_new")
	for m in ["parents", "coins", "beasiswa", "banding", "coins"]:
		if s.ukt_paid:
			break
		Sim.pay_ukt(s, m, rng)
	if not s.ukt_paid and Sim.ukt_due(s) == 0:
		Sim.pay_ukt(s, "coins", rng)
	if not s.ukt_paid:
		if s.cuti_used < Data.MAX_CUTI and strat != "santai":
			Sim.pay_ukt(s, "cuti", rng)
			return
		if not Sim.pay_ukt(s, "pinjol", rng).ok:
			s.ending = "do"
			s.ending_reason = "ukt"
			s.phase = "ending"
			return
	s.phase = "krs"


func _war(rng: RandomNumberGenerator) -> Dictionary:
	var cls := {}
	for code in ["x"]:
		cls[code] = "A"
	return cls


func _plan(s: Dictionary, strat: String) -> Array:
	var plan := Sim.default_plan(s)
	var low_e: bool = s.energy < 40
	var low_m: bool = s.mental < 45
	# Free slot = the non-job slot we can repurpose (prefer malam, else siang).
	var free := 2 if plan[2] != "kerja" else 1
	var e: int = s.energy
	match strat:
		"rajin":
			if e > 55:
				plan[3] = "belajar" if int(s.week) % 2 == 0 else "tugas"
				if s.skripsi and not s.skripsi_done:
					plan[3] = "garap_skripsi"
			if plan[2] == "kerja" and plan[1] != "kerja":
				plan[1] = "belajar" if int(s.week) % 2 == 1 else "tugas"
				if s.skripsi and not s.skripsi_done and not Sim.has_classes(s):
					plan[0] = "garap_skripsi"
					plan[1] = "bimbingan" if s.draft > s.acc + 5.0 else "garap_skripsi"
			if s.skripsi and not s.skripsi_done and plan[1] != "kerja" and (s.draft > s.acc + 5.0 or s.acc >= 100.0) and (int(s.week) % 2 == 0 or not Sim.has_classes(s)):
				plan[1] = "bimbingan"
			if low_e:
				plan[free] = "tidur"
			if low_m and plan[1] != "kerja":
				plan[1] = "konseling"
		"balance":
			plan[3] = "nongkrong" if int(s.week) % 2 == 0 else ("belajar" if e > 60 else "tidur")
			if int(s.week) % 3 == 0 and plan[free] != "kerja":
				plan[free] = "nongkrong"
			if int(s.week) % 4 == 1 and plan[1] != "kerja":
				plan[1] = "organisasi"
			if low_e:
				plan[free] = "tidur"
			if low_m and plan[1] != "kerja":
				plan[1] = "konseling"
		"santai":
			if plan[0] == "kuliah" and int(s.week) % 4 == 0:
				plan[0] = "bolos"
			if plan[2] != "kerja":
				plan[2] = "nongkrong" if int(s.week) % 2 == 0 else "tidur"
		"pekerja":
			if e > 50:
				plan[3] = "ojol"
			if low_e and plan[2] != "kerja":
				plan[2] = "tidur"
	return plan


func _safe_choice(ev: Dictionary, strat: String, rng: RandomNumberGenerator) -> int:
	var safe: Array = []
	for i in ev.choices.size():
		var ch: Dictionary = ev.choices[i]
		if not ch.has("fail_end") and not ch.has("end"):
			safe.append(i)
	if strat == "santai":
		return safe[rng.randi() % safe.size()]
	return safe[0]

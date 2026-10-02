class_name Sim
extends RefCounted
## Pure game rules operating on a JSON-serializable state Dictionary.
## No nodes, no UI — everything here is unit-testable headless.

const D := preload("res://scripts/autoload/data.gd")


static func new_state(player_name: String, prodi: String, look: Dictionary, rng: RandomNumberGenerator, carry_coins: int = 0) -> Dictionary:
	var p: Dictionary = D.PRODI[prodi]
	return {
		"v": 1, "name": player_name, "prodi": prodi, "look": look.duplicate(),
		"sem": 1, "week": 1, "phase": "ukt",
		"energy": 80, "mental": 75, "social": 30, "coins": 600 + carry_coins, "rel": 0,
		"knowledge": 0.0, "tugas": 0.0, "attend": 0, "bonus": 0.0,
		"mental_sum": 0.0, "mental_n": 0,
		"krs": [], "grades": {}, "history": [],
		"job": "", "job_izin": 0,
		"flags": {}, "seen": {},
		"parents_pay_ukt": true, "allowance": p.allowance, "phk_sem": rng.randi_range(3, 4),
		"ukt_mult": 1.0, "ukt_paid": false, "ukt_tried": {},
		"debt": 0, "cuti_used": 0,
		"skripsi": false, "draft": 0.0, "acc": 0.0, "dospem": "", "skripsi_done": false, "skripsi_score": 0.0,
		"low_ips": 0, "konseling_week": -1,
		"ending": "", "ending_reason": "",
		"stats": {"weeks": 0, "spent_khilaf": 0, "wages": 0},
	}


# --- Derived values ----------------------------------------------------------

static func ipk(s: Dictionary) -> float:
	var pts := 0.0
	var sks := 0
	for code in s.grades:
		var g: Dictionary = s.grades[code]
		pts += g.point * g.sks
		sks += int(g.sks)
	return 0.0 if sks == 0 else pts / sks


static func sks_lulus(s: Dictionary) -> int:
	var total := 0
	for code in s.grades:
		if s.grades[code].point >= 1.0:
			total += int(s.grades[code].sks)
	return total


static func last_ips(s: Dictionary) -> float:
	return -1.0 if s.history.is_empty() else float(s.history[-1].ips)


## Study progress this semester as 0..1+ of what an average-difficulty course needs (for HUD hints).
static func study_progress(s: Dictionary) -> Dictionary:
	var pdiff: float = D.PRODI[s.prodi].diff
	var load: float = maxf(1.0, krs_sks(s) / 20.0)
	var dsum := 0.0
	var n := 0
	for c in s.krs:
		if c.type == "mk":
			dsum += float(c.diff)
			n += 1
	var diff := 1.0 if n == 0 else dsum / n
	return {
		"knowledge": s.knowledge / (D.TARGET_KNOWLEDGE * pdiff * diff * load),
		"tugas": s.tugas / (D.TARGET_TUGAS * pdiff * diff * load),
	}


static func avg_mental(s: Dictionary) -> float:
	return float(s.mental) if s.mental_n == 0 else s.mental_sum / s.mental_n


static func is_exam_week(s: Dictionary) -> bool:
	return D.EXAM_WEEKS.has(int(s.week))


static func has_flag(s: Dictionary, f: String) -> bool:
	return s.flags.get(f, false)


# --- Semester start: UKT -----------------------------------------------------

## Called when a new semester begins. Returns notes (text pairs) for the UI.
static func enter_semester(s: Dictionary) -> Array:
	var notes: Array = []
	s.week = 1
	s.knowledge = 0.0
	s.tugas = 0.0
	s.attend = 0
	s.bonus = 0.0
	s.ukt_paid = false
	s.ukt_tried = {}
	s.phase = "ukt"
	s.flags.erase("buku")
	s.flags.erase("warned_sem")
	if s.parents_pay_ukt and s.sem >= s.phk_sem:
		s.parents_pay_ukt = false
		s.allowance = D.PHK_ALLOWANCE
		s.flags["phk"] = true
		s.flags["phk_new"] = true
	if s.debt > 0:
		var pay: int = mini(maxi(int(s.coins), 0), int(s.debt))
		s.coins -= pay
		s.debt -= pay
		if s.debt > 0:
			s.debt = int(s.debt * 1.1)
			_add(s, "mental", -15)
			notes.append({"id": "Debt collector DanaKilat nelpon terus. Utang berbunga lagi.", "en": "DanaKilat's debt collector keeps calling. The debt grew again."})
		else:
			notes.append({"id": "Utang pinjol lunas. Lega banget.", "en": "Loan app debt fully paid. Huge relief."})
	return notes


static func ukt_due(s: Dictionary) -> int:
	if has_flag(s, "beasiswa_%d" % s.sem):
		return 0
	var base: float = D.PRODI[s.prodi].ukt * s.ukt_mult
	return int(round(base / 50.0) * 50)


## Pay UKT. method: parents | coins | pinjol | banding | beasiswa | cuti.
## Returns {"ok": bool, "msg": pair}.
static func pay_ukt(s: Dictionary, method: String, rng: RandomNumberGenerator) -> Dictionary:
	var due := ukt_due(s)
	match method:
		"parents":
			if not s.parents_pay_ukt:
				return _r(false, "Ortu udah nggak sanggup bayar.", "Your parents can't pay anymore.")
			s.ukt_paid = true
			return _r(true, "UKT dibayar ortu. Jangan sia-siain ya, Nak.", "Your parents paid the tuition. Don't waste it, kid.")
		"coins":
			if due == 0:
				s.ukt_paid = true
				return _r(true, "Beasiswa menanggung UKT semester ini!", "A scholarship covers this semester's tuition!")
			if s.coins < due:
				return _r(false, "Koin kamu belum cukup.", "You don't have enough coins.")
			s.coins -= due
			s.ukt_paid = true
			return _r(true, "UKT lunas pakai tabungan sendiri. Sigma.", "Tuition paid from your own savings. Sigma.")
		"pinjol":
			if s.debt > 0:
				return _r(false, "DanaKilat menolak: utang lama belum lunas.", "DanaKilat refuses: your old debt isn't paid.")
			s.debt = int(due * D.PINJOL_RATE)
			s.ukt_paid = true
			_add(s, "mental", -10)
			s.flags["pinjol"] = true
			return _r(true, "UKT dibayar pinjol. Utang %d koin menunggu semester depan." % s.debt, "Tuition paid with a loan app. %d coins of debt await next semester." % s.debt)
		"banding":
			if s.ukt_tried.get("banding", false) or s.ukt_mult <= 0.25:
				return _r(false, "Banding sudah diajukan.", "Appeal already submitted.")
			s.ukt_tried["banding"] = true
			_add(s, "mental", -8)
			var phk := has_flag(s, "phk")
			var p: float = (0.6 if phk else 0.3) + s.rel * 0.03
			if rng.randf() < p:
				s.ukt_mult = 0.25 if phk else s.ukt_mult * 0.5
				return _r(true, "Setelah 7 loket, 3 cap basah, dan 1 materai: banding DITERIMA. UKT turun ke golongan %s!" % ("terendah" if phk else "bawah"), "After 7 counters, 3 wet stamps and 1 duty stamp: appeal ACCEPTED. Tuition dropped to the %s bracket!" % ("lowest" if phk else "lower"))
			return _r(false, "Banding ditolak. Alasan: \"berkas kurang lengkap\" (berkasnya lengkap).", "Appeal rejected. Reason: \"incomplete documents\" (they were complete).")
		"beasiswa":
			if s.ukt_tried.get("beasiswa", false):
				return _r(false, "Sudah daftar semester ini.", "Already applied this semester.")
			var min_ipk := 3.0 if has_flag(s, "phk") else 3.5
			if s.sem < 2 or ipk(s) < min_ipk:
				return _r(false, "Syarat beasiswa: IPK minimal %.2f." % min_ipk, "Scholarship requires GPA %.2f+." % min_ipk)
			s.ukt_tried["beasiswa"] = true
			if rng.randf() < 0.55 + s.rel * 0.03:
				s.flags["beasiswa_%d" % s.sem] = true
				return _r(true, "Beasiswa prestasi tembus! UKT semester ini gratis.", "Merit scholarship approved! Free tuition this semester.")
			return _r(false, "Kuota beasiswa habis. Katanya sih.", "Scholarship quota is full. Allegedly.")
		"cuti":
			if s.cuti_used >= D.MAX_CUTI:
				return _r(false, "Jatah cuti habis.", "No leave semesters left.")
			s.cuti_used += 1
			s.coins += D.CUTI_EARNINGS
			_add(s, "mental", 15)
			s.history.append({"sem": s.sem, "cuti": true, "ips": 0.0, "ipk": ipk(s), "sks_sem": 0, "sks_total": sks_lulus(s), "courses": []})
			enter_semester(s)
			return _r(true, "Cuti satu semester. Kerja full-time, dapat %d koin. Semester tetap %d." % [D.CUTI_EARNINGS, s.sem], "One semester of leave. Worked full-time, earned %d coins. Still semester %d." % [D.CUTI_EARNINGS, s.sem])
	return _r(false, "?", "?")


# --- KRS ---------------------------------------------------------------------

static func sks_limit(s: Dictionary) -> int:
	var ips := last_ips(s)
	if ips < 0.0:
		return 20
	if ips >= 3.0:
		return 24
	if ips >= 2.5:
		return 21
	if ips >= 2.0:
		return 18
	return 15


## Courses the player may take this semester (curriculum up to current semester, not yet passed).
static func krs_options(s: Dictionary) -> Array:
	var out: Array = []
	var cur: Array = Data.curriculum[s.prodi]
	var lulus := sks_lulus(s)
	for i in range(cur.size()):
		for c in cur[i]:
			# Future semesters are locked, except the thesis which opens from semester 7.
			if i >= int(s.sem) and c.type != "skripsi":
				continue
			var g: Dictionary = s.grades.get(c.code, {})
			if not g.is_empty() and g.point >= 1.0:
				continue
			if c.type == "skripsi" and (s.sem < 7 or lulus < 100):
				continue
			if c.type == "kkn" and (s.sem < 6 or lulus < 90):
				continue
			out.append(c)
	return out


static func default_krs(s: Dictionary) -> Array:
	var limit := sks_limit(s)
	var total := 0
	var picked: Array = []
	var opts := krs_options(s)
	opts.sort_custom(func(a, b): return a.type == "skripsi" and b.type != "skripsi")
	for c in opts:
		if total + int(c.sks) <= limit:
			picked.append(c.code)
			total += int(c.sks)
	return picked


## cls maps course code -> "A" (good lecturer) or "B" (strict lecturer, from losing the KRS war).
static func set_krs(s: Dictionary, codes: Array, cls: Dictionary, rng: RandomNumberGenerator) -> void:
	s.krs = []
	for c in krs_options(s):
		if codes.has(c.code):
			var entry: Dictionary = c.duplicate(true)
			entry["cls"] = cls.get(c.code, "A")
			s.krs.append(entry)
			if c.type == "skripsi":
				s.skripsi = true
				if s.dospem == "":
					s.dospem = D.DOSPEM_POOL[rng.randi() % D.DOSPEM_POOL.size()]
	s.phase = "week"


static func krs_sks(s: Dictionary) -> int:
	var t := 0
	for c in s.krs:
		t += int(c.sks)
	return t


# --- Weekly planning ---------------------------------------------------------

## True when the KRS holds regular courses (not just the thesis), so class attendance matters.
static func has_classes(s: Dictionary) -> bool:
	for c in s.krs:
		if c.type != "skripsi":
			return true
	return false


static func available_actions(s: Dictionary, slot: String) -> Array:
	if slot == "pagi" and is_exam_week(s) and has_classes(s):
		return ["ujian"]
	var out: Array = []
	for id in D.ACTIONS:
		var a: Dictionary = D.ACTIONS[id]
		if id == "kerja" or a.get("forced", false):
			continue
		if not a.slots.has(slot):
			continue
		if a.get("needs", "") == "skripsi" and not (s.skripsi and not s.skripsi_done):
			continue
		if id == "kuliah" and (not has_classes(s) or week_mod(s).get("no_class", false)):
			continue
		out.append(id)
	if s.job != "" and D.JOBS[s.job].slot == slot:
		out.push_front("kerja")
	return out


## Suggested plan. Without rng it is deterministic (tests/bots); with rng it varies week to week
## while still reacting to energy, mental, social, money and the thesis.
static func default_plan(s: Dictionary, rng: RandomNumberGenerator = null) -> Array:
	var plan: Array = []
	for slot in D.SLOTS:
		var opts := available_actions(s, slot)
		if opts.has("kerja"):
			plan.append("kerja")
		elif slot == "pagi":
			if opts.has("ujian"):
				plan.append("ujian")
			elif opts.has("kuliah"):
				plan.append("kuliah")
			elif opts.has("garap_skripsi"):
				plan.append("garap_skripsi")
			else:
				plan.append(_pick(rng, ["belajar", "olahraga", "belajar"], "belajar"))
		elif slot == "siang":
			if opts.has("bimbingan") and (s.draft > s.acc + 5.0 or s.acc >= 100.0):
				plan.append("bimbingan")
			elif s.mental < 35 and opts.has("konseling"):
				plan.append("konseling")
			elif rng == null:
				plan.append("belajar" if int(s.week) % 2 == 1 or not opts.has("tugas") else "tugas")
			else:
				var pool := ["belajar", "tugas", "belajar", "tugas"]
				if s.social < 40:
					pool.append("organisasi")
				if s.mental < 55:
					pool.append("nongkrong")
				plan.append(_pick(rng, pool, "belajar"))
		elif slot == "malam":
			if opts.has("garap_skripsi") and (not has_classes(s) or int(s.week) % 2 == 0):
				plan.append("garap_skripsi")
			elif rng == null:
				plan.append("tugas")
			else:
				var pool := ["tugas", "tugas", "belajar"]
				if s.mental < 60 or s.social < 45:
					pool.append("nongkrong")
				if s.energy < 35:
					pool = ["tidur"]
				plan.append(_pick(rng, pool, "tugas"))
		else:
			if rng == null or s.energy < 55:
				plan.append("tidur")
			else:
				var pool := ["tidur", "nongkrong", "olahraga", "belajar"]
				if s.coins < 400:
					pool.append("ojol")
				plan.append(_pick(rng, pool, "tidur"))
	return plan


static func _pick(rng: RandomNumberGenerator, pool: Array, fallback: String) -> String:
	if rng == null or pool.is_empty():
		return fallback
	return pool[rng.randi() % pool.size()]


# --- Weekly news ("Kabar Minggu Ini") --------------------------------------------

static func week_mod(s: Dictionary) -> Dictionary:
	var id: String = s.get("week_mod", "normal")
	if s.get("week_mod_tag", "") != "%d-%d" % [s.sem, s.week]:
		id = "normal"
	for m in Data.activities.get("weekly", []):
		if m.id == id:
			return m
	return {"id": "normal", "mods": {}}


## Rolls this week's news once per week (never the same twice in a row).
static func ensure_week_mod(s: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var tag := "%d-%d" % [s.sem, s.week]
	if s.get("week_mod_tag", "") == tag:
		return week_mod(s)
	var pool: Array = []
	var total := 0.0
	for m in Data.activities.get("weekly", []):
		var w: Dictionary = m.get("when", {})
		if w.get("not_exam", false) and is_exam_week(s):
			continue
		if w.has("job") and (s.job != "") != bool(w.job):
			continue
		if m.id == s.get("week_mod", "") and m.id != "normal":
			continue
		if s.week == 1 and m.id == "tanggal_merah":
			continue
		pool.append(m)
		total += float(m.weight)
	var roll := rng.randf() * total
	var chosen: Dictionary = pool[0]
	for m in pool:
		roll -= float(m.weight)
		if roll <= 0.0:
			chosen = m
			break
	s["week_mod"] = chosen.id
	s["week_mod_tag"] = tag
	return chosen


static func _variant(s: Dictionary, a: String, rng: RandomNumberGenerator) -> Dictionary:
	var key := a
	if a == "kerja" and s.job != "":
		var loc: String = D.JOBS[s.job].loc
		key = "kerja_les" if s.job == "les" else ("kerja_asdos" if s.job == "asdos" else ("kerja_home" if loc == "kos" else "kerja"))
	var pool: Array = Data.activities.get("variants", {}).get(key, [])
	if pool.is_empty():
		return {}
	var total := 0.0
	for v in pool:
		total += float(v.get("weight", 1.0))
	var roll := rng.randf() * total
	for v in pool:
		roll -= float(v.get("weight", 1.0))
		if roll <= 0.0:
			return v
	return pool[-1]


## Resolves the 3 slots of the current week plus weekly upkeep.
static func run_week(s: Dictionary, plan: Array, rng: RandomNumberGenerator) -> Dictionary:
	var log: Array = []
	var notes: Array = []
	var wages := 0
	var mod := ensure_week_mod(s, rng)
	if mod.get("no_class", false) and has_classes(s) and not is_exam_week(s):
		s.attend = mini(int(s.attend) + 1, D.WEEKS_PER_SEMESTER)
		notes.append({"id": "Tanggal merah: kehadiran minggu ini otomatis dihitung.", "en": "Public holiday: this week's attendance counts automatically."})
	for i in range(D.SLOTS.size()):
		var slot: String = D.SLOTS[i]
		var a: String = plan[i]
		var res := _resolve_action(s, a, slot, rng)
		wages += int(res.get("wages", 0))
		log.append({"slot": slot, "action": a, "fx": res.fx, "note": res.get("note", {}), "variant": res.get("variant", {}), "scene_key": res.get("scene_key", "")})

	# Skipped contract shifts.
	if s.job != "":
		var job: Dictionary = D.JOBS[s.job]
		if plan[D.SLOTS.find(job.slot)] != "kerja":
			s.job_izin += 1
			if s.job_izin >= 3:
				notes.append({"id": "Mas Bram: \"Udah 3x izin. Mulai besok nggak usah masuk ya.\" Kamu dipecat.", "en": "Mas Bram: \"That's 3 skipped shifts. Don't come back tomorrow.\" You're fired."})
				s.job = ""
				s.job_izin = 0
			else:
				notes.append({"id": "Izin kerja (%d/3). Bos mulai sebel." % s.job_izin, "en": "Skipped a shift (%d/3). Boss is getting annoyed." % s.job_izin})

	# Weekly upkeep.
	_add(s, "energy", D.ENERGY_REGEN + int(mod.get("energy_regen", 0)))
	_add(s, "social", -D.SOCIAL_DECAY)
	s.coins -= D.FOOD_PER_WEEK
	if [1, 5, 9].has(int(s.week)):
		s.coins += s.allowance
		s.coins -= D.KOS_PER_MONTH
		notes.append({"id": "Kiriman ortu +%d, bayar kos -%d." % [s.allowance, D.KOS_PER_MONTH], "en": "Allowance +%d, rent -%d." % [s.allowance, D.KOS_PER_MONTH]})
	if s.energy < 20:
		_add(s, "mental", -6)
		notes.append({"id": "Kurang tidur. Mental ikut turun.", "en": "Sleep-deprived. Mental health dips."})
	if s.coins < 0:
		_add(s, "mental", -5)
		notes.append({"id": "Ngutang di warung. Malu tapi lapar.", "en": "Running a tab at the food stall. Embarrassing, but hungry."})
	# Weekend: a little rest always happens.
	_add(s, "mental", D.WEEKEND_MENTAL)
	if s.mental > 40:
		s.flags.erase("warned")
	s.mental_sum += s.mental
	s.mental_n += 1
	s.stats.weeks += 1
	s.stats.wages += wages
	_check_crisis(s)
	return {"log": log, "notes": notes, "wages": wages}


static func _resolve_action(s: Dictionary, a: String, slot: String, rng: RandomNumberGenerator) -> Dictionary:
	var def: Dictionary = D.ACTIONS[a]
	var fx: Dictionary = def.fx.duplicate()
	var out := {"fx": {}, "note": {}}
	var eff := 1.0
	if s.mental < 30:
		eff *= 0.6
	if s.energy < 15 and fx.get("energy", 0) < 0:
		eff *= 0.5
		fx["mental"] = fx.get("mental", 0) - 3
		out.note = {"id": "Ngantuk berat, nggak fokus.", "en": "Too sleepy to focus."}

	if a == "kerja":
		var job: Dictionary = D.JOBS[s.job]
		fx = {"coins": job.pay, "energy": job.energy, "mental": job.mental}
		if job.has("rel"):
			fx["rel"] = job.rel
	# Random variant of the activity (flavour, small stat tweak, 3D scene) + this week's news.
	if a != "bimbingan":
		var v := _variant(s, a, rng)
		if not v.is_empty():
			out["variant"] = v
			for k in v.fx:
				fx[k] = float(fx.get(k, 0.0)) + float(v.fx[k])
	var mods: Dictionary = week_mod(s).get("mods", {}).get(a, {})
	for k in mods.get("mult", {}):
		if fx.has(k):
			fx[k] = float(fx[k]) * float(mods.mult[k])
	for k in mods.get("add", {}):
		fx[k] = float(fx.get(k, 0.0)) + float(mods.add[k])
	match a:
		"kerja", "ojol":
			out["wages"] = maxi(0, int(fx.get("coins", 0)))
		"konseling":
			if s.konseling_week == s.sem * 100 + s.week:
				fx = {}
				out.note = {"id": "Jadwal konseling minggu ini sudah terpakai.", "en": "This week's counseling slot is used."}
			s.konseling_week = s.sem * 100 + s.week
			s.flags["pernah_konseling"] = true
		"garap_skripsi":
			s.draft = minf(100.0, s.draft + 12.0 * eff)
			out.fx["draft"] = 12.0 * eff
		"bimbingan":
			var b := _bimbingan(s, rng)
			out.note = b.note
			out["scene_key"] = b.scene
		"ujian":
			var ratio: float = s.knowledge / maxf(1.0, D.TARGET_KNOWLEDGE * (0.5 if s.week <= 6 else 1.0))
			if ratio >= 0.9:
				out.note = {"id": "Soalnya keluar persis yang kamu pelajari!", "en": "The questions were exactly what you studied!"}
				s.bonus += 2.0
			elif ratio >= 0.55:
				out.note = {"id": "Lumayan, ada beberapa nomor yang ngarang bebas.", "en": "Not bad, made up a few answers."}
			else:
				out.note = {"id": "Kertas jawaban isinya doa dan curhat.", "en": "Your answer sheet was mostly prayers and venting."}
				s.bonus -= 2.0

	for k in fx:
		var v: float = fx[k]
		if k == "knowledge" or k == "tugas":
			v *= eff
		_apply_fx(s, k, v)
		out.fx[k] = v
	return out


static func _bimbingan(s: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var ghost := 0.15
	var revisi := 0.15
	match s.dospem:
		"dosen_read":
			ghost = 0.45
		"dosen_dinas":
			ghost = 0.5
		"dosen_revisi":
			revisi = 0.42
	ghost = maxf(0.05, ghost - s.rel * 0.012)
	var roll := rng.randf()
	if roll < ghost:
		if s.dospem == "dosen_dinas":
			return {"scene": "dinas", "note": {"id": "Dospem lagi dinas ke luar kota. Lagi.", "en": "Your advisor is out of town. Again."}}
		return {"scene": "ghost", "note": {"id": "Chat bimbingan cuma di-read. Centang biru, hati kelabu.", "en": "Your message was left on read. Blue ticks, grey heart."}}
	if roll < ghost + revisi:
		s.draft = maxf(0.0, s.draft - 8.0)
		s.acc = maxf(0.0, s.acc - 5.0)
		return {"scene": "revisi", "note": {"id": "\"Ganti judul ya. Sama font-nya.\" Revisi besar.", "en": "\"Change the title. And the font.\" Major revision."}}
	if s.acc >= 100.0:
		s.flags["sidang_ready"] = true
		return {"scene": "acc", "note": {"id": "\"Sudah, daftar sidang sana.\"", "en": "\"That's enough, go register for your defense.\""}}
	var gain := minf(s.draft - s.acc, 34.0 + s.rel)
	if gain <= 0.0:
		return {"scene": "kosong", "note": {"id": "\"Mana progresnya?\" Draf kamu belum nambah.", "en": "\"Where's the progress?\" Your draft hasn't grown."}}
	s.acc = minf(100.0, s.acc + gain)
	if s.acc >= 100.0:
		s.flags["sidang_ready"] = true
		return {"scene": "acc", "note": {"id": "ACC MAJU SIDANG! Akhirnya!", "en": "APPROVED FOR DEFENSE! Finally!"}}
	return {"scene": "acc", "note": {"id": "Dospem ACC sebagian. Progres naik!", "en": "Advisor approved part of it. Progress!"}}


static func _check_crisis(s: Dictionary) -> void:
	if s.mental > 0:
		return
	if not has_flag(s, "warned"):
		# Never collapse without a warning first: hold at a low value and let the warning event fire.
		s.mental = 5
		return
	s.ending = "rawat" if s.social >= 35 else "padam"
	s.phase = "ending"


# --- Events ------------------------------------------------------------------

static func event_matches(s: Dictionary, ev: Dictionary) -> bool:
	if ev.get("once", true) and s.seen.has(ev.id):
		return false
	var w: Dictionary = ev.get("when", {})
	if w.has("sem_min") and s.sem < w.sem_min: return false
	if w.has("sem_max") and s.sem > w.sem_max: return false
	if w.has("week_min") and s.week < w.week_min: return false
	if w.has("week_max") and s.week > w.week_max: return false
	if w.has("week") and s.week != w.week: return false
	if w.has("prodi") and not w.prodi.has(s.prodi): return false
	if w.has("mental_max") and s.mental > w.mental_max: return false
	if w.has("mental_min") and s.mental < w.mental_min: return false
	if w.has("coins_max") and s.coins > w.coins_max: return false
	if w.has("coins_min") and s.coins < w.coins_min: return false
	if w.has("social_min") and s.social < w.social_min: return false
	if w.has("ipk_min") and (s.history.is_empty() or ipk(s) < w.ipk_min): return false
	if w.has("job") and (s.job != "") != bool(w.job): return false
	if w.has("job_slot") and (s.job == "" or D.JOBS[s.job].slot != w.job_slot): return false
	if w.has("skripsi") and (s.skripsi and not s.skripsi_done) != bool(w.skripsi): return false
	if w.has("dospem") and s.dospem != w.dospem: return false
	for f in w.get("flags", []):
		if not has_flag(s, f): return false
	for f in w.get("not_flags", []):
		if has_flag(s, f): return false
	if w.has("has_kkn") and not _krs_has_type(s, "kkn"): return false
	return true


static func pick_event(s: Dictionary, rng: RandomNumberGenerator, chance: float = 0.65) -> Dictionary:
	var forced: Array = []
	var pool: Array = []
	for ev in Data.events:
		if not event_matches(s, ev):
			continue
		if ev.get("force", false):
			forced.append(ev)
		else:
			pool.append(ev)
	if not forced.is_empty():
		forced.sort_custom(func(a, b): return a.get("priority", 0) > b.get("priority", 0))
		return forced[0]
	if pool.is_empty() or rng.randf() > chance:
		return {}
	var total := 0.0
	for ev in pool:
		total += float(ev.get("weight", 1.0))
	var roll := rng.randf() * total
	for ev in pool:
		roll -= float(ev.get("weight", 1.0))
		if roll <= 0.0:
			return ev
	return pool[-1]


## Applies choice `idx` of event `ev`. Returns {"result": pair, "fx": dict, "success": bool}.
static func apply_choice(s: Dictionary, ev: Dictionary, idx: int, rng: RandomNumberGenerator) -> Dictionary:
	s.seen[ev.id] = true
	if ev.get("sets_warned", false):
		s.flags["warned"] = true
	var ch: Dictionary = ev.choices[idx]
	var p: float = ch.get("p", 1.0)
	for k in ch.get("p_bonus", {}):
		p += float(ch.p_bonus[k]) * float(s.get(k, 0.0))
	var ok := rng.randf() < p
	var fx: Dictionary = ch.get("fx", {}) if ok else ch.get("fail_fx", {})
	var result: Dictionary = ch.get("result", {}) if ok else ch.get("fail_result", ch.get("result", {}))
	for k in fx:
		_apply_fx(s, k, fx[k])
	for f in (ch.get("set", []) if ok else ch.get("fail_set", [])):
		s.flags[f] = true
	for f in ch.get("unset", []):
		s.flags.erase(f)
	var end_id: String = ch.get("end", "") if ok else ch.get("fail_end", "")
	if end_id != "":
		s.ending = end_id
		s.ending_reason = ch.get("end_reason", "")
		s.phase = "ending"
	if ev.id == "sidang" and ok:
		s.skripsi_done = true
		s.skripsi_score = 70.0 + minf(20.0, s.knowledge) + rng.randf_range(-3.0, 6.0)
	_check_crisis(s)
	return {"result": result, "fx": fx, "success": ok}


# --- Semester end ------------------------------------------------------------

static func finish_semester(s: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var att: float = float(s.attend) / D.WEEKS_PER_SEMESTER
	var pdiff: float = D.PRODI[s.prodi].diff
	var load: float = maxf(1.0, krs_sks(s) / 20.0)
	var rows: Array = []
	var pts := 0.0
	var sks := 0
	for c in s.krs:
		var score := 0.0
		var note := ""
		match c.type:
			"skripsi":
				if not s.skripsi_done:
					rows.append({"code": c.code, "name": c.name, "sks": c.sks, "letter": "T", "point": 0.0, "note": "tunda"})
					continue
				score = s.skripsi_score
			"kkn":
				score = 55.0 + s.social * 0.35 + att * 10.0 + rng.randf_range(-4.0, 4.0)
			_:
				var rk: float = s.knowledge / (D.TARGET_KNOWLEDGE * pdiff * c.diff * load)
				var rt: float = s.tugas / (D.TARGET_TUGAS * pdiff * c.diff * load)
				score = 100.0 * (0.2 * att + 0.42 * minf(rk, 1.0) + 0.38 * minf(rt, 1.0))
				score += s.bonus + (3.0 if c.cls == "A" else -4.0) + rng.randf_range(-5.0, 5.0)
				if att < D.ATTENDANCE_MIN:
					score = minf(score, 40.0)
					note = "absen"
		var g := Data.grade_for(score)
		rows.append({"code": c.code, "name": c.name, "sks": c.sks, "letter": g.letter, "point": g.point, "note": note})
		pts += g.point * c.sks
		sks += int(c.sks)
		var prev: Dictionary = s.grades.get(c.code, {})
		if not prev.is_empty():
			s.flags["retake"] = true
		if prev.is_empty() or g.point > prev.point:
			s.grades[c.code] = {"letter": g.letter, "point": g.point, "sks": c.sks}
		if g.letter == "E":
			s.flags["pernah_e"] = true
	var ips := 0.0 if sks == 0 else pts / sks
	if sks > 0:
		s.low_ips = s.low_ips + 1 if ips < 1.0 else 0
	var entry := {"sem": s.sem, "ips": ips, "ipk": ipk(s), "sks_sem": sks, "sks_total": sks_lulus(s), "courses": rows, "att": att}
	s.history.append(entry)
	s.phase = "khs"
	return entry


## Decides whether the run ends after a KHS. Returns ending id or "".
static func evaluate(s: Dictionary) -> String:
	var ip := ipk(s)
	var lulus := sks_lulus(s)
	var sem: int = s.sem
	if s.skripsi_done and (lulus >= D.SKS_TO_GRADUATE or sem >= D.MAX_SEMESTER):
		if sem >= 13:
			return _end(s, "abadi", "")
		if ip >= 3.90 and sem <= 8 and not has_flag(s, "retake"):
			return _end(s, "summa", "")
		if ip >= 3.0 and sem <= 9 and s.social >= 60 and avg_mental(s) >= 60.0:
			return _end(s, "balance", "")
		if ip >= 3.50 and sem <= 8:
			return _end(s, "cumlaude", "")
		if sem <= 8:
			return _end(s, "tepat", "")
		return _end(s, "telat", "")
	if sem >= D.MAX_SEMESTER:
		return _end(s, "do", "masa_studi")
	if sem == 4 and (ip < 2.0 or lulus < 48):
		return _end(s, "do", "evaluasi")
	if s.low_ips >= 2:
		return _end(s, "do", "ips")
	return ""


static func predikat(s: Dictionary) -> Dictionary:
	var ip := ipk(s)
	if ip >= 3.90 and s.sem <= 8:
		return {"id": "Summa Cum Laude", "en": "Summa Cum Laude"}
	if ip >= 3.50 and s.sem <= 8:
		return {"id": "Cum Laude (Dengan Pujian)", "en": "Cum Laude (With Honors)"}
	if ip >= 3.0:
		return {"id": "Sangat Memuaskan", "en": "Very Satisfactory"}
	return {"id": "Memuaskan", "en": "Satisfactory"}


static func next_semester(s: Dictionary) -> Array:
	s.sem += 1
	s.krs = []
	return enter_semester(s)


# --- Helpers -----------------------------------------------------------------

static func _end(s: Dictionary, id: String, reason: String) -> String:
	s.ending = id
	s.ending_reason = reason
	s.phase = "ending"
	return id


static func _krs_has_type(s: Dictionary, t: String) -> bool:
	for c in s.krs:
		if c.type == t:
			return true
	return false


static func _add(s: Dictionary, key: String, v: float) -> void:
	s[key] = clampi(int(round(s[key] + v)), 0, 100)


static func _apply_fx(s: Dictionary, k: String, v: Variant) -> void:
	match k:
		"energy", "mental", "social":
			_add(s, k, v)
		"coins":
			s.coins += int(v)
		"knowledge", "tugas", "bonus", "draft", "acc":
			s[k] = maxf(0.0, float(s[k]) + float(v))
			if k == "draft" or k == "acc":
				s[k] = minf(100.0, s[k])
			if k == "acc" and s.acc >= 100.0 and s.skripsi and not s.skripsi_done:
				s.flags["sidang_ready"] = true
		"attend":
			s.attend = clampi(int(s.attend) + int(v), 0, D.WEEKS_PER_SEMESTER)
		"rel":
			s.rel = clampi(int(s.rel) + int(v), -10, 15)
		"ukt_mult":
			s.ukt_mult *= float(v)
		"debt":
			s.debt += int(v)
		"job_izin":
			if s.job != "":
				s.job_izin += int(v)
		"job_fire":
			s.job = ""
			s.job_izin = 0
		"allowance":
			s.allowance = maxi(0, int(s.allowance) + int(v))


static func _r(ok: bool, id_text: String, en_text: String) -> Dictionary:
	return {"ok": ok, "msg": {"id": id_text, "en": en_text}}

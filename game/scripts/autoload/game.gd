extends Node
## Owns the current run: wraps Sim rules with saving, signals and cross-run (Meta) effects.

signal changed

const SAVE_PATH := "user://run.json"

var s: Dictionary = {}
var rng := RandomNumberGenerator.new()
var last_report: Dictionary = {}
var pending_notes: Array = []


func _ready() -> void:
	rng.randomize()


func has_run() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func new_run(player_name: String, prodi: String, look: Dictionary, carry_coins: int = 0) -> void:
	rng.randomize()
	s = Sim.new_state(player_name, prodi, look, rng, carry_coins)
	Sim.enter_semester(s)
	Meta.runs += 1
	Meta.save_meta()
	save_run()
	changed.emit()


func load_run() -> bool:
	if not has_run():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary) or d.get("v", 0) != 1:
		return false
	s = d
	changed.emit()
	return true


func save_run() -> void:
	if s.is_empty() or s.phase == "ending":
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(s))


func clear_run() -> void:
	if has_run():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func touch() -> void:
	save_run()
	changed.emit()


# --- Shop & wardrobe ---------------------------------------------------------

func buy_item(id: String) -> Dictionary:
	var it: Dictionary = Data.ITEMS[id]
	if Meta.owns(id):
		return _r(false, "Sudah punya.", "Already owned.")
	if it.has("price_d"):
		if Meta.diamonds < it.price_d:
			return _r(false, "Diamond kurang.", "Not enough diamonds.")
		Meta.add_diamonds(-int(it.price_d))
	else:
		if s.is_empty():
			return _r(false, "Mulai kuliah dulu untuk belanja pakai koin.", "Start a run to shop with coins.")
		if s.coins < it.price_c:
			return _r(false, "Koin kurang. Tahan dulu khilafnya.", "Not enough coins. Hold off on the impulse buy.")
		s.coins -= int(it.price_c)
		s.stats.spent_khilaf += int(it.price_c)
	Meta.grant_item(id)
	touch()
	return _r(true, "Dibeli! Cek di Lemari.", "Purchased! Check your Wardrobe.")


func equip(id: String) -> void:
	if s.is_empty() or not Meta.owns(id):
		return
	s.look[Data.ITEMS[id].slot] = id
	touch()


func buy_consumable(id: String) -> Dictionary:
	var c: Dictionary = Data.CONSUMABLES[id]
	if c.has("price_d"):
		if Meta.diamonds < c.price_d:
			return _r(false, "Diamond kurang.", "Not enough diamonds.")
		Meta.add_diamonds(-int(c.price_d))
	else:
		if s.coins < c.price_c:
			return _r(false, "Koin kurang.", "Not enough coins.")
		s.coins -= int(c.price_c)
	for k in c.fx:
		Sim._apply_fx(s, k, c.fx[k])
	touch()
	return _r(true, "Glek! Energi naik.", "Gulp! Energy up.")


func exchange_diamonds() -> Dictionary:
	var ex: Dictionary = Data.DIAMOND_TO_COIN
	if Meta.diamonds < ex.diamonds:
		return _r(false, "Diamond kurang.", "Not enough diamonds.")
	Meta.add_diamonds(-int(ex.diamonds))
	s.coins += int(ex.coins)
	touch()
	return _r(true, "Ditukar ke %d koin." % ex.coins, "Exchanged for %d coins." % ex.coins)


# --- Jobs ----------------------------------------------------------------------

func job_block_reason(id: String) -> Dictionary:
	var j: Dictionary = Data.JOBS[id]
	if j.has("prodi") and j.prodi != s.prodi:
		return Loc.T("Khusus prodi %s." % Loc.main(Data.PRODI[j.prodi].name), "%s majors only." % Data.PRODI[j.prodi].name.en)
	if s.sem < int(j.get("min_sem", 1)):
		return Loc.T("Minimal semester %d." % j.min_sem, "Semester %d or above." % j.min_sem)
	if j.has("min_ipk") and (s.history.is_empty() or Sim.ipk(s) < j.min_ipk):
		return Loc.T("IPK minimal %.2f." % j.min_ipk, "GPA %.2f or above." % j.min_ipk)
	return {}


func take_job(id: String) -> void:
	s.job = id
	s.job_izin = 0
	touch()


func quit_job() -> void:
	s.job = ""
	s.job_izin = 0
	touch()


# --- Flow ----------------------------------------------------------------------

func pay_ukt(method: String) -> Dictionary:
	var r := Sim.pay_ukt(s, method, rng)
	touch()
	return r


func confirm_krs(codes: Array, cls: Dictionary) -> void:
	Sim.set_krs(s, codes, cls, rng)
	touch()


## This week's news (rolled once per week, saved).
func ensure_week() -> Dictionary:
	var m := Sim.ensure_week_mod(s, rng)
	save_run()
	return m


func suggest_plan() -> Array:
	ensure_week()
	return Sim.default_plan(s, rng)


func run_week(plan: Array) -> Dictionary:
	var r := Sim.run_week(s, plan, rng)
	touch()
	return r


func pick_event() -> Dictionary:
	return Sim.pick_event(s, rng)


func choose(ev: Dictionary, idx: int) -> Dictionary:
	var r := Sim.apply_choice(s, ev, idx, rng)
	if r.fx.has("item"):
		Meta.grant_item(r.fx.item)
	touch()
	return r


## Advances the calendar after a week's events. Returns "week", "khs" or "ending".
func end_week() -> String:
	if s.phase == "ending":
		return "ending"
	s.week += 1
	if s.week > Data.WEEKS_PER_SEMESTER:
		last_report = Sim.finish_semester(s, rng)
		touch()
		return "khs"
	touch()
	return "week"


## Called after the KHS screen. Returns "ending" or "ukt".
func after_khs() -> String:
	if Sim.evaluate(s) != "":
		return "ending"
	pending_notes = Sim.next_semester(s)
	touch()
	return "ukt"


func switch_major(new_prodi: String) -> void:
	s.ending = "pindah"
	s.flags["pindah_to"] = new_prodi
	s.phase = "ending"


## Records the ending in the gallery and removes the save. Returns true when unlocked for the first time.
func finalize_ending() -> bool:
	var first := Meta.record_ending(s.ending, s.name)
	clear_run()
	return first


func _r(ok: bool, i: String, e: String) -> Dictionary:
	return {"ok": ok, "msg": {"id": i, "en": e}}

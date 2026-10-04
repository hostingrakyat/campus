class_name MiniGame
extends Control
## Interactive moment inside a weekly activity, played over the 3D scene.
## Kinds (see MiniGames): catch, timing, mash, quiz, chat. Emits `finished(score)` with 0..1.
## Every game ends on its own when the timer runs out, so the week never stalls.

signal finished(score: float)

const PLAY_TOP := 330.0

var main: Node
var cfg: Dictionary
var ctx: Dictionary
var kind := ""
var score := 0.0

var _panel: PanelContainer
var _area: VBoxContainer
var _timer_bar: ProgressBar
var _time_lbl: Label
var _time_total := 6.0
var _time_left := 6.0
var _running := false
var _done := false
var _rng := RandomNumberGenerator.new()

# catch
var _spawn_t := 0.0
var _good_spawned := 0
var _good_hit := 0
var _bad_hit := 0
var _count_lbl: Label
var _targets: Array = []
# timing
var _gauge: Gauge
var _round := 0
var _round_scores: Array = []
var _needle_v := 0.9
var _lock := 0.0
var _feedback: Label
# mash
var _taps := 0
var _doc: Label
var _fill: ProgressBar
# quiz / chat
var _q_idx := 0
var _right := 0
var _answer_btns: Array = []


func _init(m: Node, config: Dictionary, context: Dictionary = {}) -> void:
	main = m
	cfg = config
	ctx = context
	kind = cfg.kind
	_rng.randomize()
	Kit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var fast: bool = Meta.settings.get("fast_scenes", false)
	_time_total = float(cfg.get("time", 6.0)) * (0.8 if fast else 1.0)
	_time_left = _time_total
	_panel = Kit.panel(Kit.PAPER, 30, 20)
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = 14
	_panel.offset_right = -14
	_panel.offset_bottom = -26
	add_child(_panel)
	var v := Kit.vbox(10)
	_panel.add_child(v)
	var head := Kit.hbox(10)
	v.add_child(head)
	head.add_child(Kit.chip(Loc.main(Loc.T("INTERAKSI", "INTERACT")), Kit.PURPLE, Color.WHITE, 18, "gamepad-2"))
	var t := Kit.label(Loc.main(cfg.title), 28, Kit.INK, Kit.font_display)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(Kit.icon_rect("clock", 22, Kit.INK_SOFT))
	_time_lbl = Kit.label("", 22, Kit.INK_SOFT, Kit.font_bold)
	head.add_child(_time_lbl)
	var skip := Kit.compact(Kit.button(Loc.T("Lewati", "Skip"), Color("8a8398"), func(): _finish(0.0, true), 18, 48, false), 12)
	head.add_child(skip)
	v.add_child(Kit.dual(cfg.hint, 21, Kit.INK_SOFT))
	_timer_bar = Kit.bar(100, 100, Kit.ORANGE, 12)
	v.add_child(_timer_bar)
	_area = Kit.vbox(10)
	v.add_child(_area)
	match kind:
		"catch":
			_build_catch()
		"timing":
			_build_timing()
		"mash":
			_build_mash()
		"quiz":
			_build_quiz()
		"chat":
			_build_chat()
	Fx.slide_in(_panel, Vector2(0, 260), 0.0, 0.32)
	Audio.play("card", -4.0)
	await get_tree().create_timer(0.35).timeout
	_running = true


func _process(delta: float) -> void:
	if not _running or _done:
		return
	# A loading hitch must not eat the player's time.
	delta = minf(delta, 0.1 * Engine.time_scale)
	_time_left -= delta
	_timer_bar.value = maxf(0.0, _time_left / _time_total * 100.0)
	_time_lbl.text = "%.1f" % maxf(0.0, _time_left)
	match kind:
		"catch":
			_tick_catch(delta)
		"timing":
			_tick_timing(delta)
	if _time_left <= 0.0:
		_on_timeout()


func _on_timeout() -> void:
	match kind:
		"catch":
			_finish(_catch_score())
		"timing":
			while _round_scores.size() < int(cfg.rounds):
				_round_scores.append(0.0)
			_finish(_avg(_round_scores))
		"mash":
			_finish(minf(1.0, float(_taps) / float(cfg.target)))
		"quiz":
			_finish(float(_right) / float(cfg.questions.size()))
		"chat":
			_finish(0.0)


func _finish(s: float, skipped: bool = false) -> void:
	if _done:
		return
	_done = true
	_running = false
	score = clampf(s, 0.0, 1.0) if not skipped else 0.0
	for tg in _targets:
		if is_instance_valid(tg):
			tg.queue_free()
	_targets.clear()
	for b in find_children("*", "Button", true, false):
		b.disabled = true
	if not skipped:
		var g := MiniGames.grade(score)
		_stamp(Loc.main(g[1]), g[2])
		var p: VinylChar = main.world.player
		if score >= 0.55:
			Audio.play("levelup" if score >= 0.85 else "good", -4.0)
			p.emote("!" if score < 0.85 else "<3", Color("2fbf71"))
		else:
			Audio.play("bad", -6.0)
			p.emote("...", Color("5d5670"))
		await get_tree().create_timer(1.0).timeout
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.18)
	tw.tween_property(_panel, "offset_top", _panel.offset_top + 200, 0.18)
	tw.tween_property(_panel, "offset_bottom", _panel.offset_bottom + 200, 0.18)
	await tw.finished
	finished.emit(score)


func _stamp(text: String, color: Color) -> void:
	var l := Kit.title(text, 64, Color.WHITE)
	l.add_theme_color_override("font_outline_color", color.darkened(0.2))
	l.add_theme_constant_override("outline_size", 22)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.offset_left = -340
	l.offset_right = 340
	l.offset_top = 470
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	Fx.pop_in(l, 0.0, 0.4, 0.4)
	l.rotation = -0.06


func _avg(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var t := 0.0
	for x in a:
		t += float(x)
	return t / a.size()


# --- catch -----------------------------------------------------------------------------

func _build_catch() -> void:
	_count_lbl = Kit.label("", 24, Kit.INK, Kit.font_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_area.add_child(_count_lbl)
	_update_count()


func _update_count() -> void:
	_count_lbl.text = Loc.main(Loc.T("Dapat: %d   Salah: %d", "Got: %d   Wrong: %d")) % [_good_hit, _bad_hit]


func _catch_score() -> float:
	return clampf(float(_good_hit) / maxf(1.0, _good_spawned * 0.8) - _bad_hit * 0.2, 0.0, 1.0)


func _tick_catch(delta: float) -> void:
	_spawn_t -= delta
	if _spawn_t <= 0.0 and _time_left > 0.8:
		_spawn_t = _rng.randf_range(0.42, 0.62)
		_spawn_target(_rng.randf() < 0.7)


func _spawn_target(good: bool) -> void:
	var pool: Array = cfg.good if good else cfg.bad
	var pair: Dictionary = pool[_rng.randi() % pool.size()]
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.set_meta("silent", true)
	b.text = Loc.main(pair)
	b.add_theme_font_override("font", Kit.font_bold)
	b.add_theme_font_size_override("font_size", 24)
	var st := Kit.card_style(Color("fff3c4") if good else Color("3b3350"), 40, true)
	st.set_content_margin_all(16)
	st.border_color = Kit.GOLD if good else Kit.RED
	st.set_border_width_all(4)
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, st)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, Kit.INK if good else Color.WHITE)
	b.custom_minimum_size = Vector2(170, 92)
	add_child(b)
	var vw := get_viewport_rect().size
	var bottom := _panel.get_global_rect().position.y - 110.0
	var sz := b.get_combined_minimum_size()
	b.size = sz
	b.position = Vector2(_rng.randf_range(24.0, vw.x - sz.x - 24.0), _rng.randf_range(PLAY_TOP, maxf(PLAY_TOP + 10.0, bottom)))
	b.set_meta("good", good)
	if good:
		_good_spawned += 1
	_targets.append(b)
	Fx.pop_in(b, 0.0, 0.5, 0.25)
	b.button_down.connect(func(): _hit(b))
	var life := b.create_tween()
	life.tween_interval(1.25)
	life.tween_property(b, "modulate:a", 0.0, 0.25)
	life.tween_callback(func():
		_targets.erase(b)
		b.queue_free())


func _hit(b: Button) -> void:
	if _done or b.get_meta("hit", false):
		return
	b.set_meta("hit", true)
	b.disabled = true
	if b.get_meta("good"):
		_good_hit += 1
		Audio.play("pop", -4.0, 1.0 + _good_hit * 0.03)
		main.world.player.hop()
	else:
		_bad_hit += 1
		Audio.play("error", -6.0)
		Fx.shake(_panel, 8.0)
	_update_count()
	_targets.erase(b)
	Fx.center_pivot(b)
	var tw := b.create_tween().set_parallel(true)
	tw.tween_property(b, "scale", Vector2(1.35, 1.35), 0.16)
	tw.tween_property(b, "modulate:a", 0.0, 0.16)
	tw.chain().tween_callback(b.queue_free)


# --- timing ----------------------------------------------------------------------------

class Gauge extends Control:
	var needle := 0.0
	var zone_c := 0.5
	var zone_w := 0.2
	var flash := Color(0, 0, 0, 0)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(_box(Color("ece5d8"), 20), r)
		var zx := (zone_c - zone_w * 0.5) * size.x
		draw_style_box(_box(Color("2fbf71"), 14), Rect2(zx, 6, zone_w * size.x, size.y - 12))
		draw_rect(Rect2(zone_c * size.x - 2, 6, 4, size.y - 12), Color(1, 1, 1, 0.8))
		if flash.a > 0.0:
			draw_style_box(_box(flash, 20), r)
		var nx := needle * size.x
		draw_rect(Rect2(nx - 5, -6, 10, size.y + 12), Color("2a2238"))
		draw_circle(Vector2(nx, -8), 11, Color("ff5a4e"))

	func _box(c: Color, rad: int) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = c
		s.set_corner_radius_all(rad)
		return s


func _build_timing() -> void:
	_gauge = Gauge.new()
	_gauge.custom_minimum_size = Vector2(0, 64)
	_area.add_child(Kit.margin(_gauge, 10, 16, 10, 4))
	_new_zone()
	_feedback = Kit.label(Loc.main(Loc.T("Ronde 1/%d", "Round 1/%d")) % int(cfg.rounds), 22, Kit.INK_SOFT, Kit.font_bold, HORIZONTAL_ALIGNMENT_CENTER)
	_area.add_child(_feedback)
	var b := Kit.button(cfg.btn, Kit.GREEN, Callable(), 30, 96, false)
	Kit.set_icon(b, "clock", 30)
	b.set_meta("silent", true)
	b.button_down.connect(_timing_tap)
	_area.add_child(b)


func _new_zone() -> void:
	_gauge.zone_w = maxf(0.12, 0.24 - _round * 0.04)
	_gauge.zone_c = _rng.randf_range(0.2, 0.8)
	_gauge.needle = 0.0 if _rng.randf() < 0.5 else 1.0
	_needle_v = (0.85 + _round * 0.25) * (1.0 if _gauge.needle == 0.0 else -1.0)
	_gauge.queue_redraw()


func _tick_timing(delta: float) -> void:
	if _lock > 0.0:
		_lock -= delta
		_gauge.flash.a = maxf(0.0, _gauge.flash.a - delta * 1.5)
		_gauge.queue_redraw()
		if _lock <= 0.0:
			_new_zone()
		return
	_gauge.needle += _needle_v * delta
	if _gauge.needle > 1.0:
		_gauge.needle = 2.0 - _gauge.needle
		_needle_v = -absf(_needle_v)
	elif _gauge.needle < 0.0:
		_gauge.needle = -_gauge.needle
		_needle_v = absf(_needle_v)
	_gauge.queue_redraw()


func _timing_tap() -> void:
	if not _running or _done or _lock > 0.0:
		return
	var d := absf(_gauge.needle - _gauge.zone_c)
	var half := _gauge.zone_w * 0.5
	var s := 0.0
	if d <= half:
		s = 1.0 - 0.35 * d / half
	else:
		s = maxf(0.0, 0.4 * (1.0 - (d - half) / 0.2))
	_round_scores.append(s)
	_round += 1
	var good := s >= 0.65
	_gauge.flash = Color(0.18, 0.75, 0.44, 0.45) if good else Color(1.0, 0.35, 0.3, 0.45)
	_feedback.text = (Loc.main(Loc.T("Pas!", "Spot on!")) if s >= 0.9 else (Loc.main(Loc.T("Oke!", "Okay!")) if good else Loc.main(Loc.T("Meleset!", "Missed!"))))
	_feedback.add_theme_color_override("font_color", Kit.GREEN if good else Kit.RED)
	Fx.pulse(_feedback, 1.25)
	Audio.play("select" if good else "error", -5.0, 1.0 + _round * 0.08)
	var p: VinylChar = main.world.player
	if good:
		p.hop()
	else:
		p.shake_head()
	if _round >= int(cfg.rounds):
		_finish(_avg(_round_scores))
	else:
		_lock = 0.55


# --- mash ------------------------------------------------------------------------------

func _build_mash() -> void:
	var paper := Kit.panel(Color.WHITE, 16, 14)
	_doc = Kit.label(cfg.text, 20, Kit.INK, null, HORIZONTAL_ALIGNMENT_LEFT, true)
	_doc.custom_minimum_size = Vector2(0, 84)
	_doc.visible_ratio = 0.0
	paper.add_child(_doc)
	_area.add_child(paper)
	_fill = Kit.bar(0, 100, Kit.BLUE, 18)
	_area.add_child(_fill)
	var b := Kit.button(cfg.btn, Kit.BLUE, Callable(), 32, 104, false)
	Kit.set_icon(b, "zap", 32)
	b.set_meta("silent", true)
	b.button_down.connect(_mash_tap)
	_area.add_child(b)


func _mash_tap() -> void:
	if not _running or _done:
		return
	_taps += 1
	var r := minf(1.0, float(_taps) / float(cfg.target))
	_doc.visible_ratio = r
	_fill.value = r * 100.0
	Audio.play("tick", -8.0, 0.9 + _rng.randf() * 0.3, 0.0)
	main.world.player.play("type" if main.world.player.pose == "sit" else "write")
	if r >= 1.0:
		_finish(1.0)


func _unhandled_input(e: InputEvent) -> void:
	if not _running or _done:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		match kind:
			"mash":
				_mash_tap()
			"timing":
				if e.keycode == KEY_SPACE or e.keycode == KEY_ENTER:
					_timing_tap()


# --- quiz ------------------------------------------------------------------------------

func _build_quiz() -> void:
	_show_question()


func _show_question() -> void:
	for c in _area.get_children():
		c.queue_free()
	_answer_btns.clear()
	var q: Dictionary = cfg.questions[_q_idx]
	if cfg.questions.size() > 1:
		_area.add_child(Kit.label(Loc.main(Loc.T("Soal %d/%d", "Question %d/%d")) % [_q_idx + 1, cfg.questions.size()], 20, Kit.PURPLE, Kit.font_bold))
	_area.add_child(Kit.dual(q.q, 26, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true))
	_speak(cfg.get("who", ""), Loc.main(q.q))
	for i in q.a.size():
		var idx: int = i
		var b := Kit.plain(Kit.button(q.a[i], [Kit.BLUE, Kit.PURPLE, Kit.ORANGE][i], func(): _answer(idx), 22, 0, true))
		b.set_meta("silent", true)
		_answer_btns.append(b)
		_area.add_child(b)
		Fx.pop_in(b, 0.05 * i)
	_time_left = _time_total
	_time_total = float(cfg.time) * (0.8 if Meta.settings.get("fast_scenes", false) else 1.0)


func _answer(i: int) -> void:
	if not _running or _done:
		return
	_running = false
	var q: Dictionary = cfg.questions[_q_idx]
	var ok: bool = i == int(q.right)
	if ok:
		_right += 1
		Audio.play("good", -6.0)
		main.world.player.hop()
	else:
		Audio.play("error", -6.0)
		main.world.player.shake_head()
	for k in _answer_btns.size():
		var b: Button = _answer_btns[k]
		b.disabled = true
		if k == int(q.right):
			Kit.style_button(b, Kit.GREEN)
		elif k == i:
			Kit.style_button(b, Kit.RED)
		else:
			b.modulate.a = 0.5
	await get_tree().create_timer(0.7).timeout
	if _done:
		return
	_q_idx += 1
	if _q_idx >= cfg.questions.size():
		_finish(float(_right) / float(cfg.questions.size()))
		return
	_show_question()
	_running = true


# --- chat ------------------------------------------------------------------------------

func _build_chat() -> void:
	var who := _npc_id(cfg.get("who", ""))
	var row := Kit.hbox(12)
	if Data.NPCS.has(who):
		row.add_child(Kit.avatar(who, 60))
		row.add_child(Kit.label(Data.NPCS[who].name, 24, Kit.INK, Kit.font_bold))
		_area.add_child(row)
	_area.add_child(Kit.dual(cfg.q, 25, Kit.INK, HORIZONTAL_ALIGNMENT_LEFT, true))
	_speak(cfg.get("who", ""), Loc.main(cfg.q))
	for i in cfg.opts.size():
		var idx: int = i
		var b := Kit.plain(Kit.button(cfg.opts[i][0], [Kit.BLUE, Kit.PURPLE, Kit.ORANGE][i], func(): _pick(idx), 21, 0, true))
		b.set_meta("silent", true)
		_answer_btns.append(b)
		_area.add_child(b)
		Fx.pop_in(b, 0.05 * i)


func _pick(i: int) -> void:
	if not _running or _done:
		return
	_running = false
	var s: float = cfg.opts[i][1]
	Audio.play("card_place", -4.0)
	for k in _answer_btns.size():
		var b: Button = _answer_btns[k]
		b.disabled = true
		if k != i:
			b.modulate.a = 0.4
	main.world.player.say(Loc.main(cfg.opts[i][0]), 2.0)
	var actor := _actor(cfg.get("who", ""))
	if actor:
		if s >= 0.85:
			actor.emote("<3", Color("ff6b9a"))
			actor.play("laugh")
		elif s >= 0.5:
			actor.emote("!", Color("ff9f1c"))
		else:
			actor.emote("...", Color("5d5670"))
			actor.shake_head()
	await get_tree().create_timer(0.8).timeout
	_finish(s)


# --- helpers ---------------------------------------------------------------------------

func _npc_id(who: String) -> String:
	match who:
		"lecturer":
			return ctx.get("lecturer", "dosen_read")
		"dospem":
			var d: String = ctx.get("dospem", "")
			return d if d != "" else "dosen_read"
		"friend":
			return ctx.get("friend", "ambis")
	return who


func _actor(who: String) -> VinylChar:
	if who == "":
		return null
	var a: VinylChar = main.world.director.actor_for(who, ctx, false)
	return a if a and a.visible else null


## The question is already in the panel; the speaker just turns to the player and talks.
func _speak(who: String, _text: String) -> void:
	var a := _actor(who)
	if a:
		a.play("talk")
		a.emote("?", Color("ff9f1c"), 1.4)


## Lets the autoplay test exercise the games: a decent but imperfect player.
func bot_play() -> void:
	if not _running or _done:
		return
	match kind:
		"catch":
			for t in _targets.duplicate():
				if is_instance_valid(t) and (t.get_meta("good") or randf() < 0.1) and randf() < 0.3:
					_hit(t)
		"timing":
			if absf(_gauge.needle - _gauge.zone_c) < _gauge.zone_w * 0.4 or randf() < 0.01:
				_timing_tap()
		"mash":
			if randf() < 0.6:
				_mash_tap()
		"quiz":
			if randf() < 0.05:
				_answer(int(cfg.questions[_q_idx].right) if randf() < 0.7 else randi() % 3)
		"chat":
			if randf() < 0.05:
				_pick(randi() % cfg.opts.size())

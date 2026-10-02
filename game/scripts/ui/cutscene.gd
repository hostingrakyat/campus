class_name Cutscene
extends Control
## Story event as a cinematic: letterbox bars, the scene staged in 3D (speaker walks in), a
## visual-novel dialogue box with typewriter text, choices, the player's line, a reaction
## (cheer / slump) and the outcome.

signal done
signal _tapped
signal _chosen(idx: int)

var main: Node
var ev: Dictionary
var ctx: Dictionary
var director: Director
var speaker: VinylChar

var _top: ColorRect
var _curtain: ColorRect
var _tap_btn: Button
var _box: PanelContainer
var _who_row: HBoxContainer
var _text: DualLabel
var _extra: VBoxContainer
var _hint: Label
var _typing := false


func _init(m: Node, e: Dictionary, c: Dictionary = {}) -> void:
	main = m
	ev = e
	ctx = c
	Kit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	director = main.world.director
	# Tap anywhere to advance (sits under the dialogue box).
	_tap_btn = Button.new()
	_tap_btn.flat = true
	_tap_btn.focus_mode = Control.FOCUS_NONE
	_tap_btn.set_meta("silent", true)
	Kit.full_rect(_tap_btn)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		_tap_btn.add_theme_stylebox_override(st, empty)
	add_child(_tap_btn)
	_tap_btn.pressed.connect(_on_tap)

	_top = ColorRect.new()
	_top.color = Color(0.06, 0.05, 0.1)
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top.offset_bottom = 0
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)

	_box = Kit.panel(Kit.PAPER, 34, 24)
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_box.offset_left = 14
	_box.offset_right = -14
	_box.offset_bottom = -26
	_box.custom_minimum_size.y = 300
	add_child(_box)
	var v := Kit.vbox(12)
	_box.add_child(v)
	_who_row = Kit.hbox(12)
	v.add_child(_who_row)
	_text = Kit.dual({}, 27)
	v.add_child(_text)
	_extra = Kit.vbox(10)
	v.add_child(_extra)
	_hint = Kit.label(Loc.main(Loc.T("Ketuk untuk lanjut  >", "Tap to continue  >")), 18, Kit.INK_SOFT, Kit.font_bold, HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_child(_hint)
	var blink := _hint.create_tween().set_loops()
	blink.tween_property(_hint, "modulate:a", 0.3, 0.6)
	blink.tween_property(_hint, "modulate:a", 1.0, 0.6)

	_curtain = Kit.full_rect(ColorRect.new())
	_curtain.color = Color(0.06, 0.05, 0.1, 0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_curtain)
	_run()


func _run() -> void:
	_box.visible = false
	var tw := create_tween()
	tw.tween_property(_curtain, "color:a", 1.0, 0.2)
	await tw.finished
	var behind: Control = main.screen
	if behind:
		behind.visible = false
	Audio.play("whoosh", -8.0)
	speaker = director.stage_event(ev, ctx, 0.4)
	create_tween().tween_property(_top, "offset_bottom", 120.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	var tw2 := create_tween()
	tw2.tween_property(_curtain, "color:a", 0.0, 0.3)
	await get_tree().create_timer(1.1 if speaker and speaker.walking else 0.6).timeout
	if Data.NPCS.get(ev.speaker, {}).get("name", "") != "" and ev.speaker in Director.PHONE_SPEAKERS:
		Audio.play("bell", -6.0)

	# 1) Speaker's line.
	var s: Dictionary = Game.s
	var dospem_name: String = Data.NPCS[s.dospem].name if s.get("dospem", "") != "" else "-"
	_box.visible = true
	Fx.slide_in(_box, Vector2(0, 260), 0.0, 0.35)
	Audio.play("card", -4.0)
	_set_who(ev.speaker)
	await _say(Loc.fill(ev.text, {"name": s.name, "dospem": dospem_name}), speaker)
	await _tapped

	# 2) Choices.
	_hint.visible = false
	_tap_btn.disabled = true
	for i in ev.choices.size():
		var ch: Dictionary = ev.choices[i]
		var b := Kit.button(ch.label, [Kit.BLUE, Kit.PURPLE, Kit.ORANGE][i % 3], func(): _chosen.emit(i), 22)
		_extra.add_child(b)
		Fx.pop_in(b, i * 0.08)
	var idx: int = await _chosen
	for c in _extra.get_children():
		c.queue_free()
	_tap_btn.disabled = false

	# 3) Player's line.
	_set_who("player")
	Audio.play("card_place", -4.0)
	await _say(ev.choices[idx].label, main.world.player)
	await get_tree().create_timer(0.5).timeout

	# 4) Outcome + reaction.
	var r := Game.choose(ev, idx)
	var good := _is_good(r)
	var p: VinylChar = main.world.player
	if good:
		p.play("cheer")
		p.hop()
		p.emote("!", Color("2fbf71"))
		Audio.play("good", -4.0)
		if speaker:
			speaker.play("laugh")
	else:
		p.play("sad")
		p.shake_head()
		p.emote("...", Color("5d5670"))
		Audio.play("bad", -4.0)
		if speaker:
			speaker.play("listen")
	_set_who("")
	await _say(r.result, null)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	for f in Kit.fx_text(r.fx):
		chips.add_child(Kit.chip(f.text, Color("e3f7ea") if f.good else Color("ffe6e3"), Color("17643a") if f.good else Color("b3261e"), 20))
	_extra.add_child(chips)
	Fx.stagger(chips, 0.06)
	_hint.visible = true
	await _tapped

	# 5) Outro.
	_box.visible = false
	var out := create_tween().set_parallel(true)
	out.tween_property(_top, "offset_bottom", 0.0, 0.25)
	out.tween_property(_curtain, "color:a", 1.0, 0.25)
	await out.finished
	director.clear()
	if is_instance_valid(behind):
		behind.visible = true
	done.emit()


func _is_good(r: Dictionary) -> bool:
	if not r.success:
		return false
	var score := 0.0
	for k in ["mental", "social", "energy"]:
		score += float(r.fx.get(k, 0.0))
	score += float(r.fx.get("coins", 0.0)) / 50.0 + float(r.fx.get("bonus", 0.0)) * 3.0 + float(r.fx.get("rel", 0.0)) * 3.0
	return score >= 0.0


func _set_who(who: String) -> void:
	for c in _who_row.get_children():
		c.queue_free()
	if who == "":
		_who_row.add_child(Kit.chip(Loc.main(Loc.T("Hasilnya...", "Outcome...")), Kit.INK, Color.WHITE, 22))
		return
	if who == "player":
		var s: Dictionary = Game.s
		_who_row.add_child(Icon.make("badge", 64, Data.PRODI[s.prodi].color, s.prodi))
		_who_row.add_child(Kit.label(s.name, 28, Kit.INK, Kit.font_bold))
		return
	var npc: Dictionary = Data.NPCS.get(who, Data.NPCS.narator)
	if npc.name == "":
		return
	_who_row.add_child(Kit.avatar(who, 64))
	var col := Kit.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_text: String = npc.name
	if who in Director.PHONE_SPEAKERS:
		name_text += "  " + Loc.main(Loc.T("(telepon)", "(phone)"))
	col.add_child(Kit.label(name_text, 26, Kit.INK, Kit.font_bold))
	col.add_child(Kit.dual(npc.role, 18, Kit.INK_SOFT))
	_who_row.add_child(col)
	Fx.pop_in(_who_row, 0.0, 0.9)


## Typewriter line; the talking actor animates while text appears. Tapping completes it.
func _say(pair: Dictionary, actor: VinylChar) -> void:
	_text.set_pair(pair)
	_text.sub_label.modulate.a = 0.0
	if actor:
		actor.play("phone" if actor == main.world.player and main.world.player.pose == "sit" and _is_phone() else "talk")
	_typing = true
	_text.main_label.visible_ratio = 0.0
	var dur := clampf(_text.main_label.text.length() / 70.0, 0.25, 2.2)
	var tw := create_tween()
	tw.tween_property(_text.main_label, "visible_ratio", 1.0, dur)
	var t := 0.0
	while _typing and t < dur:
		await get_tree().process_frame
		t += get_process_delta_time()
	tw.kill()
	_text.main_label.visible_ratio = 1.0
	_typing = false
	create_tween().tween_property(_text.sub_label, "modulate:a", 1.0, 0.3)
	if actor and actor != main.world.player:
		actor.play("idle" if actor.pose != "sit" else "listen")


func _is_phone() -> bool:
	return ev.speaker in Director.PHONE_SPEAKERS


func _on_tap() -> void:
	if _typing:
		_typing = false
		return
	_tapped.emit()

class_name ExploreMode
extends Control
## Free campus walk between weeks: virtual joystick (or keyboard / gamepad), an action button for
## whatever is nearby, and a small quest line (coins + the hidden diamond).

signal closed

var main: Node
var ex: Explorer
var joy: TouchStick
var act_btn: Button
var _act_label: Label
var _prompt: PanelContainer
var _prompt_lbl: DualLabel
var _quest: Label
var _closing := false


func _init(m: Node) -> void:
	main = m
	Kit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	ex = main.world.explorer
	var vw := get_viewport_rect().size

	var bar := Kit.panel(Color(1, 1, 1, 0.92), 24, 14)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 20
	bar.offset_right = -20
	bar.offset_top = 104
	add_child(bar)
	var row := Kit.hbox(12)
	bar.add_child(row)
	var col := Kit.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(Kit.label(Loc.main(Loc.T("Jelajah Kampus", "Explore Campus")), 28, Kit.INK, Kit.font_display))
	_quest = Kit.label("", 19, Kit.INK_SOFT, Kit.font_bold, HORIZONTAL_ALIGNMENT_LEFT, true)
	col.add_child(_quest)
	row.add_child(col)
	var done := Kit.compact(Kit.button(Loc.T("Selesai", "Done"), Kit.GREEN, close, 22, 60, false), 16)
	done.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(done)

	joy = TouchStick.new()
	Kit.full_rect(joy)
	joy.home = Vector2(190, vw.y - 230)
	joy.zone = Rect2(0, vw.y * 0.3, vw.x * 0.58, vw.y * 0.7)
	add_child(joy)

	act_btn = Button.new()
	act_btn.focus_mode = Control.FOCUS_NONE
	act_btn.set_meta("silent", true)
	act_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	act_btn.offset_left = -236
	act_btn.offset_top = -296
	act_btn.offset_right = -56
	act_btn.offset_bottom = -116
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"pressed": Kit.ORANGE.darkened(0.15), "disabled": Color(0.55, 0.52, 0.6, 0.55)}.get(st, Kit.ORANGE)
		sb.set_corner_radius_all(90)
		sb.border_color = Color.WHITE
		sb.set_border_width_all(6)
		sb.shadow_color = Color(0, 0, 0, 0.25)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 6)
		act_btn.add_theme_stylebox_override(st, sb)
	act_btn.pressed.connect(_act)
	add_child(act_btn)
	_act_label = Kit.title("A", 64, Color.WHITE)
	_act_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_act_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Kit.full_rect(_act_label)
	_act_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	act_btn.add_child(_act_label)

	_prompt = Kit.panel(Kit.INK, 22, 12)
	_prompt.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_right = -24
	_prompt.offset_bottom = -316
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_lbl = Kit.dual({}, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, true)
	_prompt_lbl.custom_minimum_size.x = 240
	_prompt.add_child(_prompt_lbl)
	add_child(_prompt)

	ex.near_changed.connect(_on_near)
	ex.acted.connect(_on_acted)
	ex.begin()
	_update_quest()
	Fx.slide_in(bar, Vector2(0, -80), 0.0, 0.35)
	Fx.pop_in(act_btn, 0.1, 0.5, 0.35)
	if not Meta.settings.get("hint_explore", false):
		Meta.settings["hint_explore"] = true
		Meta.save_meta()
		main.toast(Loc.T("Geser di kiri layar buat jalan, tombol A buat interaksi. Cari koin & diamond!", "Drag on the left to walk, A to interact. Find coins & the diamond!"), Kit.BLUE, 4.0)


func _exit_tree() -> void:
	if ex and ex.near_changed.is_connected(_on_near):
		ex.near_changed.disconnect(_on_near)
		ex.acted.disconnect(_on_acted)


func _process(_d: float) -> void:
	if _closing:
		return
	var blocked: bool = main.has_modal()
	joy.enabled = not blocked
	if blocked:
		ex.move = Vector2.ZERO
		return
	ex.move = joy.value if joy.is_held() else _pad_vector()


## Keyboard (WASD / arrows) and the first gamepad's left stick or d-pad.
func _pad_vector() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1
	for pad in Input.get_connected_joypads():
		var s := Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
		if s.length() > 0.2:
			v += s
		if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_LEFT):
			v.x -= 1
		if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_RIGHT):
			v.x += 1
		if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_UP):
			v.y -= 1
		if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_DOWN):
			v.y += 1
	return v.limit_length(1.0)


func _input(e: InputEvent) -> void:
	if _closing or main.has_modal():
		return
	# A second finger on the action button while the first one steers (no mouse emulation for it).
	if e is InputEventScreenTouch and e.pressed and e.index > 0 and act_btn.get_global_rect().has_point(e.position):
		_act()
		get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_E, KEY_SPACE, KEY_ENTER:
				_act()
			KEY_ESCAPE:
				close()
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_A:
				_act()
			JOY_BUTTON_B, JOY_BUTTON_START:
				close()


func _act() -> void:
	if _closing or ex.near.is_empty():
		Audio.play("tick", -8.0)
		return
	Fx.pulse(act_btn, 1.12)
	var r := ex.interact()
	match r.get("open", ""):
		"wardrobe":
			main.open_modal(WardrobePopup.new(main))
		"shop":
			main.open_modal(ShopPopup.new(main, "style"))
		"academic":
			main.open_modal(AcademicPopup.new(main))
		"jobs":
			main.open_modal(JobsPopup.new(main))


func _on_near(it: Dictionary) -> void:
	var has := not it.is_empty()
	act_btn.disabled = not has
	_prompt.visible = has
	if has:
		_prompt_lbl.set_pair(it.label)
		Fx.pop_in(_prompt, 0.0, 0.8, 0.2)
		Audio.play("tick", -10.0)
		Fx.pulse(act_btn, 1.08)


func _on_acted(it: Dictionary, out: Dictionary) -> void:
	var fx: Dictionary = out.get("fx", {})
	if fx.has("diamonds"):
		main.toast(Loc.T("DIAMOND RAHASIA! +1 diamond", "SECRET DIAMOND! +1 diamond"), Kit.CYAN, 3.0)
		main.world.float_text([{"text": "+1 Diamond", "good": true}])
	elif not fx.is_empty():
		main.world.float_text(Kit.fx_text(fx))
	var line: Dictionary = out.get("line", {})
	if not line.is_empty() and it.get("kind", "") != "npc":
		main.toast(line, Kit.INK, 2.6)
	_update_quest()


func _update_quest() -> void:
	var coins := ex.coins_left()
	var parts: Array = []
	parts.append(Loc.main(Loc.T("Koin tersebar: %d", "Coins around: %d")) % coins)
	parts.append(Loc.main(Loc.T("Diamond rahasia: ada!", "Secret diamond: somewhere!")) if ex.diamond_here() else Loc.main(Loc.T("Diamond semester ini: sudah", "This semester's diamond: found")))
	_quest.text = "  ·  ".join(parts)


func close() -> void:
	if _closing:
		return
	_closing = true
	ex.end()
	Audio.play("close", -8.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	closed.emit()
	queue_free()

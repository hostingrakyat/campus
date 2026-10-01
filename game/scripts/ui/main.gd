extends Node
## App root: 3D campus behind, UI layer on top. Handles screen navigation, modals, toasts and Android back.

var world: CampusWorld
var ui: Control
var screen_holder: Control
var modal_holder: Control
var toast_box: VBoxContainer
var screen: Control
var screen_name := ""
var _modals: Array = []


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)
	world = CampusWorld.new()
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Kit.full_rect(Control.new())
	ui.theme = Kit.theme()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	screen_holder = Kit.full_rect(Control.new())
	screen_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(screen_holder)
	modal_holder = Kit.full_rect(Control.new())
	modal_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(modal_holder)
	toast_box = Kit.vbox(8)
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.offset_left = -320
	toast_box.offset_right = 320
	toast_box.offset_top = 170
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(toast_box)

	var shot := _arg("shot")
	if shot != "":
		Shots.run(self, shot, _arg("out"))
		return
	if not Meta.settings.get("content_note_seen", false):
		goto("title")
		open_modal(ContentNote.new(self), false)
	else:
		goto("title")


func _arg(key: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % key):
			return a.split("=", true, 1)[1]
	return ""


func goto(name: String, args: Dictionary = {}) -> void:
	close_all_modals()
	if screen:
		screen.queue_free()
	screen_name = name
	match name:
		"title":
			screen = TitleScreen.new(self)
		"create":
			screen = CreateScreen.new(self)
		"ukt":
			screen = UktScreen.new(self)
		"krs":
			screen = KrsScreen.new(self)
		"week":
			screen = HudScreen.new(self)
		"khs":
			screen = KhsScreen.new(self)
		"ending":
			screen = EndingScreen.new(self)
		"gallery":
			screen = GalleryScreen.new(self)
	for k in args:
		screen.set_meta(k, args[k])
	screen_holder.add_child(screen)
	_animate_screen_in(screen)
	_music_for(name)


## Fade the new screen in, slide its bottom sheet up and its top bar down.
func _animate_screen_in(scr: Control) -> void:
	Fx.fade_in(scr, 0.2)
	for c in scr.get_children():
		if c is PanelContainer and c.get_meta("sheet", false):
			Fx.slide_in(c, Vector2(0, 260), 0.02, 0.45)
		elif c is HBoxContainer:
			Fx.slide_in(c, Vector2(0, -60), 0.08, 0.4)


func _music_for(name: String) -> void:
	match name:
		"title", "create", "gallery", "khs":
			Audio.play_music("kampus_pagi")
		"ukt", "krs":
			Audio.play_music("kampus_malam")
		"week":
			Audio.play_music("kampus_malam" if Game.s.get("mental", 100) < Data.MENTAL_WARNING else "kampus_pagi")


## Routes to whatever screen the current run's phase needs.
func resume() -> void:
	match Game.s.get("phase", ""):
		"ukt":
			goto("ukt")
		"krs":
			goto("krs")
		"week":
			goto("week")
		"khs":
			goto("khs")
		"ending":
			goto("ending")
		_:
			goto("title")


func open_modal(content: Control, dismissable: bool = true, bottom: bool = false) -> Control:
	var wrap := Kit.full_rect(Control.new())
	var dim := Kit.full_rect(ColorRect.new())
	dim.color = Color(0.1, 0.07, 0.16, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	wrap.add_child(dim)
	if dismissable:
		dim.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed:
				close_modal(wrap))
	if bottom:
		# Docked to the bottom so the 3D character stays visible above (wardrobe).
		dim.color.a = 0.0
		var col := Kit.full_rect(VBoxContainer.new())
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.alignment = BoxContainer.ALIGNMENT_END
		wrap.add_child(col)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(content)
	else:
		var center := Kit.full_rect(CenterContainer.new())
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(center)
		center.add_child(content)
	wrap.set_meta("dismissable", dismissable)
	wrap.set_meta("content", content)
	wrap.set_meta("dim", dim)
	wrap.set_meta("bottom", bottom)
	modal_holder.add_child(wrap)
	_modals.append(wrap)
	var target_dim: float = dim.color.a
	dim.color.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(dim, "color:a", target_dim, 0.2)
	if bottom:
		Fx.slide_in(content, Vector2(0, 420), 0.0, 0.4)
	else:
		Fx.pop_in(content, 0.0, 0.88, 0.32)
	Audio.play("open", -6.0)
	return wrap


func close_modal(wrap: Control) -> void:
	if wrap == null or not is_instance_valid(wrap) or wrap.get_meta("closing", false):
		return
	wrap.set_meta("closing", true)
	_modals.erase(wrap)
	var dim: ColorRect = wrap.get_meta("dim")
	var content: Control = wrap.get_meta("content")
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.propagate_call("set_mouse_filter", [Control.MOUSE_FILTER_IGNORE])
	Audio.play("close", -8.0)
	var tw := wrap.create_tween().set_parallel(true)
	tw.tween_property(dim, "color:a", 0.0, 0.16)
	tw.tween_property(content, "modulate:a", 0.0, 0.14)
	if wrap.get_meta("bottom", false):
		tw.tween_property(content, "position:y", content.position.y + 300, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		Fx.center_pivot(content)
		tw.tween_property(content, "scale", Vector2(0.92, 0.92), 0.14)
	tw.chain().tween_callback(wrap.queue_free)


func close_top_modal() -> void:
	if not _modals.is_empty():
		close_modal(_modals[-1])


func close_all_modals() -> void:
	for m in _modals:
		if is_instance_valid(m):
			m.queue_free()
	_modals.clear()


func has_modal() -> bool:
	return not _modals.is_empty()


func toast(pair: Variant, color: Color = Kit.INK, secs: float = 2.4) -> void:
	var p := Kit.panel(color, 40, 16)
	var d := Kit.dual(pair, 24, Color.WHITE if color.get_luminance() < 0.6 else Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, true)
	p.add_child(d)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_child(p)
	Fx.pop_in(p, 0.0, 0.7, 0.35)
	Audio.play("toast", -8.0)
	var tw := p.create_tween()
	tw.tween_interval(secs + 0.3)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if has_modal():
			var top: Control = _modals[-1]
			if top.get_meta("dismissable", true):
				close_modal(top)
			return
		if screen and screen.has_method("on_back") and screen.on_back():
			return
		Game.save_run()
		get_tree().quit()

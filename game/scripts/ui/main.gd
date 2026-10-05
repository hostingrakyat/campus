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
	TouchScroll.modal_root = modal_holder
	toast_box = Kit.vbox(8)
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.offset_left = -320
	toast_box.offset_right = 320
	toast_box.offset_top = 170
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(toast_box)
	Iap.purchased.connect(_on_iap_purchased)
	Iap.purchase_failed.connect(_on_iap_failed)

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
		if c is Page:
			c.animate_in(0.02)
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


func open_modal(content: Control, dismissable: bool = true) -> Control:
	var wrap := Kit.full_rect(Control.new())
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := Kit.full_rect(ColorRect.new())
	dim.color = Color(0.1, 0.07, 0.16, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	wrap.add_child(dim)
	var layout: String = content.get_meta("layout", "compact")
	if dismissable and layout == "compact":
		dim.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed:
				close_modal(wrap))
	if layout == "full" or layout == "lower":
		# Full-screen window: placed by anchors only, so it always fits the screen.
		content.anchor_left = 0.0
		content.anchor_right = 1.0
		content.anchor_top = 0.42 if layout == "lower" else 0.0
		content.anchor_bottom = 1.0
		content.offset_left = 0
		content.offset_right = 0
		content.offset_top = 28 if layout == "full" else 0
		content.offset_bottom = 0
		wrap.add_child(content)
		if layout == "lower":
			dim.color.a = 0.0
		Fx.slide_in(content, Vector2(0, 360), 0.0, 0.38)
	else:
		var center := Kit.full_rect(CenterContainer.new())
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(center)
		center.add_child(content)
		Fx.pop_in(content, 0.0, 0.88, 0.32)
	wrap.set_meta("dismissable", dismissable)
	wrap.set_meta("content", content)
	wrap.set_meta("dim", dim)
	wrap.set_meta("layout", layout)
	modal_holder.add_child(wrap)
	_modals.append(wrap)
	var target_dim: float = dim.color.a
	dim.color.a = 0.0
	create_tween().tween_property(dim, "color:a", target_dim, 0.2)
	Audio.play("open", -6.0)
	return wrap


## Full-screen cinematic (letterbox + dialogue); counts as a non-dismissable modal.
func open_cutscene(c: Control) -> void:
	c.set_meta("dismissable", false)
	c.set_meta("cutscene", true)
	modal_holder.add_child(c)
	_modals.append(c)


func close_cutscene(c: Control) -> void:
	_modals.erase(c)
	if is_instance_valid(c):
		c.queue_free()


func close_modal(wrap: Control) -> void:
	if wrap == null or not is_instance_valid(wrap) or wrap.get_meta("closing", false):
		return
	if wrap.get_meta("cutscene", false):
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
	if wrap.get_meta("layout", "compact") != "compact":
		tw.tween_property(content, "offset_top", content.offset_top + 300, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(content, "offset_bottom", content.offset_bottom + 300, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
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


## Purchase results can arrive any time (pending payments complete later), so they toast globally.
func _on_iap_purchased(product_id: String) -> void:
	Audio.play("unlock", -3.0)
	var p: Dictionary = Data.IAP_PRODUCTS.get(product_id, {})
	var what: String = Loc.main(p.get("name", {"id": product_id, "en": product_id}))
	toast(Loc.T("Terima kasih! %s masuk." % what, "Thank you! %s added." % what), Kit.GREEN, 3.0)


func _on_iap_failed(_product_id: String, status: String, message: Dictionary) -> void:
	if status != "canceled":
		Audio.play("error", -4.0)
	toast(message, Kit.ORANGE if status == "pending" else (Kit.INK if status == "canceled" else Kit.RED), 3.4)


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

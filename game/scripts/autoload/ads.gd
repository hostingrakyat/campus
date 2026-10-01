extends Node
## AdMob facade. This sample build shows a mock ad overlay so the full reward flow is playable.
## To ship: install the Poing Studios AdMob plugin and replace _show_mock() calls with the real
## RewardedAd / InterstitialAd loaders (see docs/MONETIZATION.md). Keep the public API unchanged.

const INTERSTITIAL_COOLDOWN := 150.0
const REWARDED_UNIT := "ca-app-pub-3940256099942544/5224354917"  # Google test unit
const INTERSTITIAL_UNIT := "ca-app-pub-3940256099942544/1033173712"  # Google test unit

var _last_interstitial := -1000.0
var _busy := false


func rewarded_left() -> int:
	return Meta.rewarded_left()


## Shows a rewarded ad; on_done(rewarded: bool).
func show_rewarded(placement: String, on_done: Callable) -> void:
	if _busy or Meta.rewarded_left() <= 0:
		on_done.call(false)
		return
	_show_mock(true, placement, func(ok: bool):
		if ok:
			Meta.count_rewarded()
		on_done.call(ok))


## Interstitials only at natural breaks, never in the first minutes, never for no-ads buyers.
func maybe_interstitial(placement: String) -> void:
	if Meta.no_ads or _busy:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < 180.0 or now - _last_interstitial < INTERSTITIAL_COOLDOWN:
		return
	_last_interstitial = now
	_show_mock(false, placement, func(_ok: bool): pass)


func _show_mock(rewarded: bool, placement: String, cb: Callable) -> void:
	_busy = true
	var layer := CanvasLayer.new()
	layer.layer = 120
	get_tree().root.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.1, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	bg.add_child(box)
	box.position = Vector2(-260, -200)
	box.custom_minimum_size = Vector2(520, 400)
	var title := Label.new()
	title.text = "IKLAN · AD" + (" (REWARDED)" if rewarded else "")
	title.add_theme_font_size_override("font_size", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var info := Label.new()
	info.text = "Mode sampel: ini simulasi iklan AdMob.\nSample build: simulated AdMob ad.\n[%s]" % placement
	info.add_theme_font_size_override("font_size", 24)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.modulate = Color(1, 1, 1, 0.7)
	box.add_child(info)
	var count := Label.new()
	count.add_theme_font_size_override("font_size", 64)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(count)
	var close := Button.new()
	close.text = "Tutup / Close"
	close.custom_minimum_size = Vector2(320, 80)
	close.visible = false
	box.add_child(close)
	var finish := func(ok: bool):
		layer.queue_free()
		_busy = false
		cb.call(ok)
	close.pressed.connect(func(): finish.call(true))
	var secs := 3 if rewarded else 2
	for i in range(secs, 0, -1):
		count.text = str(i)
		await get_tree().create_timer(1.0).timeout
	count.text = "OK"
	close.visible = true

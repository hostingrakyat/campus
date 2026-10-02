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


## Full-screen mock ad that looks and behaves like a real one: countdown, progress bar,
## close button once it may be skipped, and a reward confirmation for rewarded ads.
func _show_mock(rewarded: bool, placement: String, cb: Callable) -> void:
	_busy = true
	Audio.duck(true)
	var layer := CanvasLayer.new()
	layer.layer = 120
	get_tree().root.add_child(layer)
	var root := Control.new()
	root.theme = Kit.theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.1, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	# Top bar: "Ad" tag, countdown chip, close button (appears when allowed).
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 36
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	top.add_child(Kit.chip("IKLAN · AD", Kit.YELLOW, Kit.INK, 20))
	top.add_child(Kit.spacer(0, true))
	var count := Kit.chip("", Color(1, 1, 1, 0.15), Color.WHITE, 20)
	top.add_child(count)
	var close := Kit.compact(Kit.button("X", Color(1, 1, 1, 0.25), Callable(), 24, 56, false), 16)
	close.visible = false
	top.add_child(close)

	# Centered creative.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var card := Kit.panel(Color("2f6bff"), 36, 30)
	card.custom_minimum_size = Vector2(600, 0)
	center.add_child(card)
	var v := Kit.vbox(16)
	card.add_child(v)
	var head := Kit.title("KOPI SENJA", 64, Color.WHITE)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	v.add_child(Kit.dual(Loc.T("Promo mahasiswa: es kopi aren cuma 10 ribu pakai KTM!", "Student promo: palm-sugar iced coffee for 10K with your student ID!"), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, true))
	var cup := CenterContainer.new()
	cup.add_child(Icon.make("coin", 140))
	v.add_child(cup)
	var prog := Kit.bar(0, 100, Kit.YELLOW, 14)
	v.add_child(prog)
	v.add_child(Kit.label(Loc.main(Loc.T("Mode sampel: simulasi iklan AdMob (fiktif)", "Sample build: simulated AdMob ad (fictional)")), 18, Color(1, 1, 1, 0.7), null, HORIZONTAL_ALIGNMENT_CENTER, true))
	Fx.pop_in(card, 0.05, 0.85, 0.35)

	var state := {"done": false}
	var finish := func(ok: bool):
		if state.done:
			return
		state.done = true
		layer.queue_free()
		_busy = false
		Audio.duck(false)
		cb.call(ok)
	close.pressed.connect(func():
		if rewarded:
			# Closing before the end forfeits the reward, like real rewarded ads.
			finish.call(prog.value >= 100.0)
		else:
			finish.call(true))

	var secs := 5.0 if rewarded else 3.0
	var skip_after := secs if rewarded else 1.5
	var t := 0.0
	while t < secs and not state.done:
		await get_tree().process_frame
		t += get_process_delta_time()
		prog.value = t / secs * 100.0
		var left := ceili(secs - t)
		(count.get_child(0) as Label).text = (Loc.main(Loc.T("Hadiah dalam %d", "Reward in %d")) if rewarded else Loc.main(Loc.T("Lewati dalam %d", "Skip in %d"))) % left
		if t >= skip_after and not close.visible:
			close.visible = true
			Fx.pop_in(close)
	if state.done:
		return
	prog.value = 100.0
	if rewarded:
		(count.get_child(0) as Label).text = Loc.main(Loc.T("Hadiah didapat!", "Reward earned!"))
		Audio.play("unlock", -6.0)
		var ok_btn := Kit.button(Loc.T("Ambil hadiah", "Claim reward"), Kit.GREEN, func(): finish.call(true), 26)
		v.add_child(ok_btn)
		Fx.pop_in(ok_btn)
	else:
		(count.get_child(0) as Label).text = Loc.main(Loc.T("Bisa ditutup", "You can close"))

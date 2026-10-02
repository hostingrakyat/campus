extends Node
## Music (crossfading loops) and pooled SFX on their own buses. Volumes persist in Meta.settings.
## Every Button in the app clicks automatically (set meta "silent" on a button to opt out).

## Per-track trim so loops sit at a similar loudness.
const MUSIC_GAIN := {"kampus_pagi": -5.0, "kampus_malam": -3.0, "sedih": -3.0, "lulus": -2.0}
const SFX := {
	"click": ["click"], "select": ["select"], "tab": ["tab"], "open": ["open"], "close": ["close"],
	"toast": ["toast"], "confirm": ["confirm"], "good": ["good"], "bad": ["bad"], "error": ["error"],
	"glitch": ["glitch"], "tick": ["tick"], "card": ["card"], "card_place": ["card_place"], "week": ["week"],
	"coin": ["coin"], "spend": ["spend"], "diamond": ["diamond"], "levelup": ["levelup"], "fail": ["fail"],
	"unlock": ["unlock"], "step": ["step1", "step2", "step3", "step4"], "pop": ["pop"], "whoosh": ["whoosh"],
	"bell": ["bell"], "jingle": ["jingle_pizzi"],
}
const POOL_SIZE := 12

var music_name := ""
var _players: Array = []
var _active := 0
var _pool: Array = []
var _next := 0
var _cache := {}
var _last_play := {}
var _stinger_next := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	# Keep stacked SFX + music from clipping on phone speakers.
	var master := AudioServer.get_bus_index("Master")
	if AudioServer.get_bus_effect_count(master) == 0:
		var lim := AudioEffectHardLimiter.new()
		lim.ceiling_db = -1.0
		AudioServer.add_bus_effect(master, lim)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -60.0
		add_child(p)
		p.finished.connect(_on_music_finished.bind(p))
		_players.append(p)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	apply_volumes()
	get_tree().node_added.connect(_on_node_added)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


# --- Music ---------------------------------------------------------------------

func play_music(track: String, fade: float = 1.2) -> void:
	if track == music_name:
		return
	_stinger_next = ""
	_crossfade(track, fade, true)


## One-shot cue on the music channel (e.g. graduation fanfare), then continue with a loop.
func stinger(track: String, then_track: String) -> void:
	_crossfade(track, 0.25, false)
	_stinger_next = then_track


func _crossfade(track: String, fade: float, loop: bool) -> void:
	music_name = track
	var out_p: AudioStreamPlayer = _players[_active]
	_active = 1 - _active
	var in_p: AudioStreamPlayer = _players[_active]
	var stream: AudioStream = _load("res://assets/audio/music/%s.ogg" % track)
	if stream is AudioStreamOggVorbis:
		stream.loop = loop
	in_p.stream = stream
	in_p.volume_db = -50.0
	in_p.play()
	var target: float = MUSIC_GAIN.get(track, 0.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(in_p, "volume_db", target, fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if out_p.playing:
		tw.tween_property(out_p, "volume_db", -60.0, fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(out_p.stop)


func _on_music_finished(p: AudioStreamPlayer) -> void:
	if p == _players[_active] and _stinger_next != "":
		var nxt := _stinger_next
		_stinger_next = ""
		music_name = ""
		play_music(nxt, 2.0)


## Silences music while a (real or mock) full-screen ad plays.
func duck(on: bool) -> void:
	var idx := AudioServer.get_bus_index("Music")
	var base := _bus_db("music")
	var tw := create_tween()
	tw.tween_method(func(v: float): AudioServer.set_bus_volume_db(idx, v), AudioServer.get_bus_volume_db(idx), -60.0 if on else base, 0.3)


# --- SFX -----------------------------------------------------------------------

## Plays a named effect. Repeats of the same effect within 40 ms are skipped (prevents stacking).
func play(sfx: String, vol_db: float = 0.0, pitch: float = 1.0, variance: float = 0.06) -> void:
	if not SFX.has(sfx):
		push_warning("Unknown sfx " + sfx)
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(sfx, -1000)) < 40:
		return
	_last_play[sfx] = now
	var files: Array = SFX[sfx]
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _load("res://assets/audio/sfx/%s.ogg" % files[randi() % files.size()])
	p.volume_db = vol_db
	p.pitch_scale = pitch * randf_range(1.0 - variance, 1.0 + variance)
	p.play()


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


# --- Volume settings -------------------------------------------------------------

func volume(kind: String) -> float:
	return float(Meta.settings.get(kind + "_vol", 0.8 if kind == "music" else 0.9))


func set_volume(kind: String, v: float) -> void:
	Meta.settings[kind + "_vol"] = clampf(v, 0.0, 1.0)
	apply_volumes()


func apply_volumes() -> void:
	for kind in ["music", "sfx"]:
		var idx := AudioServer.get_bus_index("Music" if kind == "music" else "SFX")
		AudioServer.set_bus_volume_db(idx, _bus_db(kind))
		AudioServer.set_bus_mute(idx, volume(kind) <= 0.01)


func _bus_db(kind: String) -> float:
	return linear_to_db(maxf(0.0001, volume(kind)))


# --- Automatic button feedback -------------------------------------------------------

func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		var b: BaseButton = n
		b.pressed.connect(func():
			if not b.has_meta("silent") and not TouchScroll.gesture_was_drag:
				play("click", -3.0))
		if b is Button:
			Fx.press_feedback(b)


func _input(e: InputEvent) -> void:
	# Every new touch starts a fresh gesture (see TouchScroll).
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		TouchScroll.gesture_was_drag = false

class_name Director
extends Node
## Stages activity scenes and event cutscenes: picks the set, places the player and cast with poses,
## animations and props, frames the camera, and plays speech bubbles.

const D := preload("res://scripts/autoload/data.gd")

var world: CampusWorld
var stages: Stages
var current := {}
var _cast := {}
var _extras: Array = []
var _active: Array = []
var _temp: Array = []
var _rng := RandomNumberGenerator.new()
var _bubble_gen := 0


func _init(w: CampusWorld) -> void:
	world = w
	name = "Director"
	stages = Stages.new(w)
	w.add_child(stages)
	_rng.randomize()


## Scene for a week log entry: random variant's scene, bimbingan outcome scene, or a sensible default.
func scene_for(entry: Dictionary) -> Dictionary:
	var a: String = entry.action
	if a == "bimbingan":
		return Data.activities.get("bimbingan", {}).get(entry.get("scene_key", "acc"), {})
	var v: Dictionary = entry.get("variant", {})
	if v.has("scene"):
		return v.scene
	return {"stage": "kamar", "spot": "floor", "pose": "stand", "anim": "idle"}


## Sets up a scene immediately (call while the screen is covered by a quick fade).
func stage(scene: Dictionary, ctx: Dictionary, frac: float = 0.5) -> void:
	clear()
	current = scene
	var st := stages.get_stage(scene.get("stage", "kamar"))
	var spots: Dictionary = st.spots
	var p: VinylChar = world.player
	_place(p, spots.get(scene.get("spot", ""), {}), scene.get("pose", "stand"))
	p.play(scene.get("anim", "idle"))
	p.hold(scene.get("hold", ""))
	if st.has("sign"):
		st.sign.text = {"minimarket": "TOKO 24 JAM", "jaga_apotek": "APOTEK SEHAT"}.get(ctx.get("job", ""), "KOPI SENJA")
	if st.has("door_sign"):
		st.door_sign.text = {"ghost": "SEDANG RAPAT", "dinas": "DINAS LUAR KOTA"}.get(ctx.get("scene_key", ""), "")
	var used_extras := 0
	for c in scene.get("cast", []):
		var target: Variant = spots.get(c.spot, {})
		if c.npc == "extras":
			target = spots.get(c.spot + "_list", target)
			var list: Array = target if target is Array else [target]
			for s in list:
				if used_extras >= _extras_pool().size():
					break
				var e: VinylChar = _extras_pool()[used_extras]
				used_extras += 1
				_activate(e, s, c.get("pose", "stand"), c.get("anim", "idle"), c.get("hold", ""))
				e.anim = _vary(c.get("anim", "idle"))
		else:
			var actor := actor_for(c.npc, ctx)
			if actor == null:
				continue
			if target is Array:
				if c.get("anim", "") == "walk":
					var pts: Array = []
					for s in target:
						pts.append(s.pos)
					_activate(actor, target[0], "stand", "idle", "")
					actor.walk_path(pts + pts)
					continue
				target = target[0]
			_activate(actor, target, c.get("pose", "stand"), c.get("anim", "idle"), c.get("hold", ""))
	# Special movement.
	if scene.get("walk", false) and spots.has("track_path"):
		p.speed = 2.4
		p.walk_path(spots.track_path)
	if scene.get("pose", "") == "ride":
		_ride(spots, ctx)
	world.set_interior(st.has("node"))
	var cam: Dictionary = st.cam
	if cam.get("follow", false) or scene.get("walk", false):
		world.follow(cam.size, frac, true)
	else:
		world.focus(cam.focus, cam.size, true, frac)


## Speech bubbles from the scene description, staggered.
func play_bubbles(scene: Dictionary, ctx: Dictionary) -> void:
	_bubble_gen += 1
	var gen := _bubble_gen
	for b in scene.get("bubbles", []):
		await get_tree().create_timer(float(b.get("delay", 0.3))).timeout
		if gen != _bubble_gen:
			return
		var who: VinylChar = world.player if b.who == "player" else actor_for(b.who, ctx, false)
		if who and who.visible:
			who.say(Loc.main(b.text), 2.6)
			if who != world.player:
				who.play("talk")


func clear() -> void:
	_bubble_gen += 1
	for a in _active:
		a.visible = false
		a.teleport(Vector3(0, -50, 0))
		a.hold("")
		a.emote("", Color.WHITE, 0.0)
	_active.clear()
	for t in _temp:
		if is_instance_valid(t):
			t.queue_free()
	_temp.clear()
	var p: VinylChar = world.player
	if p.has_meta("ride_tw"):
		var tw: Tween = p.get_meta("ride_tw")
		if tw and tw.is_valid():
			tw.kill()
		p.remove_meta("ride_tw")
	p.hold("")
	p.speed = 3.2
	p.set_pose("stand")
	p.play("idle")
	p.emote("", Color.WHITE, 0.0)
	if world._interior:
		world.set_interior(false)
	current = {}


## Back to the campus diorama at a location.
func return_to_campus(loc: String) -> void:
	clear()
	world.player.teleport(world.spots.get(loc, world.spots.kos))
	world.player.rotation.y = 0.3


func actor_for(npc: String, ctx: Dictionary = {}, create: bool = true) -> VinylChar:
	var key := npc
	match npc:
		"lecturer":
			key = ctx.get("lecturer", "dosen_read")
		"dospem":
			key = ctx.get("dospem", "dosen_read")
			if key == "":
				key = "dosen_read"
		"boss":
			key = "bos"
		"friend":
			key = ctx.get("friend", "ambis")
		"kid":
			key = "kid"
	if _cast.has(key):
		return _cast[key]
	if not create:
		return null
	var v := VinylChar.new()
	world.add_child(v)
	var look: Dictionary = D.NPC_LOOKS.get(key, {})
	if key == "kid":
		look = {"skin": 1, "hair": "hair_fringe", "hair_color": 0, "top": "top_tee", "back": "back_ransel"}
		v.scale = Vector3.ONE * 0.75
	var full: Dictionary = D.DEFAULT_LOOK.duplicate()
	full.merge(look, true)
	v.build(full, "IF")
	v.visible = false
	_cast[key] = v
	return v


func _extras_pool() -> Array:
	if _extras.is_empty():
		var tops := ["top_tee", "top_flanel", "top_hoodie_ungu", "top_almamater", "top_batik", "top_varsity"]
		var hairs := ["hair_short", "hair_fringe", "hair_long", "hair_hijab", "hair_buzz", "hair_curly"]
		var backs := ["back_none", "back_ransel", "back_tote"]
		for i in 7:
			var v := VinylChar.new()
			world.add_child(v)
			v.build({"skin": _rng.randi() % D.SKIN_TONES.size(), "hair": hairs[i % hairs.size()], "hair_color": _rng.randi() % 3,
				"top": tops[_rng.randi() % tops.size()], "back": backs[_rng.randi() % backs.size()], "head": "head_none", "face": "face_round" if i % 3 == 0 else "face_none", "aura": "aura_none"},
				D.PRODI.keys()[_rng.randi() % 3])
			v.visible = false
			_extras.append(v)
	return _extras


func _activate(a: VinylChar, s: Dictionary, pose: String, anim: String, hold: String) -> void:
	if s.is_empty():
		return
	a.visible = true
	_place(a, s, pose)
	a.play(anim)
	a.hold(hold)
	if not _active.has(a):
		_active.append(a)


func _place(a: VinylChar, s: Dictionary, pose: String) -> void:
	if s.is_empty():
		return
	a.teleport(s.pos)
	a.rotation.y = float(s.get("rot", 0.0))
	a.set_pose(s.get("pose", pose) if pose == "stand" else pose)


func _vary(anim: String) -> String:
	if anim == "listen" and _rng.randf() < 0.3:
		return ["write", "sleep", "phone"][_rng.randi() % 3]
	return anim


func _ride(spots: Dictionary, ctx: Dictionary) -> void:
	var p: VinylChar = world.player
	var bike := Props.motor(p, Vector3(0, 0, -0.1), 0.0, Color("1fa463"))
	_temp.append(bike)
	var passenger: VinylChar = null
	for a in _active:
		if a.pose == "ride":
			passenger = a
	var start: Vector3 = spots.road.pos
	var end: Vector3 = spots.road_end
	p.teleport(start)
	p.rotation.y = PI * 0.5
	var tw := p.create_tween()
	tw.tween_property(p, "position", end, 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	p.set_meta("ride_tw", tw)
	if passenger:
		passenger.teleport(start + Vector3(-0.55, 0.05, 0))
		passenger.rotation.y = PI * 0.5
		passenger.create_tween().tween_property(passenger, "position", end + Vector3(-0.55, 0.05, 0), 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# --- Event cutscenes --------------------------------------------------------------------

const PHONE_SPEAKERS := ["ibu", "ayah", "pinjol"]
const NARRATOR_SCENES := {
	"kucing": ["perpus", "seat", "sit", "read"],
	"flash_sale": ["kamar", "bed", "lie", "phone"],
	"motor_mogok": ["jalan", "road", "stand", "sad"],
	"laptop_rusak": ["kamar", "desk", "sit", "nervous"],
	"banjir": ["kos_depan", "player", "stand", "sad"],
	"demam": ["kamar", "bed", "lie", "sad"],
	"if_bug": ["kamar", "desk", "sit", "nervous"],
	"mn_presentasi": ["kelas", "front", "stand", "talk"],
	"kd_anatomi": ["perpus", "seat", "sit", "read"],
	"warkop_bon": ["warkop", "bench", "sit", "sad"],
}


## Scene for an event: where it happens and where the speaker stands. Returns {scene, speaker_spot, phone}.
func event_scene(ev: Dictionary) -> Dictionary:
	var sp: String = ev.speaker
	var scene := {}
	var speaker_spot := ""
	match sp:
		"dosen_read", "dosen_revisi", "dosen_dinas", "dosen_buku", "dekan":
			scene = {"stage": "ruang_dosen", "spot": "guest", "pose": "sit", "anim": "listen"}
			speaker_spot = "dosen_chair"
		"dosen_killer":
			scene = {"stage": "kelas", "spot": "seat", "pose": "sit", "anim": "listen", "cast": [{"npc": "extras", "spot": "seats", "anim": "listen", "pose": "sit"}]}
			speaker_spot = "lecturer"
		"tu":
			scene = {"stage": "rektorat", "spot": "player", "anim": "listen"}
			speaker_spot = "npc"
		"ibu_kos":
			scene = {"stage": "kos_depan", "spot": "player", "anim": "listen"}
			speaker_spot = "npc"
		"bos":
			scene = {"stage": "kafe", "spot": "counter", "anim": "listen"}
			speaker_spot = "boss"
		"konselor":
			scene = {"stage": "konseling", "spot": "chair_a", "pose": "sit", "anim": "listen"}
			speaker_spot = "chair_b"
		"bestie", "senior":
			scene = {"stage": "warkop", "spot": "bench", "pose": "sit", "anim": "listen"}
			speaker_spot = "bench_b"
		"ambis":
			scene = {"stage": "perpus", "spot": "seat", "pose": "sit", "anim": "listen"}
			speaker_spot = "seat_b"
		"beban":
			scene = {"stage": "perpus", "spot": "seat", "pose": "sit", "anim": "type"}
			speaker_spot = "seat_b"
		"kades":
			scene = {"stage": "lapangan", "spot": "field", "anim": "listen"}
			speaker_spot = "field_b"
		"siakad":
			scene = {"stage": "kamar", "spot": "desk", "pose": "sit", "anim": "nervous"}
		"ibu", "ayah", "pinjol":
			scene = {"stage": "kamar", "spot": "bed_edge", "pose": "sit", "anim": "phone", "hold": "phone"}
		_:
			var n: Array = NARRATOR_SCENES.get(ev.id, ["kamar", "floor", "stand", "idle"])
			scene = {"stage": n[0], "spot": n[1], "pose": n[2], "anim": n[3]}
	return {"scene": scene, "speaker_spot": speaker_spot, "phone": PHONE_SPEAKERS.has(sp)}


## Stages the event and walks the speaker in. Returns the speaker actor (or null for phone/narrator).
func stage_event(ev: Dictionary, ctx: Dictionary, frac: float = 0.42) -> VinylChar:
	var info := event_scene(ev)
	stage(info.scene, ctx, frac)
	if info.speaker_spot == "":
		world.player.emote("!" if info.phone else "?", Color("ff9f1c"))
		return null
	var st := stages.get_stage(info.scene.stage)
	var s: Dictionary = st.spots.get(info.speaker_spot, {})
	if s.is_empty():
		return null
	var actor := actor_for(ev.speaker, ctx)
	var seated: bool = s.get("pose", "stand") == "sit"
	if seated:
		_activate(actor, s, "sit", "talk", "")
	else:
		var dest: Vector3 = s.pos
		_activate(actor, {"pos": dest + Vector3(2.6, 0, 1.2), "rot": 0.0}, "stand", "idle", "")
		actor.walk_to(dest)
	world.player.emote("!", Color("ff9f1c"))
	_turn_after_arrival(actor, s)
	return actor


func _turn_after_arrival(actor: VinylChar, s: Dictionary) -> void:
	if actor.walking:
		await actor.arrived
	if not is_instance_valid(actor) or not actor.visible:
		return
	actor.face_point(world.player.position)
	if world.player.pose == "stand":
		world.player.face_point(actor.position)
	actor.play("talk")

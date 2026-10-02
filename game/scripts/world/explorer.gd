class_name Explorer
extends Node3D
## Free-roam layer on the campus diorama: joystick movement with simple collisions, coins and a
## hidden diamond to find, students to chat with, a cat to pet, a football to kick and doors to enter.

signal near_changed(item: Dictionary)
signal acted(item: Dictionary, result: Dictionary)

const BOUNDS := Rect2(-16.6, -13.6, 33.2, 28.8)
const RADIUS := 0.35
const COIN_SPOTS := [
	Vector3(-3.0, 0, 0.6), Vector3(1.6, 0, -3.2), Vector3(-8.2, 0, -2.4), Vector3(10.6, 0, -3.6),
	Vector3(13.6, 0, 2.6), Vector3(12.6, 0, 9.6), Vector3(6.2, 0, 9.4), Vector3(-1.0, 0, 10.0),
	Vector3(-13.6, 0, 6.2), Vector3(-14.6, 0, -1.2), Vector3(-4.0, 0, 6.4), Vector3(2.0, 0, 5.8),
	Vector3(-12.2, 0, -8.4), Vector3(1.4, 0, -8.2), Vector3(15.2, 0, 1.4), Vector3(-15.0, 0, 13.6),
	Vector3(9.0, 0, 13.0), Vector3(-6.0, 0, 13.4),
]
const DIAMOND_SPOTS := [Vector3(-15.8, 0, -12.6), Vector3(15.8, 0, -12.4), Vector3(-15.6, 0, 15.0), Vector3(6.4, 0, -10.2), Vector3(15.6, 0, 14.6)]
const CHATTER := [
	{"id": "Eh, KRS-an udah belum? Server SIAKAD down lagi tuh.", "en": "Done your KRS yet? SIAKAD is down again."},
	{"id": "Dosen PA gw nggak bisa dihubungi dari semester 1.", "en": "I haven't reached my academic advisor since semester 1."},
	{"id": "Warkop lagi promo es teh tiga ribu!", "en": "The warkop has iced tea for three thousand!"},
	{"id": "Katanya besok libur... katanya.", "en": "Apparently tomorrow is a holiday... apparently."},
	{"id": "Lagi nyari kelompok tugas besar nih, ikut?", "en": "Looking for a group for the big project, want in?"},
	{"id": "Wifi kampus lemot, mending di kafe.", "en": "Campus wifi is slow, the café is better."},
	{"id": "Parkiran penuh, motor gw di ujung dunia.", "en": "Parking's full, my bike is at the end of the world."},
	{"id": "Semangat ya! Kita pasti lulus.", "en": "Hang in there! We'll graduate."},
	{"id": "Udah liat kucing oren dekat perpus? Lucu banget.", "en": "Seen the orange cat by the library? So cute."},
	{"id": "Antre di TU panjang banget, bawa bekal.", "en": "The admin queue is huge, bring snacks."},
	{"id": "Tadi gw liat ada koin jatuh di sekitar kampus. Rejeki!", "en": "I saw coins dropped around campus. Free money!"},
	{"id": "Konon ada diamond nyelip di pojok kampus...", "en": "Legend says a diamond is hidden in a campus corner..."},
	{"id": "Ke lapangan yuk, main bola bentar.", "en": "Let's go to the field, quick football game."},
]
const REPLIES := [{"id": "Wkwk iya.", "en": "Lol yeah."}, {"id": "Siap!", "en": "Got it!"}, {"id": "Serius?", "en": "Seriously?"}, {"id": "Gas!", "en": "Let's go!"}]
const TIPS := [
	{"id": "Tips: kehadiran minimal 75% biar boleh UAS.", "en": "Tip: you need 75% attendance to sit the final."},
	{"id": "Tips: mental di bawah 30 bikin belajar nggak efektif. Konseling itu gratis.", "en": "Tip: mental under 30 makes studying ineffective. Counseling is free."},
	{"id": "Tips: main bagus di mini-game kegiatan = bonus kecil.", "en": "Tip: doing well in activity mini-games earns small bonuses."},
	{"id": "Tips: kerja part-time bisa bentrok jadwal. Izin 3x = dipecat.", "en": "Tip: part-time shifts can clash. 3 skips = fired."},
	{"id": "Tips: IPK di atas 3,50 + lulus tepat waktu = cum laude.", "en": "Tip: GPA above 3.50 + graduating on time = cum laude."},
]

var world: CampusWorld
var player: VinylChar
var active := false
## Joystick value, screen space (-1..1, y down).
var move := Vector2.ZERO
var items: Array = []
var near: Dictionary = {}

var _rects: Array = []
var _circles: Array = []
var _marker: Node3D
var _ball: Node3D
var _ball_v := Vector3.ZERO
var _ball_spin := Vector3.ZERO
var _cat: Node3D
var _t := 0.0
var _fwd := Vector3.ZERO
var _right := Vector3.ZERO
var _goal_cool := 0.0
var _you: Label3D
var _ring: MeshInstance3D


func _init(w: CampusWorld) -> void:
	world = w
	player = w.player
	name = "Explorer"
	var yaw := deg_to_rad(38.0)
	_fwd = -Vector3(sin(yaw), 0, cos(yaw))
	_right = Vector3(cos(yaw), 0, -sin(yaw))
	_build_obstacles()


func _ready() -> void:
	_marker = Node3D.new()
	add_child(_marker)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.22
	cone.bottom_radius = 0.0
	cone.height = 0.4
	cone.radial_segments = 12
	Mat.add(_marker, cone, Mat.unlit(Color("ffc83d")), Vector3.ZERO)
	_marker.visible = false
	_build_ball()
	_build_cat()
	# "You are here": drawn through roofs so the player is never lost behind a building.
	_you = Label3D.new()
	_you.text = "v"
	_you.font = load("res://assets/fonts/Fredoka.ttf")
	_you.font_size = 96
	_you.pixel_size = 0.006
	_you.outline_size = 20
	_you.modulate = Color("ffc83d")
	_you.outline_modulate = Color("2a2238")
	_you.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_you.no_depth_test = true
	_you.render_priority = 10
	add_child(_you)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.55
	_ring = Mat.add(self, ring, Mat.unlit(Color(1.0, 0.78, 0.24, 0.9)), Vector3.ZERO, Vector3.ZERO, Vector3(1, 0.1, 1), false)
	visible = false


# --- Lifecycle -------------------------------------------------------------------------

func begin() -> void:
	active = true
	visible = true
	move = Vector2.ZERO
	player.set_pose("stand")
	player.play("idle")
	_spawn_pickups()
	world.follow(9.0, 0.5, false)
	near = {}
	_update_near(true)


func end() -> void:
	active = false
	visible = false
	move = Vector2.ZERO
	player.steer(Vector3.ZERO, 0.0)
	for it in items:
		if it.get("temp", false) and is_instance_valid(it.node):
			it.node.queue_free()
	items = items.filter(func(it): return not it.get("temp", false))
	_marker.visible = false
	near = {}


func coins_left() -> int:
	var n := 0
	for it in items:
		if it.kind == "coin" and is_instance_valid(it.node):
			n += 1
	return n


func diamond_here() -> bool:
	for it in items:
		if it.kind == "diamond" and is_instance_valid(it.node):
			return true
	return false


# --- Frame -----------------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	_animate_props(delta)
	if not active:
		return
	_you.position = player.position + Vector3(0, 2.75 + sin(_t * 4.0) * 0.08, 0)
	_ring.position = player.position + Vector3(0, 0.05, 0)
	var mag := minf(1.0, move.length())
	if mag > 0.12:
		var dir := (_right * move.x + _fwd * -move.y).normalized()
		var speed := 2.2 + 3.0 * mag
		var p := player.position + dir * speed * mag * delta
		player.position = _collide(p, RADIUS)
		player.steer(dir, mag)
		_kick_check(dir, speed * mag)
	else:
		player.steer(Vector3.ZERO, 0.0)
	_pickup_check()
	_update_near()


func _update_near(force: bool = false) -> void:
	var best: Dictionary = {}
	var best_d := 999.0
	for it in items:
		if not it.get("interact", false) or not is_instance_valid(it.node):
			continue
		var pos: Vector3 = it.node.global_position if it.get("moving", false) else it.pos
		var d := Vector2(pos.x - player.position.x, pos.z - player.position.z).length()
		if d < float(it.get("r", 1.6)) and d < best_d:
			best_d = d
			best = it
	if best.get("id", "") != near.get("id", "") or force:
		near = best
		near_changed.emit(near)
	if near.is_empty():
		_marker.visible = false
	else:
		_marker.visible = true
		var base: Vector3 = near.node.global_position if near.get("moving", false) else near.pos
		_marker.position = base + Vector3(0, float(near.get("h", 2.6)) + sin(_t * 5.0) * 0.12, 0)
		_marker.rotation.y = _t * 2.0


## Acts on the nearest interactable. Returns {fx, line, open} for the UI.
func interact() -> Dictionary:
	if near.is_empty():
		return {}
	var it := near
	var out := {"fx": {}, "line": {}, "open": ""}
	player.face_point(it.node.global_position if it.get("moving", false) else it.pos)
	match it.kind:
		"npc":
			var n: VinylChar = it.node
			n.teleport(n.position)
			n.face_point(player.position)
			var line: Dictionary = CHATTER[randi() % CHATTER.size()]
			n.say(Loc.main(line), 3.0)
			n.play("talk")
			_after(1.4, func():
				player.say(Loc.main(REPLIES[randi() % REPLIES.size()]), 1.8)
				n.play("idle"))
			out.fx = Game.explore_reward("chat")
			out.line = line
			Audio.play("pop", -6.0)
		"cat":
			player.play("wave")
			_cat_purr()
			out.fx = Game.explore_reward("cat")
			out.line = Loc.T("Meong~ Kucing oren mendengkur.", "Meow~ The orange cat purrs.")
			_after(1.2, func(): player.play("idle"))
		"ball":
			_ball_v = (_ball.position - player.position).normalized() * 9.0
			_ball_v.y = 0
			Audio.play("whoosh", -6.0)
			player.hop()
		"jajan":
			out.fx = Game.explore_reward("jajan")
			if out.fx.is_empty():
				out.line = Loc.T("Udah jajan minggu ini (atau koin nggak cukup).", "Already snacked this week (or not enough coins).")
			else:
				out.line = Loc.T("Gorengan + es teh. Nikmat.", "Fritters + iced tea. Bliss.")
				player.hold("cup")
				_after(2.0, func(): player.hold(""))
				Audio.play("spend", -6.0)
		"buku":
			out.fx = Game.explore_reward("buku")
			out.line = Loc.T("Baca-baca sebentar di perpus.", "A quick read at the library.") if not out.fx.is_empty() else Loc.T("Perpus: \"Pinjaman minggu ini sudah.\"", "Library: \"You've borrowed this week already.\"")
			if not out.fx.is_empty():
				player.hold("book")
				_after(2.0, func(): player.hold(""))
		"mading":
			var news := Game.ensure_week()
			out.line = news.get("text", {}) if news.get("id", "normal") != "normal" else TIPS[randi() % TIPS.size()]
			player.play("read")
			_after(1.6, func(): player.play("idle"))
		"door":
			out.open = it.open
			Audio.play("open", -6.0)
	acted.emit(it, out)
	return out


# --- Building blocks -------------------------------------------------------------------

func _build_obstacles() -> void:
	var R := func(cx: float, cz: float, hx: float, hz: float): _rects.append(Rect2(cx - hx, cz - hz, hx * 2.0, hz * 2.0))
	var C := func(x: float, z: float, r: float): _circles.append(Vector3(x, z, r))
	R.call(-5.5, -6.5, 4.85, 2.7)  # fakultas
	C.call(-6.1, -2.8, 0.2)
	C.call(-3.7, -2.8, 0.2)
	R.call(6.5, -7.0, 3.3, 2.4)  # rektorat
	R.call(6.5, -3.7, 2.4, 0.1)  # queue rope
	C.call(2.3, -4.4, 0.12)  # flag
	R.call(-11.0, 2.0, 2.6, 3.1)  # perpus
	R.call(-7.1, 0.5, 0.25, 0.75)  # benches
	R.call(-7.1, 3.5, 0.25, 0.75)
	R.call(-9.2, 7.4, 2.7, 1.8)  # kos
	C.call(-5.6, 8.2, 0.08)
	C.call(-5.6, 10.2, 0.08)
	C.call(-11.2, 10.2, 0.55)  # motors
	C.call(-9.8, 10.4, 0.55)
	R.call(8.8, 5.4, 1.75, 0.55)  # warkop counter
	for px in [7.2, 10.4]:
		for pz in [4.9, 7.3]:
			C.call(px, pz, 0.08)
	R.call(8.3, 8.1, 0.72, 0.24)
	R.call(9.8, 8.1, 0.72, 0.24)
	R.call(5.6, 7.4, 0.75, 0.4)  # gerobak
	R.call(11.6, -1.0, 1.9, 2.4)  # kafe
	C.call(8.6, 1.6, 0.5)
	for gx in [0.1, 6.3]:  # goal posts
		C.call(gx, 0.9, 0.06)
		C.call(gx, 2.3, 0.06)
	C.call(-1.7, 11.3, 0.4)  # gate
	C.call(2.1, 11.3, 0.4)
	R.call(4.8, 11.0, 0.75, 0.75)  # pos satpam
	R.call(3.0, 11.5, 1.2, 0.07)
	C.call(3.2, 12.2, 0.55)
	for x in [-9.0, -1.8, 6.5, 12.0]:
		C.call(x, 11.6, 0.1)
	C.call(-2.0, 3.6, 0.1)
	C.call(5.6, -2.8, 0.1)
	C.call(-2.4, 8.6, 0.1)  # banner poles
	C.call(2.8, 8.6, 0.1)
	for p in [Vector3(-13.5, 0, -4), Vector3(-1.2, 0, -10.5), Vector3(14.5, 0, 5.5), Vector3(-14.5, 0, 9.5), Vector3(0.8, 0, -4.4), Vector3(-4.2, 0, 8.0), Vector3(13.5, 0, -8.5)]:
		C.call(p.x, p.z, 0.32)
	for p in [Vector3(-15, 0, 12), Vector3(15, 0, 11.6), Vector3(-2.5, 0, -11.6), Vector3(15.5, 0, -4)]:
		C.call(p.x + 0.15, p.z, 0.25)
	C.call(-1.8, 7.4, 0.45)  # beringin


## Pushes a point out of obstacles and keeps it on the diorama.
func _collide(p: Vector3, r: float) -> Vector3:
	for i in 2:
		for rc in _rects:
			var e: Rect2 = rc.grow(r)
			if e.has_point(Vector2(p.x, p.z)):
				var dl := p.x - e.position.x
				var dr := e.end.x - p.x
				var dt := p.z - e.position.y
				var db := e.end.y - p.z
				var m := minf(minf(dl, dr), minf(dt, db))
				if m == dl:
					p.x = e.position.x
				elif m == dr:
					p.x = e.end.x
				elif m == dt:
					p.z = e.position.y
				else:
					p.z = e.end.y
		for c in _circles:
			var d := Vector2(p.x - c.x, p.z - c.y)
			var min_d: float = c.z + r
			if d.length() < min_d:
				var n := d.normalized() if d.length() > 0.001 else Vector2(1, 0)
				p.x = c.x + n.x * min_d
				p.z = c.y + n.y * min_d
	p.x = clampf(p.x, BOUNDS.position.x, BOUNDS.end.x)
	p.z = clampf(p.z, BOUNDS.position.y, BOUNDS.end.y)
	p.y = 0.0
	return p


func _static_items() -> void:
	var add := func(id: String, kind: String, pos: Vector3, label: Dictionary, extra: Dictionary = {}):
		var it := {"id": id, "kind": kind, "pos": pos, "label": label, "interact": true, "node": self, "r": 1.6}
		it.merge(extra, true)
		items.append(it)
	add.call("door_kos", "door", Vector3(-7.6, 0, 9.6), Loc.T("Kamar kos · Lemari", "Your room · Wardrobe"), {"open": "wardrobe", "h": 2.8})
	add.call("door_kafe", "door", Vector3(9.3, 0, -1.0), Loc.T("Kopi Senja & Toko 24 Jam", "Café & 24h Store"), {"open": "shop", "h": 3.2})
	add.call("loket", "door", Vector3(6.5, 0, -3.1), Loc.T("Loket TU · Akademik", "Admin desk · Academics"), {"open": "academic", "h": 2.6})
	add.call("kerja", "door", Vector3(4.8, 0, 10.0), Loc.T("Pos info lowongan kerja", "Job board"), {"open": "jobs", "h": 2.6})
	add.call("mading", "mading", Vector3(-9.1, 0, -3.2), Loc.T("Baca mading", "Read the notice board"), {"h": 2.4})
	add.call("jajan", "jajan", Vector3(8.8, 0, 6.6), Loc.T("Jajan gorengan (-10 koin)", "Buy fritters (-10 coins)"), {"h": 2.6})
	add.call("buku", "buku", Vector3(-7.7, 0, 2.0), Loc.T("Mampir perpus", "Pop into the library"), {"h": 2.8})


func _spawn_pickups() -> void:
	if items.is_empty():
		_static_items()
		for n in world.npcs:
			items.append({"id": "npc_%d" % n.get_instance_id(), "kind": "npc", "node": n, "moving": true, "interact": true, "label": Loc.T("Ngobrol", "Chat"), "r": 1.5, "h": 2.5})
		items.append({"id": "cat", "kind": "cat", "node": _cat, "moving": true, "interact": true, "label": Loc.T("Elus kucing", "Pet the cat"), "r": 1.4, "h": 1.2})
		items.append({"id": "ball", "kind": "ball", "node": _ball, "moving": true, "interact": true, "label": Loc.T("Tendang bola", "Kick the ball"), "r": 1.2, "h": 1.0})
	var st := Game.explore_state()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(st.wk) * 7919 + hash(Game.s.get("name", ""))
	var idx: Array = range(COIN_SPOTS.size())
	for k in range(idx.size() - 1, 0, -1):
		var j := rng.randi() % (k + 1)
		var t: int = idx[k]
		idx[k] = idx[j]
		idx[j] = t
	for i in Data.EXPLORE_COINS_PER_WEEK:
		var id := "c%d" % idx[i]
		if id in st.coins:
			continue
		var pos: Vector3 = COIN_SPOTS[idx[i]]
		items.append({"id": id, "kind": "coin", "pos": pos, "node": _coin(pos), "temp": true})
	if int(st.dia_sem) != int(Game.s.sem):
		var pos: Vector3 = DIAMOND_SPOTS[absi(int(Game.s.sem) * 3 + hash(Game.s.get("name", ""))) % DIAMOND_SPOTS.size()]
		items.append({"id": "diamond", "kind": "diamond", "pos": pos, "node": _diamond(pos), "temp": true})


func _pickup_check() -> void:
	for it in items.duplicate():
		if not (it.kind == "coin" or it.kind == "diamond") or not is_instance_valid(it.node):
			continue
		var d := Vector2(it.pos.x - player.position.x, it.pos.z - player.position.z).length()
		if d > 0.75:
			continue
		var fx := Game.explore_reward(it.kind, it.id)
		var node: Node3D = it.node
		items.erase(it)
		var tw := node.create_tween().set_parallel(true)
		tw.tween_property(node, "position:y", node.position.y + 1.4, 0.35)
		tw.tween_property(node, "scale", Vector3.ONE * 0.1, 0.35).set_delay(0.1)
		tw.chain().tween_callback(node.queue_free)
		Audio.play("diamond" if it.kind == "diamond" else "coin", -2.0)
		acted.emit(it, {"fx": fx, "line": {}, "open": ""})


func _coin(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos + Vector3(0, 0.55, 0)
	add_child(n)
	var c := Mat.add(n, Mat.cyl(0.22, 0.22, 0.06, 20), Mat.vinyl(Color("ffc83d"), 0.2), Vector3.ZERO, Vector3(deg_to_rad(90), 0, 0))
	Mat.add(c, Mat.cyl(0.14, 0.14, 0.07, 16), Mat.vinyl(Color("ffb020"), 0.2), Vector3.ZERO)
	var glow := OmniLight3D.new()
	glow.light_color = Color("ffd98a")
	glow.light_energy = 0.5
	glow.omni_range = 1.4
	n.add_child(glow)
	n.set_meta("spin", 0.55)
	return n


func _diamond(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos + Vector3(0, 0.7, 0)
	add_child(n)
	var m := SphereMesh.new()
	m.radius = 0.3
	m.height = 0.75
	m.radial_segments = 4
	m.rings = 1
	Mat.add(n, m, Mat.vinyl(Color("4fc3ff"), 0.1), Vector3.ZERO)
	var glow := OmniLight3D.new()
	glow.light_color = Color("8fe0ff")
	glow.light_energy = 0.9
	glow.omni_range = 2.2
	n.add_child(glow)
	n.set_meta("spin", 0.7)
	return n


func _build_ball() -> void:
	_ball = Node3D.new()
	_ball.position = Vector3(3.2, 0.22, 1.6)
	add_child(_ball)
	var b := Mat.add(_ball, Mat.sphere(0.22, 16), Mat.vinyl(Color.WHITE, 0.3), Vector3.ZERO)
	for a in [Vector3(0, 0.2, 0.08), Vector3(0.17, -0.05, 0.1), Vector3(-0.15, -0.08, 0.12), Vector3(0.0, -0.1, -0.19), Vector3(0.12, 0.12, -0.13)]:
		Mat.add(b, Mat.sphere(0.07, 8), Mat.vinyl(Color("2a2238"), 0.3), a)


func _build_cat() -> void:
	_cat = Node3D.new()
	_cat.position = Vector3(-6.3, 0, 4.6)
	_cat.rotation.y = -0.6
	add_child(_cat)
	var fur := Mat.vinyl(Color("f2a03d"), 0.45)
	var white := Mat.vinyl(Color("fff3e0"), 0.45)
	Mat.add(_cat, Mat.capsule(0.16, 0.5), fur, Vector3(0, 0.22, 0), Vector3(deg_to_rad(90), 0, 0))
	Mat.add(_cat, Mat.sphere(0.16, 16), fur, Vector3(0, 0.38, 0.26))
	Mat.add(_cat, Mat.sphere(0.08, 10), white, Vector3(0, 0.34, 0.38), Vector3.ZERO, Vector3(1.2, 0.8, 0.7))
	for sx in [-1.0, 1.0]:
		var ear := CylinderMesh.new()
		ear.top_radius = 0.0
		ear.bottom_radius = 0.06
		ear.height = 0.12
		Mat.add(_cat, ear, fur, Vector3(0.08 * sx, 0.53, 0.25))
		Mat.add(_cat, Mat.sphere(0.022, 8), Mat.vinyl(Color("1a1420"), 0.15), Vector3(0.06 * sx, 0.41, 0.4))
		for z in [-0.14, 0.16]:
			Mat.add(_cat, Mat.cyl(0.04, 0.04, 0.16, 8), white, Vector3(0.08 * sx, 0.08, z))
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.28, -0.26)
	_cat.add_child(tail)
	Mat.add(tail, Mat.capsule(0.035, 0.36), fur, Vector3(0, 0.14, -0.05), Vector3(-0.4, 0, 0))


func _cat_purr() -> void:
	var tw := _cat.create_tween()
	tw.tween_property(_cat, "scale", Vector3(1.1, 0.9, 1.1), 0.12)
	tw.tween_property(_cat, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var e := Label3D.new()
	e.text = "<3"
	e.font = load("res://assets/fonts/Fredoka.ttf")
	e.font_size = 80
	e.pixel_size = 0.006
	e.outline_size = 18
	e.modulate = Color("ff6b9a")
	e.outline_modulate = Color.WHITE
	e.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	e.no_depth_test = true
	e.position = Vector3(0, 0.9, 0.2)
	_cat.add_child(e)
	var t2 := e.create_tween()
	t2.tween_property(e, "position:y", 1.6, 1.2)
	t2.parallel().tween_property(e, "modulate:a", 0.0, 1.2)
	t2.tween_callback(e.queue_free)


func _animate_props(delta: float) -> void:
	for c in get_children():
		if c.has_meta("spin"):
			c.rotation.y += delta * 2.6
			c.position.y = float(c.get_meta("spin")) + sin(_t * 3.0 + c.position.x) * 0.08
	if _cat:
		var tail: Node3D = _cat.get_node("Tail")
		tail.rotation.z = sin(_t * 3.0) * 0.5
	# Ball: rolls with friction, bounces off obstacles and the field edge.
	if _ball_v.length() > 0.05:
		var p := _ball.position + _ball_v * delta
		var c := _collide(p, 0.22)
		if Vector2(c.x - p.x, c.z - p.z).length() > 0.001:
			var n := Vector3(c.x - p.x, 0, c.z - p.z).normalized()
			_ball_v = _ball_v - 2.0 * _ball_v.dot(n) * n
			_ball_v *= 0.7
			Audio.play("tick", -6.0)
		_ball.position = Vector3(c.x, 0.22, c.z)
		var axis := Vector3.UP.cross(_ball_v.normalized())
		if axis.length() > 0.01:
			_ball.rotate(axis.normalized(), _ball_v.length() * delta / 0.22)
		_ball_v *= pow(0.35, delta)
		_goal_check()
	_goal_cool = maxf(0.0, _goal_cool - delta)


func _kick_check(dir: Vector3, speed: float) -> void:
	var d := Vector2(_ball.position.x - player.position.x, _ball.position.z - player.position.z)
	if d.length() < 0.6:
		var push := Vector3(d.x, 0, d.y).normalized()
		_ball_v = (push * 0.6 + dir * 0.4).normalized() * maxf(speed * 1.5, _ball_v.length())
		_ball.position = Vector3(player.position.x + push.x * 0.62, 0.22, player.position.z + push.z * 0.62)


func _goal_check() -> void:
	if _goal_cool > 0.0:
		return
	var p := _ball.position
	if p.z > 0.95 and p.z < 2.25 and (absf(p.x - 0.1) < 0.3 or absf(p.x - 6.3) < 0.3):
		_goal_cool = 2.5
		_ball_v = Vector3.ZERO
		var fx := Game.explore_reward("goal")
		player.play("cheer")
		player.hop()
		Audio.play("levelup", -4.0)
		_after(1.5, func():
			player.play("idle")
			_ball.position = Vector3(3.2, 0.22, 1.6))
		acted.emit({"id": "goal", "kind": "goal"}, {"fx": fx, "line": Loc.T("GOOOL!", "GOOOAL!"), "open": ""})


func _after(t: float, cb: Callable) -> void:
	await get_tree().create_timer(t).timeout
	cb.call()

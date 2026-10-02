class_name Stages
extends Node3D
## Interior "dollhouse" sets (cutaway rooms) built lazily far from the campus diorama, plus exterior
## sets that reuse campus locations. Each stage exposes named spots and a camera framing.
##
## Spot = {"pos": Vector3 (world), "rot": yaw (character faces +z when 0), "pose": stand|sit|lie|ride}
## Lists of spots (seats, queue, field...) are Arrays of spots.

var world: CampusWorld
var _built := {}

const ORIGINS := {
	"kelas": Vector3(-60, 0, -80), "kamar": Vector3(-40, 0, -80), "perpus": Vector3(-20, 0, -80),
	"sekre": Vector3(0, 0, -80), "kafe": Vector3(20, 0, -80), "konseling": Vector3(40, 0, -80),
	"ruang_dosen": Vector3(60, 0, -80),
}


func _init(w: CampusWorld) -> void:
	world = w
	name = "Stages"


static func spot(pos: Vector3, rot: float = 0.0, pose: String = "stand") -> Dictionary:
	return {"pos": pos, "rot": rot, "pose": pose}


func get_stage(id: String) -> Dictionary:
	if _built.has(id):
		return _built[id]
	var st: Dictionary
	match id:
		"kelas":
			st = _kelas(ORIGINS.kelas)
		"kamar":
			st = _kamar(ORIGINS.kamar)
		"perpus":
			st = _perpus(ORIGINS.perpus)
		"sekre":
			st = _sekre(ORIGINS.sekre)
		"kafe":
			st = _kafe(ORIGINS.kafe)
		"konseling":
			st = _konseling(ORIGINS.konseling)
		"ruang_dosen":
			st = _ruang_dosen(ORIGINS.ruang_dosen)
		"warkop":
			st = _warkop()
		"lapangan":
			st = _lapangan()
		"jalan":
			st = _jalan()
		"kos_depan":
			st = {"spots": {"player": spot(world.spots.kos + Vector3(0.6, 0, 0.6), PI * 0.75), "npc": spot(world.spots.kos + Vector3(-0.6, 0, -0.2), PI * 0.25)},
				"cam": {"focus": world.spots.kos + Vector3(0, 1.0, 0), "size": 6.5}}
		"rektorat":
			st = {"spots": {"player": spot(world.spots.rektorat + Vector3(0.4, 0, 0.8), PI), "npc": spot(world.spots.rektorat + Vector3(0.0, 0, -0.6), 0.0)},
				"cam": {"focus": world.spots.rektorat + Vector3(0, 1.0, 0), "size": 6.5}}
		_:
			return get_stage("kamar")
	st["id"] = id
	_built[id] = st
	return st


func _base(o: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = o
	add_child(n)
	return n


func _w(n: Node3D, local: Vector3) -> Vector3:
	return n.position + local


# --- Interiors -------------------------------------------------------------------

func _kelas(o: Vector3) -> Dictionary:
	var n := _base(o)
	Props.room(n, 8.0, 7.0, Color("e8d9b8"), "tiles", Color("cfd4da"))
	Props.whiteboard(n, Vector3(-0.9, 1.75, -3.42), 3.2, 1.3)
	var scr := Props.frame(n, Vector3(2.4, 1.95, -3.42), Vector2(1.9, 1.25), Color("2f6bff"))
	Mat.add(scr, Mat.box(Vector3(1.6, 0.18, 0.02)), Mat.unlit(Color.WHITE), Vector3(0, 0.38, 0.04), Vector3.ZERO, Vector3.ONE, false)
	for i in 3:
		Mat.add(scr, Mat.box(Vector3(0.45, 0.45, 0.02)), Mat.unlit([Color("ffc83d"), Color("ff6b9a"), Color("2fbf71")][i]), Vector3(-0.55 + i * 0.55, -0.15, 0.04), Vector3.ZERO, Vector3.ONE, false)
	Props.window(n, Vector3(-3.92, 1.7, -1.2), PI * 0.5)
	Props.window(n, Vector3(-3.92, 1.7, 1.4), PI * 0.5)
	Mat.add(n, Mat.box(Vector3(1.0, 0.32, 0.26)), Mat.vinyl(Color.WHITE), Vector3(-3.0, 2.8, -3.3))
	Props.clock(n, Vector3(0.9, 2.75, -3.38))
	var d := Props.desk(n, Vector3(-2.6, 0, -2.2), 0.0, Vector3(1.4, 0.78, 0.7), Color("8a5a3c"))
	Props.laptop(d, Vector3(0.2, 0.81, 0.05), PI)
	Props.paper_stack(d, Vector3(-0.4, 0.81, 0), 0.12)
	Props.chair(n, Vector3(-2.6, 0, -2.85), 0.0, Color("1d2a4d"))
	var seats: Array = []
	var player_seat := {}
	for z in [-0.2, 1.7]:
		for x in [-1.9, 0.2, 2.3]:
			Props.lecture_chair(n, Vector3(x, 0, z), PI)
			var s := spot(_w(n, Vector3(x, 0, z)), PI, "sit")
			if x == 0.2 and z == 1.7:
				player_seat = s
			else:
				seats.append(s)
	Props.room_light(n, Vector3(0, 2.8, 0), 0.3, 9.0)
	return {"node": n, "cam": {"focus": _w(n, Vector3(0.0, 0.9, -0.4)), "size": 11.0},
		"spots": {
			"seat": player_seat, "seats": seats,
			"lecturer": spot(_w(n, Vector3(-1.1, 0, -2.55)), 0.35),
			"lecturer_seat": spot(_w(n, Vector3(-2.6, 0, -2.85)), 0.0, "sit"),
			"front": spot(_w(n, Vector3(0.7, 0, -2.5)), 0.0),
			"aisle": [spot(_w(n, Vector3(-0.85, 0, -1.2))), spot(_w(n, Vector3(-0.85, 0, 2.7))), spot(_w(n, Vector3(1.25, 0, 2.7))), spot(_w(n, Vector3(1.25, 0, -1.2)))],
		}}


func _kamar(o: Vector3) -> Dictionary:
	var n := _base(o)
	Props.room(n, 5.6, 5.0, Color("cfe8d5"), "wood", Color("c98f63"))
	Props.bed(n, Vector3(-1.95, 0, -1.3), 0.0)
	var d := Props.desk(n, Vector3(0.9, 0, -1.05), 0.0, Vector3(1.3, 0.75, 0.65))
	Props.laptop(d, Vector3(0.0, 0.78, -0.02), PI, Color("bfe6fb"))
	Props.lamp(d, Vector3(0.48, 0.78, -0.15))
	Props.mug(d, Vector3(-0.45, 0.78, 0.1))
	Props.book(d, Vector3(-0.35, 0.78, -0.15), Color("2fbf71"))
	Props.chair(n, Vector3(0.9, 0, -1.7), 0.0, Color("ff9f1c"))
	Props.fan(n, Vector3(2.25, 0, -1.9), -0.7)
	var lemari := Props.node(n, Vector3(-0.35, 0, -2.2))
	Mat.add(lemari, Mat.box(Vector3(1.0, 1.9, 0.5)), Mat.vinyl(Props.WOOD_DARK, 0.5), Vector3(0, 0.95, 0))
	Mat.add(lemari, Mat.box(Vector3(0.03, 1.7, 0.02)), Mat.vinyl(Props.WOOD), Vector3(0, 0.95, 0.26), Vector3.ZERO, Vector3.ONE, false)
	Props.frame(n, Vector3(1.0, 2.05, -2.47), Vector2(0.9, 0.6), Color("ff6b9a"))
	Props.label(n, "SEMANGAT!", Vector3(1.0, 2.05, -2.42), 34, Color.WHITE)
	Props.window(n, Vector3(-2.75, 1.7, 0.8), PI * 0.5, 1.2, 1.0)
	Mat.add(n, Mat.cyl(0.2, 0.22, 0.55, 14), Mat.vinyl(Color(0.55, 0.8, 1.0)), Vector3(-2.3, 0.28, 1.8))
	Mat.add(n, Mat.cyl(0.18, 0.18, 0.28, 14), Mat.vinyl(Color("e85d75")), Vector3(2.2, 0.14, 1.4))
	for i in 3:
		Mat.add(n, Mat.cyl(0.06, 0.05, 0.12, 10), Mat.vinyl(Color("ffc83d")), Vector3(1.6 + i * 0.18, 0.06, 1.9))
	Props.room_light(n, Vector3(0, 2.6, -0.3), 0.3, 7.0)
	return {"node": n, "cam": {"focus": _w(n, Vector3(0.0, 0.8, -0.7)), "size": 8.4},
		"spots": {
			"desk": spot(_w(n, Vector3(0.9, 0, -1.7)), 0.0, "sit"),
			"bed": spot(_w(n, Vector3(-1.95, 0, -0.45)), 0.0, "lie"),
			"bed_edge": spot(_w(n, Vector3(-1.35, 0, -0.9)), PI * 0.5, "sit"),
			"floor": spot(_w(n, Vector3(0.4, 0, 0.9)), 0.0),
			"door": spot(_w(n, Vector3(1.8, 0, 1.6)), -PI * 0.6),
		}}


func _perpus(o: Vector3) -> Dictionary:
	var n := _base(o)
	Props.room(n, 8.0, 6.0, Color("e3cfa8"), "wood", Color("a8744f"))
	for x in [-2.8, -1.0, 0.8, 2.6]:
		Props.bookshelf(n, Vector3(x, 0, -2.75), 0.0, 1.7, 2.3)
	for z in [-1.3, 0.6]:
		Props.bookshelf(n, Vector3(-3.75, 0, z), PI * 0.5, 1.7, 2.3)
	var t := Props.desk(n, Vector3(0.3, 0, -0.3), 0.0, Vector3(3.8, 0.76, 1.2), Color("c9a66b"))
	Props.lamp(t, Vector3(-1.2, 0.79, 0.0), Color("2fbf71"))
	Props.lamp(t, Vector3(1.2, 0.79, 0.0), Color("2fbf71"))
	Props.book(t, Vector3(-0.1, 0.79, -0.3), Color("2f6bff"), 0.0, true)
	Props.book(t, Vector3(1.0, 0.79, -0.35), Color("c8423b"), 0.4)
	Props.book(t, Vector3(-0.8, 0.79, 0.3), Color("7b5cff"), -0.3)
	var far: Array = []
	var near: Array = []
	for x in [-1.0, 0.2, 1.4]:
		Props.chair(n, Vector3(x, 0, -1.15), 0.0, Color("8a5a3c"))
		Props.chair(n, Vector3(x, 0, 0.55), PI, Color("8a5a3c"))
		far.append(spot(_w(n, Vector3(x, 0, -1.15)), 0.0, "sit"))
		near.append(spot(_w(n, Vector3(x, 0, 0.55)), PI, "sit"))
	Props.label(n, "SSSTT!", Vector3(2.2, 2.65, -2.55), 56, Color("c8423b"))
	Props.clock(n, Vector3(-1.9, 2.7, -2.55))
	Props.plant(n, Vector3(3.5, 0, 1.8))
	Props.room_light(n, Vector3(0, 2.8, 0), 0.3, 9.0)
	return {"node": n, "cam": {"focus": _w(n, Vector3(0.3, 0.9, -0.5)), "size": 10.0},
		"spots": {"seat": far[1], "seat_b": far[2], "seats": [far[0], near[0], near[2], near[1]]}}


func _sekre(o: Vector3) -> Dictionary:
	var n := _base(o)
	Props.room(n, 7.0, 6.0, Color("f2dcb8"), "tiles", Color("c9cfd6"))
	var c := Vector3(0, 0, -0.3)
	Mat.add(n, Mat.cyl(1.05, 1.05, 0.06, 28), Mat.vinyl(Color.WHITE), c + Vector3(0, 0.76, 0))
	Mat.add(n, Mat.cyl(0.08, 0.12, 0.74, 10), Mat.vinyl(Props.METAL), c + Vector3(0, 0.37, 0))
	Props.paper_stack(n, c + Vector3(0.3, 0.79, 0.1), 0.1)
	Props.laptop(n, c + Vector3(-0.35, 0.79, -0.2), 0.6)
	var seats: Array = []
	var player := {}
	var seat_b := {}
	for i in 5:
		var a := PI * 0.5 + TAU * i / 5.0
		var p := c + Vector3(cos(a), 0, -sin(a)) * 1.45
		p.z = c.z + (p.z - c.z)
		var yaw := atan2(c.x - p.x, c.z - p.z)
		Props.chair(n, p, yaw, Color("2f6bff"))
		var s := spot(_w(n, p), yaw, "sit")
		if i == 0:
			player = s
		elif i == 1:
			seat_b = s
		else:
			seats.append(s)
	Props.whiteboard(n, Vector3(-1.6, 1.75, -2.92), 2.6, 1.2, "PROKER 2026")
	Props.label(n, "HIMPUNAN MAHASISWA", Vector3(-3.38, 2.55, -0.5), 46, Color("2f6bff"), PI * 0.5)
	Props.frame(n, Vector3(1.9, 1.9, -2.95), Vector2(1.2, 0.8), Color("ffc83d"))
	for i in 3:
		Mat.add(n, Mat.box(Vector3(0.5, 0.4, 0.5)), Mat.vinyl(Color("c9a66b")), Vector3(2.7, 0.2 + i * 0.4, -2.3 + (i % 2) * 0.05))
	Props.room_light(n, Vector3(0, 2.8, 0), 0.3, 8.0)
	return {"node": n, "cam": {"focus": _w(n, Vector3(-0.2, 0.9, -0.6)), "size": 9.4},
		"spots": {"seat": player, "seat_b": seat_b, "seats": seats, "head": spot(_w(n, Vector3(-2.2, 0, -1.9)), 0.5)}}


func _kafe(o: Vector3) -> Dictionary:
	var n := _base(o)
	Props.room(n, 8.0, 6.5, Color("f5c9a3"), "tiles", Color("d8cfc0"))
	Props.counter(n, Vector3(0.6, 0, -0.9), 3.6, Color("2f5d50"))
	Props.counter(n, Vector3(0.6, 0, -2.85), 4.0, Color("8a5a3c"))
	var mach := Props.node(n, Vector3(0.0, 1.06, -2.85))
	Mat.add(mach, Mat.box(Vector3(0.7, 0.55, 0.45)), Mat.vinyl(Color("c0c4cc"), 0.2), Vector3(0, 0.28, 0))
	Mat.add(mach, Mat.cyl(0.05, 0.05, 0.2, 8), Mat.vinyl(Color("2a2238")), Vector3(-0.15, 0.1, 0.25), Vector3(PI * 0.5, 0, 0))
	for i in 4:
		Props.mug(n, Vector3(0.8 + i * 0.3, 1.06, -2.8), [Color.WHITE, Color("ffc83d"), Color("ff6b9a"), Color("2f6bff")][i])
	var board := Props.frame(n, Vector3(0.6, 2.3, -3.2), Vector2(2.4, 0.9), Color("2a2238"))
	Props.label(board, "MENU  ·  Es Kopi Aren 18K  ·  Kopi Susu 15K", Vector3(0, 0, 0.05), 26, Color.WHITE)
	var sign := Props.label(n, "KOPI SENJA", Vector3(0.6, 2.95, -3.15), 72, Color("ff6b9a"))
	var reg := Props.node(n, Vector3(1.6, 1.06, -0.9))
	Mat.add(reg, Mat.box(Vector3(0.4, 0.25, 0.35)), Mat.vinyl(Color("2a2238")), Vector3(0, 0.12, 0))
	Mat.add(reg, Mat.box(Vector3(0.3, 0.2, 0.02)), Mat.unlit(Color("2fbf71")), Vector3(0, 0.33, 0), Vector3(-0.4, 0, 0))
	var shelf := Props.node(n, Vector3(-3.65, 0, -0.4), PI * 0.5)
	Mat.add(shelf, Mat.box(Vector3(3.0, 2.0, 0.4)), Mat.vinyl(Color.WHITE), Vector3(0, 1.0, 0))
	var goods := [Color("ff5a4e"), Color("ffc83d"), Color("2fbf71"), Color("2f6bff"), Color("ff9f1c"), Color("7b5cff")]
	for row in 3:
		for i in 9:
			Mat.add(shelf, Mat.box(Vector3(0.22, 0.3, 0.2)), Mat.vinyl(goods[(i + row) % goods.size()], 0.4), Vector3(-1.3 + i * 0.32, 0.45 + row * 0.55, 0.12), Vector3.ZERO, Vector3.ONE, false)
	Props.plant(n, Vector3(3.5, 0, 1.5))
	Props.room_light(n, Vector3(0, 2.8, 0), 0.3, 9.0)
	return {"node": n, "sign": sign, "cam": {"focus": _w(n, Vector3(0.3, 1.0, -0.6)), "size": 10.0},
		"spots": {
			"counter": spot(_w(n, Vector3(0.6, 0, -1.6)), 0.0),
			"boss": spot(_w(n, Vector3(-1.1, 0, -1.9)), 0.5),
			"queue": [spot(_w(n, Vector3(0.6, 0, 0.2)), PI), spot(_w(n, Vector3(0.5, 0, 1.1)), PI), spot(_w(n, Vector3(0.9, 0, 2.0)), PI)],
		}}


func _konseling(o: Vector3) -> Dictionary:
	var n := _base(o)
	Props.room(n, 6.0, 5.0, Color("cfe3d4"), "wood", Color("c99f74"))
	Mat.add(n, Mat.cyl(1.5, 1.5, 0.02, 32), Mat.matte(Color("f2c6a0")), Vector3(0, 0.01, -0.4), Vector3.ZERO, Vector3.ONE, false)
	var a_pos := Vector3(1.0, 0, 0.3)
	var b_pos := Vector3(-0.9, 0, -1.1)
	var yaw_a := atan2(b_pos.x - a_pos.x, b_pos.z - a_pos.z)
	var yaw_b := atan2(a_pos.x - b_pos.x, a_pos.z - b_pos.z)
	Props.armchair(n, a_pos, yaw_a, Color("7b9acc"))
	Props.armchair(n, b_pos, yaw_b, Color("8fb996"))
	var t := Props.node(n, Vector3(0.05, 0, -0.45))
	Mat.add(t, Mat.cyl(0.35, 0.35, 0.05, 20), Mat.vinyl(Props.WOOD), Vector3(0, 0.45, 0))
	Mat.add(t, Mat.cyl(0.05, 0.05, 0.45, 8), Mat.vinyl(Props.WOOD_DARK), Vector3(0, 0.22, 0))
	Mat.add(t, Mat.box(Vector3(0.22, 0.1, 0.12)), Mat.vinyl(Color("e9f1f7")), Vector3(0.1, 0.52, 0))
	Props.mug(t, Vector3(-0.12, 0.475, 0.05), Color("2fbf71"))
	Props.plant(n, Vector3(-2.4, 0, 1.4), 1.3)
	Props.frame(n, Vector3(0.6, 1.9, -2.45), Vector2(1.4, 0.9), Color("bfe6fb"))
	Props.lamp(n, Vector3(2.3, 0, -1.9))
	Props.bookshelf(n, Vector3(-2.75, 0, -0.6), PI * 0.5, 1.4, 1.4)
	Props.room_light(n, Vector3(0, 2.4, -0.4), 0.3, 6.0)
	return {"node": n, "cam": {"focus": _w(n, Vector3(0.0, 0.8, -0.4)), "size": 7.8},
		"spots": {"chair_a": spot(_w(n, a_pos), yaw_a, "sit"), "chair_b": spot(_w(n, b_pos), yaw_b, "sit")}}


func _ruang_dosen(o: Vector3) -> Dictionary:
	var n := _base(o)
	Props.room(n, 6.5, 5.0, Color("cfdde8"), "tiles", Color("c9d1da"))
	var d := Props.desk(n, Vector3(-0.2, 0, -1.0), 0.0, Vector3(1.8, 0.78, 0.8), Color("6b4a33"))
	for i in 4:
		Props.paper_stack(d, Vector3(-0.7 + i * 0.22, 0.81, -0.15 + (i % 2) * 0.2), randf_range(0.15, 0.45))
	var mon := Props.node(d, Vector3(0.55, 0.81, -0.2), PI)
	Mat.add(mon, Mat.box(Vector3(0.55, 0.36, 0.04)), Mat.vinyl(Color("2a2238")), Vector3(0, 0.32, 0))
	Mat.add(mon, Mat.box(Vector3(0.05, 0.14, 0.05)), Mat.vinyl(Color("2a2238")), Vector3(0, 0.07, 0))
	Props.mug(d, Vector3(0.1, 0.81, 0.25), Color("c8423b"))
	Props.label(d, "Dr. ...", Vector3(0, 0.92, 0.36), 40, Color("2a2238"))
	Props.chair(n, Vector3(-0.2, 0, -1.75), 0.0, Color("2a2238"))
	Props.chair(n, Vector3(-0.2, 0, -0.15), PI, Color("3d5a80"))
	Props.bookshelf(n, Vector3(1.9, 0, -2.3), 0.0, 1.6, 2.2)
	for i in 3:
		Props.frame(n, Vector3(-0.9 + i * 0.7, 2.1, -2.45), Vector2(0.5, 0.38), Color("fff3e0"))
	Mat.add(n, Mat.box(Vector3(1.0, 0.32, 0.26)), Mat.vinyl(Color.WHITE), Vector3(-0.2, 2.8, -2.3))
	Props.plant(n, Vector3(2.7, 0, 0.9))
	var door := Props.node(n, Vector3(-2.2, 0, -2.42), 0.0)
	Mat.add(door, Mat.box(Vector3(1.0, 2.2, 0.08)), Mat.vinyl(Color("8a5a3c")), Vector3(0, 1.1, 0))
	Mat.add(door, Mat.sphere(0.05, 8), Mat.vinyl(Color("ffc83d")), Vector3(0.38, 1.05, 0.06))
	var door_sign := Props.label(door, "", Vector3(0, 1.6, 0.06), 30, Color("c8423b"))
	Props.room_light(n, Vector3(0, 2.6, -0.5), 0.3, 7.0)
	return {"node": n, "door_sign": door_sign, "cam": {"focus": _w(n, Vector3(-0.5, 0.9, -0.5)), "size": 8.6},
		"spots": {
			"dosen_chair": spot(_w(n, Vector3(-0.2, 0, -1.75)), 0.0, "sit"),
			"guest": spot(_w(n, Vector3(-0.2, 0, -0.15)), PI, "sit"),
			"door": spot(_w(n, Vector3(-2.2, 0, -1.5)), PI),
		}}


# --- Exteriors on the campus ---------------------------------------------------------

func _warkop() -> Dictionary:
	var c := Vector3(8.8, 0, 6.2)
	return {"cam": {"focus": c + Vector3(0, 0.9, 1.6), "size": 7.0},
		"spots": {
			"bench": spot(c + Vector3(-0.85, 0, 1.9), 0.0, "sit"),
			"bench_b": spot(c + Vector3(-0.15, 0, 1.9), 0.0, "sit"),
			"bench_c": spot(c + Vector3(0.75, 0, 1.9), 0.0, "sit"),
		}}


func _lapangan() -> Dictionary:
	var c := Vector3(3.2, 0, 1.6)
	var field: Array = []
	for i in 6:
		field.append(spot(c + Vector3(-2.2 + (i % 3) * 2.2, 0, -1.0 + (i / 3) * 2.0), randf_range(-0.6, 0.6)))
	return {"cam": {"focus": c + Vector3(0, 1.0, 0), "size": 8.5},
		"spots": {
			"track": spot(c + Vector3(-2.8, 0, 1.8), PI * 0.5),
			"track_path": [c + Vector3(2.8, 0, 1.8), c + Vector3(2.8, 0, -1.8), c + Vector3(-2.8, 0, -1.8), c + Vector3(-2.8, 0, 1.8), c + Vector3(2.8, 0, 1.8)],
			"field": spot(c + Vector3(0.2, 0, 0.3), 0.3),
			"field_b": spot(c + Vector3(-0.8, 0, 0.6), 0.5),
			"field_list": field,
		}}


func _jalan() -> Dictionary:
	return {"cam": {"focus": Vector3(-4, 1.0, 13.2), "size": 6.5, "follow": true},
		"spots": {
			"road": spot(Vector3(-9.0, 0, 13.0), PI * 0.5, "ride"),
			"pillion": spot(Vector3(-9.55, 0.05, 13.0), PI * 0.5, "ride"),
			"road_end": Vector3(9.0, 0, 13.0),
		}}

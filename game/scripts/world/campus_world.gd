class_name CampusWorld
extends Node3D
## Builds the low-poly Indonesian campus diorama procedurally and owns the camera & time of day.

const D := preload("res://scripts/autoload/data.gd")

## Where the player stands for each activity location.
var spots := {
	"kos": Vector3(-8.4, 0, 10.5),
	"fakultas": Vector3(-5.0, 0, -2.2),
	"perpus": Vector3(-6.6, 0, 1.6),
	"rektorat": Vector3(6.0, 0, -3.4),
	"lapangan": Vector3(2.4, 0, 1.0),
	"warkop": Vector3(7.4, 0, 4.4),
	"kafe": Vector3(9.4, 0, -0.6),
	"minimarket": Vector3(9.4, 0, -0.6),
	"jalan": Vector3(3.2, 0, 10.4),
}
var labels := {
	"kos": {"id": "Kos", "en": "Boarding House"},
	"fakultas": {"id": "Gedung Kuliah", "en": "Lecture Hall"},
	"perpus": {"id": "Perpustakaan", "en": "Library"},
	"rektorat": {"id": "Rektorat & TU", "en": "Admin Building"},
	"lapangan": {"id": "Lapangan", "en": "Field"},
	"warkop": {"id": "Warkop", "en": "Coffee Stall"},
	"kafe": {"id": "Kafe & Toko 24 Jam", "en": "Café & 24h Store"},
	"jalan": {"id": "Jalan Raya", "en": "Main Road"},
}

var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var player: VinylChar
var npcs: Array = []
var lamps: Array = []
var cam_focus := Vector3(0, 0, 2)
var cam_size := 19.0
var cam_frac := 0.5
var following := false
var _cam_target_focus := Vector3(0, 0, 2)
var _cam_target_size := 19.0
var _cam_target_frac := 0.5
var _rng := RandomNumberGenerator.new()
var _waypoints: Array = []

const C_WALL := Color("f4ead5")
const C_WALL2 := Color("e9f1f7")
const C_ROOF := Color("d0573a")
const C_ROOF2 := Color("b8452c")
const C_WIN := Color("3d5a80")
const C_FRAME := Color("ffffff")
const C_PATH := Color("d9d4c7")
const C_GRASS := Color("7cc265")
const C_TRUNK := Color("8a5a3c")
const C_LEAF := Color("45a34a")
const C_LEAF2 := Color("348c3d")


func _ready() -> void:
	_rng.seed = 7
	_build_env()
	_build_ground()
	_build_fakultas()
	_build_rektorat()
	_build_perpus()
	_build_kos()
	_build_warkop()
	_build_kafe()
	_build_lapangan()
	_build_road()
	_build_trees()
	_waypoints = spots.values()
	player = VinylChar.new()
	player.name = "Player"
	add_child(player)
	player.teleport(spots.kos)
	_spawn_npcs()
	set_time("pagi", true)


# --- Camera & lighting ---------------------------------------------------------

func _build_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9fd6f2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff3e0")
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 2.2
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-52), deg_to_rad(28), 0)
	sun.light_energy = 1.15
	sun.light_color = Color("fff1d6")
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.55
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = cam_size
	camera.near = 0.1
	camera.far = 200.0
	add_child(camera)
	_update_camera()


## Points the camera at p. frac = where p should sit vertically on screen (0 top, 1 bottom),
## so the subject stays visible above bottom sheets.
func focus(p: Vector3, size: float = 19.0, instant: bool = false, frac: float = 0.5) -> void:
	following = false
	_cam_target_focus = p
	_cam_target_size = size
	_cam_target_frac = frac
	if instant:
		cam_focus = p
		cam_size = size
		cam_frac = frac
		_update_camera()


## Keeps the camera on the player.
func follow(size: float = 13.0, frac: float = 0.33, instant: bool = false) -> void:
	focus(player.position + Vector3(0, 1.0, 0), size, instant, frac)
	following = true


func _update_camera() -> void:
	var yaw := deg_to_rad(38.0)
	var pitch := deg_to_rad(-33.0)
	var dir := Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch))
	camera.position = cam_focus + dir * 40.0
	camera.look_at(cam_focus, Vector3.UP)
	camera.size = cam_size
	camera.v_offset = (cam_frac - 0.5) * cam_size


## pagi | siang | malam
func set_time(slot: String, instant: bool = false) -> void:
	var sky := Color("9fd6f2")
	var sun_c := Color("fff1d6")
	var sun_e := 0.95
	var amb := 0.4
	var lamp_on := false
	match slot:
		"pagi":
			sky = Color("b5e3f5")
			sun_c = Color("ffe9c4")
			sun_e = 0.9
		"siang":
			sky = Color("8fd0f2")
			sun_c = Color("fffaf0")
			sun_e = 1.0
			amb = 0.42
		"malam":
			sky = Color("1c2348")
			sun_c = Color("7f95ff")
			sun_e = 0.22
			amb = 0.16
			lamp_on = true
	for l in lamps:
		l.visible = lamp_on
	if instant:
		env.background_color = sky
		sun.light_color = sun_c
		sun.light_energy = sun_e
		env.ambient_light_energy = amb
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(env, "background_color", sky, 0.6)
	tw.tween_property(sun, "light_color", sun_c, 0.6)
	tw.tween_property(sun, "light_energy", sun_e, 0.6)
	tw.tween_property(env, "ambient_light_energy", amb, 0.6)


func _process(delta: float) -> void:
	var k := minf(1.0, delta * 3.0)
	if following:
		_cam_target_focus = player.position + Vector3(0, 1.0, 0)
	cam_focus = cam_focus.lerp(_cam_target_focus, k)
	cam_size = lerpf(cam_size, _cam_target_size, k)
	cam_frac = lerpf(cam_frac, _cam_target_frac, k)
	_update_camera()
	for n in npcs:
		if not n.walking and _rng.randf() < delta * 0.25:
			var p: Vector3 = _waypoints[_rng.randi() % _waypoints.size()]
			n.walk_to(p + Vector3(_rng.randf_range(-1.6, 1.6), 0, _rng.randf_range(-1.2, 1.2)))


func move_player(loc: String) -> void:
	var p: Vector3 = spots.get(loc, spots.kos)
	player.walk_to(p)


func _spawn_npcs() -> void:
	var tops := ["top_tee", "top_flanel", "top_hoodie_ungu", "top_almamater", "top_batik", "top_varsity"]
	var hairs := ["hair_short", "hair_fringe", "hair_long", "hair_hijab", "hair_buzz", "hair_curly"]
	var backs := ["back_none", "back_ransel", "back_tote"]
	var prodis := D.PRODI.keys()
	for i in 7:
		var n := VinylChar.new()
		add_child(n)
		n.build({
			"skin": _rng.randi() % D.SKIN_TONES.size(), "hair": hairs[_rng.randi() % hairs.size()],
			"hair_color": _rng.randi() % 3, "top": tops[_rng.randi() % tops.size()],
			"back": backs[_rng.randi() % backs.size()],
		}, prodis[_rng.randi() % prodis.size()])
		n.speed = _rng.randf_range(1.4, 2.2)
		n.scale = Vector3.ONE * 0.92
		var p: Vector3 = _waypoints[i % _waypoints.size()]
		n.teleport(p + Vector3(_rng.randf_range(-2, 2), 0, _rng.randf_range(-1, 1)))
		npcs.append(n)


# --- Builders ------------------------------------------------------------------

func _build_ground() -> void:
	Mat.add(self, Mat.box(Vector3(34, 0.6, 30)), Mat.matte(C_GRASS), Vector3(0, -0.3, 1))
	# Soil sides for a diorama feel.
	Mat.add(self, Mat.box(Vector3(34.2, 1.4, 30.2)), Mat.matte(Color("a8744f")), Vector3(0, -1.2, 1))
	var path := Mat.matte(C_PATH)
	Mat.add(self, Mat.box(Vector3(2.2, 0.06, 18)), path, Vector3(0.2, 0.03, 1.5), Vector3.ZERO, Vector3.ONE, false)
	Mat.add(self, Mat.box(Vector3(19, 0.06, 2.0)), path, Vector3(0.5, 0.03, -1.5), Vector3.ZERO, Vector3.ONE, false)
	Mat.add(self, Mat.box(Vector3(14, 0.06, 1.8)), path, Vector3(-1.0, 0.03, 4.8), Vector3.ZERO, Vector3.ONE, false)
	Mat.add(self, Mat.box(Vector3(12, 0.06, 1.6)), path, Vector3(-5.6, 0.03, 10.5), Vector3.ZERO, Vector3.ONE, false)


func _gable_roof(parent: Node3D, center: Vector3, w: float, d: float, h: float, color: Color, along_x: bool = true) -> void:
	var prism := PrismMesh.new()
	prism.size = Vector3(d + 0.6, h, w + 0.6) if along_x else Vector3(w + 0.6, h, d + 0.6)
	var rot := Vector3(0, deg_to_rad(90), 0) if along_x else Vector3.ZERO
	Mat.add(parent, prism, Mat.vinyl(color, 0.55), center + Vector3(0, h * 0.5, 0), rot)
	# Ridge cap.
	var ridge_len := w + 0.7 if along_x else d + 0.7
	var ridge := Mat.box(Vector3(ridge_len, 0.12, 0.16) if along_x else Vector3(0.16, 0.12, ridge_len))
	Mat.add(parent, ridge, Mat.vinyl(color.darkened(0.2)), center + Vector3(0, h + 0.02, 0))


func _windows_row(parent: Node3D, origin: Vector3, count: int, gap: float, y: float, facing: Vector3, size: Vector2 = Vector2(0.9, 1.0)) -> void:
	var along := Vector3(facing.z, 0, -facing.x).abs()
	for i in count:
		var off := (i - (count - 1) * 0.5) * gap
		var p := origin + along * off + Vector3(0, y, 0) + facing * 0.02
		var frame_size := Vector3(size.x + 0.14, size.y + 0.14, 0.06) if facing.z != 0 else Vector3(0.06, size.y + 0.14, size.x + 0.14)
		var glass_size := Vector3(size.x, size.y, 0.08) if facing.z != 0 else Vector3(0.08, size.y, size.x)
		Mat.add(parent, Mat.box(frame_size), Mat.vinyl(C_FRAME), p, Vector3.ZERO, Vector3.ONE, false)
		Mat.add(parent, Mat.box(glass_size), Mat.vinyl(C_WIN, 0.15), p + facing * 0.02, Vector3.ZERO, Vector3.ONE, false)


func _sign(text: String, pos: Vector3, rot_y: float = 0.0, size: int = 64, bg: Color = Color("2f6bff"), width: float = 0.0) -> void:
	var w := width if width > 0 else text.length() * size * 0.0055 + 0.6
	Mat.add(self, Mat.box(Vector3(w, size * 0.0085, 0.08)), Mat.vinyl(bg), pos, Vector3(0, rot_y, 0), Vector3.ONE, false)
	var l := Label3D.new()
	l.text = text
	l.font = load("res://assets/fonts/Fredoka.ttf")
	l.font_size = size
	l.pixel_size = 0.005
	l.outline_size = 0
	l.modulate = Color.WHITE
	l.position = pos + Vector3(sin(rot_y), 0, cos(rot_y)) * 0.05
	l.rotation.y = rot_y
	add_child(l)


func _building(center: Vector3, size: Vector3, wall: Color) -> Node3D:
	var b := Node3D.new()
	b.position = center
	add_child(b)
	Mat.add(b, Mat.box(Vector3(size.x + 0.2, 0.35, size.z + 0.2)), Mat.matte(Color("9a9a9a")), Vector3(0, 0.17, 0))
	Mat.add(b, Mat.box(size), Mat.matte(wall), Vector3(0, size.y * 0.5 + 0.3, 0))
	return b


func _build_fakultas() -> void:
	var c := Vector3(-5.5, 0, -6.5)
	var size := Vector3(9.5, 4.2, 5.2)
	var b := _building(c, size, C_WALL)
	# Floor band between storeys.
	Mat.add(b, Mat.box(Vector3(size.x + 0.15, 0.18, size.z + 0.15)), Mat.matte(Color("e2d3b5")), Vector3(0, 2.4, 0))
	_gable_roof(b, Vector3(0, size.y + 0.3, 0), size.x, size.z, 1.6, C_ROOF)
	var front := Vector3(0, 0, 1)
	_windows_row(b, Vector3(0, 0, size.z * 0.5), 6, 1.45, 3.4, front)
	_windows_row(b, Vector3(-2.5, 0, size.z * 0.5), 3, 1.3, 1.45, front)
	_windows_row(b, Vector3(2.9, 0, size.z * 0.5), 2, 1.3, 1.45, front)
	# Entrance with pillars & small porch roof.
	Mat.add(b, Mat.box(Vector3(1.6, 2.0, 0.1)), Mat.vinyl(Color("6b4a33")), Vector3(0.6, 1.3, size.z * 0.5 + 0.03))
	for px in [-0.6, 1.8]:
		Mat.add(b, Mat.cyl(0.14, 0.14, 2.4, 12), Mat.vinyl(C_FRAME), Vector3(px, 1.5, size.z * 0.5 + 1.1))
	Mat.add(b, Mat.box(Vector3(3.2, 0.18, 1.6)), Mat.vinyl(C_ROOF2), Vector3(0.6, 2.75, size.z * 0.5 + 0.8))
	_sign("GEDUNG KULIAH BERSAMA", c + Vector3(0, 3.0, size.z * 0.5 + 1.62), 0.0, 52, Color("2f6bff"))
	# Faded notice board ("Dosen sedang rapat").
	Mat.add(self, Mat.box(Vector3(1.0, 0.7, 0.05)), Mat.matte(Color("c49a6c")), c + Vector3(-3.6, 1.4, size.z * 0.5 + 0.05))
	Mat.add(self, Mat.box(Vector3(0.3, 0.4, 0.02)), Mat.matte(Color("fff7c2")), c + Vector3(-3.8, 1.45, size.z * 0.5 + 0.09))
	Mat.add(self, Mat.box(Vector3(0.35, 0.3, 0.02)), Mat.matte(Color("ffd6e0")), c + Vector3(-3.4, 1.35, size.z * 0.5 + 0.09))


func _build_rektorat() -> void:
	var c := Vector3(6.5, 0, -7.0)
	var size := Vector3(6.4, 3.6, 4.6)
	var b := _building(c, size, C_WALL2)
	# Joglo-inspired stacked roof.
	_gable_roof(b, Vector3(0, size.y + 0.3, 0), size.x, size.z, 1.0, C_ROOF2)
	Mat.add(b, Mat.box(Vector3(2.4, 1.0, 2.0)), Mat.vinyl(C_ROOF, 0.55), Vector3(0, size.y + 1.8, 0))
	_windows_row(b, Vector3(0, 0, size.z * 0.5), 4, 1.4, 2.6, Vector3(0, 0, 1), Vector2(0.8, 0.9))
	# Loket (service counters) with a queue rope.
	for i in 3:
		Mat.add(b, Mat.box(Vector3(0.9, 0.9, 0.12)), Mat.vinyl(Color("3d5a80"), 0.2), Vector3(-1.6 + i * 1.6, 1.2, size.z * 0.5 + 0.03))
	for i in 5:
		Mat.add(self, Mat.cyl(0.05, 0.08, 0.9, 8), Mat.vinyl(Color("c0c0c0")), c + Vector3(-2.4 + i * 1.2, 0.45, size.z * 0.5 + 1.0))
	Mat.add(self, Mat.box(Vector3(4.8, 0.05, 0.05)), Mat.vinyl(Color("d64545")), c + Vector3(0, 0.82, size.z * 0.5 + 1.0))
	_sign("REKTORAT · TATA USAHA", c + Vector3(0, 3.35, size.z * 0.5 + 0.06), 0.0, 48, Color("1d2a4d"))
	# Flag pole with merah putih.
	var fp := c + Vector3(-4.2, 0, 2.6)
	Mat.add(self, Mat.cyl(0.05, 0.07, 5.0, 8), Mat.vinyl(Color("e0e0e0")), fp + Vector3(0, 2.5, 0))
	Mat.add(self, Mat.box(Vector3(1.2, 0.36, 0.03)), Mat.vinyl(Color("e5262c")), fp + Vector3(0.62, 4.7, 0))
	Mat.add(self, Mat.box(Vector3(1.2, 0.36, 0.03)), Mat.vinyl(Color("ffffff")), fp + Vector3(0.62, 4.34, 0))


func _build_perpus() -> void:
	var c := Vector3(-11.0, 0, 2.0)
	var size := Vector3(5.0, 3.4, 6.0)
	var b := _building(c, size, Color("f0e2c8"))
	_gable_roof(b, Vector3(0, size.y + 0.3, 0), size.x, size.z, 1.4, C_ROOF, false)
	_windows_row(b, Vector3(size.x * 0.5, 0, 0), 3, 1.7, 2.1, Vector3(1, 0, 0), Vector2(1.1, 1.4))
	_sign("PERPUSTAKAAN", c + Vector3(size.x * 0.5 + 0.06, 3.3, 0), deg_to_rad(90), 52, Color("7b5cff"))
	# Benches outside.
	for z in [-1.5, 1.5]:
		_bench(c + Vector3(size.x * 0.5 + 1.4, 0, z), deg_to_rad(90))


func _build_kos() -> void:
	var c := Vector3(-9.2, 0, 7.4)
	var size := Vector3(5.2, 4.4, 3.4)
	var b := _building(c, size, Color("cfe8d5"))
	Mat.add(b, Mat.box(Vector3(size.x + 0.4, 0.12, 1.0)), Mat.matte(Color("bcbcbc")), Vector3(0, 2.4, size.z * 0.5 + 0.45))
	# Balcony railing.
	for i in 9:
		Mat.add(b, Mat.box(Vector3(0.05, 0.6, 0.05)), Mat.vinyl(Color("6b4a33")), Vector3(-2.6 + i * 0.65, 2.75, size.z * 0.5 + 0.9))
	Mat.add(b, Mat.box(Vector3(size.x + 0.3, 0.07, 0.07)), Mat.vinyl(Color("6b4a33")), Vector3(0, 3.05, size.z * 0.5 + 0.9))
	_gable_roof(b, Vector3(0, size.y + 0.3, 0), size.x, size.z, 1.3, Color("c7643f"))
	# Doors (rooms) & windows.
	for i in 3:
		var x := -1.7 + i * 1.7
		Mat.add(b, Mat.box(Vector3(0.7, 1.5, 0.08)), Mat.vinyl(Color("8a5a3c")), Vector3(x - 0.35, 1.05, size.z * 0.5 + 0.02))
		Mat.add(b, Mat.box(Vector3(0.5, 0.5, 0.08)), Mat.vinyl(C_WIN, 0.15), Vector3(x + 0.4, 1.4, size.z * 0.5 + 0.02))
		Mat.add(b, Mat.box(Vector3(0.7, 1.4, 0.08)), Mat.vinyl(Color("8a5a3c")), Vector3(x - 0.35, 3.0, size.z * 0.5 + 0.02))
	_sign("KOS BU ENDANG", c + Vector3(0, 4.15, size.z * 0.5 + 0.06), 0.0, 46, Color("33a06b"))
	# Jemuran (clothesline) with colorful laundry.
	var jx := c + Vector3(3.6, 0, 1.8)
	for dz in [-1.0, 1.0]:
		Mat.add(self, Mat.cyl(0.04, 0.04, 1.8, 6), Mat.vinyl(Color("9a9a9a")), jx + Vector3(0, 0.9, dz))
	Mat.add(self, Mat.box(Vector3(0.02, 0.02, 2.0)), Mat.vinyl(Color("eeeeee")), jx + Vector3(0, 1.75, 0))
	var cloth := [Color("ff6b9a"), Color("ffc83d"), Color("2f6bff"), Color("ffffff")]
	for i in 4:
		Mat.add(self, Mat.box(Vector3(0.03, 0.55, 0.36)), Mat.matte(cloth[i]), jx + Vector3(0, 1.45, -0.7 + i * 0.47))
	# Motor matic parked out front + galon.
	_motor(c + Vector3(-2.0, 0, 2.8), deg_to_rad(20), Color("ff5a4e"))
	_motor(c + Vector3(-0.6, 0, 3.0), deg_to_rad(10), Color("1d2a4d"))
	Mat.add(self, Mat.cyl(0.18, 0.2, 0.5, 12), Mat.vinyl(Color(0.55, 0.8, 1.0, 1.0), 0.1), c + Vector3(1.8, 0.25, 2.2))


func _build_warkop() -> void:
	var c := Vector3(8.8, 0, 6.2)
	# Wooden stall with a striped tarp roof.
	Mat.add(self, Mat.box(Vector3(3.4, 1.0, 1.0)), Mat.vinyl(Color("a8744f")), c + Vector3(0, 0.5, -0.8))
	Mat.add(self, Mat.box(Vector3(3.4, 0.08, 1.2)), Mat.vinyl(Color("e9d8a6")), c + Vector3(0, 1.04, -0.8))
	for px in [-1.6, 1.6]:
		for pz in [-1.3, 1.1]:
			Mat.add(self, Mat.cyl(0.05, 0.05, 2.4, 8), Mat.vinyl(Color("6b4a33")), c + Vector3(px, 1.2, pz))
	for i in 6:
		var col := Color("ff9f1c") if i % 2 == 0 else Color("2f6bff")
		Mat.add(self, Mat.box(Vector3(0.6, 0.06, 2.8)), Mat.vinyl(col, 0.6), c + Vector3(-1.5 + i * 0.6, 2.45 - absf(i - 2.5) * 0.04, -0.1))
	# Benches, kettle, gorengan tray.
	_bench(c + Vector3(-0.5, 0, 0.6), 0.0)
	_bench(c + Vector3(1.0, 0, 0.6), 0.0)
	Mat.add(self, Mat.cyl(0.15, 0.17, 0.25, 10), Mat.vinyl(Color("c0c0c0"), 0.2), c + Vector3(-1.0, 1.2, -0.8))
	Mat.add(self, Mat.box(Vector3(0.6, 0.06, 0.4)), Mat.vinyl(Color("e0e0e0")), c + Vector3(0.6, 1.12, -0.8))
	for i in 5:
		Mat.add(self, Mat.sphere(0.07, 8), Mat.vinyl(Color("d99a3e")), c + Vector3(0.4 + i * 0.1, 1.18, -0.8 + (i % 2) * 0.1), Vector3.ZERO, Vector3(1.2, 0.6, 0.8))
	_sign("WARKOP 24 JAM", c + Vector3(0, 2.75, 1.25), 0.0, 44, Color("ff9f1c"))
	# Gerobak bakso.
	_gerobak(c + Vector3(-3.2, 0, 1.2))


func _build_kafe() -> void:
	var c := Vector3(11.6, 0, -1.0)
	var size := Vector3(3.6, 3.0, 4.6)
	var b := _building(c, size, Color("ffe1c6"))
	Mat.add(b, Mat.box(Vector3(size.x + 0.2, 0.3, size.z + 0.2)), Mat.vinyl(Color("1d2a4d")), Vector3(0, size.y + 0.45, 0))
	_windows_row(b, Vector3(-size.x * 0.5, 0, 0), 2, 2.0, 1.4, Vector3(-1, 0, 0), Vector2(1.5, 1.4))
	# Striped awning.
	for i in 6:
		var col := Color("ff6b9a") if i % 2 == 0 else Color("ffffff")
		Mat.add(self, Mat.box(Vector3(1.0, 0.06, 0.76)), Mat.vinyl(col), c + Vector3(-size.x * 0.5 - 0.5, 2.5, -1.9 + i * 0.76), Vector3(0, 0, deg_to_rad(-18)))
	_sign("KOPI SENJA · TOKO 24 JAM", c + Vector3(-size.x * 0.5 - 0.06, 3.2, 0), deg_to_rad(-90), 40, Color("ff6b9a"))
	_motor(c + Vector3(-3.0, 0, 2.6), deg_to_rad(-40), Color("33c47a"))


func _build_lapangan() -> void:
	var c := Vector3(3.2, 0, 1.6)
	Mat.add(self, Mat.box(Vector3(6.4, 0.05, 4.4)), Mat.matte(Color("78c25a")), c + Vector3(0, 0.03, 0), Vector3.ZERO, Vector3.ONE, false)
	var line := Mat.unlit(Color(1, 1, 1, 0.85))
	Mat.add(self, Mat.box(Vector3(6.0, 0.02, 0.06)), line, c + Vector3(0, 0.07, 2.0), Vector3.ZERO, Vector3.ONE, false)
	Mat.add(self, Mat.box(Vector3(6.0, 0.02, 0.06)), line, c + Vector3(0, 0.07, -2.0), Vector3.ZERO, Vector3.ONE, false)
	Mat.add(self, Mat.box(Vector3(0.06, 0.02, 4.0)), line, c + Vector3(0, 0.07, 0), Vector3.ZERO, Vector3.ONE, false)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.75
	ring.outer_radius = 0.8
	Mat.add(self, ring, line, c + Vector3(0, 0.07, 0), Vector3.ZERO, Vector3(1, 0.05, 1), false)
	# Goals.
	for sx in [-1.0, 1.0]:
		var g := c + Vector3(3.1 * sx, 0, 0)
		for dz in [-0.7, 0.7]:
			Mat.add(self, Mat.cyl(0.04, 0.04, 1.0, 6), Mat.vinyl(Color.WHITE), g + Vector3(0, 0.5, dz))
		Mat.add(self, Mat.box(Vector3(0.06, 0.06, 1.46)), Mat.vinyl(Color.WHITE), g + Vector3(0, 1.0, 0))
	# Welcome banner on bamboo poles.
	var bp := Vector3(0.2, 0, 8.6)
	for sx in [-1.0, 1.0]:
		Mat.add(self, Mat.cyl(0.07, 0.08, 3.2, 8), Mat.vinyl(Color("c9a66b")), bp + Vector3(2.6 * sx, 1.6, 0))
	_sign("SELAMAT DATANG MAHASISWA BARU", bp + Vector3(0, 2.7, 0), 0.0, 44, Color("e5262c"), 5.4)


func _build_road() -> void:
	Mat.add(self, Mat.box(Vector3(34, 0.08, 3.2)), Mat.matte(Color("4a4a52")), Vector3(0, 0.04, 13.4), Vector3.ZERO, Vector3.ONE, false)
	for i in 9:
		Mat.add(self, Mat.box(Vector3(1.6, 0.02, 0.14)), Mat.unlit(Color("f2f2f2")), Vector3(-15 + i * 3.8, 0.09, 13.4), Vector3.ZERO, Vector3.ONE, false)
	# Campus gate (gapura) & pos satpam.
	for sx in [-1.0, 1.0]:
		Mat.add(self, Mat.box(Vector3(0.6, 3.0, 0.6)), Mat.vinyl(Color("f4ead5")), Vector3(0.2 + 1.9 * sx, 1.5, 11.3))
		Mat.add(self, Mat.box(Vector3(0.8, 0.25, 0.8)), Mat.vinyl(C_ROOF), Vector3(0.2 + 1.9 * sx, 3.1, 11.3))
	Mat.add(self, Mat.box(Vector3(4.6, 0.5, 0.5)), Mat.vinyl(Color("1d2a4d")), Vector3(0.2, 3.0, 11.3))
	var pos := Vector3(4.8, 0, 11.0)
	Mat.add(self, Mat.box(Vector3(1.4, 1.8, 1.4)), Mat.matte(Color("dfe7ef")), pos + Vector3(0, 0.9, 0))
	Mat.add(self, Mat.box(Vector3(1.7, 0.12, 1.7)), Mat.vinyl(Color("1d2a4d")), pos + Vector3(0, 1.86, 0))
	Mat.add(self, Mat.box(Vector3(0.7, 0.6, 0.06)), Mat.vinyl(C_WIN, 0.15), pos + Vector3(0, 1.1, 0.72))
	Mat.add(self, Mat.box(Vector3(2.4, 0.08, 0.08)), Mat.vinyl(Color("e5262c")), pos + Vector3(-1.8, 0.9, 0.5))
	# Ojol waiting by the road + street lamps.
	_motor(Vector3(3.2, 0, 12.2), deg_to_rad(90), Color("33c47a"))
	for x in [-9.0, -1.8, 6.5, 12.0]:
		_lamp(Vector3(x, 0, 11.6))
	_lamp(Vector3(-2.0, 0, 3.6))
	_lamp(Vector3(5.6, 0, -2.8))


func _build_trees() -> void:
	var mango := [Vector3(-13.5, 0, -4), Vector3(-1.2, 0, -10.5), Vector3(14.5, 0, 5.5), Vector3(-14.5, 0, 9.5), Vector3(0.8, 0, -4.4), Vector3(-4.2, 0, 8.0), Vector3(13.5, 0, -8.5)]
	for p in mango:
		_mango_tree(p, _rng.randf_range(0.85, 1.25))
	var palms := [Vector3(-15, 0, 12), Vector3(15, 0, 11.6), Vector3(-2.5, 0, -11.6), Vector3(15.5, 0, -4)]
	for p in palms:
		_palm(p)
	# Big beringin near the field.
	_mango_tree(Vector3(-1.8, 0, 7.4), 1.6)


func _mango_tree(p: Vector3, s: float) -> void:
	Mat.add(self, Mat.cyl(0.16 * s, 0.24 * s, 1.6 * s, 8), Mat.vinyl(C_TRUNK, 0.7), p + Vector3(0, 0.8 * s, 0))
	var leaf := Mat.vinyl(C_LEAF if _rng.randf() < 0.5 else C_LEAF2, 0.6)
	Mat.add(self, Mat.sphere(1.0 * s, 14), leaf, p + Vector3(0, 2.1 * s, 0), Vector3.ZERO, Vector3(1.1, 0.85, 1.1))
	Mat.add(self, Mat.sphere(0.7 * s, 12), leaf, p + Vector3(0.6 * s, 1.8 * s, 0.3 * s))
	Mat.add(self, Mat.sphere(0.6 * s, 12), leaf, p + Vector3(-0.5 * s, 1.9 * s, -0.4 * s))


func _palm(p: Vector3) -> void:
	var trunk := Mat.vinyl(Color("a07850"), 0.7)
	for i in 6:
		Mat.add(self, Mat.cyl(0.15, 0.18, 0.62, 8), trunk, p + Vector3(i * 0.06, 0.31 + i * 0.58, 0), Vector3(0, 0, -0.08))
	var top := p + Vector3(0.38, 3.6, 0)
	var leaf := Mat.vinyl(Color("5cb85c"), 0.6)
	for i in 7:
		var a := TAU * i / 7.0
		var dir := Vector3(cos(a), 0, sin(a))
		Mat.add(self, Mat.box(Vector3(1.6, 0.05, 0.32)), leaf, top + dir * 0.7 + Vector3(0, -0.2, 0), Vector3(0, -a, deg_to_rad(-22)))
	for i in 3:
		Mat.add(self, Mat.sphere(0.14, 8), Mat.vinyl(Color("6b8e23")), top + Vector3(cos(i * 2.1) * 0.15, -0.2, sin(i * 2.1) * 0.15))


func _bench(p: Vector3, rot_y: float) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = rot_y
	add_child(n)
	Mat.add(n, Mat.box(Vector3(1.4, 0.08, 0.42)), Mat.vinyl(Color("a8744f")), Vector3(0, 0.45, 0))
	for sx in [-0.6, 0.6]:
		Mat.add(n, Mat.box(Vector3(0.08, 0.45, 0.38)), Mat.vinyl(Color("6b4a33")), Vector3(sx, 0.22, 0))


func _motor(p: Vector3, rot_y: float, color: Color) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = rot_y
	add_child(n)
	var tire := Mat.vinyl(Color("1a1a1a"), 0.7)
	for z in [-0.55, 0.55]:
		Mat.add(n, Mat.cyl(0.24, 0.24, 0.12, 16), tire, Vector3(0, 0.24, z), Vector3(0, 0, deg_to_rad(90)))
	var body := Mat.vinyl(color, 0.3)
	Mat.add(n, Mat.capsule(0.22, 1.1), body, Vector3(0, 0.48, -0.1), Vector3(deg_to_rad(90), 0, 0), Vector3(0.9, 1, 0.7))
	Mat.add(n, Mat.box(Vector3(0.32, 0.1, 0.6)), Mat.vinyl(Color("222222")), Vector3(0, 0.72, -0.2))
	Mat.add(n, Mat.box(Vector3(0.18, 0.7, 0.16)), body, Vector3(0, 0.75, 0.45), Vector3(deg_to_rad(-15), 0, 0))
	Mat.add(n, Mat.cyl(0.03, 0.03, 0.62, 6), Mat.vinyl(Color("c0c0c0")), Vector3(0, 1.1, 0.52), Vector3(0, 0, deg_to_rad(90)))
	Mat.add(n, Mat.sphere(0.07, 8), Mat.unlit(Color("fff7c2")), Vector3(0, 0.95, 0.56))


func _gerobak(p: Vector3) -> void:
	var n := Node3D.new()
	n.position = p
	add_child(n)
	Mat.add(n, Mat.box(Vector3(1.4, 0.8, 0.7)), Mat.vinyl(Color("2f9e8f")), Vector3(0, 0.75, 0))
	Mat.add(n, Mat.box(Vector3(1.3, 0.5, 0.6)), Mat.vinyl(Color(0.85, 0.95, 1.0), 0.05), Vector3(0, 1.4, 0))
	Mat.add(n, Mat.box(Vector3(1.5, 0.06, 0.8)), Mat.vinyl(Color("ffc83d")), Vector3(0, 1.7, 0))
	for x in [-0.5, 0.5]:
		Mat.add(n, Mat.cyl(0.22, 0.22, 0.08, 14), Mat.vinyl(Color("333333")), Vector3(x, 0.22, 0.4), Vector3(deg_to_rad(90), 0, 0))
	Mat.add(n, Mat.cyl(0.18, 0.18, 0.25, 12), Mat.vinyl(Color("c0c0c0"), 0.2), Vector3(-0.3, 1.32, 0))
	var l := Label3D.new()
	l.text = "BAKSO"
	l.font = load("res://assets/fonts/Fredoka.ttf")
	l.font_size = 48
	l.pixel_size = 0.005
	l.modulate = Color("e5262c")
	l.position = Vector3(0, 0.8, 0.37)
	n.add_child(l)


func _lamp(p: Vector3) -> void:
	Mat.add(self, Mat.cyl(0.05, 0.07, 3.0, 8), Mat.vinyl(Color("4a4a52")), p + Vector3(0, 1.5, 0))
	Mat.add(self, Mat.sphere(0.18, 10), Mat.unlit(Color("fff2b0")), p + Vector3(0, 3.05, 0))
	var light := OmniLight3D.new()
	light.position = p + Vector3(0, 2.9, 0)
	light.light_color = Color("ffd98a")
	light.light_energy = 1.6
	light.omni_range = 5.0
	light.visible = false
	add_child(light)
	lamps.append(light)


## Floating stat-change text above the player (e.g. "+1.5 Knowledge").
func float_text(lines: Array) -> void:
	var i := 0
	for line in lines:
		var l := Label3D.new()
		l.text = line.text
		l.font = load("res://assets/fonts/Fredoka.ttf")
		l.font_size = 64
		l.pixel_size = 0.0045
		l.outline_size = 16
		l.modulate = Color("2fbf71") if line.good else Color("ff5a4e")
		l.outline_modulate = Color.WHITE
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.position = player.position + Vector3(0, 2.4 + i * 0.36, 0)
		add_child(l)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(l, "position:y", l.position.y + 0.9, 1.5)
		tw.tween_property(l, "modulate:a", 0.0, 1.5).set_delay(0.6)
		tw.tween_property(l, "outline_modulate:a", 0.0, 1.5).set_delay(0.6)
		tw.chain().tween_callback(l.queue_free)
		i += 1

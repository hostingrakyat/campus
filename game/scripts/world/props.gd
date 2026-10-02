class_name Props
extends RefCounted
## Low-poly furniture and objects for the interior stages. Every builder returns the created node,
## already parented, at local position p with yaw rot_y. Sizes are in metres (character ~1.9 m).

const WOOD := Color("b07a4f")
const WOOD_DARK := Color("7a5236")
const METAL := Color("9aa3ad")
const WHITE := Color("f7f4ee")
const INK := Color("2a2238")


static func node(parent: Node3D, p: Vector3, rot_y: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = rot_y
	parent.add_child(n)
	return n


## Cutaway room: floor + back wall (-z) + left wall (-x), open towards the camera.
static func room(parent: Node3D, w: float, d: float, wall: Color, floor_kind: String, floor_c: Color, h: float = 3.2) -> void:
	var fm: Material = Mat.pattern(floor_kind, floor_c) if floor_kind != "" else Mat.matte(floor_c)
	Mat.add(parent, Mat.box(Vector3(w, 0.12, d)), fm, Vector3(0, -0.06, 0), Vector3.ZERO, Vector3.ONE, false)
	Mat.add(parent, Mat.box(Vector3(w + 0.6, 0.5, d + 0.6)), Mat.matte(floor_c.darkened(0.45)), Vector3(0, -0.37, 0), Vector3.ZERO, Vector3.ONE, false)
	var wm := Mat.matte(wall)
	Mat.add(parent, Mat.box(Vector3(w, h, 0.18)), wm, Vector3(0, h * 0.5, -d * 0.5 - 0.09))
	Mat.add(parent, Mat.box(Vector3(0.18, h, d)), wm, Vector3(-w * 0.5 - 0.09, h * 0.5, 0))
	# Skirting boards.
	var sk := Mat.matte(wall.darkened(0.25))
	Mat.add(parent, Mat.box(Vector3(w, 0.14, 0.04)), sk, Vector3(0, 0.07, -d * 0.5 + 0.02), Vector3.ZERO, Vector3.ONE, false)
	Mat.add(parent, Mat.box(Vector3(0.04, 0.14, d)), sk, Vector3(-w * 0.5 + 0.02, 0.07, 0), Vector3.ZERO, Vector3.ONE, false)


static func desk(parent: Node3D, p: Vector3, rot_y: float = 0.0, size: Vector3 = Vector3(1.3, 0.75, 0.7), c: Color = WOOD) -> Node3D:
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.box(Vector3(size.x, 0.06, size.z)), Mat.vinyl(c, 0.5), Vector3(0, size.y, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Mat.add(n, Mat.box(Vector3(0.06, size.y, 0.06)), Mat.vinyl(c.darkened(0.3)), Vector3(sx * (size.x * 0.5 - 0.06), size.y * 0.5, sz * (size.z * 0.5 - 0.06)))
	return n


## Seat top at 0.45 m. Faces +z of its local frame (the sitter looks along +z).
static func chair(parent: Node3D, p: Vector3, rot_y: float = 0.0, c: Color = Color("3d5a80")) -> Node3D:
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.box(Vector3(0.5, 0.06, 0.48)), Mat.vinyl(c, 0.4), Vector3(0, 0.42, 0))
	Mat.add(n, Mat.box(Vector3(0.5, 0.55, 0.06)), Mat.vinyl(c, 0.4), Vector3(0, 0.72, -0.24))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Mat.add(n, Mat.cyl(0.025, 0.025, 0.42, 6), Mat.vinyl(METAL, 0.3), Vector3(sx * 0.21, 0.21, sz * 0.2))
	return n


## Classic Indonesian lecture chair with a writing tablet arm.
static func lecture_chair(parent: Node3D, p: Vector3, rot_y: float = 0.0) -> Node3D:
	var n := chair(parent, p, rot_y, Color("c8423b"))
	Mat.add(n, Mat.box(Vector3(0.32, 0.04, 0.5)), Mat.vinyl(Color("e9d8a6"), 0.5), Vector3(0.3, 0.68, 0.12))
	Mat.add(n, Mat.box(Vector3(0.04, 0.26, 0.04)), Mat.vinyl(METAL, 0.3), Vector3(0.42, 0.55, -0.05))
	return n


static func laptop(parent: Node3D, p: Vector3, rot_y: float = 0.0, screen: Color = Color("8fd0f2")) -> Node3D:
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.box(Vector3(0.42, 0.025, 0.3)), Mat.vinyl(Color("c0c4cc"), 0.25), Vector3(0, 0.012, 0))
	var lid := node(n, Vector3(0, 0.02, -0.15))
	lid.rotation.x = deg_to_rad(-12)
	Mat.add(lid, Mat.box(Vector3(0.42, 0.28, 0.02)), Mat.vinyl(Color("c0c4cc"), 0.25), Vector3(0, 0.14, 0))
	Mat.add(lid, Mat.box(Vector3(0.38, 0.24, 0.005)), Mat.unlit(screen), Vector3(0, 0.14, 0.012))
	return n


static func book(parent: Node3D, p: Vector3, c: Color, rot_y: float = 0.0, open_book: bool = false) -> Node3D:
	var n := node(parent, p, rot_y)
	if open_book:
		Mat.add(n, Mat.box(Vector3(0.36, 0.03, 0.26)), Mat.vinyl(WHITE), Vector3(0, 0.015, 0))
		Mat.add(n, Mat.box(Vector3(0.38, 0.015, 0.28)), Mat.vinyl(c), Vector3(0, 0.0, 0))
	else:
		Mat.add(n, Mat.box(Vector3(0.24, 0.05, 0.32)), Mat.vinyl(c), Vector3(0, 0.025, 0))
		Mat.add(n, Mat.box(Vector3(0.22, 0.04, 0.3)), Mat.vinyl(WHITE), Vector3(0.012, 0.025, 0))
	return n


static func paper_stack(parent: Node3D, p: Vector3, h: float = 0.3) -> Node3D:
	var n := node(parent, p, randf_range(-0.2, 0.2))
	var y := 0.0
	while y < h:
		var t := randf_range(0.02, 0.05)
		Mat.add(n, Mat.box(Vector3(0.3, t, 0.4)), Mat.matte(Color("f3f0e6") if randf() < 0.7 else Color("fff3b0")), Vector3(randf_range(-0.02, 0.02), y + t * 0.5, randf_range(-0.02, 0.02)), Vector3(0, randf_range(-0.15, 0.15), 0), Vector3.ONE, false)
		y += t
	return n


static func mug(parent: Node3D, p: Vector3, c: Color = Color("ff6b9a")) -> Node3D:
	var n := node(parent, p)
	Mat.add(n, Mat.cyl(0.06, 0.055, 0.12, 12), Mat.vinyl(c), Vector3(0, 0.06, 0))
	Mat.add(n, Mat.cyl(0.05, 0.05, 0.01, 12), Mat.vinyl(Color("4a2f22")), Vector3(0, 0.115, 0))
	return n


static func lamp(parent: Node3D, p: Vector3, c: Color = Color("ffc83d")) -> Node3D:
	var n := node(parent, p)
	Mat.add(n, Mat.cyl(0.1, 0.12, 0.04, 12), Mat.vinyl(INK), Vector3(0, 0.02, 0))
	Mat.add(n, Mat.cyl(0.015, 0.015, 0.4, 6), Mat.vinyl(INK), Vector3(0, 0.22, 0))
	Mat.add(n, Mat.cyl(0.06, 0.14, 0.14, 12), Mat.vinyl(c), Vector3(0.0, 0.44, 0.04), Vector3(0.4, 0, 0))
	return n


static func bed(parent: Node3D, p: Vector3, rot_y: float = 0.0, sheet: Color = Color("8fb7ff")) -> Node3D:
	## Long axis along local z; pillow at -z. Mattress top ~0.53 m.
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.box(Vector3(1.15, 0.3, 2.1)), Mat.vinyl(WOOD), Vector3(0, 0.15, 0))
	Mat.add(n, Mat.box(Vector3(1.05, 0.22, 2.0)), Mat.vinyl(WHITE, 0.6), Vector3(0, 0.41, 0))
	Mat.add(n, Mat.box(Vector3(1.08, 0.08, 1.3)), Mat.vinyl(sheet, 0.6), Vector3(0, 0.55, 0.33))
	Mat.add(n, Mat.capsule(0.13, 0.75), Mat.vinyl(Color("fff3e0"), 0.6), Vector3(0, 0.6, -0.8), Vector3(0, 0, PI * 0.5), Vector3(1, 1, 1.4))
	Mat.add(n, Mat.box(Vector3(1.15, 0.7, 0.08)), Mat.vinyl(WOOD_DARK), Vector3(0, 0.35, -1.05))
	return n


## Standing fan; its blades spin forever.
static func fan(parent: Node3D, p: Vector3, rot_y: float = 0.0) -> Node3D:
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.cyl(0.18, 0.2, 0.05, 16), Mat.vinyl(WHITE), Vector3(0, 0.025, 0))
	Mat.add(n, Mat.cyl(0.03, 0.03, 1.0, 8), Mat.vinyl(WHITE), Vector3(0, 0.5, 0))
	Mat.add(n, Mat.sphere(0.09, 10), Mat.vinyl(WHITE), Vector3(0, 1.05, -0.06))
	var cage := TorusMesh.new()
	cage.inner_radius = 0.3
	cage.outer_radius = 0.33
	Mat.add(n, cage, Mat.vinyl(Color("7fc8f8"), 0.3), Vector3(0, 1.05, 0.05), Vector3(PI * 0.5, 0, 0))
	var blades := node(n, Vector3(0, 1.05, 0.05))
	for i in 3:
		var a := TAU * i / 3.0
		Mat.add(blades, Mat.box(Vector3(0.1, 0.26, 0.015)), Mat.vinyl(Color("7fc8f8"), 0.3), Vector3(sin(a) * 0.13, cos(a) * 0.13, 0), Vector3(0, 0, -a))
	var tw := blades.create_tween().set_loops()
	tw.tween_property(blades, "rotation:z", -TAU, 0.35).from(0.0)
	var sway := n.create_tween().set_loops()
	sway.tween_property(n, "rotation:y", rot_y + 0.6, 2.5).set_trans(Tween.TRANS_SINE)
	sway.tween_property(n, "rotation:y", rot_y - 0.6, 2.5).set_trans(Tween.TRANS_SINE)
	return n


static func bookshelf(parent: Node3D, p: Vector3, rot_y: float = 0.0, w: float = 1.6, h: float = 2.1) -> Node3D:
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.box(Vector3(w, h, 0.36)), Mat.vinyl(WOOD_DARK, 0.6), Vector3(0, h * 0.5, 0))
	var colors := [Color("c8423b"), Color("2f6bff"), Color("2fbf71"), Color("ffc83d"), Color("7b5cff"), Color("ff9f1c"), Color("f4f1ea")]
	var shelves := int(h / 0.45)
	for s in shelves:
		var y := 0.12 + s * 0.45
		Mat.add(n, Mat.box(Vector3(w - 0.08, 0.03, 0.3)), Mat.vinyl(WOOD, 0.6), Vector3(0, y, 0.04), Vector3.ZERO, Vector3.ONE, false)
		var x := -w * 0.5 + 0.1
		while x < w * 0.5 - 0.12:
			var bw := randf_range(0.05, 0.1)
			var bh := randf_range(0.25, 0.36)
			Mat.add(n, Mat.box(Vector3(bw, bh, 0.24)), Mat.vinyl(colors[randi() % colors.size()], 0.5), Vector3(x + bw * 0.5, y + bh * 0.5 + 0.015, 0.06), Vector3(0, 0, randf_range(-0.05, 0.05)), Vector3.ONE, false)
			x += bw + 0.01
	return n


static func whiteboard(parent: Node3D, p: Vector3, w: float = 3.0, h: float = 1.3, text: String = "") -> Node3D:
	var n := node(parent, p)
	Mat.add(n, Mat.box(Vector3(w + 0.1, h + 0.1, 0.05)), Mat.vinyl(METAL, 0.3), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	Mat.add(n, Mat.box(Vector3(w, h, 0.06)), Mat.vinyl(Color.WHITE, 0.2), Vector3(0, 0, 0.01), Vector3.ZERO, Vector3.ONE, false)
	for i in 4:
		var lw := randf_range(w * 0.3, w * 0.75)
		Mat.add(n, Mat.box(Vector3(lw, 0.04, 0.01)), Mat.unlit(Color("2f6bff") if i == 0 else Color("2a2238")), Vector3(-w * 0.5 + 0.2 + lw * 0.5, h * 0.3 - i * 0.22, 0.045), Vector3.ZERO, Vector3.ONE, false)
	if text != "":
		label(n, text, Vector3(0, h * 0.5 - 0.18, 0.05), 40, Color("c8423b"))
	return n


static func label(parent: Node3D, text: String, p: Vector3, size: int = 48, c: Color = Color.WHITE, rot_y: float = 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = load("res://assets/fonts/Fredoka.ttf")
	l.font_size = size
	l.pixel_size = 0.005
	l.modulate = c
	l.position = p
	l.rotation.y = rot_y
	parent.add_child(l)
	return l


static func window(parent: Node3D, p: Vector3, rot_y: float = 0.0, w: float = 1.4, h: float = 1.2, night: bool = false) -> Node3D:
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.box(Vector3(w + 0.12, h + 0.12, 0.08)), Mat.vinyl(WHITE), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	Mat.add(n, Mat.box(Vector3(w, h, 0.09)), Mat.unlit(Color("1c2348") if night else Color("bfe6fb")), Vector3(0, 0, 0.005), Vector3.ZERO, Vector3.ONE, false)
	Mat.add(n, Mat.box(Vector3(0.05, h, 0.1)), Mat.vinyl(WHITE), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	Mat.add(n, Mat.box(Vector3(w, 0.05, 0.1)), Mat.vinyl(WHITE), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	return n


static func frame(parent: Node3D, p: Vector3, size: Vector2, c: Color, rot_y: float = 0.0) -> Node3D:
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.box(Vector3(size.x + 0.08, size.y + 0.08, 0.04)), Mat.vinyl(WOOD_DARK), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
	Mat.add(n, Mat.box(Vector3(size.x, size.y, 0.05)), Mat.matte(c), Vector3(0, 0, 0.005), Vector3.ZERO, Vector3.ONE, false)
	return n


static func clock(parent: Node3D, p: Vector3, rot_y: float = 0.0) -> Node3D:
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.cyl(0.22, 0.22, 0.05, 20), Mat.vinyl(Color.WHITE), Vector3.ZERO, Vector3(PI * 0.5, 0, 0), Vector3.ONE, false)
	Mat.add(n, Mat.box(Vector3(0.03, 0.15, 0.02)), Mat.unlit(INK), Vector3(0, 0.06, 0.03), Vector3.ZERO, Vector3.ONE, false)
	Mat.add(n, Mat.box(Vector3(0.12, 0.03, 0.02)), Mat.unlit(INK), Vector3(0.05, 0, 0.03), Vector3.ZERO, Vector3.ONE, false)
	return n


static func plant(parent: Node3D, p: Vector3, s: float = 1.0) -> Node3D:
	var n := node(parent, p)
	Mat.add(n, Mat.cyl(0.18 * s, 0.14 * s, 0.3 * s, 12), Mat.vinyl(Color("d0573a")), Vector3(0, 0.15 * s, 0))
	for i in 5:
		var a := TAU * i / 5.0
		Mat.add(n, Mat.sphere(0.2 * s, 10), Mat.vinyl(Color("45a34a"), 0.6), Vector3(cos(a) * 0.12 * s, 0.45 * s + (i % 2) * 0.12 * s, sin(a) * 0.12 * s), Vector3.ZERO, Vector3(0.8, 1.4, 0.8))
	return n


static func armchair(parent: Node3D, p: Vector3, rot_y: float, c: Color) -> Node3D:
	var n := node(parent, p, rot_y)
	Mat.add(n, Mat.box(Vector3(0.85, 0.42, 0.8)), Mat.vinyl(c, 0.7), Vector3(0, 0.21, 0))
	Mat.add(n, Mat.box(Vector3(0.85, 0.75, 0.18)), Mat.vinyl(c.darkened(0.08), 0.7), Vector3(0, 0.55, -0.34))
	for sx in [-1.0, 1.0]:
		Mat.add(n, Mat.box(Vector3(0.14, 0.55, 0.8)), Mat.vinyl(c.darkened(0.08), 0.7), Vector3(sx * 0.42, 0.33, 0))
	return n


static func counter(parent: Node3D, p: Vector3, w: float, c: Color) -> Node3D:
	var n := node(parent, p)
	Mat.add(n, Mat.box(Vector3(w, 1.0, 0.6)), Mat.vinyl(c, 0.5), Vector3(0, 0.5, 0))
	Mat.add(n, Mat.box(Vector3(w + 0.1, 0.06, 0.7)), Mat.vinyl(Color("f2e2c4"), 0.4), Vector3(0, 1.03, 0))
	return n


static func motor(parent: Node3D, p: Vector3, rot_y: float, color: Color) -> Node3D:
	var n := node(parent, p, rot_y)
	var tire := Mat.vinyl(Color("1a1a1a"), 0.7)
	for z in [-0.55, 0.55]:
		Mat.add(n, Mat.cyl(0.24, 0.24, 0.12, 16), tire, Vector3(0, 0.24, z), Vector3(0, 0, deg_to_rad(90)))
	var body := Mat.vinyl(color, 0.3)
	Mat.add(n, Mat.capsule(0.22, 1.1), body, Vector3(0, 0.48, -0.1), Vector3(deg_to_rad(90), 0, 0), Vector3(0.9, 1, 0.7))
	Mat.add(n, Mat.box(Vector3(0.32, 0.1, 0.7)), Mat.vinyl(Color("222222")), Vector3(0, 0.66, -0.25))
	Mat.add(n, Mat.box(Vector3(0.18, 0.7, 0.16)), body, Vector3(0, 0.75, 0.45), Vector3(deg_to_rad(-15), 0, 0))
	Mat.add(n, Mat.cyl(0.03, 0.03, 0.62, 6), Mat.vinyl(Color("c0c0c0")), Vector3(0, 1.1, 0.52), Vector3(0, 0, deg_to_rad(90)))
	Mat.add(n, Mat.sphere(0.07, 8), Mat.unlit(Color("fff7c2")), Vector3(0, 0.95, 0.56))
	return n


static func room_light(parent: Node3D, p: Vector3, energy: float = 1.2, rng: float = 7.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = p
	l.light_color = Color("ffe2b8")
	l.light_energy = energy
	l.omni_range = rng
	parent.add_child(l)
	return l

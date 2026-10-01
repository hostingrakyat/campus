class_name VinylChar
extends Node3D
## Procedural low-poly "vinyl toy" character: big glossy head, dot eyes, no mouth.

const D := preload("res://scripts/autoload/data.gd")

signal arrived

var look: Dictionary = {}
var prodi := "IF"
var walking := false
var speed := 3.2

var _body: Node3D
var _head: Node3D
var _parts: Node3D
var _t := randf() * 10.0
var _path: Array = []
var _bubble: Label3D


func _ready() -> void:
	if _parts == null:
		build(D.DEFAULT_LOOK, prodi)


func build(new_look: Dictionary, new_prodi: String = "IF") -> void:
	look = new_look.duplicate()
	prodi = new_prodi
	if _parts:
		_parts.queue_free()
	_parts = Node3D.new()
	_parts.name = "Parts"
	add_child(_parts)
	_body = Node3D.new()
	_parts.add_child(_body)

	var skin: Color = D.SKIN_TONES[clampi(int(look.get("skin", 1)), 0, D.SKIN_TONES.size() - 1)]
	var hair_c: Color = D.HAIR_COLORS[clampi(int(look.get("hair_color", 0)), 0, D.HAIR_COLORS.size() - 1)]
	var top_id: String = look.get("top", "top_tee")
	var top_def: Dictionary = D.ITEMS.get(top_id, {})
	var top_c: Color = Data.item_color(top_id, prodi) if is_inside_tree() else top_def.get("color", Color.WHITE)
	if top_def.get("almamater", false):
		top_c = D.PRODI[prodi].color
	var top_mat: Material = Mat.pattern(top_def.pattern, top_c) if top_def.has("pattern") else Mat.vinyl(top_c)
	var skin_mat := Mat.vinyl(skin, 0.38)
	var pants := Mat.vinyl(Color("2b3a55"), 0.5)
	var shoe := Mat.vinyl(Color("f4f1ea"), 0.4)

	# Legs & shoes.
	for sx in [-1.0, 1.0]:
		Mat.add(_body, Mat.capsule(0.11, 0.38), pants, Vector3(0.13 * sx, 0.22, 0))
		Mat.add(_body, Mat.sphere(0.12, 16), shoe, Vector3(0.13 * sx, 0.06, 0.05), Vector3.ZERO, Vector3(1.0, 0.55, 1.45))
	# Torso.
	Mat.add(_body, Mat.capsule(0.31, 0.88), top_mat, Vector3(0, 0.66, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.86))
	if top_def.get("almamater", false) or top_id == "top_varsity" or top_id == "top_snelli":
		Mat.add(_body, Mat.box(Vector3(0.16, 0.46, 0.06)), Mat.vinyl(Color("f7f4ee")), Vector3(0, 0.72, 0.255))
	if top_id == "top_snelli":
		Mat.add(_body, Mat.cyl(0.31, 0.35, 0.34), top_mat, Vector3(0, 0.33, 0))
	if top_def.get("hood", false):
		var hood := TorusMesh.new()
		hood.inner_radius = 0.12
		hood.outer_radius = 0.3
		Mat.add(_body, hood, Mat.vinyl(top_c.darkened(0.08)), Vector3(0, 1.0, -0.12), Vector3(deg_to_rad(70), 0, 0))
	# Arms.
	var sleeve: Material = Mat.vinyl(Color("f7f4ee")) if top_id == "top_varsity" else top_mat
	for sx in [-1.0, 1.0]:
		Mat.add(_body, Mat.capsule(0.085, 0.5), sleeve, Vector3(0.37 * sx, 0.7, 0), Vector3(0, 0, 0.2 * sx))
		Mat.add(_body, Mat.sphere(0.09, 14), skin_mat, Vector3(0.42 * sx, 0.45, 0.01))
	# Back item.
	match look.get("back", "back_none"):
		"back_ransel":
			Mat.add(_body, Mat.capsule(0.22, 0.6), Mat.vinyl(D.ITEMS.back_ransel.color), Vector3(0, 0.72, -0.3), Vector3.ZERO, Vector3(1, 1, 0.55))
		"back_tote":
			Mat.add(_body, Mat.box(Vector3(0.08, 0.36, 0.32)), Mat.matte(D.ITEMS.back_tote.color), Vector3(-0.45, 0.42, 0))

	# Head.
	_head = Node3D.new()
	_head.position = Vector3(0, 1.38, 0)
	_body.add_child(_head)
	var hair: String = look.get("hair", "hair_short")
	Mat.add(_head, Mat.sphere(0.5, 36), skin_mat, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.94, 0.96))
	if hair != "hair_hijab":
		for sx in [-1.0, 1.0]:
			Mat.add(_head, Mat.sphere(0.09, 12), skin_mat, Vector3(0.49 * sx, -0.03, 0))
	# Eyes: glossy dots with highlights. No mouth, by design.
	var eye_mat := Mat.vinyl(Color("1a1420"), 0.15)
	var hl := Mat.unlit(Color.WHITE)
	for sx in [-1.0, 1.0]:
		Mat.add(_head, Mat.sphere(0.075, 16), eye_mat, Vector3(0.17 * sx, -0.03, 0.44), Vector3.ZERO, Vector3(0.85, 1.15, 0.45), false)
		Mat.add(_head, Mat.sphere(0.024, 8), hl, Vector3(0.17 * sx + 0.022, 0.01, 0.468), Vector3.ZERO, Vector3.ONE, false)
		Mat.add(_head, Mat.cyl(0.065, 0.065, 0.01, 16), Mat.unlit(Color(1.0, 0.55, 0.6, 0.55)), Vector3(0.29 * sx, -0.14, 0.375), Vector3(deg_to_rad(90), 0, -0.62 * sx), Vector3.ONE, false)
	_build_hair(hair, hair_c)
	_build_head_item(look.get("head", "head_none"))
	_build_face_item(look.get("face", "face_none"))
	if look.get("aura", "aura_none") == "aura_sigma":
		_build_aura()


func _build_hair(hair: String, c: Color) -> void:
	var m := Mat.vinyl(c, 0.5)
	var cap := Mat.hemi(0.535, 32)
	match hair:
		"hair_short":
			Mat.add(_head, cap, m, Vector3(0, 0.04, -0.02), Vector3(-0.42, 0, 0), Vector3(1, 1.12, 1))
			_hair_back(m)
		"hair_fringe":
			Mat.add(_head, cap, m, Vector3(0, 0.02, -0.02), Vector3(-0.3, 0, 0))
			_hair_back(m)
			Mat.add(_head, Mat.sphere(0.3, 20), m, Vector3(0.0, 0.24, 0.3), Vector3(0.5, 0, 0), Vector3(1.45, 0.45, 0.6))
		"hair_long":
			Mat.add(_head, cap, m, Vector3(0, 0.02, -0.02), Vector3(-0.3, 0, 0))
			_hair_back(m)
			Mat.add(_head, Mat.capsule(0.44, 1.15), m, Vector3(0, -0.28, -0.2), Vector3.ZERO, Vector3(1.0, 1.0, 0.5))
			Mat.add(_head, Mat.sphere(0.28, 18), m, Vector3(-0.12, 0.25, 0.3), Vector3(0.5, 0, 0.3), Vector3(1.3, 0.42, 0.6))
		"hair_buzz":
			var thin := Mat.hemi(0.512, 28)
			Mat.add(_head, thin, m, Vector3(0, 0.0, -0.01), Vector3(-0.22, 0, 0))
		"hair_curly":
			Mat.add(_head, cap, m, Vector3(0, 0.0, -0.03), Vector3(-0.4, 0, 0))
			for i in 11:
				var a := TAU * i / 11.0
				var p := Vector3(cos(a) * 0.4, 0.3 + sin(a * 2.0) * 0.06, sin(a) * 0.36 - 0.05)
				if p.z > 0.25:
					p.y += 0.12
				Mat.add(_head, Mat.sphere(0.2, 12), m, p)
		"hair_hijab":
			var hij := Mat.vinyl(c.lightened(0.15) if c.v < 0.3 else c, 0.55)
			Mat.add(_head, Mat.sphere(0.565, 32), hij, Vector3(0, 0.04, -0.13), Vector3.ZERO, Vector3(1.0, 1.02, 0.82))
			Mat.add(_head, Mat.cyl(0.36, 0.58, 0.46, 24), hij, Vector3(0, -0.46, -0.02))
			var band := TorusMesh.new()
			band.inner_radius = 0.4
			band.outer_radius = 0.48
			Mat.add(_head, band, hij, Vector3(0, 0.0, 0.1), Vector3(deg_to_rad(84), 0, 0), Vector3(1.04, 1.0, 1.1))


## Covers the back and sides of the head so short styles read as hair, not a cap.
func _hair_back(m: Material) -> void:
	Mat.add(_head, Mat.sphere(0.5, 28), m, Vector3(0, 0.04, -0.1), Vector3.ZERO, Vector3(1.06, 0.98, 0.9))


func _build_head_item(id: String) -> void:
	if id == "head_none" or not D.ITEMS.has(id):
		return
	var c: Color = D.ITEMS[id].get("color", Color.WHITE)
	var m := Mat.vinyl(c, 0.5)
	match id:
		"head_bucket":
			Mat.add(_head, Mat.cyl(0.4, 0.5, 0.3, 24), m, Vector3(0, 0.42, -0.02))
			Mat.add(_head, Mat.cyl(0.66, 0.66, 0.03, 28), m, Vector3(0, 0.29, 0))
		"head_cap":
			var cap := Mat.hemi(0.55, 28)
			Mat.add(_head, cap, m, Vector3(0, 0.08, -0.02), Vector3(-0.15, 0, 0))
			Mat.add(_head, Mat.box(Vector3(0.5, 0.03, 0.34)), m, Vector3(0, 0.16, 0.6))
		"head_peci":
			Mat.add(_head, Mat.cyl(0.4, 0.43, 0.24, 24), m, Vector3(0, 0.42, -0.04), Vector3(-0.18, 0, 0))
		"head_toga":
			Mat.add(_head, Mat.cyl(0.42, 0.45, 0.2, 24), m, Vector3(0, 0.44, -0.03))
			Mat.add(_head, Mat.box(Vector3(0.95, 0.04, 0.95)), m, Vector3(0, 0.55, -0.03), Vector3(0, 0.785, 0))
			Mat.add(_head, Mat.capsule(0.025, 0.3), Mat.vinyl(Color("ffc83d")), Vector3(0.32, 0.42, 0.32))


func _build_face_item(id: String) -> void:
	match id:
		"face_round":
			var ring := TorusMesh.new()
			ring.inner_radius = 0.1
			ring.outer_radius = 0.125
			var m := Mat.vinyl(Color("3a2a1a"), 0.3)
			for sx in [-1.0, 1.0]:
				Mat.add(_head, ring, m, Vector3(0.17 * sx, -0.03, 0.5), Vector3(deg_to_rad(90), 0, 0), Vector3.ONE, false)
			Mat.add(_head, Mat.box(Vector3(0.1, 0.02, 0.02)), m, Vector3(0, -0.01, 0.52), Vector3.ZERO, Vector3.ONE, false)
		"face_shades":
			var m := Mat.vinyl(Color("0f0c14"), 0.08)
			for sx in [-1.0, 1.0]:
				Mat.add(_head, Mat.box(Vector3(0.24, 0.13, 0.04)), m, Vector3(0.16 * sx, -0.02, 0.5), Vector3(0, 0.18 * sx, 0), Vector3.ONE, false)
			Mat.add(_head, Mat.box(Vector3(0.12, 0.03, 0.03)), m, Vector3(0, 0.02, 0.52), Vector3.ZERO, Vector3.ONE, false)


func _build_aura() -> void:
	var p := CPUParticles3D.new()
	p.amount = 18
	p.lifetime = 1.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_radius = 0.55
	p.emission_ring_inner_radius = 0.4
	p.emission_ring_height = 0.05
	p.emission_ring_axis = Vector3.UP
	p.direction = Vector3.UP
	p.spread = 10.0
	p.gravity = Vector3(0, 0.6, 0)
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.8
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var qm := Mat.unlit(Color("ffd84d"))
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = qm
	p.mesh = q
	_parts.add_child(p)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.5
	ring.outer_radius = 0.58
	Mat.add(_parts, ring, Mat.unlit(Color(1.0, 0.85, 0.3, 0.6)), Vector3(0, 0.03, 0), Vector3.ZERO, Vector3(1, 0.2, 1), false)


# --- Behaviour ---------------------------------------------------------------

func walk_to(target: Vector3) -> void:
	_path = [target]
	walking = true


func walk_path(points: Array) -> void:
	_path = points.duplicate()
	walking = not _path.is_empty()


func teleport(p: Vector3) -> void:
	position = p
	_path = []
	walking = false


func face(dir: Vector3) -> void:
	dir.y = 0
	if dir.length() > 0.01:
		rotation.y = atan2(dir.x, dir.z)


func say(text: String, dur: float = 2.5) -> void:
	if _bubble == null:
		_bubble = Label3D.new()
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.position = Vector3(0, 2.25, 0)
		_bubble.font_size = 56
		_bubble.pixel_size = 0.006
		_bubble.outline_size = 14
		_bubble.modulate = Color("2a2238")
		_bubble.outline_modulate = Color.WHITE
		_bubble.no_depth_test = true
		_bubble.fixed_size = false
		add_child(_bubble)
	_bubble.text = text
	_bubble.visible = true
	_bubble.position.y = 2.25
	var tw := create_tween()
	tw.tween_property(_bubble, "position:y", 2.6, dur)
	tw.tween_callback(func(): _bubble.visible = false)


func _process(delta: float) -> void:
	_t += delta
	if _body == null:
		return
	if walking and not _path.is_empty():
		var target: Vector3 = _path[0]
		var to := target - position
		to.y = 0
		var dist := to.length()
		if dist < 0.06:
			position = Vector3(target.x, position.y, target.z)
			_path.pop_front()
			if _path.is_empty():
				walking = false
				arrived.emit()
		else:
			var step := minf(dist, speed * delta)
			position += to / dist * step
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), minf(1.0, delta * 12.0))
		_body.position.y = absf(sin(_t * 11.0)) * 0.09
		_body.rotation.z = sin(_t * 11.0) * 0.07
		_head.rotation.x = 0.06
	else:
		_body.position.y = sin(_t * 2.2) * 0.018
		_body.rotation.z = lerpf(_body.rotation.z, 0.0, minf(1.0, delta * 8.0))
		_head.rotation.z = sin(_t * 1.3) * 0.05
		_head.rotation.x = 0.0

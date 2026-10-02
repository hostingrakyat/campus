class_name VinylChar
extends Node3D
## Procedural low-poly "vinyl toy" character: big glossy head, dot eyes, no mouth.

const D := preload("res://scripts/autoload/data.gd")

signal arrived

var look: Dictionary = {}
var prodi := "IF"
var walking := false
var speed := 3.2
var footsteps := false
var _step_i := 0

## Pose: stand | sit | lie | ride. Anim: idle | talk | listen | write | type | read | laugh | sleep |
## cheer | sad | phone | wave | point | ride | run | nervous.
var pose := "stand"
var anim := "idle"

var _body: Node3D
var _head: Node3D
var _parts: Node3D
var _hip_l: Node3D
var _hip_r: Node3D
var _sh_l: Node3D
var _sh_r: Node3D
var _hand_r: Node3D
var _held: Node3D
var _t := randf() * 10.0
var _path: Array = []
var _bubble: Label3D
var _emote: Label3D
var _pose_y := 0.0
var _steer := Vector3.ZERO
var _steer_amt := 0.0


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

	# Legs & shoes on hip pivots so they can swing, sit and ride.
	for sx in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(0.13 * sx, 0.42, 0)
		_body.add_child(hip)
		Mat.add(hip, Mat.capsule(0.11, 0.42), pants, Vector3(0, -0.19, 0))
		Mat.add(hip, Mat.sphere(0.12, 16), shoe, Vector3(0, -0.36, 0.05), Vector3.ZERO, Vector3(1.0, 0.55, 1.45))
		if sx < 0:
			_hip_l = hip
		else:
			_hip_r = hip
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
		var sh := Node3D.new()
		sh.position = Vector3(0.33 * sx, 0.96, 0)
		sh.rotation.z = 0.2 * sx
		_body.add_child(sh)
		Mat.add(sh, Mat.capsule(0.085, 0.5), sleeve, Vector3(0, -0.24, 0))
		Mat.add(sh, Mat.sphere(0.09, 14), skin_mat, Vector3(0, -0.5, 0.01))
		if sx < 0:
			_sh_l = sh
		else:
			_sh_r = sh
			_hand_r = Node3D.new()
			_hand_r.position = Vector3(0, -0.52, 0.05)
			sh.add_child(_hand_r)
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
	_held = null
	set_pose(pose)


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
		"head_helm":
			Mat.add(_head, Mat.hemi(0.6, 28), m, Vector3(0, 0.02, -0.04), Vector3(-0.25, 0, 0))
			Mat.add(_head, Mat.box(Vector3(0.7, 0.05, 0.2)), Mat.vinyl(Color(0.2, 0.25, 0.3, 1.0), 0.1), Vector3(0, 0.12, 0.5), Vector3(-0.4, 0, 0))
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
	set_pose("stand")
	_path = [target]
	walking = true


func walk_path(points: Array) -> void:
	set_pose("stand")
	_path = points.duplicate()
	walking = not _path.is_empty()


## Free movement driven from outside (joystick): position is moved by the caller, this only
## turns the character and plays the walk/run cycle. amount 0 stops.
func steer(dir: Vector3, amount: float) -> void:
	dir.y = 0
	_steer = dir.normalized() if dir.length() > 0.001 else Vector3.ZERO
	_steer_amt = amount if _steer != Vector3.ZERO else 0.0
	if _steer_amt > 0.0 and pose != "stand":
		set_pose("stand")


func teleport(p: Vector3) -> void:
	position = p
	_path = []
	walking = false


func face(dir: Vector3) -> void:
	dir.y = 0
	if dir.length() > 0.01:
		rotation.y = atan2(dir.x, dir.z)


func face_point(p: Vector3) -> void:
	face(p - position)


## stand | sit (on a ~0.45 m seat) | lie (on a ~0.5 m bed, head towards -z) | ride (motorbike seat)
func set_pose(p: String) -> void:
	pose = p
	if _parts == null:
		return
	_parts.rotation = Vector3.ZERO
	match p:
		"sit", "ride":
			_pose_y = 0.1 if p == "sit" else 0.18
			for h in [_hip_l, _hip_r]:
				h.rotation.x = -PI * 0.5
		"lie":
			_pose_y = 0.78
			_parts.rotation.x = -PI * 0.5
			for h in [_hip_l, _hip_r]:
				h.rotation.x = 0.0
		_:
			_pose_y = 0.0
			for h in [_hip_l, _hip_r]:
				h.rotation.x = 0.0
	_parts.position.y = _pose_y


func play(a: String) -> void:
	anim = a
	if a == "sleep":
		emote("z z z", Color("7b5cff"), 999.0)
	elif _emote and _emote.text == "z z z":
		_emote.visible = false


## Hold a small prop in the right hand: phone | book | cup | "" (empty).
func hold(kind: String) -> void:
	if _held:
		_held.queue_free()
		_held = null
	if kind == "" or _hand_r == null:
		return
	_held = Node3D.new()
	_hand_r.add_child(_held)
	match kind:
		"phone":
			Mat.add(_held, Mat.box(Vector3(0.1, 0.19, 0.025)), Mat.vinyl(Color("1d1d26"), 0.15), Vector3(0, -0.04, 0.03))
			Mat.add(_held, Mat.box(Vector3(0.085, 0.16, 0.005)), Mat.unlit(Color("8fd0f2")), Vector3(0, -0.04, 0.045))
		"book":
			Mat.add(_held, Mat.box(Vector3(0.28, 0.04, 0.2)), Mat.vinyl(Color("c8423b")), Vector3(0, -0.04, 0.08))
		"cup":
			Mat.add(_held, Mat.cyl(0.06, 0.05, 0.12, 12), Mat.vinyl(Color("f4f1ea")), Vector3(0, -0.02, 0.06))


## Short symbol above the head ("!", "?", "...", "z z z", "<3"). dur <= 0 hides it.
func emote(text: String, color: Color = Color("ff5a4e"), dur: float = 1.6) -> void:
	if _emote == null:
		_emote = Label3D.new()
		_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_emote.font = load("res://assets/fonts/Fredoka.ttf")
		_emote.font_size = 96
		_emote.pixel_size = 0.006
		_emote.outline_size = 22
		_emote.outline_modulate = Color.WHITE
		_emote.no_depth_test = true
		add_child(_emote)
	if dur <= 0.0:
		_emote.visible = false
		return
	_emote.text = text
	_emote.modulate = color
	_emote.visible = true
	_emote.position = Vector3(0.35, 2.35 + _pose_y, 0)
	_emote.scale = Vector3.ONE * 0.3
	var tw := create_tween()
	tw.tween_property(_emote, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if dur < 900.0:
		tw.tween_interval(dur)
		tw.tween_callback(func():
			if _emote.text == text:
				_emote.visible = false)


func say(text: String, dur: float = 2.5) -> void:
	if _bubble == null:
		_bubble = Label3D.new()
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.font_size = 52
		_bubble.pixel_size = 0.006
		_bubble.outline_size = 14
		_bubble.modulate = Color("2a2238")
		_bubble.outline_modulate = Color.WHITE
		_bubble.no_depth_test = true
		_bubble.width = 520
		_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(_bubble)
	_bubble.text = text
	_bubble.visible = true
	_bubble.position.y = 2.25 + _pose_y
	var tw := create_tween()
	tw.tween_property(_bubble, "position:y", 2.55 + _pose_y, dur)
	tw.tween_callback(func(): _bubble.visible = false)


func _process(delta: float) -> void:
	_t += delta
	if _body == null:
		return
	var t := _t
	# Defaults (blended toward each frame).
	var arm_lx := 0.0
	var arm_rx := 0.0
	var arm_lz := -0.2
	var arm_rz := 0.2
	var head_x := 0.0
	var head_z := sin(t * 1.3) * 0.05
	var body_y := sin(t * 2.2) * 0.018
	var body_z := 0.0
	var leg_swing := 0.0
	var steering := _steer_amt > 0.05 and not walking
	if steering:
		rotation.y = lerp_angle(rotation.y, atan2(_steer.x, _steer.z), minf(1.0, delta * 14.0))
	if (walking and not _path.is_empty()) or steering:
		var target: Vector3 = _path[0] if not steering else position
		var to := target - position
		to.y = 0
		var dist := to.length()
		if steering:
			pass
		elif dist < 0.06:
			position = Vector3(target.x, position.y, target.z)
			_path.pop_front()
			if _path.is_empty():
				walking = false
				arrived.emit()
		else:
			var stp := minf(dist, speed * delta)
			position += to / dist * stp
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), minf(1.0, delta * 12.0))
		var f := 11.0 * clampf((speed if not steering else 3.2 + 2.4 * _steer_amt) / 3.2, 0.7, 1.6)
		body_y = absf(sin(t * f)) * 0.09
		body_z = sin(t * f) * 0.05
		leg_swing = sin(t * f) * 0.55
		arm_lx = -leg_swing * 0.8
		arm_rx = leg_swing * 0.8
		head_x = 0.06
		var step := int(t * f / PI)
		if footsteps and step != _step_i:
			_step_i = step
			Audio.play("step", -10.0, 1.0, 0.12)
	else:
		match anim:
			"talk":
				head_x = sin(t * 9.0) * 0.07
				arm_rx = -0.5 + sin(t * 5.0) * 0.35
				arm_rz = 0.35
			"listen":
				head_z = 0.14 + sin(t * 0.9) * 0.03
				head_x = sin(t * 1.6) * 0.06
			"write", "nervous":
				head_x = 0.28
				arm_rx = -0.95 + sin(t * 14.0) * 0.08
				arm_lx = -0.7
				if anim == "nervous":
					body_z = sin(t * 30.0) * 0.02
			"type":
				head_x = 0.18
				arm_rx = -1.05 + sin(t * 22.0) * 0.07
				arm_lx = -1.05 + sin(t * 22.0 + 1.7) * 0.07
			"read":
				head_x = 0.32
				arm_rx = -0.95
				arm_lx = -0.95
				arm_rz = 0.05
				arm_lz = -0.05
			"laugh":
				body_z = sin(t * 22.0) * 0.06
				head_x = -0.18
				body_y = absf(sin(t * 11.0)) * 0.04
				arm_rx = -0.4
				arm_lx = -0.4
			"sleep":
				body_y = sin(t * 1.4) * 0.02
				head_z = 0.0
			"cheer":
				arm_rz = 2.7 + sin(t * 12.0) * 0.12
				arm_lz = -2.7 - sin(t * 12.0) * 0.12
				body_y = absf(sin(t * 7.0)) * 0.16
			"sad":
				head_x = 0.38
				body_y = -0.03
				body_z = sin(t * 0.8) * 0.03
				arm_rz = 0.05
				arm_lz = -0.05
			"phone":
				arm_rz = 2.75
				arm_rx = -0.25
				head_z = 0.12
				head_x = sin(t * 3.0) * 0.04
			"wave":
				arm_rz = 2.6 + sin(t * 10.0) * 0.35
			"point":
				arm_rz = 1.45
				arm_rx = -0.25
				head_z = 0.1
			"ride":
				arm_rx = -1.15
				arm_lx = -1.15
				body_z = sin(t * 9.0) * 0.015
			"run":
				body_y = absf(sin(t * 14.0)) * 0.12
				leg_swing = sin(t * 14.0) * 0.8
				arm_lx = -leg_swing
				arm_rx = leg_swing
	var k := minf(1.0, delta * 12.0)
	_body.position.y = lerpf(_body.position.y, body_y, k)
	_body.rotation.z = lerpf(_body.rotation.z, body_z, k)
	_head.rotation.x = lerpf(_head.rotation.x, head_x, k)
	_head.rotation.z = lerpf(_head.rotation.z, head_z, k)
	_sh_l.rotation.x = lerpf(_sh_l.rotation.x, arm_lx, k)
	_sh_r.rotation.x = lerpf(_sh_r.rotation.x, arm_rx, k)
	_sh_l.rotation.z = lerpf(_sh_l.rotation.z, arm_lz, k)
	_sh_r.rotation.z = lerpf(_sh_r.rotation.z, arm_rz, k)
	if pose == "stand":
		_hip_l.rotation.x = lerpf(_hip_l.rotation.x, leg_swing, k)
		_hip_r.rotation.x = lerpf(_hip_r.rotation.x, -leg_swing, k)


## Little happy jump (outfit change, good news).
func hop() -> void:
	if _parts == null:
		return
	var tw := create_tween()
	tw.tween_property(_parts, "position:y", _pose_y + 0.45, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_parts, "position:y", _pose_y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var sq := create_tween()
	sq.tween_property(_parts, "scale", Vector3(1.12, 0.88, 1.12), 0.08)
	sq.tween_property(_parts, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Quick "no!" head shake for bad news.
func shake_head() -> void:
	if _head == null:
		return
	var tw := create_tween()
	for i in 3:
		tw.tween_property(_head, "rotation:y", 0.35, 0.07)
		tw.tween_property(_head, "rotation:y", -0.35, 0.07)
	tw.tween_property(_head, "rotation:y", 0.0, 0.07)

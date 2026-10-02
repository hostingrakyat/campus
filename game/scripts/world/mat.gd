class_name Mat
extends RefCounted
## Shared material factory: soft, slightly glossy "vinyl toy" look.

static var _cache: Dictionary = {}


static func vinyl(c: Color, rough: float = 0.42) -> StandardMaterial3D:
	var key := "v%s_%.2f" % [c.to_html(), rough]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic_specular = 0.65
	m.rim_enabled = true
	m.rim = 0.3
	m.rim_tint = 0.7
	_cache[key] = m
	return m


static func matte(c: Color) -> StandardMaterial3D:
	var key := "m%s" % c.to_html()
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	m.metallic_specular = 0.3
	_cache[key] = m
	return m


static func unlit(c: Color) -> StandardMaterial3D:
	var key := "u%s" % c.to_html()
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cache[key] = m
	return m


## Procedural fabric patterns (flannel checks, batik dots) so outfits need no texture files.
static func pattern(kind: String, base: Color) -> StandardMaterial3D:
	var key := "p%s%s" % [kind, base.to_html()]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	for y in 32:
		for x in 32:
			var c := base
			match kind:
				"flanel":
					var bx := (x / 4) % 2 == 0
					var by := (y / 4) % 2 == 0
					if bx and by:
						c = base.darkened(0.45)
					elif bx or by:
						c = base.darkened(0.2)
					if x % 8 == 0 or y % 8 == 0:
						c = c.lightened(0.35)
				"tiles":
					c = base if ((x / 16) + (y / 16)) % 2 == 0 else base.darkened(0.06)
					if x % 16 == 0 or y % 16 == 0:
						c = base.darkened(0.18)
				"wood":
					var plank := (y / 8) % 4
					c = base.darkened(0.05 * plank)
					if y % 8 == 0 or (x + plank * 9) % 32 == 0:
						c = base.darkened(0.3)
				"batik":
					var cx := (x % 8) - 4
					var cy := (y % 8) - 4
					var d := cx * cx + cy * cy
					if d < 4:
						c = Color("f2d48a")
					elif d < 9:
						c = base.darkened(0.35)
					if (x + y) % 16 == 0:
						c = Color("3b2416")
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(2.2, 2.2, 2.2)
	m.roughness = 0.6
	m.rim_enabled = true
	m.rim = 0.25
	_cache[key] = m
	return m


static func sphere(r: float, segs: int = 24) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = maxi(8, segs / 2)
	return m


static func hemi(r: float, segs: int = 24) -> SphereMesh:
	var m := sphere(r, segs)
	m.is_hemisphere = true
	m.height = r
	return m


static func capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 20
	m.rings = 6
	return m


static func cyl(top: float, bottom: float, h: float, segs: int = 20) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	return m


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func add(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

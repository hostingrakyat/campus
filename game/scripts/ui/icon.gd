class_name Icon
extends Control
## Vector icons drawn in code (coin, diamond, avatar bubble, slot glyphs) — no image assets needed.

var kind := "coin"
var color := Color.WHITE
var text := ""


static func make(k: String, size: int = 32, c: Color = Color.WHITE, t: String = "") -> Icon:
	var i := Icon.new()
	i.kind = k
	i.color = c
	i.text = t
	i.custom_minimum_size = Vector2(size, size)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


func _draw() -> void:
	var s := size
	var c := s * 0.5
	var r := minf(s.x, s.y) * 0.5
	match kind:
		"coin":
			draw_circle(c, r, Color("e69500"))
			draw_circle(c - Vector2(0, r * 0.08), r * 0.9, Color("ffc83d"))
			draw_circle(c - Vector2(0, r * 0.08), r * 0.62, Color("ffd96b"))
			_text("K", r * 1.0, Color("b36b00"), c - Vector2(0, r * 0.08))
		"diamond":
			var pts := PackedVector2Array([c + Vector2(0, -r * 0.92), c + Vector2(r * 0.86, -r * 0.2), c + Vector2(0, r * 0.95), c + Vector2(-r * 0.86, -r * 0.2)])
			draw_colored_polygon(pts, Color("1fb6e8"))
			var top := PackedVector2Array([c + Vector2(0, -r * 0.92), c + Vector2(r * 0.86, -r * 0.2), c + Vector2(0, -r * 0.05), c + Vector2(-r * 0.86, -r * 0.2)])
			draw_colored_polygon(top, Color("7fe3ff"))
			draw_line(c + Vector2(-r * 0.35, -r * 0.55), c + Vector2(-r * 0.1, -r * 0.3), Color(1, 1, 1, 0.9), maxf(2.0, r * 0.12))
		"avatar":
			draw_circle(c, r, color.darkened(0.2))
			draw_circle(c - Vector2(0, r * 0.06), r * 0.92, color)
			draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.16, Color(1, 1, 1, 0.35))
			_text(text, r * 0.8, Color.WHITE, c)
		"badge":
			draw_circle(c, r, color)
			_text(text, r * 0.95, Color.WHITE, c)
		"dot":
			draw_circle(c, r, color)


func _text(t: String, font_size: float, col: Color, center: Vector2) -> void:
	if t == "":
		return
	Kit.theme()
	var f: Font = Kit.font_bold
	var fs := int(font_size)
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, center + Vector2(-w * 0.5, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

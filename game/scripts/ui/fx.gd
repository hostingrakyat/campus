class_name Fx
extends RefCounted
## Small, reusable UI motion: pops, staggers, slides, count-ups, shakes, press feedback.
## Safe inside containers (animates scale/modulate, not position) unless noted.

const EASE_POP := Tween.TRANS_BACK


static func center_pivot(c: Control) -> void:
	c.pivot_offset = c.size * 0.5
	if not c.has_meta("fx_pivot"):
		c.set_meta("fx_pivot", true)
		c.resized.connect(func(): c.pivot_offset = c.size * 0.5)


## Fade + scale in. Works for container children.
static func pop_in(c: Control, delay: float = 0.0, from: float = 0.86, dur: float = 0.3) -> void:
	center_pivot(c)
	c.modulate.a = 0.0
	c.scale = Vector2(from, from)
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, dur * 0.6).set_delay(delay)
	tw.tween_property(c, "scale", Vector2.ONE, dur).set_delay(delay).set_trans(EASE_POP).set_ease(Tween.EASE_OUT)


## Staggered pop for every child of a container.
static func stagger(container: Node, step: float = 0.035, start: float = 0.0, max_items: int = 14) -> void:
	var i := 0
	for ch in container.get_children():
		if ch is Control and ch.visible:
			pop_in(ch, start + minf(i, max_items) * step)
			i += 1


## Slide a free-positioned control (not inside a container) in from an offset.
## Slides an anchored control in from an offset. It animates the layout offsets (the inputs the
## anchors use), never the computed position, so the control always ends exactly where its
## anchors put it, even if its size is still being calculated. Not for container children.
static func slide_in(c: Control, offset: Vector2, delay: float = 0.0, dur: float = 0.42) -> void:
	var o := Vector4(c.offset_left, c.offset_top, c.offset_right, c.offset_bottom)
	c.offset_left = o.x + offset.x
	c.offset_right = o.z + offset.x
	c.offset_top = o.y + offset.y
	c.offset_bottom = o.w + offset.y
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel(true)
	for prop in [["offset_left", o.x], ["offset_top", o.y], ["offset_right", o.z], ["offset_bottom", o.w]]:
		tw.tween_property(c, prop[0], prop[1], dur).set_delay(delay).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, dur * 0.5).set_delay(delay)


static func fade_in(c: CanvasItem, dur: float = 0.22, delay: float = 0.0) -> void:
	c.modulate.a = 0.0
	c.create_tween().tween_property(c, "modulate:a", 1.0, dur).set_delay(delay)


static func pulse(c: Control, amount: float = 1.14, dur: float = 0.28) -> void:
	center_pivot(c)
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(amount, amount), dur * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2.ONE, dur * 0.65).set_trans(EASE_POP).set_ease(Tween.EASE_OUT)


static func shake(c: Control, strength: float = 10.0) -> void:
	center_pivot(c)
	var tw := c.create_tween()
	for i in 4:
		tw.tween_property(c, "rotation", deg_to_rad(strength * 0.25 * (1 if i % 2 == 0 else -1)), 0.04)
	tw.tween_property(c, "rotation", 0.0, 0.05)


## Animated number in a Label, formatted with fmt(value) -> String.
static func count(l: Label, from: float, to: float, fmt: Callable, dur: float = 0.6) -> void:
	l.create_tween().tween_method(func(v: float): l.text = fmt.call(v), from, to, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func bar_to(pb: ProgressBar, value: float, dur: float = 0.55) -> void:
	pb.create_tween().tween_property(pb, "value", value, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Reveals a label's text letter by letter.
static func typewriter(l: Label, cps: float = 90.0) -> void:
	l.visible_ratio = 0.0
	var dur := clampf(l.text.length() / cps, 0.2, 1.6)
	l.create_tween().tween_property(l, "visible_ratio", 1.0, dur)


## Squash on press, springy release. Hooked onto every Button by the Audio autoload.
static func press_feedback(b: Button) -> void:
	b.button_down.connect(func():
		center_pivot(b)
		b.create_tween().tween_property(b, "scale", Vector2(0.94, 0.94), 0.06))
	b.button_up.connect(func():
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.22).set_trans(EASE_POP).set_ease(Tween.EASE_OUT))

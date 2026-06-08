extends RefCounted

static func joystick_axis(touch_position: Vector2, center: Vector2, radius: float) -> Vector2:
	var offset := touch_position - center
	if offset.length() <= 4.0:
		return Vector2.ZERO
	return offset.limit_length(radius) / radius

extends RefCounted

static func clamp_to_rect(pos: Vector2, rect: Rect2, radius: float) -> Vector2:
	return Vector2(
		clampf(pos.x, rect.position.x + radius, rect.end.x - radius),
		clampf(pos.y, rect.position.y + radius, rect.end.y - radius)
	)


static func push_out_of_rects(pos: Vector2, radius: float, rects: Array[Rect2], bounds: Rect2) -> Vector2:
	var pushed := pos
	for obstacle in rects:
		var grown := obstacle.grow(radius)
		if not grown.has_point(pushed):
			continue
		var left: float = abs(pushed.x - grown.position.x)
		var right: float = abs(grown.end.x - pushed.x)
		var top: float = abs(pushed.y - grown.position.y)
		var bottom: float = abs(grown.end.y - pushed.y)
		var smallest: float = min(left, right, top, bottom)
		if smallest == left:
			pushed.x = grown.position.x
		elif smallest == right:
			pushed.x = grown.end.x
		elif smallest == top:
			pushed.y = grown.position.y
		else:
			pushed.y = grown.end.y
	return clamp_to_rect(pushed, bounds, radius)


static func circle_overlaps_any_rect(pos: Vector2, radius: float, rects: Array[Rect2]) -> bool:
	for rect in rects:
		if rect.grow(radius).has_point(pos):
			return true
	return false

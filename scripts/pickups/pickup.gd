extends RefCounted

static func xp(position: Vector2, value: int) -> Dictionary:
	return {"pos": position, "kind": "xp", "value": value}


static func heart(position: Vector2, value: int) -> Dictionary:
	return {"pos": position, "kind": "heart", "value": value}


static func color_for(kind: String) -> Color:
	if kind == "xp":
		return Color(0.32, 0.85, 1.0)
	return Color(0.15, 1.0, 0.38)

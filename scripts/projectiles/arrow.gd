extends RefCounted

static func create(position: Vector2, direction: Vector2, damage: int, pierce: int) -> Dictionary:
	return {
		"pos": position + direction * 24.0,
		"vel": direction * 585.0,
		"damage": damage,
		"life": 1.35,
		"pierce_left": pierce,
		"ricocheted": false
	}

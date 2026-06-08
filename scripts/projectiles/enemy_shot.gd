extends RefCounted

static func create(origin: Vector2, direction: Vector2, room_index: int) -> Dictionary:
	return {
		"pos": origin + direction * 22.0,
		"vel": direction * 225.0,
		"damage": 8 + room_index,
		"life": 3.0
	}

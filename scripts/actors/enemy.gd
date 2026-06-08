extends RefCounted

static func choose_kind(room_index: int, rng: RandomNumberGenerator) -> String:
	var kind := "crawler"
	if room_index >= 2 and rng.randf() < 0.32:
		kind = "spitter"
	if room_index >= 4 and rng.randf() < 0.22:
		kind = "brute"
	return kind


static func create(kind: String, room_index: int, position: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	var hp := 24 + room_index * 6
	var speed := 92.0 + room_index * 5.0
	var touch := 9 + room_index
	if kind == "spitter":
		hp = 19 + room_index * 5
		speed = 74.0
	elif kind == "brute":
		hp = 46 + room_index * 10
		speed = 64.0
		touch = 15 + room_index

	return {
		"kind": kind,
		"pos": position,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"touch": touch,
		"hit_cd": 0.0,
		"shoot_cd": rng.randf_range(0.4, 1.4)
	}


static func color_for(kind: String) -> Color:
	if kind == "spitter":
		return Color(0.58, 0.18, 0.82)
	if kind == "brute":
		return Color(0.16, 0.46, 0.24)
	return Color(0.82, 0.18, 0.16)

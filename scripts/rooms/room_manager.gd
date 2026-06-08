extends RefCounted

static func obstacle_layout(room_index: int, arena: Rect2) -> Array[Rect2]:
	var obstacles: Array[Rect2] = []
	if room_index % 3 == 1:
		obstacles.append(Rect2(arena.position + Vector2(106, 260), Vector2(74, 150)))
		obstacles.append(Rect2(arena.position + Vector2(300, 188), Vector2(66, 220)))
	elif room_index % 3 == 2:
		obstacles.append(Rect2(arena.position + Vector2(82, 160), Vector2(122, 52)))
		obstacles.append(Rect2(arena.position + Vector2(258, 430), Vector2(142, 52)))
		obstacles.append(Rect2(arena.position + Vector2(206, 284), Vector2(70, 96)))
	else:
		obstacles.append(Rect2(arena.position + Vector2(78, 314), Vector2(136, 48)))
		obstacles.append(Rect2(arena.position + Vector2(258, 314), Vector2(136, 48)))
	return obstacles


static func player_start_position(arena: Rect2) -> Vector2:
	return arena.get_center() + Vector2(0, arena.size.y * 0.34)


static func gate_position(arena: Rect2) -> Vector2:
	return Vector2(arena.get_center().x, arena.position.y + 26)


static func wave_count(room_index: int, max_rooms: int) -> int:
	if room_index >= max_rooms:
		return 1
	if room_index <= 2:
		return 1
	if room_index <= 5:
		return 2
	return 3


static func enemy_wave(room_index: int, wave_index: int, max_rooms: int) -> Array[String]:
	if room_index >= max_rooms:
		return ["boss"]

	var enemies: Array[String] = []
	var crawler_count: int = 3 + room_index + wave_index
	for i in crawler_count:
		enemies.append("crawler")

	if room_index >= 2:
		enemies.append("spitter")
	if room_index >= 4:
		enemies.append("runner")
	if room_index >= 5 and wave_index >= 2:
		enemies.append("brute")
	if room_index >= 7:
		enemies.append("spitter")
		enemies.append("runner")

	return enemies

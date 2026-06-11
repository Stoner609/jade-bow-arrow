extends RefCounted

const ROOM_WAVES := {
	1: [{"crawler": 5}],
	2: [{"crawler": 6, "spitter": 1}],
	3: [{"crawler": 7, "spitter": 1}, {"crawler": 8, "spitter": 1}],
	4: [{"crawler": 8, "spitter": 1, "runner": 1}, {"crawler": 9, "spitter": 1, "runner": 1}],
	5: [{"crawler": 9, "spitter": 1, "runner": 1}, {"crawler": 10, "spitter": 1, "runner": 1, "brute": 1}],
	6: [{"crawler": 10, "spitter": 1, "runner": 1}, {"crawler": 11, "spitter": 1, "runner": 1, "brute": 1}, {"crawler": 12, "spitter": 1, "runner": 1, "brute": 1}],
	7: [{"crawler": 11, "spitter": 2, "runner": 2}, {"crawler": 12, "spitter": 2, "runner": 2, "brute": 1}, {"crawler": 13, "spitter": 2, "runner": 2, "brute": 1}],
	8: [{"boss": 1}]
}


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
	var room_waves: Array = ROOM_WAVES.get(min(room_index, max_rooms), [])
	return max(1, room_waves.size())


static func enemy_wave(room_index: int, wave_index: int, max_rooms: int) -> Array[String]:
	var enemies: Array[String] = []
	var room_waves: Array = ROOM_WAVES.get(min(room_index, max_rooms), [])
	if room_waves.is_empty():
		return enemies
	var wave: Dictionary = room_waves[clamp(wave_index - 1, 0, room_waves.size() - 1)]
	for kind in wave.keys():
		for i in int(wave[kind]):
			enemies.append(kind)
	return enemies

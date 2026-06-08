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

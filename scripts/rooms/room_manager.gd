extends RefCounted

const ROOMS := {
	1: {"layout": "pillars", "message": "Clear the room. Stop moving to auto-fire.", "waves": [{"crawler": 6}]},
	2: {"layout": "cross", "message": "Keep distance from spitters.", "waves": [{"crawler": 8, "spitter": 1}]},
	3: {"layout": "lanes", "message": "Survive two waves.", "waves": [{"crawler": 9, "spitter": 1}, {"crawler": 10, "spitter": 1}]},
	4: {"layout": "pillars", "message": "Runners join the fight.", "waves": [{"crawler": 10, "spitter": 1, "runner": 1}, {"crawler": 11, "spitter": 1, "runner": 1}]},
	5: {"layout": "cross", "message": "Brutes can take more hits.", "waves": [{"crawler": 11, "spitter": 1, "runner": 1}, {"crawler": 12, "spitter": 1, "runner": 1, "brute": 1}]},
	6: {"layout": "lanes", "message": "Three waves. Control the center.", "waves": [{"crawler": 11, "spitter": 1, "runner": 1}, {"crawler": 12, "spitter": 1, "runner": 1, "brute": 1}, {"crawler": 13, "spitter": 1, "runner": 1, "brute": 1}]},
	7: {"layout": "pillars", "message": "Final swarm before the boss.", "waves": [{"crawler": 12, "spitter": 2, "runner": 2}, {"crawler": 13, "spitter": 2, "runner": 2, "brute": 1}, {"crawler": 14, "spitter": 2, "runner": 2, "brute": 1}]},
	8: {"layout": "boss", "message": "Final room. Defeat the boss.", "waves": [{"boss": 1}]}
}

const LAYOUTS := {
	"pillars": [
		{"pos": Vector2(106, 260), "size": Vector2(74, 150)},
		{"pos": Vector2(300, 188), "size": Vector2(66, 220)}
	],
	"cross": [
		{"pos": Vector2(82, 160), "size": Vector2(122, 52)},
		{"pos": Vector2(258, 430), "size": Vector2(142, 52)},
		{"pos": Vector2(206, 284), "size": Vector2(70, 96)}
	],
	"lanes": [
		{"pos": Vector2(78, 314), "size": Vector2(136, 48)},
		{"pos": Vector2(258, 314), "size": Vector2(136, 48)}
	],
	"boss": []
}


static func obstacle_layout(room_index: int, arena: Rect2) -> Array[Rect2]:
	var room: Dictionary = room_data(room_index, room_index)
	var layout: String = room.get("layout", "pillars")
	return obstacle_layout_for(layout, arena)


static func obstacle_layout_for(layout: String, arena: Rect2) -> Array[Rect2]:
	var obstacles: Array[Rect2] = []
	var specs: Array = LAYOUTS.get(layout, LAYOUTS.pillars)
	for spec in specs:
		obstacles.append(Rect2(arena.position + spec.pos, spec.size))
	return obstacles


static func player_start_position(arena: Rect2) -> Vector2:
	return arena.get_center() + Vector2(0, arena.size.y * 0.34)


static func gate_position(arena: Rect2) -> Vector2:
	return Vector2(arena.get_center().x, arena.position.y + 26)


static func wave_count(room_index: int, max_rooms: int) -> int:
	var room_waves: Array = room_waves(room_index, max_rooms)
	return max(1, room_waves.size())


static func enemy_wave(room_index: int, wave_index: int, max_rooms: int) -> Array[String]:
	var enemies: Array[String] = []
	var room_waves: Array = room_waves(room_index, max_rooms)
	if room_waves.is_empty():
		return enemies
	var wave: Dictionary = room_waves[clamp(wave_index - 1, 0, room_waves.size() - 1)]
	for kind in wave.keys():
		for i in int(wave[kind]):
			enemies.append(kind)
	return enemies


static func room_message(room_index: int, wave_index: int, max_rooms: int) -> String:
	var room: Dictionary = room_data(room_index, max_rooms)
	if room_index >= max_rooms:
		return room.get("message", "Final room. Defeat the boss.")
	var wave_total := wave_count(room_index, max_rooms)
	if wave_index <= 1:
		return room.get("message", "Room %d/%d - Wave %d/%d." % [room_index, max_rooms, wave_index, wave_total])
	return "Room %d/%d - Wave %d/%d." % [room_index, max_rooms, wave_index, wave_total]


static func room_data(room_index: int, max_rooms: int) -> Dictionary:
	return ROOMS.get(min(room_index, max_rooms), {})


static func room_waves(room_index: int, max_rooms: int) -> Array:
	return room_data(room_index, max_rooms).get("waves", [])

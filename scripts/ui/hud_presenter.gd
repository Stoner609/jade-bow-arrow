extends RefCounted

static func hud_text(room_index: int, max_rooms: int, player: Dictionary, xp_needed: int) -> String:
	return "Room %d/%d   HP %d/%d   Lv.%d\nXP %d/%d   DMG %d   Arrows %d" % [
		room_index,
		max_rooms,
		player.hp,
		player.max_hp,
		player.level,
		player.xp,
		xp_needed,
		player.power,
		player.arrows
	]


static func recent_messages(messages: Array[String], count: int) -> String:
	return "\n".join(messages.slice(max(0, messages.size() - count), messages.size()))

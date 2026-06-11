extends RefCounted

static func create() -> Dictionary:
	return {
		"pos": Vector2.ZERO,
		"hp": 80,
		"max_hp": 80,
		"power": 13,
		"level": 1,
		"xp": 0,
		"speed": 275.0,
		"fire_rate": 0.48,
		"arrows": 1,
		"pierce": 0,
		"ricochet": false,
		"lifesteal": 0.0,
		"crit_chance": 0.0,
		"crit_multiplier": 1.5,
		"boss_damage_bonus": 0.0
	}


static func reset(player: Dictionary, start_position: Vector2) -> void:
	player.pos = start_position
	player.hp = player.max_hp
	player.power = 13
	player.level = 1
	player.xp = 0
	player.speed = 275.0
	player.fire_rate = 0.48
	player.arrows = 1
	player.pierce = 0
	player.ricochet = false
	player.lifesteal = 0.0
	player.crit_chance = 0.0
	player.crit_multiplier = 1.5
	player.boss_damage_bonus = 0.0

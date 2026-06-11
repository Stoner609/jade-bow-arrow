extends RefCounted

const UPGRADES := [
	{"id": "power_shot", "name": "Power Shot", "desc": "+4 damage", "effect": {"stat": "power", "op": "add", "value": 4}, "weight": 22},
	{"id": "quick_draw", "name": "Quick Draw", "desc": "faster auto-fire", "effect": {"stat": "fire_rate", "op": "add", "value": -0.05, "min": 0.28}, "weight": 18},
	{"id": "vitality", "name": "Vitality", "desc": "+18 max HP", "effect": {"stat": "max_hp", "op": "add_with_heal", "value": 18}, "weight": 20},
	{"id": "swift_steps", "name": "Swift Steps", "desc": "+22 move speed", "effect": {"stat": "speed", "op": "add", "value": 22, "max": 360}, "weight": 14},
	{"id": "blood_arrow", "name": "Blood Arrow", "desc": "heal 4% arrow damage", "effect": {"stat": "lifesteal", "op": "add", "value": 0.04, "max": 0.12}, "weight": 8},
	{"id": "critical_eye", "name": "Critical Eye", "desc": "+8% crit chance", "effect": {"stat": "crit_chance", "op": "add", "value": 0.08, "max": 0.32}, "weight": 10},
	{"id": "giant_slayer", "name": "Giant Slayer", "desc": "+12% boss damage", "effect": {"stat": "boss_damage_bonus", "op": "add", "value": 0.12, "max": 0.36}, "weight": 7},
	{"id": "twin_arrow", "name": "Twin Arrow", "desc": "+1 arrow", "effect": {"stat": "arrows", "op": "add", "value": 1, "max": 4}, "weight": 12, "requires": {"stat": "arrows", "op": "lt", "value": 4}},
	{"id": "piercing", "name": "Piercing", "desc": "arrows pass through 1 enemy", "effect": {"stat": "pierce", "op": "add", "value": 1, "max": 3}, "weight": 10, "requires": {"stat": "pierce", "op": "lt", "value": 3}},
	{"id": "ricochet", "name": "Ricochet", "desc": "first hit bounces", "effect": {"stat": "ricochet", "op": "set", "value": true}, "weight": 7, "requires": {"stat": "ricochet", "op": "is_false"}}
]


# 用途：依照升級權重抽出本次升級選項。
static func choices(rng: RandomNumberGenerator, count: int = 3, player: Dictionary = {}) -> Array[Dictionary]:
	var pool := available_upgrades(player)
	var selected: Array[Dictionary] = []
	while selected.size() < count and not pool.is_empty():
		var index := _weighted_index(pool, rng)
		selected.append(pool[index])
		pool.remove_at(index)
	return selected


# 用途：回傳目前玩家狀態允許出現的升級池。
static func available_upgrades(player: Dictionary) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for upgrade in UPGRADES:
		if _meets_requirement(player, upgrade.get("requires", {})):
			available.append(upgrade.duplicate(true))
	return available


# 用途：把升級資料中的效果套用到玩家數值。
static func apply_upgrade(player: Dictionary, upgrade: Dictionary) -> void:
	var effect: Dictionary = upgrade.get("effect", {})
	var stat: String = effect.get("stat", "")
	var op: String = effect.get("op", "")
	if stat.is_empty() or op.is_empty():
		return
	match op:
		"add":
			var value = player.get(stat, 0) + effect.get("value", 0)
			if effect.has("min"):
				value = max(effect.get("min"), value)
			if effect.has("max"):
				value = min(effect.get("max"), value)
			player[stat] = value
		"add_with_heal":
			var amount: int = int(effect.get("value", 0))
			player[stat] = int(player.get(stat, 0)) + amount
			player.hp = min(int(player.max_hp), int(player.hp) + amount)
		"set":
			player[stat] = effect.get("value")


# 用途：檢查玩家目前狀態是否符合升級出現限制。
static func _meets_requirement(player: Dictionary, requirement: Dictionary) -> bool:
	if requirement.is_empty() or player.is_empty():
		return true
	var stat: String = requirement.get("stat", "")
	var op: String = requirement.get("op", "")
	var current = player.get(stat)
	match op:
		"lt":
			return current < requirement.get("value")
		"is_false":
			return not bool(current)
	return true


# 用途：依照權重回傳升級池中的索引。
static func _weighted_index(pool: Array, rng: RandomNumberGenerator) -> int:
	var total_weight := 0.0
	for upgrade in pool:
		total_weight += float(upgrade.get("weight", 1.0))
	var roll := rng.randf_range(0.0, total_weight)
	for i in pool.size():
		roll -= float(pool[i].get("weight", 1.0))
		if roll <= 0.0:
			return i
	return pool.size() - 1

extends RefCounted

const UPGRADES := [
	{"id": "power_shot", "name": "Power Shot", "desc": "+4 damage", "effect": {"stat": "power", "op": "add", "value": 4}, "weight": 24},
	{"id": "quick_draw", "name": "Quick Draw", "desc": "faster auto-fire", "effect": {"stat": "fire_rate", "op": "add", "value": -0.06, "min": 0.25}, "weight": 20},
	{"id": "vitality", "name": "Vitality", "desc": "+18 max HP", "effect": {"stat": "max_hp", "op": "add_with_heal", "value": 18}, "weight": 22},
	{"id": "twin_arrow", "name": "Twin Arrow", "desc": "+1 arrow", "effect": {"stat": "arrows", "op": "add", "value": 1, "max": 4}, "weight": 14},
	{"id": "piercing", "name": "Piercing", "desc": "arrows pass through 1 enemy", "effect": {"stat": "pierce", "op": "add", "value": 1, "max": 3}, "weight": 12},
	{"id": "ricochet", "name": "Ricochet", "desc": "first hit bounces", "effect": {"stat": "ricochet", "op": "set", "value": true}, "weight": 8}
]


# 用途：依照升級權重抽出本次升級選項。
static func choices(rng: RandomNumberGenerator, count: int = 3) -> Array[Dictionary]:
	var pool := UPGRADES.duplicate(true)
	var selected: Array[Dictionary] = []
	while selected.size() < count and not pool.is_empty():
		var index := _weighted_index(pool, rng)
		selected.append(pool[index])
		pool.remove_at(index)
	return selected


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

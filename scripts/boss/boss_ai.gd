extends RefCounted

const Tuning := preload("res://scripts/boss/boss_tuning.gd")

const PHASE_ATTACKS := {
	1: [
		{"id": "spread", "label": "SPREAD", "kind": "projectile", "count": Tuning.PHASE_ONE_SPREAD_COUNT, "spread": Tuning.PHASE_ONE_SPREAD_ANGLE, "speed_scale": 1.0, "bullet": Tuning.BULLET_NORMAL}
	],
	2: [
		{"id": "spread", "label": "SPREAD", "kind": "projectile", "count": Tuning.PHASE_TWO_SPREAD_COUNT, "spread": Tuning.PHASE_TWO_SPREAD_ANGLE, "speed_scale": 1.0, "bullet": Tuning.BULLET_NORMAL},
		{"id": "sweep", "label": "SWEEP", "kind": "projectile", "count": Tuning.PHASE_TWO_SWEEP_COUNT, "spread": Tuning.PHASE_TWO_SWEEP_ANGLE, "speed_scale": Tuning.PHASE_TWO_SWEEP_SPEED_SCALE, "warning": Tuning.PHASE_TWO_SWEEP_WARNING, "bullet": Tuning.BULLET_SWEEP}
	],
	3: [
		{"id": "sweep", "label": "SWEEP", "kind": "projectile", "count": Tuning.PHASE_THREE_SWEEP_COUNT, "spread": Tuning.PHASE_THREE_SWEEP_ANGLE, "speed_scale": Tuning.PHASE_THREE_SWEEP_SPEED_SCALE, "warning": Tuning.PHASE_THREE_SWEEP_WARNING, "bullet": Tuning.BULLET_SWEEP},
		{"id": "delayed", "label": "DELAY", "kind": "projectile", "count": Tuning.PHASE_THREE_DELAYED_COUNT, "spread": Tuning.PHASE_THREE_DELAYED_ANGLE, "speed_scale": Tuning.PHASE_THREE_DELAYED_SPEED_SCALE, "life": Tuning.PHASE_THREE_DELAYED_LIFE, "bullet": Tuning.BULLET_DELAYED},
		{"id": "spread", "label": "SPREAD", "kind": "projectile", "count": Tuning.PHASE_THREE_SPREAD_COUNT, "spread": Tuning.PHASE_THREE_SPREAD_ANGLE, "speed_scale": 1.0, "bullet": Tuning.BULLET_NORMAL},
		{"id": "dash", "label": "DASH", "kind": "dash", "distance": Tuning.PHASE_THREE_DASH_DISTANCE, "warning": Tuning.PHASE_THREE_DASH_WARNING}
	]
}


# 用途：依 Boss 血量比例取得目前階段。
static func phase_for(enemy: Dictionary) -> int:
	var max_hp: float = max(1.0, float(enemy.max_hp))
	var ratio: float = clampf(float(enemy.hp) / max_hp, 0.0, 1.0)
	if ratio <= Tuning.PHASE_THREE_RATIO:
		return 3
	if ratio <= Tuning.PHASE_TWO_RATIO:
		return 2
	return 1


# 用途：依目前 Boss 階段與輪替索引取得下一個招式資料。
static func next_attack(enemy: Dictionary) -> Dictionary:
	var phase := int(enemy.get("boss_phase", 1))
	var attacks: Array = PHASE_ATTACKS.get(phase, PHASE_ATTACKS[1])
	var index := int(enemy.get("boss_attack_index", 0))
	enemy["boss_attack_index"] = index + 1
	return attacks[index % attacks.size()].duplicate(true)


# 用途：取得 Boss 階段射擊或招式冷卻下限。
static func cooldown_min(phase: int) -> float:
	if phase >= 3:
		return Tuning.PHASE_THREE_COOLDOWN_MIN
	if phase == 2:
		return Tuning.PHASE_TWO_COOLDOWN_MIN
	return Tuning.PHASE_ONE_COOLDOWN_MIN


# 用途：取得 Boss 階段射擊或招式冷卻上限。
static func cooldown_max(phase: int) -> float:
	if phase >= 3:
		return Tuning.PHASE_THREE_COOLDOWN_MAX
	if phase == 2:
		return Tuning.PHASE_TWO_COOLDOWN_MAX
	return Tuning.PHASE_ONE_COOLDOWN_MAX

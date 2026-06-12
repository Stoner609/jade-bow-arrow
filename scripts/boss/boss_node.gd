extends "res://scripts/actors/enemy_node.gd"

const BossAI := preload("res://scripts/boss/boss_ai.gd")

signal boss_attack_requested(enemy: Dictionary, direction: Vector2, attack: Dictionary)
signal phase_changed(enemy: Dictionary, phase: int)

var rng := RandomNumberGenerator.new()
var pending_attacks: Array = []


# 用途：初始化 Boss 自己的隨機數，用於招式冷卻。
func _ready() -> void:
	rng.randomize()


# 用途：接收目前 Boss 資料，並初始化 Boss 專用狀態。
func sync_from_model(enemy: Dictionary, current_elapsed: float) -> void:
	super.sync_from_model(enemy, current_elapsed)
	if not enemy_data.has("boss_phase"):
		enemy_data["boss_phase"] = 1
	if not enemy_data.has("boss_attack_index"):
		enemy_data["boss_attack_index"] = 0


# 用途：更新 Boss 與玩家之間的距離控制、階段、前搖與招式節奏。
func update_boss_position(player_position: Vector2, delta: float) -> Vector2:
	if not active or enemy_data.is_empty():
		return Vector2.ZERO
	enemy_data.shoot_cd = max(0.0, float(enemy_data.shoot_cd) - delta)
	_update_boss_phase()
	_update_pending_attacks(delta)
	var to_player: Vector2 = player_position - enemy_data.pos
	if to_player.is_zero_approx():
		return Vector2.ZERO
	var distance: float = to_player.length()
	if distance >= Constants.BOSS_ACTIVE_RANGE:
		return to_player.normalized()
	var direction := to_player.normalized()
	if _update_dash_warning(direction, delta):
		queue_redraw()
		return direction
	if distance < Constants.BOSS_RETREAT_DISTANCE:
		enemy_data.pos -= direction * float(enemy_data.speed) * Constants.BOSS_RETREAT_SPEED_SCALE * delta
	elif distance > Constants.BOSS_APPROACH_DISTANCE:
		enemy_data.pos += direction * float(enemy_data.speed) * delta
	if enemy_data.shoot_cd <= 0.0:
		_start_attack(direction)
	queue_redraw()
	return direction


# 用途：選擇並啟動下一個 Boss 招式。
func _start_attack(direction: Vector2) -> void:
	var attack := BossAI.next_attack(enemy_data, rng)
	var phase: int = int(enemy_data.get("boss_phase", 1))
	enemy_data.shoot_cd = rng.randf_range(BossAI.cooldown_min(phase), BossAI.cooldown_max(phase))
	if String(attack.kind) == "dash":
		_start_dash_warning(direction, attack)
		return
	var warning := float(attack.get("warning", 0.0))
	if warning > 0.0:
		pending_attacks.append({"direction": direction, "attack": attack.duplicate(true), "timer": warning, "duration": warning})
		return
	boss_attack_requested.emit(enemy_data, direction, attack)


# 用途：啟動 Boss 衝刺前搖，警示結束後才真正位移。
func _start_dash_warning(direction: Vector2, attack: Dictionary) -> void:
	var warning := float(attack.get("warning", 0.45))
	enemy_data["boss_dash_warning"] = warning
	enemy_data["boss_dash_warning_total"] = warning
	enemy_data["boss_dash_direction"] = direction
	enemy_data["boss_dash_distance"] = float(attack.distance)


# 用途：處理 Boss 衝刺前搖倒數與實際位移。
func _update_dash_warning(direction: Vector2, delta: float) -> bool:
	var warning_left := float(enemy_data.get("boss_dash_warning", 0.0))
	if warning_left <= 0.0:
		return false
	warning_left -= delta
	enemy_data["boss_dash_warning"] = warning_left
	if warning_left > 0.0:
		return true
	var dash_direction: Vector2 = enemy_data.get("boss_dash_direction", direction)
	var dash_distance := float(enemy_data.get("boss_dash_distance", 0.0))
	enemy_data.pos += dash_direction.normalized() * dash_distance
	enemy_data.erase("boss_dash_warning")
	enemy_data.erase("boss_dash_warning_total")
	enemy_data.erase("boss_dash_direction")
	enemy_data.erase("boss_dash_distance")
	return true


# 用途：更新延遲 Boss 招式，警示結束後才向 game.gd 請求產生子彈。
func _update_pending_attacks(delta: float) -> void:
	for i in range(pending_attacks.size() - 1, -1, -1):
		var pending: Dictionary = pending_attacks[i]
		pending.timer = float(pending.timer) - delta
		if float(pending.timer) > 0.0:
			continue
		boss_attack_requested.emit(enemy_data, _burst_direction(pending.direction, pending.attack, int(pending.get("burst_index", 0))), pending.attack)
		_schedule_next_burst(pending)
		pending_attacks.remove_at(i)


# 用途：依 Boss 剩餘血量切換階段。
func _update_boss_phase() -> void:
	var next_phase := BossAI.phase_for(enemy_data)
	var current_phase: int = int(enemy_data.get("boss_phase", 1))
	if current_phase == next_phase:
		return
	enemy_data["boss_phase"] = next_phase
	phase_changed.emit(enemy_data, next_phase)


# 用途：繪製 Boss 地面警示與 Boss 本體。
func _draw() -> void:
	if enemy_data.is_empty():
		return
	_draw_warnings()
	CombatRenderer.draw_enemies(self, [enemy_data], elapsed, Constants.ENEMY_RADIUS)


# 用途：繪製所有 Boss 前搖地面警示。
func _draw_warnings() -> void:
	for pending in pending_attacks:
		var attack: Dictionary = pending.attack
		if _attack_bullet_style(attack) != "sweep":
			continue
		var duration: float = max(0.01, float(pending.get("duration", pending.timer)))
		var progress: float = 1.0 - clampf(float(pending.timer) / duration, 0.0, 1.0)
		_draw_sweep_warning(enemy_data.pos, _burst_direction(pending.direction, attack, int(pending.get("burst_index", 0))), attack, progress)
	var warning_left := float(enemy_data.get("boss_dash_warning", 0.0))
	if warning_left <= 0.0:
		return
	var total: float = max(0.01, float(enemy_data.get("boss_dash_warning_total", warning_left)))
	var progress: float = 1.0 - clampf(warning_left / total, 0.0, 1.0)
	var direction: Vector2 = enemy_data.get("boss_dash_direction", Vector2.RIGHT)
	var distance := float(enemy_data.get("boss_dash_distance", 82.0))
	_draw_dash_warning(enemy_data.pos, direction, distance, progress)


# 用途：取得招式的子彈樣式，支援資料化後的 bullet profile。
func _attack_bullet_style(attack: Dictionary) -> String:
	var bullet: Dictionary = attack.get("bullet", {})
	return String(bullet.get("style", attack.get("style", "")))


# 用途：排程同一個 sweep 招式的下一段掃射。
func _schedule_next_burst(pending: Dictionary) -> void:
	var attack: Dictionary = pending.attack
	var next_index := int(pending.get("burst_index", 0)) + 1
	if next_index >= int(attack.get("bursts", 1)):
		return
	pending_attacks.append({
		"direction": pending.direction,
		"attack": attack.duplicate(true),
		"timer": float(attack.get("burst_delay", 0.0)),
		"duration": float(attack.get("burst_delay", 0.01)),
		"burst_index": next_index
	})


# 用途：依掃射段數偏移方向，讓連續掃射有左右擺動。
func _burst_direction(direction: Vector2, attack: Dictionary, burst_index: int) -> Vector2:
	if burst_index <= 0:
		return direction
	var offset := float(attack.get("burst_offset", 0.0))
	var side := 1.0 if burst_index % 2 == 1 else -1.0
	return direction.rotated(offset * side)


# 用途：繪製掃射前的扇形危險範圍。
func _draw_sweep_warning(origin: Vector2, direction: Vector2, attack: Dictionary, progress: float) -> void:
	if direction.is_zero_approx():
		return
	var count := int(attack.get("count", 1))
	var spread := float(attack.get("spread", 0.0))
	var half_angle: float = max(0.16, spread * float(max(1, count - 1)) * 0.5 + 0.12)
	var radius := 360.0
	var points := PackedVector2Array([origin])
	var segments := 18
	var base_angle := direction.angle()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := base_angle - half_angle + half_angle * 2.0 * t
		points.append(origin + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color(1.0, 0.58, 0.08, 0.12 + progress * 0.1))
	draw_arc(origin, radius * 0.62, base_angle - half_angle, base_angle + half_angle, 32, Color(1.0, 0.86, 0.24, 0.28 + progress * 0.28), 4.0)
	draw_line(origin, origin + direction.normalized() * radius, Color(1.0, 0.86, 0.24, 0.32 + progress * 0.28), 3.0)


# 用途：繪製衝刺前的直線危險路徑。
func _draw_dash_warning(origin: Vector2, direction: Vector2, distance: float, progress: float) -> void:
	if direction.is_zero_approx():
		return
	var end := origin + direction.normalized() * distance
	draw_line(origin, end, Color(1.0, 0.1, 0.06, 0.18 + progress * 0.22), 28.0)
	draw_line(origin, end, Color(1.0, 0.82, 0.3, 0.52 + progress * 0.28), 4.0)
	draw_circle(end, 14.0 + progress * 8.0, Color(1.0, 0.2, 0.08, 0.24 + progress * 0.22))

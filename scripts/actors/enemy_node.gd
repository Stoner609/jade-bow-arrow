extends Node2D

const Constants := preload("res://scripts/core/constants.gd")
const CombatRenderer := preload("res://scripts/rendering/combat_renderer.gd")

signal damaged(enemy: Dictionary, damage: int)
signal died(enemy: Dictionary)
signal shot_requested(enemy: Dictionary, direction: Vector2)
signal spread_shot_requested(enemy: Dictionary, direction: Vector2, count: int, spread: float)

var enemy_data: Dictionary = {}
var elapsed := 0.0
var active := false


# 用途：接收目前敵人資料，讓敵人節點自行繪製視覺。
func sync_from_model(enemy: Dictionary, current_elapsed: float) -> void:
	enemy_data = enemy
	elapsed = current_elapsed
	active = true
	queue_redraw()


# 用途：更新敵人的受傷閃爍生命週期。
func _process(delta: float) -> void:
	if not active or enemy_data.is_empty():
		return
	enemy_data.hit_flash = max(0.0, float(enemy_data.get("hit_flash", 0.0)) - delta)
	queue_redraw()


# 用途：套用傷害、擊退與死亡判定。
func apply_damage(damage: int, direction: Vector2) -> void:
	if not active or enemy_data.is_empty():
		return
	enemy_data.hp -= damage
	enemy_data.hit_flash = 0.12
	enemy_data.pos += direction * 8.0
	damaged.emit(enemy_data, damage)
	if enemy_data.hp <= 0:
		active = false
		died.emit(enemy_data)


# 用途：讓一般追擊型敵人朝玩家位置移動。
func chase_player(player_position: Vector2, delta: float) -> void:
	if not active or enemy_data.is_empty():
		return
	var to_player: Vector2 = player_position - enemy_data.pos
	if to_player.is_zero_approx():
		return
	enemy_data.pos += to_player.normalized() * float(enemy_data.speed) * delta
	queue_redraw()


# 用途：更新遠程敵人的距離控制與射擊節奏。
func update_spitter(player_position: Vector2, delta: float) -> void:
	if not active or enemy_data.is_empty():
		return
	enemy_data.shoot_cd = max(0.0, float(enemy_data.shoot_cd) - delta)
	var to_player: Vector2 = player_position - enemy_data.pos
	if to_player.is_zero_approx():
		return
	var distance: float = to_player.length()
	if distance >= Constants.SPITTER_ACTIVE_RANGE:
		return
	var direction := to_player.normalized()
	if distance < Constants.SPITTER_RETREAT_DISTANCE:
		enemy_data.pos -= direction * float(enemy_data.speed) * Constants.SPITTER_RETREAT_SPEED_SCALE * delta
	if enemy_data.shoot_cd <= 0.0:
		shot_requested.emit(enemy_data, direction)
	queue_redraw()


# 用途：更新 Boss 與玩家之間的距離控制與散射節奏。
func update_boss_position(player_position: Vector2, delta: float) -> Vector2:
	if not active or enemy_data.is_empty():
		return Vector2.ZERO
	enemy_data.shoot_cd = max(0.0, float(enemy_data.shoot_cd) - delta)
	var to_player: Vector2 = player_position - enemy_data.pos
	if to_player.is_zero_approx():
		return Vector2.ZERO
	var distance: float = to_player.length()
	if distance >= Constants.BOSS_ACTIVE_RANGE:
		return to_player.normalized()
	var direction := to_player.normalized()
	if distance < Constants.BOSS_RETREAT_DISTANCE:
		enemy_data.pos -= direction * float(enemy_data.speed) * Constants.BOSS_RETREAT_SPEED_SCALE * delta
	elif distance > Constants.BOSS_APPROACH_DISTANCE:
		enemy_data.pos += direction * float(enemy_data.speed) * delta
	if enemy_data.shoot_cd <= 0.0:
		spread_shot_requested.emit(enemy_data, direction, Constants.BOSS_SPREAD_COUNT, Constants.BOSS_SPREAD_ANGLE)
	queue_redraw()
	return direction


# 用途：設定遠程敵人下一次射擊前的等待時間。
func set_shoot_cooldown(cooldown: float) -> void:
	if enemy_data.is_empty():
		return
	enemy_data.shoot_cd = cooldown


# 用途：繪製敵人目前外觀。
func _draw() -> void:
	if enemy_data.is_empty():
		return
	CombatRenderer.draw_enemies(self, [enemy_data], elapsed, Constants.ENEMY_RADIUS)

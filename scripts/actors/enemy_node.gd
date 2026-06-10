extends Node2D

const Constants := preload("res://scripts/core/constants.gd")
const CombatRenderer := preload("res://scripts/rendering/combat_renderer.gd")

signal damaged(enemy: Dictionary, damage: int)
signal died(enemy: Dictionary)

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


# 用途：繪製敵人目前外觀。
func _draw() -> void:
	if enemy_data.is_empty():
		return
	CombatRenderer.draw_enemies(self, [enemy_data], elapsed, Constants.ENEMY_RADIUS)

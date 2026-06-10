extends Node2D

const Constants := preload("res://scripts/core/constants.gd")
const CombatRenderer := preload("res://scripts/rendering/combat_renderer.gd")

var enemy_data: Dictionary = {}
var elapsed := 0.0


# 用途：接收目前敵人資料，讓敵人節點自行繪製視覺。
func sync_from_model(enemy: Dictionary, current_elapsed: float) -> void:
	enemy_data = enemy
	elapsed = current_elapsed
	queue_redraw()


# 用途：繪製敵人目前外觀。
func _draw() -> void:
	if enemy_data.is_empty():
		return
	CombatRenderer.draw_enemies(self, [enemy_data], elapsed, Constants.ENEMY_RADIUS)

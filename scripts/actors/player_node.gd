extends Node2D

const Constants := preload("res://scripts/core/constants.gd")
const CombatRenderer := preload("res://scripts/rendering/combat_renderer.gd")

var player_data: Dictionary = {}
var enemies_data: Array = []
var touch_axis := Vector2.ZERO
var damage_flash := 0.0


# 用途：接收目前玩家資料，讓玩家節點自行繪製視覺。
func sync_from_model(player: Dictionary, enemies: Array, current_touch_axis: Vector2, current_damage_flash: float) -> void:
	player_data = player
	enemies_data = enemies
	touch_axis = current_touch_axis
	damage_flash = current_damage_flash
	queue_redraw()


# 用途：繪製玩家目前外觀。
func _draw() -> void:
	if player_data.is_empty():
		return
	CombatRenderer.draw_player(self, player_data, enemies_data, touch_axis, damage_flash, Constants.PLAYER_RADIUS)

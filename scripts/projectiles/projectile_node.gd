extends Node2D

const CombatRenderer := preload("res://scripts/rendering/combat_renderer.gd")

var projectile_data: Dictionary = {}
var projectile_kind := "player_arrow"


# 用途：接收目前投射物資料，讓投射物節點自行繪製視覺。
func sync_from_model(projectile: Dictionary, kind: String) -> void:
	projectile_data = projectile
	projectile_kind = kind
	queue_redraw()


# 用途：依投射物種類繪製玩家箭矢或敵方子彈。
func _draw() -> void:
	if projectile_data.is_empty():
		return
	if projectile_kind == "enemy_shot":
		CombatRenderer.draw_enemy_shots(self, [projectile_data])
	else:
		CombatRenderer.draw_arrows(self, [projectile_data])

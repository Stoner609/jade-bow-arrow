extends Node2D

const CombatRenderer := preload("res://scripts/rendering/combat_renderer.gd")

signal expired(projectile: Dictionary)

var projectile_data: Dictionary = {}
var projectile_kind := "player_arrow"
var active := false


# 用途：接收目前投射物資料，讓投射物節點自行繪製視覺。
func sync_from_model(projectile: Dictionary, kind: String) -> void:
	projectile_data = projectile
	projectile_kind = kind
	active = true
	queue_redraw()


# 用途：更新投射物飛行位置與生命週期，並將結果寫回資料模型。
func _process(delta: float) -> void:
	if not active or projectile_data.is_empty():
		return
	projectile_data.pos += projectile_data.vel * delta
	projectile_data.life -= delta
	if projectile_data.life <= 0.0:
		expired.emit(projectile_data)
	queue_redraw()


# 用途：直接改變投射物速度，供彈射等規則使用。
func set_velocity(velocity: Vector2) -> void:
	if projectile_data.is_empty():
		return
	projectile_data.vel = velocity
	queue_redraw()


# 用途：依投射物種類繪製玩家箭矢或敵方子彈。
func _draw() -> void:
	if projectile_data.is_empty():
		return
	if projectile_kind == "enemy_shot":
		CombatRenderer.draw_enemy_shots(self, [projectile_data])
	else:
		CombatRenderer.draw_arrows(self, [projectile_data])

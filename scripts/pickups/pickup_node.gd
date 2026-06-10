extends Node2D

const Constants := preload("res://scripts/core/constants.gd")
const PickupModel := preload("res://scripts/pickups/pickup.gd")

signal picked(pickup: Dictionary)

var pickup_data: Dictionary = {}
var player_position := Vector2.ZERO
var active := false


# 用途：接收目前拾取物資料，讓拾取物節點自行繪製視覺。
func sync_from_model(pickup: Dictionary) -> void:
	pickup_data = pickup
	active = true
	queue_redraw()


# 用途：更新玩家位置，供吸附與拾取判定使用。
func set_player_position(position: Vector2) -> void:
	player_position = position


# 用途：更新拾取物吸附行為，抵達玩家後發出拾取訊號。
func _process(_delta: float) -> void:
	if not active or pickup_data.is_empty():
		return
	if pickup_data.pos.distance_to(player_position) <= 135.0:
		pickup_data.pos = pickup_data.pos.move_toward(player_position, 7.0)
		if pickup_data.pos.distance_to(player_position) <= Constants.PLAYER_RADIUS + Constants.PICKUP_RADIUS:
			picked.emit(pickup_data)
	queue_redraw()


# 用途：繪製 XP 與回血拾取物，以及它們的外圈光暈。
func _draw() -> void:
	if pickup_data.is_empty():
		return
	var color: Color = PickupModel.color_for(pickup_data.kind)
	draw_circle(pickup_data.pos, Constants.PICKUP_RADIUS, color)
	draw_circle(pickup_data.pos, Constants.PICKUP_RADIUS + 4.0, Color(color.r, color.g, color.b, 0.2))

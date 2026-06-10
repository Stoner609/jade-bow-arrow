extends Node2D

const Constants := preload("res://scripts/core/constants.gd")
const PickupModel := preload("res://scripts/pickups/pickup.gd")

var pickup_data: Dictionary = {}


# 用途：接收目前拾取物資料，讓拾取物節點自行繪製視覺。
func sync_from_model(pickup: Dictionary) -> void:
	pickup_data = pickup
	queue_redraw()


# 用途：繪製 XP 與回血拾取物，以及它們的外圈光暈。
func _draw() -> void:
	if pickup_data.is_empty():
		return
	var color: Color = PickupModel.color_for(pickup_data.kind)
	draw_circle(pickup_data.pos, Constants.PICKUP_RADIUS, color)
	draw_circle(pickup_data.pos, Constants.PICKUP_RADIUS + 4.0, Color(color.r, color.g, color.b, 0.2))

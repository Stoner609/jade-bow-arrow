extends RefCounted

const EnemyModel := preload("res://scripts/actors/enemy.gd")


# 用途：繪製清場後的傳送門發光、旋轉光圈與方向提示。
static func draw_gate(canvas: CanvasItem, gate: Vector2, elapsed: float, gate_radius: float) -> void:
	var pulse: float = sin(elapsed * 5.4) * 5.0
	canvas.draw_circle(gate, gate_radius + 18.0 + pulse, Color(0.24, 1.0, 0.92, 0.13))
	canvas.draw_circle(gate, gate_radius + 7.0 + pulse * 0.6, Color(0.13, 0.92, 1.0, 0.24))
	canvas.draw_circle(gate, 28.0, Color(0.08, 0.42, 1.0))
	canvas.draw_circle(gate, 18.0, Color(0.12, 0.76, 1.0))
	canvas.draw_arc(gate, 42.0, elapsed * 2.0, elapsed * 2.0 + PI * 1.35, 48, Color(0.78, 1.0, 0.96), 5.0)
	canvas.draw_arc(gate, 31.0, -elapsed * 2.4, -elapsed * 2.4 + PI * 1.2, 48, Color(1.0, 0.92, 0.28), 3.0)
	var arrow := PackedVector2Array([
		gate + Vector2(0, -17),
		gate + Vector2(16, 2),
		gate + Vector2(6, 2),
		gate + Vector2(6, 18),
		gate + Vector2(-6, 18),
		gate + Vector2(-6, 2),
		gate + Vector2(-16, 2)
	])
	canvas.draw_colored_polygon(arrow, Color(0.96, 1.0, 0.72, 0.92))


# 用途：繪製玩家箭矢，使用高亮金色與尾跡提高辨識度。
static func draw_arrows(canvas: CanvasItem, arrows: Array) -> void:
	for arrow in arrows:
		var dir: Vector2 = arrow.vel.normalized()
		canvas.draw_line(arrow.pos - dir * 22.0, arrow.pos + dir * 14.0, Color(0.1, 0.08, 0.02, 0.65), 8.0)
		canvas.draw_line(arrow.pos - dir * 22.0, arrow.pos + dir * 14.0, Color(1.0, 0.86, 0.12), 5.0)
		canvas.draw_line(arrow.pos - dir * 28.0, arrow.pos - dir * 10.0, Color(1.0, 0.96, 0.48, 0.28), 9.0)
		canvas.draw_circle(arrow.pos + dir * 15.0, 5.5, Color(1.0, 1.0, 0.78))


# 用途：繪製敵方子彈，使用紫紅色外圈與高亮核心區分玩家箭矢。
static func draw_enemy_shots(canvas: CanvasItem, enemy_shots: Array) -> void:
	for shot in enemy_shots:
		canvas.draw_circle(shot.pos, 16.0, Color(1.0, 0.18, 0.82, 0.18))
		canvas.draw_circle(shot.pos, 10.0, Color(0.08, 0.02, 0.12, 0.8))
		canvas.draw_circle(shot.pos, 7.0, Color(1.0, 0.16, 0.78))
		canvas.draw_circle(shot.pos + Vector2(-2, -2), 3.0, Color(1.0, 0.76, 1.0))


# 用途：繪製敵人外觀、眼睛與生命條。
static func draw_enemies(canvas: CanvasItem, enemies: Array, elapsed: float, default_radius: float) -> void:
	for enemy in enemies:
		var color: Color = EnemyModel.color_for(enemy.kind)
		var radius: float = enemy.get("radius", default_radius)
		var body_color: Color = Color(1.0, 0.96, 0.72) if float(enemy.get("hit_flash", 0.0)) > 0.0 else color
		canvas.draw_circle(enemy.pos, radius + 7.0, Color(color.r, color.g, color.b, 0.22))
		_draw_enemy_body(canvas, enemy.kind, enemy.pos, radius, body_color, elapsed)
		canvas.draw_circle(enemy.pos + Vector2(-radius * 0.32, -radius * 0.25), 3.4, Color(0.03, 0.03, 0.03))
		canvas.draw_circle(enemy.pos + Vector2(radius * 0.32, -radius * 0.25), 3.4, Color(0.03, 0.03, 0.03))
		var bar_width: float = 72.0 if enemy.kind == "boss" else 48.0
		var bar := Rect2(enemy.pos + Vector2(-bar_width * 0.5, -radius - 16), Vector2(bar_width, 6))
		canvas.draw_rect(bar, Color(0.12, 0.12, 0.12))
		canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * max(0.0, float(enemy.hp) / float(enemy.max_hp)), bar.size.y)), Color(0.26, 1.0, 0.2))


# 用途：繪製 Boss 專用大血條，讓玩家不用只看場上的小血條。
static func draw_boss_health(canvas: CanvasItem, enemies: Array) -> void:
	var boss: Dictionary = _boss_enemy(enemies)
	if boss.is_empty():
		return
	var ratio: float = clampf(float(boss.hp) / float(boss.max_hp), 0.0, 1.0)
	var bar := Rect2(Vector2(74, 104), Vector2(392, 16))
	canvas.draw_rect(bar.grow(5.0), Color(0.03, 0.02, 0.02, 0.78))
	canvas.draw_rect(bar, Color(0.16, 0.05, 0.06))
	canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.92, 0.12, 0.14))
	canvas.draw_rect(bar, Color(1.0, 0.78, 0.36, 0.9), false, 2.0)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(76, 98), "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.86, 0.48))


# 用途：繪製玩家角色、武器線條、朝向標記與受傷閃爍效果。
static func draw_player(canvas: CanvasItem, player: Dictionary, enemies: Array, touch_axis: Vector2, damage_flash: float, player_radius: float) -> void:
	var flash_alpha: float = min(1.0, damage_flash / 0.18)
	var body_color: Color = Color(1.0, 0.92, 0.9) if damage_flash > 0.0 else Color(0.18, 0.42, 0.92)
	var facing: Vector2 = _player_facing_direction(player, enemies, touch_axis)
	var side: Vector2 = facing.orthogonal()
	canvas.draw_circle(player.pos, player_radius + 9.0 + flash_alpha * 8.0, Color(1.0, 0.12, 0.08, 0.18 * flash_alpha))
	canvas.draw_circle(player.pos, player_radius + 7.0, Color(0.2, 0.8, 1.0, 0.24))
	canvas.draw_circle(player.pos, player_radius + 2.0, Color(0.8, 0.96, 1.0))
	canvas.draw_circle(player.pos, player_radius, body_color)
	canvas.draw_circle(player.pos + facing * 14.0 + side * 4.0, 7.0, Color(0.96, 0.82, 0.58))
	canvas.draw_line(player.pos - side * 12.0 + facing * 2.0, player.pos + side * 12.0 + facing * 2.0, Color(0.92, 0.82, 0.28), 4.0)
	var marker := PackedVector2Array([
		player.pos + facing * 28.0,
		player.pos + facing * 14.0 + side * 8.0,
		player.pos + facing * 14.0 - side * 8.0
	])
	canvas.draw_colored_polygon(marker, Color(1.0, 0.88, 0.18))
	if damage_flash > 0.0:
		canvas.draw_arc(player.pos, player_radius + 17.0, 0.0, TAU, 48, Color(1.0, 0.16, 0.08, 0.9 * flash_alpha), 4.0)


# 用途：依敵人種類繪製不同輪廓，提升手機小畫面上的辨識度。
static func _draw_enemy_body(canvas: CanvasItem, kind: String, pos: Vector2, radius: float, color: Color, elapsed: float) -> void:
	var outline := Color(0.06, 0.04, 0.04, 0.82)
	if kind == "runner":
		var points := PackedVector2Array([
			pos + Vector2(0, -radius - 4.0),
			pos + Vector2(radius + 5.0, 0),
			pos + Vector2(0, radius + 4.0),
			pos + Vector2(-radius - 5.0, 0)
		])
		canvas.draw_colored_polygon(_scaled_polygon(points, pos, 1.12), outline)
		canvas.draw_colored_polygon(points, color)
		canvas.draw_line(pos + Vector2(-radius * 0.55, radius * 0.35), pos + Vector2(radius * 0.55, radius * 0.35), Color(1.0, 0.78, 0.28), 3.0)
	elif kind == "spitter":
		canvas.draw_colored_polygon(_regular_polygon_points(pos, radius + 4.0, 6, PI / 6.0), outline)
		canvas.draw_colored_polygon(_regular_polygon_points(pos, radius, 6, PI / 6.0), color)
		canvas.draw_circle(pos + Vector2(0, radius * 0.2), radius * 0.28, Color(0.1, 0.02, 0.16))
	elif kind == "brute":
		var outer := Rect2(pos - Vector2(radius + 5.0, radius + 5.0), Vector2(radius * 2.0 + 10.0, radius * 2.0 + 10.0))
		var inner := Rect2(pos - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
		canvas.draw_rect(outer, outline)
		canvas.draw_rect(inner, color)
		canvas.draw_line(inner.position + Vector2(5, inner.size.y - 7), inner.end - Vector2(5, 7), Color(0.64, 1.0, 0.48), 3.0)
	elif kind == "boss":
		canvas.draw_colored_polygon(_regular_polygon_points(pos, radius + 6.0, 8, PI / 8.0), outline)
		canvas.draw_colored_polygon(_regular_polygon_points(pos, radius, 8, PI / 8.0), color)
		canvas.draw_arc(pos, radius + 11.0, elapsed * 1.6, elapsed * 1.6 + PI * 1.4, 48, Color(1.0, 0.28, 0.24, 0.8), 4.0)
		canvas.draw_line(pos + Vector2(-radius * 0.55, radius * 0.32), pos + Vector2(radius * 0.55, radius * 0.32), Color(0.06, 0.01, 0.02), 4.0)
	else:
		canvas.draw_circle(pos, radius + 4.0, outline)
		canvas.draw_circle(pos, radius, color)
		canvas.draw_arc(pos, radius * 0.7, 0.15, PI - 0.15, 24, Color(1.0, 0.62, 0.36), 3.0)


# 用途：取得目前場上的 Boss 資料，沒有 Boss 時回傳空字典。
static func _boss_enemy(enemies: Array) -> Dictionary:
	for enemy in enemies:
		if enemy.kind == "boss":
			return enemy
	return {}


# 用途：取得玩家視覺朝向，優先朝最近敵人，其次使用搖桿方向。
static func _player_facing_direction(player: Dictionary, enemies: Array, touch_axis: Vector2) -> Vector2:
	var target: int = _nearest_enemy_to(player.pos, enemies)
	if target != -1:
		return (enemies[target].pos - player.pos).normalized()
	if touch_axis.length() > 0.05:
		return touch_axis.normalized()
	return Vector2(0, -1)


# 用途：取得距離指定位置最近的敵人索引。
static func _nearest_enemy_to(pos: Vector2, enemies: Array) -> int:
	var best: int = -1
	var best_distance: float = INF
	for i in enemies.size():
		var distance: float = pos.distance_squared_to(enemies[i].pos)
		if distance < best_distance:
			best = i
			best_distance = distance
	return best


# 用途：建立以中心點為基準的正多邊形點位。
static func _regular_polygon_points(center: Vector2, radius: float, sides: int, rotation: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		var angle: float = rotation + TAU * float(i) / float(sides)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


# 用途：將多邊形點位從中心等比例放大，常用於繪製外框。
static func _scaled_polygon(points: PackedVector2Array, center: Vector2, scale: float) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for point in points:
		scaled.append(center + (point - center) * scale)
	return scaled

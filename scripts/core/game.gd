extends Node2D

const Constants := preload("res://scripts/core/constants.gd")
const PlayerModel := preload("res://scripts/actors/player.gd")
const EnemyModel := preload("res://scripts/actors/enemy.gd")
const ArrowModel := preload("res://scripts/projectiles/arrow.gd")
const EnemyShotModel := preload("res://scripts/projectiles/enemy_shot.gd")
const PickupModel := preload("res://scripts/pickups/pickup.gd")
const RoomManager := preload("res://scripts/rooms/room_manager.gd")
const HudPresenter := preload("res://scripts/ui/hud_presenter.gd")
const UpgradeCatalog := preload("res://scripts/ui/upgrade_catalog.gd")
const TouchControls := preload("res://scripts/ui/touch_controls.gd")
const CollisionUtils := preload("res://scripts/utils/collision_utils.gd")

enum Mode { PLAYING, UPGRADE, DEAD, WON }

@onready var hud: Label = $CanvasLayer/HUD
@onready var log_label: Label = $CanvasLayer/Log
@onready var help_label: Label = $CanvasLayer/Help

var rng := RandomNumberGenerator.new()
var mode := Mode.PLAYING
var room_index := 1
var wave_index := 0
var total_waves := 1
var wave_break_timer := 0.0
var elapsed := 0.0
var room_clear := false
var fire_timer := 0.0
var damage_flash := 0.0
var upgrade_choices: Array = []
var messages: Array[String] = []

var player: Dictionary = PlayerModel.create()

var enemies: Array = []
var arrows: Array = []
var enemy_shots: Array = []
var pickups: Array = []
var floating_texts: Array = []
var obstacles: Array[Rect2] = []
var touch_axis := Vector2.ZERO
var joystick_touch_index := -1


# 用途：初始化隨機數、說明文字，並開始一局新遊戲。
func _ready() -> void:
	rng.randomize()
	help_label.text = "Drag joystick: Move\nStop to auto-fire\nR: Restart"
	_new_run()


# 用途：每一幀更新遊戲狀態，包括玩家、敵人、投射物、拾取物與畫面刷新。
func _process(delta: float) -> void:
	if mode != Mode.PLAYING:
		damage_flash = max(0.0, damage_flash - delta)
		_update_floating_texts(delta)
		queue_redraw()
		return

	elapsed += delta
	damage_flash = max(0.0, damage_flash - delta)
	_update_player(delta)
	_update_arrows(delta)
	_update_enemy_shots(delta)
	_update_enemies(delta)
	_update_pickups()
	_update_floating_texts(delta)
	_update_wave_flow(delta)
	_check_room_clear()
	_refresh()


# 用途：處理重新開始與升級選項等不由移動軸直接處理的按鍵輸入。
func _unhandled_input(event: InputEvent) -> void:
	if _handle_touch_input(event):
		return

	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action_pressed("restart_run"):
		_new_run()
		return

	if mode == Mode.UPGRADE:
		if event is InputEventKey:
			if event.keycode == KEY_1:
				_take_upgrade(0)
			elif event.keycode == KEY_2:
				_take_upgrade(1)
			elif event.keycode == KEY_3:
				_take_upgrade(2)


# 用途：處理手機觸控輸入，包括虛擬搖桿拖曳與升級卡片點選。
func _handle_touch_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if mode == Mode.UPGRADE:
				for i in upgrade_choices.size():
					if _upgrade_card_rect(i).has_point(touch.position):
						_take_upgrade(i)
						return true
			if touch.position.distance_to(Constants.JOYSTICK_CENTER) <= Constants.JOYSTICK_RADIUS * 1.65:
				joystick_touch_index = touch.index
				touch_axis = _joystick_axis(touch.position)
				return true
		elif touch.index == joystick_touch_index:
			joystick_touch_index = -1
			touch_axis = Vector2.ZERO
			return true
	elif event is InputEventScreenDrag and event.index == joystick_touch_index:
		touch_axis = _joystick_axis(event.position)
		return true
	return false


# 用途：依序繪製背景、房間、物件、角色、敵人、特效與覆蓋介面。
func _draw() -> void:
	_draw_background()
	_draw_arena()
	_draw_gate()
	_draw_pickups()
	_draw_arrows()
	_draw_enemy_shots()
	_draw_enemies()
	_draw_player()
	_draw_floating_texts()
	_draw_touch_controls()
	_draw_overlay()


# 用途：重設玩家能力與關卡狀態，開始一輪新的遊戲流程。
func _new_run() -> void:
	mode = Mode.PLAYING
	room_index = 1
	wave_index = 0
	total_waves = 1
	wave_break_timer = 0.0
	elapsed = 0.0
	fire_timer = 0.0
	damage_flash = 0.0
	room_clear = false
	enemies.clear()
	arrows.clear()
	enemy_shots.clear()
	pickups.clear()
	floating_texts.clear()
	messages.clear()
	touch_axis = Vector2.ZERO
	joystick_touch_index = -1
	PlayerModel.reset(player, _player_start_position())
	_spawn_room()
	_log("Clear the room. Stop moving to auto-fire.")
	_refresh()


# 用途：建立目前房間的障礙物、敵人與戰鬥狀態。
func _spawn_room() -> void:
	room_clear = false
	enemies.clear()
	arrows.clear()
	enemy_shots.clear()
	pickups.clear()
	wave_break_timer = 0.0
	_generate_obstacles()
	total_waves = RoomManager.wave_count(room_index, Constants.MAX_ROOMS)
	wave_index = 0
	_start_next_wave()


# 用途：產生目前房間的下一波敵人。
func _start_next_wave() -> void:
	wave_index += 1
	var wave: Array[String] = RoomManager.enemy_wave(room_index, wave_index, Constants.MAX_ROOMS)
	for kind in wave:
		_spawn_enemy(kind)
	if room_index >= Constants.MAX_ROOMS:
		_log("Final room. Defeat the boss.")
	else:
		_log("Room %d/%d - Wave %d/%d." % [room_index, Constants.MAX_ROOMS, wave_index, total_waves])


# 用途：依照房間編號產生不同配置的場地障礙物。
func _generate_obstacles() -> void:
	obstacles = RoomManager.obstacle_layout(room_index, Constants.ARENA)


# 用途：依敵人類型建立敵人的生命、速度、傷害與初始位置。
func _spawn_enemy(kind: String) -> void:
	enemies.append(EnemyModel.create(kind, room_index, _random_spawn_position(), rng))


# 用途：尋找遠離玩家且不在障礙物內的敵人出生位置。
func _random_spawn_position() -> Vector2:
	for attempt in 120:
		var pos := Vector2(
			rng.randf_range(Constants.ARENA.position.x + 48, Constants.ARENA.end.x - 48),
			rng.randf_range(Constants.ARENA.position.y + 44, Constants.ARENA.end.y - 130)
		)
		if pos.distance_to(player.pos) > 260.0 and not _point_in_obstacle(pos, Constants.ENEMY_RADIUS):
			return pos
	return Constants.ARENA.get_center() + Vector2(rng.randf_range(-170, 170), rng.randf_range(-250, -80))


# 用途：更新玩家移動、停止時自動射擊，以及進入清場傳送門的判定。
func _update_player(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_axis.length() > direction.length():
		direction = touch_axis
	if direction.length() > 0.05:
		player.pos += direction.normalized() * float(player.speed) * delta
		player.pos = _clamp_to_arena(player.pos, Constants.PLAYER_RADIUS)
		player.pos = _push_out_of_obstacles(player.pos, Constants.PLAYER_RADIUS)
		fire_timer = min(fire_timer, float(player.fire_rate) * 0.45)
	elif enemies.size() > 0:
		fire_timer -= delta
		if fire_timer <= 0.0:
			_fire_at_nearest_enemy()
			fire_timer = float(player.fire_rate)

	if room_clear and player.pos.distance_to(_gate_position()) <= Constants.GATE_RADIUS:
		_advance_room()


# 用途：尋找最近敵人並依玩家箭矢數量、散射角度發射箭矢。
func _fire_at_nearest_enemy() -> void:
	var target := _nearest_enemy()
	if target == -1:
		return

	var base_dir: Vector2 = (enemies[target].pos - player.pos).normalized()
	var spread := 0.16
	var count: int = player.arrows
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = (float(i) - float(count - 1) * 0.5) * spread
		var dir := base_dir.rotated(offset)
		arrows.append(ArrowModel.create(player.pos, dir, int(player.power), int(player.pierce)))


# 用途：更新玩家箭矢飛行、碰撞、穿透、彈射與命中傷害。
func _update_arrows(delta: float) -> void:
	for i in range(arrows.size() - 1, -1, -1):
		var arrow: Dictionary = arrows[i]
		arrow.pos += arrow.vel * delta
		arrow.life -= delta

		if not Constants.ARENA.has_point(arrow.pos) or _point_in_obstacle(arrow.pos, Constants.ARROW_RADIUS) or arrow.life <= 0.0:
			arrows.remove_at(i)
			continue

		var hit: int = _enemy_hit_by(arrow.pos, Constants.ARROW_RADIUS)
		if hit == -1:
			continue

		_damage_enemy(hit, int(arrow.damage), arrow.vel.normalized())
		if arrow.pierce_left > 0:
			arrow.pierce_left -= 1
		elif player.ricochet and not arrow.ricocheted:
			var next: int = _nearest_enemy_to(arrow.pos, hit)
			if next != -1:
				var dir: Vector2 = (enemies[next].pos - arrow.pos).normalized()
				arrow.vel = dir * 585.0
				arrow.ricocheted = true
			else:
				arrows.remove_at(i)
		else:
			arrows.remove_at(i)


# 用途：更新敵人追擊、遠程敵人射擊、碰撞玩家與受阻位置修正。
func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		enemy.hit_cd = max(0.0, float(enemy.hit_cd) - delta)
		enemy.shoot_cd = max(0.0, float(enemy.shoot_cd) - delta)

		var to_player: Vector2 = player.pos - enemy.pos
		var distance: float = to_player.length()
		if enemy.kind == "boss" and distance < 620.0:
			if distance < 300.0:
				enemy.pos -= to_player.normalized() * float(enemy.speed) * 0.35 * delta
			elif distance > 420.0:
				enemy.pos += to_player.normalized() * float(enemy.speed) * delta
			if enemy.shoot_cd <= 0.0:
				_fire_enemy_spread(enemy.pos, to_player.normalized(), 5, 0.22)
				enemy.shoot_cd = rng.randf_range(1.0, 1.35)
		elif enemy.kind == "spitter" and distance < 520.0:
			if distance < 220.0:
				enemy.pos -= to_player.normalized() * float(enemy.speed) * 0.7 * delta
			if enemy.shoot_cd <= 0.0:
				_fire_enemy_shot(enemy.pos, to_player.normalized())
				enemy.shoot_cd = rng.randf_range(1.25, 1.9)
		else:
			enemy.pos += to_player.normalized() * float(enemy.speed) * delta

		var radius: float = enemy.get("radius", Constants.ENEMY_RADIUS)
		enemy.pos = _clamp_to_arena(enemy.pos, radius)
		enemy.pos = _push_out_of_obstacles(enemy.pos, radius)

		if distance <= Constants.PLAYER_RADIUS + radius + 2.0 and enemy.hit_cd <= 0.0:
			_damage_player(int(enemy.touch))
			enemy.hit_cd = 0.75


# 用途：從指定位置朝指定方向產生敵人的遠程子彈。
func _fire_enemy_shot(origin: Vector2, direction: Vector2) -> void:
	enemy_shots.append(EnemyShotModel.create(origin, direction, room_index))


# 用途：讓 Boss 或特殊敵人一次發射多顆散射子彈。
func _fire_enemy_spread(origin: Vector2, direction: Vector2, count: int, spread: float) -> void:
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = (float(i) - float(count - 1) * 0.5) * spread
		_fire_enemy_shot(origin, direction.rotated(offset))


# 用途：更新敵人子彈飛行、撞牆消失與命中玩家傷害。
func _update_enemy_shots(delta: float) -> void:
	for i in range(enemy_shots.size() - 1, -1, -1):
		var shot: Dictionary = enemy_shots[i]
		shot.pos += shot.vel * delta
		shot.life -= delta

		if not Constants.ARENA.has_point(shot.pos) or _point_in_obstacle(shot.pos, 7.0) or shot.life <= 0.0:
			enemy_shots.remove_at(i)
			continue

		if shot.pos.distance_to(player.pos) <= Constants.PLAYER_RADIUS + 7.0:
			_damage_player(int(shot.damage))
			enemy_shots.remove_at(i)


# 用途：對指定敵人造成傷害，處理擊退、傷害文字、死亡掉落。
func _damage_enemy(index: int, damage: int, direction: Vector2) -> void:
	var enemy: Dictionary = enemies[index]
	enemy.hp -= damage
	enemy.pos += direction * 8.0
	floating_texts.append({"pos": enemy.pos + Vector2(-12, -24), "text": str(damage), "color": Color(1.0, 0.9, 0.22), "life": 0.65})
	if enemy.hp <= 0:
		var xp_value: int = 24 if enemy.kind == "boss" else 4 + room_index
		var drop_pos: Vector2 = enemy.pos
		enemies.remove_at(index)
		pickups.append(PickupModel.xp(drop_pos, xp_value))
		if enemy.kind == "boss":
			pickups.append(PickupModel.heart(drop_pos + Vector2(20, 12), 28))
		elif rng.randf() < 0.16:
			pickups.append(PickupModel.heart(drop_pos + Vector2(rng.randf_range(-18, 18), rng.randf_range(-18, 18)), 12))


# 用途：扣除玩家生命、顯示受傷效果，並在生命歸零時結束遊戲。
func _damage_player(damage: int) -> void:
	player.hp = max(0, int(player.hp) - damage)
	damage_flash = 0.18
	floating_texts.append({"pos": player.pos + Vector2(-18, -32), "text": "-%d" % damage, "color": Color(1.0, 0.2, 0.16), "life": 0.72})
	if player.hp <= 0:
		mode = Mode.DEAD
		_log("You were overwhelmed. Press R to restart.")


# 用途：處理拾取物靠近玩家時吸附、取得 XP 或回血的效果。
func _update_pickups() -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var pickup: Dictionary = pickups[i]
		if pickup.pos.distance_to(player.pos) > 135.0:
			continue
		pickup.pos = pickup.pos.move_toward(player.pos, 7.0)
		if pickup.pos.distance_to(player.pos) <= Constants.PLAYER_RADIUS + Constants.PICKUP_RADIUS:
			if pickup.kind == "xp":
				_gain_xp(int(pickup.value))
			else:
				player.hp = min(int(player.max_hp), int(player.hp) + int(pickup.value))
				floating_texts.append({"pos": player.pos + Vector2(-18, -36), "text": "+%d" % int(pickup.value), "color": Color(0.25, 1.0, 0.45), "life": 0.72})
			pickups.remove_at(i)


# 用途：增加玩家經驗值，達成需求時升級並進入能力選擇。
func _gain_xp(amount: int) -> void:
	player.xp += amount
	var needed: int = _xp_needed()
	if player.xp >= needed:
		player.xp -= needed
		player.level += 1
		_roll_upgrades()


# 用途：隨機產生三個升級選項並暫停戰鬥等待玩家選擇。
func _roll_upgrades() -> void:
	mode = Mode.UPGRADE
	upgrade_choices = UpgradeCatalog.choices()
	upgrade_choices.shuffle()
	upgrade_choices = upgrade_choices.slice(0, 3)
	_log("Level up. Choose an upgrade with 1, 2, or 3.")


# 用途：套用玩家選擇的升級效果，並恢復戰鬥狀態。
func _take_upgrade(index: int) -> void:
	if index < 0 or index >= upgrade_choices.size():
		return

	var upgrade: Dictionary = upgrade_choices[index]
	PlayerModel.apply_upgrade(player, upgrade.stat)
	_log("Upgrade: %s." % upgrade.name)
	upgrade_choices.clear()
	mode = Mode.PLAYING


# 用途：確認房間敵人是否全滅，並在清場後開啟傳送門。
func _check_room_clear() -> void:
	if room_clear or enemies.size() > 0:
		return
	if wave_index < total_waves:
		if wave_break_timer <= 0.0:
			wave_break_timer = 1.15
			arrows.clear()
			enemy_shots.clear()
			_log("Wave clear. Next wave incoming.")
		return
	room_clear = true
	arrows.clear()
	enemy_shots.clear()
	_log("Room clear. Enter the glowing gate.")


# 用途：處理波次之間的短暫間隔，倒數結束後生成下一波敵人。
func _update_wave_flow(delta: float) -> void:
	if wave_break_timer <= 0.0 or enemies.size() > 0 or room_clear:
		return
	wave_break_timer -= delta
	if wave_break_timer <= 0.0 and wave_index < total_waves:
		_start_next_wave()


# 用途：玩家進入傳送門後推進到下一房，或在最後房間通關。
func _advance_room() -> void:
	if room_index >= Constants.MAX_ROOMS:
		mode = Mode.WON
		_log("Chapter cleared. Press R for another run.")
		return
	room_index += 1
	var room_heal := 16 if room_index == Constants.MAX_ROOMS else 10
	player.hp = min(int(player.max_hp), int(player.hp) + room_heal)
	player.pos = _player_start_position()
	_spawn_room()
	_log("Room %d/%d. Keep moving between shots." % [room_index, Constants.MAX_ROOMS])


# 用途：取得距離玩家最近的敵人索引。
func _nearest_enemy() -> int:
	return _nearest_enemy_to(player.pos, -1)


# 用途：取得距離指定位置最近的敵人索引，可排除某個敵人。
func _nearest_enemy_to(pos: Vector2, ignored: int) -> int:
	var best: int = -1
	var best_distance: float = INF
	for i in enemies.size():
		if i == ignored:
			continue
		var distance: float = pos.distance_squared_to(enemies[i].pos)
		if distance < best_distance:
			best = i
			best_distance = distance
	return best


# 用途：檢查指定圓形範圍是否命中敵人，回傳命中的敵人索引。
func _enemy_hit_by(pos: Vector2, radius: float) -> int:
	for i in enemies.size():
		var enemy_radius: float = enemies[i].get("radius", Constants.ENEMY_RADIUS)
		if pos.distance_to(enemies[i].pos) <= radius + enemy_radius:
			return i
	return -1


# 用途：將指定位置限制在房間邊界內，並保留半徑距離。
func _clamp_to_arena(pos: Vector2, radius: float) -> Vector2:
	return CollisionUtils.clamp_to_rect(pos, Constants.ARENA, radius)


# 用途：當圓形物件進入障礙物時，將它推回最近的可通行位置。
func _push_out_of_obstacles(pos: Vector2, radius: float) -> Vector2:
	return CollisionUtils.push_out_of_rects(pos, radius, obstacles, Constants.ARENA)


# 用途：判斷指定位置與半徑是否和任何障礙物重疊。
func _point_in_obstacle(pos: Vector2, radius: float) -> bool:
	return CollisionUtils.circle_overlaps_any_rect(pos, radius, obstacles)


# 用途：取得清場後傳送門應該出現的位置。
func _gate_position() -> Vector2:
	return RoomManager.gate_position(Constants.ARENA)


# 用途：取得每個房間開始時玩家的直式版起點位置。
func _player_start_position() -> Vector2:
	return RoomManager.player_start_position(Constants.ARENA)


# 用途：將觸控位置轉換成虛擬搖桿的方向向量。
func _joystick_axis(touch_position: Vector2) -> Vector2:
	return TouchControls.joystick_axis(touch_position, Constants.JOYSTICK_CENTER, Constants.JOYSTICK_RADIUS)


# 用途：取得直式升級選單中指定卡片的位置與大小。
func _upgrade_card_rect(index: int) -> Rect2:
	return Rect2(Vector2(54, 292 + index * 136), Vector2(432, 112))


# 用途：計算玩家目前等級升到下一級所需的經驗值。
func _xp_needed() -> int:
	return 14 + int(player.level) * 8


# 用途：更新傷害與回血浮動文字的位置與生命週期。
func _update_floating_texts(delta: float) -> void:
	for i in range(floating_texts.size() - 1, -1, -1):
		floating_texts[i].pos += Vector2(0, -34) * delta
		floating_texts[i].life -= delta
		if floating_texts[i].life <= 0.0:
			floating_texts.remove_at(i)


# 用途：更新 HUD、訊息紀錄文字，並要求畫面重新繪製。
func _refresh() -> void:
	var xp_needed: int = _xp_needed()
	hud.text = HudPresenter.hud_text(room_index, Constants.MAX_ROOMS, wave_index, total_waves, player, xp_needed)
	log_label.text = HudPresenter.recent_messages(messages, 3)
	queue_redraw()


# 用途：加入一筆遊戲訊息，並限制訊息紀錄的最大筆數。
func _log(text: String) -> void:
	messages.append(text)
	if messages.size() > 6:
		messages.pop_front()


# 用途：繪製整體背景與淡色棋盤格紋理。
func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, Constants.VIEW_SIZE), Color(0.06, 0.09, 0.12))
	for y in range(0, int(Constants.VIEW_SIZE.y), 52):
		for x in range(0, int(Constants.VIEW_SIZE.x), 52):
			var cell_x: int = floori(float(x) / 52.0)
			var cell_y: int = floori(float(y) / 52.0)
			var tint: float = 0.015 if (cell_x + cell_y) % 2 == 0 else 0.0
			draw_rect(Rect2(Vector2(x, y), Vector2(52, 52)), Color(0.07 + tint, 0.19 + tint, 0.18 + tint))


# 用途：繪製戰鬥房間、地板格紋、邊框與障礙物。
func _draw_arena() -> void:
	draw_rect(Constants.ARENA.grow(20), Color(0.11, 0.31, 0.27))
	draw_rect(Constants.ARENA, Color(0.11, 0.72, 0.65))
	for y in range(int(Constants.ARENA.position.y), int(Constants.ARENA.end.y), 64):
		for x in range(int(Constants.ARENA.position.x), int(Constants.ARENA.end.x), 64):
			var cell_x: int = floori(float(x) / 64.0)
			var cell_y: int = floori(float(y) / 64.0)
			var tint: float = 0.025 if (cell_x + cell_y) % 2 == 0 else 0.0
			draw_rect(Rect2(Vector2(x, y), Vector2(64, 64)), Color(0.12 + tint, 0.76 + tint, 0.69 + tint))
	draw_rect(Constants.ARENA, Color(0.72, 0.95, 0.88), false, 4.0)
	for obstacle in obstacles:
		draw_rect(obstacle, Color(0.82, 0.85, 0.82))
		draw_rect(obstacle.grow(-6), Color(0.18, 0.22, 0.22))


# 用途：在房間清場後繪製可進入下一房的發光傳送門。
func _draw_gate() -> void:
	if not room_clear:
		return
	var gate := _gate_position()
	draw_circle(gate, Constants.GATE_RADIUS + sin(elapsed * 5.0) * 4.0, Color(0.13, 0.92, 1.0, 0.22))
	draw_circle(gate, 24.0, Color(0.08, 0.42, 1.0))
	draw_arc(gate, 34.0, 0.0, TAU, 48, Color(0.62, 1.0, 1.0), 4.0)


# 用途：繪製 XP 與回血拾取物，以及它們的外圈光暈。
func _draw_pickups() -> void:
	for pickup in pickups:
		var color: Color = PickupModel.color_for(pickup.kind)
		draw_circle(pickup.pos, Constants.PICKUP_RADIUS, color)
		draw_circle(pickup.pos, Constants.PICKUP_RADIUS + 4.0, Color(color.r, color.g, color.b, 0.2))


# 用途：繪製玩家射出的箭矢與箭頭亮點。
func _draw_arrows() -> void:
	for arrow in arrows:
		var dir: Vector2 = arrow.vel.normalized()
		draw_line(arrow.pos - dir * 18.0, arrow.pos + dir * 13.0, Color(1.0, 0.92, 0.2), 5.0)
		draw_circle(arrow.pos + dir * 14.0, 5.0, Color(1.0, 1.0, 0.76))


# 用途：繪製敵人的遠程子彈與光暈。
func _draw_enemy_shots() -> void:
	for shot in enemy_shots:
		draw_circle(shot.pos, 8.0, Color(0.76, 0.24, 1.0))
		draw_circle(shot.pos, 14.0, Color(0.76, 0.24, 1.0, 0.18))


# 用途：繪製敵人外觀、眼睛與生命條。
func _draw_enemies() -> void:
	for enemy in enemies:
		var color: Color = EnemyModel.color_for(enemy.kind)
		var radius: float = enemy.get("radius", Constants.ENEMY_RADIUS)
		draw_circle(enemy.pos, radius + 5.0, Color(color.r, color.g, color.b, 0.22))
		draw_circle(enemy.pos, radius, color)
		draw_circle(enemy.pos + Vector2(-radius * 0.32, -radius * 0.25), 3.0, Color(0.05, 0.05, 0.05))
		draw_circle(enemy.pos + Vector2(radius * 0.32, -radius * 0.25), 3.0, Color(0.05, 0.05, 0.05))
		var bar_width := 72.0 if enemy.kind == "boss" else 48.0
		var bar := Rect2(enemy.pos + Vector2(-bar_width * 0.5, -radius - 16), Vector2(bar_width, 6))
		draw_rect(bar, Color(0.12, 0.12, 0.12))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * max(0.0, float(enemy.hp) / float(enemy.max_hp)), bar.size.y)), Color(0.26, 1.0, 0.2))


# 用途：繪製玩家角色、武器線條與受傷閃爍效果。
func _draw_player() -> void:
	draw_circle(player.pos, Constants.PLAYER_RADIUS + 7.0, Color(0.2, 0.8, 1.0, 0.22))
	draw_circle(player.pos, Constants.PLAYER_RADIUS, Color(0.18, 0.42, 0.92))
	draw_circle(player.pos + Vector2(6, -13), 8.0, Color(0.96, 0.82, 0.58))
	draw_line(player.pos + Vector2(-11, 0), player.pos + Vector2(12, -3), Color(0.92, 0.82, 0.28), 4.0)
	if damage_flash > 0.0:
		draw_circle(player.pos, Constants.PLAYER_RADIUS + 13.0, Color(1.0, 0.1, 0.06, 0.28))


# 用途：繪製手機直式版左下角虛擬搖桿。
func _draw_touch_controls() -> void:
	if mode != Mode.PLAYING:
		return
	var knob_position := Constants.JOYSTICK_CENTER + touch_axis.limit_length(1.0) * Constants.JOYSTICK_RADIUS
	draw_circle(Constants.JOYSTICK_CENTER, Constants.JOYSTICK_RADIUS, Color(0.85, 0.9, 0.88, 0.18))
	draw_arc(Constants.JOYSTICK_CENTER, Constants.JOYSTICK_RADIUS, 0.0, TAU, 48, Color(0.8, 0.95, 0.92, 0.38), 3.0)
	draw_circle(knob_position, Constants.JOYSTICK_KNOB_RADIUS, Color(0.1, 0.48, 0.95, 0.72))
	draw_circle(knob_position, Constants.JOYSTICK_KNOB_RADIUS + 7.0, Color(0.15, 0.75, 1.0, 0.18))


# 用途：繪製傷害、回血等浮動數字文字。
func _draw_floating_texts() -> void:
	for text in floating_texts:
		draw_string(ThemeDB.fallback_font, text.pos, text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, text.color)


# 用途：繪製升級選擇、死亡與通關時的覆蓋介面。
func _draw_overlay() -> void:
	if mode == Mode.UPGRADE:
		draw_rect(Rect2(Vector2.ZERO, Constants.VIEW_SIZE), Color(0.02, 0.03, 0.04, 0.72))
		draw_string(ThemeDB.fallback_font, Vector2(124, 232), "Choose an ability", HORIZONTAL_ALIGNMENT_LEFT, -1, 31, Color(0.95, 0.96, 0.88))
		for i in upgrade_choices.size():
			var card := _upgrade_card_rect(i)
			draw_rect(card, Color(0.11, 0.16, 0.18))
			draw_rect(card, Color(0.54, 0.9, 0.82), false, 3.0)
			draw_string(ThemeDB.fallback_font, card.position + Vector2(20, 42), "%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color(1.0, 0.86, 0.22))
			draw_string(ThemeDB.fallback_font, card.position + Vector2(72, 42), upgrade_choices[i].name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.95, 0.96, 0.88))
			draw_string(ThemeDB.fallback_font, card.position + Vector2(72, 78), upgrade_choices[i].desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.76, 0.82, 0.78))
	elif mode == Mode.DEAD or mode == Mode.WON:
		draw_rect(Rect2(Vector2.ZERO, Constants.VIEW_SIZE), Color(0.02, 0.03, 0.04, 0.74))
		var title := "Chapter cleared" if mode == Mode.WON else "Run failed"
		draw_string(ThemeDB.fallback_font, Vector2(144, 392), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(0.95, 0.96, 0.88))
		draw_string(ThemeDB.fallback_font, Vector2(130, 442), "Press R to start a new run.", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.76, 0.82, 0.78))

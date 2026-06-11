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
const CombatRenderer := preload("res://scripts/rendering/combat_renderer.gd")
const PlayerScene := preload("res://scenes/actors/Player.tscn")
const EnemyScene := preload("res://scenes/actors/Enemy.tscn")
const ProjectileScene := preload("res://scenes/projectiles/Projectile.tscn")
const PickupScene := preload("res://scenes/pickups/Pickup.tscn")

enum Mode { START, PLAYING, UPGRADE, PAUSED, DEAD, WON }

@onready var world_layer: Node2D = $World
@onready var pickup_layer: Node2D = $World/PickupLayer
@onready var projectile_layer: Node2D = $World/ProjectileLayer
@onready var enemy_layer: Node2D = $World/EnemyLayer
@onready var player_layer: Node2D = $World/PlayerLayer
@onready var hud_view: CanvasLayer = $HUD

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
var muted := false
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
var joystick_center := Constants.JOYSTICK_CENTER
var joystick_active := false
var joystick_touch_index := -1
var player_node: Node2D


# 用途：初始化隨機數、說明文字，並開始一局新遊戲。
func _ready() -> void:
	rng.randomize()
	player_node = PlayerScene.instantiate()
	player_layer.add_child(player_node)
	_connect_hud_signals()
	hud_view.set_help_text("Drag joystick: Move\nStop to auto-fire\nR: Restart")
	_show_start_screen()


# 用途：每一幀更新遊戲狀態，包括玩家、敵人、投射物、拾取物與畫面刷新。
func _process(delta: float) -> void:
	if mode != Mode.PLAYING:
		damage_flash = max(0.0, damage_flash - delta)
		_update_floating_texts(delta)
		_refresh()
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
		_start_run()
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
			if mode == Mode.PLAYING and Constants.JOYSTICK_TOUCH_ZONE.has_point(touch.position):
				joystick_touch_index = touch.index
				joystick_center = touch.position
				joystick_active = true
				touch_axis = Vector2.ZERO
				return true
		elif touch.index == joystick_touch_index:
			joystick_touch_index = -1
			joystick_center = Constants.JOYSTICK_CENTER
			joystick_active = false
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
	_draw_floating_texts()
	_draw_touch_controls()


# 用途：連接 HUD 場景按鈕訊號到遊戲流程。
func _connect_hud_signals() -> void:
	hud_view.start_requested.connect(_start_run)
	hud_view.pause_requested.connect(_pause_game)
	hud_view.resume_requested.connect(_resume_game)
	hud_view.restart_requested.connect(_start_run)
	hud_view.menu_requested.connect(_show_start_screen)
	hud_view.sound_toggle_requested.connect(_toggle_sound)
	hud_view.upgrade_selected.connect(_take_upgrade)


# 用途：建立敵人的場景節點，讓視覺呈現在 scene tree 中。
func _create_enemy_node(enemy: Dictionary) -> Node2D:
	var node := EnemyScene.instantiate() as Node2D
	enemy_layer.add_child(node)
	node.sync_from_model(enemy, elapsed)
	node.damaged.connect(_on_enemy_damaged)
	node.died.connect(_on_enemy_died)
	node.shot_requested.connect(_on_enemy_shot_requested)
	node.spread_shot_requested.connect(_on_enemy_spread_shot_requested)
	return node


# 用途：接收敵人節點受傷事件，顯示傷害數字。
func _on_enemy_damaged(enemy: Dictionary, damage: int) -> void:
	var is_crit: bool = bool(enemy.get("last_hit_crit", false))
	var text := "CRIT %d" % damage if is_crit else str(damage)
	var color := Color(1.0, 0.38, 0.12) if is_crit else Color(1.0, 0.9, 0.22)
	var size := 30 if is_crit else 22
	var life := 0.82 if is_crit else 0.65
	var velocity := Vector2(0, -50) if is_crit else Vector2(0, -34)
	floating_texts.append({"pos": enemy.pos + Vector2(-18, -28), "text": text, "color": color, "life": life, "size": size, "velocity": velocity, "shadow": true})


# 用途：接收敵人節點死亡事件，移除資料並產生掉落。
func _on_enemy_died(enemy: Dictionary) -> void:
	if not enemies.has(enemy):
		return
	var xp_value: int = 24 if enemy.kind == "boss" else 4 + room_index
	var drop_pos: Vector2 = enemy.pos
	_free_entity_node(enemy)
	enemies.erase(enemy)
	_spawn_pickup(PickupModel.xp(drop_pos, xp_value))
	if enemy.kind == "boss":
		_spawn_pickup(PickupModel.heart(drop_pos + Vector2(20, 12), 28))
	elif rng.randf() < 0.16:
		_spawn_pickup(PickupModel.heart(drop_pos + Vector2(rng.randf_range(-18, 18), rng.randf_range(-18, 18)), 12))


# 用途：接收敵人節點的射擊請求，建立敵方投射物並重設冷卻。
func _on_enemy_shot_requested(enemy: Dictionary, direction: Vector2) -> void:
	if not enemies.has(enemy):
		return
	_fire_enemy_shot(enemy.pos, direction)
	if enemy.has("node") and is_instance_valid(enemy.node):
		enemy.node.set_shoot_cooldown(rng.randf_range(Constants.SPITTER_SHOOT_COOLDOWN_MIN, Constants.SPITTER_SHOOT_COOLDOWN_MAX))


# 用途：接收 Boss 節點的散射請求，建立多顆敵方投射物並重設冷卻。
func _on_enemy_spread_shot_requested(enemy: Dictionary, direction: Vector2, count: int, spread: float) -> void:
	if not enemies.has(enemy):
		return
	_fire_enemy_spread(enemy.pos, direction, count, spread)
	if enemy.has("node") and is_instance_valid(enemy.node):
		enemy.node.set_shoot_cooldown(rng.randf_range(Constants.BOSS_SHOOT_COOLDOWN_MIN, Constants.BOSS_SHOOT_COOLDOWN_MAX))


# 用途：建立玩家或敵方投射物的場景節點。
func _create_projectile_node(projectile: Dictionary, kind: String) -> Node2D:
	var node := ProjectileScene.instantiate() as Node2D
	projectile_layer.add_child(node)
	node.sync_from_model(projectile, kind)
	node.expired.connect(_on_projectile_expired)
	return node


# 用途：接收投射物節點生命週期結束事件，並從資料陣列移除。
func _on_projectile_expired(projectile: Dictionary) -> void:
	if _remove_projectile_from(arrows, projectile):
		return
	_remove_projectile_from(enemy_shots, projectile)


# 用途：從指定投射物陣列移除同一筆資料與節點。
func _remove_projectile_from(projectiles: Array, projectile: Dictionary) -> bool:
	for i in range(projectiles.size() - 1, -1, -1):
		if projectiles[i] == projectile:
			_free_entity_node(projectiles[i])
			projectiles.remove_at(i)
			return true
	return false


# 用途：建立拾取物資料與對應的場景節點。
func _spawn_pickup(pickup: Dictionary) -> void:
	pickup["node"] = _create_pickup_node(pickup)
	pickups.append(pickup)


# 用途：建立拾取物的場景節點。
func _create_pickup_node(pickup: Dictionary) -> Node2D:
	var node := PickupScene.instantiate() as Node2D
	pickup_layer.add_child(node)
	node.sync_from_model(pickup)
	node.set_player_position(player.pos)
	node.picked.connect(_on_pickup_picked)
	return node


# 用途：接收拾取物節點抵達玩家事件，套用獎勵並移除資料。
func _on_pickup_picked(pickup: Dictionary) -> void:
	if not pickups.has(pickup):
		return
	if pickup.kind == "xp":
		_gain_xp(int(pickup.value))
	else:
		player.hp = min(int(player.max_hp), int(player.hp) + int(pickup.value))
		floating_texts.append({"pos": player.pos + Vector2(-18, -36), "text": "+%d" % int(pickup.value), "color": Color(0.25, 1.0, 0.45), "life": 0.72})
	_free_entity_node(pickup)
	pickups.erase(pickup)


# 用途：同步目前資料模型到已建立的場景節點。
func _sync_scene_nodes() -> void:
	world_layer.visible = mode == Mode.PLAYING
	if is_instance_valid(player_node):
		player_node.sync_from_model(player, enemies, touch_axis, damage_flash)
	for enemy in enemies:
		if not enemy.has("node") or not is_instance_valid(enemy.node):
			enemy["node"] = _create_enemy_node(enemy)
		enemy.node.sync_from_model(enemy, elapsed)
	for arrow in arrows:
		if not arrow.has("node") or not is_instance_valid(arrow.node):
			arrow["node"] = _create_projectile_node(arrow, "player_arrow")
		arrow.node.sync_from_model(arrow, "player_arrow")
	for shot in enemy_shots:
		if not shot.has("node") or not is_instance_valid(shot.node):
			shot["node"] = _create_projectile_node(shot, "enemy_shot")
		shot.node.sync_from_model(shot, "enemy_shot")
	for pickup in pickups:
		if not pickup.has("node") or not is_instance_valid(pickup.node):
			pickup["node"] = _create_pickup_node(pickup)
		pickup.node.set_player_position(player.pos)
		pickup.node.sync_from_model(pickup)


# 用途：釋放指定資料物件綁定的場景節點。
func _free_entity_node(entity: Dictionary) -> void:
	if entity.has("node") and is_instance_valid(entity.node):
		entity.node.queue_free()
	entity.erase("node")


# 用途：清空指定節點容器底下所有子節點。
func _clear_layer_nodes(layer: Node) -> void:
	for child in layer.get_children():
		child.queue_free()


# 用途：清空所有戰鬥物件節點，但保留玩家節點。
func _clear_combat_nodes() -> void:
	_clear_layer_nodes(enemy_layer)
	_clear_layer_nodes(projectile_layer)
	_clear_layer_nodes(pickup_layer)


# 用途：清空玩家與敵人的投射物節點。
func _clear_projectile_nodes() -> void:
	_clear_layer_nodes(projectile_layer)


# 用途：重設玩家能力與關卡狀態，開始一輪新的遊戲流程。
func _new_run() -> void:
	_start_run()


# 用途：顯示開始畫面並清空目前戰鬥狀態。
func _show_start_screen() -> void:
	mode = Mode.START
	room_index = 1
	wave_index = 0
	total_waves = 1
	wave_break_timer = 0.0
	elapsed = 0.0
	fire_timer = 0.0
	damage_flash = 0.0
	room_clear = false
	_clear_combat_nodes()
	enemies.clear()
	arrows.clear()
	enemy_shots.clear()
	pickups.clear()
	floating_texts.clear()
	messages.clear()
	touch_axis = Vector2.ZERO
	joystick_center = Constants.JOYSTICK_CENTER
	joystick_active = false
	joystick_touch_index = -1
	PlayerModel.reset(player, _player_start_position())
	_refresh()


# 用途：重設玩家與關卡，正式開始一輪遊戲。
func _start_run() -> void:
	mode = Mode.PLAYING
	room_index = clamp(Constants.DEBUG_START_ROOM, 1, Constants.MAX_ROOMS)
	wave_index = 0
	total_waves = 1
	wave_break_timer = 0.0
	elapsed = 0.0
	fire_timer = 0.0
	damage_flash = 0.0
	room_clear = false
	_clear_combat_nodes()
	enemies.clear()
	arrows.clear()
	enemy_shots.clear()
	pickups.clear()
	floating_texts.clear()
	messages.clear()
	touch_axis = Vector2.ZERO
	joystick_center = Constants.JOYSTICK_CENTER
	joystick_active = false
	joystick_touch_index = -1
	PlayerModel.reset(player, _player_start_position())
	_spawn_room()
	_refresh()


# 用途：建立目前房間的障礙物、敵人與戰鬥狀態。
func _spawn_room() -> void:
	room_clear = false
	_clear_combat_nodes()
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
	_log(RoomManager.room_message(room_index, wave_index, Constants.MAX_ROOMS))


# 用途：依照房間編號產生不同配置的場地障礙物。
func _generate_obstacles() -> void:
	obstacles = RoomManager.obstacle_layout(room_index, Constants.ARENA)


# 用途：依敵人類型建立敵人的生命、速度、傷害與初始位置。
func _spawn_enemy(kind: String) -> void:
	var enemy := EnemyModel.create(kind, room_index, _random_spawn_position(), rng)
	enemy["node"] = _create_enemy_node(enemy)
	enemies.append(enemy)


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
		var damage := int(player.power)
		var is_crit: bool = rng.randf() < float(player.get("crit_chance", 0.0))
		if is_crit:
			damage = int(round(float(damage) * float(player.get("crit_multiplier", 1.5))))
		var arrow := ArrowModel.create(player.pos, dir, damage, int(player.pierce))
		arrow["crit"] = is_crit
		arrow["node"] = _create_projectile_node(arrow, "player_arrow")
		arrows.append(arrow)


# 用途：更新玩家箭矢飛行、碰撞、穿透、彈射與命中傷害。
func _update_arrows(_delta: float) -> void:
	for i in range(arrows.size() - 1, -1, -1):
		var arrow: Dictionary = arrows[i]

		if not Constants.ARENA.has_point(arrow.pos) or _point_in_obstacle(arrow.pos, Constants.ARROW_RADIUS):
			_free_entity_node(arrow)
			arrows.remove_at(i)
			continue

		var hit: int = _enemy_hit_by(arrow.pos, Constants.ARROW_RADIUS)
		if hit == -1:
			continue

		enemies[hit]["pending_hit_crit"] = bool(arrow.get("crit", false))
		_damage_enemy(hit, int(arrow.damage), arrow.vel.normalized())
		if arrow.pierce_left > 0:
			arrow.pierce_left -= 1
		elif player.ricochet and not arrow.ricocheted:
			var next: int = _nearest_enemy_to(arrow.pos, hit)
			if next != -1:
				var dir: Vector2 = (enemies[next].pos - arrow.pos).normalized()
				arrow.vel = dir * 585.0
				arrow.ricocheted = true
				if arrow.has("node") and is_instance_valid(arrow.node):
					arrow.node.set_velocity(arrow.vel)
			else:
				_free_entity_node(arrow)
				arrows.remove_at(i)
		else:
			_free_entity_node(arrow)
			arrows.remove_at(i)


# 用途：更新敵人追擊、遠程敵人射擊、碰撞玩家與受阻位置修正。
func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		enemy.hit_cd = max(0.0, float(enemy.hit_cd) - delta)
		var has_enemy_node: bool = enemy.has("node") and is_instance_valid(enemy.node)
		if enemy.kind != "spitter" and not (enemy.kind == "boss" and has_enemy_node):
			enemy.shoot_cd = max(0.0, float(enemy.shoot_cd) - delta)

		var to_player: Vector2 = player.pos - enemy.pos
		var distance: float = to_player.length()
		if enemy.kind == "boss" and distance < Constants.BOSS_ACTIVE_RANGE:
			var shot_direction := to_player.normalized()
			if has_enemy_node:
				shot_direction = enemy.node.update_boss_position(player.pos, delta)
			else:
				if distance < Constants.BOSS_RETREAT_DISTANCE:
					enemy.pos -= shot_direction * float(enemy.speed) * Constants.BOSS_RETREAT_SPEED_SCALE * delta
				elif distance > Constants.BOSS_APPROACH_DISTANCE:
					enemy.pos += shot_direction * float(enemy.speed) * delta
			if not has_enemy_node and enemy.shoot_cd <= 0.0:
				_fire_enemy_spread(enemy.pos, shot_direction, Constants.BOSS_SPREAD_COUNT, Constants.BOSS_SPREAD_ANGLE)
				enemy.shoot_cd = rng.randf_range(Constants.BOSS_SHOOT_COOLDOWN_MIN, Constants.BOSS_SHOOT_COOLDOWN_MAX)
		elif enemy.kind == "spitter":
			if has_enemy_node:
				enemy.node.update_spitter(player.pos, delta)
			elif distance < Constants.SPITTER_ACTIVE_RANGE:
				if distance < Constants.SPITTER_RETREAT_DISTANCE:
					enemy.pos -= to_player.normalized() * float(enemy.speed) * Constants.SPITTER_RETREAT_SPEED_SCALE * delta
				if enemy.shoot_cd <= 0.0:
					_fire_enemy_shot(enemy.pos, to_player.normalized())
					enemy.shoot_cd = rng.randf_range(Constants.SPITTER_SHOOT_COOLDOWN_MIN, Constants.SPITTER_SHOOT_COOLDOWN_MAX)
		else:
			if has_enemy_node:
				enemy.node.chase_player(player.pos, delta)
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
	var shot := EnemyShotModel.create(origin, direction, room_index)
	shot["node"] = _create_projectile_node(shot, "enemy_shot")
	enemy_shots.append(shot)


# 用途：讓 Boss 或特殊敵人一次發射多顆散射子彈。
func _fire_enemy_spread(origin: Vector2, direction: Vector2, count: int, spread: float) -> void:
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = (float(i) - float(count - 1) * 0.5) * spread
		_fire_enemy_shot(origin, direction.rotated(offset))


# 用途：更新敵人子彈飛行、撞牆消失與命中玩家傷害。
func _update_enemy_shots(_delta: float) -> void:
	for i in range(enemy_shots.size() - 1, -1, -1):
		var shot: Dictionary = enemy_shots[i]

		if not Constants.ARENA.has_point(shot.pos) or _point_in_obstacle(shot.pos, 7.0):
			_free_entity_node(shot)
			enemy_shots.remove_at(i)
			continue

		if shot.pos.distance_to(player.pos) <= Constants.PLAYER_RADIUS + 7.0:
			_damage_player(int(shot.damage))
			_free_entity_node(shot)
			enemy_shots.remove_at(i)


# 用途：將傷害委派給敵人節點，節點負責生命、受傷閃爍與死亡訊號。
func _damage_enemy(index: int, damage: int, direction: Vector2) -> void:
	var enemy: Dictionary = enemies[index]
	enemy["last_hit_crit"] = bool(enemy.get("pending_hit_crit", false))
	enemy.erase("pending_hit_crit")
	if enemy.kind == "boss":
		damage = int(round(float(damage) * (1.0 + float(player.get("boss_damage_bonus", 0.0)))))
	if enemy.has("node") and is_instance_valid(enemy.node):
		enemy.node.apply_damage(damage, direction)
	_apply_lifesteal(damage)


# 用途：依玩家吸血比例把命中傷害轉成少量回復。
func _apply_lifesteal(damage: int) -> void:
	var rate := float(player.get("lifesteal", 0.0))
	if rate <= 0.0 or player.hp >= player.max_hp:
		return
	var heal := int(floor(float(damage) * rate))
	if heal <= 0:
		return
	player.hp = min(int(player.max_hp), int(player.hp) + heal)
	floating_texts.append({"pos": player.pos + Vector2(-18, -48), "text": "+%d" % heal, "color": Color(0.2, 1.0, 0.52), "life": 0.78, "size": 26, "velocity": Vector2(0, -28), "shadow": true})


# 用途：扣除玩家生命、顯示受傷效果，並在生命歸零時結束遊戲。
func _damage_player(damage: int) -> void:
	player.hp = max(0, int(player.hp) - damage)
	damage_flash = 0.18
	floating_texts.append({"pos": player.pos + Vector2(-18, -32), "text": "-%d" % damage, "color": Color(1.0, 0.2, 0.16), "life": 0.72})
	if player.hp <= 0:
		mode = Mode.DEAD
		touch_axis = Vector2.ZERO
		joystick_active = false
		joystick_touch_index = -1
		_log("You were overwhelmed. Press R to restart.")


# 用途：更新拾取物節點需要的玩家位置，吸附與拾取由 Pickup node 處理。
func _update_pickups() -> void:
	for pickup in pickups:
		if pickup.has("node") and is_instance_valid(pickup.node):
			pickup.node.set_player_position(player.pos)


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
	upgrade_choices = UpgradeCatalog.choices(rng, 3, player)
	_log("Level up. Choose an upgrade with 1, 2, or 3.")


# 用途：套用玩家選擇的升級效果，並恢復戰鬥狀態。
func _take_upgrade(index: int) -> void:
	if index < 0 or index >= upgrade_choices.size():
		return

	var upgrade: Dictionary = upgrade_choices[index]
	UpgradeCatalog.apply_upgrade(player, upgrade)
	_log("Upgrade: %s." % upgrade.name)
	upgrade_choices.clear()
	mode = Mode.PLAYING


# 用途：進入暫停狀態並停止觸控搖桿輸入。
func _pause_game() -> void:
	if mode != Mode.PLAYING:
		return
	mode = Mode.PAUSED
	touch_axis = Vector2.ZERO
	joystick_center = Constants.JOYSTICK_CENTER
	joystick_active = false
	joystick_touch_index = -1
	_log("Paused.")


# 用途：從暫停狀態回到遊戲。
func _resume_game() -> void:
	if mode == Mode.PAUSED:
		mode = Mode.PLAYING
		_log("Resume.")


# 用途：切換音效開關狀態，之後加入音效時可接到 AudioServer。
func _toggle_sound() -> void:
	muted = not muted
	_log("Sound Off." if muted else "Sound On.")


# 用途：確認房間敵人是否全滅，並在清場後開啟傳送門。
func _check_room_clear() -> void:
	if room_clear or enemies.size() > 0:
		return
	if wave_index < total_waves:
			if wave_break_timer <= 0.0:
				wave_break_timer = 1.15
				_clear_projectile_nodes()
				arrows.clear()
				enemy_shots.clear()
				_log("Wave clear. Next wave incoming.")
			return
	room_clear = true
	_clear_projectile_nodes()
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
	return TouchControls.joystick_axis(touch_position, joystick_center, Constants.JOYSTICK_RADIUS)


# 用途：計算玩家目前等級升到下一級所需的經驗值。
func _xp_needed() -> int:
	return 14 + int(player.level) * 8


# 用途：更新傷害與回血浮動文字的位置與生命週期。
func _update_floating_texts(delta: float) -> void:
	for i in range(floating_texts.size() - 1, -1, -1):
		floating_texts[i].pos += floating_texts[i].get("velocity", Vector2(0, -34)) * delta
		floating_texts[i].life -= delta
		if floating_texts[i].life <= 0.0:
			floating_texts.remove_at(i)


# 用途：更新 HUD、訊息紀錄文字，並要求畫面重新繪製。
func _refresh() -> void:
	_sync_scene_nodes()
	hud_view.set_mode(mode, muted, upgrade_choices)
	if mode == Mode.START:
		hud_view.set_hud_text("")
		hud_view.set_log_text("")
		queue_redraw()
		return
	var xp_needed: int = _xp_needed()
	hud_view.set_hud_text(HudPresenter.hud_text(room_index, Constants.MAX_ROOMS, wave_index, total_waves, player, xp_needed))
	hud_view.set_log_text(HudPresenter.recent_messages(messages, 3))
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
			var tile_rect := Rect2(Vector2(x, y), Vector2(64, 64)).intersection(Constants.ARENA)
			draw_rect(tile_rect, Color(0.12 + tint, 0.76 + tint, 0.69 + tint))
	draw_rect(Constants.ARENA, Color(0.72, 0.95, 0.88), false, 4.0)
	for obstacle in obstacles:
		draw_rect(obstacle, Color(0.82, 0.85, 0.82))
		draw_rect(obstacle.grow(-6), Color(0.18, 0.22, 0.22))


# 用途：在房間清場後繪製可進入下一房的發光傳送門。
func _draw_gate() -> void:
	if not room_clear:
		return
	CombatRenderer.draw_gate(self, _gate_position(), elapsed, Constants.GATE_RADIUS)


# 用途：繪製手機直式版左下角虛擬搖桿。
func _draw_touch_controls() -> void:
	if mode != Mode.PLAYING:
		return
	var center := joystick_center if joystick_active else Constants.JOYSTICK_CENTER
	var knob_position := center + touch_axis.limit_length(1.0) * Constants.JOYSTICK_RADIUS
	var base_alpha := 0.28 if joystick_active else 0.12
	var ring_alpha := 0.5 if joystick_active else 0.24
	draw_circle(center, Constants.JOYSTICK_RADIUS, Color(0.85, 0.9, 0.88, base_alpha))
	draw_arc(center, Constants.JOYSTICK_RADIUS, 0.0, TAU, 48, Color(0.8, 0.95, 0.92, ring_alpha), 3.0)
	draw_circle(knob_position, Constants.JOYSTICK_KNOB_RADIUS, Color(0.1, 0.48, 0.95, 0.78))
	draw_circle(knob_position, Constants.JOYSTICK_KNOB_RADIUS + 7.0, Color(0.15, 0.75, 1.0, 0.18))


# 用途：繪製傷害、回血等浮動數字文字。
func _draw_floating_texts() -> void:
	for text in floating_texts:
		var size: int = int(text.get("size", 22))
		if bool(text.get("shadow", false)):
			draw_string(ThemeDB.fallback_font, text.pos + Vector2(2, 2), text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.45))
		draw_string(ThemeDB.fallback_font, text.pos, text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, text.color)

extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://Main.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame

	if game.get_script() == null:
		push_error("Game script failed to load.")
		quit(1)
		return
	if not "mode" in game:
		push_error("Game controller properties are unavailable.")
		quit(1)
		return
	if game.mode != game.Mode.START:
		push_error("Game did not start on the start screen.")
		quit(1)
		return
	if game.hud_view.pause_button.visible:
		push_error("Pause button should be hidden on the start screen.")
		quit(1)
		return

	game.hud_view.start_requested.emit()
	await process_frame
	if game.mode != game.Mode.PLAYING:
		push_error("HUD start signal did not enter playing mode.")
		quit(1)
		return

	if game.get_node_or_null("World/PlayerLayer") == null or game.get_node_or_null("World/EnemyLayer") == null:
		push_error("World scene node layers are missing.")
		quit(1)
		return
	if game.player_layer.get_child_count() <= 0:
		push_error("Player scene node was not instantiated.")
		quit(1)
		return
	if game.obstacles.is_empty():
		push_error("Room obstacles were not generated.")
		quit(1)
		return
	if game.player.pos == Vector2.ZERO:
		push_error("Player was not placed in the arena.")
		quit(1)
		return
	if game.enemies.is_empty():
		push_error("Enemies were not spawned.")
		quit(1)
		return
	if game.enemy_layer.get_child_count() <= 0:
		push_error("Enemy scene nodes were not instantiated.")
		quit(1)
		return
	if game.total_waves <= 0 or game.wave_index <= 0:
		push_error("Room wave state was not initialized.")
		quit(1)
		return

	game.fire_timer = 0.0
	game._fire_at_nearest_enemy()

	if game.arrows.is_empty():
		push_error("Player did not auto-fire an arrow.")
		quit(1)
		return
	if game.projectile_layer.get_child_count() <= 0:
		push_error("Projectile scene node was not instantiated.")
		quit(1)
		return
	var arrow_start: Vector2 = game.arrows[0].pos
	await process_frame
	if game.arrows.is_empty() or game.arrows[0].pos == arrow_start:
		push_error("Projectile scene node did not advance arrow position.")
		quit(1)
		return
	var xp_before: int = game.player.xp
	game._spawn_pickup(game.PickupModel.xp(game.player.pos + Vector2(24, 0), 3))
	await process_frame
	await process_frame
	if game.player.xp <= xp_before:
		push_error("Pickup scene node did not collect XP.")
		quit(1)
		return
	var chase_enemy: Dictionary = game.enemies[0]
	chase_enemy.kind = "crawler"
	chase_enemy.pos = Vector2(260, 480)
	game.player.pos = Vector2(340, 480)
	var chase_start_x: float = chase_enemy.pos.x
	game._update_enemies(0.1)
	if chase_enemy.pos.x <= chase_start_x:
		push_error("Enemy scene node did not chase the player.")
		quit(1)
		return
	chase_enemy.kind = "spitter"
	chase_enemy.pos = Vector2(260, 480)
	chase_enemy.shoot_cd = 0.0
	game.player.pos = Vector2(430, 480)
	var spitter_start_x: float = chase_enemy.pos.x
	var shot_count_before: int = game.enemy_shots.size()
	game._update_enemies(0.1)
	if chase_enemy.pos.x >= spitter_start_x:
		push_error("Spitter scene node did not keep distance from the player.")
		quit(1)
		return
	if game.enemy_shots.size() <= shot_count_before:
		push_error("Spitter scene node did not request an enemy shot.")
		quit(1)
		return
	var enemy_count_before: int = game.enemies.size()
	var pickup_count_before: int = game.pickups.size()
	game._damage_enemy(0, int(game.enemies[0].max_hp) + 1, Vector2.RIGHT)
	if game.enemies.size() >= enemy_count_before:
		push_error("Enemy node death signal did not remove the enemy.")
		quit(1)
		return
	if game.pickups.size() <= pickup_count_before:
		push_error("Enemy node death signal did not spawn a pickup.")
		quit(1)
		return

	game.hud_view.pause_requested.emit()
	if game.mode != game.Mode.PAUSED:
		push_error("HUD pause signal did not enter paused mode.")
		quit(1)
		return
	game.hud_view.resume_requested.emit()
	if game.mode != game.Mode.PLAYING:
		push_error("HUD resume signal did not return to playing mode.")
		quit(1)
		return

	var original_room: int = game.room_index
	game.enemies.clear()
	game.wave_index = game.total_waves
	game._check_room_clear()
	if not game.room_clear:
		push_error("Room clear state was not detected.")
		quit(1)
		return

	game.player.pos = game._gate_position()
	game._advance_room()
	if game.room_index <= original_room:
		push_error("Gate did not advance to the next room.")
		quit(1)
		return

	game.room_index = game.Constants.MAX_ROOMS
	game._spawn_room()
	if game.total_waves != 1 or game.enemies.is_empty() or game.enemies[0].kind != "boss":
		push_error("Boss room did not spawn the expected boss wave.")
		quit(1)
		return

	game._pause_game()
	if game.mode != game.Mode.PAUSED:
		push_error("Pause did not enter paused mode.")
		quit(1)
		return
	game._resume_game()
	if game.mode != game.Mode.PLAYING:
		push_error("Resume did not return to playing mode.")
		quit(1)
		return
	var was_muted: bool = game.muted
	game._toggle_sound()
	if game.muted == was_muted:
		push_error("Sound toggle did not change muted state.")
		quit(1)
		return
	game._show_start_screen()
	if game.mode != game.Mode.START:
		push_error("Main menu did not return to start mode.")
		quit(1)
		return

	quit(0)

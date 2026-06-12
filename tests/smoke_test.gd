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
	if game.room_index != game.Constants.DEBUG_START_ROOM:
		push_error("Run did not start from the configured debug room.")
		quit(1)
		return

	if game.get_node_or_null("World/PlayerLayer") == null or game.get_node_or_null("World/EnemyLayer") == null:
		push_error("World scene node layers are missing.")
		quit(1)
		return
	var late_wave: Array[String] = game.RoomManager.enemy_wave(7, 2, game.Constants.MAX_ROOMS)
	if late_wave.count("crawler") != 13 or late_wave.count("spitter") != 2 or late_wave.count("runner") != 2 or late_wave.count("brute") != 1:
		push_error("Room wave table did not return the expected late-game composition.")
		quit(1)
		return
	if game.RoomManager.wave_count(game.Constants.MAX_ROOMS, game.Constants.MAX_ROOMS) != 1:
		push_error("Boss room wave count should be data-driven as one wave.")
		quit(1)
		return
	if game.RoomManager.room_message(5, 1, game.Constants.MAX_ROOMS) != "Brutes can take more hits.":
		push_error("Room message should come from room data.")
		quit(1)
		return
	if game.RoomManager.obstacle_layout_for("cross", game.Constants.ARENA).size() != 3:
		push_error("Obstacle layout table did not return the expected cross layout.")
		quit(1)
		return
	if not game.RoomManager.obstacle_layout(game.Constants.MAX_ROOMS, game.Constants.ARENA).is_empty():
		push_error("Boss room layout should be configured without obstacles.")
		quit(1)
		return
	var boss_ai = load("res://scripts/boss/boss_ai.gd")
	for phase in boss_ai.PHASE_ATTACKS.keys():
		for attack in boss_ai.PHASE_ATTACKS[phase]:
			if String(attack.get("kind", "")) == "projectile" and int(attack.get("count", 1)) % 2 == 0:
				push_error("Boss projectile counts should stay odd so center shots can target the player.")
				quit(1)
				return
	var phase_two_sweep: Dictionary = boss_ai.PHASE_ATTACKS[2][1]
	if String(phase_two_sweep.bullet.style) != "sweep" or not phase_two_sweep.has("warning"):
		push_error("Phase 2 sweep should keep its warning and sweep bullet profile.")
		quit(1)
		return
	var upgrades: Array[Dictionary] = game.UpgradeCatalog.choices(game.rng, 3)
	if upgrades.size() != 3 or not upgrades[0].has("effect") or not upgrades[0].has("weight"):
		push_error("Upgrade catalog should return weighted data-driven upgrades.")
		quit(1)
		return
	var upgrade_test_player: Dictionary = game.PlayerModel.create()
	var power_upgrade := {"effect": {"stat": "power", "op": "add", "value": 4}}
	var power_before: int = int(upgrade_test_player.power)
	game.UpgradeCatalog.apply_upgrade(upgrade_test_player, power_upgrade)
	if int(upgrade_test_player.power) != power_before + 4:
		push_error("Upgrade catalog did not apply a stat effect.")
		quit(1)
		return
	var blood_arrow: Dictionary = game.UpgradeCatalog.UPGRADES.filter(func(upgrade: Dictionary) -> bool: return upgrade.id == "blood_arrow")[0]
	if float(blood_arrow.effect.value) > 0.03 or float(blood_arrow.effect.max) > 0.09:
		push_error("Blood Arrow balance values are higher than expected.")
		quit(1)
		return
	upgrade_test_player.arrows = 4
	upgrade_test_player.ricochet = true
	var limited_upgrades: Array[Dictionary] = game.UpgradeCatalog.available_upgrades(upgrade_test_player)
	for upgrade in limited_upgrades:
		if upgrade.id == "twin_arrow" or upgrade.id == "ricochet":
			push_error("Upgrade catalog returned an upgrade blocked by player limits.")
			quit(1)
			return
	game.UpgradeCatalog.apply_upgrade(upgrade_test_player, {"effect": {"stat": "speed", "op": "add", "value": 28, "max": 390}})
	if float(upgrade_test_player.speed) <= 275.0:
		push_error("Move speed upgrade did not apply.")
		quit(1)
		return
	if game.player_layer.get_child_count() <= 0:
		push_error("Player scene node was not instantiated.")
		quit(1)
		return
	if game.room_index < game.Constants.MAX_ROOMS and game.obstacles.is_empty():
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
	if game.enemies.is_empty():
		game._spawn_enemy("crawler")
	var chase_enemy: Dictionary = game.enemies[0]
	if game.enemies.is_empty():
		game._spawn_enemy("crawler")
		chase_enemy = game.enemies[0]
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
	chase_enemy.kind = "boss"
	chase_enemy.pos = Vector2(260, 480)
	chase_enemy.shoot_cd = 10.0
	game.player.pos = Vector2(430, 480)
	var boss_close_x: float = chase_enemy.pos.x
	game._update_enemies(0.1)
	if chase_enemy.pos.x >= boss_close_x:
		push_error("Boss scene node did not retreat when too close.")
		quit(1)
		return
	chase_enemy.pos = Vector2(40, 480)
	game.player.pos = Vector2(460, 480)
	var boss_far_x: float = chase_enemy.pos.x
	game._update_enemies(0.1)
	if chase_enemy.pos.x <= boss_far_x:
		push_error("Boss scene node did not approach when too far.")
		quit(1)
		return
	chase_enemy.pos = Vector2(260, 480)
	chase_enemy.shoot_cd = 0.0
	game.player.pos = Vector2(430, 480)
	var boss_shot_count_before: int = game.enemy_shots.size()
	game._update_enemies(0.1)
	if game.enemy_shots.size() < boss_shot_count_before + game.Constants.BOSS_SPREAD_COUNT:
		push_error("Boss scene node did not request a spread shot.")
		quit(1)
		return
	chase_enemy.hp = int(float(chase_enemy.max_hp) * 0.35)
	chase_enemy.shoot_cd = 0.0
	chase_enemy.pos = Vector2(260, 480)
	game.player.pos = Vector2(430, 480)
	var phase_text_count_before: int = game.floating_texts.size()
	var phase_shot_count_before: int = game.enemy_shots.size()
	game._update_enemies(0.1)
	if int(chase_enemy.get("boss_phase", 1)) != 3:
		push_error("Boss scene node did not switch to phase 3 at low HP.")
		quit(1)
		return
	if game.enemy_shots.size() < phase_shot_count_before + game.Constants.BOSS_PHASE_THREE_SPREAD_COUNT:
		push_error("Boss phase 3 did not request the denser spread shot.")
		quit(1)
		return
	if game.floating_texts.size() <= phase_text_count_before:
		push_error("Boss phase change did not create a visible phase prompt.")
		quit(1)
		return
	var delayed_attack: Dictionary = boss_ai.PHASE_ATTACKS[3][1]
	if not delayed_attack.has("bullet") or float(delayed_attack.bullet.radius) <= 7.0:
		push_error("Boss attack data does not include the expected bullet profile.")
		quit(1)
		return
	var boss_profile_shot_count_before: int = game.enemy_shots.size()
	game._fire_enemy_attack_pattern(chase_enemy.pos, Vector2.RIGHT, delayed_attack)
	var profiled_shot: Dictionary = game.enemy_shots[boss_profile_shot_count_before]
	if String(profiled_shot.shot_style) != "delayed" or float(profiled_shot.radius) <= 7.0 or int(profiled_shot.damage) <= 8 + game.room_index:
		push_error("Boss bullet profile was not applied to generated projectiles.")
		quit(1)
		return
	chase_enemy.hp = chase_enemy.max_hp
	game.player.hp = 50
	game.player.max_hp = 80
	game.player.lifesteal = 0.25
	var hp_before_lifesteal: int = int(game.player.hp)
	game._damage_enemy(0, 20, Vector2.RIGHT)
	if int(game.player.hp) <= hp_before_lifesteal:
		push_error("Lifesteal did not heal the player after damage.")
		quit(1)
		return
	if game.floating_texts.is_empty() or int(game.floating_texts.back().get("size", 0)) < 26:
		push_error("Lifesteal did not create the larger green heal text.")
		quit(1)
		return
	chase_enemy.kind = "boss"
	chase_enemy.hp = 100
	game.player.boss_damage_bonus = 0.5
	game._damage_enemy(0, 20, Vector2.RIGHT)
	if int(chase_enemy.hp) != 70:
		push_error("Boss damage bonus did not apply to boss damage.")
		quit(1)
		return
	game.player.crit_chance = 1.0
	game.player.crit_multiplier = 2.0
	game._fire_at_nearest_enemy()
	if game.arrows.is_empty() or int(game.arrows.back().damage) != int(game.player.power) * 2:
		push_error("Critical upgrade did not affect arrow damage.")
		quit(1)
		return
	chase_enemy.kind = "crawler"
	chase_enemy.hp = 100
	chase_enemy.max_hp = 100
	game.arrows.back().pos = chase_enemy.pos
	var crit_text_count_before: int = game.floating_texts.size()
	game._update_arrows(0.1)
	var found_crit_text := false
	for text_index in range(crit_text_count_before, game.floating_texts.size()):
		if String(game.floating_texts[text_index].text).begins_with("CRIT"):
			found_crit_text = true
	if not found_crit_text:
		push_error("Critical hit did not create distinct critical damage text.")
		quit(1)
		return
	if game.enemies.is_empty():
		game._spawn_enemy("crawler")
		chase_enemy = game.enemies[0]
	chase_enemy.kind = "crawler"
	chase_enemy.hp = 1
	chase_enemy.max_hp = 1
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

	game.room_index = 1
	game._spawn_room()
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
	if not game.enemies[0].node.has_method("update_boss_position"):
		push_error("Boss room did not instantiate the dedicated Boss node.")
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

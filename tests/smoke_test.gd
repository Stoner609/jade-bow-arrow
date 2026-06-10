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

	game._start_run()
	await process_frame

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

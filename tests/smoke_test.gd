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

	game.fire_timer = 0.0
	game._fire_at_nearest_enemy()

	if game.arrows.is_empty():
		push_error("Player did not auto-fire an arrow.")
		quit(1)
		return

	var original_room: int = game.room_index
	game.enemies.clear()
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

	quit(0)

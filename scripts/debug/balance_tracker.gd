extends RefCounted

var active := false
var run_started_at := 0.0
var current_room := 1
var current_room_started_at := 0.0
var room_times: Dictionary = {}
var upgrades: Array[String] = []
var result := "In Progress"
var death_room := "-"
var death_cause := "-"
var boss_started_at := -1.0
var boss_kill_time := "-"
var total_time := "-"


# 用途：開始記錄一場平衡測試。
func start_run(start_room: int) -> void:
	active = true
	run_started_at = Time.get_ticks_msec() / 1000.0
	current_room = start_room
	current_room_started_at = run_started_at
	room_times.clear()
	upgrades.clear()
	result = "In Progress"
	death_room = "-"
	death_cause = "-"
	boss_started_at = -1.0
	boss_kill_time = "-"
	total_time = "-"


# 用途：記錄玩家進入新房間的時間點。
func enter_room(room: int, max_rooms: int) -> void:
	if not active:
		return
	current_room = room
	current_room_started_at = Time.get_ticks_msec() / 1000.0
	if room >= max_rooms:
		boss_started_at = current_room_started_at - run_started_at


# 用途：記錄房間清除時間。
func clear_room(room: int) -> void:
	if not active:
		return
	var now := Time.get_ticks_msec() / 1000.0
	room_times[room] = now - current_room_started_at


# 用途：記錄玩家選擇的升級。
func record_upgrade(level: int, upgrade_name: String) -> void:
	if not active:
		return
	upgrades.append("Lv.%d %s" % [level, upgrade_name])


# 用途：記錄死亡結果。
func record_death(room: int, cause: String) -> void:
	if not active:
		return
	result = "Lose"
	death_room = str(room)
	death_cause = cause
	total_time = _format_time(Time.get_ticks_msec() / 1000.0 - run_started_at)
	_print_summary()
	active = false


# 用途：記錄通關結果。
func record_win() -> void:
	if not active:
		return
	result = "Win"
	var elapsed := Time.get_ticks_msec() / 1000.0 - run_started_at
	total_time = _format_time(elapsed)
	if boss_started_at >= 0.0:
		boss_kill_time = _format_time(elapsed - boss_started_at)
	_print_summary()
	active = false


# 用途：輸出一行可貼進平衡測試表的摘要。
func _print_summary() -> void:
	var room_summary: Array[String] = []
	for room in room_times.keys():
		room_summary.append("R%d=%s" % [room, _format_time(float(room_times[room]))])
	room_summary.sort()
	print("[Balance] Result=%s | DeathRoom=%s | DeathCause=%s | BossKill=%s | Total=%s | Rooms=%s | Upgrades=%s" % [
		result,
		death_room,
		death_cause,
		boss_kill_time,
		total_time,
		", ".join(room_summary),
		" > ".join(upgrades)
	])


static func _format_time(seconds: float) -> String:
	var total_seconds: int = max(0, int(round(seconds)))
	return "%d:%02d" % [total_seconds / 60, total_seconds % 60]

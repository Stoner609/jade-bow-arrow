extends CanvasLayer

signal start_requested
signal pause_requested
signal resume_requested
signal restart_requested
signal menu_requested
signal sound_toggle_requested
signal upgrade_selected(index: int)

enum Mode { START, PLAYING, UPGRADE, PAUSED, DEAD, WON }

@onready var root: Control = $Root
@onready var hud_label: Label = $HUD
@onready var log_label: Label = $Log
@onready var help_label: Label = $Help

var overlay: Control
var pause_button: Button
var current_mode := -1
var current_muted := false
var current_upgrade_signature := ""


# 用途：建立 HUD 互動節點。
func _ready() -> void:
	pause_button = _make_button("II", Rect2(Vector2(468, 50), Vector2(46, 38)))
	pause_button.button_down.connect(func() -> void: pause_requested.emit())
	root.add_child(pause_button)

	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)


# 用途：更新左上角主要狀態文字。
func set_hud_text(text: String) -> void:
	hud_label.text = text


# 用途：更新左下角遊戲訊息紀錄。
func set_log_text(text: String) -> void:
	log_label.text = text


# 用途：更新右上角操作提示。
func set_help_text(text: String) -> void:
	help_label.text = text


# 用途：依遊戲模式更新互動 HUD。
func set_mode(mode: int, muted: bool, upgrade_choices: Array = []) -> void:
	var upgrade_signature := _upgrade_signature(upgrade_choices)
	if mode == current_mode and muted == current_muted and upgrade_signature == current_upgrade_signature:
		return
	current_mode = mode
	current_muted = muted
	current_upgrade_signature = upgrade_signature
	_clear_overlay()
	pause_button.visible = mode == Mode.PLAYING
	match mode:
		Mode.START:
			_show_start_overlay(muted)
		Mode.UPGRADE:
			_show_upgrade_overlay(upgrade_choices)
		Mode.PAUSED:
			_show_pause_overlay(muted)
		Mode.DEAD:
			_show_end_overlay("Run failed")
		Mode.WON:
			_show_end_overlay("Chapter cleared")


# 用途：建立開始畫面。
func _show_start_overlay(muted: bool) -> void:
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_panel(Color(0.02, 0.03, 0.04, 0.64))
	_add_label("Jade Bow Arrow", Rect2(Vector2(96, 254), Vector2(348, 50)), 36, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("Clear 8 rooms. Stop moving to fire.", Rect2(Vector2(74, 318), Vector2(392, 28)), 17, HORIZONTAL_ALIGNMENT_CENTER, Color(0.72, 0.82, 0.78))
	_add_button("Start", Rect2(Vector2(108, 392), Vector2(324, 58)), func() -> void: start_requested.emit())
	_add_button("Sound: %s" % ("Off" if muted else "On"), Rect2(Vector2(108, 468), Vector2(324, 52)), func() -> void: sound_toggle_requested.emit())


# 用途：建立升級選擇畫面。
func _show_upgrade_overlay(upgrade_choices: Array) -> void:
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_panel(Color(0.02, 0.03, 0.04, 0.72))
	_add_label("Choose an ability", Rect2(Vector2(92, 200), Vector2(356, 42)), 31, HORIZONTAL_ALIGNMENT_CENTER)
	for i in upgrade_choices.size():
		var upgrade: Dictionary = upgrade_choices[i]
		var rect := Rect2(Vector2(54, 274 + i * 126), Vector2(432, 106))
		var title := "%d   %s\n%s" % [i + 1, upgrade.name, upgrade.desc]
		_add_button(title, rect, func(index := i) -> void: upgrade_selected.emit(index), HORIZONTAL_ALIGNMENT_LEFT)


# 用途：建立暫停畫面。
func _show_pause_overlay(muted: bool) -> void:
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_panel(Color(0.02, 0.03, 0.04, 0.72))
	_add_label("Paused", Rect2(Vector2(136, 254), Vector2(268, 50)), 36, HORIZONTAL_ALIGNMENT_CENTER)
	_add_button("Resume", Rect2(Vector2(108, 334), Vector2(324, 54)), func() -> void: resume_requested.emit())
	_add_button("Restart", Rect2(Vector2(108, 406), Vector2(324, 54)), func() -> void: restart_requested.emit())
	_add_button("Sound: %s" % ("Off" if muted else "On"), Rect2(Vector2(108, 478), Vector2(324, 54)), func() -> void: sound_toggle_requested.emit())
	_add_button("Main Menu", Rect2(Vector2(108, 550), Vector2(324, 54)), func() -> void: menu_requested.emit())


# 用途：建立死亡或通關畫面。
func _show_end_overlay(title: String) -> void:
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_panel(Color(0.02, 0.03, 0.04, 0.74))
	_add_label(title, Rect2(Vector2(84, 352), Vector2(372, 52)), 36, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("Choose your next step.", Rect2(Vector2(102, 414), Vector2(336, 28)), 18, HORIZONTAL_ALIGNMENT_CENTER, Color(0.76, 0.82, 0.78))
	_add_button("Restart", Rect2(Vector2(108, 456), Vector2(324, 56)), func() -> void: restart_requested.emit())
	_add_button("Main Menu", Rect2(Vector2(108, 530), Vector2(324, 56)), func() -> void: menu_requested.emit())


# 用途：新增覆蓋畫面背景色塊。
func _add_panel(color: Color) -> void:
	var panel := ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.color = color
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(panel)


# 用途：新增覆蓋畫面文字。
func _add_label(text: String, rect: Rect2, font_size: int, alignment: HorizontalAlignment, color := Color(0.95, 0.96, 0.88)) -> void:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	overlay.add_child(label)


# 用途：新增覆蓋畫面按鈕並接上動作。
func _add_button(text: String, rect: Rect2, callback: Callable, alignment := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var button := _make_button(text, rect, alignment)
	button.button_down.connect(callback)
	overlay.add_child(button)


# 用途：建立共用按鈕樣式。
func _make_button(text: String, rect: Rect2, alignment := HORIZONTAL_ALIGNMENT_CENTER) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.alignment = alignment
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 0.92))
	button.add_theme_font_size_override("font_size", 22)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.16, 0.18, 0.94)
	normal.border_color = Color(0.54, 0.9, 0.82)
	normal.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.14, 0.22, 0.24, 0.96)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.06, 0.11, 0.12, 0.98)
	button.add_theme_stylebox_override("pressed", pressed)
	return button


# 用途：清空目前覆蓋畫面。
func _clear_overlay() -> void:
	if overlay == null:
		return
	for child in overlay.get_children():
		child.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


# 用途：產生升級選單內容簽章，避免每幀重建相同按鈕。
func _upgrade_signature(upgrade_choices: Array) -> String:
	var parts: Array[String] = []
	for upgrade in upgrade_choices:
		parts.append("%s:%s" % [upgrade.get("name", ""), upgrade.get("stat", "")])
	return "|".join(parts)

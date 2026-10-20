class_name Hud
extends Control
## 8-bit NES-style HUD overlay displaying Health, Lives, Score, and Kill Count.

var health_label: Label
var lives_label: Label
var score_label: Label
var kill_label: Label
var message_label: Label


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

	# 1. Health Display
	health_label = Label.new()
	health_label.position = Vector2(16, 10)
	health_label.add_theme_color_override("font_color", Color(0.97, 0.85, 0.47))
	health_label.add_theme_font_size_override("font_size", 10)
	add_child(health_label)

	# 2. Lives Display
	lives_label = Label.new()
	lives_label.position = Vector2(16, 22)
	lives_label.add_theme_color_override("font_color", Color(0.97, 0.85, 0.47))
	lives_label.add_theme_font_size_override("font_size", 10)
	add_child(lives_label)

	# 3. Score Display
	score_label = Label.new()
	score_label.position = Vector2(96, 10)
	score_label.add_theme_color_override("font_color", Color(0.97, 0.85, 0.47))
	score_label.add_theme_font_size_override("font_size", 10)
	add_child(score_label)

	# 4. Kill Counter Display
	kill_label = Label.new()
	kill_label.position = Vector2(180, 10)
	kill_label.add_theme_color_override("font_color", Color(0.97, 0.85, 0.47))
	kill_label.add_theme_font_size_override("font_size", 10)
	add_child(kill_label)

	# 5. Center Message Overlay
	message_label = Label.new()
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	message_label.add_theme_font_size_override("font_size", 14)
	add_child(message_label)


func _process(_delta: float) -> void:
	if lives_label:
		lives_label.text = "LIVES: %01d" % GameManager.player_lives
	if score_label:
		score_label.text = "SCORE:%05d" % GameManager.score
	if kill_label:
		kill_label.text = "KILLS:%02d" % GameManager.enemies_killed


func set_health(hp: int, max_hp: int) -> void:
	if health_label:
		health_label.text = "HP:%02d/%02d" % [hp, max_hp]


func show_message(text: String) -> void:
	if message_label:
		message_label.text = text

class_name Hud
extends Control
## HUD managing segmented health bar, lives, score, and notifications dynamically via code.

const HP_SEGMENTS := 28
const FONT_SIZE := 8

var score_label: Label
var lives_label: Label
var hp_container: VBoxContainer
var message_label: Label

var _message_id := 0   # stops an old message timer from clearing a newer message


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud_layout()

	EventBus.score_updated.connect(_on_score_updated)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.show_message.connect(_on_show_message)
	GameManager.lives_changed.connect(_on_lives_changed)


func _build_hud_layout() -> void:
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.position = Vector2(8, 8)
	score_label.add_theme_font_size_override("font_size", FONT_SIZE)
	score_label.text = "SCORE: %03d" % GameManager.score
	add_child(score_label)

	lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.position = Vector2(8, 20)
	lives_label.add_theme_font_size_override("font_size", FONT_SIZE)
	lives_label.text = "LIVES: %d" % GameManager.player_lives
	add_child(lives_label)

	# Health bar sits inside the 256px-wide viewport (right-hand side)
	hp_container = VBoxContainer.new()
	hp_container.name = "HPContainer"
	hp_container.position = Vector2(240, 8)
	hp_container.add_theme_constant_override("separation", 1)
	add_child(hp_container)
	_build_segmented_health_bar()

	# Centered banner for STAGE / GAME OVER / VICTORY messages
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", FONT_SIZE)
	message_label.position = Vector2(0, 110)
	message_label.custom_minimum_size = Vector2(256, 16)
	message_label.text = ""
	message_label.visible = false
	add_child(message_label)


# Called from Main.gd during initialization
func set_score(score_val: int) -> void:
	_on_score_updated(score_val)


# Called from Main.gd during initialization
func set_health(current_hp: int, max_hp: int) -> void:
	_on_player_health_changed(current_hp, max_hp)


func _on_score_updated(score: int) -> void:
	if score_label:
		score_label.text = "SCORE: %03d" % score


func _on_lives_changed(lives: int) -> void:
	if lives_label:
		lives_label.text = "LIVES: %d" % lives


func _build_segmented_health_bar() -> void:
	if not hp_container:
		return
	for c in hp_container.get_children():
		c.queue_free()

	for i in range(HP_SEGMENTS):
		var segment := ColorRect.new()
		segment.custom_minimum_size = Vector2(8, 2)
		segment.color = Color(0.2, 0.8, 1.0) if i < GameManager.player_health else Color(0.2, 0.2, 0.2)
		hp_container.add_child(segment)


func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	if not hp_container:
		return
	var count := hp_container.get_child_count()
	for i in range(count):
		var segment := hp_container.get_child(i) as ColorRect
		if segment:
			segment.visible = i < max_hp
			segment.color = Color(0.2, 0.8, 1.0) if i < current_hp else Color(0.2, 0.2, 0.2)


func _on_show_message(text: String, duration: float) -> void:
	if not message_label:
		return

	_message_id += 1
	var my_id := _message_id

	message_label.text = text
	message_label.visible = true

	await get_tree().create_timer(duration, true, false, true).timeout

	# Only clear if no newer message replaced this one
	if my_id == _message_id and message_label:
		message_label.text = ""
		message_label.visible = false

class_name TitleScreen
extends Control
## 8-bit NES-style title screen with a blinking press-start prompt.

signal start_game

var title_label: Label
var prompt_label: Label
var blink_timer := 0.0


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

	# Dark retro background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.12, 1.0)
	add_child(bg)

	# Main Title
	title_label = Label.new()
	title_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title_label.position += Vector2(-70, -40)
	title_label.text = "MEGA DAD"
	title_label.add_theme_color_override("font_color", Color(0.97, 0.85, 0.47)) # NES Gold
	title_label.add_theme_font_size_override("font_size", 20)
	add_child(title_label)

	# Flashing Prompt
	prompt_label = Label.new()
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	prompt_label.position += Vector2(-60, 20)
	prompt_label.text = "- PRESS START -"
	prompt_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	prompt_label.add_theme_font_size_override("font_size", 10)
	add_child(prompt_label)


func _process(delta: float) -> void:
	blink_timer += delta
	# Blink the prompt every 0.5 seconds
	if prompt_label:
		prompt_label.visible = int(blink_timer * 2.0) % 2 == 0

	# Listen for input to start the game
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("move_right"):
		start_game.emit()

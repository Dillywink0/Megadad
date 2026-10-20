class_name ScorePopup
extends Node2D
## Floating arcade score text that floats upward and fades away.

var text := "100"
var label: Label
var lifetime := 0.8
var elapsed := 0.0


func _init(score_text: String) -> void:
	text = score_text


func _ready() -> void:
	z_index = 50
	
	label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 8)
	label.position = Vector2(-8, -4)
	add_child(label)


func _process(delta: float) -> void:
	elapsed += delta
	position.y -= 20.0 * delta
	
	if label:
		var alpha := clampf(1.0 - (elapsed / lifetime), 0.0, 1.0)
		label.modulate = Color(1, 1, 1, alpha)

	if elapsed >= lifetime:
		queue_free()

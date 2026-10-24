class_name GoalFlag
extends Area2D

signal reached

@onready var sprite: Sprite2D = $Sprite2D

var _t := 0.0
var _done := false


func _ready() -> void:
	print("GoalFlag ready, layer=", collision_layer, " mask=", collision_mask, " monitoring=", monitoring)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	var frame_count := maxi(sprite.hframes * sprite.vframes, 1)
	sprite.frame = int(_t * 4.0) % frame_count


func _on_body_entered(body: Node2D) -> void:
	print("flag touched by: ", body.name)
	if _done:
		return
	if body is Player:
		_done = true
		reached.emit()

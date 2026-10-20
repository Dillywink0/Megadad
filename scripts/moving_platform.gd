class_name MovingPlatform
extends AnimatableBody2D
## Code-driven moving platform supporting horizontal and vertical oscillation aligned to the retro grid.

@export var travel_distance := 48.0
@export var speed := 1.4
@export var vertical := false

const TILE := 16
var start_pos := Vector2.ZERO
var time_passed := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true # Ensures smooth rider movement in Godot 4
	
	# Snap starting position to the nearest clean grid boundary to prevent wall/floor clipping
	global_position = global_position.snapped(Vector2(TILE, TILE))
	start_pos = global_position

	# Collision shape (2 tiles wide = 32px, 8px tall)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32, 8)
	shape.shape = rect
	shape.position = Vector2(16, 4)
	add_child(shape)

	# Outer platform base visual (Clean dark steel backing)
	var base := ColorRect.new()
	base.size = Vector2(32, 8)
	base.color = Color(0.35, 0.38, 0.48)
	add_child(base)

	# Top metal highlight strip
	var top_highlight := ColorRect.new()
	top_highlight.size = Vector2(32, 2)
	top_highlight.position = Vector2(0, 0)
	top_highlight.color = Color(0.75, 0.78, 0.88)
	add_child(top_highlight)

	# Inner NES hazard warning stripes
	for i in range(2):
		var stripe := ColorRect.new()
		stripe.size = Vector2(4, 4)
		stripe.position = Vector2(8 + (i * 12), 2)
		stripe.color = Color(0.9, 0.7, 0.2)
		add_child(stripe)


func _physics_process(delta: float) -> void:
	time_passed += delta * speed
	var offset := sin(time_passed * 2.0) * travel_distance
	
	if vertical:
		global_position.y = start_pos.y + offset
	else:
		global_position.x = start_pos.x + offset

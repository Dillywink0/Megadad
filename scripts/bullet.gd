class_name Bullet
extends Area2D
## The player's "buster" shot. Flies straight, dies on walls or when it hits an enemy.

const SPEED := 240.0

var direction := 1
var life := 1.2


func _ready() -> void:
	collision_layer = 8      # layer 4: player bullets
	collision_mask = 1 | 4   # hits layer 1 (world) and layer 3 (enemies)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(6, 4)
	shape.shape = rect
	add_child(shape)
	add_to_group("player_bullets")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(-3, -2, 6, 4), Color(0.99, 0.88, 0.66))
	draw_rect(Rect2(-1, -1, 2, 2), Color(1, 1, 1))
	
	

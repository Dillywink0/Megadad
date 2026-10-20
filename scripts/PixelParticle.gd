class_name PixelParticle
extends Node2D
## Lightweight pixel particle effect for arcade juice (dust, explosions, hits).

var velocity := Vector2.ZERO
var color := Color.WHITE
var lifetime := 0.4
var elapsed := 0.0
var size := 2.0


func _init(initial_vel: Vector2, particle_color: Color, p_size: float = 2.0) -> void:
	velocity = initial_vel
	color = particle_color
	size = p_size


func _ready() -> void:
	z_index = 60


func _process(delta: float) -> void:
	elapsed += delta
	position += velocity * delta
	velocity.y += 600.0 * delta # Gravity pulling particles down

	if elapsed >= lifetime:
		queue_free()


func _draw() -> void:
	var alpha := clampf(1.0 - (elapsed / lifetime), 0.0, 1.0)
	draw_rect(Rect2(-size/2, -size/2, size, size), Color(color.r, color.g, color.b, alpha))

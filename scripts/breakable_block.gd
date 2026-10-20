class_name BreakableBlock
extends StaticBody2D
## Secret breakable block that can be destroyed by player bullets to reveal pickups.

const TILE := 16
const TARGET_HEIGHT := 16.0

var sprite: Sprite2D
var tex_brick: Texture2D = preload("res://Sprites/tiles/brick_tile.png")


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	shape.position = Vector2(TILE / 2.0, TILE / 2.0)
	add_child(shape)

	sprite = Sprite2D.new()
	sprite.texture = tex_brick
	sprite.centered = false
	if tex_brick:
		var tex_size = tex_brick.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			sprite.scale = Vector2(TILE / tex_size.x, TILE / tex_size.y)
	add_child(sprite)


func take_damage(_amount: int) -> void:
	GameManager.score += 50
	GameManager.play_sound("hit")

	var parent := get_parent()

	var popup := ScorePopup.new("50")
	popup.global_position = global_position + Vector2(8, 0)
	parent.add_child(popup)

	# take_damage is called from a physics callback (bullet hit), and Godot does not
	# allow adding collision objects such as an Area2D at that moment, so defer it.
	var pickup := Pickup.new()
	pickup.item_type = Pickup.Type.HEALTH
	pickup.position = global_position + Vector2(8, 8)
	parent.add_child.call_deferred(pickup)

	queue_free()

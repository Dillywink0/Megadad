class_name Pickup
extends Area2D
## Collectible item using your item sprite assets with dynamic sizing.
## HEALTH restores 10 HP. SMALL restores 3 HP and gives 50 points.

enum Type { HEALTH, SMALL }
@export var item_type: Type = Type.HEALTH

const TARGET_HEIGHT := 12.0 # Desired pixel height
const HEALTH_HEAL := 10
const SMALL_HEAL := 3
const SMALL_SCORE := 50

var sprite: Sprite2D

var tex_health: Texture2D = preload("res://Sprites/items/health_pickup.png")
var tex_small: Texture2D = preload("res://Sprites/items/small_pickup.png")


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Detects the player (layer 2)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 10)
	shape.shape = rect
	add_child(shape)

	sprite = Sprite2D.new()
	sprite.texture = tex_health if item_type == Type.HEALTH else tex_small
	# Scale once here instead of every frame
	if sprite.texture:
		var tex_height := sprite.texture.get_height()
		if tex_height > 0:
			var s := TARGET_HEIGHT / float(tex_height)
			sprite.scale = Vector2(s, s)
	add_child(sprite)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return

	if item_type == Type.HEALTH:
		player.heal(HEALTH_HEAL)
	else:
		player.heal(SMALL_HEAL)
		GameManager.score += SMALL_SCORE
		var popup := ScorePopup.new(str(SMALL_SCORE))
		popup.global_position = global_position + Vector2(0, -8)
		get_parent().add_child(popup)

	queue_free()

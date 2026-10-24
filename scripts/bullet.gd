class_name Bullet
extends Area2D
## Player bullet supporting standard or charged projectile tiers.

const SPEED := 300.0

var direction := 1
var life := 1.2
var damage := 1
var charge_tier := 0  # 0: Normal, 1: Medium Charge, 2: Full Charge


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 4
	
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	
	# Scale size and damage relative to charge tier
	if charge_tier == 2:
		rect.size = Vector2(16, 12)
		damage = 3
	elif charge_tier == 1:
		rect.size = Vector2(12, 8)
		damage = 2
	else:
		rect.size = Vector2(6, 4)
		damage = 1
		
	shape.shape = rect
	add_child(shape)
	
	var sprite := Sprite2D.new()
	var tex_path := "res://Sprites/characters_Sprites/player/bullet.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	else:
		var img = Image.create(int(rect.size.x), int(rect.size.y), false, Image.FORMAT_RGBA8)
		img.fill(Color(0.99, 0.88, 0.66) if charge_tier == 0 else Color(0.2, 0.8, 1.0))
		sprite.texture = ImageTexture.create_from_image(img)
		
	sprite.scale = Vector2(0.5 * (charge_tier + 1), 0.5 * (charge_tier + 1))
	add_child(sprite)
	
	add_to_group("player_bullets")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

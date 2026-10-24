class_name Boss
extends CharacterBody2D
## Boss entity with phase transitions at 50% HP, multi-pattern attacks, and EventBus integration.

signal boss_died

const MAX_HP := 32
var hp := MAX_HP
var phase := 1
var attack_timer := 2.0
var facing := -1
var is_active := false

var sprite: Sprite2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 32)
	shape.shape = rect
	shape.position = Vector2(0, -16)
	add_child(shape)
	
	sprite = Sprite2D.new()
	sprite.position = Vector2(0, -16)
	add_child(sprite)
	
	# Placeholder texture generation if no sprite is assigned
	var img = Image.create(24, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.2, 0.2))
	sprite.texture = ImageTexture.create_from_image(img)


func activate_boss() -> void:
	is_active = true
	EventBus.trigger_boss_warning()
	EventBus.update_boss_hp(hp, MAX_HP)


func _physics_process(delta: float) -> void:
	if not is_active or hp <= 0:
		return
		
	attack_timer -= delta
	if attack_timer <= 0.0:
		_perform_attack()
		attack_timer = 1.5 if phase == 2 else 2.5


func _perform_attack() -> void:
	if phase == 2:
		_shoot_spread_projectiles()
	else:
		_shoot_single_projectile()


func _shoot_single_projectile() -> void:
	var bullet := Bullet.new()
	bullet.direction = facing
	bullet.global_position = global_position + Vector2(facing * 16, -16)
	get_parent().add_child(bullet)


func _shoot_spread_projectiles() -> void:
	for offset_y in [-12.0, 0.0, 12.0]:
		var bullet := Bullet.new()
		bullet.direction = facing
		bullet.global_position = global_position + Vector2(facing * 16, -16 + offset_y)
		get_parent().add_child(bullet)


func take_damage(amount: int) -> void:
	if hp <= 0 or not is_active:
		return
		
	hp -= amount
	GameManager.play_sound("hit")
	GameManager.trigger_hit_stop(0.04)
	EventBus.update_boss_hp(hp, MAX_HP)
	
	if hp <= MAX_HP * 0.5 and phase == 1:
		phase = 2
		EventBus.show_banner_message("WARNING: PHASE 2!", 1.5)
		
	if hp <= 0:
		_die()


func _die() -> void:
	is_active = false
	EventBus.trigger_boss_defeat()
	boss_died.emit()
	GameManager.score += 2000
	queue_free()

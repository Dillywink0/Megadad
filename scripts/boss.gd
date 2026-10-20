class_name Boss
extends CharacterBody2D
## Stage 4 Final Boss using characters_Sprites/boss/ assets.

signal boss_defeated

const MAX_HP := 50
const CONTACT_DAMAGE := 6
const TARGET_HEIGHT := 32.0

var hp := MAX_HP
var dir := -1
var timer := 0.0
var flash := 0.0
var attack_phase := 0

var sprite: Sprite2D
var hitbox: Area2D
var tex_boss: Texture2D = preload("res://Sprites/characters_Sprites/boss/frames/idle_0.png")
var tex_boss_death: Texture2D = preload("res://Sprites/characters_Sprites/boss/strips/death.png")


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 28)
	shape.shape = rect
	shape.position = Vector2(0, -14)
	add_child(shape)

	sprite = Sprite2D.new()
	sprite.texture = tex_boss
	sprite.position = Vector2(0, -16)
	if sprite.texture:
		var tex_h := sprite.texture.get_height()
		if tex_h > 0:
			var s := TARGET_HEIGHT / float(tex_h)
			sprite.scale = Vector2(s, s)
	add_child(sprite)

	hitbox = Area2D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	var hit_shape := CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = Vector2(24, 28)
	hit_shape.shape = hit_rect
	hit_shape.position = Vector2(0, -14)
	hitbox.add_child(hit_shape)
	add_child(hitbox)


func _physics_process(delta: float) -> void:
	timer += delta
	flash = maxf(flash - delta, 0.0)

	if timer >= 2.2:
		timer = 0.0
		attack_phase = (attack_phase + 1) % 3
		if attack_phase == 1:
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				dir = 1 if players[0].global_position.x > global_position.x else -1

	match attack_phase:
		0:
			velocity.x = move_toward(velocity.x, 0, 200.0)
		1:
			velocity.x = dir * 85.0
			if is_on_wall():
				dir = -dir
		2:
			velocity.x = 0
			if is_on_floor() and timer < 0.1:
				velocity.y = -300.0

	velocity.y = minf(velocity.y + 1000.0 * delta, 500.0)
	move_and_slide()

	for body in hitbox.get_overlapping_bodies():
		if body is Player:
			body.hurt(CONTACT_DAMAGE, global_position.x)

	sprite.modulate = Color(10, 10, 10) if flash > 0.0 else Color(1, 1, 1)
	sprite.flip_h = (dir > 0)


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	flash = 0.12
	GameManager.play_sound("hit")
	if hp == 0:
		var parent := get_parent()
		if parent:
			var death_sprite := Sprite2D.new()
			death_sprite.texture = tex_boss_death
			death_sprite.global_position = global_position + Vector2(0, -16)
			parent.add_child(death_sprite)
			
			var death_timer := get_tree().create_timer(1.2)
			death_timer.timeout.connect(func(): if is_instance_valid(death_sprite): death_sprite.queue_free())

		boss_defeated.emit()
		queue_free()

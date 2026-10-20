class_name Enemy
extends CharacterBody2D
## Multi-behavior enemy utilizing structured character_Sprites asset subfolders with animated death frames.

const SPEED := 30.0
const GRAVITY := 1000.0
const CONTACT_DAMAGE := 3
const TARGET_HEIGHT := 16.0

@export var enemy_variant := 1  # 1: Walker, 2: Flyer, 3: Hopper, 4: Turret

var hp := 2
var dir := -1
var turn_cooldown := 0.2
var flash := 0.0
var dying := false
var time_passed := 0.0
var jump_timer := 1.5
var shoot_timer := 2.0

var ledge_ray: RayCast2D
var hitbox: Area2D
var sprite: Sprite2D

# Mapped paths to characters_Sprites subfolders
var textures := {
	1: preload("res://Sprites/characters_Sprites/walker/frames/walk_0.png"),
	2: preload("res://Sprites/characters_Sprites/flyer/frames/fly_0.png"),
	3: preload("res://Sprites/characters_Sprites/hopper/frames/jump_0.png"),
	4: preload("res://Sprites/characters_Sprites/turret/frames/idle_0.png")
}

# Correct multi-frame death animation sequence arrays pointing to each enemy's specific subfolder
var enemy_death_frames := {
	1: [ # Walker
		preload("res://Sprites/characters_Sprites/walker/frames/death_0.png"),
		preload("res://Sprites/characters_Sprites/walker/frames/death_1.png"),
		preload("res://Sprites/characters_Sprites/walker/frames/death_2.png"),
		preload("res://Sprites/characters_Sprites/walker/frames/death_3.png"),
		preload("res://Sprites/characters_Sprites/walker/frames/death_4.png")
	],
	2: [ # Flyer
		preload("res://Sprites/characters_Sprites/flyer/frames/death_0.png"),
		preload("res://Sprites/characters_Sprites/flyer/frames/death_1.png"),
		preload("res://Sprites/characters_Sprites/flyer/frames/death_2.png"),
		preload("res://Sprites/characters_Sprites/flyer/frames/death_3.png"),
		preload("res://Sprites/characters_Sprites/flyer/frames/death_4.png")
	],
	3: [ # Hopper
		preload("res://Sprites/characters_Sprites/hopper/frames/death_0.png"),
		preload("res://Sprites/characters_Sprites/hopper/frames/death_1.png"),
		preload("res://Sprites/characters_Sprites/hopper/frames/death_2.png"),
		preload("res://Sprites/characters_Sprites/hopper/frames/death_3.png"),
		preload("res://Sprites/characters_Sprites/hopper/frames/death_4.png")
	],
	4: [ # Turret
		preload("res://Sprites/characters_Sprites/turret/frames/death_0.png"),
		preload("res://Sprites/characters_Sprites/turret/frames/death_1.png"),
		preload("res://Sprites/characters_Sprites/turret/frames/death_2.png"),
		preload("res://Sprites/characters_Sprites/turret/frames/death_3.png"),
		preload("res://Sprites/characters_Sprites/turret/frames/death_4.png")
	]
}


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	add_child(shape)

	sprite = Sprite2D.new()
	sprite.texture = textures.get(enemy_variant, textures[1])
	sprite.position = Vector2(0, -8)
	if sprite.texture:
		var tex_height := sprite.texture.get_height()
		if tex_height > 0:
			var s := TARGET_HEIGHT / float(tex_height)
			sprite.scale = Vector2(s, s)
	add_child(sprite)

	hitbox = Area2D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	var hit_shape := CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = Vector2(14, 12)
	hit_shape.shape = hit_rect
	hit_shape.position = Vector2(0, -6)
	hitbox.add_child(hit_shape)
	add_child(hitbox)

	ledge_ray = RayCast2D.new()
	ledge_ray.target_position = Vector2(0, 10)
	ledge_ray.collision_mask = 1
	ledge_ray.enabled = true
	add_child(ledge_ray)
	_update_ray()


func _physics_process(delta: float) -> void:
	time_passed += delta
	
	var camera = get_viewport().get_camera_2d()
	if camera:
		if absf(global_position.x - camera.global_position.x) > 180.0:
			return

	turn_cooldown = maxf(turn_cooldown - delta, 0.0)
	flash = maxf(flash - delta, 0.0)

	match enemy_variant:
		1: # Walker
			velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
			velocity.x = dir * SPEED
			if is_on_floor() and turn_cooldown <= 0.0:
				if is_on_wall() or not ledge_ray.is_colliding():
					_turn()
		2: # Flyer
			velocity.x = dir * SPEED
			velocity.y = sin(time_passed * 5.0) * 45.0
		3: # Hopper
			velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
			velocity.x = dir * (SPEED * 0.6)
			jump_timer -= delta
			if is_on_floor() and jump_timer <= 0.0:
				velocity.y = -240.0
				jump_timer = randf_range(1.2, 2.2)
			if is_on_floor() and turn_cooldown <= 0.0 and is_on_wall():
				_turn()
		4: # Turret
			velocity.x = 0
			velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				_shoot_bullet()
				shoot_timer = 2.0

	move_and_slide()

	for body in hitbox.get_overlapping_bodies():
		if body is Player:
			body.hurt(CONTACT_DAMAGE, global_position.x)

	sprite.modulate = Color(10, 10, 10) if flash > 0.0 else Color(1, 1, 1)
	sprite.flip_h = (dir > 0)


func _shoot_bullet() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var target = players[0]
		dir = 1 if target.global_position.x > global_position.x else -1
	
	var bullet := Bullet.new()
	bullet.direction = dir
	bullet.collision_layer = 16
	bullet.collision_mask = 2
	bullet.global_position = global_position + Vector2(dir * 10, -8)
	if get_parent():
		get_parent().add_child(bullet)


func take_damage(amount: int) -> void:
	if dying:
		return
	hp -= amount
	flash = 0.1
	GameManager.play_sound("hit")
	if hp <= 0:
		_die()


func _turn() -> void:
	dir = -dir
	turn_cooldown = 0.2
	_update_ray()
	ledge_ray.force_raycast_update()


func _update_ray() -> void:
	ledge_ray.position = Vector2(dir * 8, -2)


func _die() -> void:
	dying = true
	GameManager.enemies_killed += 1
	GameManager.score += 100

	var parent := get_parent()
	if parent:
		var popup := ScorePopup.new("100")
		popup.global_position = global_position + Vector2(0, -8)
		parent.add_child(popup)

		# Spawn animated multi-frame death sequence for the exact enemy variant
		var death_sprite := Sprite2D.new()
		death_sprite.global_position = global_position + Vector2(0, -8)
		parent.add_child(death_sprite)

		var frames: Array = enemy_death_frames.get(enemy_variant, enemy_death_frames[1])
		for f in range(frames.size()):
			var frame_tex = frames[f]
			var delay = f * 0.08 # ~12 fps pacing
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(death_sprite):
					death_sprite.texture = frame_tex
					var h = frame_tex.get_height()
					if h > 0:
						var s = (TARGET_HEIGHT * 1.5) / float(h)
						death_sprite.scale = Vector2(s, s)
			)

		var timer := get_tree().create_timer(0.45)
		timer.timeout.connect(func(): if is_instance_valid(death_sprite): death_sprite.queue_free())

		for i in range(8):
			var angle := randf_range(0.0, TAU)
			var speed := randf_range(40.0, 120.0)
			var p_vel := Vector2(cos(angle), sin(angle)) * speed
			var particle := PixelParticle.new(p_vel, Color(0.99, 0.88, 0.66), 3.0)
			particle.global_position = global_position + Vector2(0, -8)
			parent.add_child(particle)

	queue_free()

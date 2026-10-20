class_name Player
extends CharacterBody2D
## Blue-bomber-style hero using structured character sprite assets, multi-frame death animations, and slide mechanics.

signal health_changed(hp: int, max_hp: int)
signal damaged
signal died

const SPEED := 105.0
const JUMP_VELOCITY := -300.0
const GRAVITY := 1000.0
const MAX_FALL_SPEED := 400.0
const MAX_HP := 28
const INVULN_TIME := 1.0
const KNOCKBACK_TIME := 0.3
const MAX_BULLETS := 3
const SHOOT_POSE_TIME := 0.3
const SLIDE_DURATION := 0.35
const SLIDE_SPEED := 150.0

const TARGET_HEIGHT := 24.0

var hp := MAX_HP
var facing := 1
var invuln := 0.0
var knockback := 0.0
var shoot_pose := 0.0
var anim_time := 0.0
var dead := false
var was_on_floor := true
var is_sliding := false
var slide_timer := 0.0

var sprite: Sprite2D

# Load character sprites from characters_Sprites/player/
var tex_idle: Texture2D = preload("res://Sprites/characters_Sprites/player/frames/idle_0.png")
var tex_walk1: Texture2D = preload("res://Sprites/characters_Sprites/player/frames/run_0.png")
var tex_walk2: Texture2D = preload("res://Sprites/characters_Sprites/player/frames/run_1.png")
var tex_walk3: Texture2D = preload("res://Sprites/characters_Sprites/player/frames/run_2.png")
var tex_jump: Texture2D = preload("res://Sprites/characters_Sprites/player/frames/jump_0.png")
var tex_shoot: Texture2D = preload("res://Sprites/characters_Sprites/player/frames/shoot_0.png")
var tex_hurt: Texture2D = preload("res://Sprites/characters_Sprites/player/frames/hurt_0.png")
var tex_slide: Texture2D = preload("res://Sprites/characters_Sprites/player/frames/slide_0.png")

# Multi-frame death animation sequence frames from characters_Sprites/player/frames/
var tex_death_frames: Array[Texture2D] = [
	preload("res://Sprites/characters_Sprites/player/frames/death_0.png"),
	preload("res://Sprites/characters_Sprites/player/frames/death_1.png"),
	preload("res://Sprites/characters_Sprites/player/frames/death_2.png"),
	preload("res://Sprites/characters_Sprites/player/frames/death_3.png"),
	preload("res://Sprites/characters_Sprites/player/frames/death_4.png")
]


func _ready() -> void:
	collision_layer = 2  # layer 2: player
	collision_mask = 1   # collides with layer 1: world

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 22)
	shape.shape = rect
	shape.position = Vector2(0, -11)
	add_child(shape)

	sprite = Sprite2D.new()
	sprite.position = Vector2(0, -12)
	add_child(sprite)
	_set_sprite_texture(tex_idle)


func _physics_process(delta: float) -> void:
	if dead:
		return

	invuln = maxf(invuln - delta, 0.0)
	knockback = maxf(knockback - delta, 0.0)
	shoot_pose = maxf(shoot_pose - delta, 0.0)

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	if knockback <= 0.0:
		# Slide Input check (Down + Jump while moving on floor)
		if Input.is_action_just_pressed("jump") and Input.is_action_pressed("ui_down") and is_on_floor() and not is_sliding:
			is_sliding = true
			slide_timer = SLIDE_DURATION

		if is_sliding:
			slide_timer -= delta
			velocity.x = facing * SLIDE_SPEED
			if slide_timer <= 0.0 or not is_on_floor():
				is_sliding = false
		else:
			var dir := signf(Input.get_axis("move_left", "move_right"))
			velocity.x = dir * SPEED
			if dir != 0.0:
				facing = 1 if dir > 0.0 else -1

			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				GameManager.play_sound("jump")
			if Input.is_action_just_released("jump") and velocity.y < 0.0:
				velocity.y = 0.0

		if Input.is_action_just_pressed("shoot"):
			_shoot()

	move_and_slide()

	if not was_on_floor and is_on_floor():
		_spawn_landing_dust()
	was_on_floor = is_on_floor()

	if is_on_floor() and absf(velocity.x) > 1.0 and not is_sliding:
		anim_time += delta
	else:
		anim_time = 0.0

	if global_position.y > 280.0:
		kill()
		return

	visible = invuln <= 0.0 or int(invuln * 20.0) % 2 == 0
	_update_sprites()


func _update_sprites() -> void:
	sprite.flip_h = (facing == -1)

	var active_texture: Texture2D = tex_idle
	if knockback > 0.0:
		active_texture = tex_hurt
	elif is_sliding:
		active_texture = tex_slide
	elif not is_on_floor():
		active_texture = tex_jump
	elif shoot_pose > 0.0:
		active_texture = tex_shoot
	elif absf(velocity.x) > 1.0:
		var frame_step := int(anim_time * 12.0) % 3
		match frame_step:
			0: active_texture = tex_walk1
			1: active_texture = tex_walk2
			2: active_texture = tex_walk3

	_set_sprite_texture(active_texture)


func _set_sprite_texture(tex: Texture2D) -> void:
	if tex == null or sprite.texture == tex:
		return
	sprite.texture = tex
	var tex_height := tex.get_height()
	if tex_height > 0:
		var s := TARGET_HEIGHT / float(tex_height)
		sprite.scale = Vector2(s, s)


func _shoot() -> void:
	if get_tree().get_nodes_in_group("player_bullets").size() >= MAX_BULLETS:
		return
	var bullet := Bullet.new()
	bullet.direction = facing
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(facing * 12, -13)
	shoot_pose = SHOOT_POSE_TIME
	GameManager.play_sound("shoot")


func _spawn_landing_dust() -> void:
	if not get_parent():
		return
	for i in range(4):
		var p_vel := Vector2(randf_range(-40, 40), randf_range(-20, -5))
		var particle := PixelParticle.new(p_vel, Color(0.8, 0.8, 0.8), 2.0)
		particle.global_position = global_position
		get_parent().add_child(particle)


func heal(amount: int) -> void:
	if dead:
		return
	hp = mini(hp + amount, MAX_HP)
	GameManager.player_health = hp
	health_changed.emit(hp, MAX_HP)


func hurt(amount: int, from_x: float) -> void:
	if dead or invuln > 0.0:
		return
	hp = maxi(hp - amount, 0)
	GameManager.player_health = hp
	GameManager.play_sound("hit")
	health_changed.emit(hp, MAX_HP)
	damaged.emit()

	if hp == 0:
		_die()
		return
	invuln = INVULN_TIME
	knockback = KNOCKBACK_TIME
	is_sliding = false
	var side := signf(global_position.x - from_x)
	if side == 0.0:
		side = -float(facing)
	velocity = Vector2(side * 50.0, -120.0)


func kill() -> void:
	if dead:
		return
	hp = 0
	GameManager.player_health = hp
	GameManager.play_sound("hit")
	health_changed.emit(hp, MAX_HP)
	_die()


func freeze() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)


func unfreeze() -> void:
	set_physics_process(true)


func _die() -> void:
	dead = true
	visible = false
	
	# Spawn animated multi-frame player death sequence
	var parent := get_parent()
	if parent:
		var death_sprite := Sprite2D.new()
		death_sprite.global_position = global_position + Vector2(0, -12)
		parent.add_child(death_sprite)
		
		for f in range(tex_death_frames.size()):
			var frame_tex = tex_death_frames[f]
			var delay = f * 0.08 # ~12 fps pacing
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(death_sprite):
					death_sprite.texture = frame_tex
					var h = frame_tex.get_height()
					if h > 0:
						var s = TARGET_HEIGHT / float(h)
						death_sprite.scale = Vector2(s, s)
			)
			
		var final_timer := get_tree().create_timer(0.45)
		final_timer.timeout.connect(func(): if is_instance_valid(death_sprite): death_sprite.queue_free())

	died.emit()

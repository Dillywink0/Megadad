class_name Main
extends Node
## Main controller managing the game loop, scene transitions, camera shake, and UI overlays via EventBus.

const TitleScreenScene := preload("res://scenes/title_screen.tscn")

var title_layer: CanvasLayer
var current_title_screen: TitleScreen
var level: Node2D
var player: Player
var camera: Camera2D
var hud_layer: CanvasLayer
var hud: Hud
var retro_overlay: Control

var is_game_started: bool = false
var shake_timer: float = 0.0
var shake_intensity: float = 0.0

# Only real stages belong here (the boss is spawned by level_4.gd)
var levels: Array = [
	# preload("res://scripts/Levels/level.gd"), # Old hardcoded level 1 script commented out
	preload("res://scenes/Level_1.tscn"),        # New Level_1 scene path
	preload("res://scripts/Levels/level_2.gd"),
	preload("res://scripts/Levels/level_3.gd"),
	preload("res://scripts/Levels/level_4.gd")
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.score_changed.connect(_on_score_changed)
	_show_title_screen()


## Frees everything created by _init_gameplay() so nothing stacks up.
func _cleanup_gameplay() -> void:
	if player and is_instance_valid(player):
		player.remove_from_group("player")
		player.queue_free()   # the Camera2D is a child, so it is freed too
	player = null
	camera = null

	if level and is_instance_valid(level):
		level.queue_free()
	level = null

	if hud_layer and is_instance_valid(hud_layer):
		hud_layer.queue_free()   # the Hud is a child, so it is freed too
	hud_layer = null
	hud = null

	shake_timer = 0.0


func _show_title_screen() -> void:
	is_game_started = false
	_cleanup_gameplay()

	if title_layer and is_instance_valid(title_layer):
		title_layer.queue_free()

	title_layer = CanvasLayer.new()
	title_layer.layer = 100
	add_child(title_layer)

	current_title_screen = TitleScreenScene.instantiate() as TitleScreen

	if current_title_screen == null:
		push_error("Main: Failed to instantiate TitleScreen scene!")
		return

	current_title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_title_screen.start_callback = _on_start_game_pressed

	title_layer.add_child(current_title_screen)
	print("Title screen successfully spawned inside CanvasLayer.")


func _on_start_game_pressed() -> void:
	print("--> Start button clicked! Transitioning to gameplay...")
	if is_game_started:
		return
	is_game_started = true

	if title_layer and is_instance_valid(title_layer):
		title_layer.queue_free()
		title_layer = null
		current_title_screen = null

	GameManager.reset_game()
	_init_gameplay()


func _init_gameplay() -> void:
	if levels.is_empty():
		push_error("Main: Levels array is empty!")
		return

	# Remove the previous level / player / camera / HUD before building new ones
	_cleanup_gameplay()

	var idx := clampi(GameManager.current_level_index - 1, 0, levels.size() - 1)
	print("Initializing gameplay. Level index: ", GameManager.current_level_index, " (Array Index: ", idx, ")")

	if levels[idx] == null:
		push_error("Main: Level resource at index %d is null!" % idx)
		return

	var level_resource = levels[idx]
	
	# Safely handle both PackedScenes (.tscn) and scripts (.gd)
	if level_resource is PackedScene:
		level = level_resource.instantiate() as Node2D
	else:
		level = level_resource.new() as Node2D

	if level == null:
		push_error("Main: Failed to instantiate level!")
		return

	print("Level successfully instantiated: ", level.name)

	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)

	# Setup player
	player = Player.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	if "spawn_point" in level:
		player.position = level.spawn_point
	else:
		player.position = Vector2(100, 100)

	if GameManager.player_health <= 0:
		GameManager.player_health = 28
	player.hp = GameManager.player_health
	add_child(player)

	# Setup Camera
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	if "cols" in level and "rows" in level and "TILE" in level:
		camera.limit_right = level.cols * level.TILE
		camera.limit_bottom = level.rows * level.TILE
	player.add_child(camera)

	# Setup HUD via CanvasLayer (stored so it can be freed later)
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	hud = Hud.new()
	hud_layer.add_child(hud)

	# Connect signals if they exist
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	if player.has_signal("damaged"):
		player.damaged.connect(_on_player_damaged)
	if level.has_signal("goal_reached"):
		level.goal_reached.connect(_on_goal_reached)

	EventBus.update_player_health(player.hp, 28)
	EventBus.update_score(GameManager.score)

	_start_stage_transition()


func _start_stage_transition() -> void:
	get_tree().paused = true
	EventBus.show_message.emit("STAGE %d" % GameManager.current_level_index, 2.0)

	var t := get_tree().create_timer(2.0, true, false, true)
	t.timeout.connect(func():
		get_tree().paused = false
	)


func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		if camera and is_instance_valid(camera):
			camera.offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
	elif camera and is_instance_valid(camera) and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


func trigger_camera_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration


func _on_score_changed(new_score: int) -> void:
	EventBus.update_score(new_score)


func _on_player_health_changed(hp: int, max_hp: int) -> void:
	EventBus.update_player_health(hp, max_hp)


func _on_player_damaged() -> void:
	trigger_camera_shake(4.0, 0.2)


func _on_player_died() -> void:
	GameManager.player_lives -= 1
	if GameManager.player_lives <= 0:
		EventBus.show_message.emit("GAME OVER", 3.0)

	var t := get_tree().create_timer(3.0)
	t.timeout.connect(func():
		if GameManager.player_lives > 0:
			GameManager.player_health = 28
			_init_gameplay()
		else:
			_show_title_screen()
	)


func _on_goal_reached() -> void:
	# Guard against the goal firing twice (e.g. boss defeat + goal pole)
	if level == null or not is_instance_valid(level):
		return
	if level.is_connected("goal_reached", _on_goal_reached):
		level.goal_reached.disconnect(_on_goal_reached)

	GameManager.current_level_index += 1
	GameManager.checkpoint_pos = Vector2.ZERO   # don't carry checkpoints into the next stage
	EventBus.show_message.emit("STAGE CLEAR!", 2.5)

	var t := get_tree().create_timer(2.5)
	t.timeout.connect(func():
		if GameManager.current_level_index > levels.size():
			EventBus.show_message.emit("VICTORY!", 3.0)
			var vt := get_tree().create_timer(3.0)
			vt.timeout.connect(_show_title_screen)
		else:
			_init_gameplay()
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_game_started:
		pass

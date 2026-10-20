class_name Main
extends Node2D
## Main game loop handling title screen, stage transitions, camera shake, and HUD state[cite: 1].

# Remembers across scene reloads (death, stage clear) that the title was already shown,
# so "PRESS START" only appears on first launch and after a game over / win[cite: 1].
static var title_shown := false

var level: Level
var player: Player
var camera: Camera2D
var hud: Hud
var title_screen: TitleScreen
var finished := false

# Screen Shake variables
var shake_trauma := 0.0
var max_shake_offset := 8.0

# Levels are referenced by class_name, so there are no file paths to get wrong[cite: 1].
var levels: Array = [Level, Level2, Level3, Level4]


func _ready() -> void:
	# Main stays active during pause to listen for the unpause key
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if title_shown:
		_init_gameplay()
	else:
		_show_title_screen()


func _show_title_screen() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	title_screen = TitleScreen.new()
	title_screen.start_game.connect(func() -> void:
		Main.title_shown = true
		layer.queue_free()
		_init_gameplay()
	)
	layer.add_child(title_screen)


func _init_gameplay() -> void:
	var idx := clampi(GameManager.current_level_index - 1, 0, levels.size() - 1)
	
	# Explicitly set level and its children to be pausable
	level = levels[idx].new()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level)

	# Explicitly set player to be pausable
	player = Player.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.position = level.spawn_point
	player.hp = GameManager.player_health
	add_child(player)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = level.cols * Level.TILE
	camera.limit_bottom = level.rows * Level.TILE
	player.add_child(camera)

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)

	var retro_overlay := RetroShaderOverlay.new()
	add_child(retro_overlay)

	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	level.goal_reached.connect(_on_goal_reached)

	hud.set_health(player.hp, Player.MAX_HP)
	_start_stage_transition()


func _process(delta: float) -> void:
	if not camera:
		return

	if shake_trauma > 0.0:
		shake_trauma = maxf(shake_trauma - delta * 2.0, 0.0)
		var shake_amount = pow(shake_trauma, 2)
		camera.offset = Vector2(
			randf_range(-max_shake_offset, max_shake_offset) * shake_amount,
			randf_range(-max_shake_offset, max_shake_offset) * shake_amount
		)
	else:
		camera.offset = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# Toggle pause state and update HUD message smoothly
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		var tree := get_tree()
		tree.paused = not tree.paused
		if hud:
			hud.show_message("PAUSED" if tree.paused else "")


func add_screen_shake(amount: float) -> void:
	shake_trauma = clampf(shake_trauma + amount, 0.0, 1.0)


func _start_stage_transition() -> void:
	if not player:
		return
	player.freeze()

	var stage_num_str := "STAGE 0" + str(GameManager.current_level_index)
	hud.show_message(stage_num_str)

	await get_tree().create_timer(1.5).timeout

	if not finished and player and not player.dead:
		hud.show_message("READY!")
		await get_tree().create_timer(0.5).timeout
		hud.show_message("")
		player.unfreeze()


func _on_player_damaged() -> void:
	add_screen_shake(0.6)


func _on_player_health_changed(new_hp: int, max_hp: int) -> void:
	GameManager.player_health = new_hp
	if hud:
		hud.set_health(new_hp, max_hp)


func _on_player_died() -> void:
	if finished:
		return
	finished = true
	add_screen_shake(1.0)

	GameManager.player_lives -= 1

	if GameManager.player_lives > 0:
		hud.show_message("YOU DIED")
		await get_tree().create_timer(1.5).timeout
		GameManager.player_health = Player.MAX_HP
		get_tree().reload_current_scene()
	else:
		hud.show_message("GAME OVER")
		await get_tree().create_timer(2.5).timeout
		GameManager.reset_game()
		Main.title_shown = false  # back to title screen after game over[cite: 1]
		get_tree().reload_current_scene()


func _on_goal_reached() -> void:
	if finished or (player and player.dead):
		return
	finished = true
	if player:
		player.freeze()

	GameManager.current_level_index += 1
	GameManager.checkpoint_pos = Vector2.ZERO  # new level must not reuse old checkpoint[cite: 1]

	if GameManager.current_level_index <= levels.size():
		hud.show_message("STAGE CLEAR")
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()
	else:
		hud.show_message("YOU WIN!")
		await get_tree().create_timer(3.0).timeout
		GameManager.reset_game()
		Main.title_shown = false  # back to title screen after winning[cite: 1]
		get_tree().reload_current_scene()

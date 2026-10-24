extends Node
## Global GameManager handling score, lives, current level index, checkpoint positions, high scores, and audio streaming.

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)

var score := 0:
	set(val):
		print("SCORE ", score, " -> ", val)
		print_stack()
		score = val
		score_changed.emit(score)

var player_lives := 3:
	set(val):
		player_lives = val
		lives_changed.emit(player_lives)

var player_health := 28
var enemies_killed := 0
var high_score := 0
var current_level_index := 1
var checkpoint_pos := Vector2.ZERO  # <--- Added this property to fix the Level._ready error

const SAVE_PATH := "user://savegame.save"

@export var sfx_pool_size := 8
var sfx_players: Array[AudioStreamPlayer] = []
var sound_library := {
	"jump": preload("res://Sound Effects/Jump.wav"),
	"shoot": preload("res://Sound Effects/Shoot.wav"),
	"hit": preload("res://Sound Effects/Hit.wav")
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_high_score()
	
	for i in range(sfx_pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		sfx_players.append(player)

# Add this function to scripts/game_manager.gd
func handle_player_death() -> void:
	player_lives -= 1
	if player_lives < 0:
		reset_game()
	else:
		# If you want score to reset on death, uncomment the line below:
		# score = 0
		player_health = 28

func play_sound(sound_name: String) -> void:
	if not sound_library.has(sound_name):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = sound_library[sound_name]
			p.play()
			return


func trigger_hit_stop(duration_sec: float = 0.04) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration_sec, true, false, true).timeout
	Engine.time_scale = 1.0


func reset_game() -> void:
	score = 0
	player_lives = 3
	player_health = 28
	enemies_killed = 0
	current_level_index = 1
	checkpoint_pos = Vector2.ZERO
	Engine.time_scale = 1.0


func save_high_score() -> void:
	if score > high_score:
		high_score = score
		var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_32(high_score)


func load_high_score() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_32()

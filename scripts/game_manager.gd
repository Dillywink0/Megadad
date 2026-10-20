class_name GameManagerClass
extends Node
## Global singleton managing score, player health, lives, kills, checkpoints, and audio.

const AUDIO_POOL_SIZE := 6

var score := 0
var enemies_killed := 0
var player_health := 28
var max_player_health := 28
var player_lives := 3
var checkpoint_pos := Vector2.ZERO
var current_level_index := 1

# Audio streams mapped to your exact folder name "Sound Effects"
var sfx_jump: AudioStream = preload("res://Sound Effects/Jump.wav")
var sfx_hit: AudioStream = preload("res://Sound Effects/Hit.wav")
var sfx_shoot: AudioStream = preload("res://Sound Effects/Shoot.wav")

# Name -> stream lookup (filled in _ready). Add new sounds here.
var sounds := {}

# Pool of players so a new sound does not cut off the previous one
var audio_players: Array[AudioStreamPlayer] = []
var _next_player := 0


func _ready() -> void:
	sounds = {
		"jump": sfx_jump,
		"hit": sfx_hit,
		"shoot": sfx_shoot,
	}
	for i in AUDIO_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		audio_players.append(p)


func play_sound(sfx_name: String) -> void:
	var stream: AudioStream = sounds.get(sfx_name)
	if stream == null or audio_players.is_empty():
		return

	var chosen: AudioStreamPlayer = null
	for p in audio_players:
		if not p.playing:
			chosen = p
			break
	if chosen == null:
		# All busy: steal the oldest one in round-robin order
		chosen = audio_players[_next_player]
		_next_player = (_next_player + 1) % audio_players.size()

	chosen.stream = stream
	chosen.play()


func reset_game() -> void:
	score = 0
	enemies_killed = 0
	player_health = max_player_health
	player_lives = 3
	checkpoint_pos = Vector2.ZERO
	current_level_index = 1


func reset_level_state() -> void:
	player_health = max_player_health

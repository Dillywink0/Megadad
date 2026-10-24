class_name TitleScreen
extends Control

# Direct function reference passed from Main
var start_callback: Callable

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var background_texture_rect: TextureRect = $BackgroundTextureRect
@onready var logo_texture_rect: TextureRect = $CenterContainer/VBoxContainer/LogoTextureRect

const TITLE_BG_PATH := "res://Sprites/Title Screen/title_v2_bg.png"
const TITLE_LOGO_PATH := "res://Sprites/Title Screen/title_v2_logo.png"
const TITLE_TRACK_PATH := "res://Sound Effects/Tile_screen.wav"

var title_music_player: AudioStreamPlayer


func _ready() -> void:
	_load_textures()
	_connect_signals()
	_setup_title_music()

	if start_button != null:
		start_button.grab_focus()


func _load_textures() -> void:
	if background_texture_rect != null:
		background_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		if ResourceLoader.exists(TITLE_BG_PATH):
			background_texture_rect.texture = load(TITLE_BG_PATH) as Texture2D

	if logo_texture_rect != null:
		logo_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(TITLE_LOGO_PATH):
			logo_texture_rect.texture = load(TITLE_LOGO_PATH) as Texture2D


func _setup_title_music() -> void:
	title_music_player = AudioStreamPlayer.new()
	title_music_player.bus = &"Master" # Ensure it plays on the active master bus
	add_child(title_music_player) # MUST add to tree before setting stream/playing in some Godot versions
	
	if ResourceLoader.exists(TITLE_TRACK_PATH):
		var audio_res = load(TITLE_TRACK_PATH)
		if audio_res is AudioStream:
			title_music_player.stream = audio_res
			title_music_player.play()
			print("Playing title music successfully.")
		else:
			push_error("TitleScreen: Failed to load Title_screen.wav as an AudioStream.")
	else:
		push_error("TitleScreen: Title_screen.wav not found at path: " + TITLE_TRACK_PATH)


func _connect_signals() -> void:
	if start_button != null:
		if not start_button.pressed.is_connected(_on_start_pressed):
			start_button.pressed.connect(_on_start_pressed)

	if quit_button != null:
		if not quit_button.pressed.is_connected(_on_quit_pressed):
			quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	print("Start button pressed! Triggering callback...")
	
	if title_music_player != null and title_music_player.playing:
		title_music_player.stop()
		title_music_player.queue_free()

	if start_callback.is_valid():
		start_callback.call()
	else:
		push_error("TitleScreen: start_callback is not assigned!")


func _on_quit_pressed() -> void:
	get_tree().quit()

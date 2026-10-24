class_name TileMapLevel
extends Node2D

signal goal_reached

const TILE := 16

var spawn_point := Vector2(24, 200)
var cols := 0
var rows := 0

@onready var tile_layer: TileMapLayer = get_node_or_null("TileMapLayer")


func _ready() -> void:
	if tile_layer:
		var used := tile_layer.get_used_rect()
		cols = used.end.x
		rows = used.end.y
	else:
		push_warning("TileMapLevel: no TileMapLayer found")

	var spawn := get_node_or_null("PlayerSpawn") as Marker2D
	if spawn:
		spawn_point = spawn.global_position  # Updated to global coordinates

	if GameManager.checkpoint_pos != Vector2.ZERO:
		spawn_point = GameManager.checkpoint_pos

	var goal := get_node_or_null("Goal") as GoalFlag
	if goal:
		goal.reached.connect(func(): goal_reached.emit())

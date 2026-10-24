class_name Level
extends Node2D
## Base level class handling map parsing, tile rendering, hazards, and moving platforms.

signal goal_reached

const TILE := 16

var active_level_data := {
	"tile": "brick",
	"map": [
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"....................................................................I...........",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................................................",
		"................................................##....####..............##......",
		"...P......E.....####..........E.......^^......................##........E...G..",
		"##########################..####..##########...##########...##########..########",
		"##########################..####..##########...##########...##########..########",
	]
}

var cols := 0
var rows := 0
var spawn_point := Vector2(24, 200)
var solids := {}
var spikes: Array[Vector2i] = []
var goal_tile := Vector2i(-1, -1)
var enemy_spawns: Array[Dictionary] = []
var item_spawns: Array[Vector2] = []
var checkpoint_spawns: Array[Vector2] = []
var breakable_spawns: Array[Vector2i] = []
var platform_spawns: Array[Dictionary] = []

var music_player: AudioStreamPlayer
# Updated to use Track_V1.wav for level background music
var bg_track: AudioStream = preload("res://Sound Effects/Track_V1.wav")

# Preload tile textures
var tex_brick: Texture2D = preload("res://Sprites/tiles/brick_tile.png")
var tex_metal: Texture2D = preload("res://Sprites/tiles/metal_block.png")
var tex_factory: Texture2D = preload("res://Sprites/spritesheets/tileset_factory.png")
var tex_crypt: Texture2D = preload("res://Sprites/spritesheets/tileset_crypt.png")
var tex_sewer: Texture2D = preload("res://Sprites/spritesheets/tileset_sewer.png")
var tex_ocean: Texture2D = preload("res://Sprites/spritesheets/tileset_ocean.png")
var tex_spikes: Texture2D = preload("res://Sprites/tiles/spikes.png")


func _ready() -> void:
	_setup_background_music()
	_parse_map()
	_build_collision()
	_build_hazards()
	_spawn_tiles()
	_spawn_items()
	_spawn_enemies()
	_spawn_checkpoints()
	_spawn_breakable_blocks()
	_spawn_moving_platforms()

	if GameManager.checkpoint_pos != Vector2.ZERO:
		spawn_point = GameManager.checkpoint_pos


func _setup_background_music() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.stream = bg_track
	add_child(music_player)
	music_player.play()


func _parse_map() -> void:
	var map_lines: Array = active_level_data["map"]
	rows = map_lines.size()
	for y in rows:
		var row: String = map_lines[y]
		cols = maxi(cols, row.length())
		for x in row.length():
			var pos := Vector2i(x, y)
			var feet := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
			var char_code := row[x]
			
			match char_code:
				"#":
					solids[pos] = true
				"^":
					spikes.append(pos)
				"G":
					goal_tile = pos
				"P":
					spawn_point = feet
				"C":
					checkpoint_spawns.append(feet)
				"E":
					enemy_spawns.append({"pos": feet, "variant": 1})
				"F":
					enemy_spawns.append({"pos": feet, "variant": 2})
				"H":
					enemy_spawns.append({"pos": feet, "variant": 3})
				"J":
					enemy_spawns.append({"pos": feet, "variant": 4})
				"I":
					item_spawns.append(feet)
				"B":
					breakable_spawns.append(pos)
				"M":
					platform_spawns.append({"pos": feet, "vertical": false, "dist": 32.0, "speed": 1.4})
				"V":
					platform_spawns.append({"pos": feet, "vertical": true, "dist": 32.0, "speed": 1.2})


func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	for y in rows:
		var x := 0
		while x < cols:
			if solids.has(Vector2i(x, y)):
				var start := x
				while x < cols and solids.has(Vector2i(x, y)):
					x += 1
				_add_rect(body, Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE))
			else:
				x += 1

	var h := rows * TILE
	_add_rect(body, Rect2(-TILE, -h, TILE, h * 3))
	_add_rect(body, Rect2(cols * TILE, -h, TILE, h * 3))


func _build_hazards() -> void:
	if not spikes.is_empty():
		var spike_area := Area2D.new()
		spike_area.collision_layer = 0
		spike_area.collision_mask = 2
		add_child(spike_area)
		for t in spikes:
			_add_rect(spike_area, Rect2(t.x * TILE + 1, t.y * TILE + 8, TILE - 2, 8))
		spike_area.body_entered.connect(_on_spike_entered)

	if goal_tile.x >= 0:
		var goal_area := Area2D.new()
		goal_area.collision_layer = 0
		goal_area.collision_mask = 2
		add_child(goal_area)
		_add_rect(goal_area, Rect2(goal_tile.x * TILE, (goal_tile.y - 1) * TILE, TILE, TILE * 2))
		goal_area.body_entered.connect(_on_goal_entered)


func _spawn_tiles() -> void:
	var theme_name: String = active_level_data.get("tile", "brick")
	var chosen_tex := tex_brick
	
	match theme_name:
		"metal": chosen_tex = tex_metal
		"factory": chosen_tex = tex_factory
		"crypt": chosen_tex = tex_crypt
		"sewer": chosen_tex = tex_sewer
		"ocean": chosen_tex = tex_ocean
		_: chosen_tex = tex_brick

	for pos in solids:
		var sprite := Sprite2D.new()
		sprite.texture = chosen_tex
		sprite.centered = false
		sprite.position = Vector2(pos.x * TILE, pos.y * TILE)
		if chosen_tex:
			var tex_size = chosen_tex.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				sprite.scale = Vector2(TILE / tex_size.x, TILE / tex_size.y)
		add_child(sprite)

	for pos in spikes:
		var sprite := Sprite2D.new()
		sprite.texture = tex_spikes
		sprite.centered = false
		sprite.position = Vector2(pos.x * TILE, pos.y * TILE)
		if tex_spikes:
			var tex_size = tex_spikes.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				sprite.scale = Vector2(TILE / tex_size.x, TILE / tex_size.y)
		add_child(sprite)

	if goal_tile.x >= 0:
		var g := Vector2(goal_tile.x * TILE, goal_tile.y * TILE)
		var pole := ColorRect.new()
		pole.size = Vector2(2, 32)
		pole.position = Vector2(g.x + 7, g.y - 16)
		pole.color = Color(0.9, 0.9, 0.9)
		add_child(pole)


func _spawn_items() -> void:
	for p in item_spawns:
		var pickup := Pickup.new()
		pickup.item_type = Pickup.Type.HEALTH
		pickup.position = p
		add_child(pickup)


func _spawn_enemies() -> void:
	for data in enemy_spawns:
		var enemy := Enemy.new()
		enemy.position = data["pos"]
		
		# Safe assignment matching declared property type
		if "enemy_variant" in enemy:
			enemy.enemy_variant = int(data["variant"])
			
		add_child(enemy)


func _spawn_breakable_blocks() -> void:
	for pos in breakable_spawns:
		var block := BreakableBlock.new()
		block.position = Vector2(pos.x * TILE, pos.y * TILE)
		add_child(block)


func _spawn_moving_platforms() -> void:
	for data in platform_spawns:
		var plat := MovingPlatform.new()
		plat.position = data["pos"]
		plat.vertical = data["vertical"]
		plat.travel_distance = data["dist"]
		plat.speed = data["speed"]
		add_child(plat)


func _spawn_checkpoints() -> void:
	for p in checkpoint_spawns:
		var area := Area2D.new()
		area.position = p
		area.collision_layer = 0
		area.collision_mask = 2

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(12, 16)
		shape.shape = rect
		shape.position = Vector2(0, -8)
		area.add_child(shape)

		var visual := ColorRect.new()
		visual.size = Vector2(8, 16)
		visual.position = Vector2(-4, -16)
		visual.color = Color(0.5, 0.5, 0.5) 
		area.add_child(visual)

		area.body_entered.connect(func(body: Node2D) -> void:
			if body is Player:
				GameManager.checkpoint_pos = area.global_position
				visual.color = Color(0.2, 0.8, 0.2)
		)
		add_child(area)


func _add_rect(parent: Node, rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	shape.position = rect.position + rect.size / 2.0
	parent.add_child(shape)


func _on_spike_entered(body: Node2D) -> void:
	if body is Player:
		body.kill()


func _on_goal_entered(body: Node2D) -> void:
	if body is Player:
		goal_reached.emit()

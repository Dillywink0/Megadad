class_name Level4
extends Level
## Stage 4: Ancient Crypt — Final gauntlet ending in the Boss Showdown.

var boss_spawn_pos := Vector2.ZERO
var boss_triggered := false


func _ready() -> void:
	active_level_data = {
		"tile": "crypt",
		"map": [
			"................................................................................",
			"................................................................................",
			"................................................................................",
			"................................................................................",
			"................................................................................",
			"................................................................................",
			"................................................................................",
			"........................................................................G.......",
			"......................................................................#####.....",
			"...................................................BBBB.............##....##....",
			"..................................................I    I..........##........##..",
			"..................^^^^^.....########...^^^^^...H2.M.......#..X....#..........#..",
			".................#     #  M         #     #...........#......#....#..........#..",
			"P...............#       #............#       #.........#........#....#..........#..",
			"################################################################################",
		]
	}
	super()
	_setup_boss_arena()


func _parse_map() -> void:
	super()
	# Scan map lines specifically for the Boss marker 'X'
	var map_lines: Array = active_level_data["map"]
	for y in map_lines.size():
		var row: String = map_lines[y]
		for x in row.length():
			if row[x] == "X":
				boss_spawn_pos = Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)


func _setup_boss_arena() -> void:
	if boss_spawn_pos == Vector2.ZERO:
		return

	# Create a trigger area before the boss arena
	var trigger := Area2D.new()
	trigger.position = boss_spawn_pos + Vector2(-120, 0)
	trigger.collision_layer = 0
	trigger.collision_mask = 2

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 100)
	shape.shape = rect
	shape.position = Vector2(0, -50)
	trigger.add_child(shape)

	trigger.body_entered.connect(func(body: Node2D) -> void:
		if body is Player and not boss_triggered:
			boss_triggered = true
			trigger.queue_free()
			_spawn_boss_encounter()
	)
	add_child(trigger)


func _spawn_boss_encounter() -> void:
	# Show boss warning banner on HUD
	for child in get_parent().get_children():
		if child is Main and child.hud:
			child.hud.show_message("WARNING: BOSS")

	await get_tree().create_timer(1.5).timeout

	for child in get_parent().get_children():
		if child is Main and child.hud:
			child.hud.show_message("")

	# Spawn the actual boss
	var boss := Boss.new()
	boss.position = boss_spawn_pos
	add_child(boss)

	boss.boss_defeated.connect(func() -> void:
		# Trigger stage win sequence on boss defeat
		goal_reached.emit()
	)

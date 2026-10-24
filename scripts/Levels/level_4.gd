
class_name Level4
extends Level
## Stage 4: Ancient Crypt
## Final gauntlet leading to the boss showdown.

var boss_spawn_pos: Vector2 = Vector2.ZERO
var boss_triggered: bool = false


func _ready() -> void:
	boss_spawn_pos = Vector2.ZERO
	boss_triggered = false

	active_level_data = {
		"tile": "crypt",
		"map": [
			"................................................................................",
			"................................................................................",
			"..............BBBB..............................................................",
			"..............I  I...................BBBB.......................................",
			"........................V................I  I...................................",
			"......#####.............V........#####.....................#####.................",
			"........................V.........................................................",
			"...E.............M......V.............F.............M............................",
			"......#####.............V....#####.............#####..............................",
			"....................^^^^^...................^^^^^....................#####........",
			"....C...............#   #.......J...........#   #....................#   #........",
			"P.............BBBB..#   #.............BBBB..#   #..........H.........#   #........",
			"..............I  I..#####...................#####....................#####........",
			"..........#####..............#####.....................#####.......................",
			"................................................................................",
			"...............................................................X................",
			"################################################################################",
		]
	}

	# The base Level class handles parsing, collision, hazards,
	# tile rendering, enemies, pickups and moving platforms.
	super()

	# Base _ready() calls _parse_map(), so the boss position
	# is available here.
	_setup_boss_arena()


func _parse_map() -> void:
	# Preserve all normal parsing behaviour from Level.
	super()

	# Find the boss marker in the hardcoded map.
	boss_spawn_pos = Vector2.ZERO

	var map_lines: Array = active_level_data["map"]

	for y in range(map_lines.size()):
		var row: String = map_lines[y]

		for x in range(row.length()):
			if row[x] == "X":
				boss_spawn_pos = Vector2(
					x * TILE + TILE / 2.0,
					(y + 1) * TILE
				)
				return


func _setup_boss_arena() -> void:
	if boss_spawn_pos == Vector2.ZERO:
		push_error("Level4: Could not find boss marker X.")
		return

	var trigger := Area2D.new()
	trigger.name = "BossArenaTrigger"
	trigger.position = boss_spawn_pos + Vector2(-128.0, 0.0)
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	trigger.monitoring = true

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()

	rect.size = Vector2(16.0, 96.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -48.0)

	trigger.add_child(shape)
	trigger.body_entered.connect(_on_boss_trigger_entered)

	add_child(trigger)


func _on_boss_trigger_entered(body: Node2D) -> void:
	if not body is Player:
		return

	if boss_triggered:
		return

	boss_triggered = true

	var trigger := get_node_or_null("BossArenaTrigger")
	if trigger != null:
		trigger.queue_free()

	_spawn_boss_encounter()


func _spawn_boss_encounter() -> void:
	EventBus.show_message.emit("WARNING: BOSS", 1.5)

	var boss := Boss.new()
	boss.name = "CryptBoss"
	boss.position = boss_spawn_pos
	boss.boss_died.connect(_on_boss_defeated)

	add_child(boss)
	boss.activate_boss()


func _on_boss_defeated() -> void:
	# The boss defeat is the only way to complete this stage.
	goal_reached.emit()

extends Node
## Global EventBus to decouple levels, UI, player, and bosses.

signal boss_warning_started
signal boss_health_changed(current_hp: int, max_hp: int)
signal boss_defeated
signal show_message(text: String, duration: float)
signal player_died
signal score_updated(new_score: int)
signal player_health_changed(hp: int, max_hp: int)


# Active wrapper functions to trigger signals cleanly from anywhere
func trigger_boss_warning() -> void:
	boss_warning_started.emit()

func update_boss_hp(current: int, max_val: int) -> void:
	boss_health_changed.emit(current, max_val)

func trigger_boss_defeat() -> void:
	boss_defeated.emit()

func show_banner_message(text: String, duration: float) -> void:
	show_message.emit(text, duration)

func notify_player_died() -> void:
	player_died.emit()

func update_score(score: int) -> void:
	score_updated.emit(score)

func update_player_health(hp: int, max_hp: int) -> void:
	player_health_changed.emit(hp, max_hp)

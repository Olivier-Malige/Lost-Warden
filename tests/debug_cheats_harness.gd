extends Node

const PlayerScene := preload("res://scenes/player/player.tscn")
const MainScript := preload("res://scenes/main/main.gd")

var _failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_input_actions_and_routing()
	await _test_player_stat_cheats()
	await get_tree().process_frame
	if _failures.is_empty():
		print("Debug cheats harness: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_input_actions_and_routing() -> void:
	var expected_keys := [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9]
	for index in range(1, 10):
		var action := "debug_Key" + str(index)
		_expect(InputMap.has_action(action), "Debug action F%d must exist." % index)
		var events := InputMap.action_get_events(action)
		_expect(events.size() == 1 and events[0] is InputEventKey and events[0].keycode == expected_keys[index - 1], "Debug action F%d must use the matching function key." % index)
	_expect(MainScript.PLAYER_CHEATS.get("debug_Key7") == "debug_increase_fire_rate", "F7 must increase fire rate.")
	_expect(MainScript.PLAYER_CHEATS.get("debug_Key8") == "debug_increase_beam", "F8 must increase beam power.")
	_expect(MainScript.PLAYER_CHEATS.get("debug_Key9") == "debug_max_stats", "F9 must maximize player stats.")

func _test_player_stat_cheats() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child(player)
	await get_tree().process_frame
	var score_before := global.score
	player.debug_increase_fire_rate()
	player.debug_increase_beam()
	_expect(player.loadout.rank_for(UpgradeDefinition.Effect.FIRE_RATE) == 1, "F7 must add one fire-rate rank.")
	_expect(player.loadout.rank_for(UpgradeDefinition.Effect.BEAM) == 1, "F8 must add one beam rank.")

	player.energy = 1
	player.debug_max_stats()
	for upgrade in [Player.UPGRADE_SPEED, Player.UPGRADE_DAMAGE, Player.UPGRADE_SIDE, Player.UPGRADE_FIRE_RATE, Player.UPGRADE_BEAM]:
		_expect(player.loadout.rank_for(upgrade.effect) == upgrade.max_rank, "%s must reach its maximum rank." % upgrade.id)
	_expect(is_equal_approx(player.loadout.fire_delay, Player.STATS.shoot_delay_min), "Maximum fire rate must respect the configured minimum delay.")
	_expect(is_equal_approx(player.loadout.move_speed(), Player.STATS.speed_max), "Maximum speed must respect the configured cap.")
	_expect(player.energy == Player.STATS.energy_max, "F9 must restore maximum energy.")
	_expect(player.shield.power == 6, "F9 must restore the full shield.")
	_expect(global.score == score_before, "Debug stat changes must not grant score.")

	player.debug_max_stats()
	_expect(global.score == score_before, "Repeated F9 use must not grant capped-upgrade score.")
	player.queue_free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

extends Node

const PlayerScene := preload("res://scenes/player/player.tscn")
const MainScript := preload("res://scenes/main/main.gd")

var _failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_input_map()
	await _test_combat_movement_slowdown()
	await _test_sustained_primary_fire()
	await _test_beam_reserve_and_priority()
	await _test_coop_input_and_charge_independence()
	_release_all_actions()
	await get_tree().process_frame
	if _failures.is_empty():
		print("Player weapon input harness: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_input_map() -> void:
	_expect(is_zero_approx(Player.STATS.beam_charge_start), "Players must start without plasma.")
	_expect(is_equal_approx(Player.STATS.beam_charge_max, 100.0), "Plasma reserve must cap at one hundred.")
	_expect(is_equal_approx(Player.STATS.beam_activation_min, 10.0), "Beam activation must require ten plasma.")
	_expect(is_equal_approx(Player.STATS.beam_drain_per_second, 20.0), "A full reserve must power five seconds of beam.")
	for action in ["all_beam", "keyboard_beam", "gamepad1_beam", "gamepad2_beam"]:
		_expect(InputMap.has_action(action), "%s must exist." % action)
	_expect(_joy_buttons("all_fire") == [[0, JOY_BUTTON_A]], "Solo primary fire must use gamepad A/Cross only.")
	_expect(_joy_buttons("all_beam") == [[0, JOY_BUTTON_B]], "Solo plasma beam must use gamepad B/Circle only.")
	_expect(_joy_buttons("gamepad1_beam") == [[0, JOY_BUTTON_B]], "Player 1 plasma beam must use B/Circle.")
	_expect(_joy_buttons("gamepad2_beam") == [[1, JOY_BUTTON_B]], "Player 2 plasma beam must use B/Circle.")
	_expect(_has_key("keyboard_fire", KEY_SPACE), "Keyboard primary fire must retain Space.")
	_expect(_has_key("keyboard_fire", KEY_INSERT), "Keyboard primary fire must retain Insert.")
	_expect(_has_key("keyboard_fire", KEY_KP_ADD), "Keyboard primary fire must retain keypad plus.")
	_expect(_has_key("keyboard_beam", KEY_SHIFT, 1), "Keyboard plasma beam must use left Shift.")
	for action in ["all_beam", "keyboard_beam", "gamepad1_beam", "gamepad2_beam"]:
		_expect(MainScript.PLAYER_INPUT_ACTIONS.has(action), "%s must be released during screen transitions." % action)

func _test_combat_movement_slowdown() -> void:
	global.coop = false
	var player := await _new_player()
	_expect(is_equal_approx(player._current_move_speed(), Player.STATS.speed), "An idle player must retain full movement speed.")
	Input.action_press("all_fire")
	player._update_weapons(0.0)
	_expect(is_equal_approx(player._current_move_speed(), Player.STATS.speed * 0.88), "Active primary fire must reduce movement speed by twelve percent.")
	Input.action_press("all_beam")
	player.beam_charge = Player.STATS.beam_activation_min
	player._update_weapons(0.0)
	_expect(player.beam_active, "Beam input above the threshold must activate immediately.")
	_expect(is_equal_approx(player._current_move_speed(), Player.STATS.speed * 0.88), "The active beam must use the same movement reduction.")
	Input.action_release("all_beam")
	player._update_weapons(0.0)
	_expect(not player.beam_active and player.shooting, "Held primary fire must resume when beam input is released.")
	_expect(is_equal_approx(player._current_move_speed(), Player.STATS.speed * 0.88), "Resumed primary fire must retain the weapon movement reduction.")
	Input.action_release("all_fire")
	player._update_weapons(0.0)
	_expect(is_equal_approx(player._current_move_speed(), Player.STATS.speed), "Releasing every active weapon must restore full speed.")
	await _free_player_and_shots(player)

func _test_sustained_primary_fire() -> void:
	global.coop = false
	var player := await _new_player()
	var baseline := _player_shots().size()
	Input.action_press("all_fire")
	player._update_weapons(0.016)
	_expect(_player_shots().size() == baseline + 1, "Primary fire must shoot immediately when held.")
	player._update_weapons(0.016)
	_expect(_player_shots().size() == baseline + 1, "Primary fire must respect its delay timer.")
	player._on_ShootingDelay_timeout()
	player._update_weapons(0.016)
	_expect(_player_shots().size() == baseline + 2, "Held primary fire must repeat after the delay.")
	player.loadout.apply(Player.UPGRADE_SIDE)
	player._on_ShootingDelay_timeout()
	var side_baseline := _player_shots().size()
	player._update_weapons(0.016)
	_expect(_player_shots().size() == side_baseline + 3, "Sustained fire must include both unlocked side cannons.")
	Input.action_release("all_fire")
	player._on_ShootingDelay_timeout()
	player._update_weapons(0.016)
	_expect(_player_shots().size() == side_baseline + 3, "Releasing primary fire must stop every cannon.")
	await _free_player_and_shots(player)

func _test_beam_reserve_and_priority() -> void:
	global.coop = false
	var player := await _new_player()
	player.beam_charge = Player.STATS.beam_charge_max
	var baseline := _player_shots().size()
	Input.action_press("all_fire")
	Input.action_press("all_beam")
	player._update_weapons(0.1)
	_expect(_player_shots().size() == baseline, "An active beam must suppress held primary fire.")
	_expect(player.beam_active and player.continuous_beam.overdrive, "Starting at full reserve must activate overdrive.")
	_expect(is_equal_approx(player.beam_charge, 98.0), "Beam drain must use physics delta.")
	player._update_weapons(0.9)
	_expect(not player.continuous_beam.overdrive, "Overdrive must end after one second without stopping the beam.")
	var conserved := player.beam_charge
	Input.action_release("all_beam")
	player._on_ShootingDelay_timeout()
	player._update_weapons(0.0)
	_expect(not player.beam_active and is_equal_approx(player.beam_charge, conserved), "Releasing beam input must preserve remaining plasma.")
	_expect(_player_shots().size() == baseline + 1, "Held primary fire must resume on the beam release frame.")
	Input.action_release("all_fire")
	await _free_player_and_shots(player)

	player = await _new_player()
	player.beam_charge = 9.0
	Input.action_press("all_fire")
	Input.action_press("all_beam")
	baseline = _player_shots().size()
	player._update_weapons(0.1)
	_expect(not player.beam_active, "Beam input below ten plasma must not activate.")
	_expect(_player_shots().size() == baseline + 1, "Insufficient plasma must not suppress primary fire.")
	Input.action_release("all_fire")
	Input.action_release("all_beam")
	player.beam_charge = 10.0
	Input.action_press("all_beam")
	player._update_weapons(0.5)
	_expect(not player.beam_active and is_zero_approx(player.beam_charge), "An empty reserve must stop the beam immediately.")
	player.beam_charge = 20.0
	player._update_weapons(0.25)
	var reset_charge := player.beam_charge
	player.reset_weapon_input()
	_expect(not player.beam_active and is_equal_approx(player.beam_charge, reset_charge), "Input cleanup must stop the beam without discarding plasma.")
	Input.action_release("all_beam")
	await _free_player_and_shots(player)

func _test_coop_input_and_charge_independence() -> void:
	global.coop = true
	global.saveData.config.player1 = "gamepad1"
	global.saveData.config.player2 = "keyboard"
	var player_one := await _new_player()
	var player_two := PlayerScene.instantiate() as Player
	player_two.set_Player_2 = true
	add_child(player_two)
	player_two.set_process(false)
	await get_tree().process_frame
	player_two.beam_charge = Player.STATS.beam_activation_min
	Input.action_press("keyboard_beam")
	player_one._update_weapons(0.1)
	player_two._update_weapons(0.1)
	_expect(not player_one.beam_active, "Keyboard beam input must not activate player 1.")
	_expect(player_two.beam_active, "Keyboard beam input must activate player 2 independently.")
	Input.action_release("keyboard_beam")
	player_two._update_weapons(0.0)
	var player_one_before := player_one.beam_charge
	var player_two_before := player_two.beam_charge
	Events.plasma_collected.emit(12.5)
	_expect(is_equal_approx(player_one.beam_charge, player_one_before + 12.5), "A plasma cell must recharge player 1 in co-op.")
	_expect(is_equal_approx(player_two.beam_charge, player_two_before + 12.5), "A plasma cell must recharge player 2 in co-op.")
	player_two.set_state(Player.State.DEAD)
	player_one_before = player_one.beam_charge
	player_two_before = player_two.beam_charge
	Events.plasma_collected.emit(12.5)
	_expect(is_equal_approx(player_one.beam_charge, player_one_before + 12.5), "Living co-op players must continue receiving shared plasma.")
	_expect(is_equal_approx(player_two.beam_charge, player_two_before), "Dead players must not receive shared plasma.")
	await _free_player_and_shots(player_one)
	player_two.queue_free()
	await get_tree().process_frame
	global.coop = false

func _new_player() -> Player:
	var player := PlayerScene.instantiate() as Player
	add_child(player)
	player.set_process(false)
	await get_tree().process_frame
	return player

func _free_player_and_shots(player: Player) -> void:
	_release_all_actions()
	for shot in _player_shots():
		shot.queue_free()
	player.queue_free()
	await get_tree().process_frame

func _player_shots() -> Array[Node]:
	return get_tree().get_nodes_in_group(&"player_Shot")

func _release_all_actions() -> void:
	for action in ["all_fire", "all_beam", "keyboard_fire", "keyboard_beam", "gamepad1_fire", "gamepad1_beam", "gamepad2_fire", "gamepad2_beam"]:
		Input.action_release(action)

func _joy_buttons(action: StringName) -> Array:
	var buttons := []
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			buttons.append([event.device, event.button_index])
	return buttons

func _has_key(action: StringName, keycode: Key, location := 0) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.keycode == keycode and event.location == location:
			return true
	return false

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

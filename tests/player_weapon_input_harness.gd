extends Node

const PlayerScene := preload("res://scenes/player/player.tscn")
const MainScript := preload("res://scenes/main/main.gd")

var _failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_input_map()
	await _test_sustained_primary_fire()
	await _test_beam_priority_and_release()
	await _test_coop_input_independence()
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
	_expect(is_equal_approx(Player.STATS.beam_mini, 0.45), "The small beam must charge in 0.45 seconds.")
	_expect(is_equal_approx(Player.STATS.beam_normal, 1.05), "The normal beam must charge in 1.05 seconds.")
	_expect(is_equal_approx(Player.STATS.beam_full, 2.1), "The full beam must charge in 2.10 seconds.")
	for action in ["all_beam", "keyboard_beam", "gamepad1_beam", "gamepad2_beam"]:
		_expect(InputMap.has_action(action), "%s must exist." % action)
	_expect(_joy_buttons("all_fire") == [[0, JOY_BUTTON_A]], "Solo primary fire must use gamepad A/Cross only.")
	_expect(_joy_buttons("all_beam") == [[0, JOY_BUTTON_B]], "Solo beam charge must use gamepad B/Circle only.")
	_expect(_joy_buttons("gamepad1_fire") == [[0, JOY_BUTTON_A]], "Player 1 primary fire must use A/Cross.")
	_expect(_joy_buttons("gamepad1_beam") == [[0, JOY_BUTTON_B]], "Player 1 beam charge must use B/Circle.")
	_expect(_joy_buttons("gamepad2_fire") == [[1, JOY_BUTTON_A]], "Player 2 primary fire must use A/Cross.")
	_expect(_joy_buttons("gamepad2_beam") == [[1, JOY_BUTTON_B]], "Player 2 beam charge must use B/Circle.")
	_expect(_has_key("keyboard_fire", KEY_SPACE), "Keyboard primary fire must retain Space.")
	_expect(_has_key("keyboard_fire", KEY_INSERT), "Keyboard primary fire must retain Insert.")
	_expect(_has_key("keyboard_fire", KEY_KP_ADD), "Keyboard primary fire must retain keypad plus.")
	_expect(_has_key("keyboard_beam", KEY_SHIFT, 1), "Keyboard beam charge must use left Shift.")
	for action in ["all_beam", "keyboard_beam", "gamepad1_beam", "gamepad2_beam"]:
		_expect(MainScript.PLAYER_INPUT_ACTIONS.has(action), "%s must be released during screen transitions." % action)

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

func _test_beam_priority_and_release() -> void:
	global.coop = false
	var player := await _new_player()
	for _rank in range(Player.UPGRADE_BEAM.max_rank):
		player.loadout.apply(Player.UPGRADE_BEAM)
	var baseline := _player_shots().size()
	Input.action_press("all_fire")
	Input.action_press("all_beam")
	player._update_weapons(Player.STATS.beam_full + 0.01)
	_expect(_player_shots().size() == baseline, "Beam charge must suppress held primary fire.")
	_expect(player.beam_Power == Player.beam_State.FULL, "A fully upgraded beam must reach full charge.")
	Input.action_release("all_beam")
	player._update_weapons(0.0)
	var beam_release_shots := _player_shots().slice(baseline)
	_expect(not beam_release_shots.is_empty(), "Releasing a charged beam must create beam segments.")
	for shot in beam_release_shots:
		_expect(shot.scene_file_path.contains("/beam/"), "A beam release frame must not contain a primary salvo.")
	var after_beam := _player_shots().size()
	player._update_weapons(0.016)
	_expect(_player_shots().size() == after_beam + 1, "Held primary fire must resume on the frame after beam release.")
	Input.action_release("all_fire")
	await _free_player_and_shots(player)

	player = await _new_player()
	Input.action_press("all_fire")
	Input.action_press("all_beam")
	player._update_weapons(0.1)
	Input.action_release("all_beam")
	baseline = _player_shots().size()
	player._update_weapons(0.0)
	_expect(_player_shots().size() == baseline + 1, "Releasing below the first beam tier must resume held primary fire immediately.")
	Input.action_release("all_fire")
	player.reset_weapon_input()
	_expect(player.accumBeam == 0.0 and player.beam_Power == Player.beam_State.EMPTY, "Input cleanup must cancel pending beam charge.")
	await _free_player_and_shots(player)

func _test_coop_input_independence() -> void:
	global.coop = true
	global.saveData.config.player1 = "gamepad1"
	global.saveData.config.player2 = "keyboard"
	var player_one := await _new_player()
	var player_two := PlayerScene.instantiate() as Player
	player_two.set_Player_2 = true
	add_child(player_two)
	player_two.set_process(false)
	await get_tree().process_frame
	Input.action_press("gamepad1_fire")
	var baseline := _player_shots().size()
	player_one._update_weapons(0.016)
	player_two._update_weapons(0.016)
	_expect(_player_shots().size() == baseline + 1, "Player 1 fire input must not fire player 2 weapons.")
	Input.action_release("gamepad1_fire")
	Input.action_press("keyboard_beam")
	player_one._update_weapons(Player.STATS.beam_mini + 0.01)
	player_two._update_weapons(Player.STATS.beam_mini + 0.01)
	_expect(player_one.beam_Power == Player.beam_State.EMPTY, "Keyboard beam input must not charge player 1.")
	_expect(player_two.beam_Power == Player.beam_State.SMALL, "Keyboard beam input must charge player 2.")
	Input.action_release("keyboard_beam")
	player_one.reset_weapon_input()
	player_two.reset_weapon_input()
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
	return get_tree().get_nodes_in_group("player_Shot")

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

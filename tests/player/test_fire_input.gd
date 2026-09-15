extends SceneTree

var _shots := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	world.child_entered_tree.connect(func(node: Node):
		if node.scene_file_path.ends_with("shot.tscn"):
			_shots += 1
	)
	var player = load("res://scenes/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	player.shooting_delay_timer.stop()
	player.shooting_audio.stream = null
	_check(is_equal_approx(player.loadout.fire_delay, 0.3), "base fire interval must be 0.30 seconds")
	await process_frame
	for action in ["all_fire", "keyboard_fire", "gamepad1_fire", "gamepad2_fire"]:
		player.controller = action.trim_suffix("_fire")
		player.canShooting = true
		var before := _shots
		Input.action_press(action)
		player._update_weapons(1.0 / 60.0)
		_check(_shots == before + 1, action + ": first press must fire once")
		await create_timer(0.1).timeout
		player._update_weapons(1.0 / 60.0)
		_check(_shots == before + 1, action + ": holding before cooldown must not repeat")
		await create_timer(0.25).timeout
		player._update_weapons(1.0 / 60.0)
		_check(_shots == before + 2, action + ": holding beyond cooldown must repeat once")
		Input.action_release(action)
		await create_timer(0.35).timeout
		player._update_weapons(1.0 / 60.0)
		_check(_shots == before + 2, action + ": release must stop firing after cooldown")
		Input.action_press(action)
		player._update_weapons(1.0 / 60.0)
		_check(_shots == before + 3, action + ": a new press after cooldown must fire immediately")
		Input.action_release(action)
		await process_frame
		Input.action_press(action)
		player._update_weapons(1.0 / 60.0)
		_check(_shots == before + 3, action + ": cooldown must prevent rapid extra shots")
		Input.action_release(action)
		await process_frame
	player.controller = "all"
	player.canShooting = true
	player.loadout.side_shot = true
	var before := _shots
	Input.action_press("all_fire")
	player._update_weapons(1.0 / 60.0)
	_check(_shots == before + 3, "side upgrade must emit one primary and two side shots")
	Input.action_release("all_fire")
	player.weapons.player = null
	player.vitals.player = null
	world.queue_free()
	await process_frame
	print("Player fire input: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)

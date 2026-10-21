extends "res://tests/test_progression_activation.gd"

func press_level(echo := false) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_L
	key.pressed = true
	key.echo = echo
	root.push_input(key, true)
	key = key.duplicate()
	key.pressed = false
	key.echo = false
	root.push_input(key, true)

func settle() -> void:
	for frame in 3: await process_frame

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = true
	globals.saveData.config.fullscreen = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.get_node("loader/Timer").stop()
	main.get_node("loader").free()
	main._debug_compact_enabled = false
	await settle()
	var binding := InputEventKey.new()
	binding.keycode = KEY_L
	binding.pressed = true
	check(binding.is_action_pressed("debug_level_up"), "L must use the project's actual debug_level_up binding")
	press_level()
	check(not main.has_node("world") and main._selection == null, "the shortcut cannot create a run outside gameplay")
	for coop in [false, true]:
		globals.coop = coop
		var world: Variant = start_world()
		var controller: Variant = world.progression
		await settle()
		events.xp_collected.emit(3, &"player1")
		await settle()
		globals.Debug = false
		press_level()
		check(controller.progression.level == 1 and controller.progression.xp == 3 and not controller.debug_gain_level(), "disabled debug must reject both input and direct cheat calls")
		globals.Debug = true
		main.menuShow = true
		main._sync_pause()
		press_level()
		check(controller.progression.level == 1 and not controller.debug_gain_level(), "pause menu must not grant or queue a level")
		main.menuShow = false
		main._sync_pause()
		main._set_debug_full(true)
		press_level()
		check(controller.progression.level == 1, "the full inspector must consume the shortcut without changing XP")
		main._set_debug_full(false)
		main._transitioning = true
		press_level()
		check(controller.progression.level == 1, "screen transitions must ignore the shortcut")
		main._transitioning = false
		press_level(true)
		check(controller.progression.level == 1, "held-key repeat must not grant a level")
		var encounter_state: int = globals.run_random.encounters.state
		var drop_state: int = globals.run_random.drops.state
		var offer_state: int = globals.run_random.upgrades.state
		press_level()
		press_level()
		check(controller.progression.level == 2 and controller.progression.xp == 0 and controller.progression.pending_count() == 1, "a fresh press grants only the missing XP; repeated input before deferral cannot queue another level")
		check(main._selection == null and globals.run_random.upgrades.state == offer_state, "level selection and offer generation must remain safely deferred")
		var ui: Variant = await wait_ready()
		check(ui != null and paused and ui.participants.size() == (2 if coop else 1), "the normal paused choice must include exactly the living solo/co-op participants")
		check(globals.run_random.encounters.state == encounter_state and globals.run_random.drops.state == drop_state, "the debug level must not alter encounter or drop RNG")
		check(world.get_node("hud")._level_label.text == "LEVEL 2", "the normal progression event must update the HUD")
		press_level()
		check(controller.progression.level == 2 and not controller.debug_gain_level(), "an open choice must reject more debug levels")
		for id in ui.participants:
			check(ui.participants[id].offers.size() == 3, "debug levels must generate real eligible upgrade cards")
			check(ui.confirm_choice(ui.selection_id, id, ui.participants[id].offers[0].id), "normal confirmation must apply the chosen personal upgrade")
		for player in controller.players:
			check(player.loadout.acquired_ranks.size() == 1, "the cheat cannot bypass normal upgrade application")
		await settle()
		press_level()
		check(controller.progression.level == 2, "the closing animation must preserve the selection pause guard")
		await create_timer(0.2).timeout
		await settle()
		check(main._selection == null and not paused, "confirming the last participant must resume ordinary gameplay")
		press_level()
		ui = await wait_ready()
		check(controller.progression.level == 3 and controller.progression.xp == 0 and ui != null, "a new press after resuming must grant exactly the next level")
		world.queue_free()
		await settle()
		check(main._selection == null and not paused, "removing the world must cancel a shortcut-created selection normally")
	var world: Variant = start_world()
	var controller: Variant = world.progression
	for player in controller.players: player.state = player.State.DYING
	press_level()
	check(controller.progression.level == 1 and main._selection == null, "no eligible living participant means no level or pause")
	for player in controller.players: player.state = player.State.ACTIVE
	controller.cancel()
	press_level()
	check(controller.progression.level == 1 and not controller.debug_gain_level(), "a cancelled progression controller must reject the shortcut")
	main.free()
	await process_frame
	check(not paused, "teardown must leave no stale pause")
	print("Debug level-up shortcut: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

extends SceneTree

var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion, true)
	var button := InputEventMouseButton.new()
	button.position = position
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = true
	root.push_input(button, true)
	button = button.duplicate()
	button.pressed = false
	root.push_input(button, true)
	await process_frame

func _press_key(code: Key, shift := false, echo := false) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.shift_pressed = shift
	key.pressed = true
	key.echo = echo
	root.push_input(key, true)
	key = key.duplicate()
	key.pressed = false
	key.echo = false
	root.push_input(key, true)
	await process_frame

func _run() -> void:
	var globals = root.get_node("global")
	var events = root.get_node("Events")
	globals.Debug = true
	globals.coop = true
	var main := Node.new()
	root.add_child(main)
	main.set_script(load("res://scenes/main/main.gd"))
	main.process_mode = Node.PROCESS_MODE_ALWAYS
	main.set_process_input(true)
	main.worldScreen = true
	var world = load("res://scenes/world/world.tscn").instantiate()
	world.name = "world"
	world.get_node("waveGenerator").set_movement_seed(1234)
	main.add_child(world)
	await process_frame
	var spawner = world.get_node("waveGenerator")
	spawner.set_physics_process(false)
	for player in get_nodes_in_group(&"player"):
		player.set_physics_process(false)
	var key := InputEventKey.new()
	key.keycode = KEY_F10
	key.pressed = true
	_check(key.is_action_pressed("debug_screen"), "F10 is mapped to the debug screen")
	globals.Debug = false
	main._input(key)
	_check(main.get("_debug_screen") == null, "debug-disabled runs cannot create the inspector")
	globals.Debug = true
	main._transitioning = true
	main._input(key)
	_check(main.get("_debug_screen") == null, "screen transitions cannot open the inspector")
	main._transitioning = false
	var before_rng: int = spawner.director.random.encounters.state
	var before_enemy_rng: int = spawner.director.random.enemies.state
	var before_drop_rng: int = spawner.director.random.drops.state
	var before_upgrade_rng: int = spawner.director.random.upgrades.state
	var before_budget: float = spawner._budget_left
	main._input(key)
	var screen = main.get("_debug_screen")
	_check(is_instance_valid(screen) and screen.visible, "F10 opens the inspector through the main input handler")
	_check(screen.layer > 10 and screen.layer < 100, "inspector appears above pause/gameplay and below transitions")
	_check(paused and spawner._running, "opening the full inspector pauses gameplay without stopping the run")
	_check(screen.get_node("Panel").visible and not screen.get_node("Compact").visible, "full view replaces the compact display")
	_check(screen._pages.size() == 5, "run, enemy, player, performance and event pages exist")
	_check(screen._snapshot.director.seed == 1234, "inspector shows the actual run seed")
	_check(screen._snapshot.players.size() == 2, "co-op exposes both individual builds")
	_check(screen._pages["RUN"].text.contains("Danger:"), "internal danger is visible in the debug view")
	_check(screen._pages["RUN"].text.contains("not integrated yet"), "planned boss/XP mechanics are distinguished from live state")
	_check(screen._pages["PLAYERS"].text.contains("PLAYER1") and screen._pages["PLAYERS"].text.contains("PLAYER2"), "both players are rendered")
	_check(screen._pages["PERF"].text.contains("FPS:") and screen._pages["PERF"].text.contains("Parked:"), "performance and pool data are rendered")
	await process_frame
	await process_frame
	var tab_bar: TabBar = screen._tabs.get_tab_bar()
	for page in [1, 2, 3, 4, 0]:
		await _click(tab_bar.global_position + tab_bar.get_tab_rect(page).get_center())
		_check(screen._tabs.current_tab == page and paused, "mouse click selects debug tab %d while paused" % page)
	await _press_key(KEY_LEFT)
	_check(screen._tabs.current_tab == 4 and paused, "Left wraps from the first to the last tab while paused")
	await _press_key(KEY_RIGHT)
	_check(screen._tabs.current_tab == 0, "Right wraps from the last to the first tab")
	await _press_key(KEY_TAB)
	_check(screen._tabs.current_tab == 1, "Tab selects the next debug tab")
	await _press_key(KEY_TAB, true)
	_check(screen._tabs.current_tab == 0, "Shift-Tab selects the previous debug tab")
	await _press_key(KEY_RIGHT, false, true)
	_check(screen._tabs.current_tab == 0, "key repeat does not cycle tabs repeatedly")
	screen.set_process(false)
	var long_text := ""
	for index in 150:
		long_text += "Scroll test line %d\n" % index
	screen._pages["RUN"].text = long_text
	await process_frame
	await process_frame
	var scroll: VScrollBar = screen._pages["RUN"].get_v_scroll_bar()
	await _press_key(KEY_DOWN)
	_check(scroll.value > 0, "Down scrolls the current debug page")
	var previous_scroll := scroll.value
	await _press_key(KEY_PAGEDOWN)
	_check(scroll.value > previous_scroll, "PageDown scrolls by a page")
	previous_scroll = scroll.value
	await _press_key(KEY_PAGEUP)
	_check(scroll.value < previous_scroll, "PageUp scrolls back by a page")
	await _press_key(KEY_END)
	_check(is_equal_approx(scroll.value, scroll.max_value - scroll.page), "End scrolls to the bottom")
	previous_scroll = scroll.value
	await _press_key(KEY_UP)
	_check(scroll.value < previous_scroll, "Up scrolls back toward the top")
	await _press_key(KEY_HOME)
	_check(is_zero_approx(scroll.value), "Home scrolls to the top")
	screen.set_process(true)
	await _press_key(KEY_ESCAPE)
	_check(not paused and not main._debug_full_open, "Escape closes the inspector and resumes its paused run")
	await _press_key(KEY_RIGHT)
	_check(screen._tabs.current_tab == 0 and not paused, "compact mode does not navigate hidden tabs")
	main._input(key)
	for index in 10:
		events.debug_snapshot_requested.emit()
	_check(spawner.director.random.encounters.state == before_rng and spawner.director.random.enemies.state == before_enemy_rng, "reading snapshots does not consume encounter/enemy randomness")
	_check(spawner.director.random.drops.state == before_drop_rng and spawner.director.random.upgrades.state == before_upgrade_rng, "reading snapshots does not consume reward randomness")
	_check(is_equal_approx(spawner._budget_left, before_budget), "reading snapshots cannot spend threat budget")
	key.echo = true
	main._input(key)
	_check(screen.visible, "holding F10 cannot repeatedly toggle the overlay")
	key.echo = false
	var frozen_time: float = spawner.director.elapsed
	spawner.set_physics_process(true)
	await create_timer(0.1).timeout
	_check(spawner.director.elapsed == frozen_time, "full inspector freezes simulation")
	main._input(key)
	_check(not paused and screen.visible and screen.get_node("Compact").visible, "closing full view restores live compact mode")
	_check(not screen.get_node("Panel").visible and screen.get_node("Compact/Margin/Stats").text.contains("FOES"), "compact view renders essential metrics")
	spawner.set_physics_process(true)
	var before_time: float = spawner.director.elapsed
	await physics_frame
	await physics_frame
	spawner.set_physics_process(false)
	_check(spawner.director.elapsed > before_time, "simulation continues while the compact display is open")
	paused = true
	main._input(key)
	events.debug_snapshot_requested.emit()
	_check(screen._snapshot.paused and screen._status.text.begins_with("PAUSED"), "paused simulation is explicitly identified")
	var requests := {"count": 0}
	var count_request := func(): requests.count += 1
	events.debug_snapshot_requested.connect(count_request)
	await create_timer(0.3).timeout
	_check(requests.count > 0, "the inspector refreshes during pause")
	main._input(key)
	_check(screen.visible and screen.get_node("Compact").visible and paused, "closing full view preserves an existing pause")
	var mini_key := InputEventKey.new()
	mini_key.keycode = KEY_F11
	mini_key.pressed = true
	_check(mini_key.is_action_pressed("debug_compact"), "F11 is mapped to compact visibility")
	main._input(mini_key)
	_check(not screen.visible and not screen.is_processing() and paused, "F11 hides compact mode without changing pause")
	requests.count = 0
	await create_timer(0.3).timeout
	_check(requests.count == 0, "closed overlay stops requesting snapshots")
	main._input(key)
	_check(screen.visible and paused, "F10 can reopen the inspector during pause")
	main._input(key)
	_check(not screen.visible and paused, "closing full view respects hidden compact preference")
	paused = false
	main._input(key)
	for index in 100:
		world._debug_log("Entry %d" % index)
	events.debug_snapshot_requested.emit()
	_check(screen._snapshot.events.size() == 64 and screen._snapshot.events[0].ends_with("Entry 99"), "event history is bounded and newest-first")
	var player = world.get_node("player")
	player.apply_upgrade(load("res://data/upgrades/damage.tres"))
	events.debug_snapshot_requested.emit()
	_check(screen._snapshot.players[0].ranks.DAMAGE == 1, "player upgrade changes appear in snapshots")
	_check(screen._snapshot.events[0].contains("DAMAGE 1/"), "upgrade changes are recorded in the journal")
	var pool_service = load("res://scenes/combat/projectile_pool.gd")
	var shot = pool_service.spawn(load("res://scenes/player/player_shot.tscn"), Vector2(320, 300), world)
	events.debug_snapshot_requested.emit()
	_check(screen._snapshot.pool.active.player == 1, "active player shots are counted")
	pool_service.despawn(shot)
	await process_frame
	events.debug_snapshot_requested.emit()
	_check(screen._snapshot.pool.active.player == 0 and screen._snapshot.pool.parked >= 1, "parked shots are not counted as active")
	var killed = load("res://scenes/enemies/asteroid.tscn").instantiate()
	spawner.queue_enemy(killed)
	await process_frame
	var kills_before: int = screen._snapshot.enemy_removed.killed
	var escapes_before: int = screen._snapshot.enemy_removed.escaped
	killed.hitByPlayerShot = true
	killed._hit_something(killed.max_life, false)
	events.debug_snapshot_requested.emit()
	_check(screen._snapshot.enemy_removed.killed == kills_before + 1, "player kills are counted from actual enemy destruction")
	killed._on_screen_exited()
	events.debug_snapshot_requested.emit()
	_check(screen._snapshot.enemy_removed.escaped == escapes_before, "a destroyed enemy exiting the screen is not counted as an escape")
	await process_frame
	var escaped = load("res://scenes/enemies/asteroid.tscn").instantiate()
	spawner.queue_enemy(escaped)
	await process_frame
	escaped._on_screen_exited()
	escaped._on_screen_exited()
	events.debug_snapshot_requested.emit()
	_check(screen._snapshot.enemy_removed.escaped == escapes_before + 1, "duplicate screen exits count an escaped enemy only once")
	await process_frame
	globals.Debug = false
	screen._process(0.25)
	_check(not screen.visible and not screen.is_processing(), "disabling debug hides the overlay and stops sampling")
	_check(not paused, "disabling debug releases the inspector-owned pause")
	globals.Debug = true
	main._input(key)
	_check(paused, "full view can reopen after debug is reenabled")
	await _click(screen.get_node("Panel/Margin/Content/Header/Close").get_global_rect().get_center())
	_check(not paused and not screen.visible, "close button restores pause state and compact preference")
	main.set_Pause()
	main._input(key)
	_check(paused and main.menuShow, "full inspector can open above the pause menu")
	main._input(key)
	_check(paused and main.menuShow, "closing the inspector retains the pause menu")
	main.set_Resume()
	_check(not paused and not main.menuShow, "normal resume still works after inspector use")
	main._input(key)
	var start_key := InputEventKey.new()
	start_key.keycode = KEY_ENTER
	start_key.pressed = true
	if not start_key.is_action_pressed("start"):
		start_key = InputMap.action_get_events("start")[0].duplicate()
		start_key.pressed = true
	main._input(start_key)
	_check(not paused and not main.menuShow and not main._debug_full_open, "Start closes full view without opening the pause menu")
	main._input(key)
	events.debug_snapshot_requested.disconnect(count_request)
	spawner.stop_run()
	main.queue_free()
	await process_frame
	await process_frame
	_check(not is_instance_valid(screen), "the overlay is freed with its screen owner")
	_check(not paused, "freeing the screen owner releases its debug pause")
	print("Debug screen: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)

extends SceneTree

const CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")
const CATALOG: UpgradeTable = preload("res://data/upgrades/foundation_catalog.tres")
const STATS: PlayerStats = preload("res://data/player/player_stats.tres")
var failures := 0
var checks := 0
var main: Node
var choices: Array[Array] = []
var views := {}
var events: Node
var globals: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func participants(coop := true) -> Dictionary:
	var result := {}
	var random := RunRandom.new(314)
	for id in [&"player1", &"player2"] if coop else [&"player1"]:
		var build := PlayerLoadout.new(STATS)
		build.initialize_foundation(CONFIG, CATALOG.upgrades)
		var view := build.foundation_snapshot()
		var hand := CATALOG.generate_offers(view, {"energy": 3, "shield": 0}, random.upgrades, CONFIG, true)
		result[id] = {"build": view, "offers": hand.offers}
	return result

func action(name_value: StringName, pressed_value := true) -> InputEvent:
	for source in InputMap.action_get_events(name_value):
		if source is InputEventKey or source is InputEventJoypadButton:
			var mapped: InputEvent = source.duplicate()
			mapped.pressed = pressed_value
			return mapped
	var event := InputEventAction.new()
	event.action = name_value
	event.pressed = pressed_value
	return event

func on_choice(id: int, player: StringName, upgrade: StringName) -> void:
	choices.append([id, player, upgrade])
	events.upgrade_choice_applied.emit(id, player)

func wait_until_armed(ui: Variant) -> void:
	while Time.get_ticks_msec() < ui._armed_at:
		await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.save_webp(ProjectSettings.globalize_path("res://phase3_selection_%s.webp" % label), true) == OK, "native selection capture must save")

func check_categories(ui: Variant) -> void:
	for player_id in ui._panels:
		var cards: Array = ui._panels[player_id].get_meta("cards")
		for index in cards.size():
			var card: Button = cards[index]
			var offer: Dictionary = ui.participants[player_id].offers[index]
			var category := card.get_node("Category") as Label
			check(category.text == ui._category_text(offer.category) and category.text in ["OFFENSIVE", "UTILITY", "RECOVERY"], "each card exposes its authored category in solo and co-op")
			check(Rect2(Vector2.ZERO, card.size).encloses(Rect2(category.position, category.size)) and category.get_minimum_size().x <= category.size.x, "category labels fit their cards without clipping")
	check(ui._category_text(UpgradeDefinition.Category.REWARD) == "RECOVERY", "consumable energy is not presented as a utility family")

func run() -> void:
	events = root.get_node("Events")
	globals = root.get_node("global")
	globals.Debug = false
	globals.coop = true
	globals.saveData.config.fullscreen = false
	globals.saveData.config.player1 = "gamepad1"
	globals.saveData.config.player2 = "keyboard"
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(640, 400)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.get_node("loader/Timer").stop()
	main.get_node("loader").free()
	main._show_world_screen()
	main.get_node("world/waveGenerator").stop_run()
	events.upgrade_choice_requested.connect(on_choice)
	views = participants()
	Input.action_press("gamepad1_fire")
	Input.action_press("keyboard_upgrade_confirm")
	events.upgrade_selection_requested.emit(1, views, {"level": 2, "xp": 1, "next_threshold": 13})
	var ui: Variant = main._selection
	check(paused and main._selection_pause, "selection opening must acquire main's pause")
	check(not ui.confirm_choice(1, &"player1", views.player1.offers[0].id), "reveal must not accept premature confirmation")
	check(is_equal_approx(ui._flash.color.a, 0.18), "opening pulse must use the bounded contract alpha")
	await capture("coop_opening")
	await create_timer(0.34).timeout
	await wait_until_armed(ui)
	await capture("coop")
	check_categories(ui)
	check(is_equal_approx(ui._dim.color.a, 0.65), "opening must settle to the authored dim alpha")
	for panel in ui._panels.values():
		check(panel.find_children("BuildSlot*", "Panel", false, false).size() == 6 and panel.get_node_or_null("BuildSlot6") == null, "each co-op selection draws three offensive and three utility slots")
		for card in panel.get_meta("cards"):
			check(Rect2(Vector2.ZERO, panel.size).encloses(Rect2(card.position, card.size)), "native cards must remain inside their personal panel")
			var icon: TextureRect = card.get_node("Icon")
			var expected_row := 64 if panel.name == "Player2Panel" else 0
			check(icon.texture.region.size == Vector2(64, 64) and icon.texture.region.position.y == expected_row and icon.size == Vector2(64, 64) and icon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "co-op choices must use native 64px Nomad artwork with the correct team row and crisp sampling")
	Input.action_press("gamepad1_fire")
	for press in 3:
		main._input(action(&"gamepad1_fire"))
		main._input(action(&"keyboard_fire"))
	check(choices.is_empty() and not ui.ready_players.player1 and not ui.ready_players.player2, "repeated firing from either player cannot confirm a choice")
	main._input(action(&"keyboard_upgrade_confirm"))
	check(choices.is_empty() and not main.menuShow, "confirmation held when selection opens must be released without opening the pause menu")
	main._input(action(&"keyboard_upgrade_confirm", false))
	Input.action_release("keyboard_upgrade_confirm")
	check(ui._panels.player1.get_node("ControlsHint").text == "D-PAD / START" and ui._panels.player2.get_node("ControlsHint").text == "ARROWS / ENTER", "personal hints advertise a confirmation control distinct from firing")
	ui.handle_input(action(&"gamepad1_down"))
	check(ui.cursors.player1 == 1 and ui.cursors.player2 == 0, "P1 navigation must not move P2's cursor")
	check(Input.is_action_pressed("gamepad1_fire"), "holding fire does not block upgrade navigation")
	ui.handle_input(action(&"keyboard_down"))
	check(ui.cursors.player1 == 1 and ui.cursors.player2 == 1, "P2 keyboard navigation must be personal")
	check(not ui.confirm_choice(0, &"player1", views.player1.offers[1].id), "stale selection IDs must be ignored")
	check(not ui.confirm_choice(1, &"player1", &"unknown"), "unoffered upgrade IDs must be ignored")
	check(not ui.confirm_choice(1, &"unknown", &"speed"), "unregistered players must be ignored")
	Input.action_press("keyboard_fire")
	main._input(action(&"keyboard_upgrade_confirm"))
	check(ui.ready_players.player2 and not ui.ready_players.player1 and choices.size() == 1 and paused, "P2 may confirm first while P1 remains pending")
	check(not main.menuShow and Input.is_action_pressed("keyboard_fire"), "Enter confirms the keyboard owner while fire is held, without opening pause")
	await capture("coop_ready")
	main._input(action(&"keyboard_upgrade_confirm"))
	check(choices.size() == 1, "duplicate confirmation must not spend another choice")
	main.set_Pause()
	check(paused and main.menuShow and not ui.visible, "menu may suspend the existing selection")
	globals.saveData.config.player1 = "gamepad2"
	main.set_Resume()
	await process_frame
	check(paused and ui.visible and ui.ready_players.player2, "menu return must preserve selection pause and confirmations")
	check(ui._bindings.player1 == "gamepad2", "menu return must refresh reassigned controller bindings")
	main._input(action(&"gamepad1_upgrade_confirm"))
	check(not ui.ready_players.player1 and not main.menuShow, "old controller mapping must neither confirm nor open pause during a choice")
	Input.action_press("gamepad2_upgrade_confirm")
	main._input(action(&"gamepad2_upgrade_confirm"))
	check(ui.ready_players.player1 and choices.size() == 2, "new controller must confirm only its personal choice")
	var old_confirm: Button = ui._panels.player1.get_node("Confirm")
	events.upgrade_selection_requested.emit(2, views, {"level": 3, "xp": 2, "next_threshold": 16})
	var armed_at: int = ui._armed_at
	ui._armed_at = 0
	old_confirm.pressed.emit()
	ui._armed_at = armed_at
	check(choices.size() == 2 and not ui.ready_players.player1, "fading old panel callbacks must retain their old selection ID")
	check(ui == main._selection and ui.opening_count == 1 and not ui.ready_players.player1 and not ui.ready_players.player2, "queued levels must reuse one opening and reset personal confirmations")
	events.upgrade_selection_finished.emit(1)
	check(not ui._closing, "stale completion must not close the next selection")
	await create_timer(0.15).timeout
	await wait_until_armed(ui)
	check(ui.audio.session_count == 1, "queued levels must retain one musical session")
	main._input(action(&"gamepad2_upgrade_confirm"))
	check(choices.size() == 2 and not ui.ready_players.player1 and not main.menuShow, "held Start cannot confirm the next queued level or open pause")
	var echo := action(&"keyboard_upgrade_confirm") as InputEventKey
	echo.echo = true
	main._input(echo)
	check(not ui.ready_players.player2, "keyboard repeat cannot confirm a queued choice")
	main._input(action(&"gamepad2_upgrade_confirm", false))
	Input.action_release("gamepad2_upgrade_confirm")
	main._input(action(&"gamepad2_upgrade_confirm"))
	check(choices.size() == 3 and ui.ready_players.player1 and not ui.ready_players.player2, "a fresh Start press confirms only the controller owner's queued choice")
	main._set_debug_full(true)
	check(paused and ui.suspended, "inspector must suspend selection input")
	events.upgrade_selection_finished.emit(2)
	await create_timer(0.18).timeout
	check(paused and not main._selection_pause and main._debug_full_open, "closing selection must preserve inspector pause")
	main._set_debug_full(false)
	check(not paused, "closing final pause owner must resume gameplay")
	main._input(action(&"gamepad1_upgrade_confirm"))
	check(main.menuShow and paused, "Start keeps its ordinary pause behavior outside upgrade selection")
	main.set_Resume()
	check(main.get_node("world/music").playing and not main.get_node("world/music").stream_paused, "nested selection/inspector pause must not leave gameplay music suspended")
	globals.coop = false
	views = participants(false)
	events.upgrade_selection_requested.emit(3, views, {"level": 2, "xp": 0, "next_threshold": 13})
	await create_timer(0.34).timeout
	ui = main._selection
	await wait_until_armed(ui)
	main._input(action(&"all_fire"))
	check(not ui.ready_players.player1, "solo firing cannot confirm an upgrade")
	check(ui._panels.player1.get_node("ControlsHint").text.contains("ENTER") and ui._panels.player1.get_node("ControlsHint").text.contains("START"), "solo hints include both keyboard and gamepad confirmation")
	check(ui._panels.size() == 1 and ui._panels.player1.size.x == 608, "solo must use the approved horizontal wide panel")
	check(ui._panels.player1.find_children("BuildSlot*", "Panel", false, false).size() == 6, "solo draws the same six configured family slots")
	var solo_icon: TextureRect = ui._panels.player1.get_meta("cards")[0].get_node("Icon")
	check(solo_icon.texture.region.size == Vector2(64, 64) and solo_icon.size == Vector2(64, 64), "solo menu must display 64px Nomad effect artwork at native scale")
	await capture("solo")
	check_categories(ui)
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(960, 400)
		await process_frame
		await capture("solo_wide")
		check(is_equal_approx(ui._root.position.x, (root.get_visible_rect().size.x - 640) * 0.5), "wide selection core must remain centered")
	var cards: Array = ui._panels.player1.get_meta("cards")
	cards[2].pressed.emit()
	check(ui.cursors.player1 == 2, "a mouse card action must address its owning panel")
	main._input(action(&"all_upgrade_confirm"))
	check(ui.ready_players.player1 and choices.size() == 4 and not main.menuShow, "Enter confirms a solo choice instead of opening pause")
	main._transitioning = true
	main._cancel_selection()
	await create_timer(0.2).timeout
	check(paused and not main._selection_pause and main._selection == null, "cancelled callbacks cannot release transition pause")
	main._transitioning = false
	main._sync_pause()
	main.queue_free()
	await process_frame
	check(not paused, "removing the screen owner must release its remaining pause")
	print("Upgrade selection: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

extends SceneTree

var checks := 0
var failures := 0
var main: Node
var events: Node
var globals: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func start_world() -> Variant:
	main._show_world_screen()
	var world := main.get_node("world")
	world.get_node("waveGenerator").stop_run()
	for player in world.progression.players:
		player.set_physics_process(false)
	return world

func wait_ready() -> Variant:
	for frame in 3: await process_frame
	var ui: Variant = main._selection
	if ui:
		while Time.get_ticks_msec() < ui._armed_at: await process_frame
	return ui

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://phase3_playable_%s.webp" % label), true) == OK, "playable capture must save")

func run() -> void:
	events = root.get_node("Events")
	globals = root.get_node("global")
	globals.Debug = false
	globals.coop = true
	globals.saveData.config.fullscreen = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.get_node("loader/Timer").stop()
	main.get_node("loader").free()
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(640, 400)
	var world: Variant = start_world()
	var controller: Variant = world.progression
	var p1: Variant = controller.players[0]
	var p2: Variant = controller.players[1]
	check(controller.progression.level == 1 and controller.progression.xp == 0 and p1.loadout.acquired_ranks.is_empty(), "live runs must start with empty shared XP and personal foundation builds")
	check(is_equal_approx(p1.loadout.attraction_radius, 24) and is_equal_approx(p1.loadout.fire_delay, 0.2), "live players must now use foundation initialization")
	for kill in 2:
		var turret = load("res://scenes/enemies/turret.tscn").instantiate()
		turret.position = p1.position + Vector2(0, -10)
		world.add_child(turret)
		turret.hitByPlayerShot = true
		turret._hit_something(turret.max_life, false)
		for frame in 12: await physics_frame
	var earned_ui: Variant = await wait_ready()
	check(earned_ui != null and controller.pool.emitted == 12 and controller.pool.collected == 12, "actual enemy defeats, orb attraction and collection must reach a live level-up")
	check(controller.progression.level == 2 and controller.progression.xp == 2, "natural reward integration must retain collected excess")
	for id in [&"player2", &"player1"]:
		earned_ui.confirm_choice(earned_ui.selection_id, id, earned_ui.participants[id].offers[0].id)
	await create_timer(0.2).timeout
	for frame in 3: await process_frame
	world.queue_free()
	await process_frame
	world = start_world()
	controller = world.progression
	p1 = controller.players[0]
	p2 = controller.players[1]
	events.xp_collected.emit(100, &"player1")
	var ui: Variant = await wait_ready()
	check(ui != null and paused and ui.participants.size() == 2, "shared XP must open one paused personal choice per living co-op player")
	await capture("coop_choices")
	var previous_id := 0
	for level in range(2, 7):
		ui = await wait_ready()
		check(ui != null and ui.selection_id != previous_id and ui._progress.text.begins_with("LEVEL %d " % level), "queued choices must display earned levels in FIFO order")
		previous_id = ui.selection_id
		var state: int = globals.run_random.upgrades.state
		var p2_offer: StringName = ui.participants.player2.offers[0].id
		check(ui.confirm_choice(ui.selection_id, &"player2", p2_offer), "P2 may confirm a valid personal offer first")
		check(paused and ui.ready_players.player2 and not ui.ready_players.player1, "P2-first confirmation must preserve P1's choice and pause")
		check(globals.run_random.upgrades.state == state, "confirmations must not consume offer randomness")
		check(not ui.confirm_choice(ui.selection_id, &"player2", p2_offer), "duplicate personal confirmations must be rejected")
		var p1_offer: StringName = ui.participants.player1.offers[0].id
		check(ui.confirm_choice(ui.selection_id, &"player1", p1_offer), "P1's choice must complete the current level")
	await create_timer(0.2).timeout
	for frame in 3: await process_frame
	check(not paused and main._selection == null and controller.progression.level == 6 and controller.progression.xp == 13, "final queued choice must close and resume without losing excess XP")
	check(world.get_node("music").playing and not world.get_node("music").stream_paused, "real gameplay music must resume after the selection pause releases")
	check(p1.loadout.foundation_snapshot().utility_count <= 3 and p2.loadout.foundation_snapshot().offensive_count <= 3, "live choices must obey personal slot caps")
	check(world.get_node("hud")._level_label.text == "LEVEL 6", "HUD must display shared progression through events")
	check(world.get_node("hud/RightColumn/Progression").get_child_count() == 2 and not world.get_node("hud")._xp_bar.show_percentage, "HUD progression must show the level and its progress bar without a numeric XP counter")
	check(is_equal_approx(world.get_node("hud")._xp_bar.value, controller.progression.xp) and is_equal_approx(world.get_node("hud")._xp_bar.max_value, controller.progression.next_threshold()), "level progress bar must reflect the shared XP remainder and next threshold")
	check(world.get_node("hud")._build_controls.size() == 2, "HUD must maintain two personal builds")
	for holder in world.get_node("hud")._build_controls.values():
		for row in holder.find_children("*", "HBoxContainer", false, false):
			check(row.get_child_count() == 3, "each personal HUD category draws three slots from its build capacity")
	await capture("coop_hud")
	p1.weapons.fire_primary()
	p2.weapons.fire_primary()
	var owners := {}
	for child in world.get_children():
		if child.is_in_group("player_Shot"): owners[child.player_Id] = true
	check(owners.has("player1") and owners.has("player2"), "live red/blue projectiles must retain personal weapon ownership")
	await create_timer(0.12).timeout
	await capture("coop_projectiles")
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(960, 400)
		await process_frame
		await capture("coop_hud_wide")
	events.xp_collected.emit(100, &"player2")
	ui = await wait_ready()
	var stale_id: int = ui.selection_id
	world.queue_free()
	await process_frame
	check(main._selection == null and not paused, "removing the world during choices must cancel its pause and pending offers")
	world = start_world()
	controller = world.progression
	check(controller.progression.level == 1 and controller.pool.snapshot().value == 0 and controller.players[0].loadout.acquired_ranks.is_empty(), "a replacement world must reset XP, orb reservations and personal ranks")
	events.upgrade_choice_requested.emit(stale_id, &"player1", &"damage")
	check(controller.players[0].loadout.acquired_ranks.is_empty(), "old-world confirmations must not modify replacement players")
	p1 = controller.players[0]
	p2 = controller.players[1]
	p1.state = p1.State.DYING
	events.xp_collected.emit(10, &"player2")
	ui = await wait_ready()
	check(ui.participants.size() == 1 and ui.participants.has(&"player2"), "same-tick death and XP must exclude a dying participant before its delayed death event")
	ui.confirm_choice(ui.selection_id, &"player2", ui.participants.player2.offers[0].id)
	await create_timer(0.2).timeout
	for frame in 3: await process_frame
	p2.state = p2.State.DYING
	events.xp_collected.emit(100, &"player1")
	for frame in 3: await process_frame
	check(main._selection == null and not main._selection_pause, "no eligible players must not acquire a choice pause or stall game over")
	world.queue_free()
	await process_frame
	globals.coop = false
	world = start_world()
	controller = world.progression
	p1 = controller.players[0]
	for file in ["speed", "damage", "fire_rate"]:
		var upgrade = load("res://data/upgrades/foundation/%s.tres" % file)
		for rank in upgrade.max_rank: p1.apply_upgrade(upgrade)
	for rank in 3: p1.apply_upgrade(load("res://data/upgrades/foundation/side_shot.tres"))
	for id in ["critical_hits", "energy_chains"]:
		for rank in 3: p1.apply_upgrade(load("res://data/upgrades/%s.tres" % id))
	p1.energy = 12
	p1.update_energy()
	var score_before: int = globals.score
	events.xp_collected.emit(40, &"player1")
	ui = await wait_ready()
	check(ui.participants.size() == 1 and ui.participants.player1.offers.size() == 1 and ui.participants.player1.offers[0].id == &"side_shot", "solo capped builds must receive the one remaining useful rank")
	ui.confirm_choice(ui.selection_id, &"player1", &"side_shot")
	for frame in 10: await process_frame
	await create_timer(0.2).timeout
	check(not paused and main._selection == null and globals.score == score_before + 1000, "automatic fallback-only queued levels must still close the last visible selection")
	p1.debug_max_stats()
	check(p1.loadout.foundation_snapshot().utility_count == 3 and is_equal_approx(p1.loadout.direct_damage_multiplier, 2.25) and p1.defenses.charges == 0, "debug maximum must respect valid utility slots and foundation damage and acquired shield ranks")
	check(is_equal_approx(p1.get_debug_snapshot().primary_damage, 2.25) and is_equal_approx(p1.get_debug_snapshot().side_damage, 2.25), "inspector weapon values must match actual foundation damage")
	p1.weapons.fire_primary()
	var shots := []
	for child in world.get_children():
		if child.is_in_group("player_Shot"): shots.append(child)
	check(shots.size() == 5, "maximum side rank must emit the main cannon and two side pairs")
	var amounts := []
	for shot in shots: amounts.append(shot.damage)
	amounts.sort()
	check(is_equal_approx(amounts[0], 1.35) and is_equal_approx(amounts[2], 2.25) and is_equal_approx(amounts[4], 2.25), "main, side and outer-pair damage must apply common and outer multipliers exactly once")
	await capture("solo_maximum")
	p1.beam_charge = 50
	p1._update_beam(0.01, true)
	check(p1.beam_active and not p1.continuous_beam.overdrive and is_equal_approx(p1.continuous_beam.damage, 4.25), "manual signature must keep separate additive plasma damage")
	await capture("plasma_normal")
	p1._stop_beam()
	p1.beam_charge = 100
	p1._update_beam(0.01, true)
	check(p1.continuous_beam.overdrive and p1.loadout.foundation_snapshot().offensive_count == 3, "full-reserve overdrive must remain native and outside offensive slots")
	await capture("plasma_overdrive")
	p1._stop_beam()
	controller.pool.spawn(1, p1.global_position + Vector2(-32, -160))
	controller.pool.spawn(6, p1.global_position + Vector2(0, -160))
	var cell = load("res://scenes/ui/plasma_cell.tscn").instantiate()
	cell.position = p1.position + Vector2(32, -160)
	world.add_child(cell)
	for frame in 3: await process_frame
	check(cell.get_node("Sprite2D").hframes == 1 and cell.get_node("Sprite2D").texture.get_size() == Vector2(16, 16), "plasma pickup must use its dedicated native sprite instead of the old atlas")
	await capture("xp_and_plasma")
	for entry in controller.pool._entries:
		entry.node.set_physics_process(false)
		entry.node.global_position = Vector2(620 if entry.amount == 1 else 652, 286)
	await capture("xp_contrast")
	var baseline_nodes := 0
	for cycle in 5:
		for index in 150: controller.pool.spawn(1, Vector2(300, 100))
		world.queue_free()
		for frame in 3: await process_frame
		world = start_world()
		controller = world.progression
		for frame in 3: await process_frame
		check(controller.pool.snapshot().active == 0 and controller.pool.snapshot().reserved == 0, "restart must cancel queued orb materialization from the removed world")
		if cycle == 0:
			baseline_nodes = get_node_count()
		else:
			check(get_node_count() == baseline_nodes, "repeated world replacement must not grow the scene tree")
	main.queue_free()
	await process_frame
	check(not paused, "teardown must leave no stale selection pause")
	print("Progression activation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

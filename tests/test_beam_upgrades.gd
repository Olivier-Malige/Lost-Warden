extends SceneTree

const CATALOG := preload("res://data/upgrades/foundation_catalog.tres")
const MINI := preload("res://assets/sprites/ui/upgrade_miniatures.png")
var checks := 0
var failures := 0
var main: Node
var world: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func definition(id: StringName) -> UpgradeDefinition:
	for entry in CATALOG.upgrades:
		if entry.id == id: return entry
	return null

func start_world() -> void:
	main._show_world_screen()
	world = main.get_node("world")
	world.get_node("waveGenerator").stop_run()
	for player in world.progression.players:
		player.set_physics_process(false)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://phase3_beam_upgrades_%s.webp" % label), true) == OK, "beam upgrade capture must save")

func run() -> void:
	var globals := root.get_node("global")
	var events := root.get_node("Events")
	globals.coop = true
	globals.Debug = false
	globals.saveData.config.fullscreen = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.get_node("loader/Timer").stop()
	main.get_node("loader").free()
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(640, 400)
	start_world()
	var p1: Variant = world.progression.players[0]
	var p2: Variant = world.progression.players[1]
	p1.beam_charge = 100
	check(p1.apply_upgrade(definition(&"beam_capacity")).applied, "live player must accept the reserve upgrade")
	check(is_equal_approx(p1.loadout.beam_capacity, 125) and is_equal_approx(p1.beam_charge, 100), "reserve upgrade must preserve existing charge without granting free plasma")
	var bar: ProgressBar = world.get_node("hud/LeftColumn/plasma_holder_player1/plasma_player1")
	check(is_equal_approx(bar.max_value, 125) and is_equal_approx(bar.value, 100), "HUD must immediately publish the personal upgraded reserve")
	check(is_equal_approx(p2.loadout.beam_capacity, 100), "personal reserve upgrade must not alter the partner")
	p1._update_beam(0.0, true)
	check(p1.beam_active and not p1.continuous_beam.overdrive, "old base capacity must no longer count as full after reserve expansion")
	p1._stop_beam()
	for rank in [2, 3]:
		check(p1.apply_upgrade(definition(&"beam_capacity")).rank == rank, "live reserve ranks must progress to their cap")
	p1.beam_charge = 0
	for rank in range(1, 4):
		check(p1.apply_upgrade(definition(&"beam_recharge")).rank == rank, "live recovery ranks must progress to their cap")
		check(is_zero_approx(p1.beam_charge), "recovery rank selection must not grant immediate plasma")
	check(p1.apply_upgrade(definition(&"beam_capacity")).capped and p1.apply_upgrade(definition(&"beam_recharge")).capped, "live capped families must not change their totals")
	check(p1.apply_upgrade(definition(&"damage")).applied and not p1.apply_upgrade(definition(&"speed")).applied, "beam families must participate in the three-utility capacity rule")
	check(p1.apply_upgrade(definition(&"side_shot")).applied and p2.apply_upgrade(definition(&"beam_capacity")).applied, "offensive and partner upgrades must retain independent slots")
	p1.beam_charge = 0
	p2.beam_charge = 0
	var cell = load("res://scenes/ui/plasma_cell.tscn").instantiate()
	cell.position = p1.position
	world.add_child(cell)
	for frame in 4: await physics_frame
	check((not is_instance_valid(cell) or cell._collected) and is_equal_approx(p1.beam_charge, 21.875) and is_equal_approx(p2.beam_charge, 12.5), "real pickup collision must credit shared base plasma once with each player's own recovery multiplier")
	var before: float = p1.beam_charge
	for amount in [-1.0, 0.0, NAN, INF]: p1.add_beam_charge(amount)
	check(is_equal_approx(p1.beam_charge, before), "invalid charge amounts must not drain or corrupt the reserve")
	p1.state = p1.State.DYING
	events.plasma_collected.emit(10.0)
	check(is_equal_approx(p1.beam_charge, before) and is_equal_approx(p2.beam_charge, 22.5), "dying players must ignore shared recharge while the living partner still receives it")
	p1.state = p1.State.ACTIVE
	p1.add_beam_charge(1000)
	check(is_equal_approx(p1.beam_charge, 175) and is_equal_approx(bar.max_value, 175) and is_equal_approx(bar.value, 175), "scaled recovery must clamp to the expanded personal capacity and fill its HUD")
	p1._update_beam(0.1, true)
	check(p1.continuous_beam.overdrive and is_equal_approx(p1.beam_charge, 173), "overdrive must require the new full reserve and keep the original twenty-per-second drain")
	check(is_equal_approx(p1.continuous_beam.damage, 3.25), "charge upgrades must preserve the separate additive damage adapter")
	p1._stop_beam()
	for frame in 2: await process_frame
	var hud := world.get_node("hud")
	for id in [&"player1", &"player2"]:
		var row: HBoxContainer = hud._build_controls[id].get_child(3)
		var icon: TextureRect = row.get_child(0).get_child(0)
		check(icon.texture.atlas == MINI and icon.texture.region.size == Vector2(16, 16) and icon.texture.region.position.y == (16 if id == &"player2" else 0), "HUD miniatures must match the Nomad effect atlas and their owner's team row")
	await capture("hud")
	var snapshot: Dictionary = p1.get_debug_snapshot()
	check(is_equal_approx(snapshot.plasma_max, 175) and is_equal_approx(snapshot.plasma_pickup_multiplier, 1.75), "inspector snapshots must report the actual personal reserve and recovery")
	world.queue_free()
	for frame in 3: await process_frame
	start_world()
	p1 = world.progression.players[0]
	p2 = world.progression.players[1]
	check(is_zero_approx(p1.beam_charge) and is_equal_approx(p1.loadout.beam_capacity, 100) and is_equal_approx(p1.loadout.plasma_pickup_multiplier, 1), "new runs must reset charge, capacity, recovery and all acquired ranks")
	var participants := {}
	var random := RunRandom.new(882)
	var preview := UpgradeTable.new()
	for id in [&"beam_capacity", &"beam_recharge", &"side_shot", &"score"]: preview.upgrades.append(definition(id))
	for player in [p1, p2]:
		player.apply_upgrade(definition(&"beam_capacity"))
		player.apply_upgrade(definition(&"beam_recharge"))
		var build: Dictionary = player.loadout.foundation_snapshot()
		var hand := preview.generate_offers(build, {"energy": 12, "shield": 3}, random.upgrades, world.progression.CONFIG, true)
		participants[StringName(player.id_Player)] = {"build": build, "offers": hand.offers}
	events.upgrade_selection_requested.emit(990001, participants, {"level": 2, "xp": 0, "next_threshold": 13})
	await create_timer(0.34).timeout
	var ui: Variant = main._selection
	for id in [&"player1", &"player2"]:
		var cards: Array = ui._panels[id].get_meta("cards")
		check(cards.size() == 3, "new beam families must be offered together with eligible weapons")
		for card in cards:
			check(card.get_node("Icon").texture.region.size == Vector2(64, 64), "beam offers must use complete native effect illustrations")
		var miniature: TextureRect = ui._panels[id].get_node("BuildSlot4/Icon")
		check(miniature.texture.atlas == MINI, "menu utility miniatures must use the same dedicated atlas as the HUD")
	await capture("choices")
	main._cancel_selection()
	await create_timer(0.2).timeout
	main.queue_free()
	await create_timer(0.1).timeout
	print("Beam upgrades: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

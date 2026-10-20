extends SceneTree

var checks := 0
var failures := 0
var stage: Node2D
var globals: Node
var xp: Array[int] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func enemy(kind: String, elite := false) -> Variant:
	var node = load("res://scenes/enemies/%s.tscn" % kind).instantiate()
	var context := EnemySpawnContext.new()
	context.elite = elite
	context.elite_definition = load("res://data/waves/wave_spawner_config.tres").elite_definition
	node.configure_spawn(context)
	stage.add_child(node)
	node.global_position = Vector2(300, 100)
	node.set_physics_process(false)
	for timer in node.find_children("*", "Timer", true, false): timer.stop()
	for voice in node.find_children("*", "AudioStreamPlayer2D", true, false): voice.stream = null
	return node

func clear_stage() -> void:
	for child in stage.get_children(): child.queue_free()
	await process_frame

func run() -> void:
	globals = root.get_node("global")
	globals.coop = false
	stage = Node2D.new()
	root.add_child(stage)
	root.get_node("Events").xp_spawn_requested.connect(func(amount, _point): xp.append(amount))
	var kinds := ["drone", "tie", "interceptor", "turret", "mother_ship", "mother_ship_turret", "asteroid", "big_asteroid"]
	var chances := [45, 45, 75, 100, 100, 60, 35, 100]
	var values := [1, 1, 4, 6, 6, 2, 1, 2]
	var plasma := [11, 12, 63, 59, 55, 30, 4, 9]
	for index in kinds.size():
		var node: Variant = enemy(kinds[index])
		check(node.definition.is_valid(), "authored XP data must validate for " + kinds[index])
		for roll in 100:
			check(node._xp_for_roll(roll) == (values[index] if roll < chances[index] else 0), "ordinary XP chance/value must match its authored family")
			check(node._plasma_amount_for_roll(roll) == (12.5 if roll < plasma[index] else 0.0), "plasma must retain its independent authored chance and quantity")
			check(node._reward_for_roll(roll) != node.RewardDrop.POWER_UP, "no reward roll may yield a legacy direct power-up")
		await clear_stage()
	for seed_value in range(20):
		globals.reset_run(seed_value)
		var expected := RunRandom.new(seed_value)
		var node: Variant = enemy("interceptor")
		var expected_xp: int = node._xp_for_roll(expected.drops.randi_range(0, 99))
		var expected_plasma: float = node._plasma_amount_for_roll(expected.drops.randi_range(0, 99))
		xp.clear()
		node.hitByPlayerShot = true
		node._hit_something(node.max_life, false)
		node._hit_something(node.max_life, false)
		await process_frame
		check(xp == ([expected_xp] if expected_xp > 0 else []), "accepted defeat must issue XP at most once")
		check(globals.run_random.drops.state == expected.drops.state, "every accepted kill must draw XP then plasma exactly once each")
		var cells := 0
		for child in stage.get_children():
			if child.scene_file_path == "res://scenes/ui/plasma_cell.tscn":
				cells += 1
				check(is_equal_approx(child.charge_amount, expected_plasma), "independent plasma amount must match the second roll")
			check(child.scene_file_path != "res://scenes/ui/power_up.tscn", "ordinary defeats must never instantiate legacy power-ups")
		check(cells == int(expected_plasma > 0), "XP success must not exclude a successful plasma roll")
		await clear_stage()
	var elite: Variant = enemy("drone", true)
	xp.clear()
	elite.hitByPlayerShot = true
	elite._hit_something(elite.max_life, false)
	await process_frame
	check(xp == [6], "elite drone defeat must guarantee at least six XP")
	var elite_plasma := false
	for child in stage.get_children():
		if child.scene_file_path == "res://scenes/ui/plasma_cell.tscn": elite_plasma = is_equal_approx(child.charge_amount, 25)
		check(child.scene_file_path != "res://scenes/ui/power_up.tscn", "elite defeats must retire guaranteed direct power-ups")
	check(elite_plasma, "elite defeats must retain guaranteed large plasma")
	await clear_stage()
	var asteroid: Variant = enemy("big_asteroid")
	asteroid.hitByPlayerShot = true
	asteroid._hit_something(asteroid.max_life, false)
	await process_frame
	var fragments := 0
	for child in stage.get_children():
		if child is Area2D and child.get("definition") != null and child.definition.id == &"asteroid_small":
			fragments += 1
			check(child._spawn_context.asteroid_fragment and child._xp_for_roll(0) == 0 and child._plasma_amount_for_roll(0) == 12.5, "spawned fragments must disable only XP while retaining plasma")
	check(fragments > 0 and load("res://data/enemies/asteroid.tres").xp_drop_chance == 35, "fragment exclusion must not mutate the shared initial-asteroid resource")
	await clear_stage()
	xp.clear()
	var uncredited: Variant = enemy("drone")
	uncredited._hit_something(uncredited.max_life, false)
	await process_frame
	check(xp.is_empty(), "uncredited collisions must not create player XP")
	await clear_stage()
	var escaping: Variant = enemy("drone")
	escaping._on_screen_exited()
	await process_frame
	check(xp.is_empty(), "escapes must not award XP")
	var boss = load("res://scenes/bosses/dread_ark.tscn").instantiate()
	boss.boss_data = load("res://data/bosses/dread_ark.tres")
	stage.add_child(boss)
	boss.set_physics_process(false)
	xp.clear()
	var before := RunRandom.new(33)
	globals.reset_run(33)
	before.drops.randi_range(0, 99)
	before.drops.randi_range(0, 99)
	boss._award_player_kill()
	await process_frame
	check(xp == [20] and globals.run_random.drops.state == before.drops.state, "Dread Ark's reward override must issue twenty XP with the fixed roll order")
	var boss_plasma := false
	for child in stage.get_children():
		if child.scene_file_path == "res://scenes/ui/plasma_cell.tscn": boss_plasma = is_equal_approx(child.charge_amount, 25)
		check(child.scene_file_path != "res://scenes/ui/power_up.tscn", "boss override must never instantiate a legacy direct power-up")
	check(boss_plasma, "boss override must retain guaranteed large plasma")
	stage.queue_free()
	await process_frame
	print("XP rewards: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

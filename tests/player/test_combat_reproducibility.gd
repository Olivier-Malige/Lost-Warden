extends SceneTree

class Owner extends Node2D:
	var id_Player := "player1"
	var state := 0

var checks := 0
var failures := 0
var globals: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func freeze(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	for child in node.get_children():
		freeze(child)

func trace(seed_value: int, coop: bool, noise: bool) -> Dictionary:
	globals.coop = coop
	globals.reset_run(seed_value)
	var stage := Node2D.new()
	root.add_child(stage)
	var effects = load("res://scenes/combat/player_hit_effects.gd").new()
	effects.name = "PlayerHitEffects"
	stage.add_child(effects)
	var owners: Array = []
	for index in (2 if coop else 1):
		var owner := Owner.new()
		owner.id_Player = "player1" if index == 0 else "player2"
		stage.add_child(owner)
		owners.append(owner)
	effects.start(owners, globals.run_random)
	var spawner = load("res://tests/fixtures/xp_economy_spawner.gd").new()
	spawner.catalog = load("res://data/waves/wave_catalog.tres")
	spawner.config = load("res://data/waves/wave_spawner_config.tres")
	for index in spawner.config.lane_count:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % index
		marker.position = Vector2(116 + index * 37, -28)
		spawner.add_child(marker)
	stage.add_child(spawner)
	spawner.set_physics_process(false)
	var actors: Array = []
	spawner.enemy_spawned.connect(func(actor):
		freeze(actor)
		actors.append([String(actor.get_combat_identity()), String(actor.definition.id), actor._spawn_context.movement_seed])
		for child in actor.get_children():
			if child.is_in_group("enemy"):
				actors.append([String(child.get_combat_identity()), String(child.definition.id), child._spawn_context.movement_seed])
	)
	spawner.start_run()
	var sources: Array = []
	for tick in range(1, 1801):
		spawner.tick = tick
		spawner.advance()
		if tick % 100 == 0:
			for owner in owners:
				if noise:
					for index in 5:
						globals.run_random.combat_for(StringName(owner.id_Player)).randi()
						randi()
				var hit = effects.create_hit(StringName(owner.id_Player), 1.0, 1.25, {&"damage": 1})
				sources.append([String(hit.root_id()), hit.snapshot()])
				effects.release_root(hit)
	# Explicitly exercise the authored carrier and debris paths regardless of early encounter selection.
	for family in ["mother_ship", "big_asteroid"]:
		var context := EnemySpawnContext.new()
		context.combat_id = spawner._next_combat_identity()
		var definition: EnemyDefinition = load("res://data/enemies/%s.tres" % family)
		var item := {"scene": load("res://scenes/enemies/%s.tscn" % family), "position": Vector2(300, -28),
			"context": context, "generation": spawner._generation, "slots": definition.spawn_slots, "family": definition.id}
		spawner._reserve(item)
		spawner._materialize(item)
	for tick in range(1801, 1922):
		spawner.tick = tick
		spawner.advance()
	check(spawner._begin_boss(true), "authored boss must be selectable for the identity fixture")
	await process_frame
	await process_frame
	check(spawner._boss != null and spawner._boss.get_combat_identity() != &"", "boss materialization must receive an explicit actor identity")
	spawner._spawn_boss_reinforcements()
	for tick in range(1922, 1983):
		spawner.tick = tick
		spawner.advance()
	var ids := {}
	var mounted := 0
	var fragments := 0
	for actor in actors:
		check(actor[0] != "" and not ids.has(actor[0]), "spawn and child actor identities must be nonempty and unique")
		ids[actor[0]] = true
		mounted += int("/turret_" in actor[0])
		fragments += int("/fragment_" in actor[0])
	check(mounted == 2 and fragments >= 5, "carrier mounts and asteroid fragments must derive stable child identities: %d mounts, %d fragments" % [mounted, fragments])
	var states := {}
	for key in ["encounters", "enemies", "drops", "upgrades"]:
		states[key] = globals.run_random.get(key).state
	var result := {"actors": actors, "sources": sources, "states": states}
	spawner.stop_run()
	effects.cancel()
	check(effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "each replay must end with empty root/request bookkeeping")
	stage.free()
	await process_frame
	return result

func check_targeting_and_teardown() -> void:
	for cycle in 8:
		var stage := Node2D.new()
		root.add_child(stage)
		var owner := Owner.new()
		stage.add_child(owner)
		var effects = load("res://scenes/combat/player_hit_effects.gd").new()
		effects.name = "PlayerHitEffects"
		stage.add_child(effects)
		effects.start([owner], RunRandom.new(cycle))
		var pool := ProjectilePool.new()
		stage.add_child(pool)
		var targets: Array = []
		for id in [&"z_target", &"a_target"]:
			var actor = load("res://scenes/enemies/drone.tscn").instantiate()
			var context := EnemySpawnContext.new()
			context.combat_id = id
			actor.configure_spawn(context)
			stage.add_child(actor)
			actor.position = Vector2(360 if id == &"z_target" else 280, 200)
			actor.set_physics_process(false)
			actor.set_process(false)
			targets.append(actor)
		await physics_frame
		await process_frame
		var ordered := CombatTargeting.targets(stage, Vector2(320, 300), 200, {}, false)
		check(ordered.size() == 2 and ordered[0] == targets[1], "equal distances must sort by authored identity rather than group or instance order")
		check(CombatTargeting.has_line_of_sight(stage, Vector2(280, 300), targets[1]), "physics sight query must reach an exposed target")
		targets[0].position = Vector2(280, 250)
		await physics_frame
		await process_frame
		check(not CombatTargeting.has_line_of_sight(stage, Vector2(280, 300), targets[1]), "secondary acquisition must reject a target hidden behind another enemy")
		targets[0].position = Vector2(310, -100)
		check(not CombatTargeting.eligible(stage, targets[0]), "off-screen actors must not be target candidates")
		var hit = effects.create_hit(&"player1", 1, 1)
		effects.queue_projectile(hit, load("res://scenes/player/player_shot.tscn"), Vector2(200, 200), Vector2.ZERO, 0.1, 1)
		stage.free()
		await process_frame
		check(get_nodes_in_group("player_Shot").is_empty(), "queued collision objects must not survive world destruction")
	var first := Node2D.new()
	var second := Node2D.new()
	root.add_child(first)
	root.add_child(second)
	var first_pool := ProjectilePool.new()
	var second_pool := ProjectilePool.new()
	first.add_child(first_pool)
	second.add_child(second_pool)
	var shot = ProjectilePool.spawn(load("res://scenes/player/player_shot.tscn"), Vector2(300, 300), second)
	ProjectilePool.despawn(shot)
	await process_frame
	check(shot.get_parent() == second_pool, "pool lookup must remain scoped to its world when another world still exists")
	first.free()
	second.free()
	await process_frame

func run() -> void:
	globals = root.get_node("global")
	globals.Debug = false
	root.size = Vector2i(640, 400)
	var random := RunRandom.new(71)
	var p2_before: int = random.combat_for(&"player2").state
	for index in 100:
		random.combat_for(&"player1").randi()
	check(random.combat_for(&"player2").state == p2_before and random.combat_for(&"unknown") == null, "combat RNG is personal and requires an explicit owner")
	for coop in [false, true]:
		for seed_value in [0, 1, 42, 99]:
			var first := await trace(seed_value, coop, false)
			var repeated := await trace(seed_value, coop, false)
			var noisy := await trace(seed_value, coop, true)
			check(first == repeated and first == noisy, "same seed/input must replay identities and sources despite unrelated combat/cosmetic RNG draws")
	await check_targeting_and_teardown()
	check(checks > 1000, "all seeded actor traces must execute before acceptance")
	print("Combat reproducibility: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

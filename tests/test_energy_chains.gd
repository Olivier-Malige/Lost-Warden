extends "res://tests/player/test_player_hit_contract.gd"

const CHAIN: UpgradeDefinition = preload("res://data/upgrades/energy_chains.tres")
const CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")
const CATALOG: UpgradeTable = preload("res://data/upgrades/foundation_catalog.tres")
const ChainScene := preload("res://scenes/combat/energy_chain.tscn")
const Layers := preload("res://core/collision_layers.gd")

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = true
	globals.reset_run(301)
	root.size = Vector2i(640, 400)
	stage = Node2D.new()
	root.add_child(stage)
	pool = load("res://scenes/combat/projectile_pool.gd").new()
	stage.add_child(pool)
	effects = load("res://scenes/combat/player_hit_effects.gd").new()
	effects.name = "PlayerHitEffects"
	stage.add_child(effects)
	for index in 2:
		var player = load("res://scenes/player/player.tscn").instantiate()
		player.set_Player_2 = index == 1
		player.position = Vector2(200 + index * 250, 350)
		stage.add_child(player)
		player.set_physics_process(false)
		player.set_process(false)
		for kind in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
			for audio in player.find_children("*", kind, true, false): audio.stream = null
		if index == 0: p1 = player
		else: p2 = player
	effects.start([p1, p2], globals.run_random)
	effects.hit_accepted.connect(func(hit, target, position, first): accepted.append({"hit": hit, "target": target, "position": position, "first": first}))
	events.xp_spawn_requested.connect(func(_amount, _position): xp_events += 1)
	check(CHAIN.foundation_errors().is_empty() and PackedFloat32Array(CHAIN.rank_values) == PackedFloat32Array([1, 2, 3]) and PackedFloat32Array(CHAIN.range_values) == PackedFloat32Array([72, 88, 104]) and is_equal_approx(CHAIN.secondary_damage_scale, 0.45) and CHAIN.proc_cooldown == 0.5, "chain prototype data must match the approved contract")
	for field in ["range_values", "secondary_damage_scale", "proc_cooldown", "rank_values"]:
		var invalid := CHAIN.duplicate() as UpgradeDefinition
		match field:
			"rank_values": invalid.rank_values = PackedFloat32Array([1, 2.5, 4])
			"range_values": invalid.range_values = PackedFloat32Array([NAN])
			_: invalid.set(field, -1.0)
		check(not invalid.foundation_errors().is_empty(), "invalid chain data must reject: " + field)
	await rank_contacts()
	await targeting_cases()
	await cooldown_and_sources()
	await side_cannon()
	await lifecycle_cases()
	await boss_cases()
	await visual_lifetime()
	await moving_endpoints()
	if DisplayServer.get_name() != "headless": await native_presentation()
	await reset_case()
	stage.free()
	await process_frame
	print("Energy chains: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func reset_case() -> void:
	paused = false
	effects.cancel()
	for shot in get_nodes_in_group("player_Shot"):
		if not shot.get_meta("pooled", false): ProjectilePool.despawn(shot)
	await settle()
	for child in stage.get_children():
		if child not in [p1, p2, pool, effects]: child.free()
	for player in [p1, p2]:
		player.state = player.State.ACTIVE
		player.loadout.reset()
	effects.start([p1, p2], globals.run_random)
	accepted.clear()

func ranked(player: Node, rank: int) -> void:
	for value in rank: check(player.loadout.apply_foundation(&"energy_chains").applied, "each authored chain rank applies through normal personal eligibility")

func packet(rank: int, kind := PlayerHitSnapshot.Kind.GUN, critical := false, owner := &"player1") -> PlayerHitSnapshot:
	return effects.create_hit(owner, 1.0, 2.0, {&"energy_chains": rank}, kind, 1.0 if critical else 0.0)

func strike(hit: PlayerHitSnapshot, target: Area2D) -> void:
	check(effects.resolve_hit(hit, target), "direct setup contact must be accepted")
	effects.release_root(hit)

func rank_contacts() -> void:
	for rank in range(1, 4):
		await reset_case()
		ranked(p1, rank)
		p1.loadout.apply_foundation(&"damage")
		check(p1.loadout.foundation_snapshot().offensive_count == 1 and p1.loadout.foundation_snapshot().utility_count == 1 and p2.loadout.rank_for(UpgradeDefinition.Effect.ENERGY_CHAINS) == 0, "ranks occupy one offensive slot and remain personal")
		var targets: Array = [enemy(&"origin", Vector2(200, 180))]
		for index in 4: targets.append(enemy(StringName("hop_%d" % index), Vector2(260 + index * 50, 180 + (index % 2) * 20)))
		await settle()
		var random_states := [globals.run_random.encounters.state, globals.run_random.drops.state, globals.run_random.upgrades.state, effects.combat_random(&"player1").state]
		var shot = fire(p1)
		shot.position = targets[0].position
		await settle()
		check(shot.get_meta("pooled", false) and shot.hit_snapshot == null, "a real Area2D source recycles before its copied chain finishes")
		check(accepted.size() == rank + 1 and is_equal_approx(targets[0].life, 18.75), "the direct shot remains ordinary and the chain obeys its rank budget")
		for index in 4:
			check(is_equal_approx(targets[index + 1].life, 20.0 - (0.5625 if index < rank else 0.0)), "each additional target receives forty-five percent of modified pre-critical damage exactly once")
		check(accepted.slice(1).all(func(record): return record.hit.kind() == PlayerHitSnapshot.Kind.SECONDARY and not record.hit.is_critical() and not record.first and record.hit.modifier_rank(&"energy_chains") == 0), "chain hits strip all proc and critical capabilities")
		check(random_states == [globals.run_random.encounters.state, globals.run_random.drops.state, globals.run_random.upgrades.state, effects.combat_random(&"player1").state], "targeting and chain presentation consume no combat, encounter, drop or offer RNG")
		check(effects.get_debug_snapshot().roots == 0 and effects.get_debug_snapshot().requests == 0, "all chain root leases and requests retire after resolution")
		var visuals := get_nodes_in_group(&"energy_chain")
		check(visuals.size() == 1 and visuals[0].links.size() == rank and visuals[0].links[0][1] == targets[1].global_position, "visual links contain only the finite accepted path")
		var offer := CHAIN.offer_snapshot(rank - 1)
		check(offer.next_range == CHAIN.range_value(rank) and is_equal_approx(offer.secondary_damage_scale, 0.45) and offer.proc_cooldown == 0.5, "selection snapshots disclose authored range, secondary damage and cooldown")
		if rank == 3: check(not p1.loadout.apply_foundation(&"energy_chains").applied, "rank three caps without consuming another offensive slot")

func targeting_cases() -> void:
	for rank in range(1, 4):
		await reset_case()
		var range_origin = enemy(&"origin", Vector2(240, 200))
		var inside = enemy(&"inside", Vector2(240 + CHAIN.range_value(rank), 200))
		var outside = enemy(&"outside", Vector2(240, 200 - CHAIN.range_value(rank) - 1))
		await settle()
		strike(packet(rank), range_origin)
		await settle()
		check(is_equal_approx(inside.life, 19.1) and outside.life == 20.0, "rank range includes its exact boundary but excludes farther targets")
	await reset_case()
	var origin = enemy(&"origin", Vector2(240, 200))
	var later = enemy(&"tie_b", Vector2(280, 170))
	var earlier = enemy(&"tie_a", Vector2(200, 170))
	await settle()
	strike(packet(1), origin)
	await settle()
	check(earlier.life < 20.0 and later.life == 20.0 and accepted[1].target == &"tie_a", "equal distances use stable spawn identity, independent of insertion order")
	await reset_case()
	origin = enemy(&"origin", Vector2(240, 200))
	var blocked = enemy(&"blocked", Vector2(300, 200))
	var visible = enemy(&"visible", Vector2(240, 135))
	var armor := Area2D.new()
	armor.collision_layer = Layers.ENEMY
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 24)
	shape.shape = rect
	armor.add_child(shape)
	armor.position = Vector2(270, 200)
	stage.add_child(armor)
	await settle()
	strike(packet(1), origin)
	await settle()
	check(blocked.life == 20.0 and visible.life < 20.0, "intervening collision surfaces block a jump; the nearest visible alternative qualifies")
	await reset_case()
	origin = enemy(&"origin", Vector2(240, 200))
	var invalid = enemy(&"invalid", Vector2(280, 200))
	var valid = enemy(&"valid", Vector2(240, 140))
	await settle()
	strike(packet(1), origin)
	invalid.free()
	await settle()
	check(valid.life < 20 and accepted.size() == 2, "targets removed between contact and deferred acquisition are safely skipped")

func cooldown_and_sources() -> void:
	await reset_case()
	var origin = enemy(&"origin", Vector2(240, 200))
	var next = enemy(&"next", Vector2(290, 200))
	await settle()
	strike(packet(3, PlayerHitSnapshot.Kind.GUN, true), origin)
	await settle()
	check(is_equal_approx(origin.life, 16.0) and is_equal_approx(next.life, 19.1), "critical damage doubles only the direct hit; chains use pre-critical damage once")
	var before: float = next.life
	strike(packet(3), origin)
	await settle()
	check(next.life == before, "a second direct root during cooldown cannot trigger another chain")
	var cooldown: float = effects._chain_cooldowns[&"player1"]
	paused = true
	await create_timer(0.12, true).timeout
	check(effects._chain_cooldowns[&"player1"] == cooldown, "selection pause freezes owner proc cooldowns")
	paused = false
	strike(packet(1, PlayerHitSnapshot.Kind.GUN, false, &"player2"), origin)
	await settle()
	check(is_equal_approx(next.life, before - 0.9) and accepted.back().hit.owner_id() == &"player2", "the partner has an independent cooldown and correct chain ownership")
	await create_timer(0.52).timeout
	strike(packet(1), origin)
	await settle()
	check(is_equal_approx(next.life, before - 1.8), "the next eligible contact after 0.5 seconds can trigger again")
	for kind in [PlayerHitSnapshot.Kind.PLASMA, PlayerHitSnapshot.Kind.REFLECTED, PlayerHitSnapshot.Kind.SECONDARY]:
		await reset_case()
		origin = enemy(&"origin", Vector2(240, 200))
		next = enemy(&"next", Vector2(290, 200))
		await settle()
		strike(packet(3, kind), origin)
		await settle()
		check(next.life == 20.0 and get_nodes_in_group(&"energy_chain").is_empty(), "plasma, reflected and secondary sources cannot start chains")
	await reset_case()
	origin = enemy(&"origin", Vector2(240, 200))
	next = enemy(&"kill", Vector2(290, 200), 1.0)
	next.life = 0.5
	await settle()
	var before_xp := xp_events
	var before_kills: int = globals.eliminations
	strike(packet(1), origin)
	await settle()
	check(next.destroyed and next.last_player_hit_owner == &"player1" and xp_events == before_xp + 1 and globals.eliminations == before_kills + 1, "secondary kills award normal XP and one elimination to the original owner")

func lifecycle_cases() -> void:
	await reset_case()
	ranked(p1, 1)
	var origin = enemy(&"origin", Vector2(240, 200))
	var next = enemy(&"next", Vector2(290, 200))
	var third = enemy(&"third", Vector2(340, 200))
	await settle()
	var shot = fire(p1)
	ranked(p1, 2)
	shot.position = origin.position
	await settle()
	check(next.life < 20 and third.life == 20, "a flying shot retains its emission rank after later upgrades")
	var reused = fire(p2)
	check(reused == shot and reused.hit_snapshot.modifier_rank(&"energy_chains") == 0, "cross-player pool reuse clears the former owner's arc rank")
	ProjectilePool.despawn(reused)
	await reset_case()
	origin = enemy(&"origin", Vector2(240, 200))
	next = enemy(&"next", Vector2(290, 200))
	await settle()
	strike(packet(1), origin)
	paused = true
	await create_timer(0.10, true).timeout
	check(next.life == 20 and effects.get_debug_snapshot().requests == 1, "a deferred chain cannot resolve while paused")
	paused = false
	await settle()
	check(next.life < 20 and effects.get_debug_snapshot().roots == 0, "pending copied work resolves once after resuming")
	for cancel_world in [false, true]:
		await reset_case()
		origin = enemy(&"origin", Vector2(240, 200))
		next = enemy(&"next", Vector2(290, 200))
		await settle()
		strike(packet(1), origin)
		if cancel_world: effects.cancel()
		else:
			p1.state = p1.State.DYING
			effects.stop_owner(&"player1")
		await settle()
		check(next.life == 20 and effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "owner DYING or world cancellation removes queued work and retained roots")
	await reset_case()
	origin = enemy(&"origin", Vector2(240, 200))
	next = enemy(&"next", Vector2(290, 200))
	await settle()
	var hit := packet(3)
	check(effects.resolve_hit(hit, next), "the first accepted root impact starts its one permitted chain")
	check(effects.resolve_hit(hit, origin), "another direct contact of the same legacy piercing root can still be accepted")
	effects.release_root(hit)
	await settle()
	check(accepted.filter(func(record): return record.first).size() == 1 and accepted.size() == 2, "the root's already accepted groups remain excluded from deferred chain targeting")
	await reset_case()
	origin = enemy(&"isolated", Vector2(240, 200))
	await settle()
	strike(packet(3), origin)
	await settle()
	check(accepted.size() == 1 and effects.get_debug_snapshot().roots == 0 and get_nodes_in_group(&"energy_chain").is_empty(), "an isolated impact has no chain visual and cannot retain its empty request")

func side_cannon() -> void:
	await reset_case()
	ranked(p1, 2)
	p1.loadout.apply_foundation(&"side_shot")
	for rank in 5: p1.loadout.apply_foundation(&"fire_rate")
	var origin = enemy(&"side_origin", Vector2(240, 200))
	var next = enemy(&"side_next", Vector2(290, 200))
	await settle()
	p1.weapons.fire_primary()
	var side: Node2D = null
	for shot in get_nodes_in_group("player_Shot"):
		if shot.get_meta("pooled", false): continue
		shot.set_physics_process(false)
		if String(shot.get_meta("pool_key", "")).contains("side_shot") and side == null: side = shot
		else: ProjectilePool.despawn(shot)
	check(side != null and side.hit_snapshot.modifier_rank(&"energy_chains") == 2, "real side-cannon emission snapshots the same personal chain family")
	side.position = origin.position
	await settle()
	check(is_equal_approx(origin.life, 19.6) and is_equal_approx(next.life, 19.82), "side shots trigger chains using their own lower authored damage")
	check(effects._chain_cooldowns[&"player1"] > 0.4 and effects._chain_cooldowns[&"player1"] <= 0.5, "maximum FIRE_RATE does not shorten the shared chain cooldown")

func boss_cases() -> void:
	await reset_case()
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"arc_boss"
	boss.configure_spawn(context)
	boss.position = Vector2(320, 110)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	var origin = enemy(&"origin", Vector2(320, 210))
	var outside = enemy(&"outside", Vector2(380, 190))
	await settle()
	var hit := packet(3)
	var armor = boss.get_node("Armor")
	check(not effects.resolve_hit(hit, armor) and effects.get_debug_snapshot().requests == 0, "rejected boss armor cannot trigger a chain")
	effects.release_root(hit)
	var cannon = boss.get_node("PortCannon")
	var health: float = boss.life + cannon.life + boss.get_node("StarboardCannon").life
	strike(packet(3), cannon)
	await settle()
	check(is_equal_approx(health - boss.life - cannon.life - boss.get_node("StarboardCannon").life, 2.0), "the initial boss group cannot be damaged again through a chain child")
	check(accepted.filter(func(record): return String(record.target).begins_with("arc_boss")).size() == 1, "only one boss surface appears in the root's accepted trace")
	check(not origin.destroyed and not outside.destroyed, "ordinary enemies remain independent of boss damage grouping")
	effects.start([p1, p2], globals.run_random)
	accepted.clear()
	boss.get_node("Armor").position.x = 200
	cannon.position = Vector2.ZERO
	boss.get_node("StarboardCannon").position = Vector2.ZERO
	origin.position = Vector2(320, 200)
	outside.position = Vector2(410, 110)
	await settle()
	health = boss.life + cannon.life + boss.get_node("StarboardCannon").life
	var outside_before: float = outside.life
	strike(packet(3), origin)
	await settle()
	check(is_equal_approx(health - boss.life - cannon.life - boss.get_node("StarboardCannon").life, 0.9) and is_equal_approx(outside_before - outside.life, 0.9), "a chain entering overlapping boss surfaces damages one group then continues to a distinct enemy")
	check(accepted.size() == 3 and accepted.filter(func(record): return String(record.target).begins_with("arc_boss")).size() == 1, "nearest-target traversal excludes all other surfaces of an already visited boss")

func visual_lifetime() -> void:
	await reset_case()
	var links: Array[PackedVector2Array] = [PackedVector2Array([Vector2(200, 180), Vector2(260, 140)])]
	for index in 20:
		var visual = ChainScene.instantiate()
		visual.configure(links, &"player2")
		stage.add_child(visual)
	await process_frame
	check(get_nodes_in_group(&"energy_chain").size() == 16, "visual instances have a hard global cap")
	paused = true
	var age: float = get_nodes_in_group(&"energy_chain")[0].age
	await create_timer(0.1, true).timeout
	check(get_nodes_in_group(&"energy_chain")[0].age == age, "pause freezes finite visual animation")
	paused = false
	await create_timer(0.3).timeout
	check(get_nodes_in_group(&"energy_chain").is_empty(), "all four-frame visuals expire without retaining links or target references")
	await settle()
	var baseline := get_node_count()
	for cycle in 5:
		var visual = ChainScene.instantiate()
		visual.configure(links, &"player1")
		stage.add_child(visual)
		await create_timer(0.3).timeout
		check(get_node_count() == baseline, "repeated finite effects return to a stable node baseline")

func moving_endpoints() -> void:
	await reset_case()
	var origin = enemy(&"moving_origin", Vector2(220, 230))
	var middle = enemy(&"moving_middle", Vector2(280, 200))
	var last = enemy(&"moving_last", Vector2(340, 170))
	await settle()
	var hit := packet(2)
	var offset := Vector2(3, -4)
	check(effects.resolve_hit(hit, origin, true, origin.to_global(offset)), "a moving chain starts at its actual local impact offset")
	effects.release_root(hit)
	await process_frame
	var visual = get_nodes_in_group(&"energy_chain")[0]
	visual.set_process(false)
	var frozen_age: float = visual.age
	var hits_before := accepted.size()
	origin.position += Vector2(-12, 8)
	origin.rotation = 0.3
	middle.position += Vector2(15, -10)
	last.position += Vector2(20, 12)
	visual._process(0.0)
	check(visual.links.size() == 2 and visual.links[0][0].is_equal_approx(origin.to_global(offset)), "the source endpoint follows enemy translation, recoil and rotation at its original local impact point")
	check(visual.links[0][1].is_equal_approx(middle.global_position) and visual.links[1][0].is_equal_approx(middle.global_position) and visual.links[1][1].is_equal_approx(last.global_position), "every shared junction follows its own enemy without breaking the next link")
	for index in 2:
		var points: PackedVector2Array = visual._lines[index].points
		check(points == visual._cores[index].points and points == visual._sparks[index].points and points[0] == visual.to_local(visual.links[index][0]).round() and points[-1] == visual.to_local(visual.links[index][1]).round(), "rim, core and sparks share the same updated pixel-snapped endpoints")
		check(visual._anchors[index * 2].position == points[0] and visual._anchors[index * 2 + 1].position == points[-1], "impact sprites stay attached to the moving link endpoints")
	check(accepted.size() == hits_before and effects.get_debug_snapshot().roots == 0, "visual following does not apply damage again or retain a combat root")
	var last_position: Vector2 = visual.links[1][1]
	last.free()
	middle.position += Vector2(8, 4)
	visual._process(0.0)
	check(visual.links[1][1] == last_position and visual.links[1][0].is_equal_approx(middle.global_position), "a freed enemy leaves its last position while surviving endpoints keep following safely")
	visual.set_process(true)
	paused = true
	var frozen: Vector2 = visual.links[0][1]
	middle.position += Vector2(10, 0)
	await create_timer(0.06, true).timeout
	check(visual.links[0][1] == frozen and visual.age == frozen_age, "pause freezes attachment updates together with the animation")
	paused = false
	await process_frame
	await process_frame
	check(visual.links[0][1].is_equal_approx(middle.global_position), "surviving endpoints catch up on resume")
	await create_timer(0.3).timeout
	check(get_nodes_in_group(&"energy_chain").is_empty(), "attached visuals still expire at their original bounded lifetime")

func native_presentation() -> void:
	await reset_case()
	stage.visible = false
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	world.get_node("waveGenerator").stop_run()
	var players: Array = world.progression.players
	var original_stage := stage
	for index in 2:
		var player = players[index]
		player.set_physics_process(false)
		player.position = Vector2(220 + index * 200, 350)
		for rank in 3: player.apply_upgrade(CHAIN)
		stage = world
		var positions := [Vector2(195 + index * 200, 260), Vector2(250 + index * 200, 220), Vector2(200 + index * 200, 170), Vector2(255 + index * 200, 125)]
		for n in positions.size(): enemy(StringName("native_%d_%d" % [index, n]), positions[n])
		stage = original_stage
	await settle()
	for index in 2:
		var hit: PlayerHitSnapshot = world.hit_effects.create_hit(&"player1" if index == 0 else &"player2", 1.0, 1.0, {&"energy_chains": 3})
		var start: Area2D = world.get_tree().get_nodes_in_group("enemy").filter(func(node): return node.get_combat_identity() == StringName("native_%d_0" % index))[0]
		world.hit_effects.resolve_hit(hit, start)
		world.hit_effects.release_root(hit)
	await process_frame
	for visual in get_nodes_in_group(&"energy_chain"): visual.set_process(false)
	for sample in 4:
		for visual in get_nodes_in_group(&"energy_chain"):
			visual.age = sample * 0.06
			visual._process(0.0)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://energy_chains_%d.webp" % sample), true) == OK, "native chain frames must save")
	var ui = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
	root.add_child(ui)
	var offers := [CHAIN.offer_snapshot(2), load("res://data/upgrades/beam_piercing.tres").offer_snapshot(0), load("res://data/upgrades/critical_hits.tres").offer_snapshot(0)]
	check(ui._effect_lines(offers[0]) == "3 ARC JUMPS / 104 PX\n45% DAMAGE / 0.5 SEC", "the native card must display the resource's exact rank-three prototype values")
	ui.open(500, {&"player1": {"build": players[0].loadout.foundation_snapshot(), "offers": offers}, &"player2": {"build": players[1].loadout.foundation_snapshot(), "offers": offers}}, {"level": 4, "xp": 0, "next_threshold": 21})
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://energy_chains_choices.webp"), true) == OK, "native owner-specific cards and miniatures must save")
	ui.free()
	for enemy_node in get_nodes_in_group("enemy"):
		if world.is_ancestor_of(enemy_node): enemy_node.free()
	for visual in get_nodes_in_group(&"energy_chain"): visual.free()
	world.hit_effects.start(players, globals.run_random)
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"native_boss"
	boss.configure_spawn(context)
	boss.position = Vector2(320, 100)
	world.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	original_stage = stage
	stage = world
	var source = enemy(&"boss_arc_origin", Vector2(230, 185))
	enemy(&"boss_arc_followup", Vector2(215, 85))
	stage = original_stage
	await settle()
	var boss_hit: PlayerHitSnapshot = world.hit_effects.create_hit(&"player1", 1.0, 1.0, {&"energy_chains": 3})
	world.hit_effects.resolve_hit(boss_hit, source)
	world.hit_effects.release_root(boss_hit)
	await process_frame
	for visual in get_nodes_in_group(&"energy_chain"): visual.set_process(false)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://energy_chains_boss.webp"), true) == OK, "native boss interaction must save")
	world.free()
	await process_frame
	globals.coop = false
	world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	world.get_node("waveGenerator").stop_run()
	var solo = world.progression.players[0]
	solo.set_physics_process(false)
	for rank in 3: solo.apply_upgrade(CHAIN)
	original_stage = stage
	stage = world
	var solo_origin = enemy(&"solo_origin", Vector2(280, 270))
	for index in 3: enemy(StringName("solo_jump_%d" % index), Vector2(335 if index % 2 == 0 else 280, 220 - index * 50))
	stage = original_stage
	await settle()
	solo.weapons.fire_primary()
	for shot in get_nodes_in_group("player_Shot"):
		if world.is_ancestor_of(shot) and not shot.get_meta("pooled", false):
			shot.set_physics_process(false)
			shot.global_position = solo_origin.global_position
	await settle()
	var solo_visuals := get_nodes_in_group(&"energy_chain")
	check(solo_visuals.size() == 1 and solo_visuals[0].links.size() == 3 and world.hit_effects.get_debug_snapshot().roots == 0, "an actual solo-world cannon contact produces all three copied jumps and releases its root")
	for visual in solo_visuals:
		visual.set_process(false)
		visual.age = 0.0
		visual._process(0.0)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://energy_chains_solo.webp"), true) == OK, "native solo combat presentation must save")
	for sample in 3:
		for actor in get_nodes_in_group("enemy"):
			if world.is_ancestor_of(actor): actor.position += Vector2(9 if actor.position.y > 200 else -7, 6)
		for visual in solo_visuals: visual._process(0.0)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://energy_chains_follow_%d.webp" % sample), true) == OK, "native movement samples must preserve attached chain endpoints")
	world.free()
	stage.visible = true
	await process_frame

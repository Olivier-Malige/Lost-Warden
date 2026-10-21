extends "res://tests/player/test_player_hit_contract.gd"

const CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")
const CATALOG: UpgradeTable = preload("res://data/upgrades/foundation_catalog.tres")
const PIERCE: UpgradeDefinition = preload("res://data/upgrades/piercing.tres")
const CRITICAL: UpgradeDefinition = preload("res://data/upgrades/critical_hits.tres")
const Impact := preload("res://scenes/effects/critical_impact.gd")
var observations: Array = []

func reset_build() -> void:
	p1.loadout.reset()
	p2.loadout.reset()

func contact(shot: Node2D, target: Node2D) -> void:
	shot.global_position = target.global_position
	await settle()

func leave(shot: Node2D) -> void:
	shot.position = Vector2(580, 320)
	await settle()

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = true
	globals.reset_run(123)
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
		var definitions: Array[UpgradeDefinition] = CATALOG.upgrades.duplicate()
		for definition in [PIERCE, CRITICAL]:
			if not definitions.has(definition): definitions.append(definition)
		check(player.loadout.initialize_foundation(CONFIG, definitions), "completed families must initialize through normal loadout data")
	effects.start([p1, p2], globals.run_random)
	effects.hit_accepted.connect(func(hit, target, position, first): accepted.append({"hit": hit, "target": target, "position": position, "first": first}))
	events.xp_spawn_requested.connect(func(_amount, _position): xp_events += 1)
	await ranks_and_contacts()
	await combined_and_reuse()
	await blocking_and_boss()
	await side_cannons()
	await ranked_critical_emissions()
	await critical_replays()
	await impact_limits()
	reset_build()
	for id in [&"piercing", &"critical_hits"]:
		for rank in 3: p1.loadout.apply_foundation(id)
	await check_plasma_and_reflection()
	await check_owner_and_generation()
	stage.free()
	await process_frame
	check(get_nodes_in_group(&"critical_impact").is_empty(), "world removal must remove all transient critical feedback")
	if DisplayServer.get_name() != "headless": await native_presentation()
	var evidence := FileAccess.open("res://step7_critical_traces.json", FileAccess.WRITE)
	evidence.store_string(JSON.stringify(observations, "\t"))
	evidence.close()
	print("Piercing and critical hits: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func ranks_and_contacts() -> void:
	for rank in range(1, 4):
		reset_build()
		for increment in rank: check(p1.loadout.apply_foundation(&"piercing").applied, "each piercing rank must apply")
		check(p1.loadout.foundation_snapshot().offensive_count == 1, "ranking piercing consumes one offensive slot")
		var targets: Array = []
		for index in 5: targets.append(enemy(StringName("rank_%d_%d" % [rank, index]), Vector2(75 + index * 95, 130)))
		var shot = fire(p1)
		check(shot.remaining_penetrations == rank and shot._source_sprite.texture == shot.piercing_texture, "ranked primary uses the piercing treatment and authored extra-target budget")
		var root_id: StringName = shot.hit_snapshot.root_id()
		for index in rank + 1:
			await contact(shot, targets[index])
			check(is_equal_approx(20.0 - targets[index].life, pow(0.8, index)), "actual contacts must retain 80 percent per accepted distinct target")
			if index == 0:
				await leave(shot)
				await contact(shot, targets[index])
				check(targets[index].life == 19.0 and shot.remaining_penetrations == rank - 1 and not shot.get_meta("pooled", false), "target re-entry cannot repeat damage or consume another traversal")
			if index < rank:
				check(not shot.get_meta("pooled", false) and shot.hit_snapshot.root_id() == root_id, "one root survives until its target budget is exhausted")
		check(shot.get_meta("pooled", false) and targets[rank + 1].life == 20.0, "the shot must stop after exactly rank plus one accepted targets")
		for target in targets: target.free()
		await settle()
	reset_build()
	for rank in 3: p1.loadout.apply_foundation(&"piercing")
	var a = enemy(&"simultaneous_a", Vector2(250, 120))
	var b = enemy(&"simultaneous_b", Vector2(250, 120))
	var shot = fire(p1)
	await contact(shot, a)
	check(is_equal_approx(40.0 - a.life - b.life, 1.8) and shot.remaining_penetrations == 1, "simultaneous distinct callbacks accept once each with one decay, regardless of callback order")
	ProjectilePool.despawn(shot)
	a.free(); b.free()
	await settle()

func combined_and_reuse() -> void:
	reset_build()
	for rank in 3:
		p1.loadout.apply_foundation(&"piercing")
		p1.loadout.apply_foundation(&"critical_hits")
	check(not p1.loadout.apply_foundation(&"piercing").applied and not p1.loadout.apply_foundation(&"critical_hits").applied, "both authored families cap at rank three")
	check(p1.loadout.foundation_snapshot().offensive_count == 2 and p2.loadout.acquired_ranks.is_empty(), "combined ranks consume two personal slots")
	p1.loadout.apply_foundation(&"damage")
	var shot: Variant
	for attempt in 100:
		shot = fire(p1)
		if shot.hit_snapshot.is_critical(): break
		ProjectilePool.despawn(shot)
		await settle()
	check(shot.hit_snapshot != null and shot.hit_snapshot.is_critical(), "fixed seed must exercise an actual critical weapon emission")
	var target = enemy(&"critical_a", Vector2(250, 140))
	var other = enemy(&"critical_b", Vector2(380, 140))
	var snapshot: PlayerHitSnapshot = shot.hit_snapshot.copy()
	p1.loadout.reset()
	await contact(shot, target)
	await contact(shot, other)
	check(is_equal_approx(target.life, 17.5) and is_equal_approx(other.life, 18.0), "combined critical/piercing contacts retain emission damage x2 then x0.8 despite a build change")
	check(accepted.back().hit.is_critical() and is_equal_approx(accepted.back().hit.pre_critical_damage(), 1.0) and not accepted.back().first, "subsequent critical impacts carry their decayed pre-critical damage and cannot reattempt first-hit procs")
	var secondary := snapshot.secondary_hit(snapshot.pre_critical_damage() * 0.5)
	check(is_equal_approx(secondary.damage(), 0.625) and not secondary.is_critical() and secondary.modifier_rank(&"piercing") == 0, "secondary amounts derive from pre-critical damage without critical or piercing inheritance")
	var lethal = enemy(&"critical_kill", Vector2(500, 140), 1.0)
	var xp_before := xp_events
	await contact(shot, lethal)
	check(lethal.destroyed and lethal.last_player_hit_owner == &"player1" and xp_events == xp_before + 1, "a critical piercing kill must retain its original owner and award XP exactly once")
	check(not lethal.receive_player_hit(100.0, &"player2") and xp_events == xp_before + 1, "a rejected repeat of the critical kill must not duplicate its reward")
	ProjectilePool.despawn(shot)
	await settle()
	var reused = fire(p2)
	check(reused == shot and not reused.hit_snapshot.is_critical() and reused.remaining_penetrations == 0 and reused._damage_scale == 1.0 and reused._source_sprite.texture == reused._base_texture and reused.hit_snapshot.owner_id() == &"player2", "cross-player reuse must restore the base art and all damage/modifier state")
	await contact(reused, other)
	check(is_equal_approx(other.life, 17.0) and reused.get_meta("pooled", false), "unranked reused projectile must deal one ordinary damage and stop")
	target.free(); other.free(); lethal.free()
	await settle()

func blocking_and_boss() -> void:
	reset_build()
	for rank in 3: p1.loadout.apply_foundation(&"piercing")
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"piercing_boss"
	boss.configure_spawn(context)
	boss.position = Vector2(300, 90)
	stage.add_child(boss)
	boss.set_physics_process(false)
	var armor = boss.get_node("Armor")
	var port = boss.get_node("PortCannon")
	var starboard = boss.get_node("StarboardCannon")
	boss.attack = boss.Attack.IDLE
	var shot = fire(p1)
	var before := accepted.size()
	shot.global_position = armor.global_position + Vector2(-18, -12)
	await settle()
	check(shot.get_meta("pooled", false) and accepted.size() == before and not armor.hitByPlayerShot, "actual armor contact rejects damage and stops a ranked projectile")
	armor.position = Vector2(200, 0)
	port.position = Vector2.ZERO
	starboard.position = Vector2.ZERO
	var health: float = boss.life + port.life + starboard.life
	shot = fire(p1)
	await contact(shot, boss)
	check(is_equal_approx(health - boss.life - port.life - starboard.life, 1.0) and shot.remaining_penetrations == 2 and not shot.get_meta("pooled", false), "overlapping boss surfaces consume only one accepted hit and one traversal")
	await leave(shot)
	await contact(shot, port)
	check(is_equal_approx(health - boss.life - port.life - starboard.life, 1.0) and shot.remaining_penetrations == 2, "another boss surface cannot bypass the shared root exclusion")
	var target = enemy(&"after_boss", Vector2(520, 230))
	await contact(shot, target)
	check(is_equal_approx(target.life, 19.2) and shot.remaining_penetrations == 1, "ordinary enemies after the boss remain independent targets")
	ProjectilePool.despawn(shot)
	await settle()
	boss.free(); target.free()
	await settle()

func side_cannons() -> void:
	reset_build()
	p1.loadout.apply_foundation(&"side_shot")
	p1.loadout.apply_foundation(&"piercing")
	p1.loadout.apply_foundation(&"critical_hits")
	p1.weapons.fire_primary()
	var count := 0
	for shot in get_nodes_in_group("player_Shot"):
		if shot.get_meta("pooled", false): continue
		count += 1
		shot.set_physics_process(false)
		check(shot.remaining_penetrations == 1 and shot.hit_snapshot.modifier_rank(&"critical_hits") == 1, "each primary and side emission snapshots both personal modifiers")
		if shot._base_texture.get_width() == 30:
			check(shot._source_sprite.texture == shot.piercing_texture and shot.piercing_texture.get_width() == 30 and is_equal_approx(shot.damage, 0.4), "side projectile uses its own six-pixel treatment without changing its base damage")
		ProjectilePool.despawn(shot)
	check(count == 3, "rank-one side cannons still emit exactly one primary and two wing projectiles")
	await settle()

func critical_replays() -> void:
	reset_build()
	var states := {}
	for owner in [&"player1", &"player2"]:
		states[owner] = effects.combat_random(owner).state
		var ordinary = effects.create_hit(owner, 1, 1)
		effects.release_root(ordinary)
		check(effects.combat_random(owner).state == states[owner], "unranked emissions must not advance combat RNG")
	for rank in range(1, 4):
		var chance := CRITICAL.rank_value(rank)
		check(is_equal_approx(chance, rank * 0.1), "critical chances must use the authored ten/twenty/thirty percent values")
		for pair in [[0.0, true], [chance - 0.000001, true], [chance, false], [chance + 0.000001, false], [1.0, false]]:
			check(PlayerHitEffects.is_critical_roll(pair[0], chance) == pair[1], "critical threshold uses a strict less-than boundary")
	for seed_value in [0, 1, 42, 99]:
		var expected_trace: Array = []
		for noise in [false, true]:
			var random := RunRandom.new(seed_value)
			var untouched := RunRandom.new(seed_value)
			effects.start([p1, p2], random)
			var trace: Array = []
			for index in 60:
				var owner: StringName = &"player1" if index % 2 == 0 else &"player2"
				if noise:
					random.encounters.randi(); random.enemies.randi(); random.drops.randi(); random.upgrades.randi(); randi()
				var owner_before := random.combat_for(&"player2" if owner == &"player1" else &"player1").state
				var hit = effects.create_hit(owner, 0.8, 1.0, {&"critical_hits": 3, &"piercing": 2}, PlayerHitSnapshot.Kind.GUN, CRITICAL.rank_value(3))
				trace.append([String(owner), hit.source_sequence(), hit.is_critical(), hit.damage(), random.combat_for(owner).state])
				check(random.combat_for(&"player2" if owner == &"player1" else &"player1").state == owner_before, "one owner's critical emission cannot consume the partner's RNG")
				effects.release_root(hit)
			if not noise:
				expected_trace = trace
				check(random.encounters.state == untouched.encounters.state and random.enemies.state == untouched.enemies.state and random.drops.state == untouched.drops.state and random.upgrades.state == untouched.upgrades.state, "actual critical emissions cannot consume encounter, enemy, drop or offer streams")
			else: check(trace == expected_trace, "critical traces must replay identically despite unrelated stream activity")
			observations.append({"seed": seed_value, "unrelated_noise": noise, "emissions": trace})
	var before: int = effects.combat_random(&"player1").state
	for kind in [PlayerHitSnapshot.Kind.PLASMA, PlayerHitSnapshot.Kind.REFLECTED, PlayerHitSnapshot.Kind.SECONDARY]:
		var hit = effects.create_hit(&"player1", 3, 3, {&"critical_hits": 3}, kind, 1.0)
		check(not hit.is_critical() and hit.damage() == 3.0 and effects.combat_random(&"player1").state == before, "incompatible hit kinds cannot roll or multiply critical damage")
		effects.release_root(hit)

func ranked_critical_emissions() -> void:
	reset_build()
	for rank in range(1, 4):
		check(p1.loadout.apply_foundation(&"critical_hits").applied and is_equal_approx(p1.loadout.critical_chance, CRITICAL.rank_value(rank)), "personal critical probability must derive from each authored rank")
		var random := RunRandom.new(314)
		var expected := RunRandom.new(314)
		effects.start([p1, p2], random)
		for index in 12:
			var result := expected.combat_for(&"player1").randf() < CRITICAL.rank_value(rank)
			var shot = fire(p1)
			check(shot.hit_snapshot.is_critical() == result and random.combat_for(&"player1").state == expected.combat_for(&"player1").state, "each real emission must consume exactly one personal draw and obey its authored rank threshold")
			if index == 0:
				var target = enemy(StringName("critical_rank_%d" % rank), Vector2(280, 150))
				await contact(shot, target)
				check(is_equal_approx(target.life, 18.0 if result else 19.0), "each critical rank must apply the exact seeded direct damage through an actual contact")
				target.free()
			else: ProjectilePool.despawn(shot)
			await settle()

func impact_limits() -> void:
	reset_build()
	p1.loadout.apply_foundation(&"piercing")
	var shot = fire(p1)
	shot.set_physics_process(true)
	var position_before: Vector2 = shot.position
	var combat_state: int = effects.combat_random(&"player1").state
	for index in 40: Impact.spawn(stage, Vector2(70 + index * 10, 100), &"player1" if index % 2 == 0 else &"player2")
	check(get_nodes_in_group(&"critical_impact").size() == 32, "critical feedback must obey its fixed transient cap")
	var ages: Array = []
	for effect in get_nodes_in_group(&"critical_impact"): ages.append(effect.age)
	paused = true
	await create_timer(0.10, true).timeout
	var index := 0
	for effect in get_nodes_in_group(&"critical_impact"):
		check(effect.age == ages[index], "selection pause must freeze critical animation and expiry")
		index += 1
	paused = false
	check(shot.position == position_before and shot.remaining_penetrations == 1 and effects.combat_random(&"player1").state == combat_state, "pause must freeze ranked projectiles, penetration state and combat draws")
	ProjectilePool.despawn(shot)
	await create_timer(0.36).timeout
	check(get_nodes_in_group(&"critical_impact").is_empty(), "all critical feedback must expire after its six-frame sequence")
	check(effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "sustained ranked emissions and pooling must leave no root or reservation drift")
	var baseline := get_node_count()
	for cycle in 5:
		var temporary_world := Node2D.new()
		stage.add_child(temporary_world)
		for burst in 8: Impact.spawn(temporary_world, Vector2(100, 100), &"player1")
		temporary_world.free()
		await process_frame
		check(get_node_count() == baseline and get_nodes_in_group(&"critical_impact").is_empty(), "repeated world removal must leave no critical sprite or node-count drift")

func native_presentation() -> void:
	var main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.get_node("loader/Timer").stop()
	main.get_node("loader").free()
	for coop in [false, true]:
		globals.coop = coop
		main._show_world_screen()
		var world = main.get_node("world")
		world.get_node("waveGenerator").stop_run()
		for player in world.progression.players:
			player.set_physics_process(false)
			player.set_process(false)
			for definition in [load("res://data/upgrades/foundation/side_shot.tres"), PIERCE, CRITICAL]:
				for rank in 3: player.apply_upgrade(definition)
			player.weapons.fire_primary()
		for shot in get_nodes_in_group("player_Shot"):
			if not shot.get_meta("pooled", false):
				shot.position.y -= 45
				shot.set_physics_process(false)
		for frame_index in [0, 1, 3, 5]:
			for effect in get_nodes_in_group(&"critical_impact"): effect.free()
			for player in world.progression.players:
				var effect = Impact.spawn(world, player.global_position + Vector2(0, -90), StringName(player.id_Player))
				effect.set_process(false)
				effect.frame = effect.team * 6 + frame_index
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://step7_%s_impact_%d.webp" % ["coop" if coop else "solo", frame_index]), true)
		var participants := {}
		for player in world.progression.players:
			participants[StringName(player.id_Player)] = {"build": player.loadout.foundation_snapshot(), "offers": [PIERCE.offer_snapshot(2), CRITICAL.offer_snapshot(2), CATALOG.upgrades[0].offer_snapshot(0)]}
		var ui = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
		main.add_child(ui)
		ui.open(77, participants, {"level": 6, "xp": 0, "next_threshold": 34})
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://step7_%s_choices.webp" % ["coop" if coop else "solo"]), true)
		ui.free()
		world.free()
		await process_frame
	main.free()
	await process_frame

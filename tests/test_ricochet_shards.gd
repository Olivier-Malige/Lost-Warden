extends "res://tests/test_energy_chains.gd"

const RICOCHET: UpgradeDefinition = preload("res://data/upgrades/ricochet.tres")

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
	check(RICOCHET.foundation_errors().is_empty(), "ricochet authored data validates")
	for atlas in [preload("res://assets/sprites/ui/upgrade_icons_64.png"), preload("res://assets/sprites/ui/upgrade_miniatures.png")]:
		var cell := 64 if atlas.get_height() == 128 else 16
		for team in 2:
			var image: Image = atlas.get_image().get_region(Rect2i(20 * cell, team * cell, cell, cell))
			check(not image.is_invisible(), "ricochet selection art must be visible for both players")
	for field in ["range_values", "secondary_damage_scale", "proc_cooldown", "secondary_damage_retention", "weapon"]:
		var invalid := RICOCHET.duplicate() as UpgradeDefinition
		match field:
			"range_values": invalid.range_values = PackedFloat32Array([NAN])
			"weapon": invalid.weapon = null
			_: invalid.set(field, -1.0)
		check(not invalid.foundation_errors().is_empty(), "invalid ricochet data rejects: " + field)
	check(RICOCHET.weapon.projectile_speed == 300.0 and RICOCHET.weapon.projectile_lifetime == 1.2 and RICOCHET.weapon.active_limit == 4 and RICOCHET.proc_cooldown == 0.4, "flight and capacity match authored contract")
	for rank in range(1, 4):
		await reset_case()
		var targets: Array = [enemy(&"origin", Vector2(100, 180))]
		for i in 6: targets.append(enemy(StringName("hop_%d" % i), Vector2(155 + i * 55, 180)))
		await settle()
		var hit = effects.create_hit(&"player1", 2.0, 4.0, {&"ricochet": rank}, PlayerHitSnapshot.Kind.GUN, 1.0)
		strike(hit, targets[0])
		await create_timer(1.1).timeout
		check(accepted.size() == rank + 3, "rank controls actual additional physical impacts")
		check(is_equal_approx(targets[0].life, 12.0), "original direct critical damage stays independent")
		for i in 6:
			check(is_equal_approx(targets[i + 1].life, 20.0 - (2.2 * pow(0.8, i) if i < rank + 2 else 0.0)), "secondary pre-critical damage decays once")
		check(effects.get_debug_snapshot().reservations == 0, "expiry returns owner reservation")
		check(accepted.slice(1).all(func(record): return record.hit.kind() == PlayerHitSnapshot.Kind.SECONDARY and not record.hit.is_critical()), "secondary impacts cannot critically strike")
	for kind in PlayerHitSnapshot.Kind.values():
		await reset_case()
		var origin = enemy(&"origin", Vector2(100, 180))
		enemy(&"other", Vector2(155, 180))
		await settle()
		var hit = effects.create_hit(&"player1", 2.0, 2.0, {&"ricochet": 3}, kind)
		strike(hit, origin)
		await create_timer(0.35).timeout
		check((accepted.size() > 1) == (kind in [PlayerHitSnapshot.Kind.GUN, PlayerHitSnapshot.Kind.SIDE_GUN, PlayerHitSnapshot.Kind.DRONE]), "only approved source kinds emit shards")
	await reset_case()
	var origin = enemy(&"origin", Vector2(100, 180))
	var other = enemy(&"other", Vector2(175, 180))
	await settle()
	strike(effects.create_hit(&"player1", 1.0, 1.0, {&"ricochet": 3}), origin)
	await process_frame
	paused = true
	var shard: Node = null
	for candidate in get_nodes_in_group("ricochet_shard"):
		if not candidate.get_meta("pooled", false): shard = candidate
	check(shard != null, "deferred shard materializes")
	var position: Vector2 = shard.position
	await create_timer(0.15, true).timeout
	check(shard.position == position and other.life == 20.0, "pause freezes travel and damage")
	paused = false
	effects.stop_owner(&"player1")
	await create_timer(0.4).timeout
	check(other.life < 20.0, "already flying shard finishes after owner death")
	await reset_case()
	check(effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "restart clears bookkeeping")
	await edge_cases()
	await ricochet_boss()
	await combination()
	await actual_cannon()
	await volley_counts()
	await return_trips()
	if DisplayServer.get_name() != "headless": await presentation()
	stage.free()
	await process_frame
	print("Ricochet shards: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func edge_cases() -> void:
	for owner in [&"player1", &"player2"]:
		await reset_case()
		var origin = enemy(&"origin", Vector2(100, 180), 100.0)
		enemy(&"other", Vector2(175, 180), 100.0)
		await settle()
		for i in 6:
			var hit = effects.create_hit(owner, 1.0, 1.0, {&"ricochet": 3})
			strike(hit, origin)
			if i == 1: check(effects.get_debug_snapshot().reservations == 1, "owner cooldown suppresses same-frame repeated roots")
			if i != 0: effects._ricochet_cooldowns.clear()
		check(effects.get_debug_snapshot().reservations == 4, "four active plus pending shards cap each owner")
		await create_timer(1.3).timeout
		check(effects.get_debug_snapshot().reservations == 0, "saturation leaves no delayed emissions")
	await reset_case()
	var origin = enemy(&"origin", Vector2(100, 180))
	var beyond = enemy(&"beyond", Vector2(240, 180))
	await settle()
	strike(effects.create_hit(&"player1", 1.0, 1.0, {&"ricochet": 3}), origin)
	check(effects.get_debug_snapshot().reservations == 0, "targets beyond acquisition range emit nothing")
	beyond.position = Vector2(175, 180)
	await settle()
	strike(effects.create_hit(&"player1", 1.0, 1.0, {&"ricochet": 3}), origin)
	await process_frame
	beyond.queue_free()
	await create_timer(0.2).timeout
	check(effects.get_debug_snapshot().reservations == 0, "lost last target recycles without retaining ownership")
	await reset_case()
	origin = enemy(&"origin", Vector2(100, 180))
	var target = enemy(&"other", Vector2(175, 180))
	await settle()
	strike(effects.create_hit(&"player1", 1.0, 1.0, {&"ricochet": 3}), origin)
	await process_frame
	var wall := Area2D.new()
	wall.set_script(load("res://tests/fixtures/ricochet_armor.gd"))
	wall.collision_layer = Layers.ENEMY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(4, 80)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = Vector2(140, 180)
	stage.add_child(wall)
	await create_timer(0.4).timeout
	check(target.life == 20, "armor introduced during travel blocks shard damage")
	await reset_case()
	for candidate in get_nodes_in_group("ricochet_shard"):
		check(candidate.hit == null and candidate.target == null and candidate.exclusions.is_empty() and candidate.reservation == &"" and candidate.last_group == &"" and candidate.visited.is_empty(), "parked shards clear all mutable ownership and history")

func presentation() -> void:
	await reset_case()
	for owner in [&"player1", &"player2"]:
		var y := 140.0 if owner == &"player1" else 240.0
		var origin = enemy(StringName("visual_" + owner), Vector2(160, y))
		for i in 9:
			enemy(StringName("visual_%s_%d" % [owner, i]), Vector2(220 + (i / 3) * 60, y - 32 + (i % 3) * 32))
		await settle()
		strike(effects.create_hit(owner, 1.0, 1.0, {&"ricochet": 3}), origin)
	for i in 8:
		await create_timer(0.06).timeout
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/ricochet_native_%d.png" % i)

func ricochet_boss() -> void:
	await reset_case()
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"ricochet_boss"
	boss.configure_spawn(context)
	boss.position = Vector2(320, 110)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	var origin = enemy(&"origin", Vector2(320, 190))
	await settle()
	var cannon = boss.get_node("PortCannon")
	var health: float = boss.life + cannon.life + boss.get_node("StarboardCannon").life
	strike(effects.create_hit(&"player1", 2.0, 2.0, {&"ricochet": 3}), cannon)
	await create_timer(0.6).timeout
	check(is_equal_approx(health - boss.life - cannon.life - boss.get_node("StarboardCannon").life, 2.0), "root boss contact excludes every boss surface from its shard")
	check(accepted.filter(func(record): return String(record.target).begins_with("ricochet_boss")).size() == 1, "one root never repeats a boss group")
	check(origin.life <= 20, "ordinary hull remains valid outside boss grouping")
	effects.start([p1, p2], globals.run_random)
	accepted.clear()
	boss.get_node("Armor").position.x = 200
	cannon.position = Vector2.ZERO
	boss.get_node("StarboardCannon").position = Vector2.ZERO
	origin.position = Vector2(320, 180)
	await settle()
	health = boss.life + cannon.life + boss.get_node("StarboardCannon").life
	strike(effects.create_hit(&"player1", 2.0, 2.0, {&"ricochet": 3}), origin)
	await create_timer(1.3).timeout
	check(is_equal_approx(health - boss.life - cannon.life - boss.get_node("StarboardCannon").life, 1.1), "a shard entering overlapping boss surfaces damages the boss once")
	check(accepted.filter(func(record): return String(record.target).begins_with("ricochet_boss")).size() == 1, "a return to an ordinary hull never unlocks a second boss impact")

func combination() -> void:
	await reset_case()
	var origin = enemy(&"origin", Vector2(180, 180))
	for i in 4: enemy(StringName("combined_%d" % i), Vector2(220 + i * 40, 180))
	await settle()
	var hit = effects.create_hit(&"player1", 2.0, 2.0, {&"ricochet": 3, &"energy_chains": 1, &"impact_explosions": 3}, PlayerHitSnapshot.Kind.GUN, 1.0)
	check(effects.resolve_hit(hit, origin), "combined root contact accepts")
	await create_timer(1.3).timeout
	check(accepted.filter(func(record): return record.first).size() == 1, "combined effects never recursively count as first impact")
	check(accepted.slice(1).all(func(record): return not record.hit.is_critical() and record.hit.modifier_rank(&"ricochet") == 0), "secondary combination strips critical and recursion")
	effects.release_root(hit)
	check(effects.get_debug_snapshot().roots == 0, "combined children release all root leases")

func actual_cannon() -> void:
	for player in [p1, p2]:
		await reset_case()
		check(player.loadout.apply_foundation(&"ricochet").applied, "family acquired through normal catalog")
		var origin = enemy(&"origin", Vector2(200, 180))
		var other = enemy(&"other", Vector2(260, 180))
		await settle()
		var shot = fire(player)
		shot.position = origin.position
		await settle()
		check(shot.get_meta("pooled", false), "real source shot recycles independently of child")
		await create_timer(0.4).timeout
		check(other.life < 20 and accepted.size() > 1, "real cannon emits a physical shard for either owner")
		check(accepted[1].hit.owner_id() == StringName(player.id_Player), "pooled child ownership follows current player")

func volley_counts() -> void:
	for rank in range(1, 4):
		await reset_case()
		var origin = enemy(&"origin", Vector2(180, 180))
		for i in 3: enemy(StringName("fan_%d" % i), Vector2(235, 140 + i * 40))
		await settle()
		strike(effects.create_hit(&"player1", 1.0, 1.0, {&"ricochet": rank}), origin)
		check(effects.get_debug_snapshot().reservations == rank, "rank emits one/two/three reserved shards toward distinct targets")
		await create_timer(1.3).timeout
		check(accepted.size() <= 1 + rank * (rank + 2), "multiple shards respect individual impact budgets")
		check(effects.get_debug_snapshot().reservations == 0, "whole volley returns capacity")

func return_trips() -> void:
	for owner in [&"player1", &"player2"]:
		for rank in range(1, 4):
			await reset_case()
			var a = enemy(&"return_a", Vector2(200, 180), 100.0)
			var b = enemy(&"return_b", Vector2(255, 180), 100.0)
			await settle()
			strike(effects.create_hit(owner, 4.0, 4.0, {&"ricochet": rank}), a)
			if DisplayServer.get_name() != "headless" and owner == &"player1" and rank == 3:
				for frame in 8:
					await create_timer(0.06).timeout
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://.godot/ricochet_return_%d.png" % frame)
			await create_timer(1.3).timeout
			check(accepted.size() == rank + 3, "two hulls sustain the full rank budget without a new emission")
			var damage_a := 4.0
			var damage_b := 0.0
			for i in rank + 2:
				var expected := &"return_b" if i % 2 == 0 else &"return_a"
				check(accepted[i + 1].target == expected, "return trips alternate hull identities")
				var amount := 2.2 * pow(0.8, i)
				check(is_equal_approx(accepted[i + 1].hit.damage(), amount), "each return retains the next decayed damage exactly once")
				if i % 2 == 0: damage_b += amount
				else: damage_a += amount
			check(is_equal_approx(a.life, 100.0 - damage_a) and is_equal_approx(b.life, 100.0 - damage_b), "actual hull HP includes repeated physical contacts")
			check(effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "return trips release every lease and reservation")
	await reset_case()
	var alone = enemy(&"alone", Vector2(200, 180))
	await settle()
	strike(effects.create_hit(&"player1", 1.0, 1.0, {&"ricochet": 3}), alone)
	await create_timer(0.3).timeout
	check(accepted.size() == 1 and effects.get_debug_snapshot().reservations == 0, "an isolated hull never bounces onto itself")

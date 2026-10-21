extends "res://tests/player/test_player_hit_contract.gd"

const UPGRADE: UpgradeDefinition = preload("res://data/upgrades/escort_drone.tres")
const BOLT := preload("res://scenes/player/weapons/drone_bolt.tscn")

func active_bolts() -> Array:
	return get_nodes_in_group(&"player_Shot").filter(func(shot): return not shot.get_meta("pooled", false) and shot.get_meta("pool_key", "") == BOLT.resource_path)

func materialize_bolts() -> void:
	for id in effects._requests.keys(): effects._materialize(id)
	for shot in active_bolts(): shot.set_physics_process(false)

func reset_case() -> void:
	for shot in active_bolts(): ProjectilePool.despawn(shot)
	for target in get_nodes_in_group(&"enemy"):
		if stage.is_ancestor_of(target): target.free()
	for group in [&"critical_impact", &"energy_chain", &"combat_feedback"]:
		for visual in get_nodes_in_group(group):
			if stage.is_ancestor_of(visual): visual.free()
	for player in [p1, p2]:
		player.weapons.stop_support()
		player.loadout.reset()
		player.state = player.State.ACTIVE
		player.position = Vector2(200 if player == p1 else 450, 350)
		player.reset_weapon_input()
	effects.start([p1, p2], globals.run_random)
	accepted.clear()
	await settle()

func equip(player: Node, rank: int) -> void:
	for index in rank: check(player.apply_upgrade(UPGRADE).applied, "each authored drone rank must acquire normally")
	check(is_instance_valid(player.weapons.escort), "acquisition immediately creates the support")
	check(player.weapons.escorts.size() == UPGRADE.support_count(rank), "support counts follow the authored one / one / two rank progression")
	for support in player.weapons.escorts: support.set_process(false)

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = true
	globals.reset_run(909)
	root.size = Vector2i(640, 400)
	stage = Node2D.new()
	root.add_child(stage)
	pool = ProjectilePool.new()
	stage.add_child(pool)
	effects = PlayerHitEffects.new()
	effects.name = "PlayerHitEffects"
	stage.add_child(effects)
	for index in 2:
		var player = load("res://scenes/player/player.tscn").instantiate()
		player.set_Player_2 = index == 1
		stage.add_child(player)
		player.set_physics_process(false)
		player.set_process(false)
		for kind in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
			for audio in player.find_children("*", kind, true, false): audio.stream = null
		if index == 0: p1 = player
		else: p2 = player
	effects.hit_accepted.connect(func(hit, target, at, first): accepted.append({"hit": hit, "target": target, "position": at, "first": first}))
	await reset_case()
	check(UPGRADE.foundation_errors().is_empty() and PackedFloat32Array(UPGRADE.rank_values) == PackedFloat32Array([0.6, 0.75, 0.9]) and PackedFloat32Array(UPGRADE.interval_values) == PackedFloat32Array([0.65, 0.55, 0.45]), "all drone ranks and intervals match the approved contract")
	for field in ["target_range", "projectile_speed", "projectile_lifetime"]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		invalid.weapon = UPGRADE.weapon.duplicate()
		invalid.weapon.set(field, NAN)
		check(not invalid.foundation_errors().is_empty(), "nonfinite weapon data must reject before offers: " + field)
	var invalid_cap := UPGRADE.duplicate() as UpgradeDefinition
	invalid_cap.weapon = UPGRADE.weapon.duplicate()
	invalid_cap.weapon.active_limit = 7
	check(not invalid_cap.foundation_errors().is_empty(), "the authored bolt cap cannot exceed six")
	var invalid_count := UPGRADE.duplicate() as UpgradeDefinition
	invalid_count.support_counts = PackedInt32Array([1, 2, 3])
	check(not invalid_count.foundation_errors().is_empty(), "support data cannot spawn a third companion")
	for rank in range(1, 4):
		for boosted in [false, true]: await rank_and_flight(rank, boosted)
	await movement_and_reactors()
	await gliding_motion()
	await targeting_and_capacity()
	await forward_targeting()
	await modifiers_and_contacts()
	await chain_exclusion()
	await lifecycle()
	if DisplayServer.get_name() != "headless": await native_presentation()
	stage.free()
	await settle()
	print("Escort drone: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func rank_and_flight(rank: int, boosted: bool) -> void:
	await reset_case()
	equip(p1, rank)
	var drone = p1.weapons.escort
	for index in 5 if boosted else 0:
		p1.loadout.apply_foundation(&"damage")
		p1.loadout.apply_foundation(&"fire_rate")
	var target = enemy(&"aimed", drone.muzzle.global_position + Vector2(40, -100), 100)
	await settle()
	p1.weapons.update_autonomous(0)
	materialize_bolts()
	check(active_bolts().size() == UPGRADE.support_count(rank) and get_nodes_in_group(&"escort_drone").size() == UPGRADE.support_count(rank), "ranks one and two retain one drone; rank three emits from both shoulder companions")
	var shot = active_bolts()[0]
	for other in active_bolts().slice(1): ProjectilePool.despawn(other)
	for other in p1.weapons.escorts.slice(1): other.wait = 10
	var expected: float = UPGRADE.rank_value(rank) * (2.25 if boosted else 1.0)
	check(is_equal_approx(shot.damage, expected) and is_equal_approx(shot.hit_snapshot.damage(), expected), "common DAMAGE applies exactly once")
	check(is_equal_approx(drone.wait, UPGRADE.interval_value(rank) * (0.6 if boosted else 1.0)), "independent cadence follows rank and the bounded common FIRE_RATE factor")
	var interval: float = drone.wait
	p1.weapons.update_autonomous(interval - 0.001)
	check(effects.get_debug_snapshot().requests == 0 and active_bolts().size() == 1, "the independent timer cannot emit before its full interval")
	p1.weapons.update_autonomous(0.002)
	check(effects.get_debug_snapshot().requests == 1, "the next interval emits one shot while manual fire remains idle")
	for id in effects._requests.keys():
		var queued: Dictionary = effects._requests[id]
		effects.release_reservation(queued.key)
		effects.release_root(queued.hit)
		effects._requests.erase(id)
	var velocity := Vector2(shot.speedX, shot.speedY)
	var start: Vector2 = shot.global_position
	check(is_equal_approx(velocity.length(), 360) and is_equal_approx(shot.remaining_lifetime, 1), "straight bolts use the contracted speed and lifetime")
	check(velocity.normalized().is_equal_approx((target.global_position - start).normalized()), "aim snapshots the target position at emission")
	target.position.x -= 120
	shot._physics_process(0.1)
	check(shot.global_position.is_equal_approx(start + velocity * 0.1) and Vector2(shot.speedX, shot.speedY) == velocity, "moving a target never steers or leads an airborne bolt")
	target.position = shot.position
	await settle()
	check(is_equal_approx(target.life, 100 - expected) and target.last_player_hit_owner == &"player1", "real Area2D contact applies the exact authored direct amount and owner")
	check(shot.get_meta("pooled", false) and effects.get_debug_snapshot().reservations == 0, "impact safely returns the bolt and releases its reservation")
	var same_drone = drone
	p1.reset_weapon_input()
	check(p1.weapons.escort == same_drone, "generic input reset preserves the escort")
	p1.position += Vector2(30, -20)
	check(drone.position == Vector2(24, -12) and drone.global_position == p1.global_position + Vector2(24, -12), "the nonblocking support follows the fixed shoulder anchor")
	check(drone.find_children("*", "CollisionObject2D", true, false).is_empty(), "support never blocks movement or intercepts projectiles")

func movement_and_reactors() -> void:
	await reset_case()
	for player in [p1, p2]:
		equip(player, 2)
		var first = player.weapons.escort
		player.apply_upgrade(UPGRADE)
		check(player.weapons.escort == first and player.weapons.escorts.size() == 2 and player.weapons.escorts[1].position.x == -first.position.x, "rank three adds the opposite shoulder without replacing the original drone")
		for motion in [Vector2(-1, -1), Vector2(1, 1), Vector2.ZERO]:
			player._motion = motion
			player.effects.update_reactor(motion.y, 1.0)
			for support in player.weapons.escorts:
				support.set_process(false)
				support._process(0.016)
				var expected_bank := 1 if motion.x < 0 else (2 if motion.x > 0 else 0)
				check(support.bank == expected_bank and int(support.hull.frame / 6.0) == support.team * 3 + expected_bank, "both owners bank through dedicated left/right frames with the Nomad's actual movement")
				check(support._reactors.size() == 2, "every escort has two reduced copies of the Nomad reactors")
				for reactor in support._reactors:
					check(is_equal_approx(reactor.scale.y, player.effects._reactor_length_scale) and is_equal_approx(reactor.modulate.a, player.effects._reactor_brightness), "escort exhaust length and brightness use the player's smoothed reactor state")
					for particles in reactor.get_children():
						check(is_equal_approx(particles.amount_ratio, player.effects._reactor_amount_ratio) and is_equal_approx(particles.speed_scale, player.effects._reactor_speed_scale), "forward, braking and idle emission match the existing player reactor response")
		player._motion = Vector2.ZERO
	enemy(&"dual_p1", Vector2(230, 210), 100)
	enemy(&"dual_p2", Vector2(420, 210), 100)
	await settle()
	for index in 5:
		for player in [p1, p2]:
			for support in player.weapons.escorts: support.wait = 0
			player.weapons.update_autonomous(0)
	check(effects.get_debug_snapshot().reservations == 12 and effects.get_debug_snapshot().requests == 12, "two companions still share six flying/reserved bolts per owner, including simultaneous deferred volleys")
	materialize_bolts()
	for player in [p1, p2]:
		check(active_bolts().filter(func(shot): return shot.player_Id == player.id_Player).size() == 6, "rank-three pairs cannot exceed their owner's common bolt cap")

func gliding_motion() -> void:
	await reset_case()
	for player in [p1, p2]:
		equip(player, 3)
		for support in player.weapons.escorts: support._process(0.2)
		check(player.weapons.escorts[0]._glide != player.weapons.escorts[1]._glide, "companions have deterministic independent hover phases")
		player.position += Vector2(8, -4)
		for support in player.weapons.escorts:
			support._process(1.0 / 60.0)
			check(support._lag.x < 0 and support._lag.y > 0 and support._lag.length() <= support.MAX_LAG, "bounded inertia trails actual ship displacement in both axes")
			check(support.muzzle.position == support.hull.position + Vector2(0, -7), "the aiming emitter moves with the gliding hull")
			var saved_glide: Vector2 = support._glide
			support._process(0)
			check(support._glide == saved_glide, "zero elapsed time cannot advance the glide")
			support._process(2.0)
			check(support._lag.length() < 0.001 and absf(support._glide.x) <= 0.651 and absf(support._glide.y) <= 1.501, "a stopped ship settles to the small idle hover without drift")
			player.position += Vector2(100, 0)
			support._process(1.0 / 60.0)
			check(support._lag.length() <= support.MAX_LAG, "sudden relocation cannot create an unbounded trailing offset")
			player.position -= Vector2(100, 0)

func targeting_and_capacity() -> void:
	await reset_case()
	equip(p1, 1)
	equip(p2, 1)
	var drone = p1.weapons.escort
	check(p2.weapons.escort.position == Vector2(-24, -12) and p2.weapons.escort.team == 1, "P2 has its own mirrored support and blue team frames")
	p1.weapons.update_autonomous(20)
	check(drone.wait == 0 and effects.get_debug_snapshot().requests == 0, "no target retains one ready shot without a timer backlog")
	var later = enemy(&"tie_b", drone.muzzle.global_position + Vector2(30, -40))
	var earlier = enemy(&"tie_a", drone.muzzle.global_position + Vector2(-30, -40))
	var far = enemy(&"far", drone.muzzle.global_position + Vector2(0, -181))
	await settle()
	p1.weapons.update_autonomous(0)
	var request: Dictionary = effects._requests.values()[0]
	check(request.velocity.normalized().is_equal_approx((earlier.global_position - drone.muzzle.global_position).normalized()), "nearest-target ties use stable spawn identity")
	materialize_bolts()
	for index in 12:
		drone.wait = 0
		p1.weapons.update_autonomous(10)
	check(effects.get_debug_snapshot().reservations == 6 and active_bolts().size() + effects.get_debug_snapshot().requests == 6, "six flying plus reserved bolts cap each owner even before deferred creation")
	check(is_equal_approx(drone.wait, 0.65), "saturation consumes an interval without queuing a burst")
	for index in 6: check(effects.queue_drone_bolt(&"player2", UPGRADE, 1, Vector2(450, 300), Vector2.UP, 1, {}, 0), "P2 retains its own six-bolt capacity while P1 is saturated")
	check(effects.get_debug_snapshot().reservations == 12, "both owners may reserve six bolts independently")
	materialize_bolts()
	for shot in active_bolts():
		shot._physics_process(1.01)
	await settle()
	check(active_bolts().is_empty() and effects.get_debug_snapshot().reservations == 0, "expiry clears all root leases and active capacity")
	later.free()
	earlier.free()
	drone.wait = 0
	p1.weapons.update_autonomous(0)
	check(effects.get_debug_snapshot().requests == 0, "targets beyond the authored radius cannot trigger fire")
	far.position = drone.muzzle.global_position + Vector2(0, -180)
	await settle()
	p1.weapons.update_autonomous(0)
	check(effects.get_debug_snapshot().requests == 1, "the exact range boundary is included")
	materialize_bolts()
	for shot in active_bolts(): ProjectilePool.despawn(shot)
	var armor := Area2D.new()
	armor.collision_layer = CombatTargeting.Layers.ENEMY
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(12, 20)
	armor.add_child(shape)
	armor.position = drone.muzzle.global_position + Vector2(0, -90)
	stage.add_child(armor)
	await settle()
	drone.wait = 0
	p1.weapons.update_autonomous(0)
	check(effects.get_debug_snapshot().requests == 0, "intervening armor occludes acquisition")
	armor.free()

func forward_targeting() -> void:
	for angle in [0.0, -10.0, 181.0, NAN, INF]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		invalid.weapon = UPGRADE.weapon.duplicate()
		invalid.weapon.forward_angle_degrees = angle
		check(not invalid.foundation_errors().is_empty(), "invalid drone cones must reject before entering offers")
	for player_index in 2:
		for rank in [1, 3]:
			await reset_case()
			var player = p1 if player_index == 0 else p2
			equip(player, rank)
			for support in player.weapons.escorts:
				var origin: Vector2 = support.muzzle.global_position
				enemy(&"behind", origin + Vector2(0, 24))
				enemy(&"left", origin + Vector2(-24, -2))
				enemy(&"right", origin + Vector2(24, -2))
				var outside_left = enemy(&"outside_left", origin + Vector2(-42, -40))
				var outside_right = enemy(&"outside_right", origin + Vector2(42, -40))
				await settle()
				support.wait = 0
				support.flash = 0
				support.tick(0)
				check(effects.get_debug_snapshot().requests == 0 and support.wait == 0 and support.flash == 0, "side and rear enemies cannot consume drone readiness or trigger a muzzle flash")
				materialize_bolts()
				for shot in active_bolts(): ProjectilePool.despawn(shot)
				var front = enemy(&"front", origin + Vector2(0, -140))
				await settle()
				support.wait = 0
				support.tick(0)
				materialize_bolts()
				check(active_bolts().size() == 1, "one valid forward enemy permits exactly one ready shot per support")
				if not active_bolts().is_empty():
					var shot = active_bolts()[0]
					check(Vector2(shot.speedX, shot.speedY).normalized().is_equal_approx(Vector2.UP) and shot.player_Id == player.id_Player, "each companion chooses the forward enemy even when lateral and rear enemies are closer")
					ProjectilePool.despawn(shot)
				front.free()
				outside_left.free()
				outside_right.free()
				for side in [-1, 1]:
					var edge = enemy(&"edge", origin + Vector2(side * 48, -48))
					await settle()
					support.wait = 0
					support.tick(0)
					materialize_bolts()
					check(active_bolts().size() == 1, "the exact left and right forty-five-degree boundaries remain eligible")
					if not active_bolts().is_empty():
						var shot = active_bolts()[0]
						check(Vector2(shot.speedX, shot.speedY).normalized().is_equal_approx(Vector2(side, -1).normalized()), "forward edge aim: actual %s, expected %s, emitter %s, target %s" % [Vector2(shot.speedX, shot.speedY), Vector2(side, -1).normalized() * 360, support.muzzle.global_position, edge.global_position])
						ProjectilePool.despawn(shot)
					edge.free()
				for target in get_nodes_in_group(&"enemy"):
					if stage.is_ancestor_of(target): target.free()
				await settle()

func modifiers_and_contacts() -> void:
	await reset_case()
	equip(p1, 3)
	var one = enemy(&"direct", Vector2(250, 220), 100)
	var two = enemy(&"arc", Vector2(280, 170), 100)
	await settle()
	var seed_state: int = effects.combat_random(&"player1").state
	var trace: Array[bool] = []
	for owner_id in [&"player1", &"player2"]:
		for replay in 2:
			effects.combat_random(owner_id).state = seed_state
			var rolls: Array[bool] = []
			for index in 32:
				var rolled_hit: PlayerHitSnapshot = effects.create_hit(owner_id, 0.9, 0.9, {}, PlayerHitSnapshot.Kind.DRONE, 0.3)
				rolls.append(rolled_hit.is_critical())
				effects.release_root(rolled_hit)
			if trace.is_empty(): trace.assign(rolls)
			else: check(rolls == trace, "personal combat RNG replays the same emission critical trace")
	effects.queue_drone_bolt(&"player1", UPGRADE, 3, Vector2(250, 300), Vector2.UP, 2.25, {&"piercing": 1, &"energy_chains": 1}, 1.0)
	materialize_bolts()
	var shot = active_bolts()[0]
	shot.position = one.position
	await settle()
	check(is_equal_approx(one.life, 95.95) and not shot.get_meta("pooled", false) and shot.remaining_penetrations == 0, "legacy compatible piercing retains emission-time critical damage on its first real contact")
	check(two.life == 100 and accepted.size() == 1 and effects._chain_cooldowns.is_empty() and get_nodes_in_group(&"energy_chain").is_empty(), "drone criticals cannot emit electric chains or consume the cannon cooldown")
	check(not effects.resolve_hit(shot.hit_snapshot, one), "a drone's piercing root cannot hit the same target twice")
	await settle()
	check(two.life == 100 and not shot.get_meta("pooled", false), "rejected duplicate contacts preserve the remaining projectile without damaging nearby enemies")
	var third = enemy(&"penetrated", Vector2(320, 220), 100)
	shot.position = third.position
	await settle()
	check(is_equal_approx(third.life, 96.76) and shot.get_meta("pooled", false), "the next unvisited direct target receives eighty percent of the same critical root")
	effects.queue_drone_bolt(&"player2", UPGRADE, 1, Vector2(450, 300), Vector2.UP, 1, {}, 0)
	materialize_bolts()
	var reused = active_bolts()[0]
	check(reused == shot and reused.remaining_penetrations == 0 and not reused.hit_snapshot.is_critical() and reused.player_Id == "player2" and reused.remaining_lifetime == 1, "pool reuse clears old owner, penetration, critical, damage decay and lifetime")
	ProjectilePool.despawn(reused)
	await settle()
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"escort_boss"
	boss.configure_spawn(context)
	boss.position = Vector2(450, 150)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	await settle()
	var packet: PlayerHitSnapshot = effects.create_hit(&"player1", 0.9, 0.9, {}, PlayerHitSnapshot.Kind.DRONE, 1)
	var total: float = boss.life + boss.get_node("PortCannon").life
	check(effects.resolve_hit(packet, boss.get_node("PortCannon")) and not effects.resolve_hit(packet, boss), "one drone root cannot damage another surface of the same multipart boss")
	check(is_equal_approx(boss.life + boss.get_node("PortCannon").life, total - 1.8), "multipart exclusion preserves exact critical damage")
	effects.release_root(packet)
	boss.free()

func chain_exclusion() -> void:
	for owner_id in [&"player1", &"player2"]:
		await reset_case()
		var target = enemy(&"drone_contact", Vector2(240, 200), 100)
		var nearby = enemy(&"chain_candidate", Vector2(280, 150), 100)
		await settle()
		effects.queue_drone_bolt(owner_id, UPGRADE, 3, Vector2(240, 300), Vector2.UP, 2.25, {&"energy_chains": 3}, 1.0)
		materialize_bolts()
		var shot = active_bolts()[0]
		check(shot.hit_snapshot.is_critical() and shot.hit_snapshot.modifier_rank(&"energy_chains") == 0, "drone snapshots retain criticals but discard electric-chain capability")
		shot.position = target.position
		await settle()
		check(is_equal_approx(target.life, 95.95) and target.last_player_hit_owner == owner_id and nearby.life == 100, "each owner's real drone impact deals only its direct critical damage")
		check(get_nodes_in_group(&"energy_chain").is_empty() and effects._chain_cooldowns.is_empty() and effects.get_debug_snapshot().roots == 0, "drone impacts create no lightning, chain cooldown or retained proc root")
		var raw: PlayerHitSnapshot = effects.create_hit(owner_id, 1, 1, {&"energy_chains": 3}, PlayerHitSnapshot.Kind.DRONE)
		check(effects.resolve_hit(raw, target), "a raw drone packet still resolves its direct damage")
		effects.release_root(raw)
		await settle()
		check(nearby.life == 100 and get_nodes_in_group(&"energy_chain").is_empty() and effects._chain_cooldowns.is_empty(), "source-kind exclusion blocks lightning even on an unfiltered drone packet")
		var gun: PlayerHitSnapshot = effects.create_hit(owner_id, 1, 1, {&"energy_chains": 1})
		check(effects.resolve_hit(gun, target), "the same owner's cannon can still trigger its normal chain immediately")
		effects.release_root(gun)
		await settle()
		check(is_equal_approx(nearby.life, 99.55) and get_nodes_in_group(&"energy_chain").size() == 1, "cannon lightning remains available after drone impacts")

func lifecycle() -> void:
	await reset_case()
	equip(p1, 1)
	equip(p2, 1)
	var drone = p1.weapons.escort
	enemy(&"lifecycle", Vector2(224, 200), 100)
	await settle()
	p1.beam_charge = 50
	Input.action_press(p1.controller + "_beam")
	p1._update_weapons(0.1)
	Input.action_release(p1.controller + "_beam")
	materialize_bolts()
	check(p1.beam_active and is_equal_approx(p1.beam_charge, 48) and active_bolts().size() == 1, "the independent drone fires during manual plasma use")
	var shot = active_bolts()[0]
	shot.set_physics_process(true)
	drone.set_process(true)
	var at: Vector2 = shot.position
	var lifetime: float = shot.remaining_lifetime
	var wait: float = drone.wait
	var age: float = drone.age
	var glide: Vector2 = drone._glide
	paused = true
	await process_frame
	await process_frame
	check(shot.position == at and shot.remaining_lifetime == lifetime and drone.wait == wait and drone.age == age and p1.weapons.escort == drone, "choice pause freezes support, flight and timer without destroying the drone")
	check(drone._glide == glide, "choice pause also preserves the gliding displacement and hover phase")
	paused = false
	shot.set_physics_process(false)
	drone.set_process(false)
	effects.queue_drone_bolt(&"player1", UPGRADE, 1, Vector2(224, 300), Vector2.UP, 1, {}, 0)
	p1.set_state(p1.State.DYING)
	check(p1.weapons.escort == null and is_instance_valid(p2.weapons.escort) and effects.get_debug_snapshot().requests == 0, "DYING removes only the owner's support and cancels reserved emissions")
	var victim = enemy(&"after_death", shot.position, 100)
	await settle()
	check(is_equal_approx(victim.life, 99.4) and shot.get_meta("pooled", false) and not accepted.back().first, "airborne direct bolts may finish after owner death without new procs")
	await reset_case()
	check(get_nodes_in_group(&"escort_drone").is_empty() and active_bolts().is_empty() and effects.get_debug_snapshot().roots == 0, "reset leaves no support or old root behind")
	var baseline := get_node_count()
	for cycle in 3:
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		for player in world.progression.players: player.set_physics_process(false)
		if cycle != 1:
			var pilot = world.progression.players[0]
			pilot.apply_upgrade(UPGRADE)
			world.hit_effects.queue_drone_bolt(&"player1", UPGRADE, 1, Vector2(220, 300), Vector2.UP, 1, {}, 0)
		world.free()
		await settle()
		check(get_node_count() == baseline and get_nodes_in_group(&"escort_drone").is_empty(), "restarting clears supports and deferred requests without node growth: %d / %d" % [get_node_count(), baseline])

func native_presentation() -> void:
	await reset_case()
	stage.visible = false
	for layout in ["solo", "native", "wide"]:
		var wide: bool = layout == "wide"
		globals.coop = layout != "solo"
		root.size = Vector2i(960 if wide else 640, 400)
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var previous := stage
		stage = world
		var viewport_offset := maxf((root.size.x - 640.0) * 0.5, 0.0)
		for player in world.progression.players:
			player.set_physics_process(false)
			player.position = Vector2((180 if player.id_Player == "player1" else 460) + viewport_offset, 330)
			equip(player, 3)
			enemy(StringName("native_" + player.id_Player), player.position + Vector2(50 if player.id_Player == "player1" else -50, -120), 100)
			player.weapons.update_autonomous(0)
		stage = previous
		await create_timer(0.1).timeout
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://escort_drone_%s.webp" % layout), true) == OK, "solo, native and wide ownership/aim captures save")
		if layout == "solo":
			var pilot = world.progression.players[0]
			for sample in 48:
				var direction := 1 if sample < 12 else (-1 if sample < 24 else 0)
				pilot.position.x += direction * 3
				pilot._motion = Vector2(direction, 0)
				pilot._update_movement_animation(direction)
				pilot.animation_player.advance(0)
				for support in pilot.weapons.escorts: support._process(1.0 / 60.0)
				await process_frame
				if sample in [0, 10, 14, 26, 47]:
					await RenderingServer.frame_post_draw
					check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://escort_drone_glide_%d.webp" % sample), true) == OK, "native gliding captures show trailing, reversal and settling")
		for motion in [Vector2(-1, -1), Vector2(1, 1), Vector2.ZERO]:
			for player in world.progression.players:
				player._motion = motion
				player._update_movement_animation(motion.x)
				player.animation_player.advance(0)
				player.effects.update_reactor(motion.y, 1.0)
				for support in player.weapons.escorts: support._process(0.016)
			await create_timer(0.2).timeout
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://escort_drone_motion_%s_%d.webp" % [layout, int(motion.x)]), true) == OK, "banking and matched forward/braking/idle reactors save in each viewport")
		for edge in [false, true]:
			for player in world.progression.players:
				var side_width := maxf((root.size.x - 640.0) * 0.5, 0.0)
				player.position = Vector2(player.STATS.bound_min.x if player.id_Player == "player1" else player.STATS.bound_max.x, player.STATS.bound_min.y if edge else player.STATS.bound_max.y) + Vector2(side_width, 0)
				player.weapons.escort._process(0)
				var drone = player.weapons.escort
				var screen_y: float = drone.get_global_transform_with_canvas().origin.y + drone.hull.position.y
				check(screen_y >= 12 and screen_y <= 388 and drone.position == Vector2(-24 if player.set_Player_2 else 24, -12), "edge adjustment preserves the fixed shoulder anchor and keeps the complete support visible")
				for support in player.weapons.escorts:
					support._process(0)
					var screen_x: float = support.get_global_transform_with_canvas().origin.x + support.hull.position.x
					check(screen_x >= player.STATS.bound_min.x + side_width and screen_x <= player.STATS.bound_max.x + side_width, "both escorts tuck into the arena without covering the HUD at the movement boundaries")
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://escort_drone_edges_%s_%s.webp" % [layout, "top" if edge else "bottom"]), true) == OK, "support remains visible at upper and lower playfield edges")
		var ui = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
		root.add_child(ui)
		var offers := [UPGRADE.offer_snapshot(2), load("res://data/upgrades/micro_missiles.tres").offer_snapshot(0), load("res://data/upgrades/energy_chains.tres").offer_snapshot(0)]
		var participants := {}
		for player in world.progression.players: participants[StringName(player.id_Player)] = {"build": player.loadout.foundation_snapshot(), "offers": offers}
		ui.open(900, participants, {"level": 4, "xp": 0, "next_threshold": 21})
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://escort_drone_choices_%s.webp" % layout), true) == OK, "owner cards and miniatures save")
		ui.free()
		world.free()
		await settle()
	root.size = Vector2i(640, 400)
	globals.coop = true
	stage.visible = true

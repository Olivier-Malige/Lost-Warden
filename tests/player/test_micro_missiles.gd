extends "res://tests/player/test_player_hit_contract.gd"

const UPGRADE: UpgradeDefinition = preload("res://data/upgrades/micro_missiles.tres")
var weapon: WeaponDefinition = UPGRADE.weapon

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = true
	globals.reset_run(808)
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
	check(UPGRADE.foundation_errors().is_empty() and PackedFloat32Array(UPGRADE.rank_values) == PackedFloat32Array([0.9, 1.1, 1.3]) and PackedFloat32Array(UPGRADE.interval_values) == PackedFloat32Array([1.1, 0.95, 0.8]), "all missile ranks must be authored in validated resources")
	check(PackedInt32Array(UPGRADE.projectile_counts) == PackedInt32Array([1, 2, 3]) and weapon.collision_sizes == PackedVector2Array([Vector2(3, 6), Vector2(4, 8), Vector2(5, 10)]), "missile volley counts and collision sizes progress through all three authored ranks")
	for field in ["interval_values", "weapon"]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		if field == "weapon":
			invalid.weapon = null
		else:
			invalid.interval_values = PackedFloat32Array([1.1, NAN, 0.8])
		check(not invalid.foundation_errors().is_empty(), "missing weapon or malformed intervals reject before activation")
	for field in ["projectile_lifetime", "active_limit"]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		invalid.weapon = weapon.duplicate()
		if field == "projectile_lifetime":
			invalid.weapon.projectile_lifetime = NAN
		else:
			invalid.weapon.active_limit = 4
		check(not invalid.foundation_errors().is_empty(), "invalid lifetime or over-cap weapon data reject before activation")
	var invalid_volley := UPGRADE.duplicate() as UpgradeDefinition
	invalid_volley.projectile_counts = PackedInt32Array([1, 2, 4])
	check(not invalid_volley.foundation_errors().is_empty(), "rank volleys cannot exceed their hard three-missile budget")
	await cadence_and_damage()
	await readiness_and_caps()
	await flight_and_reacquisition()
	await acquisition_and_manual_weapons()
	await forward_targeting()
	await missed_target_reacquisition()
	await destroyed_target_reacquisition()
	await critical_streams()
	await contact_and_reuse()
	await boss_contacts()
	await owner_and_world()
	if DisplayServer.get_name() != "headless": await native_presentation()
	await reset_case()
	stage.free()
	await process_frame
	print("Micro-missiles: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func active(owner := &"") -> Array:
	return get_nodes_in_group(&"micro_missile").filter(func(shot): return not shot.get_meta("pooled", false) and (owner == &"" or StringName(shot.player_Id) == owner))

func materialize() -> void:
	for id in effects._requests.keys(): effects._materialize(id)
	for shot in active(): shot.set_physics_process(false)

func reset_case() -> void:
	paused = false
	for player in [p1, p2]: player.set_physics_process(false)
	effects.cancel()
	for shot in get_nodes_in_group("player_Shot"):
		if not shot.get_meta("pooled", false): ProjectilePool.despawn(shot)
	await settle()
	for child in stage.get_children():
		if child not in [p1, p2, pool, effects]: child.free()
	for player in [p1, p2]:
		player.state = player.State.ACTIVE
		player.loadout.reset()
		player.weapons.missile_wait = 0.0
		player.position = Vector2(200 if player == p1 else 450, 350)
	effects.start([p1, p2], globals.run_random)
	accepted.clear()

func rank_up(player: Node, rank: int) -> void:
	for value in rank: check(player.apply_upgrade(UPGRADE).applied, "personal missile ranks apply through the real upgrade path")

func queue(target: Area2D, rank := 1, owner := &"player1", at := Vector2(200, 300), multiplier := 1.0, modifiers := {}, crit := 0.0) -> bool:
	return effects.queue_missile(owner, UPGRADE, rank, at, target, multiplier, modifiers, crit)

func cadence_and_damage() -> void:
	for rank in range(1, 4):
		for maximum in [false, true]:
			await reset_case()
			rank_up(p1, rank)
			if maximum:
				for index in 5:
					p1.loadout.apply_foundation(&"fire_rate")
					p1.loadout.apply_foundation(&"damage")
			var target = enemy(&"cadence", p1.primary_origin.global_position + Vector2(0, -120), 100)
			await settle()
			var emitted: Array[float] = []
			for frame in 200:
				p1.weapons.update_autonomous(1.0 / 60.0)
				materialize()
				if active().is_empty(): continue
				emitted.append(frame / 60.0)
				check(active().size() == rank, "the emitter produces one, two or three missiles per ranked volley")
				for shot in active():
					check(is_equal_approx(shot.damage, [0.9, 1.1, 1.3][rank - 1] * (2.25 if maximum else 1.0)), "emitted missile damage applies its rank and the common multiplier once")
					check(shot.hit_snapshot.kind() == PlayerHitSnapshot.Kind.MISSILE and shot.steering_target.get_ref() == target, "autonomous emissions own direct missile snapshots and acquire the nearest target")
					check(shot.upgrade_rank == rank and shot.get_node("Sprite2D").frame == (rank - 1) * 4 and shot.get_node("CollisionShape2D").shape.size == weapon.collision_sizes[rank - 1], "each rank uses its own native sprite animation and matching central hull collision")
					ProjectilePool.despawn(shot)
				await settle()
			check(emitted.size() >= 3 and emitted[0] == 0.0, "the first ready autonomous emission needs no manual fire and does not accumulate a backlog")
			for index in range(1, emitted.size()):
				var interval: float = [1.1, 0.95, 0.8][rank - 1] * (0.6 if maximum else 1.0)
				check(absf(emitted[index] - emitted[index - 1] - interval) <= 1.0 / 60.0 + 0.0001, "measured fixed-step emissions match rank cadence and FIRE_RATE extremes")
			check(p1.loadout.foundation_snapshot().offensive_count == 1 and p2.loadout.rank_for(UpgradeDefinition.Effect.MICRO_MISSILES) == 0, "all missile ranks occupy one offensive slot and remain personal")
			if rank == 3: check(not p1.apply_upgrade(UPGRADE).applied, "the third rank caps without consuming another slot")

func readiness_and_caps() -> void:
	await reset_case()
	rank_up(p1, 1)
	p1.weapons.update_autonomous(100.0)
	check(p1.weapons.missile_wait == 0 and effects.get_debug_snapshot().roots == 0, "no target retains only one ready emission and consumes no snapshot")
	var target = enemy(&"outside", p1.primary_origin.global_position + Vector2(221, 0))
	await settle()
	p1.weapons.update_autonomous(0)
	check(effects.get_debug_snapshot().requests == 0, "initial acquisition obeys the authored 220 pixel range")
	target.position = p1.primary_origin.global_position + Vector2(0, -120)
	await settle()
	for index in 3: check(queue(target), "pending direct missiles reserve their personal capacity before materializing")
	var rng_state: int = effects.combat_random(&"player1").state
	var sequence: int = effects._sequences[&"player1"]
	check(not queue(target, 1, &"player1", Vector2(200, 300), 1.0, {}, 1.0) and effects.get_debug_snapshot().reservations == 3 and effects.get_debug_snapshot().requests == 3, "active plus reserved entries cannot exceed three for one owner")
	check(effects.combat_random(&"player1").state == rng_state and effects._sequences[&"player1"] == sequence, "a denied saturated opportunity consumes no critical roll or source identity")
	p1.weapons.update_autonomous(0)
	check(p1.weapons.missile_wait > 1.09, "saturation discards this opportunity and starts a normal interval")
	materialize()
	for index in 3: check(queue(target, 1, &"player2", Vector2(450, 300)), "the partner retains an independent three-missile limit")
	materialize()
	check(active(&"player1").size() == 3 and active(&"player2").size() == 3 and effects.get_debug_snapshot().reservations == 6, "both owners can each reach their limit without sharing capacity")
	for shot in active(&"player1"): shot._physics_process(1.81)
	check(effects.get_debug_snapshot().reservations == 3 and active(&"player1").is_empty(), "actual expiry releases active capacity and root leases immediately")
	p1.weapons.update_autonomous(0.5)
	check(active(&"player1").is_empty() and effects.get_debug_snapshot().requests == 0, "freeing capacity does not replay a skipped emission")
	p1.weapons.update_autonomous(0.61)
	materialize()
	check(active(&"player1").size() == 1, "the next normal opportunity emits exactly one missile after saturation")
	await reset_case()
	rank_up(p1, 3)
	target = enemy(&"partial_volley", Vector2(200, 180))
	await settle()
	queue(target, 1, &"player1", Vector2(190, 300))
	queue(target, 1, &"player1", Vector2(210, 300))
	materialize()
	p1.weapons.update_autonomous(0)
	materialize()
	check(active().size() == 3 and active().filter(func(shot): return shot.upgrade_rank == 3).size() == 1, "a rank-three volley uses only free capacity rather than exceeding the active/reserved cap")
	check(active().filter(func(shot): return shot.upgrade_rank == 1).all(func(shot): return shot.get_node("CollisionShape2D").shape.size == Vector2(3, 6)), "large missiles cannot resize the independent collision resources of already flying small missiles")

func flight_and_reacquisition() -> void:
	await reset_case()
	var target = enemy(&"flight", Vector2(300, 90), 100)
	await settle()
	check(queue(target, 1, &"player1", Vector2(200, 250)), "guided-flight fixture queues a direct missile")
	materialize()
	var shot = active()[0]
	for frame in 15:
		var before: Vector2 = shot.global_position
		var angle: float = shot.rotation
		shot._physics_process(1.0 / 60.0)
		check(is_equal_approx(before.distance_to(shot.global_position), 4.0), "actual fixed-step travel measures 240 pixels per second")
		check(absf(wrapf(shot.rotation - angle, -PI, PI)) <= deg_to_rad(4) + 0.00001, "actual heading changes by at most 240 degrees per second")
	check(shot.rotation > deg_to_rad(20) and shot.rotation <= deg_to_rad(45) and is_equal_approx(shot.remaining_lifetime, 1.55), "guidance visibly curves toward an off-axis forward target and spends its bounded lifetime")
	target.position = shot.global_position + Vector2(-100, -150)
	var old_heading: float = shot.rotation
	for frame in 5: shot._physics_process(1.0 / 60.0)
	check(shot.rotation < old_heading and shot.steering_target.get_ref() == target, "guidance responds to a moving target while retaining its original acquisition")
	var replacement = enemy(&"replacement", shot.global_position + Vector2(40, -100))
	var later = enemy(&"later", shot.global_position + Vector2(-60, -120))
	await settle()
	target.free()
	shot._physics_process(1.0 / 60.0)
	check(shot.reacquired and shot.steering_target.get_ref() == replacement, "first target loss reacquires the nearest valid target above")
	replacement.free()
	var heading: float = shot.rotation
	shot._physics_process(1.0 / 60.0)
	check(shot.steering_target.get_ref() == later and shot.reacquired and absf(wrapf(shot.rotation - heading, -PI, PI)) <= deg_to_rad(4) + 0.00001 and later.life == 20.0, "later target loss reacquires again with bounded turning and no remote damage")
	shot._physics_process(1.8)
	check(shot.get_meta("pooled", false) and effects.get_debug_snapshot().reservations == 0, "guided or straight flight always expires")
	await reset_case()
	target = enemy(&"pause", Vector2(200, 150))
	await settle()
	queue(target)
	materialize()
	shot = active()[0]
	shot.set_physics_process(true)
	rank_up(p1, 1)
	p1.weapons.missile_wait = 1.0
	p1.set_physics_process(true)
	await settle()
	paused = true
	var at: Vector2 = shot.position
	var lifetime: float = shot.remaining_lifetime
	var wait: float = p1.weapons.missile_wait
	await create_timer(0.12, true).timeout
	check(shot.position == at and shot.remaining_lifetime == lifetime and p1.weapons.missile_wait == wait, "real scene pause freezes flight, lifetime and the autonomous emitter together")
	paused = false
	p1.set_physics_process(false)
	await settle()
	check(shot.position != at and shot.remaining_lifetime < lifetime, "actual guidance resumes after selection pause")
	await reset_case()
	target = enemy(&"lost_without_replacement", Vector2(200, 150))
	await settle()
	queue(target)
	materialize()
	shot = active()[0]
	target.free()
	shot._physics_process(1.0 / 60.0)
	check(shot.reacquired and shot.steering_target == null, "a targetless missile continues flying while awaiting another visible target above")
	var late_target = enemy(&"late_replacement", Vector2(250, 200))
	await settle()
	shot._physics_process(0.1)
	check(shot.steering_target.get_ref() == late_target and shot.rotation > 0, "a later arrival can be acquired on the bounded retry interval")

func acquisition_and_manual_weapons() -> void:
	await reset_case()
	rank_up(p1, 1)
	var origin: Vector2 = p1.primary_origin.global_position
	var late = enemy(&"tie_z", origin + Vector2(40, -110))
	var early = enemy(&"tie_a", origin + Vector2(-40, -110))
	await settle()
	p1.weapons.update_autonomous(0)
	materialize()
	check(active().size() == 1 and active()[0].steering_target.get_ref() == early, "the real emitter breaks equal-distance acquisition ties by stable spawn identity")
	ProjectilePool.despawn(active()[0])
	late.free()
	early.free()
	await settle()
	enemy(&"manual_compatibility", origin + Vector2(0, -140))
	await settle()
	p1.weapons.missile_wait = 0
	p1.beam_charge = 50
	Input.action_press(p1.controller + "_beam")
	p1._update_weapons(0.1)
	Input.action_release(p1.controller + "_beam")
	p1.continuous_beam.set_physics_process(false)
	materialize()
	check(p1.beam_active and is_equal_approx(p1.beam_charge, 48) and active().size() == 1 and not p1.shooting, "autonomous missiles emit while the manual signature beam drains its own plasma normally")
	p1.canShooting = true
	Input.action_press(p1.controller + "_fire")
	p1._update_weapons(0)
	Input.action_release(p1.controller + "_fire")
	var guns := get_nodes_in_group("player_Shot").filter(func(shot): return not shot.get_meta("pooled", false) and not shot.is_in_group(&"micro_missile"))
	check(not p1.beam_active and p1.shooting and guns.size() == 1 and active().size() == 1, "manual cannon fire remains independent of a flying autonomous missile")
	for shot in guns: ProjectilePool.despawn(shot)
	p1.shooting = false
	await reset_case()

func forward_targeting() -> void:
	await reset_case()
	rank_up(p1, 1)
	var muzzle: Vector2 = p1.primary_origin.global_position
	var behind = enemy(&"behind", muzzle + Vector2(60, 40))
	var side = enemy(&"side", muzzle + Vector2(80, -5))
	var front = enemy(&"front", muzzle + Vector2(0, -140))
	await settle()
	p1.weapons.update_autonomous(0)
	materialize()
	check(active().size() == 1 and active()[0].steering_target.get_ref() == front, "closer rear and lateral enemies cannot compete with a valid forward target")
	ProjectilePool.despawn(active()[0])
	front.free()
	await settle()
	p1.weapons.missile_wait = 0
	p1.weapons.update_autonomous(0)
	check(effects.get_debug_snapshot().requests == 0 and p1.weapons.missile_wait == 0, "rear and lateral enemies alone retain one ready emission without launching")
	behind.free()
	side.free()
	var boundary = enemy(&"cone_boundary", muzzle + Vector2(80, -80))
	var outside = enemy(&"outside_cone", muzzle + Vector2(-40, -39))
	await settle()
	p1.weapons.update_autonomous(0)
	materialize()
	var shot = active()[0]
	check(shot.steering_target.get_ref() == boundary and outside.life == 20, "the 45-degree edge qualifies while a closer target beyond it does not")
	boundary.position = shot.global_position + Vector2(25, 25)
	var replacement = enemy(&"forward_replacement", shot.global_position + Vector2(40, -100))
	await settle()
	shot._physics_process(1.0 / 60.0)
	check(shot.reacquired and shot.steering_target.get_ref() == outside, "after a miss the closest upper target wins even outside the launch cone")
	outside.position = shot.global_position + Vector2(-25, 25)
	await settle()
	shot._physics_process(1.0 / 60.0)
	check(shot.steering_target.get_ref() == replacement and outside.life == 20 and boundary.life == 20, "a second miss acquires another upper target without remote damage")
	replacement.position = shot.global_position + Vector2(25, 25)
	await settle()
	var heading: float = shot.rotation
	shot._physics_process(1.0 / 60.0)
	check(shot.steering_target == null and shot.rotation == heading and replacement.life == 20 and boundary.life == 20, "a passed replacement is abandoned without a backward turn, new target or remote damage")
	var invalid := UPGRADE.duplicate() as UpgradeDefinition
	invalid.weapon = weapon.duplicate()
	invalid.weapon.forward_angle_degrees = 181
	check(not invalid.foundation_errors().is_empty(), "a missile definition cannot enable a rear-facing acquisition cone")

func missed_target_reacquisition() -> void:
	await reset_case()
	var missed = enemy(&"missed", Vector2(200, 200))
	var nearest = enemy(&"nearest_upper", Vector2(240, 185))
	var farther = enemy(&"farther_upper", Vector2(200, 120))
	var below = enemy(&"closer_below", Vector2(205, 195))
	var level = enemy(&"same_height", Vector2(205, 190))
	await settle()
	queue(missed)
	materialize()
	var shot = active()[0]
	shot.position = Vector2(200, 190)
	var lifetime: float = shot.remaining_lifetime
	shot._physics_process(1.0 / 60.0)
	check(shot.steering_target.get_ref() == nearest and is_equal_approx(shot.remaining_lifetime, lifetime - 1.0 / 60.0), "a missile past its living target chooses the nearest enemy strictly above without renewing its lifetime")
	check([missed, nearest, farther, below, level].all(func(body): return body.life == 20), "switching targets never applies damage without physical contact")
	missed.position = shot.position + Vector2(60, -12)
	nearest.position = shot.position + Vector2(0, 20)
	below.position.y += 30
	level.position.y += 30
	await settle()
	shot._physics_process(1.0 / 60.0)
	check(shot.steering_target.get_ref() == farther and shot.speedY < 0, "another miss excludes the previously missed target and continues steering upward")

func destroyed_target_reacquisition() -> void:
	await reset_case()
	rank_up(p1, 3)
	var target = enemy(&"volley_victim", Vector2(200, 200), 1)
	target.life = 0.5
	var near = enemy(&"near_replacement", Vector2(240, 180))
	var farther = enemy(&"farther_replacement", Vector2(300, 140))
	var side = enemy(&"side_replacement", Vector2(250, 360))
	var behind = enemy(&"rear_replacement", Vector2(250, 370))
	await settle()
	p1.weapons.update_autonomous(0)
	materialize()
	var volley := active()
	check(volley.size() == 3 and volley.all(func(shot): return shot.steering_target.get_ref() == target), "all three actual volley emissions initially track the same nearest forward enemy")
	volley[0].position = target.position
	await settle()
	check(is_instance_valid(target) and target.destroyed and active().size() == 2, "one real missile contact destroys the target while its two siblings remain in flight")
	for shot in active():
		var lifetime: float = shot.remaining_lifetime
		shot._physics_process(1.0 / 60.0)
		check(shot.reacquired and shot.steering_target.get_ref() == near, "a real destruction selects the closest valid replacement ahead while ignoring nearer side/rear enemies")
		check(is_equal_approx(shot.remaining_lifetime, lifetime - 1.0 / 60.0), "reacquisition spends the existing lifetime without refreshing it")
		shot.set_physics_process(true)
	await create_timer(1.0).timeout
	check(is_equal_approx(near.life, 17.4) and farther.life == 20 and side.life == 20 and behind.life == 20, "both surviving missiles physically reach the nearby replacement rather than applying remote or rear-target damage")
	check(active().is_empty() and effects.get_debug_snapshot().roots == 0 and effects.get_debug_snapshot().reservations == 0, "replacement impacts retire both remaining missiles and all their ownership bookkeeping")

func critical_streams() -> void:
	await reset_case()
	var target = enemy(&"critical_trace", Vector2(200, 150), 100)
	await settle()
	var random := RunRandom.new(556)
	var expected := RunRandom.new(556)
	effects.start([p1, p2], random)
	for index in 24:
		for draw in index % 4:
			random.encounters.randf()
			random.drops.randf()
			random.upgrades.randf()
		check(queue(target, 1, &"player1", Vector2(200, 300), 1.0, {}, 0.3), "a valid missile critical trial reserves one root")
		materialize()
		var shot = active()[0]
		check(shot.hit_snapshot.is_critical() == (expected.combat_for(&"player1").randf() < 0.3), "fixed-seed missile critical traces are independent of encounter, drop and offer draws")
		ProjectilePool.despawn(shot)
		await settle()
	check(random.combat_for(&"player2").state == expected.combat_for(&"player2").state, "P1 missile criticals consume none of the partner's combat stream")

func contact_and_reuse() -> void:
	await reset_case()
	var target = enemy(&"direct", Vector2(240, 170))
	var next = enemy(&"chain", Vector2(300, 170))
	await settle()
	queue(target, 3, &"player1", Vector2(240, 260), 2.25, {&"energy_chains": 3, &"piercing": 3, &"ricochet": 3}, 1.0)
	materialize()
	var shot = active()[0]
	check(shot.hit_snapshot.is_critical() and shot.hit_snapshot.modifier_rank(&"piercing") == 0 and shot.hit_snapshot.modifier_rank(&"ricochet") == 0 and shot.hit_snapshot.modifier_rank(&"energy_chains") == 0, "missiles keep criticals but discard piercing, ricochet and electric-chain modifiers")
	shot.position = target.position
	await settle()
	check(is_equal_approx(target.life, 14.15) and next.life == 20 and get_nodes_in_group(&"energy_chain").is_empty() and effects._chain_cooldowns.is_empty(), "physical missile criticals cannot trigger an electric chain or consume the cannon's chain cooldown")
	check(shot.get_meta("pooled", false) and shot.hit_snapshot == null and effects.get_debug_snapshot().roots == 0 and effects.get_debug_snapshot().reservations == 0, "contact retires the missile, root and reservation without pending chain work")
	check(get_nodes_in_group(&"micro_missile_impact").size() == 1 and get_nodes_in_group(&"critical_impact").size() == 1, "accepted missile criticals show both dedicated owner effects")
	var unfiltered: PlayerHitSnapshot = effects.create_hit(&"player1", 1, 1, {&"energy_chains": 3}, PlayerHitSnapshot.Kind.MISSILE)
	check(effects.resolve_hit(unfiltered, target), "an unfiltered missile packet still resolves direct damage")
	effects.release_root(unfiltered)
	await settle()
	check(next.life == 20 and get_nodes_in_group(&"energy_chain").is_empty() and effects._chain_cooldowns.is_empty(), "the source-kind guard blocks lightning even if a missile packet contains the chain modifier")
	var gun: PlayerHitSnapshot = effects.create_hit(&"player1", 1, 1, {&"energy_chains": 3})
	check(effects.resolve_hit(gun, target), "ordinary cannon contacts remain eligible for the electric-chain family")
	effects.release_root(gun)
	await settle()
	check(is_equal_approx(next.life, 19.55) and get_nodes_in_group(&"energy_chain").size() == 1, "a cannon can trigger its normal chain immediately after missile impacts")
	queue(next, 1, &"player2", Vector2(450, 300))
	materialize()
	var reused = active()[0]
	check(reused == shot and reused.player_Id == "player2" and reused.get_node("Sprite2D").frame == 16 and reused.upgrade_rank == 1 and reused.get_node("CollisionShape2D").shape.size == Vector2(3, 6) and not reused.reacquired and reused._missed_groups.is_empty() and reused._retarget_wait == 0 and reused.rotation == 0 and reused.remaining_lifetime == 1.8, "cross-player pool reuse resets rank size, owner art, heading, missed targets, retry timer and lifetime")
	check(reused.steering_target.get_ref() == next and not reused.hit_snapshot.is_critical() and reused.hit_snapshot.modifier_rank(&"energy_chains") == 0 and is_equal_approx(reused.damage, 0.9), "recycled missiles cannot retain the previous owner's damage, critical or proc state")
	ProjectilePool.despawn(reused)
	await settle()
	reused._on_screen_exited()
	check(effects.get_debug_snapshot().reservations == 0, "a hidden parked missile cannot double-release its reservation through screen exit")
	await reset_case()
	target = enemy(&"kill", Vector2(240, 170), 1)
	target.life = 0.5
	await settle()
	var xp_before := xp_events
	var kills: int = globals.eliminations
	queue(target)
	materialize()
	active()[0].position = target.position
	await settle()
	check(target.destroyed and target.last_player_hit_owner == &"player1" and xp_events == xp_before + 1 and globals.eliminations == kills + 1, "a physical missile kill retains normal XP and elimination ownership exactly once")

func boss_contacts() -> void:
	await reset_case()
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"missile_boss"
	boss.configure_spawn(context)
	boss.position = Vector2(320, 110)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	var cannon = boss.get_node("PortCannon")
	await settle()
	var health: float = boss.life + cannon.life + boss.get_node("StarboardCannon").life
	queue(cannon, 1, &"player1", boss.position + Vector2(-40, -5))
	materialize()
	await settle()
	check(active().is_empty() and is_equal_approx(health, boss.life + cannon.life + boss.get_node("StarboardCannon").life), "real armor collision stops a missile without penetrating or damaging a boss surface")
	queue(cannon, 1, &"player1", cannon.global_position)
	materialize()
	await settle()
	check(active().is_empty() and is_equal_approx(health - boss.life - cannon.life - boss.get_node("StarboardCannon").life, 0.9), "a real vulnerable cannon contact damages only one boss group and never splashes")

func owner_and_world() -> void:
	await reset_case()
	var target = enemy(&"owner", Vector2(200, 150))
	var next = enemy(&"next", Vector2(260, 150))
	await settle()
	queue(target, 1, &"player1", Vector2(200, 300), 1.0, {&"energy_chains": 3})
	materialize()
	var flying = active()[0]
	queue(target)
	p1.state = p1.State.DYING
	effects.stop_owner(&"player1")
	await settle()
	check(active().size() == 1 and effects.get_debug_snapshot().requests == 0 and effects.get_debug_snapshot().reservations == 1, "owner DYING cancels pending missiles while bounded existing flight survives")
	flying.position = target.position
	await settle()
	check(is_equal_approx(target.life, 19.1) and next.life == 20 and effects.get_debug_snapshot().roots == 0, "a flying missile may finish after owner death, without starting a new proc")
	await reset_case()
	target = enemy(&"cancel", Vector2(200, 150))
	await settle()
	queue(target)
	effects.cancel()
	await settle()
	check(active().is_empty() and effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "world cancellation clears pending direct roots and reservations before deferred creation")
	await reset_case()
	await create_timer(0.45).timeout
	var baseline := get_node_count()
	for cycle in 5:
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var owner = world.progression.players[0]
		owner.set_physics_process(false)
		var previous := stage
		stage = world
		var victim = enemy(StringName("restart_%d" % cycle), Vector2(220, 180))
		stage = previous
		world.hit_effects.queue_missile(&"player1", UPGRADE, 1, Vector2(220, 300), victim, 1.0, {}, 0.0)
		world.free()
		await settle()
		check(get_node_count() == baseline and active().is_empty(), "real repeated world destruction cancels reserved missiles without node growth")

func native_presentation() -> void:
	await reset_case()
	stage.visible = false
	for coop in [false, true]:
		globals.coop = coop
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var players: Array = world.progression.players
		var previous := stage
		stage = world
		for index in players.size():
			var player = players[index]
			player.position = Vector2(220 + index * 200 if coop else 320, 350)
			player.set_physics_process(false)
			for rank in 3: player.apply_upgrade(UPGRADE)
			enemy(StringName("native_target_%d" % index), player.position + Vector2(55 if index == 0 else -55, -175), 100)
			player.weapons.update_autonomous(0)
		stage = previous
		for sample in 3:
			await create_timer(0.1).timeout
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://micro_missiles_%s_%d.webp" % ["coop" if coop else "solo", sample]), true) == OK, "native guided flight and owner art must save")
		for shot in active():
			if world.is_ancestor_of(shot):
				shot.set_physics_process(false)
				shot.global_position = shot.steering_target.get_ref().global_position
		await settle()
		var impacts := get_nodes_in_group(&"micro_missile_impact")
		check(impacts.size() == players.size() * 3, "physical native contacts show the three rank-three missiles for each owner")
		for impact in impacts: impact.set_process(false)
		for frame in 4:
			for impact in impacts:
				impact.age = frame * 0.05
				impact._process(0.0)
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://micro_missiles_%s_impact_%d.webp" % ["coop" if coop else "solo", frame]), true) == OK, "native impact animation frames must save")
		var ui = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
		root.add_child(ui)
		var offers := [UPGRADE.offer_snapshot(2), load("res://data/upgrades/energy_chains.tres").offer_snapshot(0), load("res://data/upgrades/beam_piercing.tres").offer_snapshot(0)]
		var participants := {}
		for player in players: participants[StringName(player.id_Player)] = {"build": player.loadout.foundation_snapshot(), "offers": offers}
		ui.open(800, participants, {"level": 4, "xp": 0, "next_threshold": 21})
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://micro_missiles_%s_choices.webp" % ["coop" if coop else "solo"]), true) == OK, "native missile cards and personal miniatures must save")
		ui.free()
		if not coop:
			for impact in impacts: impact.free()
			var solo = players[0]
			solo.loadout.reset()
			for rank in range(1, 4):
				for shot in active():
					if world.is_ancestor_of(shot): ProjectilePool.despawn(shot)
				await settle()
				solo.apply_upgrade(UPGRADE)
				solo.weapons.missile_wait = 0.0
				solo.weapons.update_autonomous(0.0)
				await create_timer(0.15).timeout
				check(active().size() == rank, "native rank review must show one, two and three missiles per volley")
				await RenderingServer.frame_post_draw
				check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://micro_missiles_rank_%d.webp" % rank), true) == OK, "native size and volley progression must save at each rank")
		world.free()
		await process_frame
	stage.visible = true

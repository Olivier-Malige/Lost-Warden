extends "res://tests/player/test_player_hit_contract.gd"

const UPGRADE: UpgradeDefinition = preload("res://data/upgrades/orbiting_satellites.tres")

func reset_case() -> void:
	effects.cancel()
	for player in [p1, p2]:
		player.weapons.stop_support()
		player.loadout.reset()
		player.state = player.State.ACTIVE
		player.position = Vector2(220 if player == p1 else 450, 250)
	await settle()
	for child in stage.get_children():
		if child not in [p1, p2, pool, effects]: child.free()
	effects.start([p1, p2], globals.run_random)
	accepted.clear()
	xp_events = 0

func equip(player: Node, value: int) -> Variant:
	for index in value: check(player.apply_upgrade(UPGRADE).applied, "satellite ranks acquire through the normal live catalog")
	var satellites = player.weapons.satellites
	check(is_instance_valid(satellites), "acquisition creates one owned orbit controller")
	satellites.set_physics_process(false)
	await settle()
	return satellites

func contact_enemy(id: StringName, at: Vector2, health := 1000.0, radius := 10.0) -> Variant:
	var target = enemy(id, at, health)
	target.collision_mask = 0
	var circle := CircleShape2D.new()
	circle.radius = radius
	target.get_node("CollisionShape2D").shape = circle
	return target

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = true
	globals.reset_run(1010)
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
		player.collision_mask = 0
		player.monitorable = false
		for kind in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
			for audio in player.find_children("*", kind, true, false): audio.stream = null
		if index == 0: p1 = player
		else: p2 = player
	effects.hit_accepted.connect(func(hit, target, at, first): accepted.append({"hit": hit, "target": target, "position": at, "first": first}))
	events.xp_spawn_requested.connect(func(_amount, _at): xp_events += 1)
	await reset_case()
	check(UPGRADE.foundation_errors().is_empty() and PackedInt32Array(UPGRADE.support_counts) == PackedInt32Array([1, 2, 3]) and PackedFloat32Array(UPGRADE.rank_values) == PackedFloat32Array([1, 1.25, 1.5]), "the completed family authors the contracted counts and direct damage")
	check(UPGRADE.orbit_period == 1.25 and UPGRADE.spin_period == 0.625 and UPGRADE.offer_snapshot(0).spin_period == 0.625, "the resource and offer author independent orbit and spin periods")
	for field in ["orbit_radius", "orbit_period", "spin_period", "contact_radius", "contact_cooldown"]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		invalid.set(field, NAN)
		check(not invalid.foundation_errors().is_empty(), "invalid satellite geometry or timing rejects before offers")
	for period in [0.0, -0.625, INF]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		invalid.spin_period = period
		check(not invalid.foundation_errors().is_empty(), "satellite spin rejects nonpositive or infinite periods")
	for count in [0, 4]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		invalid.support_counts = PackedInt32Array([1, 2, count])
		check(not invalid.foundation_errors().is_empty(), "satellites cannot author zero or more than three contacts")
	await geometry()
	for value in range(1, 4):
		for boosted in [false, true]: await contact_cadence(value, boosted)
	await independent_owners()
	await crossing_and_reentry()
	await moving_crossings()
	await critical_replay()
	await boss_and_rejections()
	await proc_and_projectile_rules()
	await lifecycle()
	if DisplayServer.get_name() != "headless": await native_presentation()
	await reset_case()
	stage.free()
	await settle()
	print("Orbiting satellites: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func geometry() -> void:
	await reset_case()
	var satellites = await equip(p1, 1)
	satellites.phase = 0.37
	satellites.spin_phase = 0.61
	for value in range(1, 4):
		if value > 1:
			check(p1.apply_upgrade(UPGRADE).applied, "ranking adds one orbiter without replacing the orbit controller")
			await settle()
		check(p1.weapons.satellites == satellites and satellites._orbiters.size() == value and is_equal_approx(satellites.phase, 0.37) and is_equal_approx(satellites.spin_phase, 0.61), "rank changes preserve the deterministic orbit and spin phases")
		satellites._sync_positions()
		for index in value:
			var orb = satellites._orbiters[index]
			check(orb.position.is_equal_approx(Vector2.from_angle(0.37 + TAU * index / value) * 32), "orbiters remain evenly spaced on the exact thirty-two-pixel circle")
			check(orb.collision_layer == 0 and orb.collision_mask == CombatTargeting.Layers.ENEMY | CombatTargeting.Layers.ASTEROID and not orb.monitorable and orb.get_child(0).shape.radius == 4, "the four-pixel contact mask only observes enemy and asteroid surfaces")
			var sprite: Sprite2D = orb.get_child(1)
			check(absf(angle_difference(sprite.rotation, 0.61 + TAU * index / value)) < 0.0001 and sprite.vframes == 2 and int(sprite.frame / 8.0) == 0 and orb.rotation == 0.0, "one red hull rotates continuously by script without rotating its contact collider")
		var initial_phase: float = satellites.phase
		var initial_spin: float = satellites.spin_phase
		satellites._physics_process(0.3125)
		check(absf(angle_difference(initial_phase + PI / 2, satellites.phase)) < 0.0001 and absf(angle_difference(initial_spin + PI, satellites.spin_phase)) < 0.0001, "a quarter orbit advances the hull through an independent half spin at every rank")
		satellites._physics_process(0.9375)
		check(absf(angle_difference(initial_phase, satellites.phase)) < 0.0001 and absf(angle_difference(initial_spin, satellites.spin_phase)) < 0.0001, "all ranks complete one orbit and two spins in 1.25 seconds")
	for boosted in [false, true]:
		if boosted:
			for rank in 5: p1.loadout.apply_foundation(&"fire_rate")
		var initial: float = satellites.phase
		var initial_spin: float = satellites.spin_phase
		for step in 75: satellites._physics_process(1.0 / 60.0)
		check(absf(angle_difference(initial, satellites.phase)) < 0.0001 and absf(angle_difference(initial_spin, satellites.spin_phase)) < 0.0001, "one orbit and two spins take 1.25 seconds at sixty physics ticks, including maximum FIRE_RATE")
	var other = await equip(p2, 3)
	check(other.phase == PI and other.spin_phase == PI, "the second owner starts with deterministic separate orbit and spin phases")
	for index in 3:
		var sprite: Sprite2D = other._orbiters[index].get_child(1)
		check(int(sprite.frame / 8.0) == 1 and absf(angle_difference(sprite.rotation, PI + TAU * index / 3)) < 0.0001, "P2 uses one blue hull with an independent scripted angle")

func contact_cadence(value: int, boosted: bool) -> void:
	await reset_case()
	var satellites = await equip(p1, value)
	if boosted:
		for rank in 5:
			p1.loadout.apply_foundation(&"damage")
			p1.loadout.apply_foundation(&"fire_rate")
	var target = contact_enemy(&"continuous", p1.position, 1000, 46)
	await settle()
	check(satellites._orbiters.all(func(orb): return orb.overlaps_area(target)), "all orbiters really overlap the same physics target")
	satellites._resolve_contacts()
	var amount: float = UPGRADE.rank_value(value) * (2.25 if boosted else 1.0)
	var cooldown := 0.3 if boosted else 0.5
	check(is_equal_approx(target.life, 1000 - amount) and accepted.size() == 1, "several orbiters share one accepted direct hit per logical target")
	check(is_equal_approx(satellites._cooldowns[&"continuous"].left, cooldown), "FIRE_RATE scales only the shared contact cooldown")
	check(accepted[0].hit.kind() == PlayerHitSnapshot.Kind.SATELLITE and accepted[0].hit.owner_id() == &"player1" and is_equal_approx(accepted[0].hit.authored_base(), UPGRADE.rank_value(value)), "contact roots retain their authored base and owner without applying DAMAGE twice")
	var rng_state: int = effects.combat_random(&"player1").state
	for retry in 5: satellites._resolve_contacts()
	check(accepted.size() == 1 and effects.combat_random(&"player1").state == rng_state, "blocked repeat contacts do not consume critical RNG")
	satellites._physics_process(cooldown - 0.01)
	check(accepted.size() == 1, "continuous overlap cannot bypass the cooldown before its boundary")
	satellites._physics_process(0.02)
	check(accepted.size() == 2 and is_equal_approx(target.life, 1000 - amount * 2), "continuous overlap ticks again when the adjusted cooldown expires")
	check(effects.get_debug_snapshot().roots == 0, "each accepted contact releases its bounded root")
	target.destroyed = true
	satellites._physics_process(0)
	check(satellites._cooldowns.is_empty(), "destroyed groups cannot retain cooldown records")

func independent_owners() -> void:
	await reset_case()
	p2.position = p1.position
	var left = await equip(p1, 3)
	var right = await equip(p2, 3)
	var target = contact_enemy(&"shared", p1.position, 1000, 46)
	await settle()
	left._resolve_contacts()
	right._resolve_contacts()
	check(is_equal_approx(target.life, 997) and accepted.size() == 2, "both owners have an independent contact cooldown on the same enemy")
	check(accepted[0].hit.owner_id() == &"player1" and accepted[1].hit.owner_id() == &"player2" and is_equal_approx(right.phase, PI), "P2 ownership and deterministic initial phase remain distinct")

func crossing_and_reentry() -> void:
	await reset_case()
	var satellites = await equip(p1, 1)
	var at: Vector2 = satellites._orbiters[0].global_position
	var target = contact_enemy(&"crossing", at + Vector2(0, -40), 1000, 2)
	await settle()
	satellites._resolve_contacts()
	check(accepted.is_empty(), "a nearby non-overlapping enemy takes no contact damage")
	target.position = at
	await settle()
	satellites._resolve_contacts()
	check(accepted.size() == 1, "a brief actual crossing accepts one direct contact")
	target.position.y -= 40
	await settle()
	target.position = at
	await settle()
	satellites._resolve_contacts()
	check(accepted.size() == 1, "leaving and re-entering cannot reset the group's cooldown")
	target.free()
	await settle()
	satellites._physics_process(0)
	check(satellites._cooldowns.is_empty(), "freed targets remove weak cooldown entries")

func moving_crossings() -> void:
	for owner_index in 2:
		for value in range(1, 4):
			await reset_case()
			var pilot = p1 if owner_index == 0 else p2
			var satellites = await equip(pilot, value)
			var target = enemy(&"moving_crossing", pilot.position + Vector2(-32 if owner_index == 0 else 32, -52), 1000)
			target.collision_mask = 0
			target._movement_profile = MovementProfile.new()
			target.speedX = 0
			target.speedY = 80
			await settle()
			satellites.set_physics_process(true)
			target.set_physics_process(true)
			for tick in 48:
				await physics_frame
				await process_frame
			satellites.set_physics_process(false)
			target.set_physics_process(false)
			check(not accepted.is_empty() and target.life < 1000, "a real moving enemy crosses the faster orbit at every rank for either owner")
			check(is_equal_approx(1000 - target.life, accepted.size() * UPGRADE.rank_value(value)), "moving contacts subtract actual HP exactly once per accepted direct hit")
			check(accepted.all(func(entry): return entry.hit.owner_id() == StringName(pilot.id_Player) and entry.hit.kind() == PlayerHitSnapshot.Kind.SATELLITE), "faster contacts preserve source and personal ownership")

func critical_replay() -> void:
	for owner_index in 2:
		var traces: Array = []
		for replay in 2:
			await reset_case()
			var pilot = p1 if owner_index == 0 else p2
			var owner_id := StringName(pilot.id_Player)
			var other_id := &"player2" if owner_index == 0 else &"player1"
			var satellites = await equip(pilot, 3)
			pilot.loadout.critical_chance = 0.3
			effects.combat_random(owner_id).seed = 777 + owner_index
			var other_state: int = effects.combat_random(other_id).state
			var streams := [globals.run_random.encounters.state, globals.run_random.drops.state, globals.run_random.upgrades.state]
			var a = contact_enemy(&"alpha", pilot.position, 1000, 46)
			var b = contact_enemy(&"beta", pilot.position, 1000, 46)
			if replay == 1: stage.move_child(b, stage.get_children().find(a))
			await settle()
			var trace: Array = []
			for tick in 16:
				satellites._cooldowns.clear()
				satellites._resolve_contacts()
				trace.append([accepted[-2].target, accepted[-2].hit.is_critical(), accepted[-1].target, accepted[-1].hit.is_critical()])
				check(accepted[-2].target == &"alpha" and accepted[-1].target == &"beta", "surface/group ordering is stable regardless of insertion order")
			traces.append(trace)
			check(effects.combat_random(other_id).state == other_state and streams == [globals.run_random.encounters.state, globals.run_random.drops.state, globals.run_random.upgrades.state], "satellite criticals consume only their owner's combat stream")
		check(traces[0] == traces[1], "each owner's replay retains identical ordered critical traces")

func boss_and_rejections() -> void:
	await reset_case()
	var satellites = await equip(p1, 3)
	p1.loadout.critical_chance = 1
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"satellite_boss"
	boss.configure_spawn(context)
	boss.position = p1.position
	stage.add_child(boss)
	boss.set_physics_process(false)
	for surface in [boss, boss.get_node("PortCannon"), boss.get_node("StarboardCannon"), boss.get_node("Armor")]:
		if surface != boss: surface.position = Vector2.ZERO
		surface.collision_mask = 0
		var circle := CircleShape2D.new()
		circle.radius = 46
		for shape in surface.get_children():
			if shape is CollisionShape2D: shape.shape = circle
	await settle()
	var initial_rng: int = effects.combat_random(&"player1").state
	satellites._resolve_contacts()
	check(accepted.is_empty() and satellites._cooldowns.is_empty() and effects.combat_random(&"player1").state == initial_rng, "entering boss surfaces and armor consume no critical roll or cooldown")
	boss.attack = boss.Attack.IDLE
	var total: float = boss.life + boss.get_node("PortCannon").life + boss.get_node("StarboardCannon").life
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.state = initial_rng
	expected_rng.randf()
	satellites._resolve_contacts()
	check(accepted.size() == 1 and satellites._cooldowns.size() == 1 and effects.combat_random(&"player1").state == expected_rng.state, "all overlapping boss parts share one contact cooldown and one critical roll")
	check(is_equal_approx(boss.life + boss.get_node("PortCannon").life + boss.get_node("StarboardCannon").life, total - 3), "the logical boss receives exactly one direct critical amount")
	for retry in 3: satellites._resolve_contacts()
	check(accepted.size() == 1, "another orbiter or boss part cannot multiply the same tick")
	boss.free()

func proc_and_projectile_rules() -> void:
	await reset_case()
	var satellites = await equip(p1, 1)
	var at: Vector2 = satellites._orbiters[0].global_position
	var target = contact_enemy(&"proc_origin", at, 100, 5)
	var next = contact_enemy(&"proc_next", at + Vector2(40, -30), 100, 5)
	for index in 3: p1.loadout.apply_foundation(&"energy_chains")
	p1.loadout.acquired_ranks[&"piercing"] = 3
	p1.loadout.acquired_ranks[&"ricochet"] = 3
	await settle()
	satellites._resolve_contacts()
	check(accepted[0].hit.modifier_rank(&"piercing") == 0 and accepted[0].hit.modifier_rank(&"ricochet") == 0, "satellite snapshots strip piercing and ricochet")
	await settle()
	check(target.life == 99 and next.life == 100 and accepted.size() == 1 and effects._chain_cooldowns.is_empty() and get_nodes_in_group(&"energy_chain").is_empty(), "satellite contact cannot inherit cannon chains or consume their cooldown")
	var bullet = ProjectilePool.spawn(load("res://scenes/combat/mother_ship_shot.tscn"), at, stage)
	bullet.set_physics_process(false)
	await settle()
	check(not bullet.get_meta("pooled", false) and not bullet.trowbackByShield, "enemy projectiles pass through satellite contacts without interception")
	ProjectilePool.despawn(bullet)
	await reset_case()
	satellites = await equip(p1, 1)
	var victim = contact_enemy(&"credited_kill", satellites._orbiters[0].global_position, 1, 5)
	await settle()
	satellites._resolve_contacts()
	satellites._resolve_contacts()
	check(victim.destroyed and victim.last_player_hit_owner == &"player1" and xp_events == 1, "a satellite kill retains player credit and awards XP exactly once")

func lifecycle() -> void:
	await reset_case()
	var satellites = await equip(p1, 1)
	var other = await equip(p2, 1)
	contact_enemy(&"pause", p1.position, 1000, 46)
	await settle()
	satellites._resolve_contacts()
	var phase: float = satellites.phase
	var spin: float = satellites.spin_phase
	var animation_age: float = satellites.age
	var sprite_frame: int = satellites._orbiters[0].get_child(1).frame
	var sprite_angle: float = satellites._orbiters[0].get_child(1).rotation
	var timer: float = satellites._cooldowns[&"pause"].left
	satellites.set_physics_process(true)
	paused = true
	await process_frame
	await process_frame
	check(satellites.phase == phase and satellites.spin_phase == spin and satellites.age == animation_age and satellites._orbiters[0].get_child(1).frame == sprite_frame and satellites._orbiters[0].get_child(1).rotation == sprite_angle and satellites._cooldowns[&"pause"].left == timer, "selection pause freezes orbit, independent spin, animation and all contact cooldowns")
	paused = false
	satellites.set_physics_process(false)
	p1.reset_weapon_input()
	check(p1.weapons.satellites == satellites, "resetting held input cannot remove the satellite build")
	var orb: Area2D = satellites._orbiters[0]
	orb.area_entered.connect(func(_area): p1.set_state(p1.State.DYING))
	var death_target = contact_enemy(&"death_callback", orb.global_position + Vector2(0, -40), 100, 2)
	await settle()
	death_target.position = orb.global_position
	await settle()
	check(p1.weapons.satellites == null and not is_instance_valid(satellites) and is_instance_valid(other), "a real area callback disables/removes only the dying owner's contacts without physics flush errors")
	await reset_case()
	var baseline := get_node_count()
	for cycle in 3:
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		for player in world.progression.players: player.set_physics_process(false)
		if cycle != 1: world.progression.players[0].apply_upgrade(UPGRADE)
		world.free()
		await settle()
		check(get_node_count() == baseline and get_nodes_in_group(&"orbiting_satellites").is_empty(), "world teardown cancels even pending deferred satellite construction")

func native_presentation() -> void:
	await reset_case()
	var imported: Image = load("res://assets/sprites/player/weapons/orbiting_satellites_sheet.png").get_image()
	var authored := Image.new()
	var decoded := authored.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/sprites/player/weapons/orbiting_satellites_sheet.png"))
	imported.convert(Image.FORMAT_RGBA8)
	authored.convert(Image.FORMAT_RGBA8)
	var matches := decoded == OK and imported.get_size() == authored.get_size()
	if matches:
		for y in authored.get_height():
			for x in authored.get_width():
				var original := authored.get_pixel(x, y)
				var cached := imported.get_pixel(x, y)
				if (original.a > 0.0 or cached.a > 0.0) and original != cached:
					matches = false
	check(matches, "native presentation uses the current exported satellite pixels rather than a stale texture import")
	stage.hide()
	for layout in ["solo", "coop", "wide"]:
		root.size = Vector2i(960 if layout == "wide" else 640, 400)
		globals.coop = layout != "solo"
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var previous := stage
		stage = world
		var players: Array = world.progression.players
		var side_width := maxf((root.size.x - 640.0) * 0.5, 0)
		for index in players.size():
			var player = players[index]
			player.position = Vector2((220 if index == 0 else 420) + side_width, 290)
			player.set_physics_process(false)
			await equip(player, 3)
		var hunter = load("res://scenes/enemies/drone_hunter.tscn").instantiate()
		hunter.definition = hunter.definition.duplicate()
		hunter.definition.max_health = 100
		var context := EnemySpawnContext.new()
		context.combat_id = &"native_hunter"
		hunter.configure_spawn(context)
		hunter.position = players[0].position + Vector2(-32, -52)
		stage.add_child(hunter)
		hunter.set_physics_process(false)
		hunter.collision_mask = 0
		hunter._movement_profile = MovementProfile.new()
		hunter.speedX = 0
		hunter.speedY = 80
		for audio in hunter.find_children("*", "AudioStreamPlayer2D", true, false): audio.stream = null
		stage = previous
		for sample in 15:
			for tick in 4:
				hunter._physics_process(1.0 / 60.0)
				for player in players: player.weapons.satellites._physics_process(1.0 / 60.0)
				await physics_frame
				await process_frame
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://satellites_%s_%d.webp" % [layout, sample]), true) == OK, "native crossing and orbit contact states save")
		check(hunter.life < 100, "a real hunter crosses the orbit and receives contact feedback in the native sequence")
		for player in players: player.weapons.satellites.set_physics_process(false)
		hunter.set_physics_process(false)
		for player in players: player.position = player.STATS.bound_min + Vector2(side_width, 0)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://satellites_edges_%s.webp" % layout), true) == OK, "the fixed nonblocking orbit remains readable at playfield edges")
		var ui = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
		root.add_child(ui)
		var offers := [UPGRADE.offer_snapshot(2), load("res://data/upgrades/escort_drone.tres").offer_snapshot(0), load("res://data/upgrades/critical_hits.tres").offer_snapshot(0)]
		var participants := {}
		for player in players: participants[StringName(player.id_Player)] = {"build": player.loadout.foundation_snapshot(), "offers": offers}
		ui.open(1000, participants, {"level": 4, "xp": 0, "next_threshold": 21})
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://satellites_choices_%s.webp" % layout), true) == OK, "satellite cards and personal build miniatures save")
		ui.free()
		world.free()
		await settle()
	root.size = Vector2i(640, 400)
	globals.coop = true
	stage.show()

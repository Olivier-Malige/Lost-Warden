extends "res://tests/player/test_defensive_pack.gd"

const UPGRADE: UpgradeDefinition = preload("res://data/upgrades/guard_blades.tres")

func blades(player: Node, value: int) -> Variant:
	for level in value: check(player.apply_upgrade(UPGRADE).applied, "guard blade ranks acquire through ordinary offensive eligibility")
	var controller = player.weapons.guard_blades
	controller.set_physics_process(false)
	return controller

func polar(origin: Vector2, angle: float, radius: float) -> Vector2:
	return origin + Vector2.from_angle(deg_to_rad(angle)) * radius

func run() -> void:
	setup_stage()
	check(UPGRADE.foundation_errors().is_empty() and UPGRADE.effect == 21 and UPGRADE.category == UpgradeDefinition.Category.OFFENSIVE, "the appended guard definition validates without shifting existing ordinals")
	for field in ["sweep_inner_radius", "sweep_width_degrees", "sweep_motion_duration", "sweep_duration", "sweep_visual_duration", "sweep_warning_duration"]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		invalid.set(field, NAN)
		check(not invalid.foundation_errors().is_empty(), "nonfinite guard geometry and durations are rejected")
	var invalid_angle := UPGRADE.duplicate() as UpgradeDefinition
	invalid_angle.sweep_end_angles = Vector2(90, -110)
	check(not invalid_angle.foundation_errors().is_empty(), "authored sweep sectors cannot extend behind the player")
	for warning in [0.0, -0.1, INF, 1.2]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		invalid.sweep_warning_duration = warning
		check(not invalid.foundation_errors().is_empty(), "warnings must be finite, positive and fit between salvos")
	for motion in [0.0, -0.1, INF, UPGRADE.sweep_duration, UPGRADE.sweep_duration + 0.01]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		invalid.sweep_motion_duration = motion
		check(not invalid.foundation_errors().is_empty(), "motion must leave a positive active hold after convergence")
	for value in range(1, 4):
		await reset_case()
		var controller = blades(p1, value)
		var victims: Array[Area2D] = []
		for angle in [-170.0, -140.0, -110.0, -90.0, -50.0, -10.0]: victims.append(target(StringName("guard_%d" % victims.size()), polar(p1.position, angle, 32), 2))
		for angle in [-150.0, -90.0, -30.0]: victims.append(target(StringName("extended_%d" % victims.size()), polar(p1.position, angle, 54), 2))
		for angle in [-150.0, -90.0, -30.0]: victims.append(target(StringName("rank_reach_%d" % victims.size()), polar(p1.position, angle, UPGRADE.range_value(value) - 4), 1))
		var next_rank_reach := target(&"next_rank_reach", polar(p1.position, -90, UPGRADE.range_value(value) + 6), 1)
		var edge_shot := hostile(polar(p1.position, -50, UPGRADE.range_value(value) - 4))
		var rear := target(&"rear", p1.position + Vector2(0, 30))
		var inner := target(&"inner", p1.position + Vector2(0, -8))
		var far := target(&"far", p1.position + Vector2(0, -UPGRADE.range_value(value) - 6))
		await settle()
		controller._physics_process(controller.cooldown_left)
		controller._physics_process(UPGRADE.sweep_motion_duration)
		check(is_zero_approx(controller._sprites[0].rotation) and is_zero_approx(controller._sprites[1].rotation) and not controller._sprites[1].flip_h and controller._hit != null, "both bright arcs overlap exactly before damage and light end, at every rank")
		controller._physics_process(UPGRADE.sweep_duration - UPGRADE.sweep_motion_duration)
		for victim in victims: check(victim.get("life") == 100 - value - 1, "a whole double sweep reaches every covered real hull exactly once at each rank")
		check(rear.get("life") == 100 and inner.get("life") == 100 and far.get("life") == 100, "rear, inner gap and out-of-range enemies remain untouched")
		check(next_rank_reach.get("life") == 100, "a lower rank cannot borrow the next rank's larger reach")
		check(edge_shot.get_meta("pooled", false), "each rank clears hostile shots throughout its larger authored reach")
		check(floori(controller._sprites[0].frame / 20.0) == value - 1, "each salvo selects the native sprite matching its snapshotted rank")
		check(is_zero_approx(controller._sprites[0].rotation) and is_zero_approx(controller._sprites[1].rotation), "both arcs finish aligned screen-up at every rank instead of crossing past one another")
		check(controller._sprites[0].position == controller._sprites[1].position and controller._sprites[0].frame == controller._sprites[1].frame, "the final overlap shares the same center and animation frame")
		check(effects.get_debug_snapshot().roots == 0 and accepted.size() == victims.size(), "both blades release their single shared secondary root at the active boundary")
	await geometry_cases()
	await active_window()
	await merged_hold()
	await projectile_clearing()
	await armor_and_boss()
	await cooldowns_and_ranks()
	await warning_countdown()
	await damage_policy()
	await owner_lifecycle()
	await dense_sweep()
	if DisplayServer.get_name() != "headless":
		await native_guard_presentation()
		await native_guard_menus()
	effects.cancel()
	stage.free()
	await settle()
	print("Guard blades: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func geometry_cases() -> void:
	await reset_case()
	var controller = blades(p1, 1)
	var partial := target(&"partial", p1.position + Vector2(0, -UPGRADE.range_value(1) - 3), 4)
	var outside := target(&"outside", p1.position + Vector2(0, -UPGRADE.range_value(1) - 1), 0.5)
	var offset := target(&"offset", p1.position + Vector2(80, 0))
	var collider := offset.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8, 12)
	collider.shape = rectangle
	collider.position = Vector2(-80, -35)
	collider.rotation = PI / 4
	await settle()
	controller._physics_process(controller.cooldown_left)
	controller._physics_process(0.28)
	check(partial.get("life") == 98 and outside.get("life") == 100, "partial real hull coverage counts while a wholly external hull does not")
	check(offset.get("life") == 98, "offset rotated collision geometry is queried independently of the actor center")
	await reset_case()
	controller = blades(p1, 1)
	var crossed := target(&"crossed", p1.position + Vector2(24, -32))
	var behind := target(&"behind_motion", p1.position + Vector2(24, 28))
	await settle()
	controller._physics_process(controller.cooldown_left)
	p1.position.x += 48
	await settle()
	controller._physics_process(0.28)
	check(crossed.get("life") == 98 and behind.get("life") == 100, "the traveled blade follows a translating player without covering the rear")
	check(controller.global_position == p1.global_position and controller.global_rotation == 0, "the two blades stay centered and face screen-up")

func active_window() -> void:
	await reset_case()
	var controller = blades(p1, 1)
	var victim := target(&"double", p1.position + Vector2(0, -32))
	var entering := target(&"entering", p1.position + Vector2(90, 0))
	await settle()
	controller._physics_process(controller.cooldown_left)
	controller._physics_process(0.21)
	check(victim.get("life") == 98 and accepted.size() == 1, "two overlapping blades produce one accepted impact per salvo")
	victim.position.x += 100
	await settle()
	victim.position = p1.position + Vector2(0, -32)
	entering.position = p1.position + Vector2(8, -30)
	await settle()
	controller._physics_process(0.04)
	check(victim.get("life") == 98 and entering.get("life") == 98, "reentry is deduplicated and entering during the active sweep is dangerous")
	controller._physics_process(0.04)
	var late := target(&"late", p1.position + Vector2(0, -30))
	var late_shot := hostile(p1.position + Vector2(0, -30))
	await settle()
	controller._physics_process(0.05)
	check(late.get("life") == 100 and not late_shot.get_meta("pooled", false), "inactive fragments cannot injure new enemies or clear new shots")
	check(controller._playing and controller._hit == null and controller._sprites[0].frame % 10 >= 7, "the active root ends before the final visual frames")
	controller._physics_process(0.07)
	check(not controller._sprites[0].visible and effects.get_debug_snapshot().roots == 0, "the inactive tail ends without retaining a damage root")

func merged_hold() -> void:
	await reset_case()
	var controller = blades(p1, 1)
	controller._physics_process(controller.cooldown_left)
	controller._physics_process(UPGRADE.sweep_motion_duration)
	var entering := target(&"merged_entry", p1.position + Vector2(0, -32))
	var shot := hostile(p1.position + Vector2(0, -32))
	await settle()
	controller._physics_process(0.04)
	check(entering.get("life") == 98 and shot.get_meta("pooled", false), "the visible merged blade remains active for entering hulls and projectiles")
	controller._physics_process(0.04)
	check(entering.get("life") == 98 and accepted.size() == 1, "the merged hold cannot apply damage twice")
	check(controller._sprites[0].frame == controller._sprites[1].frame and controller._sprites[0].flip_h == controller._sprites[1].flip_h and controller._sprites[0].transform == controller._sprites[1].transform, "the held images share identical texture orientation, frame and transform")
	check(controller._hit != null and controller._sprites[0].frame % 10 < 7, "the held overlap keeps its bright active edge until the cooling phase")

func projectile_clearing() -> void:
	await reset_case()
	var controller = blades(p1, 1)
	var erased: Array[Shot] = []
	for angle in [-170.0, -140.0, -100.0, -90.0, -40.0, -10.0]: erased.append(hostile(polar(p1.position, angle, 32)))
	for angle in [-150.0, -90.0, -30.0]: erased.append(hostile(polar(p1.position, angle, 54)))
	var reflected := hostile(p1.position + Vector2(5, -32))
	reflected.trowbackByShield = true
	reflected.set_reflected_owner(p2)
	var rear := hostile(p1.position + Vector2(0, 30))
	var ally: Shot = ProjectilePool.spawn(load("res://scenes/player/player_shot.tscn"), p1.position + Vector2(0, -32), stage)
	ally.set_physics_process(false)
	var beam = load("res://scenes/bosses/dread_ark_beam.gd").new()
	stage.add_child(beam)
	beam.set_physics_process(false)
	await settle()
	controller._physics_process(controller.cooldown_left)
	controller._physics_process(0.28)
	for shot in erased: check(shot.get_meta("pooled", false), "each hostile projectile reached during the sweep returns safely to the pool")
	check(not reflected.get_meta("pooled", false) and reflected.reflected_owner_id == &"player2", "the partner's reflected projectile survives a blade sweep")
	check(not rear.get_meta("pooled", false) and not ally.get_meta("pooled", false) and is_instance_valid(beam), "rear shots, friendly fire and continuous beams are preserved")
	await settle()
	var reused := hostile(p1.position + Vector2(90, 0))
	check(not reused.get_meta("pooled", false) and not reused.trowbackByShield, "cleared projectiles can be reused with clean pool state")

func armor_and_boss() -> void:
	await reset_case()
	var controller = blades(p1, 1)
	var wall := ArmorWall.new()
	wall.collision_layer = CombatTargeting.Layers.ENEMY
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(48, 3)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = p1.position + Vector2(0, -20)
	stage.add_child(wall)
	var blocked := target(&"behind_armor", p1.position + Vector2(0, -33))
	var blocked_shot := hostile(p1.position + Vector2(5, -33))
	await settle()
	controller._physics_process(controller.cooldown_left)
	controller._physics_process(0.28)
	check(blocked.get("life") == 100 and not blocked_shot.get_meta("pooled", false), "explicit armor occludes damage and hostile-shot clearing")
	await reset_case()
	controller = blades(p1, 1)
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"guard_boss"
	boss.configure_spawn(context)
	boss.position = p1.position + Vector2(0, -30)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	for surface in [boss, boss.get_node("PortCannon"), boss.get_node("StarboardCannon")]:
		if surface != boss: surface.position = Vector2.ZERO
		surface.collision_mask = 0
		for child in surface.get_children():
			if child is CollisionShape2D:
				var circle := CircleShape2D.new()
				circle.radius = 3
				child.shape = circle
	boss.get_node("Armor").position.x -= 160
	await settle()
	var before: float = boss.life + boss.get_node("PortCannon").life + boss.get_node("StarboardCannon").life
	controller._physics_process(controller.cooldown_left)
	controller._physics_process(0.28)
	check(is_equal_approx(before - 2, boss.life + boss.get_node("PortCannon").life + boss.get_node("StarboardCannon").life) and accepted.size() == 1, "both blades and all boss parts share one accepted salvo impact")
	await reset_case()
	controller = blades(p1, 1)
	var asteroid = load("res://scenes/enemies/asteroid.tscn").instantiate()
	var asteroid_context := EnemySpawnContext.new()
	asteroid_context.combat_id = &"guard_asteroid"
	asteroid.configure_spawn(asteroid_context)
	asteroid.position = p1.position + Vector2(0, -32)
	stage.add_child(asteroid)
	asteroid.set_physics_process(false)
	asteroid.collision_mask = 0
	var life_before: float = asteroid.life
	await settle()
	controller._physics_process(controller.cooldown_left)
	controller._physics_process(0.28)
	check(asteroid.life == life_before - 2, "a destructible asteroid takes one real accepted guard impact")

func cooldowns_and_ranks() -> void:
	for value in range(1, 4):
		await reset_case()
		var rank_controller = blades(p1, value)
		rank_controller._physics_process(rank_controller.cooldown_left)
		check(rank_controller.salvo_count == 1 and rank_controller.cooldown_left == UPGRADE.interval_value(value), "the first salvo starts after its warning even without targets")
		rank_controller._physics_process(UPGRADE.interval_value(value) - 0.01)
		check(rank_controller.salvo_count == 1, "the start-to-start interval does not fire early")
		rank_controller._physics_process(0.02)
		check(rank_controller.salvo_count == 2, "the next salvo starts at the authored rank interval without needing a target")
		rank_controller._physics_process(60)
		check(rank_controller.salvo_count == 3, "a long tick never queues a backlog of missed salvos")
	await reset_case()
	paused = true
	var controller = blades(p1, 1)
	controller._physics_process(9)
	check(controller.salvo_count == 0, "acquiring during selection cannot emit until gameplay resumes")
	paused = false
	controller._physics_process(controller.cooldown_left)
	controller._physics_process(0.1)
	var victim := target(&"rank_snapshot", p1.position + Vector2(0, -32))
	var extended := target(&"rank_extended", p1.position + Vector2(0, -66), 1)
	p1.apply_upgrade(UPGRADE)
	check(is_equal_approx(controller.cooldown_left, 2.9 / 3 * 2), "ranking preserves the remaining cooldown percentage")
	await settle()
	controller._physics_process(0.18)
	check(victim.get("life") == 98 and controller._salvo_rank == 1, "an ongoing salvo retains its original damage when rank changes")
	check(extended.get("life") == 100 and controller._sprites[0].frame < 20, "an ongoing salvo retains its smaller hitbox and native sprite after ranking")
	var state: Dictionary = controller.snapshot()
	paused = true
	controller._physics_process(50)
	check(controller.snapshot() == state, "pause freezes visual age, cooldown and salvo count")
	paused = false
	controller._physics_process(controller.cooldown_left + 0.001)
	controller._physics_process(0.28)
	check(victim.get("life") == 95 and controller._salvo_rank == 2, "the next salvo uses the upgraded damage")
	check(extended.get("life") == 97 and controller._sprites[0].frame >= 20, "the next salvo uses the upgraded reach and native sprite together")

func damage_policy() -> void:
	for other in [&"impact_explosions", &"energy_chains"]:
		await reset_case()
		var controller = blades(p1, 1)
		p1.apply_upgrade(load("res://data/upgrades/critical_hits.tres"))
		p1.apply_upgrade(load("res://data/upgrades/%s.tres" % other))
		for level in 5:
			p1.loadout.apply_foundation(&"damage")
			p1.loadout.apply_foundation(&"fire_rate")
		p1.loadout.critical_chance = 1
		var victim := target(&"policy", p1.position + Vector2(0, -32))
		var random_state: int = globals.run_random.combat_for(&"player1").state
		await settle()
		controller._physics_process(controller.cooldown_left)
		controller._physics_process(0.28)
		check(victim.get("life") == 95.5, "common DAMAGE applies once without a critical multiplier")
		check(controller.interval == 3 and is_equal_approx(controller.cooldown_left, 2.72), "FIRE_RATE never changes blade cadence")
		check(accepted.size() == 1 and accepted[0].hit.kind() == PlayerHitSnapshot.Kind.SECONDARY and not accepted[0].first and not accepted[0].hit.is_critical(), "guard impacts remain secondary with no first-hit proc opportunity")
		check(effects._chain_cooldowns.is_empty() and effects._explosion_cooldowns.is_empty() and globals.run_random.combat_for(&"player1").state == random_state, "blades neither trigger combat effects nor consume critical RNG")
		check(not p1.apply_upgrade(load("res://data/upgrades/side_shot.tres")).applied, "guard blades occupy an ordinary offensive slot and reject a fourth family")
		p1.debug_max_stats()
		check(p1.loadout.foundation_snapshot().offensive_count == 3 and p1.loadout.foundation_snapshot().utility_count == 3, "debug maximum still respects both existing build capacities")

func warning_countdown() -> void:
	await reset_case()
	var controller = blades(p1, 1)
	var victim := target(&"warning_hull", polar(p1.position, -150, 32))
	var shot := hostile(polar(p1.position, -150, 32))
	await settle()
	check(controller.snapshot().warning and is_equal_approx(controller.cooldown_left, 0.6) and controller.salvo_count == 0, "acquisition shows a brief warning bar before the first attack")
	controller._physics_process(0.3)
	check(controller.snapshot().warning and is_equal_approx(controller.cooldown_left, 0.3) and victim.get("life") == 100 and not shot.get_meta("pooled", false), "the bar fills without damaging hulls or clearing shots")
	var state: Dictionary = controller.snapshot()
	paused = true
	controller._physics_process(5)
	check(controller.snapshot() == state, "pause freezes the bar alongside attack timers")
	paused = false
	p1.apply_upgrade(UPGRADE)
	check(is_equal_approx(controller.cooldown_left, 0.3), "ranking during first anticipation preserves its remaining warning time")
	controller._physics_process(0.29)
	check(controller.salvo_count == 0 and controller.snapshot().warning and is_equal_approx(controller.cooldown_left, 0.01), "the first salvo cannot start before the warning bar fills")
	controller._physics_process(0.011)
	check(controller.salvo_count == 1 and not controller.snapshot().warning and controller._salvo_rank == 2, "the attack replaces its warning bar and uses the current rank")
	controller._physics_process(0.4)
	controller._physics_process(controller.cooldown_left - UPGRADE.sweep_warning_duration + 0.001)
	check(controller.snapshot().warning and controller.salvo_count == 1 and not controller._playing, "the next bar only appears in the final warning window")
	var remaining: float = controller.cooldown_left
	p1.apply_upgrade(UPGRADE)
	check(is_equal_approx(controller.cooldown_left, remaining / 2 * 1.5) and controller.snapshot().warning, "ranking during a recurring warning preserves the interval's remaining percentage")
	controller._physics_process(controller.cooldown_left)
	check(controller.salvo_count == 2 and controller.interval == 1.5 and not controller.snapshot().warning, "the bar fits inside the shorter cadence without adding a warning delay")

func owner_lifecycle() -> void:
	await reset_case()
	p2.position = p1.position
	var left = blades(p1, 1)
	var right = blades(p2, 3)
	var victim := target(&"cooperative", p1.position + Vector2(0, -32))
	var shot := hostile(p1.position + Vector2(0, -30))
	await settle()
	left._physics_process(left.cooldown_left)
	right._physics_process(right.cooldown_left)
	left._physics_process(0.28)
	right._physics_process(0.28)
	check(victim.get("life") == 94 and accepted.size() == 2 and shot.get_meta("pooled", false), "overlapping co-op blades damage independently and clear a projectile safely once")
	check(left.interval == 3 and right.interval == 1.5 and left._sprites[0].frame < 10 and right._sprites[0].frame >= 10, "owners keep their own interval and team visuals")
	left._physics_process(1)
	check(right.age == 0.28, "advancing one owner's clock cannot advance its partner")
	await reset_case()
	var controller = blades(p1, 1)
	target(&"death_first", p1.position + Vector2(0, -30))
	var survivor := target(&"death_second", p1.position + Vector2(0, -36))
	await settle()
	effects.hit_accepted.connect(func(_hit, _id, _at, _first): p1.set_state(p1.State.DYING), CONNECT_ONE_SHOT)
	controller._physics_process(controller.cooldown_left)
	controller._physics_process(0.28)
	check(survivor.get("life") == 100 and effects.get_debug_snapshot().roots == 0 and controller._stopped, "owner death during an accepted hit cancels the rest of the sweep and releases its root")
	await settle()
	check(get_nodes_in_group(&"guard_blades").is_empty(), "death frees the controller and its visuals")
	await reset_case()
	var baseline := get_node_count()
	for cycle in 3:
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var player = world.progression.players[0]
		player.apply_upgrade(UPGRADE)
		if cycle != 1: player.weapons.guard_blades._physics_process(player.weapons.guard_blades.cooldown_left)
		world.free()
		await settle()
		check(get_node_count() == baseline and get_nodes_in_group(&"guard_blades").is_empty(), "active and pending first salvos do not leak nodes across world restarts")

func native_guard_presentation() -> void:
	await reset_case()
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(640, 400)
	RenderingServer.set_default_clear_color(Color("101522"))
	p1.position = Vector2(220, 265)
	p2.position = Vector2(420, 265)
	var left = blades(p1, 1)
	var right = blades(p2, 3)
	var labels: Array[Label] = []
	var victims: Array[Area2D] = []
	for index in 2:
		var player = p1 if index == 0 else p2
		victims.append(target(StringName("native_guard_%d" % index), player.position + Vector2(0, -UPGRADE.range_value(1 if index == 0 else 3) + 6), 4))
		var label := Label.new()
		label.position = player.position + Vector2(-60, -105)
		stage.add_child(label)
		labels.append(label)
		for angle in [-150.0, -90.0, -30.0]: hostile(polar(player.position, angle, 54))
	await settle()
	await RenderingServer.frame_post_draw
	capture("guard_blades_warning_06")
	left._physics_process(0.3)
	right._physics_process(0.3)
	await RenderingServer.frame_post_draw
	capture("guard_blades_warning_03")
	left._physics_process(left.cooldown_left)
	right._physics_process(right.cooldown_left)
	for frame in 10:
		if frame > 0:
			left._physics_process(0.04)
			right._physics_process(0.04)
		for index in 2: labels[index].text = "TARGET HP %d / 100" % victims[index].get("life")
		await RenderingServer.frame_post_draw
		capture("guard_blades_native_%02d" % frame)
	check(victims[0].get("life") == 98 and victims[1].get("life") == 96, "native dual-color sweep captures expose measured per-rank target HP")

func dense_sweep() -> void:
	await reset_case()
	var controller = blades(p1, 3)
	var victims: Array[Area2D] = []
	var shots: Array[Shot] = []
	for index in 24:
		var angle := -172.0 + (index % 8) * 23
		var point := polar(p1.position, angle, 23 + floori(index / 8.0) * 8)
		victims.append(target(StringName("dense_%d" % index), point, 1.5))
		shots.append(hostile(point + Vector2(0, -1)))
	await settle()
	controller._physics_process(controller.cooldown_left)
	var timings: Array[int] = []
	for frame in 18:
		var started := Time.get_ticks_usec()
		controller._physics_process(0.0 if frame == 0 else 1.0 / 60)
		timings.append(Time.get_ticks_usec() - started)
	for victim in victims: check(victim.get("life") == 96, "dense native geometry has no victim cap or repeated damage")
	for shot in shots: check(shot.get_meta("pooled", false), "dense clearing does not leave covered hostile projectiles behind")
	timings.sort()
	print("Guard dense sweep: 24 hulls + 24 shots, median %dus, max %dus per active step" % [timings[floori(timings.size() * 0.5)], timings.back()])
	check(effects.get_debug_snapshot().roots == 0 and get_nodes_in_group(&"guard_blades").size() == 1, "dense combat remains bounded to one controller and no inactive damage roots")

func native_guard_menus() -> void:
	stage.hide()
	for layout in ["solo", "coop", "wide"]:
		globals.coop = layout != "solo"
		root.size = Vector2i(960 if layout == "wide" else 640, 400)
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var players: Array = world.progression.players
		for player in players:
			player.set_physics_process(false)
			for level in 2: player.apply_upgrade(UPGRADE)
			for data in [SHIELD, ARMOR, RIPOSTE]: equip(player, data, 2)
			player.weapons.guard_blades.set_physics_process(false)
			player.defenses.set_physics_process(false)
			player.weapons.guard_blades._physics_process(player.weapons.guard_blades.cooldown_left)
			player.weapons.guard_blades._physics_process(0.18)
		await RenderingServer.frame_post_draw
		capture("guard_blades_%s_hud" % layout)
		var menu = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
		root.add_child(menu)
		var participants := {}
		for player in players:
			participants[StringName(player.id_Player)] = {"build": player.loadout.foundation_snapshot(), "offers": [UPGRADE.offer_snapshot(2), SHIELD.offer_snapshot(2), ARMOR.offer_snapshot(2)]}
		menu.open(1400, participants, {"level": 4, "xp": 0, "next_threshold": 21})
		check(menu._effect_lines(UPGRADE.offer_snapshot(1)).contains("REACH +20%") and menu._effect_lines(UPGRADE.offer_snapshot(2)).contains("REACH +40%"), "upgrade cards expose the authored reach growth as percentages")
		await create_timer(0.6).timeout
		for panel in menu._panels.values():
			check(panel.find_children("BuildSlot*", "Panel", false, false).size() == 6, "native guard menus preserve three offensive and three utility slots")
			var card: Button = panel.get_meta("cards")[0]
			check(card.get_node("Icon").texture.region.position.x == 19 * 64, "the new guard card selects the appended team illustration")
		await RenderingServer.frame_post_draw
		capture("guard_blades_%s_choices" % layout)
		menu.free()
		world.free()
		await settle()
	root.size = Vector2i(640, 400)
	globals.coop = true
	stage.show()

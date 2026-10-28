extends "res://tests/player/test_player_hit_contract.gd"

const SHIELD: UpgradeDefinition = preload("res://data/upgrades/foundation/shield.tres")
const ARMOR: UpgradeDefinition = preload("res://data/upgrades/reactive_armor.tres")
const RIPOSTE: UpgradeDefinition = preload("res://data/upgrades/retaliation_pulse.tres")

class ArmorWall extends Area2D:
	var armored := true

func reset_case() -> void:
	effects.cancel()
	for child in stage.get_children():
		if child not in [pool, effects]: child.free()
	await settle()
	for index in 2:
		var player = load("res://scenes/player/player.tscn").instantiate()
		player.set_Player_2 = index == 1
		stage.add_child(player)
		player.position = Vector2(220 if index == 0 else 450, 250)
		player.set_physics_process(false)
		player.set_process(false)
		player.defenses.set_physics_process(false)
		player.collision_mask = 0
		player.monitorable = false
		player.energy = 12
		for kind in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
			for audio in player.find_children("*", kind, true, false): audio.stream = null
		if index == 0: p1 = player
		else: p2 = player
	effects.start([p1, p2], globals.run_random)
	accepted.clear()
	xp_events = 0

func equip(player: Node, data: UpgradeDefinition, value: int) -> void:
	for level in value: check(player.apply_upgrade(data).applied, "defensive ranks acquire through the live catalog and ordinary slots")

func hostile(at: Vector2) -> Shot:
	var shot: Shot = ProjectilePool.spawn(load("res://scenes/combat/mother_ship_shot.tscn"), at, stage)
	shot.set_physics_process(false)
	shot.speedX = 30
	shot.speedY = 275
	return shot

func target(id: StringName, at: Vector2, radius := 2.0) -> Area2D:
	var body: Area2D = enemy(id, at, 100)
	body.collision_mask = 0
	var shape := CircleShape2D.new()
	shape.radius = radius
	body.get_node("CollisionShape2D").shape = shape
	return body

func pulse_now() -> Node2D:
	p1.defenses._spawn_pulse()
	var pulse: Node2D = p1.defenses._pulses.back().get_ref()
	pulse.set_physics_process(false)
	return pulse

func contact_hit(player: Node) -> void:
	player.defenses.take_hit(1, false, true)

func setup_stage() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = true
	globals.reset_run(522)
	root.size = Vector2i(640, 400)
	stage = Node2D.new()
	root.add_child(stage)
	pool = ProjectilePool.new()
	stage.add_child(pool)
	effects = PlayerHitEffects.new()
	effects.name = "PlayerHitEffects"
	stage.add_child(effects)
	effects.hit_accepted.connect(func(hit, id, at, first): accepted.append({"hit": hit, "target": id, "position": at, "first": first}))

func run() -> void:
	setup_stage()
	await reset_case()
	for data in [SHIELD, ARMOR, RIPOSTE]: check(data.foundation_errors().is_empty() and data.category == UpgradeDefinition.Category.UTILITY and not data.repeatable, "all defensive definitions are valid three-rank utility families")
	for field in ["shield_radius"]:
		var bad_geometry := SHIELD.duplicate() as UpgradeDefinition
		bad_geometry.set(field, NAN)
		check(not bad_geometry.foundation_errors().is_empty(), "invalid defensive geometry or cadence is rejected")
	var invalid := SHIELD.duplicate() as UpgradeDefinition
	invalid.recharge_values = PackedFloat32Array([8, 0, 4])
	check(not invalid.foundation_errors().is_empty(), "invalid recharge durations are rejected")
	for value in range(1, 4): await projectile_capacity(value)
	await rank_changes()
	await ownership_and_pooling()
	await real_callbacks()
	await body_contacts()
	await beam_contacts()
	await countermeasure_protection()
	await countermeasure_contacts()
	await countermeasure_ranks()
	for value in range(1, 4): await reactive_armor(value)
	for value in range(1, 4): await pulse_damage(value)
	await pulse_timing_and_armor()
	await boss_exclusion()
	await saturation_and_pending()
	await independent_pulses()
	await death_during_acceptance()
	await lifecycle()
	if DisplayServer.get_name() != "headless": await native_presentation()
	effects.cancel()
	stage.free()
	await settle()
	print("Defensive pack: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func projectile_capacity(value: int) -> void:
	await reset_case()
	equip(p1, SHIELD, value)
	var guard = p1.defenses
	var capacity: int = [3, 5, 7][value - 1]
	check(guard.maximum == capacity and guard.charges == capacity and p1.shield.position == Vector2.ZERO, "the sphere starts centered with the authored capacity")
	for impact in capacity:
		var shot := hostile(p1.position + Vector2(0, -18))
		await settle()
		var speed := Vector2(shot.speedX, shot.speedY)
		check(guard.intercept_projectile(shot) and shot.trowbackByShield and Vector2(shot.speedX, shot.speedY) == -speed, "an actual sphere overlap reverses both velocity components")
		check(guard.charges == capacity - impact - 1 and shot.reflected_owner_id == &"player1", "each distinct projectile consumes exactly one owned charge")
		guard.intercept_projectile(shot)
		check(guard.charges == capacity - impact - 1 and shot.speedY == -275, "duplicate interception cannot reverse or charge the same projectile twice")
		ProjectilePool.despawn(shot)
		await settle()
	check(guard.charges == 0 and guard.recharge_left == [8.0, 6.0, 4.0][value - 1] and p1.energy == 12, "the last charge fully absorbs its impact and starts full recharge")
	var excess := hostile(p1.position)
	await settle()
	excess._on_shot_area_entered(p1)
	check(p1.energy == 11 and excess.get_meta("pooled", false), "an excess projectile reaches the hull while the sphere is down")
	var duration: float = guard.recharge_duration
	guard._physics_process(duration - 0.01)
	check(guard.charges == 0, "charges do not refill before the full recharge boundary")
	guard._physics_process(0.02)
	check(guard.charges == capacity and guard.recharge_left == 0, "depleted charges regenerate together automatically")
	var outside := hostile(p1.position + Vector2(70, 0))
	await settle()
	check(not guard.intercept_projectile(outside) and guard.charges == capacity, "owning charges alone grants no global projectile immunity")
	ProjectilePool.despawn(outside)

func rank_changes() -> void:
	await reset_case()
	equip(p1, SHIELD, 1)
	p1.defenses.take_hit()
	equip(p1, SHIELD, 1)
	check(p1.defenses.maximum == 5 and p1.defenses.charges == 4, "ranking adds new capacity without restoring a spent charge")
	for impact in 4: p1.defenses.take_hit()
	p1.defenses._physics_process(3)
	equip(p1, SHIELD, 1)
	check(p1.defenses.maximum == 7 and p1.defenses.charges == 0 and is_equal_approx(p1.defenses.recharge_left, 2), "ranking during recharge preserves its completed percentage")
	equip(p1, ARMOR, 1)
	equip(p1, RIPOSTE, 1)
	check(p1.loadout.foundation_snapshot().utility_count == 3 and not p1.apply_upgrade(load("res://data/upgrades/foundation/speed.tres")).applied, "the whole pack occupies exactly the existing three utility slots")
	p1.debug_max_stats()
	check(p1.defenses.charges == 0 and p1.loadout.foundation_snapshot().utility_count == 3, "debug maximum cannot grant free reflector charges or extra utility slots")

func ownership_and_pooling() -> void:
	await reset_case()
	p2.position = p1.position
	equip(p1, SHIELD, 1)
	equip(p2, SHIELD, 1)
	var shot := hostile(p1.position + Vector2(0, -18))
	await settle()
	check(p1.defenses.intercept_projectile(shot) and p2.defenses.intercept_projectile(shot) and p1.defenses.charges == 2 and p2.defenses.charges == 3 and shot.reflected_owner_id == &"player1", "overlapping owners cannot steal or double-charge a reflected shot")
	var victim: Area2D = target(&"reflected_victim", p1.position + Vector2(0, -70), 8)
	var damage: int = shot.get("damage")
	shot.position = victim.position
	await settle()
	check(victim.get("life") == 100 - damage and victim.get("last_player_hit_owner") == &"player1" and accepted.back().hit.kind() == PlayerHitSnapshot.Kind.REFLECTED and not accepted.back().first, "a reflected shot retains original damage and credits its owner without procs")
	var reused := hostile(p1.position + Vector2(70, 0))
	check(reused == shot and not reused.trowbackByShield and reused.reflected_owner_id == &"" and reused.get("hit_snapshot") == null, "pool reuse clears reflection ownership, snapshot and direction")
	ProjectilePool.despawn(reused)
	check(effects.get_debug_snapshot().roots == 0, "reflected roots release after recycling")

func real_callbacks() -> void:
	await reset_case()
	p1.monitorable = true
	p1.collision_mask = CombatTargeting.Layers.ENEMY_SHOT
	p2.position = p1.position
	equip(p2, SHIELD, 1)
	var shot := hostile(p1.position)
	await settle()
	check(p1.energy == 12 and p2.energy == 12 and shot.trowbackByShield and shot.reflected_owner_id == &"player2" and p2.defenses.charges == 2, "an actual hull callback lets a covering co-op sphere intercept before either player takes damage")
	ProjectilePool.despawn(shot)
	await settle()
	await reset_case()
	equip(p1, SHIELD, 1)
	p1.collision_mask = CombatTargeting.Layers.ENEMY | CombatTargeting.Layers.ENEMY_SHOT
	p1.monitorable = true
	p1.defenses.set_physics_process(true)
	var shots: Array[Shot] = []
	for index in 5: shots.append(hostile(p1.position + Vector2(index % 3 - 1, 0)))
	await settle()
	p1.defenses.set_physics_process(false)
	check(shots.filter(func(item: Shot): return item.trowbackByShield).size() == 3 and p1.energy == 11 and p1.defenses.charges == 0, "simultaneous real callbacks spend exactly three charges and expose the hull to excess fire once")

func body_contacts() -> void:
	await reset_case()
	equip(p1, SHIELD, 1)
	p1.collision_mask = CombatTargeting.Layers.ENEMY | CombatTargeting.Layers.ASTEROID
	var body := target(&"body", p1.position + Vector2(24, 0))
	await settle()
	p1.defenses._physics_process(0)
	check(p1.defenses.charges == 3 and p1.energy == 12, "a near miss through the visual sphere cannot consume charges or harm the hull")
	body.position = p1.position
	await settle()
	p1.defenses._physics_process(0)
	check(p1.defenses.charges == 0 and p1.energy == 11 and body.get("life") == 100, "direct hull contact shatters every reflector charge and remains dangerous")
	p1.defenses._physics_process(1.01)
	check(p1.energy == 10, "continued hull contact retains ordinary injury cadence")
	body.free()
	await settle()
	p1.defenses._physics_process(p1.defenses.recharge_left + 0.01)
	check(p1.defenses.charges == 3, "the reflector fully recharges after body rupture")
	var asteroid = load("res://scenes/enemies/asteroid.tscn").instantiate()
	asteroid.position = p1.position + Vector2(70, 0)
	stage.add_child(asteroid)
	asteroid.set_physics_process(false)
	asteroid.rotation = 0
	asteroid.collision_mask = 0
	asteroid.get_node("CollisionShape2D").position.x = -55
	await settle()
	p1.defenses._physics_process(0)
	check(p1.defenses.charges == 0 and p1.energy == 9, "an offset asteroid hull breaks reflection based on its actual collision shape")
func beam_contacts() -> void:
	await reset_case()
	p1.position = Vector2(320, 300)
	equip(p1, SHIELD, 1)
	var beam = load("res://scenes/bosses/dread_ark_beam.gd").new()
	stage.add_child(beam)
	beam.position = Vector2(320, 100)
	beam.offsets = PackedFloat32Array([0])
	beam.set_physics_process(false)
	beam.fire()
	beam._physics_process(0.01)
	check(p1.defenses.charges == 3 and p1.energy == 11, "continuous beams bypass reflection without spending a projectile charge")
	beam._physics_process(0.34)
	check(p1.energy == 11, "continuous beams retain their existing damage cadence")
	beam._physics_process(0.02)
	check(p1.energy == 10 and p1.defenses.charges == 3 and p2.energy == 12, "later beam ticks remain dangerous despite a charged reflector")
	beam.stop()
func reactive_armor(value: int) -> void:
	await reset_case()
	equip(p1, ARMOR, value)
	p1._hit_something()
	check(p1.energy == 11 and p1.defenses.grace_left == 1 and p1.defenses.repair_left == ARMOR.interval_value(value) and is_equal_approx(p1.touched_reset_timer.wait_time, 1), "armor schedules repair while keeping ordinary one-second injury grace")
	p1.defenses._physics_process(1.01)
	p1._on_touchedReset_timeout()
	check(not p1.touched and p1.malusSpeed == 0 and p1.ship_sprite.modulate == Color.WHITE, "repair armor does not extend ordinary invulnerability or hit feedback")
	p1._hit_something()
	check(p1.energy == 10 and p1.defenses.repair_left == ARMOR.interval_value(value), "another ordinary wound restarts the repair delay")
	p1._hit_by_beam()
	check(p1.energy == 9 and p1.defenses.repair_left == ARMOR.interval_value(value), "continuous beam wounds also restart repair without being absorbed")
	p1.defenses._physics_process(ARMOR.interval_value(value) + 0.01)
	check(p1.energy == 10 and p1.defenses.repair_left == 0 and p1.defenses.repair_flash_left > 0, "the full quiet interval repairs one point once")

func countermeasure_protection() -> void:
	await reset_case()
	equip(p1, RIPOSTE, 1)
	var guard = p1.defenses
	p1.energy = 1
	p1.vitals.hit(0)
	check(guard.pulse_cooldown == 0 and not guard._pulse_pending, "zero damage cannot consume the emergency charge")
	paused = true
	contact_hit(p1)
	check(guard.pulse_cooldown == 0 and p1.energy == 1, "a paused hit cannot consume the emergency charge")
	paused = false
	p1.touched = true
	contact_hit(p1)
	check(guard.pulse_cooldown == 0, "an ordinary hit already covered by injury grace preserves the ready charge")
	p1.touched = false
	contact_hit(p1)
	check(p1.energy == 1 and p1.state == p1.State.ACTIVE and not p1.touched and p1.malusSpeed == 0 and p1.ship_sprite.modulate == Color.WHITE, "the emergency charge cancels a lethal enemy contact before injury, slowdown or death effects")
	check(guard.pulse_cooldown == 12 and is_equal_approx(guard.pulse_protection_left, 0.6), "enemy contact starts the authored protection and recharge")
	var pulse := pulse_now()
	var shot := hostile(p1.position)
	shot._on_shot_area_entered(p1)
	check(p1.energy == 1 and shot.get_meta("pooled", false), "projectiles remain blocked during protection already triggered by enemy contact")
	var rank: int = p1.loadout.rank_for(UpgradeDefinition.Effect.RETALIATION_PULSE)
	for source in 5:
		contact_hit(p1)
		p1._hit_by_beam()
	check(p1.energy == 1 and guard._pulses.size() == 1 and rank == 1, "simultaneous hull and continuous hits cannot bypass protection or emit extra waves")
	var snapshot: Dictionary = guard.snapshot()
	var alpha: float = p1.get_node("RetaliationIndicator").modulate.a
	paused = true
	guard._physics_process(2)
	check(guard.snapshot() == snapshot and p1.get_node("RetaliationIndicator").modulate.a == alpha, "pause freezes protection, recharge and presentation together")
	paused = false
	guard._physics_process(0.59)
	p1._hit_by_beam()
	check(p1.energy == 1 and guard.pulse_protection_left > 0, "continuous hazards are blocked throughout the short escape window")
	guard._physics_process(0.02)
	check(not p1.get_node("RetaliationIndicator").visible, "the protection indicator ends while the emergency charge remains cooling")
	contact_hit(p1)
	check(p1.energy == 0 and p1.state == p1.State.DYING and guard.pulse_protection_left == 0 and pulse._cancelled, "a subsequent lethal hit remains lethal during recharge and cancels the active wave")
	await reset_case()
	for data in [SHIELD, RIPOSTE, ARMOR]: equip(p1, data, 1)
	contact_hit(p1)
	check(p1.defenses.charges == 0 and p1.energy == 12 and p1.defenses.pulse_protection_left > 0 and p1.defenses.grace_left == 0, "a body breaks reflection and immediately triggers the independent contact countermeasure")
	p1.defenses._physics_process(0.61)
	contact_hit(p1)
	check(p1.energy == 11 and p1.defenses.grace_left == 1 and p1.defenses.repair_left == ARMOR.interval_value(1), "ordinary injury schedules repair after pulse protection ends")

func countermeasure_contacts() -> void:
	await reset_case()
	equip(p1, RIPOSTE, 1)
	p1.monitorable = true
	p1.collision_mask = CombatTargeting.Layers.ENEMY_SHOT
	p1.defenses.set_physics_process(true)
	for index in 5: hostile(p1.position + Vector2(index % 3 - 1, 0))
	await settle()
	p1.defenses.set_physics_process(false)
	check(p1.energy == 11 and p1.defenses._pulses.is_empty() and p1.defenses.pulse_cooldown == 0 and not p1.defenses._pulse_pending, "five actual projectile callbacks injure the hull without triggering or consuming the ready pulse")
	await reset_case()
	equip(p1, RIPOSTE, 1)
	p1.energy = 1
	var lethal := hostile(p1.position)
	lethal._on_shot_area_entered(p1)
	check(p1.energy == 0 and p1.state == p1.State.DYING and p1.defenses._pulses.is_empty() and not p1.defenses._pulse_pending, "even a lethal projectile cannot trigger the contact-only pulse")
	await reset_case()
	equip(p1, RIPOSTE, 1)
	p1.energy = 1
	p1.collision_mask = CombatTargeting.Layers.ENEMY
	target(&"countermeasure_body", p1.position)
	await settle()
	p1.defenses._physics_process(0)
	check(p1.energy == 1 and p1.defenses._pulse_pending, "the body-contact query protects a hull even though it enters vitals directly")
	for value in range(1, 4):
		for scene in ["asteroid", "big_asteroid"]:
			await reset_case()
			equip(p1, RIPOSTE, value)
			p1.collision_mask = CombatTargeting.Layers.ENEMY | CombatTargeting.Layers.ASTEROID
			var asteroid = load("res://scenes/enemies/%s.tscn" % scene).instantiate()
			stage.add_child(asteroid)
			asteroid.position = p1.position
			asteroid.collision_mask = 0
			asteroid.set_physics_process(false)
			await settle()
			p1.defenses._physics_process(0)
			check(p1.energy == 12 and p1.defenses.pulse_cooldown == RIPOSTE.recharge_value(value) and p1.defenses._pulse_pending, "small and large asteroid hulls trigger the contact countermeasure at every rank")
	await reset_case()
	equip(p1, RIPOSTE, 1)
	var beam = load("res://scenes/bosses/dread_ark_beam.gd").new()
	stage.add_child(beam)
	beam.position = p1.position - Vector2(0, 100)
	beam.offsets = PackedFloat32Array([0])
	beam.set_physics_process(false)
	beam.fire()
	beam._physics_process(0.01)
	beam._physics_process(0.36)
	check(p1.energy == 10 and p1.defenses.pulse_cooldown == 0 and p1.defenses.pulse_protection_left == 0 and not p1.defenses._pulse_pending, "a real boss beam retains its damage cadence without triggering the ready pulse")
	p1.defenses._physics_process(1.01)
	contact_hit(p1)
	beam._physics_process(0.36)
	check(p1.energy == 10 and p1.defenses.pulse_protection_left > 0, "enemy contact activates protection against later beam ticks")
	p1.defenses._physics_process(0.61)
	beam._physics_process(0.36)
	check(p1.energy == 9 and p1.defenses.pulse_cooldown > 0, "continuous beam damage resumes after contact-triggered protection expires")
	beam.stop()

func countermeasure_ranks() -> void:
	await reset_case()
	var menu = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
	var offer := RIPOSTE.offer_snapshot(2)
	var copy: String = menu._effect_lines(offer)
	check(offer.next_recharge == 8 and is_equal_approx(offer.protection_duration, 0.6) and copy.contains("CONTACT") and copy.contains("96PX") and copy.contains("8S CD"), "the selection card explains protection, upgraded reach and the actual rank cooldown")
	menu.free()
	for invalid_value in [0.0, -0.1, NAN, INF]:
		var invalid := RIPOSTE.duplicate() as UpgradeDefinition
		invalid.protection_duration = invalid_value
		check(not invalid.foundation_errors().is_empty(), "invalid emergency protection durations are rejected")
	for periods in [PackedFloat32Array([12, 10]), PackedFloat32Array([12, 13, 8]), PackedFloat32Array([12, 10, 0.5]), PackedFloat32Array([12, NAN, 8])]:
		var invalid := RIPOSTE.duplicate() as UpgradeDefinition
		invalid.recharge_values = periods
		check(not invalid.foundation_errors().is_empty(), "rank recharge data must be complete, finite and decreasing beyond protection")
	equip(p1, RIPOSTE, 1)
	contact_hit(p1)
	p1.defenses._physics_process(3)
	equip(p1, RIPOSTE, 1)
	check(is_equal_approx(p1.defenses.pulse_cooldown, 7.5) and p1.defenses.pulse_recharge_duration == 10, "rank two preserves the completed quarter of a twelve-second recharge")
	equip(p1, RIPOSTE, 1)
	check(is_equal_approx(p1.defenses.pulse_cooldown, 6) and p1.defenses.pulse_recharge_duration == 8, "rank three preserves recharge progress instead of granting a new charge")
	p1.defenses._physics_process(5.99)
	check(not p1.get_node("RetaliationIndicator").visible, "the ready indicator waits for the entire remaining recharge")
	p1.defenses._physics_process(0.02)
	check(p1.get_node("RetaliationIndicator").visible and p1.defenses.pulse_cooldown == 0, "the ready indicator returns exactly when the charge is usable")
	await reset_case()
	equip(p1, RIPOSTE, 1)
	contact_hit(p1)
	p1.defenses._physics_process(0.2)
	equip(p1, RIPOSTE, 1)
	check(is_equal_approx(p1.defenses.pulse_protection_left, 0.4), "ranking during protection never restarts or lengthens the escape window")

func pulse_damage(value: int) -> void:
	await reset_case()
	equip(p1, RIPOSTE, value)
	for rank in 5: p1.apply_upgrade(load("res://data/upgrades/foundation/damage.tres"))
	for id in [&"critical_hits", &"energy_chains", &"impact_explosions"]: p1.loadout.acquired_ranks[id] = 3
	p1.loadout.critical_chance = 1
	var bodies: Array[Area2D] = []
	for index in 6: bodies.append(target(StringName("pulse_%d" % index), p1.position + Vector2(12 + (index % 3) * 6, -5 + floori(index / 3.0) * 10)))
	var edge := target(&"pulse_edge", p1.position + Vector2(0, -RIPOSTE.range_value(value) + 3))
	var outside := target(&"pulse_outside", p1.position + Vector2(0, RIPOSTE.range_value(value) + 8))
	var erased := hostile(p1.position + Vector2(12, 0))
	var kept := hostile(p1.position + Vector2(-12, 0))
	kept.trowbackByShield = true
	await settle()
	var random_state: int = effects.combat_random(&"player1").state
	contact_hit(p1)
	var pulse := pulse_now()
	var native_scale := true
	for tick in 10:
		pulse._advance(RIPOSTE.blast_active_duration / 10)
		native_scale = native_scale and pulse._sprite.scale.x <= 1.0 and pulse._sprite.scale.y <= 1.0
	check(native_scale, "each rank expands without magnifying the golden artwork")
	pulse._advance(0.001)
	for body in bodies: check(is_equal_approx(body.get("life"), 100 - RIPOSTE.rank_value(value) * 2.25), "every aligned victim takes exactly one retaliation hit with common DAMAGE once")
	check(is_equal_approx(edge.get("life"), 100 - RIPOSTE.rank_value(value) * 2.25) and outside.get("life") == 100, "each rank reaches its larger authored radius without damaging hulls beyond it")
	check(erased.get_meta("pooled", false) and not kept.get_meta("pooled", false), "the wave erases hostile shots while preserving reflected projectiles")
	check(accepted.size() == 7 and accepted.all(func(entry): return entry.hit.kind() == PlayerHitSnapshot.Kind.SECONDARY and not entry.hit.is_critical() and not entry.first) and effects.combat_random(&"player1").state == random_state, "retaliation cannot critically strike, recurse or consume combat RNG")
	check(effects._chain_cooldowns.is_empty() and effects._explosion_cooldowns.is_empty() and effects.get_debug_snapshot().roots == 0, "pulse activity releases its root and never consumes offensive proc cooldowns")
	p1.defenses.request_pulse()
	check(p1.defenses._pulses.size() == 1 and p1.defenses.pulse_cooldown == RIPOSTE.recharge_value(value), "the owner pulse cooldown prevents duplicate emergency triggers")
	pulse._advance(RIPOSTE.blast_visual_duration - pulse.age + 0.01)
	await settle()
	check(get_nodes_in_group(&"retaliation_pulse").is_empty(), "inactive fragments end without retaining a root or node")

func pulse_timing_and_armor() -> void:
	await reset_case()
	equip(p1, RIPOSTE, 1)
	var late := target(&"late", p1.position + Vector2(100, 0))
	var entering := target(&"entering", p1.position + Vector2(100, -8))
	var following := target(&"following", p1.position + Vector2(100, 8))
	var following_shot := hostile(p1.position + Vector2(100, 0))
	var old_edge := target(&"old_rank_one_edge", p1.position + Vector2(60, 0))
	var old_edge_shot := hostile(p1.position + Vector2(60, 6))
	var wall := ArmorWall.new()
	wall.collision_layer = CombatTargeting.Layers.ENEMY
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2, 36)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = p1.position + Vector2(-12, 0)
	stage.add_child(wall)
	var blocked := target(&"blocked", p1.position + Vector2(-22, 0))
	var blocked_shot := hostile(p1.position + Vector2(-20, 4))
	await settle()
	contact_hit(p1)
	var origin: Vector2 = p1.position
	var pulse := pulse_now()
	p1.position.x += 70
	pulse._advance(0.04)
	entering.position = origin + Vector2(25, 0)
	await settle()
	pulse._advance(0.16)
	check(entering.get("life") == 96 and pulse.position == origin and is_equal_approx(pulse.visual_radius, RIPOSTE.range_value(1)), "expansion hits at the fixed protection origin and the burst reaches its authored radius")
	entering.position.x += 70
	await settle()
	entering.position = origin + Vector2(25, 0)
	await settle()
	following.position = origin + Vector2(39, -12)
	following_shot.position = origin + Vector2(39, 0)
	await settle()
	pulse._advance(0.08)
	check(following.get("life") == 96 and following_shot.get_meta("pooled", false) and pulse._hit != null, "the full-size burst keeps clearing later arrivals during its active hold")
	check(RIPOSTE.range_value(1) == 48 and old_edge.get("life") == 100 and not old_edge_shot.get_meta("pooled", false), "rank one no longer damages hulls or clears shots at the former sixty-pixel edge")
	pulse._advance(0.07)
	check(entering.get("life") == 96 and blocked.get("life") == 100 and not blocked_shot.get_meta("pooled", false), "reentry cannot multiply damage and explicit armor protects hulls and hostile shots")
	late.position = origin
	await settle()
	pulse._advance(0.04)
	check(late.get("life") == 100 and pulse._hit == null, "entering during inactive fragments causes no damage")

func boss_exclusion() -> void:
	await reset_case()
	equip(p1, SHIELD, 1)
	equip(p1, RIPOSTE, 1)
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"defense_boss"
	boss.configure_spawn(context)
	boss.position = p1.position + Vector2(6, 0)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	for surface in [boss, boss.get_node("PortCannon"), boss.get_node("StarboardCannon")]:
		if surface != boss: surface.position = Vector2.ZERO
		surface.collision_mask = 0
		var circle := CircleShape2D.new()
		circle.radius = 4
		for child in surface.get_children():
			if child is CollisionShape2D: child.shape = circle
	boss.get_node("Armor").position.x = -100
	p1.collision_mask = CombatTargeting.Layers.ENEMY
	await settle()
	p1.defenses._physics_process(0)
	check(p1.defenses.charges == 0 and p1.energy == 12 and p1.defenses.pulse_cooldown > 0, "boss contact breaks reflection and triggers retaliation once across its parts")
	var before: float = boss.life + boss.get_node("PortCannon").life + boss.get_node("StarboardCannon").life
	var pulse := pulse_now()
	pulse._advance(0.12)
	check(is_equal_approx(boss.life + boss.get_node("PortCannon").life + boss.get_node("StarboardCannon").life, before - 4), "one defensive wave damages at most one piece of a logical boss")

func saturation_and_pending() -> void:
	await reset_case()
	equip(p1, RIPOSTE, 1)
	var victim := target(&"saturation", p1.position + Vector2(20, 0))
	await settle()
	var pulses: Array[Node2D] = []
	var packed = load("res://scenes/player/weapons/retaliation_pulse.gd")
	for index in 10:
		var pulse: Node2D = packed.new()
		check(pulse.configure(p1, {"position": p1.position, "rank": 1, "multiplier": 1.0}), "saturation waves configure through normal owned hit roots")
		stage.add_child(pulse)
		pulse.set_physics_process(false)
		pulses.append(pulse)
	check(pulses.filter(func(pulse: Node2D): return pulse.visible).size() == 4, "the native pulse visual budget remains bounded")
	for pulse in pulses: pulse._advance(0.12)
	check(victim.get("life") == 60, "visual saturation cannot suppress any wave's gameplay damage")
	for pulse in pulses: pulse._advance(0.49)
	await settle()
	check(effects.get_debug_snapshot().roots == 0 and get_nodes_in_group(&"retaliation_pulse").is_empty(), "saturated waves release all roots and visuals")
	var origin: Vector2 = p1.position
	contact_hit(p1)
	p1.position.x += 70
	paused = true
	await process_frame
	check(p1.defenses._pulse_pending and p1.defenses._pulses.is_empty(), "pausing before deferred pulse creation preserves the pending request")
	paused = false
	p1.defenses._physics_process(0)
	var queued: Node2D = p1.defenses._pulses.back().get_ref()
	queued.set_physics_process(false)
	check(queued.position == origin, "resumed pending waves retain the actual injury position")

func independent_pulses() -> void:
	await reset_case()
	p2.position = p1.position + Vector2(48, 0)
	equip(p1, RIPOSTE, 1)
	equip(p2, RIPOSTE, 1)
	var victim := target(&"both_pulses", p1.position + Vector2(24, 0))
	await settle()
	contact_hit(p1)
	contact_hit(p2)
	var left := pulse_now()
	p2.defenses._spawn_pulse()
	var right: Node2D = p2.defenses._pulses.back().get_ref()
	right.set_physics_process(false)
	left._advance(0.12)
	right._advance(0.12)
	check(victim.get("life") == 92 and accepted.size() == 2 and accepted[0].hit.owner_id() == &"player1" and accepted[1].hit.owner_id() == &"player2", "both owners can retaliate independently against the same hull")
	p1.set_state(p1.State.DYING)
	right._advance(0.24)
	check(not right._cancelled and effects.get_debug_snapshot().roots == 0 and p2.defenses.pulse_cooldown == 12 and p2.defenses.pulse_protection_left > 0, "one owner's death cannot cancel the partner's wave, protection or recharge")

func death_during_acceptance() -> void:
	await reset_case()
	equip(p1, RIPOSTE, 1)
	var first := target(&"cleanup_a", p1.position + Vector2(6, -1))
	var next := target(&"cleanup_b", p1.position + Vector2(6, 1))
	await settle()
	effects.hit_accepted.connect(func(_packet, _id, _at, _first): p1.set_state(p1.State.DYING), CONNECT_ONE_SHOT)
	contact_hit(p1)
	p1.defenses._spawn_pulse()
	check(first.get("life") == 96 and next.get("life") == 100 and p1.state == p1.State.DYING and effects.get_debug_snapshot().roots == 0, "death during accepted-hit notification cancels remaining pulse damage and releases the active root")
	await settle()
	check(get_nodes_in_group(&"retaliation_pulse").is_empty(), "a wave cancelled during its own startup leaves no deferred node or reference")

func lifecycle() -> void:
	await reset_case()
	equip(p1, SHIELD, 1)
	equip(p1, RIPOSTE, 1)
	for impact in 4: contact_hit(p1)
	var pulse := pulse_now()
	var snapshot: Dictionary = p1.defenses.snapshot()
	paused = true
	p1.defenses._physics_process(2)
	pulse._physics_process(0.2)
	check(p1.defenses.snapshot() == snapshot and pulse.age == 0, "selection pause freezes shield recharge, pulse protection, cooldown and active wave")
	paused = false
	p1.set_state(p1.State.DYING)
	check(p1.defenses.charges == 0 and p1.defenses.recharge_left == 0 and p1.defenses.pulse_protection_left == 0 and not p1.shield.visible and not p1.get_node("RetaliationIndicator").visible and effects.get_debug_snapshot().roots == 0, "owner death stops shield, protection, recharge, pending waves and roots immediately")
	await settle()
	check(get_nodes_in_group(&"retaliation_pulse").is_empty(), "owner death releases pulse references and nodes")
	await reset_case()
	var baseline := get_node_count()
	for cycle in 3:
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var player = world.progression.players[0]
		player.apply_upgrade(SHIELD)
		player.apply_upgrade(RIPOSTE)
		for impact in 4: contact_hit(player)
		world.free()
		await settle()
		check(get_node_count() == baseline and get_nodes_in_group(&"retaliation_pulse").is_empty(), "world teardown cancels both pending and active defensive state")

func native_presentation() -> void:
	await reset_case()
	stage.hide()
	for layout in ["solo", "coop", "wide"]:
		root.size = Vector2i(960 if layout == "wide" else 640, 400)
		globals.coop = layout != "solo"
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var players: Array = world.progression.players
		var side_width := maxf((root.size.x - 640) * 0.5, 0)
		for index in players.size():
			var player = players[index]
			player.position = Vector2((220 if index == 0 else 420) + side_width, 285)
			player.set_physics_process(false)
			player.energy = 12
			player.update_energy()
			for data in [SHIELD, ARMOR, RIPOSTE]: equip(player, data, 2)
			player.defenses.set_physics_process(false)
			player.defenses._physics_process(0.16)
		var previous := stage
		stage = world
		var victims: Array[Area2D] = []
		for index in 6:
			var body: Area2D = enemy(StringName("native_defense_%d" % index), players[0].position + Vector2.from_angle(TAU * index / 6) * 34, 100)
			body.collision_mask = 0
			victims.append(body)
		await settle()
		await RenderingServer.frame_post_draw
		capture("defense_%s_ready" % layout)
		var shots: Array[Shot] = []
		for index in 5:
			var shot := hostile(players[0].position + Vector2(index % 3 - 1, -8))
			shot.speedX = 0
			shot.set_physics_process(true)
			shots.append(shot)
		stage = previous
		await settle()
		check(players[0].defenses.charges == 0 and players[0].energy == 12 and players[0].defenses.pulse_cooldown == 0, "native projectile impacts deplete five sphere charges while preserving the contact-only pulse")
		check(shots.filter(func(item: Shot): return item.trowbackByShield).size() == 5, "native field reflection preserves exactly its authored capacity")
		victims[0].position = players[0].position
		await settle()
		players[0].defenses._physics_process(0)
		await settle()
		check(players[0].energy == 12 and players[0].defenses.pulse_protection_left > 0 and players[0].defenses.pulse_cooldown > 0, "a native enemy hull collision triggers the preserved pulse and protection")
		await RenderingServer.frame_post_draw
		capture("defense_%s_impact" % layout)
		for sample in 5:
			for tick in 2:
				await physics_frame
				await process_frame
			for player in players: player.defenses._physics_process(1.0 / 30.0)
			await RenderingServer.frame_post_draw
			capture("defense_%s_wave_%d" % [layout, sample])
		check(victims.all(func(body: Area2D): return body.get("life") <= 97), "all six visible native hulls receive the retaliation damage")
		victims[0].position = players[0].position + Vector2(34, 0)
		for tick in 12:
			await physics_frame
			await process_frame
		players[0].defenses._physics_process(2)
		await RenderingServer.frame_post_draw
		capture("defense_%s_recharge" % layout)
		players[0].defenses._physics_process(players[0].defenses.recharge_left + 0.01)
		await RenderingServer.frame_post_draw
		capture("defense_%s_return" % layout)
		check(players[0].defenses.charges == 5 and players[0].shield.visible, "the native sphere returns with its full capacity")
		if players.size() > 1:
			stage = world
			var blue_victims: Array[Area2D] = []
			for sign_y in [-1, 1]: blue_victims.append(enemy(StringName("native_blue_%d" % sign_y), players[1].position + Vector2(24, sign_y * 12), 100))
			for body in blue_victims: body.collision_mask = 0
			stage = previous
			await settle()
			for impact in 5: players[1].defenses.take_hit()
			contact_hit(players[1])
			players[1].defenses._spawn_pulse()
			var blue: Node2D = players[1].defenses._pulses.back().get_ref()
			blue.set_physics_process(false)
			for sample in 4:
				blue._advance(0.04)
				await RenderingServer.frame_post_draw
				capture("defense_%s_blue_%d" % [layout, sample])
			check(blue_victims.all(func(body: Area2D): return body.get("life") == 94), "native blue-team victims receive the same authored wave damage")
			blue._advance(0.45)
			players[1].defenses._physics_process(players[1].defenses.recharge_left + 0.01)
			check(players[1].defenses.charges == 5 and players[1].energy == 12, "nearby bodies outside the hull cannot consume a projectile-only sphere")
		var menu = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
		root.add_child(menu)
		var participants := {}
		for player in players:
			participants[StringName(player.id_Player)] = {"build": player.loadout.foundation_snapshot(), "offers": [SHIELD.offer_snapshot(2), ARMOR.offer_snapshot(2), RIPOSTE.offer_snapshot(2)]}
		menu.open(1200, participants, {"level": 4, "xp": 0, "next_threshold": 21})
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		capture("defense_%s_choices" % layout)
		menu.free()
		world.free()
		await settle()
	root.size = Vector2i(640, 400)
	globals.coop = true
	stage.show()

func capture(name: String) -> void:
	check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://%s.webp" % name), true) == OK, "native defensive state capture saves")

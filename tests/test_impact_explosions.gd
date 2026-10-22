extends "res://tests/player/test_player_hit_contract.gd"

const UPGRADE: UpgradeDefinition = preload("res://data/upgrades/impact_explosions.tres")
const ExplosionScene := preload("res://scenes/combat/impact_explosion.tscn")
const Layers := preload("res://core/collision_layers.gd")

class BlastArmor extends Area2D:
	var armored := true

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = true
	globals.reset_run(1110)
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
		player.position = Vector2(200 + index * 250, 350)
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
	check(UPGRADE.foundation_errors().is_empty() and UPGRADE.target_limit == 0 and is_equal_approx(UPGRADE.proc_cooldown, 0.3), "bounded explosion data is fully authored")
	check(PackedFloat32Array(UPGRADE.rank_values) == PackedFloat32Array([0.7, 0.9, 1.1]) and PackedFloat32Array(UPGRADE.range_values) == PackedFloat32Array([24, 30, 36]), "the concentrated blast revision doubles damage and reduces each previous radius by one quarter")
	for field in ["range_values", "proc_cooldown", "target_limit", "blast_expansion_duration", "blast_active_duration", "blast_visual_duration"]:
		var invalid := UPGRADE.duplicate() as UpgradeDefinition
		if field == "range_values": invalid.range_values = PackedFloat32Array([NAN])
		elif field == "target_limit": invalid.target_limit = 1
		else: invalid.set(field, 0)
		check(not invalid.foundation_errors().is_empty(), "invalid area data rejects before catalog eligibility")
	for rank in range(1, 4): await ranks_and_boundaries(rank)
	await hull_overlap()
	await wave_timing()
	await moving_formation()
	await channel_order()
	await cap_and_occlusion()
	await sources_and_cooldowns()
	await actual_projectiles()
	await actual_satellite()
	await chains_and_rewards()
	await boss_surfaces()
	await lifecycle()
	await visuals()
	if DisplayServer.get_name() != "headless": await native_presentation()
	await reset_case()
	stage.free()
	await settle()
	print("Impact explosions: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func reset_case() -> void:
	paused = false
	effects.cancel()
	for player in [p1, p2]:
		player.weapons.stop_support()
		player.loadout.reset()
		player.state = player.State.ACTIVE
	for shot in get_nodes_in_group("player_Shot"):
		if not shot.get_meta("pooled", false): ProjectilePool.despawn(shot)
	await settle()
	for child in stage.get_children():
		if child not in [p1, p2, pool, effects]: child.free()
	effects.start([p1, p2], globals.run_random)
	effects.set_physics_process(true)
	accepted.clear()
	xp_events = 0

func complete_blasts() -> void:
	await settle()
	if effects.is_physics_processing():
		await create_timer(0.18).timeout
	else:
		for id in effects._active_explosions.keys():
			effects._advance_explosion(id, maxf(0.0, UPGRADE.blast_active_duration - effects._active_explosions[id].age))
	await settle()

func tiny_enemy(id: StringName, at: Vector2, health := 100.0) -> Variant:
	var target = enemy(id, at, health)
	target.collision_mask = 0
	var circle := CircleShape2D.new()
	circle.radius = 1
	target.get_node("CollisionShape2D").shape = circle
	return target

func packet(rank := 3, kind := PlayerHitSnapshot.Kind.GUN, critical := false, owner := &"player1") -> PlayerHitSnapshot:
	return effects.create_hit(owner, 1, 2, {&"impact_explosions": rank}, kind, 1.0 if critical else 0.0)

func strike(hit: PlayerHitSnapshot, target: Area2D) -> void:
	check(effects.resolve_hit(hit, target, false, target.global_position), "setup direct impact accepts damage")
	effects.release_root(hit)

func ranks_and_boundaries(rank: int) -> void:
	await reset_case()
	for value in rank: check(p1.apply_upgrade(UPGRADE).applied, "normal upgrade acquisition applies each authored rank")
	check(p1.loadout.foundation_snapshot().offensive_count == 1 and p2.loadout.rank_for(UpgradeDefinition.Effect.IMPACT_EXPLOSIONS) == 0, "ranks share one personal offensive slot")
	if rank == 3: check(not p1.apply_upgrade(UPGRADE).applied, "rank three cannot consume a fourth acquisition")
	var origin = tiny_enemy(&"origin", Vector2(240, 200))
	var inside = tiny_enemy(&"boundary", Vector2(240 + UPGRADE.range_value(rank), 200))
	var outside = tiny_enemy(&"outside", Vector2(240, 198 - UPGRADE.range_value(rank)))
	await settle()
	var rng_states := [globals.run_random.encounters.state, globals.run_random.drops.state, globals.run_random.upgrades.state, effects.combat_random(&"player2").state]
	strike(packet(rank, PlayerHitSnapshot.Kind.GUN, true), origin)
	effects.set_physics_process(false)
	for id in effects._explosion_requests.keys(): effects._resolve_explosion(id)
	var blast_visuals := get_nodes_in_group(&"impact_explosion")
	check(not blast_visuals.is_empty() and blast_visuals[0].rank == rank and blast_visuals[0].position == origin.position and blast_visuals[0].owner_id == &"player1", "effect uses the recorded impact center, rank and owner")
	await complete_blasts()
	check(origin.life == 96 and is_equal_approx(inside.life, 100 - 2 * UPGRADE.rank_value(rank)) and outside.life == 100, "critical doubles direct damage only; authored radius includes boundary and excludes outside")
	check(accepted.size() == 2 and not accepted[1].first and not accepted[1].hit.is_critical() and accepted[1].hit.modifier_rank(&"impact_explosions") == 0, "splash is secondary and cannot crit or recursively trigger a proc")
	check(rng_states == [globals.run_random.encounters.state, globals.run_random.drops.state, globals.run_random.upgrades.state, effects.combat_random(&"player2").state], "area selection and visuals consume no unrelated RNG streams")
	check(effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "copied area requests release their roots after resolution")
	var offer := UPGRADE.offer_snapshot(rank - 1)
	check(offer.next_range == UPGRADE.range_value(rank) and offer.next_value == UPGRADE.rank_value(rank) and offer.target_limit == 0, "cards disclose radius, pre-critical factor and target limit")
	check(is_equal_approx(offer.next_range_bonus, [0.0, 0.25, 0.5][rank - 1]), "radius bonuses are measured against the first rank")

func cap_and_occlusion() -> void:
	await reset_case()
	var origin = tiny_enemy(&"origin", Vector2(240, 200))
	var targets: Array = []
	for index in 6:
		targets.append(tiny_enemy(StringName("crowd_%d" % index), origin.position + Vector2.from_angle(index * TAU / 6) * (14 + index * 2)))
	await settle()
	strike(packet(), origin)
	await complete_blasts()
	check(accepted.size() == 7, "one direct impact reaches all six additional groups without a target cap")
	for index in targets.size(): check(is_equal_approx(targets[index].life, 97.8), "every overlapping target receives the same area damage")
	await reset_case()
	origin = tiny_enemy(&"origin", Vector2(240, 200))
	var later = tiny_enemy(&"tie_b", Vector2(260, 200))
	var earlier = tiny_enemy(&"tie_a", Vector2(220, 200))
	var blocked = tiny_enemy(&"blocked", Vector2(240, 170))
	var armor := BlastArmor.new()
	armor.collision_layer = Layers.ENEMY
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 3)
	shape.shape = rect
	armor.add_child(shape)
	armor.position = Vector2(240, 185)
	stage.add_child(armor)
	await settle()
	strike(packet(), origin)
	await complete_blasts()
	check(accepted.size() == 3 and accepted[1].target == &"tie_a" and accepted[2].target == &"tie_b", "equal distances resolve by stable spawn identity regardless of insertion")
	check(earlier.life < 100 and later.life < 100 and blocked.life == 100, "armor occludes area damage while visible neighbors remain eligible")

func hull_overlap() -> void:
	for rank in range(1, 4):
		await reset_case()
		var radius := UPGRADE.range_value(rank)
		var source_enemy = tiny_enemy(&"origin", Vector2(240, 200))
		var touching = tiny_enemy(&"hull_edge", source_enemy.position + Vector2(radius + 8, 0))
		var circle := CircleShape2D.new()
		circle.radius = 10
		touching.get_node("CollisionShape2D").shape = circle
		var outside = tiny_enemy(&"outside_hull", source_enemy.position - Vector2(0, radius + 12))
		outside.get_node("CollisionShape2D").shape = circle
		await settle()
		strike(packet(rank), source_enemy)
		await complete_blasts()
		check(is_equal_approx(touching.life, 100 - 2 * UPGRADE.rank_value(rank)) and outside.life == 100, "explosion overlaps the actual enemy hull beyond its center without reaching a separated hull")
	await reset_case()
	var origin = tiny_enemy(&"origin", Vector2(240, 200))
	var offset_target = tiny_enemy(&"offset_hull", origin.position + Vector2(UPGRADE.range_value(1) + 28, 0))
	offset_target.rotation = 0.25
	var collision = offset_target.get_node("CollisionShape2D")
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(24, 14)
	collision.shape = rectangle
	collision.position = Vector2(-20, 0)
	collision.rotation = 0.4
	await settle()
	strike(packet(1), origin)
	await complete_blasts()
	check(is_equal_approx(offset_target.life, 98.6), "offset and rotated collision shapes use their actual world transform")
	await reset_case()
	origin = tiny_enemy(&"origin", Vector2(240, 200))
	var enclosing = tiny_enemy(&"enclosing_hull", origin.position)
	var enclosing_shape := CircleShape2D.new()
	enclosing_shape.radius = 20
	enclosing.get_node("CollisionShape2D").shape = enclosing_shape
	await settle()
	strike(packet(1), origin)
	await complete_blasts()
	check(is_equal_approx(enclosing.life, 98.6), "an explosion beginning inside another hull still damages it once")

func sources_and_cooldowns() -> void:
	for kind in [PlayerHitSnapshot.Kind.GUN, PlayerHitSnapshot.Kind.SIDE_GUN, PlayerHitSnapshot.Kind.DRONE, PlayerHitSnapshot.Kind.MISSILE, PlayerHitSnapshot.Kind.SATELLITE, PlayerHitSnapshot.Kind.PLASMA, PlayerHitSnapshot.Kind.REFLECTED, PlayerHitSnapshot.Kind.SECONDARY]:
		await reset_case()
		var source_target = tiny_enemy(&"origin", Vector2(240, 200))
		var splash_target = tiny_enemy(&"neighbor", Vector2(260, 200))
		await settle()
		strike(packet(3, kind), source_target)
		await complete_blasts()
		check((splash_target.life < 100) == (kind in [PlayerHitSnapshot.Kind.GUN, PlayerHitSnapshot.Kind.SIDE_GUN, PlayerHitSnapshot.Kind.DRONE, PlayerHitSnapshot.Kind.MISSILE, PlayerHitSnapshot.Kind.SATELLITE]), "only compatible direct sources trigger explosions: %d" % kind)
	await reset_case()
	effects.set_physics_process(false)
	for value in 5: p1.loadout.apply_foundation(&"fire_rate")
	var origin = tiny_enemy(&"origin", Vector2(240, 200))
	var neighbor = tiny_enemy(&"neighbor", Vector2(260, 200))
	await settle()
	strike(packet(), origin)
	await complete_blasts()
	for kind in [PlayerHitSnapshot.Kind.DRONE, PlayerHitSnapshot.Kind.MISSILE, PlayerHitSnapshot.Kind.SATELLITE]: strike(packet(3, kind), origin)
	await complete_blasts()
	check(is_equal_approx(neighbor.life, 97.8) and is_equal_approx(effects._explosion_cooldowns[&"player1"], 0.3), "all weapons share the owner cooldown; FIRE_RATE cannot shorten it or accumulate denied requests")
	strike(packet(3, PlayerHitSnapshot.Kind.GUN, false, &"player2"), origin)
	await complete_blasts()
	check(is_equal_approx(neighbor.life, 95.6) and accepted.back().hit.owner_id() == &"player2", "partner cooldown and secondary credit are independent")
	effects._physics_process(0.299)
	strike(packet(), origin)
	await complete_blasts()
	check(is_equal_approx(neighbor.life, 95.6), "cooldown rejects just before its boundary")
	effects._physics_process(0.0011)
	strike(packet(), origin)
	await complete_blasts()
	check(is_equal_approx(neighbor.life, 93.4), "the next accepted impact after the cooldown can trigger once")

func wave_timing() -> void:
	await reset_case()
	effects.set_physics_process(false)
	var center := Vector2(240, 200)
	var origin = tiny_enemy(&"timing_origin", center)
	var near = tiny_enemy(&"near", center + Vector2(3, 0))
	var middle = tiny_enemy(&"middle", center + Vector2(18, 0))
	var edge = tiny_enemy(&"edge", center + Vector2(36, 0))
	var entrant = tiny_enemy(&"entrant", center + Vector2(80, 0))
	var late = tiny_enemy(&"late", center - Vector2(0, 80))
	await settle()
	strike(packet(), origin)
	await settle()
	var id: int = effects._active_explosions.keys()[0]
	var visual = get_nodes_in_group(&"impact_explosion")[0]
	check(is_equal_approx(near.life, 97.8) and middle.life == 100 and edge.life == 100, "ignition damages only the initial quarter-radius disk")
	check(effects.get_debug_snapshot().roots == 1 and visual.age == 0, "the wave owns the copied root and visual clock during its active interval")
	origin.position += Vector2(80, 40)
	effects._physics_process(0.04)
	check(is_equal_approx(middle.life, 97.8) and edge.life == 100 and visual._sprite.frame % 8 == 1, "the half-radius damage and forty-millisecond visual frame advance together")
	entrant.position = center + Vector2(0, 20)
	await settle()
	paused = true
	var cooldown: float = effects._explosion_cooldowns[&"player1"]
	effects._physics_process(0.2)
	await create_timer(0.05, true).timeout
	check(entrant.life == 100 and visual.age == 0.04 and effects._explosion_cooldowns[&"player1"] == cooldown, "pause freezes an already active wave, its frame and cooldown")
	paused = false
	effects._physics_process(0.04)
	check(is_equal_approx(entrant.life, 97.8) and visual._sprite.frame % 8 == 2, "an enemy entering the growing disk is damaged at the next physics sample")
	entrant.position += Vector2(80, 0)
	await settle()
	entrant.position = center + Vector2(0, 20)
	await settle()
	effects._physics_process(0.04)
	check(is_equal_approx(edge.life, 97.8) and is_equal_approx(entrant.life, 97.8) and is_equal_approx(near.life, 97.8) and visual._sprite.frame % 8 == 3, "peak radius hits the boundary while sustained overlap and re-entry never repeat damage")
	check(effects._active_explosions[id].position == center and visual.global_position == center, "the expanding blast never follows its surviving origin enemy")
	effects._physics_process(0.04)
	check(effects.get_debug_snapshot().roots == 0 and effects.get_debug_snapshot().requests == 0 and visual._sprite.frame % 8 == 4, "the active interval releases hit references exactly when the animation becomes inactive fragments")
	late.position = center - Vector2(10, 0)
	await settle()
	effects._physics_process(0.05)
	check(late.life == 100, "entering the fading fragments after the active interval causes no damage")
	effects._physics_process(0.12)
	await settle()
	check(effects._active_explosions.is_empty() and not is_instance_valid(visual), "the shared clock removes the visual tail at its authored lifetime")
	for death_age in [0.04, 0.2]:
		await reset_case()
		effects.set_physics_process(false)
		var death_origin = tiny_enemy(&"death_origin", center)
		var death_neighbor = tiny_enemy(&"death_neighbor", center + Vector2(30, 0))
		await settle()
		strike(packet(), death_origin)
		await settle()
		effects._physics_process(death_age)
		var before: float = death_neighbor.life
		p1.set_state(p1.State.DYING)
		await settle()
		check(effects._active_explosions.is_empty() and get_nodes_in_group(&"impact_explosion").is_empty() and death_neighbor.life == before and effects.get_debug_snapshot().roots == 0, "DYING removes both active and cooling waves without late hits or retained roots")

func moving_formation() -> void:
	await reset_case()
	var origin = enemy(&"formation_origin", Vector2(240, 200), 100)
	var targets: Array = []
	for index in 6:
		var target = enemy(StringName("formation_%d" % index), origin.position + Vector2((14 + (index % 3) * 8) * (1 if index < 3 else -1), 0), 100)
		target._movement_profile = target._movement_profile.duplicate()
		target._movement_profile.mode = MovementProfile.Mode.STRAIGHT
		target.speedX = 0
		target.speedY = 24
		target.set_physics_process(true)
		targets.append(target)
	await settle()
	var starting_y: float = targets[0].position.y
	strike(packet(), origin)
	await settle()
	check(get_nodes_in_group(&"combat_feedback").size() > 0, "accepted area hits produce local finite feedback on their actual victims")
	await complete_blasts()
	for target in targets:
		check(is_equal_approx(target.life, 97.8) and accepted.filter(func(record): return record.target == target.get_combat_identity()).size() == 1, "every real moving hull receives one full hit, including enemies behind other enemies")
	check(targets[0].position.y > starting_y and accepted.size() == 7, "six enemies move under their real physics without being limited to four splash victims")

func channel_order() -> void:
	for explosion_first in [false, true]:
		await reset_case()
		effects.set_physics_process(false)
		var origin = tiny_enemy(&"order_origin", Vector2(240, 200))
		var next = tiny_enemy(&"order_next", Vector2(260, 200))
		await settle()
		var hit: PlayerHitSnapshot = effects.create_hit(&"player1", 1, 2, {&"impact_explosions": 3, &"energy_chains": 1})
		strike(hit, origin)
		var chain_id: int = effects._chain_requests.keys()[0]
		var explosion_id: int = effects._explosion_requests.keys()[0]
		if explosion_first:
			effects._resolve_explosion(explosion_id)
			effects._advance_explosion(explosion_id, 0.12)
			effects._resolve_chain(chain_id)
		else:
			effects._resolve_chain(chain_id)
			effects._resolve_explosion(explosion_id)
			effects._advance_explosion(explosion_id, 0.12)
		check(is_equal_approx(next.life, 96.9) and accepted.size() == 3, "chain plus explosion stack exactly once on the same ordinary hull in either resolution order")
		check(not effects.resolve_hit(hit.secondary_hit(10), next, false, Vector2.INF, &"impact_explosions") and not effects.resolve_hit(hit.secondary_hit(10), next, false, Vector2.INF, &"energy_chains"), "each secondary channel rejects its own duplicate contact")
		check(not effects.resolve_hit(hit.secondary_hit(10), origin, false, Vector2.INF, &"impact_explosions"), "the directly hit origin remains excluded from both independent channels")

func actual_projectiles() -> void:
	for family in [&"gun", &"side_shot", &"micro_missiles", &"escort_drone"]:
		await reset_case()
		p1.apply_upgrade(UPGRADE)
		for rank in 5: p1.loadout.apply_foundation(&"damage")
		var origin = tiny_enemy(&"origin", Vector2(240, 180))
		var neighbor = tiny_enemy(&"neighbor", Vector2(256, 180))
		await settle()
		var shot: Variant = null
		if family == &"gun": shot = fire(p1)
		elif family == &"side_shot":
			p1.loadout.apply_foundation(family)
			p1.weapons.fire_primary()
			for candidate in get_nodes_in_group("player_Shot"):
				if candidate.get_meta("pooled", false): continue
				if String(candidate.get_meta("pool_key", "")).contains("side_shot") and shot == null: shot = candidate
				else: ProjectilePool.despawn(candidate)
		else:
			var definition: UpgradeDefinition = load("res://data/upgrades/%s.tres" % family)
			var queued: bool
			if family == &"micro_missiles": queued = effects.queue_missile(&"player1", definition, 1, Vector2(240, 300), origin, p1.loadout.direct_damage_multiplier, p1.loadout.acquired_ranks, 0)
			else: queued = effects.queue_drone_bolt(&"player1", definition, 1, Vector2(240, 300), Vector2.UP, p1.loadout.direct_damage_multiplier, p1.loadout.acquired_ranks, 0)
			check(queued, "autonomous emitter reserves a real pooled projectile")
			await settle()
			for candidate in get_nodes_in_group("player_Shot"):
				if not candidate.get_meta("pooled", false): shot = candidate
		check(shot != null and shot.hit_snapshot.modifier_rank(&"impact_explosions") == 1, "real emission retains explosion rank: " + family)
		shot.set_physics_process(false)
		var base: float = shot.hit_snapshot.pre_critical_damage()
		p1.apply_upgrade(UPGRADE)
		p1.apply_upgrade(UPGRADE)
		shot.position = origin.position
		await complete_blasts()
		check(is_equal_approx(neighbor.life, 100 - base * 0.7) and is_equal_approx(origin.life, 100 - base), "real collision uses emission rank and modified damage once: " + family)
		check(shot.get_meta("pooled", false) and shot.hit_snapshot == null and effects.get_debug_snapshot().roots == 0, "recycled source cannot be retained by its explosion")
		if family == &"gun":
			var reused = fire(p2)
			check(reused == shot and reused.hit_snapshot.modifier_rank(&"impact_explosions") == 0, "cross-owner projectile reuse clears explosion state")
			ProjectilePool.despawn(reused)

func actual_satellite() -> void:
	await reset_case()
	p1.apply_upgrade(UPGRADE)
	p1.apply_upgrade(load("res://data/upgrades/orbiting_satellites.tres"))
	var satellites = p1.weapons.satellites
	satellites.set_physics_process(false)
	await settle()
	var at: Vector2 = satellites._orbiters[0].global_position
	var origin = tiny_enemy(&"sat_origin", at)
	var neighbor = tiny_enemy(&"sat_neighbor", at + Vector2(16, 0))
	await settle()
	satellites._resolve_contacts()
	await complete_blasts()
	check(origin.life == 99 and is_equal_approx(neighbor.life, 99.3), "real satellite overlap uses the same bounded explosion contract")

func chains_and_rewards() -> void:
	await reset_case()
	var origin = tiny_enemy(&"origin", Vector2(240, 200))
	var chain = tiny_enemy(&"chain", Vector2(252, 200))
	var splash = tiny_enemy(&"splash", Vector2(240, 220))
	await settle()
	var hit: PlayerHitSnapshot = effects.create_hit(&"player1", 1, 2, {&"impact_explosions": 3, &"energy_chains": 1}, PlayerHitSnapshot.Kind.GUN, 1)
	strike(hit, origin)
	await settle()
	check(get_nodes_in_group(&"energy_chain").size() == 1 and get_nodes_in_group(&"impact_explosion").size() == 1, "both distinct visual effects can coexist on one root")
	await complete_blasts()
	check(origin.life == 96 and is_equal_approx(chain.life, 96.9) and is_equal_approx(splash.life, 97.8) and accepted.size() == 4, "chain and explosion stack once per channel without critical splash or direct-target repeats")
	await reset_case()
	origin = tiny_enemy(&"origin", Vector2(240, 200))
	var victim = tiny_enemy(&"victim", Vector2(260, 200), 1)
	victim.definition.plasma_drop_chance = 100
	await settle()
	var before_score: int = globals.score
	var before_kills: int = globals.eliminations
	strike(packet(), origin)
	await complete_blasts()
	check(victim.destroyed and victim.last_player_hit_owner == &"player1" and xp_events == 1 and globals.score > before_score and globals.eliminations == before_kills + 1, "splash kills retain normal owner credit, score, XP and one elimination")
	check(not victim.receive_player_hit(100, &"player2") and xp_events == 1, "duplicate contact cannot repeat a splash kill reward")
	var cells := stage.get_children().filter(func(child): return child.scene_file_path == "res://scenes/ui/plasma_cell.tscn")
	check(cells.size() == 1 and cells[0].charge_amount == 12.5, "a guaranteed secondary plasma drop spawns exactly one normal cell")

func boss_surfaces() -> void:
	await reset_case()
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"explosion_boss"
	boss.configure_spawn(context)
	boss.position = Vector2(320, 110)
	stage.add_child(boss)
	boss.set_physics_process(false)
	var cannon = boss.get_node("PortCannon")
	var other = boss.get_node("StarboardCannon")
	var armor = boss.get_node("Armor")
	var hit := packet()
	check(not effects.resolve_hit(hit, boss) and not effects.resolve_hit(hit, armor) and effects.get_debug_snapshot().requests == 0 and effects._explosion_cooldowns.is_empty(), "entering and armored surfaces consume no explosion opportunity")
	boss.attack = boss.Attack.IDLE
	var total: float = boss.life + cannon.life + other.life
	check(effects.resolve_hit(hit, cannon, false), "the rejected root can later accept a vulnerable surface")
	effects.release_root(hit)
	await complete_blasts()
	check(is_equal_approx(total - boss.life - cannon.life - other.life, 2), "a boss-origin explosion excludes every surface of that logical boss")
	effects.start([p1, p2], globals.run_random)
	accepted.clear()
	cannon.position = Vector2.ZERO
	other.position = Vector2.ZERO
	armor.position.x = 200
	var origin = tiny_enemy(&"external_origin", Vector2(320, 135))
	await settle()
	total = boss.life + cannon.life + other.life
	strike(packet(), origin)
	await complete_blasts()
	check(is_equal_approx(total - boss.life - cannon.life - other.life, 2.2) and accepted.size() == 2, "external splash reaches only one visible vulnerable boss part despite overlapping surfaces")
	for first_channel in [&"energy_chains", &"impact_explosions"]:
		effects.start([p1, p2], globals.run_random)
		var root_packet: PlayerHitSnapshot = effects.create_hit(&"player1", 1, 1)
		check(effects.resolve_hit(root_packet, origin, false), "a new external root can attempt both secondary channels")
		var secondary := root_packet.secondary_hit(2.0)
		var second_channel := &"impact_explosions" if first_channel == &"energy_chains" else &"energy_chains"
		total = boss.life + cannon.life + other.life
		check(effects.resolve_hit(secondary, boss, false, Vector2.INF, first_channel) and not effects.resolve_hit(secondary, cannon, false, Vector2.INF, second_channel), "the boss shares one exclusion across both secondary channels in either order")
		check(is_equal_approx(total - boss.life - cannon.life - other.life, 2.0), "independent ordinary-enemy histories cannot multiply a boss root's damage")
		check(not effects.resolve_hit(secondary, other, false, Vector2.INF, &"unknown_channel"), "unregistered channels cannot bypass common exclusions")
		effects.release_root(root_packet)

func lifecycle() -> void:
	for cancel_kind in ["pause", "death", "world", "removed_target", "later_impact"]:
		await reset_case()
		var origin = tiny_enemy(&"origin", Vector2(240, 200))
		var neighbor = tiny_enemy(&"neighbor", Vector2(260, 200))
		await settle()
		var hit := packet()
		check(effects.resolve_hit(hit, origin, false), "first impact queues one copied explosion")
		if cancel_kind == "pause":
			paused = true
			var timer: float = effects._explosion_cooldowns[&"player1"]
			await create_timer(0.1, true).timeout
			check(neighbor.life == 100 and effects.get_debug_snapshot().requests == 1 and effects._explosion_cooldowns[&"player1"] == timer, "selection pause freezes queued work and owner cooldown")
			paused = false
		elif cancel_kind == "death": p1.set_state(p1.State.DYING)
		elif cancel_kind == "world": effects.cancel()
		elif cancel_kind == "removed_target": origin.free()
		else: check(effects.resolve_hit(hit, neighbor, false), "later direct impact can precede deferred area resolution")
		effects.release_root(hit)
		await complete_blasts()
		check(is_equal_approx(neighbor.life, 100.0 if cancel_kind in ["death", "world"] else (98.0 if cancel_kind == "later_impact" else 97.8)), "copied origin, cancellation and visited history remain valid: " + cancel_kind)
		check(effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "lifecycle leaves no queued effects or root leases")
	await reset_case()
	var baseline := get_node_count()
	for cycle in 3:
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var service = world.get_node("PlayerHitEffects")
		var player = world.progression.players[0]
		player.set_physics_process(false)
		var previous := stage
		stage = world
		var target = tiny_enemy(&"teardown", Vector2(240, 200))
		stage = previous
		var hit: PlayerHitSnapshot = service.create_hit(StringName(player.id_Player), 1, 1, {&"impact_explosions": 3})
		service.resolve_hit(hit, target, false)
		service.release_root(hit)
		world.free()
		await settle()
		check(get_node_count() == baseline and get_nodes_in_group(&"impact_explosion").is_empty(), "world removal cancels pending area work without node growth")

func visuals() -> void:
	await reset_case()
	var origin = tiny_enemy(&"visual_origin", Vector2(240, 200), 1000)
	var neighbor = tiny_enemy(&"saturated_neighbor", Vector2(260, 200), 1000)
	await settle()
	for index in 12:
		effects._explosion_cooldowns.clear()
		strike(packet(3, PlayerHitSnapshot.Kind.SIDE_GUN, false, &"player2"), origin)
	await settle()
	check(get_nodes_in_group(&"impact_explosion").size() == 8, "only presentation obeys the eight-instance cap")
	var visual = get_nodes_in_group(&"impact_explosion")[0]
	check(visual._sprite.texture.get_size() == Vector2(768, 576), "native wave cells retain the authored grid")
	paused = true
	var age: float = visual.age
	await create_timer(0.1, true).timeout
	check(visual.age == age and visual._sprite.frame >= 40, "pause freezes the combat-owned clock and P2 rank-three frame")
	paused = false
	await complete_blasts()
	check(is_equal_approx(neighbor.life, 1000 - 12 * 2.2), "visual saturation cannot drop any of twelve independent blast damages")
	await create_timer(0.35).timeout
	check(get_nodes_in_group(&"impact_explosion").is_empty() and effects._active_explosions.is_empty(), "all active waves and visual tails retire after the shared lifetime")
	await settle()
	var baseline := get_node_count()
	for cycle in 3:
		effects._explosion_cooldowns.clear()
		strike(packet(), origin)
		await create_timer(0.45).timeout
		check(get_node_count() == baseline, "repeated combat-driven waves and hit feedback return to a stable node baseline")

func native_presentation() -> void:
	await reset_case()
	stage.hide()
	for layout in ["solo", "coop", "wide"]:
		root.size = Vector2i(960 if layout == "wide" else 640, 400)
		globals.coop = layout != "solo"
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var service = world.get_node("PlayerHitEffects")
		service.set_physics_process(false)
		var side_width := maxf((root.size.x - 640.0) * 0.5, 0)
		var origins: Array = []
		var victims: Array = []
		for index in world.progression.players.size():
			var player = world.progression.players[index]
			player.position = Vector2(220 + index * 200 + side_width, 290)
			player.set_physics_process(false)
			for rank in 3: player.apply_upgrade(UPGRADE)
			var previous := stage
			stage = world
			var center := Vector2(230 + index * 180 + side_width, 170)
			origins.append(enemy(StringName("native_origin_%d" % index), center, 100))
			for slot in 6:
				var target = enemy(StringName("native_victim_%d_%d" % [index, slot]), center + Vector2((slot % 3 - 1) * 24, -18 if slot < 3 else 18), 100)
				target._movement_profile = target._movement_profile.duplicate()
				target._movement_profile.mode = MovementProfile.Mode.STRAIGHT
				target.speedX = 0
				target.speedY = 10
				victims.append(target)
			stage = previous
		await settle()
		for index in origins.size():
			var owner_id := StringName(world.progression.players[index].id_Player)
			var hit: PlayerHitSnapshot = service.create_hit(owner_id, 1, 1, {&"impact_explosions": 3})
			service.resolve_hit(hit, origins[index], false)
			service.release_root(hit)
		await settle()
		var previous_age := 0.0
		for sample in [0.0, 0.04, 0.08, 0.12, 0.16, 0.24]:
			for target in victims: target._physics_process(sample - previous_age)
			await physics_frame
			await process_frame
			service._physics_process(sample - previous_age)
			previous_age = sample
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://explosion_wave_%s_%03d.webp" % [layout, roundi(sample * 1000)]), true) == OK, "native moving victims and the synchronized damaging front save together")
		for target in victims: check(is_equal_approx(target.life, 98.9), "each real hull in the captured formation receives one accepted blast hit")
		var ui = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
		root.add_child(ui)
		var offers := [UPGRADE.offer_snapshot(0), UPGRADE.offer_snapshot(1), UPGRADE.offer_snapshot(2)]
		for rank in 3:
			var text: String = ui._effect_lines(offers[rank])
			check(not text.contains("PX") and text.contains("AREA") and not text.contains("TARGETS") and (text.contains("BASE BLAST") if rank == 0 else text.contains("+%d%% RADIUS" % (rank * 25))), "cards show percentage area bonuses without a four-target limit")
		var participants := {}
		for player in world.progression.players: participants[StringName(player.id_Player)] = {"build": player.loadout.foundation_snapshot(), "offers": offers}
		ui.open(1110, participants, {"level": 4, "xp": 0, "next_threshold": 21})
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://explosion_wave_choices_%s.webp" % layout), true) == OK, "updated area cards save in each native layout")
		ui.free()
		world.free()
		await settle()
	root.size = Vector2i(640, 400)
	globals.coop = true
	stage.show()

extends "res://tests/player/test_defensive_pack.gd"

const SIDE: UpgradeDefinition = preload("res://data/upgrades/foundation/side_shot.tres")
const DAMAGE: UpgradeDefinition = preload("res://data/upgrades/foundation/damage.tres")
const MAIN_TIERS := [0, 1, 2, 4]
const OUTER_TIERS := [0, 0, 1, 4]
const SIZES := [Vector2(2, 3), Vector2(4, 4), Vector2(4, 5), Vector2(5, 6), Vector2(6, 8)]

func run() -> void:
	setup_stage()
	check(SIDE.foundation_errors().is_empty() and SIDE.projectile_counts == PackedInt32Array([2, 4, 4, 4]), "side pairs are authored at every rank")
	for field in [&"projectile_counts", &"secondary_visual_tiers"]:
		var invalid := SIDE.duplicate() as UpgradeDefinition
		invalid.set(field, PackedInt32Array())
		check(not invalid.foundation_errors().is_empty(), "incomplete side data rejects before offers")
	var invalid := SIDE.duplicate() as UpgradeDefinition
	invalid.secondary_visual_tiers = PackedInt32Array([0, -1, 1, 4])
	check(not invalid.foundation_errors().is_empty(), "invalid native frame rejects before firing")
	invalid = SIDE.duplicate() as UpgradeDefinition
	invalid.secondary_damage_scale = NAN
	check(not invalid.foundation_errors().is_empty(), "invalid outer damage rejects before offers")
	for rank in range(1, 5): await rank_case(rank)
	await pool_case()
	if DisplayServer.get_name() != "headless": await native_sides()
	effects.cancel()
	stage.free()
	await settle()
	print("Earlier side pair: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func live_shots(owner_id: String) -> Array:
	return get_nodes_in_group(&"player_Shot").filter(func(shot): return not shot.get_meta("pooled", false) and shot.player_Id == owner_id)

func rank_case(rank: int) -> void:
	await reset_case()
	for pilot in [p1, p2]:
		equip(pilot, SIDE, rank)
		equip(pilot, DAMAGE, 2)
		pilot.weapons.fire_primary()
		var shots := live_shots(pilot.id_Player)
		check(shots.size() == (3 if rank == 1 else 5) and pilot.loadout.outer_side_pair == (rank >= 2), "each owner gets exactly the requested side pairs and one primary")
		var directions: Array[float] = []
		for shot in shots:
			shot.set_physics_process(false)
			if shot.hit_snapshot.kind() != PlayerHitSnapshot.Kind.SIDE_GUN: continue
			directions.append(shot.speedX)
			var outer: bool = absf(shot.speedX) > 100
			var tier: int = OUTER_TIERS[rank - 1] if outer else MAIN_TIERS[rank - 1]
			var shape: CollisionShape2D = shot.get_node("CollisionShape2D")
			check(shot._source_sprite.frame == tier + (5 if pilot == p2 else 0) and shape.shape.size == SIZES[tier], "each side uses its owner's native frame and matching collision size")
			check(shot.scale == Vector2.ONE and shape.scale == Vector2.ONE, "smaller shots use native geometry rather than scaled collision nodes")
			var expected: float = SIDE.rank_value(rank) * pilot.loadout.direct_damage_multiplier * (0.6 if outer else 1.0)
			check(is_equal_approx(shot.damage, expected) and is_equal_approx(shot.hit_snapshot.damage(), expected), "main and outer sides retain authored damage and one common multiplier")
			check(shot.hit_snapshot.modifier_rank(&"energy_chains") == 0 and shot.speedY == -540, "side identity and flight speed remain unchanged")
		check(directions.has(-51.0) and directions.has(51.0) and (rank == 1 or (directions.has(-110.5) and directions.has(110.5))), "all ranks preserve symmetric inner and outer trajectories")
	var selector = load("res://scenes/ui/upgrade_selection.gd").new()
	var copy: String = selector._effect_lines(SIDE.offer_snapshot(rank - 1))
	selector.free()
	check(copy.contains("2 SHOTS" if rank == 1 else "4 SHOTS") and (rank == 1 or copy.contains(["", "SMALL", "MEDIUM", "FULL"][rank - 1])), "offers state the actual count and outer size")
	if rank >= 2:
		var outer = live_shots(p1.id_Player).filter(func(shot): return shot.speedX == -110.5)[0]
		var expected: float = outer.damage
		var body = enemy(&"side_contact", Vector2(320, 100))
		outer.position = body.position
		await settle()
		check(is_equal_approx(body.life, 20 - expected) and outer.get_meta("pooled", false), "smaller outer shots cause real physical hull damage and recycle normally")

func pool_case() -> void:
	await reset_case()
	equip(p1, SIDE, 4)
	p1.weapons.fire_primary()
	var old_sides: Array = live_shots(p1.id_Player).filter(func(shot): return shot.speedX != 0)
	for shot in live_shots(p1.id_Player): ProjectilePool.despawn(shot)
	await settle()
	equip(p2, SIDE, 2)
	p2.weapons.fire_primary()
	var shots := live_shots(p2.id_Player)
	check(shots.size() == 5, "rank-two volleys can reuse a parked final-rank volley")
	for shot in shots:
		shot.set_physics_process(false)
		if shot.speedX == 0: continue
		var tier := 0 if absf(shot.speedX) > 100 else 1
		check(shot in old_sides and shot._source_sprite.frame == 5 + tier and shot.get_node("CollisionShape2D").shape.size == SIZES[tier], "reuse resets team, native size and shape from full to smaller shots")

func native_sides() -> void:
	for pilot in [p1, p2]:
		for shot in live_shots(pilot.id_Player): ProjectilePool.despawn(shot)
	await settle()
	stage.hide()
	for layout in ["solo", "coop", "wide"]:
		root.size = Vector2i(960 if layout == "wide" else 640, 400)
		globals.coop = layout != "solo"
		for rank in range(1, 5):
			var world = load("res://scenes/world/world.tscn").instantiate()
			root.add_child(world)
			world.get_node("waveGenerator").stop_run()
			var players: Array = world.progression.players
			for index in players.size():
				var pilot = players[index]
				pilot.position = Vector2((220 if index == 0 else 420) + (160 if layout == "wide" else 0), 300)
				pilot.set_physics_process(false)
				equip(pilot, SIDE, rank)
				pilot.weapons.fire_primary()
				for shot in live_shots(pilot.id_Player):
					shot._physics_process(0.16)
					shot.set_physics_process(false)
				check(live_shots(pilot.id_Player).size() == (3 if rank == 1 else 5), "native volley retains the requested count for each owner")
			await process_frame
			await RenderingServer.frame_post_draw
			capture("side_%s_rank_%d" % [layout, rank])
			if rank >= 2:
				var menu = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
				root.add_child(menu)
				var participants := {}
				for pilot in players:
					participants[StringName(pilot.id_Player)] = {"build": pilot.loadout.foundation_snapshot(), "offers": [SIDE.offer_snapshot(rank - 1), DAMAGE.offer_snapshot(0), SHIELD.offer_snapshot(0)]}
				menu.open(1500, participants, {"level": 4, "xp": 0, "next_threshold": 21})
				await create_timer(0.5).timeout
				await RenderingServer.frame_post_draw
				capture("side_%s_offer_%d" % [layout, rank])
				menu.free()
			world.free()
			await settle()
	root.size = Vector2i(640, 400)
	globals.coop = true
	stage.show()

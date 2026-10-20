extends SceneTree

const CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")
const CATALOG: UpgradeTable = preload("res://data/upgrades/foundation_catalog.tres")
const LEGACY: UpgradeTable = preload("res://data/upgrades/upgrade_table.tres")
const STATS: PlayerStats = preload("res://data/player/player_stats.tres")
const FULL := {"energy": 12, "shield": 3}

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func definition(id: StringName, table: UpgradeTable = CATALOG) -> UpgradeDefinition:
	for upgrade in table.upgrades:
		if upgrade.id == id:
			return upgrade
	return null

func fresh(table: UpgradeTable = CATALOG) -> PlayerLoadout:
	var loadout := PlayerLoadout.new(STATS)
	check(loadout.initialize_foundation(CONFIG, table.upgrades), "foundation initialization must succeed")
	return loadout

func rng(seed_value: int) -> RandomNumberGenerator:
	return RunRandom.new(seed_value).upgrades

func ids(hand: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for offer in hand.offers:
		result.append(offer.id)
	return result

func subset(names: Array[StringName]) -> UpgradeTable:
	var table := UpgradeTable.new()
	for id in names:
		table.upgrades.append(definition(id))
	table.upgrades.append(definition(&"score"))
	return table

func check_data_and_legacy() -> void:
	check(CATALOG.foundation_errors(CONFIG).is_empty() and CATALOG.upgrades.size() == 10, "only implemented foundation families/rewards must be authored")
	check([UpgradeDefinition.Effect.SPEED, UpgradeDefinition.Effect.FIRE_RATE, UpgradeDefinition.Effect.DAMAGE, UpgradeDefinition.Effect.SIDE_SHOT, UpgradeDefinition.Effect.SHIELD, UpgradeDefinition.Effect.ENERGY] == [0, 1, 2, 3, 4, 5], "legacy enum ordinals must remain stable")
	check(LEGACY.upgrades.size() == 6 and STATS.speed_max == 240 and is_equal_approx(STATS.shoot_delay_min, 0.12), "legacy catalog stays readable while live stat limits use the activated foundation")
	var legacy := PlayerLoadout.new(STATS)
	for upgrade in LEGACY.upgrades:
		for rank in upgrade.max_rank:
			legacy.apply(upgrade)
	check(is_equal_approx(legacy.move_speed(), 225) and is_equal_approx(legacy.fire_delay, 0.13), "legacy initialization/direct pickups must keep their previous caps")
	check(is_equal_approx(legacy.damage_bonus, 1.5) and legacy.rank_for(UpgradeDefinition.Effect.SIDE_SHOT) == 10, "legacy damage and side-shot ranks must remain unchanged")
	check(legacy.acquired_ranks.is_empty(), "legacy direct pickups must not silently enable foundation slots")
	var old_rng := rng(123)
	var expected_rng := rng(123)
	var total := 0
	for upgrade in LEGACY.upgrades:
		total += upgrade.weight
	for index in 100:
		var roll := expected_rng.randi_range(1, total)
		var expected: UpgradeDefinition
		for upgrade in LEGACY.upgrades:
			roll -= upgrade.weight
			if roll <= 0:
				expected = upgrade
				break
		check(LEGACY.pick(old_rng) == expected, "single-pick API must preserve the original weighted sequence")
	var invalid := CATALOG.duplicate(true) as UpgradeTable
	invalid.upgrades.append(invalid.upgrades[0])
	check(not invalid.foundation_errors(CONFIG).is_empty(), "duplicate stable IDs must be rejected")
	invalid = CATALOG.duplicate(true) as UpgradeTable
	var duplicate_effect := definition(&"speed").duplicate() as UpgradeDefinition
	duplicate_effect.id = &"other_speed"
	invalid.upgrades.append(duplicate_effect)
	check(not invalid.foundation_errors(CONFIG).is_empty(), "duplicate effects with different IDs must not bypass personal slot/stat ownership")
	for change in ["category", "repeatable", "weight", "rank_values"]:
		var bad := definition(&"speed").duplicate() as UpgradeDefinition
		match change:
			"category": bad.category = UpgradeDefinition.Category.OFFENSIVE
			"repeatable": bad.repeatable = true
			"weight": bad.weight = 0
			"rank_values": bad.rank_values = PackedFloat32Array([NAN])
		check(not bad.foundation_errors().is_empty(), "malformed categories/ranks/weights must be rejected: " + change)
	invalid = subset([&"speed"])
	invalid.upgrades.remove_at(1)
	check(not invalid.foundation_errors(CONFIG).is_empty(), "catalogs must define an automatic fallback")
	var random := rng(9)
	var before := random.state
	check(invalid.generate_offers({}, FULL, random, CONFIG).has("errors") and random.state == before, "invalid catalogs must not consume offer RNG")
	check(CATALOG.generate_offers({}, FULL, null, CONFIG).has("errors"), "offers must require an explicit RNG instead of touching a global stream")
	var fractional := definition(&"energy").duplicate() as UpgradeDefinition
	fractional.rank_values = PackedFloat32Array([0.5])
	check(not fractional.foundation_errors().is_empty(), "fractional reward amounts must not become unusable zero-int rewards")

func check_foundation_stats() -> void:
	var build := fresh()
	check(is_equal_approx(build.move_speed(), 180) and is_equal_approx(build.fire_delay, 0.2) and is_equal_approx(build.attraction_radius, 24), "foundation initialization must derive base stats without modifying PlayerStats")
	for id in [&"speed", &"damage", &"fire_rate"]:
		var upgrade := definition(id)
		for rank in range(1, upgrade.max_rank + 1):
			check(build.apply_foundation(id).rank == rank, "accepted foundation ranks must increment exactly once")
			match id:
				&"speed": check(is_equal_approx(build.move_speed(), 180 + 15 * rank), "speed must add fifteen per rank")
				&"damage": check(is_equal_approx(build.direct_damage_multiplier, 1 + 0.25 * rank), "DAMAGE must derive one common multiplier")
				&"fire_rate": check(is_equal_approx(build.fire_delay, 0.2 - 0.016 * rank), "FIRE_RATE must derive the exact manual delay")
		check(build.apply_foundation(id).capped, "maximum ranks must reject further increments")
	check(is_equal_approx(build.move_speed(), 240) and is_equal_approx(build.fire_delay, 0.12), "new caps must exist only in explicit foundation mode")
	check(is_equal_approx(build.direct_damage_multiplier, 2.25) and is_equal_approx(build.damage_bonus, 1.25), "gun multiplier and plasma additive adapter must remain distinct")
	check(not build.can_apply_foundation(&"orb_magnet"), "three occupied utility slots must reject the fourth family")
	check(build.foundation_snapshot().utility_count == 3, "increasing ranks must not consume more slots")
	for rank in range(1, 5):
		check(build.apply_foundation(&"side_shot").applied, "an offensive may be acquired with full utility slots")
		check(is_equal_approx(build.side_base_damage, [0.4, 0.6, 0.8, 1.0][rank - 1]), "side-shot damage must use authored bases")
		check(build.outer_side_pair == (rank == 4), "only side rank four must enable the outer pair")
	check(build.side_shot and build.rank_for(UpgradeDefinition.Effect.SIDE_SHOT) == 4 and build.side_damage_bonus == 0.0, "foundation adapters must not double-apply legacy side damage")
	var snapshot := build.foundation_snapshot()
	snapshot.ranks[&"side_shot"] = 99
	snapshot.stats.direct_damage_multiplier = 99
	check(build.rank_for(UpgradeDefinition.Effect.SIDE_SHOT) == 4 and is_equal_approx(build.direct_damage_multiplier, 2.25), "mutating a build snapshot must not mutate its owner")
	build.reset()
	check(build.acquired_ranks.is_empty() and build.ranks.is_empty() and not build.side_shot and build.foundation_snapshot().utility_count == 0, "reset must clear personal families, enum adapters and slots")
	check(is_equal_approx(build.direct_damage_multiplier, 1) and is_equal_approx(build.attraction_radius, 24), "reset must recompute base derived stats")
	for rank in range(1, 5):
		build.apply_foundation(&"orb_magnet")
		check(is_equal_approx(build.attraction_radius, 24 + 24 * rank), "attraction must derive its authored radius up to 120")
	var invalid := CONFIG.duplicate() as ProgressionConfig
	invalid.utility_slots = 0
	check(not build.initialize_foundation(invalid, CATALOG.upgrades) and build.acquired_ranks.get(&"orb_magnet") == 4, "failed initialization must retain the existing valid build")
	check(not build.apply_foundation(&"missing").applied, "unknown upgrades cannot occupy slots")

func check_rewards_and_capacity() -> void:
	var build := fresh()
	check(not build.can_apply_foundation(&"energy", FULL) and not build.can_apply_foundation(&"shield", FULL), "full vitals must suppress reward offers")
	check(not build.can_apply_foundation(&"energy") and not build.can_apply_foundation(&"shield"), "missing vital snapshots must not grant rewards")
	var vitals := {"energy": 11, "shield": 2}
	var repair := build.apply_foundation(&"energy", vitals)
	var shield := build.apply_foundation(&"shield", vitals)
	check(repair.applied and repair.reward.value == 12 and repair.reward.amount == 1, "repair must clamp immediately to twelve")
	check(shield.applied and shield.reward.value == 3 and shield.reward.amount == 1, "shield must add one charge up to three")
	check(vitals == {"energy": 11, "shield": 2}, "reward application must return updates without mutating caller-owned vitals")
	for index in 5:
		check(build.apply_foundation(&"energy", {"energy": 3}).reward.value == 5, "repairs must remain repeatable without acquiring ranks")
	check(build.acquired_ranks.is_empty() and build.ranks.is_empty() and build.foundation_snapshot().utility_count == 0, "repeatable consumables must never occupy family slots")
	check(not build.apply_foundation(&"score").applied, "score fallback must never be manually applied as a normal family/reward")
	var utilities: Array[StringName] = [&"speed", &"damage", &"fire_rate", &"orb_magnet", &"beam_capacity", &"beam_recharge"]
	for a in utilities.size():
		for b in range(a + 1, utilities.size()):
			for c in range(b + 1, utilities.size()):
				build = fresh()
				for id in [utilities[a], utilities[b], utilities[c]]:
					check(build.apply_foundation(id).applied, "every valid three-utility combination must fit")
				var hand := CATALOG.generate_offers(build.foundation_snapshot(), FULL, rng(7), CONFIG)
				for id in utilities:
					if not build.acquired_ranks.has(id):
						check(not build.apply_foundation(id).applied and not ids(hand).has(id), "full utility slots must reject every unacquired family in application and offers")
	var extended := CATALOG.duplicate(true) as UpgradeTable
	for index in range(4):
		var extra := definition(&"side_shot").duplicate() as UpgradeDefinition
		extra.id = StringName("test_offensive_%d" % index)
		extra.effect = UpgradeDefinition.Effect.PIERCING + index
		extended.upgrades.append(extra)
	check(extended.foundation_errors(CONFIG).is_empty(), "synthetic future families are test fixtures only")
	build = fresh(extended)
	for id in [&"side_shot", &"test_offensive_0", &"test_offensive_1", &"test_offensive_2"]:
		check(build.apply_foundation(id).applied, "four offensive families must fit")
	check(not build.apply_foundation(&"test_offensive_3").applied and build.foundation_snapshot().offensive_count == 4, "a fifth offensive cannot replace an existing slot")
	check(build.apply_foundation(&"side_shot").applied and build.foundation_snapshot().offensive_count == 4, "an acquired family may increase rank at full capacity")
	check(not ids(extended.generate_offers(build.foundation_snapshot(), FULL, rng(11), CONFIG)).has(&"test_offensive_3"), "full offensive slots must also filter new-family offers")

func check_offer_policy() -> void:
	var build := fresh()
	for seed_value in range(100):
		var random := rng(seed_value)
		var hand := CATALOG.generate_offers(build.foundation_snapshot(), {"energy": 3, "shield": 0}, random, CONFIG, true)
		var names := ids(hand)
		check(names.size() == 3 and names.has(&"side_shot") and hand.fallback_score == 0, "first selection must offer an offensive when available")
		var utility_count := 0
		var seen := {}
		for offer in hand.offers:
			utility_count += int(offer.category == UpgradeDefinition.Category.UTILITY)
			seen[offer.id] = true
			check(build.can_apply_foundation(offer.id, {"energy": 3, "shield": 0}), "every drawn offer must be personally eligible")
		check(utility_count > 0 and seen.size() == 3, "first offers must reserve a utility and have distinct IDs")
		var state := random.state
		var copy: Dictionary = hand.offers[0].duplicate(true)
		copy.rank_values[0] = 999
		copy.next_value = 999
		check(random.state == state and definition(hand.offers[0].id).rank_value(1) < 999, "presentation snapshots must not mutate authored values or consume RNG")
	build.apply_foundation(&"damage")
	for first_selection in [false, true]:
		for seed_value in range(100):
			var hand := CATALOG.generate_offers(build.foundation_snapshot(), FULL, rng(seed_value), CONFIG, first_selection)
			var has_new := false
			var has_acquired := false
			for offer in hand.offers:
				has_new = has_new or offer.current_rank == 0
				has_acquired = has_acquired or offer.current_rank > 0
			check(has_new and has_acquired and ids(hand).has(&"damage"), "acquired/new guarantees must coexist with first-selection category guarantees")
	for count in [1, 2]:
		var names: Array[StringName] = [&"speed"]
		if count == 2:
			names.append(&"side_shot")
		var table := subset(names)
		var small_build := fresh(table)
		var hand := table.generate_offers(small_build.foundation_snapshot(), FULL, rng(1), CONFIG)
		check(hand.offers.size() == names.size() and hand.fallback_score == 0, "one/two useful candidates must remain one/two without salvage competition")
	var exhausted := subset([&"speed"])
	var capped := fresh(exhausted)
	for rank in 4:
		capped.apply_foundation(&"speed")
	var random := rng(9)
	var before := random.state
	var fallback := exhausted.generate_offers(capped.foundation_snapshot(), FULL, random, CONFIG)
	check(fallback.offers.is_empty() and fallback.fallback_score == 500 and random.state == before, "zero candidates alone must return automatic 500 score without drawing RNG")
	var reward_only := subset([&"energy", &"shield"])
	var reward_build := fresh(reward_only)
	check(reward_only.generate_offers(reward_build.foundation_snapshot(), FULL, rng(1), CONFIG).fallback_score == 500, "inapplicable rewards must not compete with automatic fallback")
	check(reward_only.generate_offers(reward_build.foundation_snapshot(), {"energy": 11, "shield": 3}, rng(1), CONFIG).offers.size() == 1, "only applicable repeatable rewards may appear")
	var weighted := subset([&"speed", &"energy"])
	var weighted_build := fresh(weighted)
	for seed_value in range(50):
		var expected_rng := rng(seed_value)
		var expected_id := &"speed" if expected_rng.randi_range(1, 15) <= 10 else &"energy"
		var hand := weighted.generate_offers(weighted_build.foundation_snapshot(), {"energy": 3}, rng(seed_value), CONFIG)
		check(hand.offers[0].id == expected_id, "family/reward draws must use the exact authored 10:5 weights")

func check_beam_stats() -> void:
	var build := fresh()
	check(is_equal_approx(build.beam_capacity, 100) and is_equal_approx(build.plasma_pickup_multiplier, 1), "base beam values must preserve the native reserve and cell charge")
	for rank in range(1, 4):
		check(build.apply_foundation(&"beam_capacity").rank == rank, "reserve family must support three ranks")
		check(build.apply_foundation(&"beam_recharge").rank == rank, "cell recovery family must support three ranks")
		check(is_equal_approx(build.beam_capacity, 100 + 25 * rank) and is_equal_approx(build.plasma_pickup_multiplier, 1 + 0.25 * rank), "beam stats must use authored rank totals rather than compound multipliers")
	check(build.apply_foundation(&"beam_capacity").capped and build.apply_foundation(&"beam_recharge").capped, "maximum beam ranks must reject overflow")
	check(build.foundation_snapshot().utility_count == 2 and build.foundation_snapshot().offensive_count == 0, "beam upgrades must occupy utility slots while leaving the signature outside offensive slots")
	check(is_equal_approx(build.direct_damage_multiplier, 1) and is_equal_approx(build.damage_bonus, 0), "charge upgrades must not increase weapon damage")
	var snapshot := build.foundation_snapshot()
	check(is_equal_approx(snapshot.stats.beam_capacity, 175) and is_equal_approx(snapshot.stats.plasma_pickup_multiplier, 1.75), "detached build snapshots must expose derived beam values")
	build.reset()
	check(is_equal_approx(build.beam_capacity, 100) and is_equal_approx(build.plasma_pickup_multiplier, 1) and build.acquired_ranks.is_empty(), "run reset must clear beam families and derived values")

func trace(seed_value: int, reverse_players := false, unrelated_noise := false) -> Array:
	var streams := RunRandom.new(seed_value)
	var p1 := fresh()
	var p2 := fresh()
	p2.apply_foundation(&"orb_magnet")
	var result := []
	for level in range(2, 20):
		if unrelated_noise:
			for index in 12:
				streams.encounters.randi()
				streams.enemies.randi()
				streams.drops.randi()
		var p1_view := {"build": p1.foundation_snapshot(), "vitals": FULL.duplicate()}
		var p2_view := {"build": p2.foundation_snapshot(), "vitals": {"energy": 5, "shield": 1}}
		var participants := {&"player2": p2_view, &"player1": p1_view} if reverse_players else {&"player1": p1_view, &"player2": p2_view}
		var hands := CATALOG.generate_player_offers(participants, streams.upgrades, CONFIG, level == 2)
		result.append([ids(hands.player1), ids(hands.player2)])
		for id in [&"player2", &"player1"] if reverse_players else [&"player1", &"player2"]:
			var hand: Dictionary = hands[id]
			if not hand.offers.is_empty():
				var owner := p1 if id == &"player1" else p2
				check(owner.apply_foundation(hand.offers[0].id, participants[id].vitals).applied, "replayed choices must remain personally applicable")
	result.append([p1.foundation_snapshot(), p2.foundation_snapshot()])
	return result

func check_determinism_and_queue() -> void:
	for seed_value in range(10):
		check(trace(seed_value) == trace(seed_value, true, true), "same seed/decisions must survive participant insertion/confirmation order and unrelated RNG noise")
	var p1 := fresh()
	var p2 := fresh()
	p2.apply_foundation(&"side_shot")
	p2.apply_foundation(&"speed")
	p2.apply_foundation(&"damage")
	p2.apply_foundation(&"fire_rate")
	var participants := {&"player2": {"build": p2.foundation_snapshot(), "vitals": FULL}, &"player1": {"build": p1.foundation_snapshot(), "vitals": FULL}}
	var random := rng(17)
	var no_players_state := random.state
	check(CATALOG.generate_player_offers({}, random, CONFIG).is_empty() and random.state == no_players_state, "zero participants must not draw or alter offer RNG")
	var solo_p2 := CATALOG.generate_player_offers({&"player2": participants.player2}, rng(17), CONFIG, true)
	check(solo_p2.size() == 1 and solo_p2.player2 == CATALOG.generate_offers(p2.foundation_snapshot(), FULL, rng(17), CONFIG, true), "a remaining P2 must receive a personal hand without a synthetic P1 draw")
	var hands := CATALOG.generate_player_offers(participants, random, CONFIG, true)
	var expected_rng := rng(17)
	var expected_p1 := CATALOG.generate_offers(p1.foundation_snapshot(), FULL, expected_rng, CONFIG, true)
	var expected_p2 := CATALOG.generate_offers(p2.foundation_snapshot(), FULL, expected_rng, CONFIG, true)
	check(hands.player1 == expected_p1 and hands.player2 == expected_p2 and random.state == expected_rng.state, "co-op hands must always draw P1 before P2")
	check(ids(hands.player1) != ids(hands.player2), "different personal builds may produce different hands from shared progression")
	var old_p2: Dictionary = hands.player2.duplicate(true)
	p1.apply_foundation(hands.player1.offers[0].id)
	check(hands.player2 == old_p2 and p2.rank_for(UpgradeDefinition.Effect.SIDE_SHOT) == 1, "one player's choice must not mutate the already-drawn other hand/build")
	var progression := RunProgression.new(CONFIG)
	var table := subset([&"speed"])
	var build := fresh(table)
	progression.add_xp(100)
	var choices := 0
	var score := 0
	while progression.pending_count() > 0:
		progression.take_selection_level()
		var hand := table.generate_offers(build.foundation_snapshot(), FULL, random, CONFIG)
		if hand.offers.is_empty():
			score += hand.fallback_score
		else:
			choices += 1
			build.apply_foundation(hand.offers[0].id)
	check(choices == 4 and score == 500 and progression.xp == 13, "each queued level must recompute eligibility after prior choices without losing XP")

func run() -> void:
	check_data_and_legacy()
	check_foundation_stats()
	check_rewards_and_capacity()
	check_offer_policy()
	check_beam_stats()
	check_determinism_and_queue()
	print("Upgrade offers: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

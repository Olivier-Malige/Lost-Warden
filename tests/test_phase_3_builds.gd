extends SceneTree

const CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")
const CATALOG: UpgradeTable = preload("res://data/upgrades/foundation_catalog.tres")
const STATS: PlayerStats = preload("res://data/player/player_stats.tres")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func triples(items: Array[UpgradeDefinition]) -> Array:
	var sets: Array = []
	for a in items.size():
		for b in range(a + 1, items.size()):
			for c in range(b + 1, items.size()):
				sets.append([items[a], items[b], items[c]])
	return sets

func run() -> void:
	var offensives: Array[UpgradeDefinition] = []
	var utilities: Array[UpgradeDefinition] = []
	for upgrade in CATALOG.upgrades:
		if upgrade.category == UpgradeDefinition.Category.OFFENSIVE: offensives.append(upgrade)
		if upgrade.category == UpgradeDefinition.Category.UTILITY: utilities.append(upgrade)
	check(CONFIG.offensive_slots == 3 and CONFIG.utility_slots == 3, "current slot contract remains three plus three")
	check(offensives.size() == 9 and utilities.size() == 10, "full current catalog contains nine offensive and ten utility families")
	var offensive_sets := triples(offensives)
	var utility_sets := triples(utilities)
	var samples := 0
	for offensive in offensive_sets:
		for utility in utility_sets:
			var build := PlayerLoadout.new(STATS)
			check(build.initialize_foundation(CONFIG, CATALOG.upgrades), "full catalog initializes")
			var selected: Array = offensive + utility
			for upgrade in selected:
				for rank in upgrade.max_rank:
					check(build.apply_foundation(upgrade.id).applied, "every selected rank applies within legal capacity")
				check(not build.apply_foundation(upgrade.id).applied, "maximum ranks reject extra acquisition")
			var snapshot := build.foundation_snapshot()
			check(snapshot.offensive_count == 3 and snapshot.utility_count == 3 and snapshot.ranks.size() == 6, "every maximal cross-product build occupies exactly six families")
			for upgrade in CATALOG.upgrades:
				if upgrade.is_family() and upgrade not in selected:
					check(not build.apply_foundation(upgrade.id).applied, "unowned families cannot bypass either full category")
			var random := RandomNumberGenerator.new()
			random.seed = 1400 + samples
			var state := random.state
			var hand := CATALOG.generate_offers(snapshot, {"energy": 12}, random, CONFIG)
			check(hand.offers.is_empty() and hand.fallback_score == 500, "fully ranked and healthy builds use automatic score fallback")
			random.state = state
			check(hand == CATALOG.generate_offers(snapshot, {"energy": 12}, random, CONFIG), "same seed and build reproduce the complete offer snapshot")
			for kind in PlayerHitSnapshot.Kind.values():
				var hit := PlayerHitSnapshot.new(&"player1", samples, 2.0, 4.5, build.acquired_ranks, kind, true)
				for modifier in PlayerHitSnapshot.COMBAT_MODIFIERS:
					var expected := int(build.acquired_ranks.get(modifier, 0)) if PlayerHitSnapshot.allows_modifier(kind, modifier) else 0
					check(hit.modifier_rank(modifier) == expected, "all legal builds obey the centralized source policy")
				check(hit.is_critical() == PlayerHitSnapshot.allows_modifier(kind, &"critical_hits"), "source policy also controls direct critical flags")
			build.reset()
			check(build.acquired_ranks.is_empty(), "run reset clears each maximal build")
			check(snapshot.ranks.size() == 6, "previous build snapshots remain immutable after reset")
			samples += 1
		await process_frame
	var report := {"offensive_sets": offensive_sets.size(), "utility_sets": utility_sets.size(), "cross_product": samples, "checks": checks, "failures": failures}
	var output := FileAccess.open("user://phase_3_builds.json", FileAccess.WRITE)
	if output:
		output.store_string(JSON.stringify(report, "\t"))
		output.close()
	else:
		check(false, "build evidence file must be writable in the isolated validation project")
	print("Phase 3 legal builds: %s" % JSON.stringify(report))
	quit(1 if failures else 0)

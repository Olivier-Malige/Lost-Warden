extends SceneTree

const CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")
var enemies := {}
var runs: Array = []
var failures := 0

func _initialize() -> void:
	call_deferred("run")

# Screen reward-only candidates on fixed materialization traces before an expensive full rerun.
func run() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://xp_economy.json"))
	var enemy_script: Script = load("res://scenes/enemies/enemy.gd")
	for name_value in ["drone", "tie", "interceptor", "turret", "mother_ship", "mother_ship_turret", "asteroid", "big_asteroid"]:
		var definition: EnemyDefinition = load("res://data/enemies/%s.tres" % name_value).duplicate()
		var enemy: Variant = enemy_script.new()
		enemy.definition = definition
		enemies[String(definition.id)] = enemy
	for item in report.runs:
		if item.profile != "perfect":
			continue
		var random := RunRandom.new(int(item.seed)).drops
		var kills: Array = []
		for spawn in item.spawn_trace:
			if int(spawn[0]) + 60 > 18000:
				continue
			kills.append({"tick": int(spawn[0]) + 180, "family": spawn[1],
				"elite": spawn[5], "fragment": spawn[6], "roll": random.randi_range(0, 99)})
			random.randi_range(0, 99)
		if str(random.state) != item.final_rng.drops or kills.size() != int(item.kills):
			failures += 1
			push_error("Candidate replay must preserve the actual drop stream and kill count.")
		runs.append({"seed": item.seed, "mode": item.mode, "kills": kills,
			"baseline_emitted": item.emitted, "baseline_selections": item.selections})
	var candidates: Array = []
	candidates.append(evaluate(45, 35, 2, true))
	for common in [20, 25, 30, 35, 40, 45]:
		for asteroid in [20, 35, 50]:
			for large in [1, 2, 3]:
				candidates.append(evaluate(common, asteroid, large))
	candidates.sort_custom(func(a, b): return a.solo_missed_distance < b.solo_missed_distance)
	var output := FileAccess.open("user://xp_economy_candidates.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"kind": "fixed-trace-reward-projection", "failures": failures,
		"seed_count": report.seed_count, "candidates": candidates}, "\t"))
	for index in mini(5, candidates.size()):
		print(JSON.stringify(candidates[index]))
	for enemy in enemies.values():
		enemy.free()
	print("Candidate replay: %d failures" % failures)
	quit(1 if failures else 0)

func evaluate(common: int, asteroid: int, large: int, baseline := false) -> Dictionary:
	enemies.razor_wing.definition.xp_drop_chance = common
	enemies.razor_fighter.definition.xp_drop_chance = common
	enemies.asteroid_small.definition.xp_drop_chance = asteroid
	enemies.asteroid_large.definition.xp_value = large
	var groups := {}
	for item in runs:
		for missed in [false, true]:
			var key: String = item.mode + ("_missed" if missed else "_perfect")
			if not groups.has(key):
				groups[key] = [[], [], [], [], []]
			var progression := RunProgression.new(CONFIG)
			var selections: Array = []
			var emitted := 0
			var sequence := 0
			for kill in item.kills:
				var enemy: Variant = enemies[kill.family]
				enemy.elite = kill.elite
				enemy._spawn_context.asteroid_fragment = kill.fragment
				var amount: int = enemy._xp_for_roll(kill.roll)
				if amount <= 0:
					continue
				emitted += amount
				sequence += 1
				if kill.tick > 18000 or (missed and sequence % 5 == 0):
					continue
				for level in progression.add_xp(amount):
					selections.append(float(kill.tick) / 60.0)
			if baseline and not missed:
				var actual_ticks := selections.map(func(value): return roundi(value * 60.0))
				var expected_ticks: Array = item.baseline_selections.map(func(value): return roundi(value * 60.0))
				if emitted != int(item.baseline_emitted) or actual_ticks != expected_ticks:
					failures += 1
					push_error("Baseline reward replay must reproduce measured XP and choice timestamps.")
			for index in 5:
				groups[key][index].append(selections[index] - (selections[index - 1] if index else 0.0) if selections.size() > index else INF)
	var result := {"common_chance": common, "asteroid_chance": asteroid, "large_value": large, "medians": {}}
	for key in groups:
		var medians: Array = []
		for values in groups[key]:
			values.sort()
			medians.append(values[ceili(values.size() * 0.5) - 1])
		result.medians[key] = medians
	var distance := 0.0
	for index in 5:
		var value: float = result.medians.solo_missed[index]
		distance += maxf((20.0 if index == 0 else 35.0) - value, 0.0) + maxf(value - (25.0 if index == 0 else 50.0), 0.0)
	result.solo_missed_distance = distance
	return result

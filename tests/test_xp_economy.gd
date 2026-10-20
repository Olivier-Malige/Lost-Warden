extends SceneTree

const VERSION := 1
const CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")
const CATALOG: UpgradeTable = preload("res://data/upgrades/foundation_catalog.tres")
const STATS: PlayerStats = preload("res://data/player/player_stats.tres")
const PRIORITY := [&"side_shot", &"damage", &"fire_rate", &"speed", &"orb_magnet", &"energy", &"shield"]
const DURATION_TICKS := 18000

class FallProbePool extends Node:
	var released := false
	func living_players() -> Array:
		return []
	func release(_orb: Node) -> void:
		released = true

var checks := 0
var failures := 0
var globals: Node
var events: Node
var spawner: Variant
var orb_probe: Variant
var probe_pool: FallProbePool
var progression: RunProgression
var participants := {}
var vitals := {}
var orbs: Array[Dictionary] = []
var trace := {}
var current_tick := 0
var missed_profile := false
var sequence := 0
var seed_count := 100
var fall_cache := {}

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.set_process(false)
	root.size = Vector2i(640, 400)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seeds="):
			seed_count = clampi(argument.trim_prefix("--seeds=").to_int(), 1, 100)
	probe_pool = FallProbePool.new()
	root.add_child(probe_pool)
	orb_probe = load("res://scenes/progression/xp_orb.tscn").instantiate()
	root.add_child(orb_probe)
	orb_probe.pool = probe_pool
	orb_probe.process_mode = Node.PROCESS_MODE_DISABLED
	events.xp_spawn_requested.connect(on_xp)
	events.encounter_started.connect(on_encounter)
	var results: Array = []
	var started := Time.get_ticks_msec()
	for coop in [false, true]:
		for missed in [false, true]:
			for seed_value in seed_count:
				var first := simulate(seed_value, coop, missed)
				var repeated := simulate(seed_value, coop, missed)
				check(first == repeated, "traces must repeat: %s/%s/%d" % [coop, missed, seed_value])
				results.append(first)
				if seed_value % 10 == 9:
					print("XP economy: %s / %s / %d seeds" % ["coop" if coop else "solo", "miss-every-fifth" if missed else "perfect", seed_value + 1])
					await process_frame
	var report := {"fixture_version": VERSION, "godot": Engine.get_version_info().string,
		"seed_count": seed_count, "seconds": 300, "step": "1/60", "repeats": 2,
		"elapsed_wall_seconds": float(Time.get_ticks_msec() - started) / 1000.0,
		"groups": summarize(results), "runs": results}
	var path := "user://xp_economy.json"
	var output := FileAccess.open(path, FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print(JSON.stringify(report.groups, "\t"))
	print("XP economy evidence: %s" % ProjectSettings.globalize_path(path))
	print("XP economy: %d checks, %d failures" % [checks, failures])
	orb_probe.free()
	probe_pool.free()
	quit(1 if failures else 0)

func simulate(seed_value: int, coop: bool, missed: bool) -> Dictionary:
	globals.coop = coop
	globals.reset_run(seed_value)
	missed_profile = missed
	current_tick = 0
	sequence = 0
	orbs.clear()
	participants.clear()
	vitals.clear()
	progression = RunProgression.new(CONFIG)
	for id in ([&"player1", &"player2"] if coop else [&"player1"]):
		var build := PlayerLoadout.new(STATS)
		check(build.initialize_foundation(CONFIG, CATALOG.upgrades), "fresh personal build")
		participants[id] = build
		vitals[id] = {"energy": STATS.starting_energy, "shield": 0}
	trace = {"seed": seed_value, "mode": "coop" if coop else "solo", "profile": "miss-every-fifth" if missed else "perfect",
		"encounters": [], "selections": [], "choices": [], "orb_trace": [],
		"emitted": 0, "collected": 0, "offscreen_lost": 0, "active": 0, "cancelled": 0,
		"missed_events": 0, "missed_value": 0, "peak_orbs": 0}
	spawner = load("res://tests/fixtures/xp_economy_spawner.gd").new()
	spawner.config = load("res://data/waves/wave_spawner_config.tres")
	spawner.catalog = load("res://data/waves/wave_catalog.tres")
	# Use authored world marker coordinates, including the spawner's transform.
	var world_state: SceneState = load("res://scenes/world/world.tscn").get_state()
	for index in world_state.get_node_count():
		var name_value := String(world_state.get_node_name(index))
		if name_value == "waveGenerator" or name_value.begins_with("spawnPos"):
			var position_value := Vector2.ZERO
			for property in world_state.get_node_property_count(index):
				if world_state.get_node_property_name(index, property) == &"position":
					position_value = world_state.get_node_property_value(index, property)
			if name_value == "waveGenerator":
				spawner.position = position_value
			else:
				var marker := Marker2D.new()
				marker.name = name_value
				marker.position = position_value
				spawner.add_child(marker)
	root.add_child(spawner)
	spawner.process_mode = Node.PROCESS_MODE_DISABLED
	spawner.start_run()
	for tick in range(1, DURATION_TICKS + 1):
		current_tick = tick
		spawner.tick = tick
		spawner.advance()
		advance_orbs()
	trace.level = progression.level
	trace.xp_remainder = progression.xp
	trace.orb_events = sequence
	trace.kills = spawner.kills
	trace.fragments = spawner.fragments
	trace.spawn_trace = spawner.spawn_trace.duplicate(true)
	trace.final_rng = {}
	for key in ["encounters", "enemies", "drops", "upgrades"]:
		trace.final_rng[key] = str(globals.run_random.get(key).state)
	for orb in orbs:
		trace.active += orb.amount
	check(trace.emitted == trace.collected + trace.offscreen_lost + trace.active + trace.cancelled, "XP accounting must close")
	check(trace.missed_events == floori(float(sequence) / 5.0) if missed else trace.missed_events == 0, "stable missed-event schedule")
	check(trace.peak_orbs < 128, "projection must remain below the shipped pool's merge cap")
	check(progression.pending_count() == 0, "scripted choices must resolve without ticking gameplay")
	check(is_equal_approx(spawner.director.elapsed, 300.0), "all clocks stop at 300 simulation seconds")
	spawner.stop_run()
	spawner.free()
	return trace.duplicate(true)

func on_encounter(id: StringName, number: int) -> void:
	trace.encounters.append([current_tick, String(id), number])

func on_xp(amount: int, point: Vector2) -> void:
	sequence += 1
	var missed := missed_profile and sequence % 5 == 0
	orbs.append({"sequence": sequence, "amount": amount, "position": point,
		"collect_at": current_tick + 120, "missed": missed,
		"lost_at": current_tick + fall_ticks(point.y)})
	trace.emitted += amount
	trace.missed_events += int(missed)
	trace.missed_value += amount if missed else 0
	trace.peak_orbs = maxi(trace.peak_orbs, orbs.size())
	trace.orb_trace.append([current_tick, sequence, amount, point.x, point.y, missed])

# Sample the shipped orb script once per starting height; fixture targets never attract missed orbs.
func fall_ticks(height: float) -> int:
	if fall_cache.has(height):
		return fall_cache[height]
	orb_probe.position = Vector2(320, height)
	orb_probe.set_meta("pooled", false)
	probe_pool.released = false
	var ticks := 0
	while not probe_pool.released and ticks < DURATION_TICKS:
		orb_probe._physics_process(1.0 / 60.0)
		ticks += 1
	check(probe_pool.released, "an unattracted orb must eventually leave the viewport")
	fall_cache[height] = ticks
	return ticks

func advance_orbs() -> void:
	for orb in orbs.duplicate():
		if current_tick >= orb.lost_at:
			trace.offscreen_lost += orb.amount
			orbs.erase(orb)
		elif not orb.missed and current_tick >= orb.collect_at:
			trace.collected += orb.amount
			progression.add_xp(orb.amount)
			orbs.erase(orb)
			resolve_choices()

func resolve_choices() -> void:
	while progression.pending_count() > 0:
		var level := progression.take_selection_level()
		trace.selections.append(float(current_tick) / 60.0)
		var snapshots := {}
		for id in participants:
			snapshots[id] = {"build": participants[id].foundation_snapshot(), "vitals": vitals[id].duplicate()}
		var hands := CATALOG.generate_player_offers(snapshots, globals.run_random.upgrades, CONFIG, level == 2)
		for id in hands:
			var hand: Dictionary = hands[id]
			var ids: Array[StringName] = []
			for offer in hand.offers:
				ids.append(offer.id)
			if ids.is_empty():
				check(hand.fallback_score == 500, "only empty real offers use score fallback")
				trace.choices.append([level, String(id), "score", ids])
				continue
			ids.sort()
			var chosen := ids[0]
			for preferred in PRIORITY:
				if preferred in ids:
					chosen = preferred
					break
			var result: Dictionary = participants[id].apply_foundation(chosen, vitals[id])
			check(result.applied, "scripted choice must be eligible")
			if not result.reward.is_empty():
				vitals[id]["energy" if result.reward.effect == UpgradeDefinition.Effect.ENERGY else "shield"] = result.reward.value
			trace.choices.append([level, String(id), String(chosen), ids])

# Missing samples are right-censored at the remaining observation window, never discarded.
func distribution(values: Array, censored: Array) -> Dictionary:
	var ordered := values.duplicate()
	ordered.sort()
	var result := {"observed": values.size(), "censored": censored.size(), "censor_windows": censored}
	for fraction in [0.1, 0.5, 0.9]:
		var rank := ceili(fraction * seed_count)
		var value: Variant = ordered[rank - 1] if rank <= ordered.size() else null
		var certain := value != null
		if certain:
			for window in censored:
				if window < value:
					certain = false
		result[str(fraction)] = value if certain else "censored"
	return result

func summarize(results: Array) -> Array:
	var groups: Array = []
	for mode in ["solo", "coop"]:
		for profile in ["perfect", "miss-every-fifth"]:
			var group := {"mode": mode, "profile": profile, "cadence": []}
			for observation in 5:
				var values: Array = []
				var censored: Array = []
				for item in results:
					if item.mode != mode or item.profile != profile:
						continue
					if item.selections.size() > observation:
						values.append(item.selections[observation] - (item.selections[observation - 1] if observation else 0.0))
					else:
						censored.append(300.0 - (item.selections[observation - 1] if observation and item.selections.size() == observation else 300.0 if observation else 0.0))
				group.cadence.append(distribution(values, censored))
			groups.append(group)
	return groups

class_name EncounterDirector
extends RefCounted

enum State { REGULAR, BOSS, RECOVERY, BOSS_APPROACH }

var random: RunRandom
var elapsed := 0.0
var regular_elapsed := 0.0
var next_boss_at := 300.0
var danger_offset := 0.0
var state := State.REGULAR
var recovery_left := 0.0
var encounter_left := 0.0
var encounter: WaveDefinition
var recent: Array[StringName] = []
var previous_boss: StringName
var encounter_number := 0
var victories := 0
var survival_combat_time := 0.0
var recent_families: Array[int] = []
var survival_encounters := 0
var encounters_since_hunt := 4
var elite_due := false
var introduced: Array[StringName] = []

var _enemy_health_curve: Curve

func _init(streams: RunRandom, enemy_health_curve: Curve = preload("res://data/waves/enemy_health_progression.tres")) -> void:
	random = streams
	_enemy_health_curve = enemy_health_curve

func advance(delta: float) -> void:
	delta = maxf(delta, 0.0)
	elapsed += delta
	if state == State.REGULAR:
		regular_elapsed += delta
		if victories > 0:
			survival_combat_time += delta
		encounter_left -= delta
	elif state == State.RECOVERY:
		recovery_left = maxf(recovery_left - delta, 0.0)
		if recovery_left <= 0.0:
			state = State.REGULAR
			encounter_left = 0.0

func danger() -> float:
	return maxf(1.0, danger_at(elapsed) + danger_offset)

static func danger_at(seconds: float) -> float:
	var times := [0.0, 120.0, 300.0, 480.0, 600.0, 720.0]
	var values := [1.0, 1.4, 2.4, 3.4, 4.2, 5.0]
	for index in range(1, times.size()):
		if seconds <= times[index]:
			return lerpf(values[index - 1], values[index], inverse_lerp(times[index - 1], times[index], seconds))
	return 5.0 + (seconds - 720.0) / 60.0 * 0.2

func elite_chance() -> float:
	if elapsed < 120.0:
		return 0.0
	var times := [120.0, 180.0, 300.0, 480.0, 720.0]
	var values := [0.0, 0.05, 0.10, 0.18, 0.25]
	for index in range(1, times.size()):
		if elapsed <= times[index]:
			return lerpf(values[index - 1], values[index], inverse_lerp(times[index - 1], times[index], elapsed))
	return 0.25

func choose_encounter(waves: Array[WaveDefinition], lane_count: int = 12) -> WaveDefinition:
	if state != State.REGULAR:
		return null
	var eligible: Array[WaveDefinition] = []
	var phase_four := waves.any(func(wave: WaveDefinition) -> bool: return wave != null and wave.family == WaveDefinition.Family.REENTRY)
	var wants_coordination := phase_four and victories > 0 and survival_tier() >= 5 \
		and random.encounters.randf() < minf(0.5, 0.1 * (survival_tier() - 4))
	var alternatives: Array[WaveDefinition] = []
	for wave in waves:
		if wave == null or not wave.is_encounter_valid(lane_count) or wave.selection_weight <= 0.0:
			continue
		if wave.minimum_combat_time > regular_elapsed or wave.minimum_survival_time > survival_combat_time:
			continue
		if phase_four and victories > 0:
			if wave.family == WaveDefinition.Family.OPENING:
				continue
			if survival_encounters == 0 and wave.family != WaveDefinition.Family.REENTRY:
				continue
			if survival_encounters > 0 and wave.family == WaveDefinition.Family.REENTRY:
				continue
			if encounters_since_hunt >= 4 and survival_encounters > 0 and wave.family != WaveDefinition.Family.ELITE_HUNT:
				continue
		elif wave.family != WaveDefinition.Family.OPENING:
			continue
		if wave.minimum_danger <= danger() and (victories > 0 or danger() <= wave.maximum_danger):
			eligible.append(wave)
			if wave.id not in recent:
				alternatives.append(wave)
	if phase_four and victories > 0:
		var fresh := eligible.filter(func(wave: WaveDefinition) -> bool: return wave.family not in recent_families)
		if not fresh.is_empty():
			eligible = fresh
		if survival_tier() >= 5:
			var coordinated := eligible.filter(func(wave: WaveDefinition) -> bool: return wave.coordinated == wants_coordination)
			if not coordinated.is_empty():
				eligible = coordinated
		var variants := eligible.filter(func(wave: WaveDefinition) -> bool: return wave.id not in recent)
		if not variants.is_empty():
			eligible = variants
	elif phase_four and victories == 0:
		var introductions := eligible.filter(func(wave: WaveDefinition) -> bool: return wave.minimum_combat_time > 0.0 and wave.id not in introduced)
		if not introductions.is_empty():
			eligible = introductions
		elif not alternatives.is_empty():
			eligible = alternatives
	elif not alternatives.is_empty():
		eligible = alternatives
	if eligible.is_empty():
		return null
	var weights := PackedFloat32Array()
	for wave in eligible:
		weights.append(wave.selection_weight)
	encounter = eligible[random.encounters.rand_weighted(weights)]
	if encounter.minimum_combat_time > 0.0 and encounter.id not in introduced:
		introduced.append(encounter.id)
	recent.append(encounter.id)
	if recent.size() > 2:
		recent.pop_front()
	if phase_four and victories > 0:
		survival_encounters += 1
		recent_families.append(encounter.family)
		if recent_families.size() > 2:
			recent_families.pop_front()
		if encounter.family == WaveDefinition.Family.ELITE_HUNT:
			elite_due = true
			encounters_since_hunt = 0
		elif encounter.family != WaveDefinition.Family.REENTRY:
			encounters_since_hunt += 1
	encounter_left = encounter.duration
	encounter_number += 1
	return encounter

func boss_due() -> bool:
	return state == State.REGULAR and regular_elapsed >= next_boss_at

func choose_boss(bosses: Array[BossDefinition], force := false) -> BossDefinition:
	if state != State.REGULAR or (not force and not boss_due()):
		return null
	var eligible: Array[BossDefinition] = []
	var alternatives: Array[BossDefinition] = []
	for boss in bosses:
		if boss != null and boss.is_valid() and boss.minimum_danger <= danger() and (victories > 0 or danger() <= boss.maximum_danger) and boss.selection_weight > 0.0:
			eligible.append(boss)
			if boss.id != previous_boss:
				alternatives.append(boss)
	if not alternatives.is_empty():
		eligible = alternatives
	if eligible.is_empty():
		return null
	var weights := PackedFloat32Array()
	for boss in eligible:
		weights.append(boss.selection_weight)
	var chosen := eligible[random.encounters.rand_weighted(weights)]
	previous_boss = chosen.id
	state = State.BOSS if force else State.BOSS_APPROACH
	return chosen

func boss_entered() -> void:
	if state == State.BOSS_APPROACH:
		state = State.BOSS

func boss_defeated() -> void:
	if state != State.BOSS:
		return
	victories += 1
	next_boss_at = regular_elapsed + 300.0
	state = State.RECOVERY
	recovery_left = 8.0

func health_multiplier(maximum := 1.20) -> float:
	return lerpf(1.0, maximum, clampf(_enemy_health_curve.sample(regular_elapsed), 0.0, 1.0))

func speed_multiplier() -> float:
	return lerpf(1.0, 1.2, _scaling_progress())

func fire_delay_multiplier() -> float:
	return lerpf(1.0, 0.8, _scaling_progress())

func encounter_budget() -> float:
	if not encounter:
		return 0.0
	if encounter.family == WaveDefinition.Family.OPENING:
		return encounter.threat_budget * danger()
	return encounter.threat_budget * (1.0 + 0.15 * survival_tier())

func survival_tier() -> int:
	return floori(survival_combat_time / 180.0)

func formation_interval_scale() -> float:
	return maxf(0.6, 1.0 - 0.08 * survival_tier())

func _scaling_progress() -> float:
	return clampf((danger() - 1.0) / 4.0, 0.0, 1.0)

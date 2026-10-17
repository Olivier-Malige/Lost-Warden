class_name EncounterDirector
extends RefCounted

enum State { REGULAR, BOSS, RECOVERY }

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

func _init(streams: RunRandom) -> void:
	random = streams

func advance(delta: float) -> void:
	delta = maxf(delta, 0.0)
	elapsed += delta
	if state == State.REGULAR:
		regular_elapsed += delta
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
	var alternatives: Array[WaveDefinition] = []
	for wave in waves:
		if wave != null and wave.is_encounter_valid(lane_count) and wave.minimum_danger <= danger() and danger() <= wave.maximum_danger and wave.selection_weight > 0.0:
			eligible.append(wave)
			if wave.id not in recent:
				alternatives.append(wave)
	if not alternatives.is_empty():
		eligible = alternatives
	if eligible.is_empty():
		return null
	var weights := PackedFloat32Array()
	for wave in eligible:
		weights.append(wave.selection_weight)
	encounter = eligible[random.encounters.rand_weighted(weights)]
	recent.append(encounter.id)
	if recent.size() > 2:
		recent.pop_front()
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
		if boss != null and boss.is_valid() and boss.minimum_danger <= danger() and danger() <= boss.maximum_danger and boss.selection_weight > 0.0:
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
	state = State.BOSS
	return chosen

func boss_defeated() -> void:
	if state != State.BOSS:
		return
	next_boss_at = regular_elapsed + 300.0
	state = State.RECOVERY
	recovery_left = 8.0

func health_multiplier() -> float:
	return lerpf(1.0, 1.5, _scaling_progress())

func speed_multiplier() -> float:
	return lerpf(1.0, 1.2, _scaling_progress())

func fire_delay_multiplier() -> float:
	return lerpf(1.0, 0.8, _scaling_progress())

func encounter_budget() -> float:
	return encounter.threat_budget * danger() if encounter else 0.0

func _scaling_progress() -> float:
	return clampf((danger() - 1.0) / 4.0, 0.0, 1.0)

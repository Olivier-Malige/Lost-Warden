class_name PlayerLoadout
extends RefCounted

var stats: PlayerStats
var speed_bonus := 0.0
var fire_delay: float
var damage_bonus := 0.0
var side_shot := false
var side_damage_bonus := 0.0
var ranks: Dictionary[int, int] = {}
var acquired_ranks: Dictionary[StringName, int] = {}
var _foundation_config: ProgressionConfig
var _foundation_definitions: Dictionary[StringName, UpgradeDefinition] = {}
var direct_damage_multiplier := 1.0
var side_base_damage := 0.0
var attraction_radius := 0.0
var outer_side_pair := false
var beam_capacity := 100.0
var plasma_pickup_multiplier := 1.0
var critical_chance := 0.0
var beam_extra_targets := 0
var beam_damage_multiplier := 1.0
var beam_width_multiplier := 1.0

func _init(p_stats: PlayerStats) -> void:
	stats = p_stats
	reset()

func reset() -> void:
	speed_bonus = 0.0
	fire_delay = stats.shoot_delay_base
	damage_bonus = 0.0
	side_shot = false
	side_damage_bonus = 0.0
	ranks.clear()
	acquired_ranks.clear()
	direct_damage_multiplier = 1.0
	side_base_damage = 0.0
	attraction_radius = 0.0
	outer_side_pair = false
	beam_capacity = stats.beam_charge_max
	plasma_pickup_multiplier = 1.0
	critical_chance = 0.0
	beam_extra_targets = 0
	beam_damage_multiplier = 1.0
	beam_width_multiplier = 1.0
	if _foundation_config != null:
		_derive_foundation_stats()

func apply(upgrade: UpgradeDefinition) -> UpgradeResult:
	if _foundation_config != null:
		var result := apply_foundation(upgrade.id)
		return UpgradeResult.new(result.applied, result.rank, upgrade.max_rank, result.capped)
	var rank := rank_for(upgrade.effect)
	if rank >= upgrade.max_rank:
		return UpgradeResult.new(false, rank, upgrade.max_rank, true)
	rank += 1
	ranks[upgrade.effect] = rank
	match upgrade.effect:
		UpgradeDefinition.Effect.SPEED:
			speed_bonus += upgrade.value
		UpgradeDefinition.Effect.FIRE_RATE:
			fire_delay -= upgrade.value
		UpgradeDefinition.Effect.DAMAGE:
			damage_bonus += upgrade.value
		UpgradeDefinition.Effect.SIDE_SHOT:
			side_shot = true
			if rank > 1:
				side_damage_bonus += upgrade.value
		UpgradeDefinition.Effect.SHIELD, UpgradeDefinition.Effect.ENERGY:
			pass
	fire_delay = maxf(fire_delay, stats.shoot_delay_min)
	speed_bonus = minf(speed_bonus, stats.speed_max - stats.speed)
	return UpgradeResult.new(true, rank, upgrade.max_rank, false)

func rank_for(effect: int) -> int:
	return int(ranks.get(effect, 0))

func move_speed() -> float:
	return stats.speed + speed_bonus

func initialize_foundation(config: ProgressionConfig, definitions: Array[UpgradeDefinition]) -> bool:
	if config == null or not config.validation_errors().is_empty():
		return false
	var registered: Dictionary[StringName, UpgradeDefinition] = {}
	var effects: Dictionary = {}
	for upgrade in definitions:
		if upgrade == null or not upgrade.foundation_errors().is_empty():
			return false
		if registered.has(upgrade.id) or effects.has(upgrade.effect):
			return false
		registered[upgrade.id] = upgrade
		effects[upgrade.effect] = true
	_foundation_config = config
	_foundation_definitions = registered
	reset()
	return true

func foundation_snapshot() -> Dictionary:
	var offensive_count := 0
	var utility_count := 0
	var families: Array[Dictionary] = []
	for id in acquired_ranks:
		var upgrade := _foundation_definitions[id]
		families.append({"id": id, "category": upgrade.category, "rank": acquired_ranks[id], "icon": upgrade.icon, "display_name": upgrade.display_name})
		if upgrade.category == UpgradeDefinition.Category.OFFENSIVE:
			offensive_count += 1
		elif upgrade.category == UpgradeDefinition.Category.UTILITY:
			utility_count += 1
	return {
		"ranks": acquired_ranks.duplicate(),
		"families": families,
		"offensive_count": offensive_count, "utility_count": utility_count,
		"offensive_capacity": _foundation_config.offensive_slots if _foundation_config else 0,
		"utility_capacity": _foundation_config.utility_slots if _foundation_config else 0,
		"stats": {
			"move_speed": move_speed(), "manual_delay": fire_delay,
			"direct_damage_multiplier": direct_damage_multiplier, "side_base_damage": side_base_damage,
			"attraction_radius": attraction_radius, "outer_side_pair": outer_side_pair,
			"plasma_damage_bonus": damage_bonus,
			"beam_capacity": beam_capacity, "plasma_pickup_multiplier": plasma_pickup_multiplier,
			"critical_chance": critical_chance,
			"beam_extra_targets": beam_extra_targets, "beam_damage_multiplier": beam_damage_multiplier,
			"beam_width_multiplier": beam_width_multiplier,
		},
	}

func can_apply_foundation(id: StringName, vitals: Dictionary = {}) -> bool:
	if _foundation_config == null or not _foundation_definitions.has(id):
		return false
	return _foundation_definitions[id].is_eligible(foundation_snapshot(), vitals, _foundation_config)

# Rewards describe a vital-state update; the controller remains responsible for applying it.
func apply_foundation(id: StringName, vitals: Dictionary = {}) -> Dictionary:
	var rank := int(acquired_ranks.get(id, 0))
	var result := {"applied": false, "rank": rank, "capped": false, "reward": {}}
	if _foundation_config == null or not _foundation_definitions.has(id):
		return result
	var upgrade := _foundation_definitions[id]
	result.capped = upgrade.is_family() and rank >= upgrade.max_rank
	if not can_apply_foundation(id, vitals):
		return result
	result.applied = true
	if upgrade.is_family():
		acquired_ranks[id] = rank + 1
		result.rank = rank + 1
		_derive_foundation_stats()
	else:
		var key := "energy" if upgrade.effect == UpgradeDefinition.Effect.ENERGY else "shield"
		var maximum := _foundation_config.energy_max if key == "energy" else _foundation_config.shield_max
		var current := int(vitals[key])
		var next := mini(current + int(upgrade.rank_value(1)), maximum)
		result.reward = {"effect": upgrade.effect, "amount": next - current, "value": next}
	return result

func _foundation_value(effect: int) -> float:
	for id in _foundation_definitions:
		var upgrade := _foundation_definitions[id]
		if upgrade.effect == effect:
			return upgrade.rank_value(int(acquired_ranks.get(id, 0)))
	return 0.0

func _derive_foundation_stats() -> void:
	ranks.clear()
	for id in acquired_ranks:
		ranks[_foundation_definitions[id].effect] = acquired_ranks[id]
	speed_bonus = clampf(
		_foundation_config.speed_base + _foundation_value(UpgradeDefinition.Effect.SPEED),
		_foundation_config.speed_base, _foundation_config.speed_max
	) - stats.speed
	fire_delay = maxf(
		_foundation_config.manual_delay_base - _foundation_value(UpgradeDefinition.Effect.FIRE_RATE),
		_foundation_config.manual_delay_min
	)
	damage_bonus = _foundation_value(UpgradeDefinition.Effect.DAMAGE)
	direct_damage_multiplier = 1.0 + damage_bonus
	side_shot = rank_for(UpgradeDefinition.Effect.SIDE_SHOT) > 0
	side_base_damage = _foundation_value(UpgradeDefinition.Effect.SIDE_SHOT)
	side_damage_bonus = 0.0
	outer_side_pair = rank_for(UpgradeDefinition.Effect.SIDE_SHOT) >= 4
	attraction_radius = minf(
		_foundation_config.attraction_base + _foundation_value(UpgradeDefinition.Effect.ORB_MAGNET),
		_foundation_config.attraction_max
	)
	beam_capacity = stats.beam_charge_max + _foundation_value(UpgradeDefinition.Effect.BEAM_CAPACITY)
	plasma_pickup_multiplier = 1.0 + _foundation_value(UpgradeDefinition.Effect.BEAM_RECHARGE)
	critical_chance = _foundation_value(UpgradeDefinition.Effect.CRITICAL_HITS)
	beam_extra_targets = int(_foundation_value(UpgradeDefinition.Effect.BEAM_PIERCING))
	beam_damage_multiplier = 1.0
	beam_width_multiplier = 1.0
	for id in _foundation_definitions:
		var definition := _foundation_definitions[id]
		if definition.effect == UpgradeDefinition.Effect.BEAM_PIERCING:
			beam_damage_multiplier += definition.damage_bonus(int(acquired_ranks.get(id, 0)))
			beam_width_multiplier += definition.width_bonus(int(acquired_ranks.get(id, 0)))

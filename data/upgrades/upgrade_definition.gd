class_name UpgradeDefinition
extends Resource

enum Effect {
	SPEED, FIRE_RATE, DAMAGE, SIDE_SHOT, SHIELD, ENERGY,
	ORB_MAGNET, SCORE, PIERCING, CRITICAL_HITS, MICRO_MISSILES, ESCORT_DRONE,
	ORBITING_SATELLITES, IMPACT_EXPLOSIONS, ENERGY_CHAINS, RICOCHET,
	BEAM_CAPACITY, BEAM_RECHARGE, BEAM_PIERCING,
}
enum Category { UTILITY, OFFENSIVE, REWARD, FALLBACK }

@export var id: StringName
@export var effect: Effect = Effect.SPEED
@export var anim: StringName
@export var weight: int = 10
@export var value: float = 1.0
@export var max_rank: int = 0
@export var hud_label: StringName

@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var category: Category = Category.UTILITY
@export var repeatable: bool = false
@export var rank_values: PackedFloat32Array = []
@export var damage_bonus_values: PackedFloat32Array = []
@export var width_bonus_values: PackedFloat32Array = []
@export var range_values: PackedFloat32Array = []
@export var secondary_damage_scale := 0.0
@export var proc_cooldown := 0.0
@export var weapon: WeaponDefinition
@export var interval_values: PackedFloat32Array = []
@export var projectile_counts: PackedInt32Array = []
@export var support_counts: PackedInt32Array = []

func support_count(rank: int) -> int:
	return support_counts[mini(rank, support_counts.size()) - 1] if rank > 0 and not support_counts.is_empty() else 0

func projectile_count(rank: int) -> int:
	return projectile_counts[mini(rank, projectile_counts.size()) - 1] if rank > 0 and not projectile_counts.is_empty() else 0

func interval_value(rank: int) -> float:
	return interval_values[mini(rank, interval_values.size()) - 1] if rank > 0 and not interval_values.is_empty() else 0.0

func range_value(rank: int) -> float:
	return range_values[mini(rank, range_values.size()) - 1] if rank > 0 and not range_values.is_empty() else 0.0

func damage_bonus(rank: int) -> float:
	return damage_bonus_values[mini(rank, damage_bonus_values.size()) - 1] if rank > 0 and not damage_bonus_values.is_empty() else 0.0

func width_bonus(rank: int) -> float:
	return width_bonus_values[mini(rank, width_bonus_values.size()) - 1] if rank > 0 and not width_bonus_values.is_empty() else 0.0

func rank_value(rank: int) -> float:
	if rank <= 0 or rank_values.is_empty():
		return 0.0
	return rank_values[mini(rank, rank_values.size()) - 1]

func is_family() -> bool:
	return category == Category.UTILITY or category == Category.OFFENSIVE

func foundation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"" or display_name.is_empty() or description.is_empty():
		errors.append("Foundation upgrades require an ID, display name and description.")
	if weight <= 0 or max_rank <= 0 or rank_values.size() != max_rank:
		errors.append("Foundation weights and ranks must be positive and fully authored.")
	var previous := 0.0
	for amount in rank_values:
		if not is_finite(amount) or amount <= 0.0 or amount < previous:
			errors.append("Authored rank values must be finite, positive and nondecreasing.")
		previous = amount
	var expected := Category.OFFENSIVE
	if effect < Effect.SPEED or effect > Effect.BEAM_PIERCING:
		errors.append("Unknown foundation effect.")
	match effect:
		Effect.SPEED, Effect.FIRE_RATE, Effect.DAMAGE, Effect.ORB_MAGNET, Effect.BEAM_CAPACITY, Effect.BEAM_RECHARGE, Effect.BEAM_PIERCING:
			expected = Category.UTILITY
		Effect.ENERGY, Effect.SHIELD:
			expected = Category.REWARD
		Effect.SCORE:
			expected = Category.FALLBACK
	if category != expected or repeatable != (category == Category.REWARD):
		errors.append("Foundation categories and repeatable rewards must match their effects.")
	if effect == Effect.BEAM_PIERCING:
		for bonuses in [damage_bonus_values, width_bonus_values]:
			if bonuses.size() != max_rank:
				errors.append("Beam piercing requires authored damage and width bonuses for every rank.")
			var previous_bonus := 0.0
			for bonus in bonuses:
				if not is_finite(bonus) or bonus <= 0.0 or bonus < previous_bonus:
					errors.append("Beam bonuses must be positive, finite and nondecreasing.")
				previous_bonus = bonus
	if effect == Effect.ENERGY_CHAINS:
		if range_values.size() != max_rank or not is_finite(secondary_damage_scale) or secondary_damage_scale <= 0.0 or not is_finite(proc_cooldown) or proc_cooldown <= 0.0:
			errors.append("Energy chains require authored ranges, positive damage scale and cooldown.")
		var previous_range := 0.0
		for radius in range_values:
			if not is_finite(radius) or radius <= 0.0 or radius < previous_range:
				errors.append("Chain ranges must be finite, positive and nondecreasing.")
			previous_range = radius
		for jumps in rank_values:
			if jumps != roundf(jumps) or jumps > 3.0:
				errors.append("Chain jump budgets must be whole numbers, at most three.")
	if effect == Effect.ESCORT_DRONE:
		if support_counts.size() != max_rank:
			errors.append("Escort drones require an authored support count at every rank.")
		var previous_supports := 0
		for count in support_counts:
			if count < 1 or count > 2 or count < previous_supports:
				errors.append("Escort counts must be nondecreasing and bounded to two companions.")
			previous_supports = count
		if weapon == null or weapon.kind != WeaponDefinition.Kind.DRONE_BOLT or weapon.projectile == null:
			errors.append("Escort drones require their authored bolt weapon and projectile.")
		elif weapon.active_limit <= 0 or weapon.active_limit > 6 or not is_finite(weapon.target_range) or weapon.target_range <= 0.0 or not is_finite(weapon.projectile_speed) or weapon.projectile_speed <= 0.0 or not is_finite(weapon.projectile_lifetime) or weapon.projectile_lifetime <= 0.0:
			errors.append("Drone bolt range, speed, lifetime and capacity must be positive and bounded.")
		if weapon != null and (not is_finite(weapon.forward_angle_degrees) or weapon.forward_angle_degrees <= 0.0 or weapon.forward_angle_degrees > 180.0):
			errors.append("Drone targeting requires a finite forward cone no wider than 180 degrees.")
	if effect == Effect.MICRO_MISSILES or effect == Effect.ESCORT_DRONE:
		if interval_values.size() != max_rank:
			errors.append("Autonomous weapons require an authored interval for every rank.")
		var previous_interval := INF
		for interval in interval_values:
			if not is_finite(interval) or interval <= 0.0 or interval > previous_interval:
				errors.append("Autonomous intervals must be positive, finite and nonincreasing.")
			previous_interval = interval
	if effect == Effect.MICRO_MISSILES:
		if projectile_counts.size() != max_rank:
			errors.append("Micro-missiles require an authored volley count for every rank.")
		var previous_count := 0
		for count in projectile_counts:
			if count <= 0 or count > 3 or count < previous_count:
				errors.append("Missile volley counts must increase within the three-missile cap.")
			previous_count = count
		if weapon == null or weapon.kind != WeaponDefinition.Kind.MICRO_MISSILE or weapon.projectile == null:
			errors.append("Micro-missiles require their authored weapon and projectile.")
		elif weapon.active_limit <= 0 or weapon.active_limit > 3 or not is_finite(weapon.target_range) or weapon.target_range <= 0.0 or not is_finite(weapon.projectile_speed) or weapon.projectile_speed <= 0.0 or not is_finite(weapon.turn_speed_degrees) or weapon.turn_speed_degrees <= 0.0 or not is_finite(weapon.projectile_lifetime) or weapon.projectile_lifetime <= 0.0:
			errors.append("Missile guidance, lifetime and capacity must be positive and bounded.")
		if weapon != null:
			if not is_finite(weapon.forward_angle_degrees) or weapon.forward_angle_degrees <= 0.0 or weapon.forward_angle_degrees > 180.0:
				errors.append("Missile targeting requires a finite forward cone no wider than 180 degrees.")
			if weapon.collision_sizes.size() != max_rank or weapon.collision_offsets.size() != max_rank:
				errors.append("Every missile size requires matching collision dimensions and offsets.")
			for size in weapon.collision_sizes:
				if not size.is_finite() or size.x <= 0.0 or size.y <= 0.0:
					errors.append("Missile collision sizes must be positive and finite.")
			for offset in weapon.collision_offsets:
				if not offset.is_finite(): errors.append("Missile collision offsets must be finite.")
	if not is_family() and max_rank != 1:
		errors.append("Rewards require one authored value and no acquired ranks.")
	if not is_family() and not rank_values.is_empty() and not is_equal_approx(rank_values[0], roundf(rank_values[0])):
		errors.append("Reward amounts must be whole numbers.")
	return errors

func is_eligible(build: Dictionary, vitals: Dictionary, config: ProgressionConfig) -> bool:
	if is_family():
		var rank := int(build.get("ranks", {}).get(id, 0))
		if rank < 0 or rank >= max_rank:
			return false
		var count_key := "offensive_count" if category == Category.OFFENSIVE else "utility_count"
		var capacity := config.offensive_slots if category == Category.OFFENSIVE else config.utility_slots
		return rank > 0 or int(build.get(count_key, 0)) < capacity
	if category == Category.REWARD:
		var key := "energy" if effect == Effect.ENERGY else "shield"
		var maximum := config.energy_max if effect == Effect.ENERGY else config.shield_max
		var current := int(vitals.get(key, maximum))
		return current >= 0 and current < maximum
	return false

func offer_snapshot(rank: int) -> Dictionary:
	var next_rank := rank + 1 if is_family() else 1
	return {
		"id": id, "effect": effect, "category": category,
		"display_name": display_name, "description": description, "icon": icon,
		"repeatable": repeatable, "current_rank": rank, "next_rank": next_rank,
		"max_rank": max_rank, "current_value": rank_value(rank),
		"next_value": rank_value(next_rank), "rank_values": rank_values.duplicate(),
		"next_damage_bonus": damage_bonus(next_rank),
		"next_width_bonus": width_bonus(next_rank),
		"next_range": range_value(next_rank),
		"secondary_damage_scale": secondary_damage_scale, "proc_cooldown": proc_cooldown,
		"next_interval": interval_value(next_rank),
		"next_projectile_count": projectile_count(next_rank),
		"next_support_count": support_count(next_rank),
	}

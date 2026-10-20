class_name UpgradeDefinition
extends Resource

enum Effect {
	SPEED, FIRE_RATE, DAMAGE, SIDE_SHOT, SHIELD, ENERGY,
	ORB_MAGNET, SCORE, PIERCING, CRITICAL_HITS, MICRO_MISSILES, ESCORT_DRONE,
	ORBITING_SATELLITES, IMPACT_EXPLOSIONS, ENERGY_CHAINS, RICOCHET,
	BEAM_CAPACITY, BEAM_RECHARGE,
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
	if effect < Effect.SPEED or effect > Effect.BEAM_RECHARGE:
		errors.append("Unknown foundation effect.")
	match effect:
		Effect.SPEED, Effect.FIRE_RATE, Effect.DAMAGE, Effect.ORB_MAGNET, Effect.BEAM_CAPACITY, Effect.BEAM_RECHARGE:
			expected = Category.UTILITY
		Effect.ENERGY, Effect.SHIELD:
			expected = Category.REWARD
		Effect.SCORE:
			expected = Category.FALLBACK
	if category != expected or repeatable != (category == Category.REWARD):
		errors.append("Foundation categories and repeatable rewards must match their effects.")
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
	}

class_name EnemyDefinition
extends Resource

enum Durability { HAZARD, FODDER, FIGHTER, SPECIALIST, HEAVY }

@export_group("Combat")
@export_range(1, 10000, 1) var max_health := 1
@export_range(0, 10000, 1) var collision_damage := 1
@export_range(0, 1000000, 1) var score := 0
@export var durability: Durability = Durability.FODDER
@export_range(0, 100, 1) var power_up_chance := 0
@export_range(0, 100, 1) var plasma_drop_chance := 0

@export_group("Movement")
@export var movement_profile: MovementProfile

@export_group("Drops")
@export var drops_on_destroy := false
@export var drop_scene: PackedScene
@export_range(0, 100, 1) var drop_count := 1
@export_range(0.0, 1000.0, 1.0) var drop_range := 64.0

@export_group("Presentation")
@export_range(1, 64, 1) var sprite_variants := 1

func is_valid() -> bool:
	return max_health > 0 \
		and collision_damage >= 0 \
		and score >= 0 \
		and power_up_chance >= 0 \
		and plasma_drop_chance >= 0 \
		and power_up_chance + plasma_drop_chance <= 100 \
		and movement_profile != null \
		and movement_profile.is_valid() \
		and sprite_variants > 0 \
		and (not drops_on_destroy or drop_scene != null)

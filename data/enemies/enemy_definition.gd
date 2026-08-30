class_name EnemyDefinition
extends Resource

enum Durability { HAZARD, FODDER, FIGHTER, SPECIALIST, HEAVY }

@export_group("Combat")
@export_range(1, 10000, 1) var max_health := 1
@export_range(0, 10000, 1) var collision_damage := 1
@export_range(0, 1000000, 1) var score := 0
@export var durability: Durability = Durability.FODDER
@export_range(0, 100, 1) var power_up_chance := 0

@export_group("Movement")
@export var speed := Vector2.ZERO
@export var random_speed := Vector2.ZERO
@export_range(0.0, 500.0, 1.0) var lateral_amplitude := 0.0
@export_range(0.0, 5.0, 0.05) var lateral_frequency := 0.0
@export var rotates := false
@export var rotation_speed := 0.0
@export var random_rotation := false
@export var random_rotation_min := -1.0
@export var random_rotation_max := 1.0

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
		and power_up_chance <= 100 \
		and lateral_amplitude >= 0.0 \
		and lateral_frequency >= 0.0 \
		and sprite_variants > 0 \
		and (not drops_on_destroy or drop_scene != null)

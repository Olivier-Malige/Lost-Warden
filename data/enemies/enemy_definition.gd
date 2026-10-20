class_name EnemyDefinition
extends Resource

enum Durability { HAZARD, FODDER, FIGHTER, SPECIALIST, HEAVY }

@export_group("Encounter director")
@export var id: StringName
@export var threat_cost := 1.0
@export var minimum_danger := 1.0
@export var maximum_danger := 1000.0
@export var selection_weight := 1.0
@export var danger_weight_growth := 0.0
@export var elite_eligible := true
@export var elite_texture: Texture2D
@export var elite_frame_grid := Vector2i.ONE
@export_range(1, 8, 1) var spawn_slots := 1
@export_range(0, 100, 1) var active_limit := 0

@export_group("Combat")
@export_range(1, 10000, 1) var max_health := 1
@export_range(0, 10000, 1) var collision_damage := 1
@export_range(0, 1000000, 1) var score := 0
@export var durability: Durability = Durability.FODDER
@export_range(0, 100, 1) var power_up_chance := 0
@export_range(0, 100, 1) var plasma_drop_chance := 0
@export_range(0, 100, 1) var xp_drop_chance := 0
@export_range(0, 1000, 1) var xp_value := 0

@export_group("Movement")
@export var movement_profile: MovementProfile

@export_group("Drops")
@export var drops_on_destroy := false
@export var drop_scene: PackedScene
@export_range(0, 100, 1) var drop_count := 1
@export_range(0.0, 1000.0, 1.0) var drop_range := 32.0

@export_group("Presentation")
@export_range(1, 64, 1) var sprite_variants := 1
@export var bank_on_turn := false

func weight_at(danger: float) -> float:
	if danger < minimum_danger or danger > maximum_danger:
		return 0.0
	return maxf(selection_weight + danger_weight_growth * (danger - minimum_danger), 0.0)

func is_valid() -> bool:
	return id != &"" and threat_cost > 0.0 and spawn_slots > 0 and active_limit >= 0 \
		and minimum_danger >= 1.0 and maximum_danger >= minimum_danger \
		and selection_weight >= 0.0 and danger_weight_growth >= 0.0 \
		and max_health > 0 \
		and collision_damage >= 0 \
		and score >= 0 \
		and power_up_chance >= 0 \
		and plasma_drop_chance >= 0 \
		and plasma_drop_chance <= 100 \
		and xp_drop_chance >= 0 and xp_drop_chance <= 100 and xp_value >= 0 \
		and movement_profile != null \
		and movement_profile.is_valid() \
		and sprite_variants > 0 \
		and elite_frame_grid.x > 0 and elite_frame_grid.y > 0 \
		and (not drops_on_destroy or drop_scene != null)

class_name EnemyDefinition
extends Resource

enum Durability { HAZARD, FODDER, FIGHTER, SPECIALIST, HEAVY }

@export_group("Combat")
@export var max_health := 1
@export var collision_damage := 1
@export var score := 0
@export var durability: Durability = Durability.FODDER
@export var power_up_chance := 0

@export_group("Movement")
@export var speed := Vector2.ZERO
@export var random_speed := Vector2.ZERO
@export var rotates := false
@export var rotation_speed := 0.0
@export var random_rotation := false
@export var random_rotation_min := -1.0
@export var random_rotation_max := 1.0

@export_group("Drops")
@export var drops_on_destroy := false
@export var drop_scene: PackedScene
@export var drop_count := 1
@export var drop_range := 64.0

@export_group("Presentation")
@export var sprite_variants := 1

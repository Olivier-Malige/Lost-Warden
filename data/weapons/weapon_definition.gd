class_name WeaponDefinition
extends Resource

enum Kind { PRIMARY, SIDE, MICRO_MISSILE, DRONE_BOLT }

@export var id: StringName
@export var kind: Kind = Kind.PRIMARY
@export var projectile: PackedScene
@export var damage: float = 1.0
@export var fire_delay: float = 0.18
@export var target_range := 0.0
@export_range(1.0, 180.0, 1.0) var forward_angle_degrees := 90.0
@export var projectile_speed := 0.0
@export var turn_speed_degrees := 0.0
@export var projectile_lifetime := 0.0
@export var active_limit := 0
@export var collision_sizes: PackedVector2Array = []
@export var collision_offsets: PackedVector2Array = []

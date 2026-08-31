class_name PlayerStats
extends Resource

@export var shoot_delay_base: float = 0.18
@export var shoot_delay_min: float = 0.13
@export var speed: float = 360.0
@export var malus_speed: float = 100.0
@export_range(0.1, 1.0, 0.01) var weapon_speed_multiplier: float = 1.0
@export var energy_max: int = 12
@export_range(1, 100, 1) var starting_energy: int = 4
@export var speed_max: float = 450.0
@export var bound_min := Vector2(118, 24)
@export var bound_max := Vector2(948, 784)
@export var beam_mini: float = 0.45
@export var beam_normal: float = 1.05
@export var beam_full: float = 2.1

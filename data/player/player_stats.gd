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

@export_group("Plasma beam")
@export_range(0.0, 100.0, 0.5) var beam_charge_start := 0.0
@export_range(1.0, 100.0, 0.5) var beam_charge_max := 100.0
@export_range(0.0, 100.0, 0.5) var beam_activation_min := 10.0
@export_range(0.1, 100.0, 0.5) var beam_drain_per_second := 20.0
@export_range(0.01, 1.0, 0.01) var beam_damage_interval := 0.1
@export_range(0.1, 100.0, 0.1) var beam_damage := 3.0
@export_range(1.0, 256.0, 1.0) var beam_width := 32.0
@export_range(1.0, 256.0, 1.0) var beam_overdrive_width := 64.0
@export_range(1.0, 2.0, 0.05) var beam_collision_width_multiplier := 1.2
@export_range(1.0, 10.0, 0.1) var beam_overdrive_damage_multiplier := 1.5
@export_range(0.0, 10.0, 0.1) var beam_overdrive_duration := 1.0

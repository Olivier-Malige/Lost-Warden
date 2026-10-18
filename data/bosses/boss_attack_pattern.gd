class_name BossAttackPattern
extends Resource

enum Kind { AIMED, RINGS, SPIRAL, DRONES, BEAM }

@export var kind: Kind = Kind.AIMED
@export var projectile_count := 5
@export var burst_count := 3
@export var burst_interval := 0.25
@export var projectile_speed := 230.0
@export var angular_step_degrees := 7.0
@export var gap_degrees := 45.0
@export var gap_offset_degrees := 35.0
@export var telegraph_time := 0.6
@export var recovery_time := 0.4

func is_valid() -> bool:
	for value in [telegraph_time, recovery_time, burst_interval, projectile_speed, angular_step_degrees, gap_degrees, gap_offset_degrees]:
		if not is_finite(value):
			return false
	if kind < Kind.AIMED or kind > Kind.BEAM or telegraph_time <= 0.0 or recovery_time <= 0.0:
		return false
	if kind in [Kind.DRONES, Kind.BEAM]:
		return true
	if projectile_count < 1 or burst_count < 1 or burst_interval <= 0.0 or projectile_speed <= 0.0:
		return false
	if angular_step_degrees <= 0.0:
		return false
	if kind == Kind.RINGS:
		return projectile_count >= 8 and gap_degrees >= 30.0 and gap_degrees < 180.0
	return true

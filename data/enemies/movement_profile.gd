class_name MovementProfile
extends Resource

enum Mode {
	STRAIGHT,
	SINE,
	SMOOTH_ZIGZAG,
	STRAFE,
	DRIFT,
	PATROL_EXIT,
}

@export var id: StringName
@export var mode: Mode = Mode.STRAIGHT
@export var velocity := Vector2.ZERO

@export_group("Horizontal motion")
@export_range(0.0, 500.0, 1.0) var horizontal_speed := 0.0
@export_range(0.0, 500.0, 1.0) var horizontal_speed_min := 0.0
@export_range(0.0, 500.0, 1.0) var horizontal_speed_max := 0.0
@export_range(0.0, 500.0, 1.0) var acceleration := 0.0
@export_range(0.05, 20.0, 0.05) var turn_interval := 1.0
@export_range(0.0, 500.0, 1.0) var amplitude := 0.0
@export_range(0.05, 20.0, 0.05) var period := 1.0
@export_range(0.0, 2000.0, 1.0) var min_x := 0.0
@export_range(0.0, 2000.0, 1.0) var max_x := 1066.0
@export var synchronize_formation := false

@export_group("Patrol")
@export_range(0.0, 2000.0, 1.0) var entry_y := 0.0
@export_range(0.0, 60.0, 0.05) var patrol_duration := 0.0

@export_group("Rotation")
@export var random_rotation := false
@export var rotation_speed_min := 0.0
@export var rotation_speed_max := 0.0

func is_valid() -> bool:
	if id.is_empty() or max_x < min_x or horizontal_speed_max < horizontal_speed_min:
		return false
	match mode:
		Mode.SINE:
			return amplitude > 0.0 and period > 0.0
		Mode.SMOOTH_ZIGZAG:
			return horizontal_speed > 0.0 and acceleration > 0.0 and turn_interval > 0.0
		Mode.STRAFE:
			return horizontal_speed > 0.0
		Mode.DRIFT:
			return horizontal_speed_min > 0.0 and horizontal_speed_max >= horizontal_speed_min
		Mode.PATROL_EXIT:
			return horizontal_speed > 0.0 and patrol_duration > 0.0
		_:
			return true

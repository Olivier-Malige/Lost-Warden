class_name SpawnRule
extends Resource

enum Pattern {
	SINGLE,
	LINE,
	V,
	ALTERNATING_EDGES,
	SCATTER,
	OFFSET_GROUP,
}

@export var scene: PackedScene
@export_range(0.05, 60.0, 0.05) var interval: float = 1.0
@export var weight: float = 1.0
@export_range(0, 31, 1) var spawn_min: int = 0
@export_range(0, 31, 1) var spawn_max: int = 11
@export_range(1, 16, 1) var formation: int = 1
@export_range(0.0, 60.0, 0.05) var start_delay: float = 0.0
@export_range(0.0, 60.0, 0.05) var active_duration: float = 6.0
@export_enum("Single", "Line", "V", "Alternating Edges", "Scatter", "Offset Group") var pattern: int = Pattern.SINGLE
@export_range(1, 12, 1) var lane_spacing: int = 1
@export_range(0.0, 5.0, 0.01) var spawn_gap: float = 0.15
@export_range(0, 1, 1) var elite_count: int = 0

func is_valid(lane_count: int) -> bool:
	return scene != null \
		and interval > 0.0 \
		and active_duration > 0.0 \
		and spawn_min >= 0 \
		and spawn_max >= spawn_min \
		and spawn_max < lane_count

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
@export var interval: float = 1.0
@export var weight: float = 1.0
@export var spawn_min: int = 0
@export var spawn_max: int = 11
@export var formation: int = 1
@export var start_delay: float = 0.0
@export var active_duration: float = 6.0
@export_enum("Single", "Line", "V", "Alternating Edges", "Scatter", "Offset Group") var pattern: int = Pattern.SINGLE
@export var lane_spacing: int = 1
@export var spawn_gap: float = 0.15

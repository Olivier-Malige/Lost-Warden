class_name WaveDefinition
extends Resource

@export_range(1.0, 180.0, 0.5) var duration: float = 30.0
@export_range(0.1, 10.0, 0.05) var difficulty: float = 1.0
@export var rules: Array[SpawnRule] = []

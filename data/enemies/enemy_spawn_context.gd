class_name EnemySpawnContext
extends RefCounted

var health_multiplier := 1.0
var elite := false
var elite_definition: EliteDefinition

func _init(p_health_multiplier := 1.0, p_elite := false, p_elite_definition: EliteDefinition = null) -> void:
	health_multiplier = p_health_multiplier
	elite = p_elite
	elite_definition = p_elite_definition

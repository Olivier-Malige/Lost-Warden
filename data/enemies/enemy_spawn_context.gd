class_name EnemySpawnContext
extends RefCounted

var health_multiplier := 1.0
var elite := false
var elite_definition: EliteDefinition
var speed_multiplier := 1.0
var rule_health_multiplier := 1.0

func _init(p_health_multiplier := 1.0, p_elite := false, p_elite_definition: EliteDefinition = null, p_speed_multiplier := 1.0, p_rule_health_multiplier := 1.0) -> void:
	health_multiplier = p_health_multiplier
	elite = p_elite
	elite_definition = p_elite_definition
	speed_multiplier = p_speed_multiplier
	rule_health_multiplier = p_rule_health_multiplier

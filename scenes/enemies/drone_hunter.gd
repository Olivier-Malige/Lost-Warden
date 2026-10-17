extends Enemy

const CHASE := preload("res://data/enemies/movement/boss_drone_chase.tres")
const ELITE_TEXTURE := preload("res://assets/sprites/enemies/animation_rework/razor_wing_hunter_elite_sheet.png")

func _ready() -> void:
	if _spawn_context.movement_profile == null:
		_spawn_context.movement_profile = CHASE
	super._ready()
	if elite:
		$Sprite2D.texture = ELITE_TEXTURE
		_elite_indicator.hide()

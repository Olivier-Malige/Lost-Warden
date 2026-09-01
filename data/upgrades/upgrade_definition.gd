class_name UpgradeDefinition
extends Resource

enum Effect { SPEED, FIRE_RATE, DAMAGE, SIDE_SHOT, SHIELD, ENERGY }

@export var id: StringName
@export var effect: Effect = Effect.SPEED
@export var anim: StringName
@export var weight: int = 10
@export var value: float = 1.0
@export var max_rank: int = 0
@export var hud_label: StringName

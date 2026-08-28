class_name Shot
extends Area2D

const Layers := preload("res://core/collision_layers.gd")

@export var speedY: int = 0
@export var speedX: int = 0
@warning_ignore("shadowed_variable_base_class")
@export var rotate: bool = false
@export var playerShot: bool = false
var speedRotation := 20 # radians per frame at 60 FPS
var trowbackByShield := false


func _process(delta: float) -> void:
	if rotate:
		rotation += speedRotation * 60.0 * delta
	translate(Vector2(speedX, speedY) * delta)

func _ready() -> void:
	if playerShot:
		add_to_group("player_Shot")
		collision_layer = Layers.PLAYER_SHOT
		collision_mask = Layers.ENEMY | Layers.ASTEROID
	else:
		add_to_group("enemy_Shot")
		collision_layer = Layers.ENEMY_SHOT
		collision_mask = Layers.PLAYER | Layers.ENEMY | Layers.ASTEROID


func _on_screen_exited() -> void:
	if get_meta("pooled", false):
		return
	set_process(false)
	ProjectilePool.despawn(self)

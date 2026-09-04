class_name Shot
extends Area2D

const Layers := preload("res://core/collision_layers.gd")

@export var speedY := 0.0
@export var speedX := 0.0
@warning_ignore("shadowed_variable_base_class")
@export var rotate: bool = false
@export var align_with_velocity := false
@export var playerShot: bool = false
var speedRotation := 20 # radians per frame at 60 FPS
var trowbackByShield := false


func _physics_process(delta: float) -> void:
	var velocity := Vector2(speedX, speedY)
	if align_with_velocity and velocity.length_squared() > 0.0:
		rotation = Vector2.DOWN.angle_to(velocity)
	if rotate:
		rotation += speedRotation * 60.0 * delta
	position += velocity * delta

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
	set_physics_process(false)
	ProjectilePool.despawn(self)

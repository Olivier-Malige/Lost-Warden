class_name PlasmaCell
extends Area2D

const SPEED := 100.0
const Layers := preload("res://core/collision_layers.gd")

@export_range(0.5, 100.0, 0.5) var charge_amount := 12.5

var _collected := false

func _ready() -> void:
	add_to_group(&"plasma_cells")
	collision_layer = Layers.PICKUP
	collision_mask = Layers.PLAYER

func _physics_process(delta: float) -> void:
	translate(Vector2(0.0, SPEED * delta))

func _on_area_entered(area: Area2D) -> void:
	if _collected or not area.is_in_group(&"player"):
		return
	_collected = true
	Events.plasma_collected.emit(charge_amount)
	$PickupSound.play()
	$Sprite2D.visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)

func _on_screen_exited() -> void:
	if not _collected:
		queue_free()

func _on_pickup_sound_finished() -> void:
	queue_free()

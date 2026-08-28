class_name Enemy
extends Area2D
const Layers := preload("res://core/collision_layers.gd")
const PROJECTILE_SPEED_MULTIPLIER := 1.1
@export var dropOnDestroy: bool = false

@export var dropRange: int = 64
@export var objectOnDestroy: PackedScene
@export var nbrObjectOnDestroy: int = 1
@export var nbrSprites = 1
@export var rnd_Roation_Range_Max: float = 1
@export var rnd_Roation_Range_Min: float = -1
@export var life: int = 0
@export var hitSomething: int = 1
@export var points: int = 0
@export var speedX: float = 0
@export var speedY: float = 0
@export var randomX: float = 0
@export var randomY: float = 0
@export var randPowerUp: int = 0 # chance out of 100
@export var setRotation: bool = false
@export var speedRotation: float = 0.0
@export var rndRotation: bool = false
var destroyed := false
var hitByPlayerShot := false
var indexSprites
var bonusCoop := 1.5

func _process(delta: float) -> void:
	hitByPlayerShot = false
	translate(Vector2(speedX, speedY) * delta)
	if setRotation:
		rotation += speedRotation * delta


func _ready() -> void:
	if _is_coop():
		life = int(life * bonusCoop)
	if rndRotation:
		speedRotation = randf_range(rnd_Roation_Range_Min, rnd_Roation_Range_Max)

	speedX = randf_range(speedX - randomX, speedX + randomX)
	speedY = randf_range(speedY - randomY, speedY + randomY)
	add_to_group("enemy")
	collision_layer = Layers.ENEMY
	collision_mask = Layers.PLAYER | Layers.PLAYER_SHOT

	if nbrSprites > 1:
		indexSprites = randi() % nbrSprites + 1
	else:
		indexSprites = ""
	$anim.play("start" + str(indexSprites))

func _hit_something(dmg := 0) -> void:
	if destroyed:
		return
	life -= dmg
	$sound_Hit.playing = true
	var pos = global_position
	pos.y -= 5
	position = pos

	if life <= 0:
		_destroy()
	else:
		$anim.play("hit" + str(indexSprites))


func _on_area_entered(area: Area2D) -> void:
	if not destroyed and area.has_method("_hit_something"):
		area._hit_something(hitSomething)

func _on_screen_exited() -> void:
	set_process(false)
	queue_free()

func _on_anim_animation_finished(n: StringName) -> void:
	if n == "explode":
		set_process(false)
		queue_free()
	elif n == "hit" + str(indexSprites):
		$anim.play("start" + str(indexSprites))

func _drop() -> void:
	for i in range(nbrObjectOnDestroy):
		var objDroped = objectOnDestroy.instantiate()
		objDroped.position = Vector2(position.x + randf_range(-dropRange, dropRange), position.y + randf_range(-dropRange, dropRange))
		get_parent().call_deferred("add_child", objDroped)

func _destroy() -> void:
	destroyed = true
	if hitByPlayerShot:
		Events.hit_stop_requested.emit(0.035 if points < 500 else 0.05)
	var shake_strength := clampf(1.25 + sqrt(float(maxi(points, 0))) * 0.08, 1.25, 5.0)
	Events.screen_shake_requested.emit(shake_strength, 0.08 + shake_strength * 0.015)
	if shake_strength >= 4.0:
		Events.screen_flash_requested.emit(Color(0.88, 0.35, 0.25, 0.08), 0.08)
	$sound_Explode.playing = true
	$anim.play("explode")
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if has_node("shootTimer"):
		$shootTimer.stop()
	if hitByPlayerShot:
		var score_popup = preload("res://scenes/ui/score.tscn").instantiate()
		score_popup.position = global_position
		score_popup.setScore = points
		get_parent().call_deferred("add_child", score_popup)
		global.register_kill(points)
		if randi() % 101 <= randPowerUp:
			var powerUp = preload("res://scenes/ui/power_up.tscn").instantiate()
			powerUp.position = global_position
			get_parent().call_deferred("add_child", powerUp)
	if dropOnDestroy:
		_drop()

func _is_coop() -> bool:
	return global.coop

func _spawn_shot(packed: PackedScene, from: Vector2, speed_x: float = 0, rot_deg: float = 0) -> Node:
	var shot = ProjectilePool.spawn(packed, from, get_parent())
	shot.speedX = speed_x * PROJECTILE_SPEED_MULTIPLIER
	if rot_deg != 0.0:
		shot.rotation_degrees = rot_deg
	return shot

class_name Enemy
extends Area2D

const Layers := preload("res://core/collision_layers.gd")
const EliteIndicatorScene := preload("res://scenes/enemies/elite_indicator.gd")
const PowerUpScene := preload("res://scenes/ui/power_up.tscn")
const PROJECTILE_SPEED_MULTIPLIER := 1.1

@export var definition: EnemyDefinition
@export var shoot_timer_paths: Array[NodePath] = []

var destroyed := false
var hitByPlayerShot := false
var life := 0
var max_life := 0
var hitSomething := 1
var points := 0
var speedX := 0.0
var speedY := 0.0
var setRotation := false
var speedRotation := 0.0
var indexSprites: Variant
var elite := false

var _spawn_context := EnemySpawnContext.new()
var _elite_indicator: EliteIndicator
var _shoot_timers: Array[Timer] = []
var _lateral_phase := 0.0
var _lateral_time := 0.0

func _ready() -> void:
	if definition == null:
		push_error("EnemyDefinition is required for %s." % scene_file_path)
		queue_free()
		return
	if not definition.is_valid():
		push_error("EnemyDefinition contains invalid combat or presentation values for %s." % scene_file_path)
		queue_free()
		return
	_apply_definition()
	_resolve_shoot_timers()
	_apply_spawn_context()
	_configure_collision()
	_play_spawn_animation()
	if elite:
		_setup_elite_indicator()

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	hitByPlayerShot = false
	_lateral_time += delta
	translate(Vector2(_lateral_velocity(), speedY) * delta)
	if setRotation:
		rotation += speedRotation * delta

func configure_spawn(context: EnemySpawnContext) -> void:
	_spawn_context = context

func _apply_definition() -> void:
	life = definition.max_health
	hitSomething = definition.collision_damage
	points = definition.score
	speedX = definition.speed.x + randf_range(-definition.random_speed.x, definition.random_speed.x)
	speedY = definition.speed.y + randf_range(-definition.random_speed.y, definition.random_speed.y)
	_lateral_phase = randf_range(0.0, TAU)
	setRotation = definition.rotates
	speedRotation = definition.rotation_speed
	if definition.random_rotation:
		rotation = randf_range(-PI, PI)
		speedRotation = randf_range(definition.random_rotation_min, definition.random_rotation_max)

func _lateral_velocity() -> float:
	if definition.lateral_amplitude <= 0.0 or definition.lateral_frequency <= 0.0:
		return speedX
	var angular_frequency := TAU * definition.lateral_frequency
	return speedX + cos(_lateral_time * angular_frequency + _lateral_phase) * definition.lateral_amplitude * angular_frequency

func _apply_spawn_context() -> void:
	var health_multiplier := _spawn_context.health_multiplier * _spawn_context.rule_health_multiplier
	elite = _spawn_context.elite
	speedX *= _spawn_context.speed_multiplier
	speedY *= _spawn_context.speed_multiplier
	if elite and _spawn_context.elite_definition:
		var elite_definition := _spawn_context.elite_definition
		health_multiplier *= elite_definition.health_multiplier
		speedX *= elite_definition.speed_multiplier
		speedY *= elite_definition.speed_multiplier
		points *= elite_definition.score_multiplier
		for timer in _shoot_timers:
			timer.wait_time *= elite_definition.fire_delay_multiplier
	life = ceili(float(life) * health_multiplier)
	max_life = life
	add_to_group("enemy")
	if elite:
		add_to_group("elite")

func _resolve_shoot_timers() -> void:
	for path in shoot_timer_paths:
		var timer := get_node_or_null(path) as Timer
		if timer:
			_shoot_timers.append(timer)

func _configure_collision() -> void:
	collision_layer = Layers.ENEMY
	collision_mask = Layers.PLAYER | Layers.PLAYER_SHOT

func _play_spawn_animation() -> void:
	indexSprites = randi() % definition.sprite_variants + 1 if definition.sprite_variants > 1 else ""
	$anim.play("start" + str(indexSprites))

func _hit_something(dmg := 0) -> void:
	if destroyed:
		return
	life -= dmg
	if _elite_indicator:
		_elite_indicator.set_health(life)
	$sound_Hit.playing = true
	position.y -= 5.0
	if life <= 0:
		_destroy()
	else:
		$anim.play("hit" + str(indexSprites))

func _on_area_entered(area: Area2D) -> void:
	if not destroyed and area.has_method("_hit_something"):
		area._hit_something(hitSomething)

func _on_screen_exited() -> void:
	set_physics_process(false)
	queue_free()

func _on_anim_animation_finished(animation: StringName) -> void:
	if animation == "explode":
		set_physics_process(false)
		queue_free()
	elif animation == "hit" + str(indexSprites):
		$anim.play("start" + str(indexSprites))

func _destroy() -> void:
	destroyed = true
	var shake_strength := clampf(1.25 + sqrt(float(maxi(points, 0))) * 0.08, 1.25, 5.0)
	Events.screen_shake_requested.emit(shake_strength, 0.08 + shake_strength * 0.015)
	if shake_strength >= 4.0:
		Events.screen_flash_requested.emit(Color(0.88, 0.35, 0.25, 0.08), 0.08)
	$sound_Explode.playing = true
	$anim.play("explode")
	$CollisionShape2D.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for timer in _shoot_timers:
		timer.stop()
	if hitByPlayerShot:
		_award_player_kill()
	if definition.drops_on_destroy:
		_drop_debris()

func _award_player_kill() -> void:
	var awarded_points := global.register_kill(points)
	var multiplier := global.combo_multiplier(global.combo)
	Events.score_popup_requested.emit(awarded_points, global.combo, multiplier, global_position)
	if not elite and randi() % 101 <= definition.power_up_chance:
		var power_up := PowerUpScene.instantiate()
		power_up.position = get_parent().to_local(global_position)
		get_parent().call_deferred("add_child", power_up)

func _drop_debris() -> void:
	if definition.drop_scene == null:
		return
	for _index in range(definition.drop_count):
		var debris := definition.drop_scene.instantiate()
		var drop_position := global_position + Vector2(randf_range(-definition.drop_range, definition.drop_range), randf_range(-definition.drop_range, definition.drop_range))
		debris.position = get_parent().to_local(drop_position)
		get_parent().call_deferred("add_child", debris)

func _setup_elite_indicator() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and _spawn_context.elite_definition:
		sprite.self_modulate = _spawn_context.elite_definition.outline_color
	_elite_indicator = EliteIndicatorScene.new()
	_elite_indicator.name = "EliteIndicator"
	add_child(_elite_indicator)
	_elite_indicator.setup(self, max_life, _spawn_context.elite_definition)

func _spawn_shot(packed: PackedScene, from: Vector2, speed_x: float = 0.0, rot_deg: float = 0.0) -> Node:
	var shot = ProjectilePool.spawn(packed, from, get_parent())
	shot.speedX = speed_x * PROJECTILE_SPEED_MULTIPLIER
	if rot_deg != 0.0:
		shot.rotation_degrees = rot_deg
	return shot

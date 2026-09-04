class_name Enemy
extends Area2D

const Layers := preload("res://core/collision_layers.gd")
const EliteIndicatorScene := preload("res://scenes/enemies/elite_indicator.gd")
const PowerUpScene := preload("res://scenes/ui/power_up.tscn")
const PlasmaCellScene := preload("res://scenes/ui/plasma_cell.tscn")
const PROJECTILE_SPEED_MULTIPLIER := 1.1

enum RewardDrop { NONE, PLASMA, POWER_UP }
enum PatrolState { ENTERING, PATROLLING, EXITING }

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
var _movement_profile: MovementProfile
var _movement_time := 0.0
var _movement_phase := 0.0
var _movement_direction := 1.0
var _target_horizontal_speed := 0.0
var _sine_wave_offset := 0.0
var _patrol_state := PatrolState.ENTERING
var _patrol_elapsed := 0.0
var fire_delay_multiplier := 1.0

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
	_initialize_movement()
	_configure_collision()
	_play_spawn_animation()
	if elite:
		_setup_elite_indicator()

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	hitByPlayerShot = false
	_update_movement(delta)
	if setRotation:
		rotation += speedRotation * delta

func configure_spawn(context: EnemySpawnContext) -> void:
	_spawn_context = context

func _apply_definition() -> void:
	life = definition.max_health
	hitSomething = definition.collision_damage
	points = definition.score

func _apply_spawn_context() -> void:
	var health_multiplier := _spawn_context.health_multiplier * _spawn_context.rule_health_multiplier
	_movement_profile = _spawn_context.movement_profile if _spawn_context.movement_profile else definition.movement_profile
	speedX = _movement_profile.velocity.x * _spawn_context.speed_multiplier
	speedY = _movement_profile.velocity.y * _spawn_context.speed_multiplier
	elite = _spawn_context.elite
	if elite and _spawn_context.elite_definition:
		var elite_definition := _spawn_context.elite_definition
		health_multiplier *= elite_definition.health_multiplier
		speedX *= elite_definition.speed_multiplier
		speedY *= elite_definition.speed_multiplier
		points *= elite_definition.score_multiplier
		fire_delay_multiplier = elite_definition.fire_delay_multiplier
		for timer in _shoot_timers:
			timer.wait_time *= fire_delay_multiplier
	life = ceili(float(life) * health_multiplier)
	max_life = life
	add_to_group("enemy")
	if elite:
		add_to_group("elite")

func _initialize_movement() -> void:
	_movement_time = _spawn_context.movement_time_offset
	var individual_rng := RandomNumberGenerator.new()
	individual_rng.seed = _spawn_context.movement_seed
	var formation_rng := RandomNumberGenerator.new()
	formation_rng.seed = _spawn_context.formation_seed
	var phase_rng := formation_rng if _movement_profile.synchronize_formation else individual_rng
	_movement_phase = phase_rng.randf_range(0.0, TAU)
	_movement_direction = -1.0 if phase_rng.randi_range(0, 1) == 0 else 1.0
	_target_horizontal_speed = _movement_direction * _movement_profile.horizontal_speed * _movement_speed_scale()
	global_position.x = clampf(global_position.x, _movement_profile.min_x, _movement_profile.max_x)
	if _movement_profile.mode == MovementProfile.Mode.SINE:
		_sine_wave_offset = _current_sine_wave_offset()
	if _movement_profile.mode == MovementProfile.Mode.DRIFT:
		var drift_speed := individual_rng.randf_range(_movement_profile.horizontal_speed_min, _movement_profile.horizontal_speed_max)
		speedX = drift_speed * _movement_direction * _movement_speed_scale()
	if _movement_profile.random_rotation:
		rotation = individual_rng.randf_range(-PI, PI)
		speedRotation = individual_rng.randf_range(_movement_profile.rotation_speed_min, _movement_profile.rotation_speed_max)
		setRotation = true
	elif not is_zero_approx(_movement_profile.rotation_speed_max):
		speedRotation = _movement_profile.rotation_speed_max
		setRotation = true

func _update_movement(delta: float) -> void:
	_movement_time += delta
	match _movement_profile.mode:
		MovementProfile.Mode.SINE:
			_update_sine_movement(delta)
		MovementProfile.Mode.SMOOTH_ZIGZAG:
			_update_smooth_zigzag(delta)
		MovementProfile.Mode.STRAFE:
			_update_strafe(delta)
		MovementProfile.Mode.DRIFT:
			_update_drift(delta)
		MovementProfile.Mode.PATROL_EXIT:
			_update_patrol_exit(delta)
		_:
			translate(Vector2(speedX, speedY) * delta)
			_apply_horizontal_bounds()

func _update_sine_movement(delta: float) -> void:
	var speed_scale := maxf(_movement_speed_scale(), 0.01)
	var wave_offset := _current_sine_wave_offset()
	var horizontal_delta := (
		wave_offset - _sine_wave_offset
		+ _movement_profile.horizontal_speed * speed_scale * delta
	) * _movement_direction
	_sine_wave_offset = wave_offset
	global_position.x += horizontal_delta
	global_position.y += speedY * delta
	_apply_horizontal_bounds()

func _current_sine_wave_offset() -> float:
	var speed_scale := maxf(_movement_speed_scale(), 0.01)
	var angle := _movement_time * TAU * speed_scale / _movement_profile.period + _movement_phase
	return sin(angle) * _movement_profile.amplitude

func _update_smooth_zigzag(delta: float) -> void:
	if _movement_time >= _movement_profile.turn_interval:
		_movement_time = fmod(_movement_time, _movement_profile.turn_interval)
		_movement_direction *= -1.0
		_target_horizontal_speed = _movement_direction * _movement_profile.horizontal_speed * _movement_speed_scale()
	speedX = move_toward(speedX, _target_horizontal_speed, _movement_profile.acceleration * _movement_speed_scale() * delta)
	translate(Vector2(speedX, speedY) * delta)
	_apply_horizontal_bounds()

func _update_strafe(delta: float) -> void:
	speedX = _movement_direction * _movement_profile.horizontal_speed * _movement_speed_scale()
	translate(Vector2(speedX, speedY) * delta)
	_apply_horizontal_bounds()

func _update_drift(delta: float) -> void:
	translate(Vector2(speedX, speedY) * delta)
	_apply_horizontal_bounds()

func _update_patrol_exit(delta: float) -> void:
	match _patrol_state:
		PatrolState.ENTERING:
			global_position.y += speedY * delta
			if global_position.y >= _movement_profile.entry_y:
				global_position.y = _movement_profile.entry_y
				_patrol_state = PatrolState.PATROLLING
		PatrolState.PATROLLING:
			_patrol_elapsed += delta
			speedX = _movement_direction * _movement_profile.horizontal_speed * _movement_speed_scale()
			global_position.x += speedX * delta
			_apply_horizontal_bounds()
			if _patrol_elapsed >= _movement_profile.patrol_duration:
				_patrol_state = PatrolState.EXITING
				speedX = 0.0
		PatrolState.EXITING:
			global_position.y += speedY * delta

func _apply_horizontal_bounds() -> void:
	var bounced := false
	if global_position.x < _movement_profile.min_x:
		global_position.x = _movement_profile.min_x
		_movement_direction = 1.0
		speedX = absf(speedX)
		bounced = true
	elif global_position.x > _movement_profile.max_x:
		global_position.x = _movement_profile.max_x
		_movement_direction = -1.0
		speedX = -absf(speedX)
		bounced = true
	if not bounced:
		return
	if _movement_profile.mode == MovementProfile.Mode.SMOOTH_ZIGZAG:
		_movement_time = 0.0
	_target_horizontal_speed = _movement_direction * _movement_profile.horizontal_speed * _movement_speed_scale()

func _movement_speed_scale() -> float:
	var value := _spawn_context.speed_multiplier
	if elite and _spawn_context.elite_definition:
		value *= _spawn_context.elite_definition.speed_multiplier
	return value

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

func _hit_something(dmg := 0, impact_feedback := true) -> void:
	if destroyed:
		return
	life -= dmg
	if _elite_indicator:
		_elite_indicator.set_health(life)
	if impact_feedback:
		$sound_Hit.playing = true
		position.y -= 5.0
	if life <= 0:
		_destroy()
	elif impact_feedback:
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
	var shake_strength := clampf(3.0 + sqrt(float(maxi(points, 0))) * 0.2, 3.0, 14.0)
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
	if elite:
		_spawn_power_up()
		_spawn_plasma_cell(25.0)
		return
	match _reward_for_roll(randi_range(0, 99)):
		RewardDrop.PLASMA:
			_spawn_plasma_cell(12.5)
		RewardDrop.POWER_UP:
			_spawn_power_up()

func _reward_for_roll(roll: int) -> RewardDrop:
	if roll < definition.plasma_drop_chance:
		return RewardDrop.PLASMA
	if roll < definition.plasma_drop_chance + definition.power_up_chance:
		return RewardDrop.POWER_UP
	return RewardDrop.NONE

func _spawn_power_up() -> void:
	var power_up := PowerUpScene.instantiate()
	power_up.position = get_parent().to_local(global_position)
	get_parent().call_deferred("add_child", power_up)

func _spawn_plasma_cell(amount: float) -> void:
	var plasma_cell := PlasmaCellScene.instantiate() as PlasmaCell
	plasma_cell.charge_amount = amount
	plasma_cell.position = get_parent().to_local(global_position)
	get_parent().call_deferred("add_child", plasma_cell)

func _drop_debris() -> void:
	if definition.drop_scene == null:
		return
	for index in range(definition.drop_count):
		var debris := definition.drop_scene.instantiate()
		if debris is Enemy:
			var debris_context := EnemySpawnContext.new()
			debris_context.movement_seed = _derived_seed(_spawn_context.movement_seed, index + 1)
			debris_context.formation_seed = _spawn_context.formation_seed
			debris.configure_spawn(debris_context)
		var drop_position := global_position + Vector2(randf_range(-definition.drop_range, definition.drop_range), randf_range(-definition.drop_range, definition.drop_range))
		debris.position = get_parent().to_local(drop_position)
		get_parent().call_deferred("add_child", debris)

func _derived_seed(base_seed: int, salt: int) -> int:
	return int((base_seed * 1103515245 + salt * 12345 + 1013904223) & 0x7fffffff)

func _setup_elite_indicator() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and _spawn_context.elite_definition:
		sprite.self_modulate = _spawn_context.elite_definition.outline_color
	_elite_indicator = EliteIndicatorScene.new()
	_elite_indicator.name = "EliteIndicator"
	add_child(_elite_indicator)
	_elite_indicator.setup(self, max_life, _spawn_context.elite_definition)

func _spawn_shot(packed: PackedScene, from: Vector2, speed_x: float = 0.0, rot_deg: float = 0.0) -> Node:
	var shot = ProjectilePool.spawn(packed, from, _projectile_parent())
	shot.speedX = speed_x * PROJECTILE_SPEED_MULTIPLIER
	shot.speedY *= PROJECTILE_SPEED_MULTIPLIER
	if rot_deg != 0.0:
		shot.rotation_degrees = rot_deg
	return shot

func _spawn_shot_velocity(packed: PackedScene, from: Vector2, velocity: Vector2) -> Node:
	var shot = ProjectilePool.spawn(packed, from, _projectile_parent())
	var scaled_velocity := velocity * PROJECTILE_SPEED_MULTIPLIER
	shot.speedX = scaled_velocity.x
	shot.speedY = scaled_velocity.y
	return shot

func _projectile_parent() -> Node:
	return get_parent()

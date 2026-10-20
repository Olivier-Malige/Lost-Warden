class_name Enemy
extends Area2D

const Layers := preload("res://core/collision_layers.gd")
const EliteIndicatorScene := preload("res://scenes/enemies/elite_indicator.gd")
const PlasmaCellScene := preload("res://scenes/ui/plasma_cell.tscn")
const PROJECTILE_SPEED_MULTIPLIER := 1.1
const HIT_FLASH_MATERIAL := preload("res://scenes/effects/enemy_hit_flash.tres")

enum RewardDrop { NONE, PLASMA, POWER_UP }
enum PatrolState { ENTERING, PATROLLING, EXITING }

@export var definition: EnemyDefinition
@export var shoot_timer_paths: Array[NodePath] = []

var destroyed := false
var hitByPlayerShot := false
var last_player_hit_owner: StringName = &""
var life := 0.0
var max_life := 0.0
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
var _hit_sprite: Sprite2D
var _hit_flash_tween: Tween
var _movement_animation := &"start"
var _debug_removal_reported := false
var _chase_target: WeakRef
var _chase_committed := false
var _chase_exit_y := INF
var _chase_exiting := false

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
	_hit_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _hit_sprite == null:
		_hit_sprite = get_node_or_null("SpriteAsteroid") as Sprite2D
	if _hit_sprite:
		_hit_sprite.material = HIT_FLASH_MATERIAL
	if elite:
		_setup_elite_indicator()

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	hitByPlayerShot = false
	_update_movement(delta)
	_update_ship_banking(delta)
	if setRotation:
		rotation += speedRotation * delta

func configure_spawn(context: EnemySpawnContext) -> void:
	_spawn_context = context

func get_combat_identity() -> StringName:
	return _spawn_context.combat_id

func player_damage_group() -> Node:
	return self

func can_receive_player_hit() -> bool:
	return not destroyed and life > 0.0 and is_inside_tree() and not is_queued_for_deletion()

# Kill ownership must be set before virtual damage can synchronously award the kill.
func receive_player_hit(amount: float, owner_id: StringName = &"", impact_feedback := true) -> bool:
	if not is_finite(amount) or amount <= 0.0 or not can_receive_player_hit():
		return false
	var before := life
	var previous_credit := hitByPlayerShot
	var previous_owner := last_player_hit_owner
	hitByPlayerShot = true
	last_player_hit_owner = owner_id
	_hit_something(amount, impact_feedback)
	if life < before:
		return true
	hitByPlayerShot = previous_credit
	last_player_hit_owner = previous_owner
	return false

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
	fire_delay_multiplier = _spawn_context.fire_delay_multiplier
	if elite and _spawn_context.elite_definition:
		var elite_definition := _spawn_context.elite_definition
		health_multiplier *= elite_definition.health_multiplier
		speedX *= elite_definition.speed_multiplier
		speedY *= elite_definition.speed_multiplier
		points *= elite_definition.score_multiplier
		fire_delay_multiplier *= elite_definition.fire_delay_multiplier
	for timer in _shoot_timers:
		timer.wait_time *= fire_delay_multiplier
		if not timer.is_stopped():
			timer.start()
	life *= health_multiplier
	max_life = life
	add_to_group("enemy")
	if definition.id != &"":
		add_to_group(StringName("family_" + String(definition.id)))
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
	global_position.x = clampf(global_position.x, _movement_min_x(), _movement_max_x())
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
		MovementProfile.Mode.CHASE:
			_update_chase(delta)
		_:
			translate(Vector2(speedX, speedY) * delta)
			_apply_horizontal_bounds()


func _choose_chase_target() -> void:
	var players: Array[Node2D] = []
	for player in get_tree().get_nodes_in_group("player"):
		if player is Node2D and (player.get("state") == null or int(player.state) < 2):
			players.append(player)
	_chase_target = weakref(players[posmod(_spawn_context.movement_seed, players.size())]) if not players.is_empty() else null

# Commit before reaching the player so the final approach stays predictable and dodgeable.
func _update_chase(delta: float) -> void:
	var target = _chase_target.get_ref() if _chase_target else null
	if not _chase_committed and (not is_instance_valid(target) or (target.get("state") != null and int(target.state) >= 2)):
		_choose_chase_target()
		target = _chase_target.get_ref() if _chase_target else null
	if not _chase_committed and is_instance_valid(target) and target.global_position.y - global_position.y <= _movement_profile.chase_commit_distance:
		_chase_committed = true
		_chase_exit_y = target.global_position.y
	if _chase_committed and global_position.y >= _chase_exit_y:
		_chase_exiting = true
	if _chase_exiting or (not _chase_committed and is_instance_valid(target)):
		var direction := Vector2.DOWN if _chase_exiting else global_position.direction_to(target.global_position)
		var desired := direction * _movement_profile.chase_speed * _movement_speed_scale()
		var velocity := Vector2(speedX, speedY).move_toward(desired, _movement_profile.chase_acceleration * delta)
		speedX = velocity.x
		speedY = maxf(velocity.y, 0.0)
	translate(Vector2(speedX, speedY) * delta)
	if not _chase_committed:
		_apply_horizontal_bounds()

func _update_ship_banking(_delta: float) -> void:
	if not definition.bank_on_turn or _hit_sprite == null:
		return
	var current_animation := StringName($anim.current_animation)
	if current_animation == &"explode" or String(current_animation).begins_with("hit"):
		return
	var animation := &"start"
	if speedX < -1.0:
		animation = &"bank_left"
	elif speedX > 1.0:
		animation = &"bank_right"
	if _movement_animation != animation:
		_movement_animation = animation
		$anim.play(animation)

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
	if global_position.x < _movement_min_x():
		global_position.x = _movement_min_x()
		_movement_direction = 1.0
		speedX = absf(speedX)
		bounced = true
	elif global_position.x > _movement_max_x():
		global_position.x = _movement_max_x()
		_movement_direction = -1.0
		speedX = -absf(speedX)
		bounced = true
	if not bounced:
		return
	if _movement_profile.mode == MovementProfile.Mode.SMOOTH_ZIGZAG:
		_movement_time = 0.0
	_target_horizontal_speed = _movement_direction * _movement_profile.horizontal_speed * _movement_speed_scale()


func _movement_min_x() -> float:
	return _movement_profile.min_x + _playfield_side_width()


func _movement_max_x() -> float:
	return _movement_profile.max_x + _playfield_side_width()


func _playfield_side_width() -> float:
	return maxf((get_viewport_rect().size.x - 640.0) * 0.5, 0.0)

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
	indexSprites = str(randi() % definition.sprite_variants + 1) if definition.sprite_variants > 1 else ""
	$anim.play("start" + str(indexSprites))

func _hit_something(dmg: float = 0.0, impact_feedback := true) -> void:
	if destroyed:
		return
	life -= dmg
	if dmg > 0:
		_flash_hit()
	if _elite_indicator:
		_elite_indicator.set_health(life)
	if impact_feedback:
		$sound_Hit.playing = true
		position.y -= 5.0
	if life <= 0:
		_destroy()

func _flash_hit() -> void:
	if _hit_sprite == null:
		return
	if _hit_flash_tween and _hit_flash_tween.is_valid():
		_hit_flash_tween.kill()
	_set_hit_flash(1.0)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_interval(0.04)
	_hit_flash_tween.tween_method(_set_hit_flash, 1.0, 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _set_hit_flash(amount: float) -> void:
	_hit_sprite.set_instance_shader_parameter(&"hit_flash", amount)

func _on_area_entered(area: Area2D) -> void:
	if not destroyed and area.has_method("_hit_something"):
		area._hit_something(hitSomething)

func _on_screen_exited() -> void:
	if not destroyed:
		_report_debug_removal("escaped")
	set_physics_process(false)
	queue_free()

func _report_debug_removal(reason: String) -> void:
	if global.Debug and not _debug_removal_reported:
		_debug_removal_reported = true
		Events.debug_enemy_removed.emit(definition.id, reason)

func _on_anim_animation_finished(animation: StringName) -> void:
	if animation == "explode":
		set_physics_process(false)
		queue_free()

func _destroy() -> void:
	destroyed = true
	if _elite_indicator:
		_elite_indicator.hide()
	_report_debug_removal("killed" if hitByPlayerShot else "other")
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
		call_deferred("_drop_debris")

func _award_player_kill() -> void:
	var awarded_points := global.register_kill(points)
	var multiplier := global.combo_multiplier(global.combo)
	Events.score_popup_requested.emit(awarded_points, global.combo, multiplier, global_position)
	var xp := _xp_for_roll(global.run_random.drops.randi_range(0, 99))
	var plasma := _plasma_amount_for_roll(global.run_random.drops.randi_range(0, 99))
	if xp > 0:
		Events.xp_spawn_requested.emit(xp, global_position)
	if plasma > 0.0:
		_spawn_plasma_cell(plasma)

func _xp_for_roll(roll: int) -> int:
	if _spawn_context.asteroid_fragment:
		return 0
	if elite:
		return maxi(6, 3 * definition.xp_value)
	return definition.xp_value if roll < definition.xp_drop_chance else 0

func _plasma_amount_for_roll(roll: int) -> float:
	if elite: return 25.0
	return 12.5 if roll < definition.plasma_drop_chance else 0.0

func _reward_for_roll(roll: int) -> RewardDrop:
	if roll < definition.plasma_drop_chance:
		return RewardDrop.PLASMA
	return RewardDrop.NONE

func _spawn_plasma_cell(amount: float) -> void:
	call_deferred("_materialize_plasma_cell", amount, global_position)

func _materialize_plasma_cell(amount: float, point: Vector2) -> void:
	if not is_inside_tree() or get_parent().is_queued_for_deletion():
		return
	var plasma_cell := PlasmaCellScene.instantiate() as PlasmaCell
	plasma_cell.charge_amount = amount
	plasma_cell.position = get_parent().to_local(point)
	get_parent().add_child(plasma_cell)

func _drop_debris() -> void:
	if definition.drop_scene == null:
		return
	var debris_rng := RandomNumberGenerator.new()
	debris_rng.seed = _derived_seed(_spawn_context.movement_seed, 701)
	for index in range(definition.drop_count):
		var debris := definition.drop_scene.instantiate()
		if debris is Enemy:
			var debris_context := EnemySpawnContext.new()
			debris_context.asteroid_fragment = true
			debris_context.combat_id = StringName("%s/fragment_%02d" % [_spawn_context.combat_id, index])
			debris_context.movement_seed = _derived_seed(_spawn_context.movement_seed, index + 1)
			debris_context.formation_seed = _spawn_context.formation_seed
			debris.configure_spawn(debris_context)
		var drop_position := global_position + Vector2(debris_rng.randf_range(-definition.drop_range, definition.drop_range), debris_rng.randf_range(-definition.drop_range, definition.drop_range))
		debris.position = get_parent().to_local(drop_position)
		if debris is Enemy and get_parent().has_method("queue_enemy"):
			get_parent().queue_enemy(debris)
		else:
			get_parent().call_deferred("add_child", debris)

func _derived_seed(base_seed: int, salt: int) -> int:
	return int((base_seed * 1103515245 + salt * 12345 + 1013904223) & 0x7fffffff)

func _setup_elite_indicator() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and definition.elite_texture:
		sprite.texture = definition.elite_texture
		sprite.hframes = definition.elite_frame_grid.x
		sprite.vframes = definition.elite_frame_grid.y
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

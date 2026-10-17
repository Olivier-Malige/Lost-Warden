class_name TurretEnemy
extends Enemy

const TurretShot := preload("res://scenes/combat/turret_shot.tscn")
const AIM_TELEGRAPH_TIME := 0.35
const STANDALONE_AIM_TELEGRAPH_TIME := 0.6
const AIM_BURST_DELAY := 0.14
const AIM_COOLDOWN := 0.65
const RING_TELEGRAPH_TIME := 0.7
const RING_COOLDOWN := 1.1
const AIM_SPEED := 210.0
const RING_SPEED := 140.0
const AIM_SPREAD := [-5.0, 0.0, 5.0]
const RING_SHOT_COUNT := 10
const RING_OFFSET_DEGREES := 18.0
const MOUNTED_AIM_LIMIT := PI / 3.0
const MOUNTED_TURN_SPEED := 5.0

enum AttackState {
	IDLE,
	AIM_TELEGRAPH,
	AIM_BURST,
	AIM_COOLDOWN,
	RING_TELEGRAPH,
	RING_COOLDOWN,
	STOPPED,
}

@export var mounted := false
@export var shot_speed_multiplier := 1.0
@export_range(0.0, 10.0, 0.05) var initial_delay := 0.0

var _attack_state := AttackState.IDLE
var _burst_index := 0
var _locked_target := Vector2.ZERO
var _has_locked_target := false
var _ring_offset := 0.0
var _patterns_started := false
var _resting_sprite_rotation := 0.0

@onready var _attack_timer: Timer = $ShotDelay
@onready var _shoot_origin: Marker2D = $shootPos
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	add_to_group("turret")
	if mounted:
		add_to_group("mounted_turret")
	super._ready()
	if not is_inside_tree():
		return
	_resting_sprite_rotation = _sprite.rotation
	_attack_timer.timeout.connect(_on_attack_timer_timeout)
	if mounted:
		set_combat_enabled(false)
	else:
		$anim.animation_finished.connect(_on_attack_animation_finished)
		_screen_notifier.screen_entered.connect(_on_screen_entered)
		call_deferred("_start_if_visible")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if mounted and _patterns_started and not destroyed:
		_has_locked_target = _lock_nearest_target()
		var aim := _resting_sprite_rotation
		if _has_locked_target:
			aim = clampf(Vector2.DOWN.angle_to(global_position.direction_to(_locked_target)), -MOUNTED_AIM_LIMIT, MOUNTED_AIM_LIMIT)
		_sprite.rotation = move_toward(_sprite.rotation, aim, MOUNTED_TURN_SPEED * delta)
	elif not mounted and _attack_state == AttackState.AIM_COOLDOWN and not destroyed:
		_sprite.rotation = move_toward(_sprite.rotation, _resting_sprite_rotation, MOUNTED_TURN_SPEED * delta)

func activate_patterns(delay := -1.0) -> void:
	if destroyed or _patterns_started:
		return
	_patterns_started = true
	set_combat_enabled(true)
	_attack_state = AttackState.IDLE
	_schedule(initial_delay if delay < 0.0 else delay)

func stop_patterns() -> void:
	_patterns_started = false
	_attack_state = AttackState.STOPPED
	_attack_timer.stop()
	_set_telegraph(false)
	_sprite.rotation = _resting_sprite_rotation
	if not destroyed:
		$anim.play("start")

func shutdown_from_parent() -> void:
	_report_debug_removal("other")
	stop_patterns()
	set_combat_enabled(false)
	visible = false

func set_combat_enabled(enabled: bool) -> void:
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", not enabled)
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)

func _configure_collision() -> void:
	super._configure_collision()
	if mounted:
		collision_mask = Layers.PLAYER_SHOT

func _projectile_parent() -> Node:
	if mounted and get_parent() and get_parent().get_parent():
		return get_parent().get_parent()
	return super._projectile_parent()

func _start_if_visible() -> void:
	if not mounted and _screen_notifier.is_on_screen():
		activate_patterns()

func _on_screen_entered() -> void:
	activate_patterns()

func _on_attack_timer_timeout() -> void:
	if destroyed or not _patterns_started:
		return
	match _attack_state:
		AttackState.IDLE, AttackState.RING_COOLDOWN:
			_begin_aim_telegraph()
		AttackState.AIM_TELEGRAPH:
			_begin_aim_burst()
		AttackState.AIM_BURST:
			_continue_aim_burst()
		AttackState.AIM_COOLDOWN:
			if mounted:
				_begin_aim_telegraph()
			else:
				_begin_ring_telegraph()
		AttackState.RING_TELEGRAPH:
			_fire_ring()

func _begin_aim_telegraph() -> void:
	_attack_state = AttackState.AIM_TELEGRAPH
	_has_locked_target = _lock_nearest_target()
	_set_telegraph(true)
	if not mounted:
		$anim.play("aim_charge")
	_schedule(AIM_TELEGRAPH_TIME if mounted else STANDALONE_AIM_TELEGRAPH_TIME)

func _begin_aim_burst() -> void:
	_set_telegraph(false)
	_burst_index = 0
	if not _has_locked_target:
		_attack_state = AttackState.AIM_COOLDOWN
		if not mounted:
			$anim.play("aim_recover")
		_schedule(AIM_COOLDOWN)
		return
	_attack_state = AttackState.AIM_BURST
	if not mounted:
		$anim.play("aim_fire")
	_fire_aimed_projectile()
	_schedule(AIM_BURST_DELAY)

func _continue_aim_burst() -> void:
	if mounted and not _has_locked_target:
		_attack_state = AttackState.AIM_COOLDOWN
		_schedule(AIM_COOLDOWN)
		return
	if _burst_index < AIM_SPREAD.size():
		_fire_aimed_projectile()
		if _burst_index < AIM_SPREAD.size():
			_schedule(AIM_BURST_DELAY)
			return
	_attack_state = AttackState.AIM_COOLDOWN
	if not mounted:
		$anim.play("aim_recover")
	_schedule(AIM_COOLDOWN)

func _fire_aimed_projectile() -> void:
	var origin := _shoot_origin.global_position
	var direction := origin.direction_to(_locked_target)
	if mounted:
		origin = to_global(_shoot_origin.position.rotated(_sprite.rotation))
		direction = Vector2.DOWN.rotated(global_rotation + _sprite.rotation)
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	var spread_radians := deg_to_rad(AIM_SPREAD[_burst_index])
	_spawn_shot_velocity(TurretShot, origin, direction.rotated(spread_radians) * AIM_SPEED * shot_speed_multiplier)
	_burst_index += 1
	$sound_Shooting.playing = true

func _begin_ring_telegraph() -> void:
	_attack_state = AttackState.RING_TELEGRAPH
	_sprite.rotation = _resting_sprite_rotation
	_set_telegraph(true)
	$anim.play("ring_charge")
	_schedule(RING_TELEGRAPH_TIME)

func _fire_ring() -> void:
	_set_telegraph(false)
	$anim.play("ring_fire")
	for index in range(RING_SHOT_COUNT):
		var angle := _ring_offset + TAU * float(index) / float(RING_SHOT_COUNT)
		_spawn_shot_velocity(TurretShot, _shoot_origin.global_position, Vector2.DOWN.rotated(angle) * RING_SPEED * shot_speed_multiplier)
	_ring_offset = deg_to_rad(RING_OFFSET_DEGREES) if is_zero_approx(_ring_offset) else 0.0
	$sound_Shooting.playing = true
	_attack_state = AttackState.RING_COOLDOWN
	_schedule(RING_COOLDOWN)

func _lock_nearest_target() -> bool:
	var nearest_distance := INF
	var found := false
	for candidate in get_tree().get_nodes_in_group("player"):
		if candidate is not Node2D or not candidate.is_physics_processing():
			continue
		var distance := _shoot_origin.global_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			_locked_target = candidate.global_position
			found = true
	if found and not mounted:
		_sprite.rotation = Vector2.DOWN.angle_to(_shoot_origin.global_position.direction_to(_locked_target))
	return found

func _schedule(duration: float) -> void:
	_attack_timer.start(maxf(duration * fire_delay_multiplier, 0.01))

func _set_telegraph(enabled: bool) -> void:
	modulate = Color(1.6, 0.55, 0.3, 1.0) if mounted and enabled else Color.WHITE

func _on_attack_animation_finished(animation: StringName) -> void:
	if animation == &"ring_fire" and _attack_state == AttackState.RING_COOLDOWN and not destroyed:
		$anim.play("ring_recover")

func _destroy() -> void:
	if destroyed:
		return
	stop_patterns()
	super._destroy()

func _hit_something(dmg: float = 0.0, impact_feedback := true) -> void:
	var mounted_position := position
	super._hit_something(dmg, impact_feedback)
	if mounted:
		position = mounted_position

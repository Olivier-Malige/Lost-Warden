extends Enemy

const MountedTurretScene := preload("res://scenes/enemies/mother_ship_turret.tscn")
const MotherShipShot := preload("res://scenes/combat/mother_ship_shot.tscn")
const TELEGRAPH_TIME := 0.45
const MATERIALIZE_TIME := 0.2
const ANCHOR_HEIGHT_RATIO := 0.27
const ANCHOR_HORIZONTAL_OFFSET_RATIO := 0.21
const HULL_SHOT_SPEED := 320.0
const HULL_FAN_ANGLES := [-24.0, -12.0, 0.0, 12.0, 24.0]

enum ArrivalState { TELEGRAPH, MATERIALIZING, ACTIVE }

var anchor_index := -1
var _arrival_state := ArrivalState.TELEGRAPH
var _arrival_elapsed := 0.0
var _mounted_turrets: Array[TurretEnemy] = []

@onready var _teleport_timer: Timer = $TeleportTimer
@onready var _hull_shoot_origin: Marker2D = $HullShootPos
@onready var _left_turret_mount: Marker2D = $LeftTurretMount
@onready var _right_turret_mount: Marker2D = $RightTurretMount
@onready var _shoot_timer: Timer = $shootTimer

func _ready() -> void:
	add_to_group("mother_ship")
	super._ready()
	if not is_inside_tree():
		return
	anchor_index = _claim_anchor()
	if anchor_index < 0:
		_discard_without_reward()
		return
	speedX = 0.0
	speedY = 0.0
	global_position = _anchor_positions()[anchor_index]
	_teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	_spawn_mounted_turrets()
	_begin_teleport()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if destroyed or _arrival_state != ArrivalState.TELEGRAPH:
		return
	_arrival_elapsed += delta
	var pulse := 0.32 + sin(_arrival_elapsed * 28.0) * 0.18
	modulate = Color(0.35, 1.25, 1.6, pulse)

func _on_ShootTimer_timeout() -> void:
	if destroyed or _arrival_state != ArrivalState.ACTIVE:
		return
	$sound_Shooting.playing = true
	for angle in HULL_FAN_ANGLES:
		var velocity := Vector2.DOWN.rotated(deg_to_rad(angle)) * HULL_SHOT_SPEED
		_spawn_shot_velocity(MotherShipShot, _hull_shoot_origin.global_position, velocity)

func _claim_anchor() -> int:
	var occupied: Dictionary[int, bool] = {}
	for candidate in get_tree().get_nodes_in_group("mother_ship"):
		if candidate == self or candidate is not Enemy:
			continue
		var candidate_anchor: int = candidate.get("anchor_index")
		if candidate_anchor >= 0:
			occupied[candidate_anchor] = true
	for index in range(3):
		if not occupied.has(index):
			return index
	return -1

func _anchor_positions() -> Array[Vector2]:
	var viewport_rect := get_viewport_rect()
	var center := viewport_rect.position + Vector2(viewport_rect.size.x * 0.5, viewport_rect.size.y * ANCHOR_HEIGHT_RATIO)
	var offset := viewport_rect.size.x * ANCHOR_HORIZONTAL_OFFSET_RATIO
	return [center, center + Vector2(-offset, 0.0), center + Vector2(offset, 0.0)]

func _spawn_mounted_turrets() -> void:
	var health_multiplier := float(max_life) / float(definition.max_health)
	var mounts: Array[Marker2D] = [_left_turret_mount, _right_turret_mount]
	for index in range(mounts.size()):
		var turret := MountedTurretScene.instantiate() as TurretEnemy
		turret.configure_spawn(EnemySpawnContext.new(health_multiplier))
		turret.initial_delay = 0.0 if index == 0 else 1.25
		add_child(turret)
		turret.position = mounts[index].position
		_mounted_turrets.append(turret)

func _begin_teleport() -> void:
	_arrival_state = ArrivalState.TELEGRAPH
	_arrival_elapsed = 0.0
	_set_hull_combat_enabled(false)
	modulate = Color(0.35, 1.25, 1.6, 0.15)
	_teleport_timer.start(TELEGRAPH_TIME)

func _on_teleport_timer_timeout() -> void:
	if destroyed:
		return
	if _arrival_state == ArrivalState.TELEGRAPH:
		_arrival_state = ArrivalState.MATERIALIZING
		modulate = Color(1.6, 1.8, 2.0, 1.0)
		_teleport_timer.start(MATERIALIZE_TIME)
		return
	_arrival_state = ArrivalState.ACTIVE
	modulate = Color.WHITE
	_set_hull_combat_enabled(true)
	for turret in _mounted_turrets:
		if is_instance_valid(turret):
			turret.activate_patterns()
	_shoot_timer.start()

func _set_hull_combat_enabled(enabled: bool) -> void:
	$CollisionShape2D.set_deferred("disabled", not enabled)
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)

func _discard_without_reward() -> void:
	destroyed = true
	set_physics_process(false)
	_shoot_timer.stop()
	_teleport_timer.stop()
	_set_hull_combat_enabled(false)
	call_deferred("queue_free")

func _destroy() -> void:
	if destroyed:
		return
	_shoot_timer.stop()
	_teleport_timer.stop()
	for turret in _mounted_turrets:
		if is_instance_valid(turret):
			turret.shutdown_from_parent()
	super._destroy()

func _hit_something(dmg := 0) -> void:
	var anchor_position := position
	super._hit_something(dmg)
	position = anchor_position

func _on_anim_animation_finished(n: StringName) -> void:
	if n == "explode" or $anim.current_animation == "explode":
		for p in [$droneReactorParticles, $droneReactorParticles2, $droneReactorParticles3, $droneReactorParticles4]:
			p.queue_free()
		set_physics_process(false)
		queue_free()
	else:
		$anim.play("start")

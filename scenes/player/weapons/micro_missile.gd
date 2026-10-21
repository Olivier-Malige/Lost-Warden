extends Shot

const Impact := preload("res://scenes/player/weapons/micro_missile_impact.gd")

var hit_snapshot: PlayerHitSnapshot
var _hit_effects: WeakRef
var _reservation_key: StringName = &""
var steering_target: WeakRef
var reacquired := false
var remaining_lifetime := 0.0
var flight_speed := 0.0
var turn_speed := 0.0
var target_range := 0.0
var forward_angle_degrees := 90.0
var age := 0.0
var player_Id := ""
var damage := 0.0
var upgrade_rank := 1

func _ready() -> void:
	super._ready()
	add_to_group(&"micro_missile")
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()

func prepare() -> void:
	reset_hit_state()
	rotation = 0.0
	age = 0.0
	reacquired = false
	remaining_lifetime = 0.0
	flight_speed = 0.0
	turn_speed = 0.0
	target_range = 0.0
	speedX = 0.0
	speedY = 0.0
	damage = 0.0
	player_Id = ""
	upgrade_rank = 1
	$Sprite2D.frame = 0

func configure_missile(hit: PlayerHitSnapshot, service: Node, reservation: StringName, weapon: WeaponDefinition, target: WeakRef, rank: int) -> void:
	reset_hit_state()
	hit_snapshot = hit.copy()
	_hit_effects = weakref(service)
	_reservation_key = reservation
	steering_target = target
	player_Id = String(hit.owner_id())
	damage = hit.damage()
	flight_speed = weapon.projectile_speed
	turn_speed = deg_to_rad(weapon.turn_speed_degrees)
	target_range = weapon.target_range
	forward_angle_degrees = weapon.forward_angle_degrees
	remaining_lifetime = weapon.projectile_lifetime
	rotation = 0.0
	age = 0.0
	reacquired = false
	speedX = 0.0
	speedY = -flight_speed
	upgrade_rank = rank
	$CollisionShape2D.shape.size = weapon.collision_sizes[rank - 1]
	$CollisionShape2D.position = weapon.collision_offsets[rank - 1]
	$Sprite2D.frame = (16 if player_Id == "player2" else 0) + (rank - 1) * 4

func reset_hit_state() -> void:
	var service = _hit_effects.get_ref() if _hit_effects else null
	if is_instance_valid(service):
		service.release_root(hit_snapshot)
		service.release_reservation(_reservation_key)
	hit_snapshot = null
	_hit_effects = null
	_reservation_key = &""
	steering_target = null
	reacquired = false

func _physics_process(delta: float) -> void:
	if get_meta("pooled", false):
		return
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		ProjectilePool.despawn(self)
		return
	var target: Area2D = steering_target.get_ref() if steering_target else null
	if not CombatTargeting.eligible(get_parent(), target) or not CombatTargeting.in_forward_cone(global_position, target.global_position, forward_angle_degrees):
		steering_target = null
		if not reacquired:
			reacquired = true
			var exclusions: Array[RID] = []
			if is_instance_valid(target) and not CombatTargeting.eligible(get_parent(), target):
				exclusions = CombatTargeting.origin_exclusions(target)
			var targets := CombatTargeting.targets(get_parent(), global_position, target_range, {}, true, exclusions, forward_angle_degrees)
			if not targets.is_empty():
				steering_target = weakref(targets[0])
			target = steering_target.get_ref() if steering_target else null
		else:
			target = null
	if is_instance_valid(target):
		var desired := Vector2.UP.angle_to(global_position.direction_to(target.global_position))
		rotation = rotate_toward(rotation, desired, turn_speed * delta)
	var velocity := Vector2.UP.rotated(rotation) * flight_speed
	speedX = velocity.x
	speedY = velocity.y
	global_position += velocity * delta
	age += delta
	$Sprite2D.frame = (16 if player_Id == "player2" else 0) + (upgrade_rank - 1) * 4 + int(age / 0.06) % 4

func _on_area_entered(area: Area2D) -> void:
	if get_meta("pooled", false) or hit_snapshot == null:
		return
	var service = _hit_effects.get_ref() if _hit_effects else null
	var armored: bool = area.get("armored") == true
	var accepted: bool = is_instance_valid(service) and service.resolve_hit(hit_snapshot, area, true, global_position)
	if not accepted and not armored:
		return
	Impact.spawn(get_parent(), global_position, hit_snapshot.owner_id())
	ProjectilePool.despawn(self)

func _exit_tree() -> void:
	reset_hit_state()

extends Shot

const _Feedback := preload("res://scenes/effects/combat_feedback.gd")
const _ProjectileGlow := preload("res://scenes/combat/projectile_glow.gd")

@export var damage: float
@export var damage_Max: float
@export var power_Small: float
@export var power_Normal: float
@export var power_Big: float
@export var power_Large: float
@export var power_Full: float
@export var piercing := false
@export var vfx_config: ProjectileVfxConfig
var player_Id: String
var _base_damage: float = -1.0
var _base_speed_y := 0.0
var _follow_target: Node2D
var _follow_offset := Vector2.ZERO
var _follow_time := 0.0
var _source_sprite: Sprite2D
var _laser_glow: Sprite2D
var hit_snapshot: PlayerHitSnapshot
var _hit_effects: WeakRef
var _reservation_key: StringName = &""
var _visited_groups: Array[WeakRef] = []
var remaining_penetrations := 0
var remaining_lifetime := -1.0
var steering_target: WeakRef
var _base_piercing := false


func _ready() -> void:
	super._ready()
	if _base_damage < 0.0:
		_base_damage = damage
		_base_speed_y = speedY
		_base_piercing = piercing
	damage = minf(damage, damage_Max)
	_create_laser_glow()


func prepare() -> void:
	reset_hit_state()
	$anim.stop()
	damage = _base_damage
	speedX = 0
	speedY = _base_speed_y
	_follow_target = null
	_follow_time = 0.0
	_follow_offset = Vector2.ZERO
	player_Id = ""
	piercing = _base_piercing
	trowbackByShield = false
	rotation = 0.0
	scale = Vector2.ONE

# The initial root lease transfers to the projectile; queued children transfer their reservation.
func configure_hit(hit: PlayerHitSnapshot, effects: PlayerHitEffects, reservation: StringName = &"") -> void:
	reset_hit_state()
	hit_snapshot = hit.copy()
	_hit_effects = weakref(effects)
	_reservation_key = reservation

func reset_hit_state() -> void:
	var effects: PlayerHitEffects = _hit_effects.get_ref() if _hit_effects else null
	if is_instance_valid(effects):
		effects.release_root(hit_snapshot)
		effects.release_reservation(_reservation_key)
	hit_snapshot = null
	_hit_effects = null
	_reservation_key = &""
	_visited_groups.clear()
	remaining_penetrations = 0
	remaining_lifetime = -1.0
	steering_target = null

func _exit_tree() -> void:
	reset_hit_state()

func set_damage_bonus(extra_damage: float) -> void:
	damage = minf(_base_damage + extra_damage, damage_Max)
	setPowerAnim()

func set_foundation_damage(authored_base: float, multiplier: float, visual_tier: int) -> void:
	damage = minf(authored_base, damage_Max) * multiplier
	$anim.play(player_Id + ["_small", "_normal", "_big", "_large", "_full"][clampi(visual_tier, 0, 4)])
	$anim.advance(0.0)

func _physics_process(delta: float) -> void:
	if remaining_lifetime >= 0.0:
		remaining_lifetime -= delta
		if remaining_lifetime <= 0.0:
			ProjectilePool.despawn(self)
			return
	_sync_laser_glow()
	if is_instance_valid(_follow_target) and _follow_time > 0.0:
		global_position = _follow_target.global_position + _follow_offset
		_follow_time = maxf(_follow_time - delta, 0.0)
		if _follow_time <= 0.0:
			ProjectilePool.despawn(self)
		return
	super._physics_process(delta)


func _create_laser_glow() -> void:
	if vfx_config == null or not vfx_config.is_valid():
		return
	for child in get_children():
		if child is Sprite2D:
			_source_sprite = child as Sprite2D
			break
	if _source_sprite == null:
		return
	_laser_glow = _ProjectileGlow.create(
		_source_sprite,
		vfx_config.glow_color(player_Id),
		vfx_config.core_brightness,
		_get_glow_size(),
		vfx_config.glow_material
	)
	_laser_glow.name = "LaserGlow"
	if vfx_config.glow_behind_sprite:
		_laser_glow.z_index = _source_sprite.z_index - 1
	_sync_laser_glow()


func _sync_laser_glow() -> void:
	if _source_sprite == null or _laser_glow == null:
		return
	_ProjectileGlow.sync(_source_sprite, _laser_glow, vfx_config.glow_color(player_Id), _get_glow_size())


func _get_glow_size() -> Vector2:
	return vfx_config.glow_spread * vfx_config.glow_scale

func follow_player(target: Node2D, offset: Vector2, duration: float) -> void:
	_follow_target = target
	_follow_offset = offset
	_follow_time = duration
	speedX = 0
	speedY = 0


# Call after setting damage and player_Id, before the shot is visible.
func setPowerAnim() -> void:
	for tier in [[power_Full, "_full"], [power_Large, "_large"], [power_Big, "_big"], [power_Normal, "_normal"], [power_Small, "_small"]]:
		if damage >= tier[0]:
			$anim.play(player_Id + tier[1])
			$anim.advance(0.0)
			return
	$anim.play(player_Id + "_small")
	$anim.advance(0.0)


func _on_area_entered(area: Area2D) -> void:
	if get_meta("pooled", false):
		return
	if area.is_in_group("enemy") or area.is_in_group("asteroid") or area.is_in_group("turret") or area.is_in_group("boss_hit_zone"):
		var accent: Color = Color("96a5b5") if area.get("armored") == true else _Feedback.GOLD
		_Feedback.spawn(get_parent(), global_position, accent)
		var effects: PlayerHitEffects = _hit_effects.get_ref() if _hit_effects else null
		if hit_snapshot and is_instance_valid(effects):
			effects.resolve_hit(hit_snapshot, area, true, global_position)
		elif area.has_method("receive_player_hit"):
			var group := CombatTargeting.damage_group(area)
			var visited := _visited_groups.any(func(reference: WeakRef): return reference.get_ref() == group)
			if not visited and area.receive_player_hit(damage, StringName(player_Id)):
				_visited_groups.append(weakref(group))
		if not piercing:
			ProjectilePool.despawn(self)

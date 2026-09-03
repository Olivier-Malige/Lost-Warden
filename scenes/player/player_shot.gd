extends Shot

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
var _base_speed_y := 0
var _follow_target: Node2D
var _follow_offset := Vector2.ZERO
var _follow_time := 0.0
var _source_sprite: Sprite2D
var _laser_glow: Sprite2D


func _ready() -> void:
	super._ready()
	if _base_damage < 0.0:
		_base_damage = damage
		_base_speed_y = speedY
	damage = minf(damage, damage_Max)
	_create_laser_glow()


func prepare() -> void:
	damage = _base_damage
	speedX = 0
	speedY = _base_speed_y
	_follow_target = null
	_follow_time = 0.0

func set_damage_bonus(extra_damage: float) -> void:
	damage = minf(_base_damage + extra_damage, damage_Max)
	setPowerAnim()

func _physics_process(delta: float) -> void:
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
			return
	$anim.play(player_Id + "_small")


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") or area.is_in_group("asteroid") or area.is_in_group("turret"):
		area.hitByPlayerShot = true
		area._hit_something(damage)
		if not piercing:
			ProjectilePool.despawn(self)

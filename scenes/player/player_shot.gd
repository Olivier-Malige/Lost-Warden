extends Shot

@export var damage: float
@export var damage_Max: float
@export var power_Small: float
@export var power_Normal: float
@export var power_Big: float
@export var power_Large: float
@export var power_Full: float
@export var piercing := false
var player_Id
var _base_damage: float = -1.0
var _base_speed_y := 0
var _follow_target: Node2D
var _follow_offset := Vector2.ZERO
var _follow_time := 0.0


func _ready() -> void:
	super._ready()
	if _base_damage < 0.0:
		_base_damage = damage
		_base_speed_y = speedY
	damage = minf(damage, damage_Max)


func prepare() -> void:
	damage = _base_damage
	speedX = 0
	speedY = _base_speed_y
	_follow_target = null
	_follow_time = 0.0

func _process(delta: float) -> void:
	if is_instance_valid(_follow_target) and _follow_time > 0.0:
		global_position = _follow_target.global_position + _follow_offset
		_follow_time = maxf(_follow_time - delta, 0.0)
		if _follow_time <= 0.0:
			ProjectilePool.despawn(self)
		return
	super._process(delta)

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


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") or area.is_in_group("asteroid") or area.is_in_group("turret"):
		area.hitByPlayerShot = true
		area._hit_something(damage)
		if not piercing:
			ProjectilePool.despawn(self)

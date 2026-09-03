extends Shot

const SPEED_Y := 550.0
const _ProjectileGlow := preload("res://scenes/combat/projectile_glow.gd")

@export var damage := 10
@export var noDamageToGroup := ""
@export var glow_color := Color(0.2, 1.0, 0.36, 0.42)
@export_range(1.0, 3.0, 0.05) var core_brightness := 1.45
@export var glow_spread := Vector2(1.65, 0.85)

func _ready() -> void:
	super._ready()
	speedY = SPEED_Y
	_create_projectile_glow()


func _create_projectile_glow() -> void:
	var source_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if source_sprite == null:
		return
	_ProjectileGlow.create(source_sprite, glow_color, core_brightness, glow_spread)

func prepare() -> void:
	speedY = SPEED_Y
	speedX = 0.0
	trowbackByShield = false
	rotation = 0

func is_enemy() -> bool:
	return true

func _on_shot_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if trowbackByShield or (area.has_node("shield") and area.get_node("shield").power > 0):
			return
		_hit_area(area)
	elif area.is_in_group("asteroid"):
		_hit_area(area)
	elif trowbackByShield and area.is_in_group("enemy") and not area.is_in_group(noDamageToGroup):
		area.hitByPlayerShot = true
		_hit_area(area)


func _hit_area(area: Area2D) -> void:
	if area.has_method("_hit_something"):
		area._hit_something(damage)
	ProjectilePool.despawn(self)

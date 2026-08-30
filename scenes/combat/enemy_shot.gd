extends Shot
const SPEED_Y := 550.0
@export var damage := 10
@export var noDamageToGroup := ""

func _ready() -> void:
	super._ready()
	speedY = SPEED_Y

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

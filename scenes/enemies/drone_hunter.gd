extends Enemy

const CHASE := preload("res://data/enemies/movement/boss_drone_chase.tres")
const ELITE_TEXTURE := preload("res://assets/sprites/enemies/animation_rework/razor_wing_hunter_elite_sheet.png")

@onready var _reactors: Array[GPUParticles2D] = [$droneReactorParticles, $droneReactorParticles2]
@onready var _reactor_offsets: Array[Vector2] = [_reactors[0].position, _reactors[1].position]

func _ready() -> void:
	if _spawn_context.movement_profile == null:
		_spawn_context.movement_profile = CHASE
	super._ready()
	if elite:
		$Sprite2D.texture = ELITE_TEXTURE
		_elite_indicator.hide()

# Keep the native hull and its contact surface aligned throughout a chase.
func _update_ship_banking(_delta: float) -> void:
	var velocity := Vector2(speedX, speedY)
	if _hit_sprite == null or velocity.is_zero_approx():
		return
	var heading := Vector2.DOWN.angle_to(velocity)
	_hit_sprite.rotation = heading
	$CollisionShape2D.rotation = heading
	for index in _reactors.size():
		_reactors[index].position = _reactor_offsets[index].rotated(heading)
		_reactors[index].rotation = PI + heading

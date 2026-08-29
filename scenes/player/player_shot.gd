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
var _glow_sources: Array[Sprite2D] = []
var _glows: Array[Sprite2D] = []
var _trail: Line2D


func _ready() -> void:
	super._ready()
	if _base_damage < 0.0:
		_base_damage = damage
		_base_speed_y = speedY
	damage = minf(damage, damage_Max)
	_create_glows()
	_create_trail()


func prepare() -> void:
	damage = _base_damage
	speedX = 0
	speedY = _base_speed_y
	_follow_target = null
	_follow_time = 0.0

func set_damage_bonus(extra_damage: float) -> void:
	damage = minf(_base_damage + extra_damage, damage_Max)
	setPowerAnim()

func _process(delta: float) -> void:
	_sync_glows()
	_sync_trail()
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
			_apply_player_color()
			_sync_glows()
			return
	$anim.play(player_Id + "_small")
	_apply_player_color()
	_sync_glows()

func _apply_player_color() -> void:
	var color := Color(0.25, 0.95, 1.0) if player_Id == "player1" else Color(1.0, 0.42, 0.72)
	for source in _glow_sources:
		source.modulate = color
	if _trail:
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color.WHITE, color, Color(color.r, color.g, color.b, 0.0)])
		gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		_trail.gradient = gradient

func _create_glows() -> void:
	if global.saveData.config.graphic == "low" or not _glows.is_empty():
		return
	for child in get_children():
		var source := child as Sprite2D
		if source == null:
			continue
		var glow := Sprite2D.new()
		glow.texture = source.texture
		glow.hframes = source.hframes
		glow.vframes = source.vframes
		glow.position = source.position
		glow.scale = source.scale * 2.15
		glow.modulate = Color(0.3, 0.9, 1.0, 0.58)
		glow.z_index = -1
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = material
		add_child(glow)
		_glow_sources.append(source)
		_glows.append(glow)

func _sync_glows() -> void:
	for index in _glows.size():
		var source := _glow_sources[index]
		var glow := _glows[index]
		if not is_instance_valid(source) or not is_instance_valid(glow):
			continue
		glow.frame = source.frame
		glow.flip_h = source.flip_h
		glow.flip_v = source.flip_v

func _create_trail() -> void:
	if piercing or global.saveData.config.graphic == "low":
		return
	_trail = Line2D.new()
	_trail.width = 6.0
	_trail.antialiased = false
	_trail.z_index = -2
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.95, 0.98, 1.0, 0.95), Color(0.15, 0.8, 1.0, 0.45), Color(0.15, 0.8, 1.0, 0.0)])
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	_trail.gradient = gradient
	add_child(_trail)

func _sync_trail() -> void:
	if _trail == null:
		return
	var velocity := Vector2(speedX, speedY)
	if velocity.length_squared() <= 0.0:
		return
	_trail.points = PackedVector2Array([Vector2.ZERO, -velocity.normalized() * 34.0])


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") or area.is_in_group("asteroid") or area.is_in_group("turret"):
		area.hitByPlayerShot = true
		area._hit_something(damage)
		if not piercing:
			ProjectilePool.despawn(self)

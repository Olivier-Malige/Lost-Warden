extends Shot

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
var _glow_sources: Array[Sprite2D] = []
var _glows: Array[Sprite2D] = []
var _trail: Line2D


func _ready() -> void:
	super._ready()
	if vfx_config == null or not vfx_config.is_valid():
		push_error("ProjectileVfxConfig is required for %s." % scene_file_path)
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

func _physics_process(delta: float) -> void:
	_sync_glows()
	_sync_trail()
	if is_instance_valid(_follow_target) and _follow_time > 0.0:
		global_position = _follow_target.global_position + _follow_offset
		_follow_time = maxf(_follow_time - delta, 0.0)
		if _follow_time <= 0.0:
			ProjectilePool.despawn(self)
		return
	super._physics_process(delta)

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
	if vfx_config == null:
		return
	var color := vfx_config.player_color(player_Id)
	for index in range(_glows.size()):
		_glow_sources[index].modulate = color
		_glows[index].modulate = vfx_config.glow_color(player_Id)
	if _trail:
		var trail_color := vfx_config.trail_color(player_Id)
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([vfx_config.trail_head_color, trail_color, Color(trail_color.r, trail_color.g, trail_color.b, 0.0)])
		gradient.offsets = PackedFloat32Array([0.0, vfx_config.trail_middle_offset, 1.0])
		_trail.gradient = gradient

func _create_glows() -> void:
	if vfx_config == null or global.saveData.config.graphic == "low" or not _glows.is_empty():
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
		glow.scale = source.scale * vfx_config.glow_scale
		glow.modulate = vfx_config.glow_color(player_Id)
		glow.z_index = -1
		glow.material = vfx_config.glow_material
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
	if vfx_config == null or piercing or global.saveData.config.graphic == "low":
		return
	_trail = Line2D.new()
	_trail.width = vfx_config.trail_width
	_trail.antialiased = false
	_trail.z_index = -2
	add_child(_trail)
	_apply_player_color()

func _sync_trail() -> void:
	if _trail == null:
		return
	var velocity := Vector2(speedX, speedY)
	if velocity.length_squared() <= 0.0:
		return
	_trail.points = PackedVector2Array([Vector2.ZERO, -velocity.normalized() * vfx_config.trail_length])


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") or area.is_in_group("asteroid") or area.is_in_group("turret"):
		area.hitByPlayerShot = true
		area._hit_something(damage)
		if not piercing:
			ProjectilePool.despawn(self)

extends Enemy

enum Role { DIVER, BOMBER, SNIPER, STALKER, BASTION, COMMANDER }

signal reinforcement_signal

const SHOT := preload("res://scenes/combat/tie_shot.tscn")
const WARNING := Color("#ffa467")

@export var role: Role
@export var hull_texture: Texture2D
@export var elite_hull_texture: Texture2D

var _hull_sprite: Sprite2D
var _stage := 0
var _left := 0.0
var _aim := Vector2.DOWN
var _charge := Vector2.DOWN
var _bombs: Array[Vector2] = []
var _entry := Vector2.ZERO
var _stop := Vector2.ZERO
var _horizontal := 1.0
var _started_attack := false

func _ready() -> void:
	_entry = position
	super._ready()
	position = _entry
	$ShootTimer.stop()
	$Sprite2D.hide()
	_hull_sprite = Sprite2D.new()
	_hull_sprite.texture = elite_hull_texture if elite else hull_texture
	_hull_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hull_sprite.material = HIT_FLASH_MATERIAL
	add_child(_hull_sprite)
	_hit_sprite = _hull_sprite
	var arena := _arena_size()
	_horizontal = 1.0 if position.x < arena.x * 0.5 else -1.0
	_stop = Vector2(clampf(position.x + _horizontal * 48.0, 150.0, arena.x - 150.0), 76.0)
	if role == Role.STALKER:
		_stop = Vector2(position.x, arena.y * 0.43)
	elif role == Role.SNIPER:
		_stop.x = 145.0 if _horizontal > 0.0 else arena.x - 145.0
	elif role == Role.BOMBER:
		_stop.y = 52.0
	elif role == Role.DIVER:
		_stop.y = clampf(position.y + 35.0, 96.0, 160.0)

func _on_ShootTimer_timeout() -> void:
	pass

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	hitByPlayerShot = false
	_left -= delta
	if _stage == 0:
		position = position.move_toward(_stop, 145.0 * _movement_speed_scale() * delta)
		if position == _stop:
			_begin_attack()
	elif _stage == 1:
		_telegraph(delta)
		if _left <= 0.0:
			_execute()
	elif _stage == 2 and role == Role.BASTION:
		if _left <= 0.0:
			_fire_fan(5, 0.22, 165.0)
			_stage = 3
			_left = 1.5
	elif _stage == 3 and role == Role.BASTION and _left > 0.0:
		position.y += 20.0 * delta
	else:
		var velocity := _charge * 265.0 if role == Role.DIVER else Vector2(_horizontal * 35.0, -95.0)
		if role == Role.STALKER or role == Role.BASTION or role == Role.COMMANDER:
			velocity = Vector2(_horizontal * 22.0, 102.0)
		position += velocity * _movement_speed_scale() * delta
	var bounds := Rect2(Vector2.ZERO, _arena_size()).grow(44.0)
	if _started_attack and not bounds.has_point(position):
		_on_screen_exited()
	queue_redraw()

func _begin_attack() -> void:
	_started_attack = true
	_stage = 1
	_aim = _target_direction()
	match role:
		Role.DIVER:
			_left = 0.65
			_charge = Vector2(_aim.x, maxf(_aim.y, 0.3)).normalized()
		Role.BOMBER:
			_left = 0.9
			var center := clampf(position.x, 128.0, _arena_size().x - 128.0)
			_bombs.assign([Vector2(center - 78.0, 278.0), Vector2(center + 78.0, 278.0)])
		Role.SNIPER:
			_left = 1.15
		Role.STALKER:
			_left = 0.35
		Role.BASTION:
			_left = 0.65
		Role.COMMANDER:
			_left = 0.7

func _telegraph(delta: float) -> void:
	if role == Role.SNIPER and _left > 0.8:
		_aim = _target_direction()
	elif role == Role.BOMBER:
		position.x += _horizontal * 82.0 * delta

func _execute() -> void:
	_stage = 2
	match role:
		Role.BOMBER:
			for player in get_tree().get_nodes_in_group(&"player"):
				if player is Player:
					for bomb in _bombs:
						if player.global_position.distance_to(_bomb_world_position(bomb)) <= 36.0:
							player.vitals.hit(1)
							break
			_left = 0.18
		Role.SNIPER:
			_fire_fan(1, 0.0, 335.0)
		Role.STALKER:
			_fire_fan(3, 0.26, 185.0)
		Role.BASTION:
			_fire_fan(5, 0.22, 165.0)
			_left = 0.45 * fire_delay_multiplier
		Role.COMMANDER:
			$sound_Shooting.play()
			_flash_hit(true)
			reinforcement_signal.emit()

func _arena_size() -> Vector2:
	return get_viewport_rect().size - Vector2(2.0 * _playfield_side_width(), 0.0)

func _bomb_world_position(center: Vector2) -> Vector2:
	return (get_parent() as Node2D).to_global(center)

func _target_direction() -> Vector2:
	var nearest := INF
	var direction := Vector2.DOWN
	for player in get_tree().get_nodes_in_group(&"player"):
		if player is Player and int(player.state) < 2:
			var distance := global_position.distance_squared_to(player.global_position)
			if distance < nearest and distance > 1.0:
				nearest = distance
				direction = global_position.direction_to(player.global_position)
	return direction

func _fire_fan(count: int, angle: float, speed: float) -> void:
	var active := 0
	for projectile in get_tree().get_nodes_in_group(&"enemy_Shot"):
		if not projectile.get_meta(&"pooled", false):
			active += 1
	var cap := 128 if global.coop else 96
	if active + count > cap:
		return
	$sound_Shooting.play()
	for index in count:
		var direction := _aim.rotated((index - (count - 1) * 0.5) * angle)
		var shot := _spawn_shot_velocity(SHOT, global_position + direction * 10.0, direction * speed) as Node2D
		shot.rotation = direction.angle() - PI * 0.5

func _destroy() -> void:
	super._destroy()
	_hull_sprite.hide()
	$Sprite2D.show()
	queue_redraw()

func _draw() -> void:
	if destroyed or not is_node_ready():
		return
	if role == Role.BOMBER and (_stage == 1 or (_stage == 2 and _left > 0.0)):
		for bomb in _bombs:
			var center := to_local(_bomb_world_position(bomb))
			draw_circle(center, 36.0, Color(WARNING, 0.12 if _stage == 1 else 0.55))
			draw_arc(center, 36.0, 0.0, TAU, 32, WARNING, 1.0)
	elif _stage == 1:
		match role:
			Role.DIVER:
				draw_line(Vector2.ZERO, _charge * 110.0, WARNING, 1.0)
			Role.SNIPER:
				draw_line(Vector2.ZERO, _aim * 760.0, Color(WARNING, 0.85 if _left <= 0.8 else 0.35), 1.0)
			_:
				draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 24, WARNING, 1.0)

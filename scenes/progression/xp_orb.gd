class_name XpOrb
extends Area2D

const Layers := preload("res://core/collision_layers.gd")
const Glow := preload("res://scenes/combat/projectile_glow.gd")
var value := 0
var pool: Node
var target: WeakRef
var collected := false
var entry: Dictionary = {}
@onready var _glow: Sprite2D = $XpGlow
var _glow_phase := 0.0

func _ready() -> void:
	collision_layer = Layers.PICKUP
	collision_mask = Layers.PLAYER

func prepare(amount: int, owner_pool: Node, reservation: Dictionary) -> void:
	value = amount
	pool = owner_pool
	entry = reservation
	target = null
	collected = false
	_glow_phase = 0.0
	set_meta("pooled", false)
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	$CollisionShape2D.set_deferred("disabled", false)
	_update_sprite()

func _physics_process(delta: float) -> void:
	if collected or get_meta("pooled", true):
		return
	_glow_phase = fmod(_glow_phase + delta * TAU / 1.2, TAU)
	_update_glow_pulse()
	var player: Player = target.get_ref() if target else null
	if not _eligible(player):
		player = _nearest_player()
		target = weakref(player) if player else null
	if player:
		global_position = global_position.move_toward(player.global_position, 260.0 * delta)
		if global_position.distance_to(player.global_position) <= 8.0:
			_collect(player)
	else:
		position.y += 60.0 * delta
	if not get_meta("pooled", true) and global_position.y > get_viewport_rect().size.y + 16.0:
		pool.release(self)

func _eligible(player: Player) -> bool:
	return is_instance_valid(player) and player.state in [Player.State.ACTIVE, Player.State.HIT]

func _nearest_player() -> Player:
	var nearest: Player
	var distance := INF
	for player in pool.living_players():
		var separation := global_position.distance_squared_to(player.global_position)
		var nearer: bool = separation < distance or (separation == distance and player.id_Player == "player1")
		if separation <= pow(player.loadout.attraction_radius, 2) and nearer:
			nearest = player
			distance = separation
	return nearest

func _on_area_entered(area: Area2D) -> void:
	if area is Player and _eligible(area) and global_position.distance_to(area.global_position) <= 8.0:
		var retained: Player = target.get_ref() if target else null
		if not _eligible(retained) or retained == area:
			_collect(area)

func _collect(player: Player) -> void:
	if collected or get_meta("pooled", true):
		return
	collected = true
	pool.collect(self, StringName(player.id_Player))

func _update_sprite() -> void:
	$Sprite2D.frame = 1 if value >= 4 else 0
	Glow.sync($Sprite2D, _glow, Color.WHITE, Vector2.ONE * (4.5 if value >= 4 else 3.5))
	_update_glow_pulse()

func _update_glow_pulse() -> void:
	_glow.modulate.a = 0.8 + 0.15 * sin(_glow_phase)

func _on_screen_exited() -> void:
	if not get_meta("pooled", true):
		pool.release(self)

class_name ContinuousBeam
extends Area2D

const Layers := preload("res://core/collision_layers.gd")
const TOP_EDGE := 0.0
const PLAYER_ONE_COLOR := Color(1.0, 0.12, 0.08, 1.0)
const PLAYER_TWO_COLOR := Color(0.12, 0.48, 1.0, 1.0)
const GLOW_ALPHA := 0.72

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var outer_line: Line2D = $OuterLine
@onready var core_line: Line2D = $CoreLine

var active := false
var overdrive := false
var damage := 3.0
var damage_interval := 0.1
var player_id := "player1"
var beam_width := 32.0
var overdrive_width := 64.0
var overdrive_damage_multiplier := 1.5
var _damage_accumulator := 0.0
var _shape := RectangleShape2D.new()

func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.ENEMY | Layers.ASTEROID
	monitoring = false
	monitorable = false
	visible = false
	collision_shape.shape = _shape
	collision_shape.disabled = true
	set_physics_process(false)

func activate(p_player_id: String, p_damage: float, p_overdrive: bool) -> void:
	player_id = p_player_id
	damage = p_damage
	overdrive = p_overdrive
	_damage_accumulator = 0.0
	active = true
	_apply_player_color()
	_update_width()
	_update_geometry()
	visible = true
	set_physics_process(true)
	collision_shape.set_deferred("disabled", false)
	set_deferred("monitoring", true)

func deactivate() -> void:
	active = false
	overdrive = false
	_damage_accumulator = 0.0
	visible = false
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)

func set_overdrive(enabled: bool) -> void:
	if overdrive == enabled:
		return
	overdrive = enabled
	_update_width()
	_update_geometry()

func set_damage(p_damage: float) -> void:
	damage = p_damage

func _physics_process(delta: float) -> void:
	if not active:
		return
	_update_geometry()
	_damage_accumulator += delta
	while _damage_accumulator >= damage_interval:
		_damage_accumulator -= damage_interval
		_damage_overlaps()

func _damage_overlaps() -> void:
	var tick_damage := damage * (overdrive_damage_multiplier if overdrive else 1.0)
	for area in get_overlapping_areas():
		var enemy := area as Enemy
		if enemy == null or enemy.destroyed:
			continue
		enemy.hitByPlayerShot = true
		enemy._hit_something(tick_damage, false)

func _update_geometry() -> void:
	var length := maxf(global_position.y - TOP_EDGE, 1.0)
	var width := overdrive_width if overdrive else beam_width
	_shape.size = Vector2(width, length)
	collision_shape.position = Vector2(0.0, -length * 0.5)
	var points := PackedVector2Array([Vector2.ZERO, Vector2(0.0, -length)])
	outer_line.points = points
	core_line.points = points

func _update_width() -> void:
	var width := overdrive_width if overdrive else beam_width
	outer_line.width = width
	core_line.width = width * 0.38

func _apply_player_color() -> void:
	var color := PLAYER_ONE_COLOR if player_id == "player1" else PLAYER_TWO_COLOR
	outer_line.modulate = Color(color.r, color.g, color.b, GLOW_ALPHA)
	core_line.modulate = color.lightened(0.25)

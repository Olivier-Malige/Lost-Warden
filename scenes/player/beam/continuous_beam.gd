class_name ContinuousBeam
extends Area2D

const Layers := preload("res://core/collision_layers.gd")
const IMPACT_FEEDBACK := preload("res://scenes/effects/combat_feedback.gd")
const TOP_EDGE := 0.0
const PLAYER_ONE_COLOR := Color(1.0, 0.12, 0.08, 1.0)
const PLAYER_TWO_COLOR := Color(0.12, 0.48, 1.0, 1.0)
const HALO_ALPHA := 0.14
const FLOW_FRAME_DURATION := 0.16

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var halo_line: Line2D = $HaloLine
@onready var outer_line: Line2D = $OuterLine
@onready var flow_material: ShaderMaterial = $OuterLine.material
@onready var beam_audio: AudioStreamPlayer2D = $BeamAudio
@onready var impact_cast: ShapeCast2D = $ImpactCast

var active := false
var overdrive := false
var damage := 3.0
var damage_interval := 0.1
var player_id := "player1"
var beam_width := 8.0
var overdrive_width := 16.0
var collision_width_multiplier := 1.2
var overdrive_damage_multiplier := 1.5
var _damage_accumulator := 0.0
var _flow_time := 0.0
var _shape := RectangleShape2D.new()
var _impact_target: Area2D
var _impact_point := Vector2.ZERO

func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.ENEMY | Layers.ASTEROID
	monitoring = false
	monitorable = false
	visible = false
	collision_shape.shape = _shape
	collision_shape.disabled = true
	impact_cast.collision_mask = collision_mask
	set_physics_process(false)

func activate(p_player_id: String, p_damage: float, p_overdrive: bool) -> void:
	player_id = p_player_id
	damage = p_damage
	overdrive = p_overdrive
	_damage_accumulator = 0.0
	_impact_target = null
	active = true
	_flow_time = 0.0
	flow_material.set_shader_parameter("frame_index", 0.0)
	_apply_player_color()
	_update_width()
	_update_geometry()
	visible = true
	if not beam_audio.playing:
		beam_audio.play()
	set_physics_process(true)
	collision_shape.set_deferred("disabled", false)
	set_deferred("monitoring", true)

func deactivate() -> void:
	active = false
	_impact_target = null
	overdrive = false
	_damage_accumulator = 0.0
	visible = false
	beam_audio.stop()
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
	_flow_time = fmod(_flow_time + delta, FLOW_FRAME_DURATION * 4.0)
	flow_material.set_shader_parameter("frame_index", floorf(_flow_time / FLOW_FRAME_DURATION))
	_damage_accumulator += delta
	while _damage_accumulator >= damage_interval:
		_damage_accumulator -= damage_interval
		_damage_overlaps()

func _damage_overlaps() -> void:
	_update_geometry()
	if not is_instance_valid(_impact_target):
		return
	var target := _impact_target
	if not (target is Enemy or target.is_in_group("boss_hit_zone")) or target.destroyed:
		return
	var tick_damage := damage * (overdrive_damage_multiplier if overdrive else 1.0)
	var color := Color("96a5b5") if target.get("armored") == true else (PLAYER_ONE_COLOR if player_id == "player1" else PLAYER_TWO_COLOR)
	IMPACT_FEEDBACK.spawn(target.get_parent(), to_global(_impact_point), color)
	var effects := PlayerHitEffects.find_service(self)
	if effects:
		var hit := effects.create_hit(StringName(player_id), damage, tick_damage, {}, PlayerHitSnapshot.Kind.PLASMA)
		if hit:
			effects.resolve_hit(hit, target, false, to_global(_impact_point))
			effects.release_root(hit)
	elif target.has_method("receive_player_hit"):
		target.receive_player_hit(tick_damage, StringName(player_id), false)
	if not is_instance_valid(target) or target.destroyed:
		_update_geometry()

func _update_geometry() -> void:
	var length := maxf(global_position.y - TOP_EDGE, 1.0)
	var width := overdrive_width if overdrive else beam_width
	impact_cast.shape.size = Vector2(width * collision_width_multiplier, 0.1)
	impact_cast.clear_exceptions()
	var origin_blocked := _cast_first_obstacle(length)
	_impact_target = null
	while impact_cast.is_colliding():
		var collider = impact_cast.get_collider(0)
		if collider is Area2D and collider.get("destroyed") == true:
			impact_cast.add_exception(collider)
			origin_blocked = _cast_first_obstacle(length)
			continue
		_impact_target = collider as Area2D
		_impact_point = Vector2.ZERO if origin_blocked else to_local(impact_cast.get_collision_point(0))
		length = 1.0 if origin_blocked else clampf(-_impact_point.y, 1.0, length)
		break
	flow_material.set_shader_parameter("flow_length", length * (16.0 if overdrive else 8.0) / width)
	_shape.size = Vector2(width * collision_width_multiplier, length)
	collision_shape.position = Vector2(0.0, -length * 0.5)
	var points := PackedVector2Array([Vector2.ZERO, Vector2(0.0, -length)])
	halo_line.points = points
	outer_line.points = points

# A moving shape query can skip an obstacle already overlapping the emitter.
func _cast_first_obstacle(length: float) -> bool:
	impact_cast.target_position = Vector2.ZERO
	impact_cast.force_shapecast_update()
	if impact_cast.is_colliding():
		return true
	impact_cast.target_position = Vector2(0, -length)
	impact_cast.force_shapecast_update()
	return false

func _update_width() -> void:
	var width := overdrive_width if overdrive else beam_width
	halo_line.width = width * 1.35
	outer_line.width = width
	flow_material.set_shader_parameter("overdrive", overdrive)

func _apply_player_color() -> void:
	var color := PLAYER_ONE_COLOR if player_id == "player1" else PLAYER_TWO_COLOR
	halo_line.modulate = Color(color.r, color.g, color.b, HALO_ALPHA)
	flow_material.set_shader_parameter("team_row", 0.0 if player_id == "player1" else 1.0)

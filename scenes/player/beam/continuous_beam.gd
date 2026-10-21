class_name ContinuousBeam
extends Area2D

const Layers := preload("res://core/collision_layers.gd")
const IMPACT_FEEDBACK := preload("res://scenes/effects/combat_feedback.gd")
const TOP_EDGE := 0.0
const PLAYER_ONE_COLOR := Color(1.0, 0.12, 0.08, 1.0)
const PLAYER_TWO_COLOR := Color(0.12, 0.48, 1.0, 1.0)
const HALO_ALPHA := 0.14
const FLOW_FRAME_DURATION := 0.16
const PIERCING_RETAINED := 0.8
const MAX_EXTRA_TARGETS := 3

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
var extra_targets := 0
var _segments: Array[Dictionary] = []
var _contacts: Array[Dictionary] = []
var _outer_segments: Array[Line2D] = []
var _halo_segments: Array[Line2D] = []
var _collision_segments: Array[CollisionShape2D] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.ENEMY | Layers.ASTEROID
	monitoring = false
	monitorable = false
	visible = false
	collision_shape.shape = _shape
	collision_shape.disabled = true
	impact_cast.collision_mask = collision_mask
	_outer_segments.append(outer_line)
	_halo_segments.append(halo_line)
	_collision_segments.append(collision_shape)
	for index in MAX_EXTRA_TARGETS:
		var outer := outer_line.duplicate() as Line2D
		outer.name = "PiercingOuter%d" % index
		outer.material = flow_material.duplicate()
		add_child(outer)
		_outer_segments.append(outer)
		var halo := halo_line.duplicate() as Line2D
		halo.name = "PiercingHalo%d" % index
		add_child(halo)
		_halo_segments.append(halo)
		var collision := CollisionShape2D.new()
		collision.name = "PiercingCollision%d" % index
		collision.shape = RectangleShape2D.new()
		collision.disabled = true
		add_child(collision)
		_collision_segments.append(collision)
	set_physics_process(false)

func activate(p_player_id: String, p_damage: float, p_overdrive: bool) -> void:
	player_id = p_player_id
	damage = p_damage
	overdrive = p_overdrive
	_damage_accumulator = 0.0
	_impact_target = null
	active = true
	_flow_time = 0.0
	for line in _outer_segments:
		(line.material as ShaderMaterial).set_shader_parameter("frame_index", 0.0)
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
	_contacts.clear()
	_segments.clear()
	_damage_accumulator = 0.0
	visible = false
	beam_audio.stop()
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	for collision in _collision_segments: collision.set_deferred("disabled", true)
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
	for line in _outer_segments:
		(line.material as ShaderMaterial).set_shader_parameter("frame_index", floorf(_flow_time / FLOW_FRAME_DURATION))
	_damage_accumulator += delta
	while _damage_accumulator >= damage_interval:
		_damage_accumulator -= damage_interval
		_damage_overlaps()

func _damage_overlaps() -> void:
	_update_geometry()
	var tick_damage := damage * (overdrive_damage_multiplier if overdrive else 1.0)
	var effects := PlayerHitEffects.find_service(self)
	var hit := effects.create_hit(StringName(player_id), damage, tick_damage, {}, PlayerHitSnapshot.Kind.PLASMA) if effects and not _contacts.is_empty() else null
	var changed := false
	for contact in _contacts:
		var target: Area2D = contact.target.get_ref()
		if not is_instance_valid(target) or target.get("destroyed") == true:
			continue
		var color := Color("96a5b5") if target.get("armored") == true else (PLAYER_ONE_COLOR if player_id == "player1" else PLAYER_TWO_COLOR)
		IMPACT_FEEDBACK.spawn(target.get_parent(), to_global(contact.point), color)
		if effects:
			if hit: effects.resolve_hit(hit.scaled_direct(contact.scale), target, false, to_global(contact.point))
		elif target.has_method("receive_player_hit"):
			target.receive_player_hit(tick_damage * contact.scale, StringName(player_id), false)
		changed = changed or not is_instance_valid(target) or target.get("destroyed") == true
	if effects: effects.release_root(hit)
	if changed:
		_update_geometry()

func _update_geometry() -> void:
	var length := maxf(global_position.y - TOP_EDGE, 1.0)
	var width := overdrive_width if overdrive else beam_width
	impact_cast.clear_exceptions()
	_impact_target = null
	_contacts.clear()
	_segments.clear()
	var previous := 0.0
	var scale_factor := 1.0
	var groups := {}
	for probe in 64:
		impact_cast.shape.size = Vector2(width * scale_factor * collision_width_multiplier, 0.1)
		var origin_blocked := _cast_first_obstacle(length)
		if not impact_cast.is_colliding():
			_segments.append({"start": previous, "length": maxf(length - previous, 0.01), "width": width * scale_factor})
			break
		var collider = impact_cast.get_collider(0)
		if collider is Area2D and collider.get("destroyed") == true:
			impact_cast.add_exception(collider)
			continue
		if not collider is Area2D:
			break
		var point := Vector2.ZERO if origin_blocked else to_local(impact_cast.get_collision_point(0))
		var distance := 1.0 if origin_blocked else clampf(-point.y, previous, length)
		var group := CombatTargeting.damage_group(collider)
		var blocking: bool = collider.get("armored") == true or not collider.has_method("can_receive_player_hit") or not collider.can_receive_player_hit()
		if not blocking and groups.has(group):
			impact_cast.add_exception(collider)
			continue
		if _impact_target == null:
			_impact_target = collider
			_impact_point = point
		_segments.append({"start": previous, "length": maxf(distance - previous, 0.01), "width": width * scale_factor})
		_contacts.append({"target": weakref(collider), "point": point, "scale": scale_factor})
		if blocking or groups.size() >= clampi(extra_targets, 0, MAX_EXTRA_TARGETS):
			break
		groups[group] = true
		impact_cast.add_exception(collider)
		previous = distance
		scale_factor *= PIERCING_RETAINED
	_apply_segments()

# Each rendered segment and its physical query use the same attenuated width.
func _apply_segments() -> void:
	for index in _outer_segments.size():
		var used := index < _segments.size()
		_outer_segments[index].visible = used
		_halo_segments[index].visible = used
		_collision_segments[index].set_deferred("disabled", not (used and active))
		if not used: continue
		var segment := _segments[index]
		var points := PackedVector2Array([Vector2(0, -segment.start), Vector2(0, -segment.start - segment.length)])
		_outer_segments[index].points = points
		_halo_segments[index].points = points
		_outer_segments[index].width = segment.width
		_halo_segments[index].width = segment.width * 1.35
		var segment_material := _outer_segments[index].material as ShaderMaterial
		segment_material.set_shader_parameter("flow_length", segment.length * (16.0 if overdrive else 8.0) / segment.width)
		_collision_segments[index].shape.size = Vector2(segment.width * collision_width_multiplier, segment.length)
		_collision_segments[index].position = Vector2(0, -segment.start - segment.length * 0.5)

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
	for line in _outer_segments:
		(line.material as ShaderMaterial).set_shader_parameter("overdrive", overdrive)

func _apply_player_color() -> void:
	var color := PLAYER_ONE_COLOR if player_id == "player1" else PLAYER_TWO_COLOR
	for halo in _halo_segments: halo.modulate = Color(color.r, color.g, color.b, HALO_ALPHA)
	for line in _outer_segments:
		(line.material as ShaderMaterial).set_shader_parameter("team_row", 0.0 if player_id == "player1" else 1.0)

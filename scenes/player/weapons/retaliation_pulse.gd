extends Node2D

const DATA: UpgradeDefinition = preload("res://data/upgrades/retaliation_pulse.tres")
const SHEET := preload("res://assets/sprites/player/weapons/retaliation_pulse.png")
const Feedback := preload("res://scenes/effects/combat_feedback.gd")
const Layers := preload("res://core/collision_layers.gd")
const MAX_VISUALS := 4
const ART_RADII := [48.0, 80.0, 96.0]

var age := 0.0
var rank := 0
var owner_id: StringName
var _hit: PlayerHitSnapshot
var _service: WeakRef
var visual_radius := 0.0
var _sprite: Sprite2D
var _circle := CircleShape2D.new()
var _cancelled := false

func configure(player: Player, request: Dictionary) -> bool:
	var effects := PlayerHitEffects.find_service(player)
	if effects == null: return false
	rank = request.rank
	owner_id = StringName(player.id_Player)
	var base := DATA.rank_value(rank)
	_hit = effects.create_hit(owner_id, base, base * float(request.multiplier), {}, PlayerHitSnapshot.Kind.SECONDARY)
	if _hit == null: return false
	_service = weakref(effects)
	position = request.position
	return true

func _ready() -> void:
	visible = get_tree().get_nodes_in_group(&"retaliation_pulse").size() < MAX_VISUALS
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 8
	_sprite.vframes = 3
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	add_to_group(&"retaliation_pulse")
	z_index = 6
	_advance(0.0)

func _physics_process(delta: float) -> void:
	if get_tree().paused or _cancelled: return
	_advance(delta)

# Use the next native-size front and only shrink it to follow the active damage radius.
func _advance(delta: float) -> void:
	var effects: PlayerHitEffects = _service.get_ref() if _service else null
	if not is_instance_valid(effects) or not effects.owner_alive(owner_id) or get_parent().is_queued_for_deletion():
		cancel()
		return
	age += delta
	var world := get_parent() as Node2D
	if _hit != null:
		_circle.radius = DATA.blast_radius(rank, minf(age, DATA.blast_active_duration))
		for target in CombatTargeting.area_targets(world, global_position, _circle.radius, effects.visited_groups(_hit)):
			if _cancelled or not effects.owner_alive(owner_id): return
			if effects.resolve_hit(_hit, target, false) and not _cancelled and is_instance_valid(target) and not world.is_queued_for_deletion():
				Feedback.spawn(world, target.global_position, Color("ffb34a"))
		for area in CombatTargeting.query_areas(world, _circle, Transform2D(0.0, global_position), Layers.ENEMY_SHOT):
			if _cancelled: return
			if area is Shot and not area.trowbackByShield and not area.get_meta("pooled", false) and CombatTargeting.armor_path_clear(world, global_position, area.global_position):
				ProjectilePool.despawn(area)
		if age >= DATA.blast_active_duration:
			effects.release_root(_hit)
			_hit = null
	visual_radius = DATA.blast_radius(rank, minf(age, DATA.blast_active_duration))
	var frame := clampi(ceili(visual_radius * 4.0 / ART_RADII[rank - 1]), 1, 4) - 1
	_sprite.scale = Vector2.ONE * visual_radius / (ART_RADII[rank - 1] * (frame + 1) / 4.0)
	if age >= DATA.blast_active_duration:
		frame = 4 + mini(int((age - DATA.blast_active_duration) * 4 / (DATA.blast_visual_duration - DATA.blast_active_duration)), 3)
		_sprite.scale = Vector2.ONE * DATA.range_value(rank) / ART_RADII[rank - 1]
	_sprite.frame = (rank - 1) * 8 + frame
	if age >= DATA.blast_visual_duration: cancel()

func cancel() -> void:
	if _cancelled: return
	_cancelled = true
	_release()
	hide()
	set_physics_process(false)
	call_deferred("queue_free")

func _release() -> void:
	var effects: PlayerHitEffects = _service.get_ref() if _service else null
	if is_instance_valid(effects): effects.release_root(_hit)
	_hit = null

func _exit_tree() -> void:
	_release()

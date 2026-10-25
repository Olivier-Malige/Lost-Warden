extends Node2D

const DATA: UpgradeDefinition = preload("res://data/upgrades/guard_blades.tres")
const SHEET := preload("res://assets/sprites/player/weapons/guard_blades.png")
const Feedback := preload("res://scenes/effects/combat_feedback.gd")
const Layers := preload("res://core/collision_layers.gd")
const ANGLE_STEP := 5.0
const MOTION_STEP := 4.0

var rank := 0
var interval := 0.0
var cooldown_left := 0.0
var age := 0.0
var salvo_count := 0
var _salvo_rank := 0
var _playing := false
var _stopped := false
var _previous_origin := Vector2.ZERO
var _hit: PlayerHitSnapshot
var _service: WeakRef
var _sprites: Array[Sprite2D] = []
var _warning_visible := false

func _ready() -> void:
	add_to_group(&"guard_blades")
	for index in 2:
		var sprite := Sprite2D.new()
		sprite.name = "LeftBlade" if index == 0 else "RightBlade"
		sprite.texture = SHEET
		sprite.hframes = 10
		sprite.vframes = 6
		sprite.flip_h = index == 1
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 5
		sprite.hide()
		add_child(sprite)
		_sprites.append(sprite)
	_update_warning()

func sync_rank(value: int) -> void:
	if _stopped or value == rank: return
	var fraction := cooldown_left / interval if interval > 0.0 else 0.0
	var acquiring := rank == 0 and value > 0
	var warning_left := cooldown_left
	rank = value
	interval = DATA.interval_value(rank)
	cooldown_left = DATA.sweep_warning_duration if acquiring else warning_left if salvo_count == 0 else fraction * interval
	_update_warning()

func _physics_process(delta: float) -> void:
	if _stopped or get_tree().paused: return
	var player := get_parent() as Player
	if player == null or player.state >= Player.State.DYING or player.is_queued_for_deletion():
		shutdown()
		return
	global_rotation = 0.0
	sync_rank(player.loadout.rank_for(UpgradeDefinition.Effect.GUARD_BLADES))
	var effects := PlayerHitEffects.find_service(player)
	if effects == null or not effects.owner_alive(StringName(player.id_Player)):
		if _playing: shutdown()
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if _playing: _advance(delta)
	if not _stopped and cooldown_left <= 0.0: _begin_salvo(effects)
	_update_warning()

func _begin_salvo(effects: PlayerHitEffects) -> void:
	if rank <= 0 or _stopped: return
	_release()
	var player := get_parent() as Player
	var base := DATA.rank_value(rank)
	_hit = effects.create_hit(StringName(player.id_Player), base, base * player.loadout.direct_damage_multiplier, {}, PlayerHitSnapshot.Kind.SECONDARY)
	if _hit == null: return
	_service = weakref(effects)
	_salvo_rank = rank
	age = 0.0
	_playing = true
	cooldown_left = interval
	salvo_count += 1
	_previous_origin = global_position
	var audio := $SalvoAudio as AudioStreamPlayer2D
	if audio.stream != null: audio.play()
	_update_visuals()
	_resolve_sweep(0.0, 0.0, global_position, global_position)

func _advance(delta: float) -> void:
	var before := age
	age += delta
	if _hit != null and before < DATA.sweep_duration:
		var end_age := minf(age, DATA.sweep_duration)
		var end_origin := _previous_origin.lerp(global_position, (end_age - before) / delta) if delta > 0.0 else global_position
		_resolve_sweep(before, end_age, _previous_origin, end_origin)
		if _stopped: return
		if age >= DATA.sweep_duration: _release()
	_previous_origin = global_position
	if age >= DATA.sweep_visual_duration: _playing = false
	_update_visuals()

# Sweep the traveled angles and short translations so physics sampling cannot skip a blade.
func _resolve_sweep(from_age: float, to_age: float, from_origin: Vector2, to_origin: Vector2) -> void:
	var player := get_parent() as Player
	var world := player.get_parent() as Node2D
	var effects: PlayerHitEffects = _service.get_ref() if _service else null
	if effects == null or _hit == null: return
	var visited := effects.visited_groups(_hit)
	var candidates := {}
	var steps := maxi(1, ceili(from_origin.distance_to(to_origin) / MOTION_STEP))
	for step in steps:
		var t0 := float(step) / steps
		var t1 := float(step + 1) / steps
		var origin0 := from_origin.lerp(to_origin, t0)
		var origin1 := from_origin.lerp(to_origin, t1)
		for index in 2:
			var a0 := _angle(index, lerpf(from_age, to_age, t0))
			var a1 := _angle(index, lerpf(from_age, to_age, t1))
			var start := minf(a0, a1) - DATA.sweep_width_degrees * 0.5
			var end := maxf(a0, a1) + DATA.sweep_width_degrees * 0.5
			var slices := ceili((end - start) / ANGLE_STEP)
			for slice in slices:
				var left := deg_to_rad(lerpf(start, end, float(slice) / slices))
				var right := deg_to_rad(lerpf(start, end, float(slice + 1) / slices))
				var points := PackedVector2Array([
					Vector2.from_angle(left) * DATA.sweep_inner_radius, Vector2.from_angle(left) * DATA.range_value(_salvo_rank),
					Vector2.from_angle(right) * DATA.range_value(_salvo_rank), Vector2.from_angle(right) * DATA.sweep_inner_radius,
				])
				for point in points.duplicate(): points.append(point + origin0 - origin1)
				var shape := ConvexPolygonShape2D.new()
				var hull := Geometry2D.convex_hull(points)
				hull.resize(hull.size() - 1)
				shape.points = hull
				var query_transform := Transform2D(0.0, origin1)
				for target in CombatTargeting.query_areas(world, shape, query_transform, Layers.ENEMY | Layers.ASTEROID | Layers.ENEMY_SHOT):
					if target is Shot:
						if target.trowbackByShield or target.get_meta("pooled", false) or not target.is_in_group(&"enemy_Shot"): continue
					elif not CombatTargeting.eligible(world, target) or visited.has(CombatTargeting.group_identity(target)): continue
					var point := _surface_point(target, shape, query_transform, origin1, world)
					if not point.is_finite(): continue
					var id := target.get_instance_id()
					var distance := origin1.distance_squared_to(point)
					if not candidates.has(id) or distance < candidates[id].distance:
						candidates[id] = {"target": target, "point": point, "distance": distance}
	var ordered: Array = candidates.values()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary):
		return a.target.get_instance_id() < b.target.get_instance_id() if a.distance == b.distance else a.distance < b.distance
	)
	for candidate in ordered:
		if _stopped or _hit == null or not effects.owner_alive(StringName(player.id_Player)) or world.is_queued_for_deletion(): return
		if not is_instance_valid(candidate.target): continue
		var target: Area2D = candidate.target
		if target.is_queued_for_deletion(): continue
		if target is Shot:
			if not target.trowbackByShield and not target.get_meta("pooled", false): ProjectilePool.despawn(target)
		elif effects.resolve_hit(_hit, target, false, candidate.point) and not _stopped and is_instance_valid(target) and not world.is_queued_for_deletion():
			Feedback.spawn(world, candidate.point, Color("ff5a4d") if player.id_Player == "player1" else Color("7ad9ff"))

# Use contact points from the actual transformed shape, including offset boss/asteroid surfaces.
func _surface_point(target: Area2D, query: Shape2D, query_transform: Transform2D, origin: Vector2, world: Node2D) -> Vector2:
	var nearest := Vector2.INF
	var distance := INF
	for shape_owner in target.get_shape_owners():
		if target.is_shape_owner_disabled(shape_owner): continue
		for index in target.shape_owner_get_shape_count(shape_owner):
			var shape := target.shape_owner_get_shape(shape_owner, index)
			var contacts := shape.collide_and_get_contacts(target.global_transform * target.shape_owner_get_transform(shape_owner), query, query_transform)
			for contact in range(0, contacts.size(), 2):
				var point := contacts[contact]
				var squared := origin.distance_squared_to(point)
				if squared < distance and CombatTargeting.armor_path_clear(world, origin, point):
					nearest = point
					distance = squared
	return nearest

func _angle(index: int, elapsed: float) -> float:
	return lerpf(DATA.sweep_start_angles[index], DATA.sweep_end_angles[index], clampf(elapsed / DATA.sweep_motion_duration, 0.0, 1.0))

func _update_visuals() -> void:
	var team := 1 if get_parent().set_Player_2 else 0
	var frame := mini(int(age * 10 / DATA.sweep_visual_duration), 9)
	for index in _sprites.size():
		_sprites[index].visible = _playing and not _stopped
		_sprites[index].rotation = deg_to_rad(_angle(index, age) + 90.0)
		_sprites[index].flip_h = index == 1 and age < DATA.sweep_motion_duration
		_sprites[index].frame = (maxi(1, _salvo_rank) - 1) * 20 + team * 10 + frame

func _update_warning() -> void:
	_warning_visible = not _stopped and rank > 0 and cooldown_left > 0.0 and cooldown_left <= DATA.sweep_warning_duration
	queue_redraw()

func _draw() -> void:
	if not _warning_visible: return
	var progress := 1.0 - cooldown_left / DATA.sweep_warning_duration
	var tint := Color("ff5a4d") if not get_parent().set_Player_2 else Color("7ad9ff")
	draw_rect(Rect2(-11, -24, 22, 4), Color("101522"))
	draw_rect(Rect2(-10, -23, 20, 2), Color("621521") if not get_parent().set_Player_2 else Color("113a75"))
	draw_rect(Rect2(-10, -23, roundf(20 * progress), 2), tint)

func snapshot() -> Dictionary:
	return {"rank": rank, "cooldown_left": cooldown_left, "interval": interval, "age": age, "active": _hit != null, "salvos": salvo_count, "warning": _warning_visible}

func _release() -> void:
	var effects: PlayerHitEffects = _service.get_ref() if _service else null
	if is_instance_valid(effects): effects.release_root(_hit)
	_hit = null

func shutdown() -> void:
	if _stopped: return
	_stopped = true
	_release()
	$SalvoAudio.stop()
	hide()
	set_physics_process(false)
	call_deferred("queue_free")

func _exit_tree() -> void:
	_release()

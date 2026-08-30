class_name PlayerWeapons
extends RefCounted

const BEAM_TOP: PackedScene = preload("res://scenes/player/beam/beam_top.tscn")
const BEAM_BOTTOM: PackedScene = preload("res://scenes/player/beam/beam_bottom.tscn")
const BEAM_ORIGIN_OFFSET := Vector2(0, -16)

class BeamSegment:
	extends RefCounted
	var scene: PackedScene
	var offset: Vector2
	var scale: Vector2
	var speed_x: float
	var speed_y: float

	func _init(p_scene: PackedScene, p_offset: Vector2, p_scale: Vector2, p_speed_x: float, p_speed_y: float) -> void:
		scene = p_scene
		offset = p_offset
		scale = p_scale
		speed_x = p_speed_x
		speed_y = p_speed_y

var player: Player
var _beam_cache: Dictionary[String, Array] = {}

func _init(p_player: Player) -> void:
	player = p_player
	_beam_segments(Player.WEAPON_BEAM_MINI.projectile)
	_beam_segments(Player.WEAPON_BEAM_NORMAL.projectile)
	_beam_segments(Player.WEAPON_BEAM_FULL.projectile)

func fire_primary() -> void:
	_spawn_gun(Player.WEAPON_PRIMARY.projectile, player.primary_origin, player.loadout.damage_bonus)
	player.play_shot_recoil()
	player.shooting_audio.playing = true
	player.canShooting = false
	player.shooting_delay_timer.start()
	if player.loadout.side_shot:
		_spawn_gun(Player.WEAPON_SIDE.projectile, player.left_origin, player.loadout.side_damage_bonus, 120)
		_spawn_gun(Player.WEAPON_SIDE.projectile, player.right_origin, player.loadout.side_damage_bonus, -120)

func fire_beam(power: int) -> void:
	var weapon: WeaponDefinition
	var sound: AudioStreamPlayer2D
	match power:
		Player.beam_State.SMALL:
			weapon = Player.WEAPON_BEAM_MINI
			sound = player.mini_beam_audio
		Player.beam_State.NORMAL:
			weapon = Player.WEAPON_BEAM_NORMAL
			sound = player.normal_beam_audio
		Player.beam_State.FULL:
			weapon = Player.WEAPON_BEAM_FULL
			sound = player.full_beam_audio
		_:
			return
	sound.playing = true
	for origin in [player.left_origin, player.right_origin]:
		_spawn_beam(weapon.projectile, origin, power == Player.beam_State.FULL)
	var kick := float(power) * 1.5
	player.play_shot_recoil(kick, 0.1)
	Events.screen_shake_requested.emit(kick, 0.1)
	player.malusSpeed = 0

func _spawn_gun(packed: PackedScene, origin: Marker2D, extra_damage: float, speed_x: float = 0) -> void:
	var shot := ProjectilePool.spawn(packed, origin.global_position, player.get_parent())
	shot.player_Id = player.id_Player
	shot.set_damage_bonus(extra_damage)
	shot.speedX = speed_x

func _spawn_beam(packed: PackedScene, marker: Marker2D, fill_screen := false) -> void:
	var origin := marker.global_position + BEAM_ORIGIN_OFFSET
	var world := player.get_parent()
	var segments: Array[BeamSegment] = _beam_segments(packed)
	if fill_screen:
		_spawn_full_screen_beam(segments, origin, world)
		return
	for spec in segments:
		_spawn_beam_segment(spec, spec.offset, origin, world)

func _spawn_full_screen_beam(segments: Array[BeamSegment], origin: Vector2, world: Node) -> void:
	if segments.size() < 2:
		return
	var top := segments[0]
	var middle := segments[1]
	var step := absf(top.offset.y - middle.offset.y)
	var y := 0.0
	for spec in segments:
		y = maxf(y, spec.offset.y)
	step = maxf(step, 16.0)
	while origin.y + y > step:
		_spawn_beam_segment(middle, Vector2(middle.offset.x, y), origin, world, player.loadout.full_beam_duration(), player.loadout.full_beam_width_scale())
		y -= step
	_spawn_beam_segment(top, Vector2(top.offset.x, y), origin, world, player.loadout.full_beam_duration(), player.loadout.full_beam_width_scale())

func _spawn_beam_segment(spec: BeamSegment, offset: Vector2, origin: Vector2, world: Node, follow_duration := 0.0, width_scale := 1.0) -> void:
	var shot := ProjectilePool.spawn(spec.scene, origin + offset, world)
	var scale := spec.scale
	shot.scale = Vector2(scale.x * width_scale, scale.y)
	shot.speedX = spec.speed_x * scale.x
	shot.speedY = spec.speed_y * scale.y
	shot.player_Id = player.id_Player
	shot.set_damage_bonus(player.loadout.damage_bonus + player.loadout.beam_damage_bonus)
	if follow_duration > 0.0:
		shot.follow_player(player, origin - player.global_position + offset, follow_duration)

func _beam_segments(packed: PackedScene) -> Array[BeamSegment]:
	var key := packed.resource_path
	if _beam_cache.has(key):
		return _beam_cache[key] as Array[BeamSegment]
	var template: Node2D = packed.instantiate()
	var parent_scale: Vector2 = template.scale
	var segments: Array[BeamSegment] = []
	for ch in template.get_children():
		if ch.scene_file_path.is_empty():
			continue
		var segment_scene := BEAM_TOP if ch.scene_file_path == BEAM_TOP.resource_path else BEAM_BOTTOM
		segments.append(BeamSegment.new(segment_scene, ch.position * parent_scale, ch.scale * parent_scale, ch.speedX, ch.speedY))
	template.free()
	_beam_cache[key] = segments
	return segments

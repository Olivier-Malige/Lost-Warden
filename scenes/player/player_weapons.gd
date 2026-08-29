class_name PlayerWeapons
extends RefCounted

const FULL_BEAM_DURATION := 0.4
const FULL_BEAM_WIDTH_SCALE := 1.25

var player: Player
var _beam_cache := {}

func _init(p_player: Player) -> void:
	player = p_player

func fire_primary() -> void:
	_spawn_gun(Player.WEAPON_PRIMARY.projectile, "shootFrom", player.loadout.damage_bonus)
	player.play_shot_recoil()
	player.get_node("sound_Shooting").playing = true
	player.canShooting = false
	player.get_node("ShootingDelay").start()
	if player.loadout.side_shot:
		_spawn_gun(Player.WEAPON_SIDE.projectile, "shootFromLeft", player.loadout.side_damage_bonus, 120)
		_spawn_gun(Player.WEAPON_SIDE.projectile, "shootFromRight", player.loadout.side_damage_bonus, -120)

func fire_beam(power: int) -> void:
	var weapon: WeaponDefinition
	var sound: String
	match power:
		Player.beam_State.SMALL:
			weapon = Player.WEAPON_BEAM_MINI
			sound = "sound_Beam_mini"
		Player.beam_State.NORMAL:
			weapon = Player.WEAPON_BEAM_NORMAL
			sound = "sound_Beam_normal"
		Player.beam_State.FULL:
			weapon = Player.WEAPON_BEAM_FULL
			sound = "sound_Beam_full"
		_:
			return
	player.get_node(sound).playing = true
	for from in ["shootFromLeft", "shootFromRight"]:
		_spawn_beam(weapon.projectile, from, power == Player.beam_State.FULL)
	var kick := float(power) * 1.5
	player.play_shot_recoil(kick, 0.1)
	Events.screen_shake_requested.emit(kick, 0.1)
	player.malusSpeed = 0

func _spawn_gun(packed: PackedScene, from: String, extra_damage: float, speed_x: float = 0) -> void:
	var shot = ProjectilePool.spawn(packed, player.get_node(from).global_position, player.get_parent())
	shot.player_Id = player.id_Player
	shot.damage += extra_damage
	shot.setPowerAnim()
	shot.speedX = speed_x

func _spawn_beam(packed: PackedScene, from: String, fill_screen := false) -> void:
	var origin: Vector2 = player.get_node(from).global_position
	var world := player.get_parent()
	var segments := _beam_segments(packed)
	if fill_screen:
		_spawn_full_screen_beam(segments, origin, world)
		return
	for spec in segments:
		_spawn_beam_segment(spec, spec[1], origin, world)

func _spawn_full_screen_beam(segments: Array, origin: Vector2, world: Node) -> void:
	if segments.size() < 2:
		return
	var top: Array = segments[0]
	var middle: Array = segments[1]
	var step := absf(float(top[1].y - middle[1].y))
	var y := 0.0
	for spec in segments:
		y = maxf(y, float(spec[1].y))
	step = maxf(step, 16.0)
	while origin.y + y > step:
		_spawn_beam_segment(middle, Vector2(middle[1].x, y), origin, world, FULL_BEAM_DURATION, FULL_BEAM_WIDTH_SCALE)
		y -= step
	_spawn_beam_segment(top, Vector2(top[1].x, y), origin, world, FULL_BEAM_DURATION, FULL_BEAM_WIDTH_SCALE)

func _spawn_beam_segment(spec: Array, offset: Vector2, origin: Vector2, world: Node, follow_duration := 0.0, width_scale := 1.0) -> void:
	var shot = ProjectilePool.spawn(spec[0], origin + offset, world)
	var scale: Vector2 = spec[2]
	shot.scale = Vector2(scale.x * width_scale, scale.y)
	shot.speedX = spec[3] * scale.x
	shot.speedY = spec[4] * scale.y
	shot.player_Id = player.id_Player
	shot.damage += player.loadout.damage_bonus
	shot.setPowerAnim()
	if follow_duration > 0.0:
		shot.follow_player(player, origin - player.global_position + offset, follow_duration)

func _beam_segments(packed: PackedScene) -> Array:
	var key := packed.resource_path
	if _beam_cache.has(key):
		return _beam_cache[key]
	var template: Node2D = packed.instantiate()
	var parent_scale: Vector2 = template.scale
	var segs: Array = []
	for ch in template.get_children():
		if ch.scene_file_path.is_empty():
			continue
		segs.append([load(ch.scene_file_path), ch.position * parent_scale, ch.scale * parent_scale, ch.speedX, ch.speedY])
	template.free()
	_beam_cache[key] = segs
	return segs

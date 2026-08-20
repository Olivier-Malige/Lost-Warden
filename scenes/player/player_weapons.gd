class_name PlayerWeapons
extends RefCounted

var player: Player
var _beam_cache := {}

func _init(p_player: Player) -> void:
	player = p_player

func fire_primary() -> void:
	_spawn_gun(Player.WEAPON_PRIMARY.projectile, "shootFrom", player.loadout.damage_bonus)
	player.get_node("sound_Shooting").playing = true
	player.canShooting = false
	player.get_node("ShootingDelay").start()
	if player.loadout.side_shot:
		_spawn_gun(Player.WEAPON_SIDE.projectile, "shootFromLeft", player.loadout.side_damage_bonus, 100)
		_spawn_gun(Player.WEAPON_SIDE.projectile, "shootFromRight", player.loadout.side_damage_bonus, -100)

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
		_spawn_beam(weapon.projectile, from)
	player.malusSpeed = 0

func _spawn_gun(packed: PackedScene, from: String, extra_damage: float, speed_x: float = 0) -> void:
	var shot = ProjectilePool.spawn(packed, player.get_node(from).global_position, player.get_parent())
	shot.player_Id = player.id_Player
	shot.damage += extra_damage
	shot.setPowerAnim()
	shot.speedX = speed_x

func _spawn_beam(packed: PackedScene, from: String) -> void:
	var origin: Vector2 = player.get_node(from).global_position
	var world := player.get_parent()
	for spec in _beam_segments(packed):
		var shot = ProjectilePool.spawn(spec[0], origin + spec[1], world)
		var scale: Vector2 = spec[2]
		shot.scale = scale
		shot.speedX = spec[3] * scale.x
		shot.speedY = spec[4] * scale.y
		shot.player_Id = player.id_Player
		shot.damage += player.loadout.damage_bonus
		shot.setPowerAnim()

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

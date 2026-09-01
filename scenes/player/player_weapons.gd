class_name PlayerWeapons
extends RefCounted

var player: Player

func _init(p_player: Player) -> void:
	player = p_player

func fire_primary() -> void:
	_spawn_gun(Player.WEAPON_PRIMARY.projectile, player.primary_origin, player.loadout.damage_bonus)
	player.play_shot_recoil()
	player.shooting_audio.playing = true
	player.canShooting = false
	player.shooting_delay_timer.start()
	if player.loadout.side_shot:
		_spawn_gun(Player.WEAPON_SIDE.projectile, player.left_origin, player.loadout.side_damage_bonus, 120)
		_spawn_gun(Player.WEAPON_SIDE.projectile, player.right_origin, player.loadout.side_damage_bonus, -120)
func _spawn_gun(packed: PackedScene, origin: Marker2D, extra_damage: float, speed_x: float = 0) -> void:
	var shot := ProjectilePool.spawn(packed, origin.global_position, player.get_parent())
	shot.player_Id = player.id_Player
	shot.set_damage_bonus(extra_damage)
	shot.speedX = speed_x

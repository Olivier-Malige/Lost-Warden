class_name PlayerWeapons
extends RefCounted

const SIDE_SPREAD_SPEED := 51.0
const EXTRA_SIDE_MIN_RANK := 4
const EXTRA_SIDE_SPREAD_SPEED := 110.5
const EXTRA_SIDE_DAMAGE_MULTIPLIER := 0.6

var player: Player

func _init(p_player: Player) -> void:
	player = p_player

func fire_primary() -> void:
	_spawn_gun(Player.WEAPON_PRIMARY.projectile, player.primary_origin, Player.WEAPON_PRIMARY.damage)
	player.play_shot_recoil()
	player.shooting_audio.playing = true
	player.canShooting = false
	player.shooting_delay_timer.start()
	if player.loadout.side_shot:
		_fire_side_shots()

func _fire_side_shots() -> void:
	var projectile := Player.WEAPON_SIDE.projectile
	var authored_damage := player.loadout.side_base_damage
	_spawn_gun(projectile, player.left_origin, authored_damage, SIDE_SPREAD_SPEED)
	_spawn_gun(projectile, player.right_origin, authored_damage, -SIDE_SPREAD_SPEED)
	if player.loadout.rank_for(UpgradeDefinition.Effect.SIDE_SHOT) < EXTRA_SIDE_MIN_RANK:
		return
	_spawn_gun(
		projectile,
		player.left_origin,
		authored_damage,
		-EXTRA_SIDE_SPREAD_SPEED,
		EXTRA_SIDE_DAMAGE_MULTIPLIER
	)
	_spawn_gun(
		projectile,
		player.right_origin,
		authored_damage,
		EXTRA_SIDE_SPREAD_SPEED,
		EXTRA_SIDE_DAMAGE_MULTIPLIER
	)

func _spawn_gun(
	packed: PackedScene,
	origin: Marker2D,
	authored_damage: float,
	speed_x: float = 0.0,
	damage_multiplier: float = 1.0
) -> void:
	var shot := ProjectilePool.spawn(packed, origin.global_position, player.get_parent())
	shot.player_Id = player.id_Player
	var tier := mini(player.loadout.rank_for(UpgradeDefinition.Effect.DAMAGE), 4)
	if packed == Player.WEAPON_SIDE.projectile:
		tier = [0, 1, 2, 4][clampi(player.loadout.rank_for(UpgradeDefinition.Effect.SIDE_SHOT) - 1, 0, 3)]
	shot.set_foundation_damage(authored_damage, player.loadout.direct_damage_multiplier * damage_multiplier, tier)
	shot.speedX = speed_x
	shot.scale = Vector2.ONE
	shot.rotation = Vector2.UP.angle_to(Vector2(shot.speedX, shot.speedY))

class_name PlayerWeapons
extends RefCounted

const SIDE_SPREAD_SPEED := 120.0
const EXTRA_SIDE_MIN_RANK := 6
const EXTRA_SIDE_SPREAD_SPEED := 260.0
const EXTRA_SIDE_DAMAGE_MULTIPLIER := 0.6
const EXTRA_SIDE_VISUAL_SCALE := 0.75

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
		_fire_side_shots()

func _fire_side_shots() -> void:
	var projectile := Player.WEAPON_SIDE.projectile
	var damage_bonus := player.loadout.side_damage_bonus
	_spawn_gun(projectile, player.left_origin, damage_bonus, SIDE_SPREAD_SPEED)
	_spawn_gun(projectile, player.right_origin, damage_bonus, -SIDE_SPREAD_SPEED)
	if player.loadout.rank_for(UpgradeDefinition.Effect.SIDE_SHOT) < EXTRA_SIDE_MIN_RANK:
		return
	_spawn_gun(
		projectile,
		player.left_origin,
		damage_bonus,
		-EXTRA_SIDE_SPREAD_SPEED,
		EXTRA_SIDE_DAMAGE_MULTIPLIER,
		EXTRA_SIDE_VISUAL_SCALE
	)
	_spawn_gun(
		projectile,
		player.right_origin,
		damage_bonus,
		EXTRA_SIDE_SPREAD_SPEED,
		EXTRA_SIDE_DAMAGE_MULTIPLIER,
		EXTRA_SIDE_VISUAL_SCALE
	)

func _spawn_gun(
	packed: PackedScene,
	origin: Marker2D,
	extra_damage: float,
	speed_x: float = 0.0,
	damage_multiplier: float = 1.0,
	visual_scale: float = 1.0
) -> void:
	var shot := ProjectilePool.spawn(packed, origin.global_position, player.get_parent())
	shot.player_Id = player.id_Player
	shot.set_damage_bonus(extra_damage)
	shot.damage *= damage_multiplier
	shot.speedX = speed_x
	shot.scale = Vector2.ONE * visual_scale
	shot.rotation = Vector2.UP.angle_to(Vector2(shot.speedX, shot.speedY))

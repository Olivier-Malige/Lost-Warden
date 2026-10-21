class_name PlayerWeapons
extends RefCounted

const SIDE_SPREAD_SPEED := 51.0
const EXTRA_SIDE_MIN_RANK := 4
const EXTRA_SIDE_SPREAD_SPEED := 110.5
const EXTRA_SIDE_DAMAGE_MULTIPLIER := 0.6
const MISSILES: UpgradeDefinition = preload("res://data/upgrades/micro_missiles.tres")

var player: Player
var missile_wait := 0.0

func _init(p_player: Player) -> void:
	player = p_player

func update_autonomous(delta: float) -> void:
	if not is_instance_valid(player) or player.state >= Player.State.DYING:
		return
	var rank := player.loadout.rank_for(UpgradeDefinition.Effect.MICRO_MISSILES)
	if rank == 0:
		missile_wait = 0.0
		return
	missile_wait = maxf(missile_wait - delta, 0.0)
	if missile_wait > 0.0:
		return
	var service := PlayerHitEffects.find_service(player)
	if service == null or not service.owner_alive(StringName(player.id_Player)):
		return
	var targets := CombatTargeting.targets(player.get_parent(), player.primary_origin.global_position, MISSILES.weapon.target_range, {}, true, [], MISSILES.weapon.forward_angle_degrees)
	if targets.is_empty():
		return
	missile_wait = MISSILES.interval_value(rank) * maxf(player.loadout.fire_delay / 0.20, 0.6)
	var count := MISSILES.projectile_count(rank)
	for index in count:
		var origin := player.primary_origin.global_position + Vector2((index * 2 - count + 1) * 5, 0)
		if not service.queue_missile(StringName(player.id_Player), MISSILES, rank, origin,
			targets[0], player.loadout.direct_damage_multiplier, player.loadout.acquired_ranks, player.loadout.critical_chance):
			break

func fire_primary() -> void:
	if not is_instance_valid(player) or player.state >= Player.State.DYING:
		return
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
	var effects := PlayerHitEffects.find_service(player)
	if effects:
		var hit := effects.create_hit(StringName(player.id_Player), minf(authored_damage, shot.damage_Max), shot.damage, player.loadout.acquired_ranks, PlayerHitSnapshot.Kind.GUN, player.loadout.critical_chance)
		if hit:
			shot.configure_hit(hit, effects)
	shot.speedX = speed_x
	shot.scale = Vector2.ONE
	shot.rotation = Vector2.UP.angle_to(Vector2(shot.speedX, shot.speedY))

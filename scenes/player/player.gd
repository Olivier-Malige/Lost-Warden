class_name Player
extends Area2D

const STATS: PlayerStats = preload("res://data/player/player_stats.tres")
const WEAPON_PRIMARY: WeaponDefinition = preload("res://data/weapons/primary.tres")
const WEAPON_SIDE: WeaponDefinition = preload("res://data/weapons/side.tres")
const UPGRADE_SPEED: UpgradeDefinition = preload("res://data/upgrades/foundation/speed.tres")
const UPGRADE_DAMAGE: UpgradeDefinition = preload("res://data/upgrades/foundation/damage.tres")
const UPGRADE_SIDE: UpgradeDefinition = preload("res://data/upgrades/foundation/side_shot.tres")
const UPGRADE_FIRE_RATE: UpgradeDefinition = preload("res://data/upgrades/foundation/fire_rate.tres")
const FOUNDATION: UpgradeTable = preload("res://data/upgrades/foundation_catalog.tres")
const PROGRESSION_CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")
const Layers := preload("res://core/collision_layers.gd")
const PLAYER_ONE_TEXTURE: Texture2D = preload("res://assets/sprites/player/nomad-red.png")
const PLAYER_TWO_TEXTURE: Texture2D = preload("res://assets/sprites/player/nomad-blue.png")
const IDLE_ANIMATION := &"idle"
const LEFT_ANIMATION := &"left"
const RIGHT_ANIMATION := &"right"
const EXPLODE_ANIMATION := &"explode"

@onready var effects: PlayerEffects = $Runtime/Effects
@onready var ship_sprite: Sprite2D = $Visuals/sprite
@onready var explosion_sprite: Sprite2D = $Visuals/ExplosionSprite
@onready var animation_player: AnimationPlayer = $Runtime/anim
@onready var touched_reset_timer: Timer = $Runtime/touchedReset
@onready var shooting_delay_timer: Timer = $Runtime/ShootingDelay
@onready var shield: Variant = $shield
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var primary_origin: Marker2D = $Weapons/shootFrom
@onready var left_origin: Marker2D = $Weapons/shootFromLeft
@onready var right_origin: Marker2D = $Weapons/shootFromRight
@onready var continuous_beam: ContinuousBeam = $Weapons/ContinuousBeam
@onready var hit_audio: AudioStreamPlayer2D = $Audio/sound_Hit
@onready var explosion_audio: AudioStreamPlayer2D = $Audio/sound_Explode
@onready var shooting_audio: AudioStreamPlayer2D = $Audio/sound_Shooting
@onready var normal_beam_audio: AudioStreamPlayer2D = $Audio/sound_Beam_normal
@onready var full_beam_audio: AudioStreamPlayer2D = $Audio/sound_Beam_full

enum State { ACTIVE, HIT, DYING, DEAD }

var set_Player_2 := false # set before add_child for P2 colors and stats
var loadout: PlayerLoadout
var weapons: PlayerWeapons
var vitals: PlayerVitals
var defenses: PlayerDefenses
var energy: int
var touched := false
var canShooting := true
var malusSpeed := 0.0
var controller := ""
var id_Player := ""
var shooting := false
var beam_charge := 0.0
var beam_active := false
var state := State.ACTIVE
var _recoil_tween: Tween
var _ship_rest_position := Vector2.ZERO
var _motion := Vector2.ZERO
var _beam_overdrive_left := 0.0
var _movement_animation := StringName()

func _ready() -> void:
	energy = mini(STATS.starting_energy, STATS.energy_max)
	beam_charge = clampf(STATS.beam_charge_start, 0.0, STATS.beam_charge_max)
	_setup_components()
	_setup_player()
	defenses.setup(self)

func _setup_components() -> void:
	loadout = PlayerLoadout.new(STATS)
	loadout.initialize_foundation(PROGRESSION_CONFIG, FOUNDATION.upgrades)
	weapons = PlayerWeapons.new(self)
	vitals = PlayerVitals.new(self)
	defenses = PlayerDefenses.new()
	defenses.name = "Defenses"
	$Runtime.add_child(defenses)

func _setup_player() -> void:
	id_Player = "player2" if set_Player_2 else "player1"
	ship_sprite.texture = PLAYER_TWO_TEXTURE if set_Player_2 else PLAYER_ONE_TEXTURE
	_movement_animation = IDLE_ANIMATION
	animation_player.play(_movement_animation)
	var charge_texture := load("res://assets/sprites/player/" + id_Player + "_particle.png") as Texture2D
	effects.setup(charge_texture, set_Player_2)
	_ship_rest_position = ship_sprite.position
	update_controller()
	update_energy()
	shooting_delay_timer.set_wait_time(loadout.fire_delay)
	add_to_group("player")
	_configure_collision()
	Events.plasma_collected.connect(add_beam_charge)
	_emit_upgrade_state()
	update_beam_charge()

func _configure_collision() -> void:
	collision_layer = Layers.PLAYER
	collision_mask = Layers.ENEMY | Layers.ENEMY_SHOT | Layers.PICKUP | Layers.ASTEROID

func get_debug_snapshot() -> Dictionary:
	var upgrade_ranks := {}
	for effect in loadout.ranks:
		upgrade_ranks[UpgradeDefinition.Effect.keys()[effect]] = loadout.ranks[effect]
	return {
		"id": id_Player, "controller": controller, "state": State.keys()[state],
		"position": global_position, "energy": energy, "energy_max": STATS.energy_max,
		"shield": defenses.charges, "defenses": defenses.snapshot(), "touched": touched, "hit_slowdown": malusSpeed,
		"move_speed": loadout.move_speed(), "weapon_speed_multiplier": STATS.weapon_speed_multiplier,
		"fire_delay": loadout.fire_delay, "can_fire": canShooting,
		"primary_damage": WEAPON_PRIMARY.damage * loadout.direct_damage_multiplier,
		"side_shot": loadout.side_shot, "side_damage": loadout.side_base_damage * loadout.direct_damage_multiplier,
		"plasma": beam_charge, "plasma_max": loadout.beam_capacity,
		"plasma_pickup_multiplier": loadout.plasma_pickup_multiplier,
		"beam_active": beam_active, "overdrive_left": _beam_overdrive_left,
		"ranks": upgrade_ranks,
	}

func update_controller() -> void:
	if global.coop:
		controller = global.saveData.config.player2 if set_Player_2 else global.saveData.config.player1
	else:
		controller = "all"

func _process(delta: float) -> void:
	if state == State.DYING or state == State.DEAD:
		return
	energy = min(energy, STATS.energy_max)
	_update_effects(_motion, delta)

func _physics_process(delta: float) -> void:
	if state == State.DYING or state == State.DEAD:
		return
	_update_weapons(delta)
	_motion = _update_movement(delta)

func _update_movement(delta: float) -> Vector2:
	var motion := _movement_input()
	_update_movement_animation(motion.x)
	var side_width := maxf((get_viewport_rect().size.x - 640.0) * 0.5, 0.0)
	var bounds_min := STATS.bound_min + Vector2(side_width, 0.0)
	var bounds_max := STATS.bound_max + Vector2(side_width, 0.0)
	position = (position + motion * delta * _current_move_speed()).clamp(bounds_min, bounds_max)
	Events.player_motion_changed.emit(id_Player, -motion.y)
	return motion

func _current_move_speed() -> float:
	var speed_multiplier := 1.0
	if beam_active or shooting:
		speed_multiplier = STATS.weapon_speed_multiplier
	return maxf(loadout.move_speed() * speed_multiplier - malusSpeed, 0.0)

func _movement_input() -> Vector2:
	var motion := Vector2.ZERO

	if Input.is_action_pressed(controller + "_up"):
		motion.y -= 1
	if Input.is_action_pressed(controller + "_down"):
		motion.y += 1
	if Input.is_action_pressed(controller + "_left"):
		motion.x -= 1
	if Input.is_action_pressed(controller + "_right"):
		motion.x += 1
	return motion

func _update_movement_animation(horizontal_motion: float) -> void:
	var animation := IDLE_ANIMATION
	if horizontal_motion < 0.0:
		animation = LEFT_ANIMATION
	elif horizontal_motion > 0.0:
		animation = RIGHT_ANIMATION
	if _movement_animation != animation:
		_movement_animation = animation
		animation_player.play(animation)

func _update_weapons(delta: float) -> void:
	weapons.update_autonomous(delta)
	var fire_action := controller + "_fire"
	var beam_action := controller + "_beam"
	_update_beam(delta, Input.is_action_pressed(beam_action))
	shooting = Input.is_action_pressed(fire_action) and not beam_active
	if shooting and canShooting:
		weapons.fire_primary()

func _update_beam(delta: float, beam_held: bool) -> void:
	if not beam_held:
		_stop_beam()
		return
	if not beam_active:
		if beam_charge < STATS.beam_activation_min:
			return
		_start_beam()
	beam_charge = maxf(beam_charge - STATS.beam_drain_per_second * delta, 0.0)
	continuous_beam.set_damage((STATS.beam_damage + loadout.damage_bonus) * loadout.beam_damage_multiplier)
	continuous_beam.extra_targets = loadout.beam_extra_targets
	if _beam_overdrive_left > 0.0:
		_beam_overdrive_left = maxf(_beam_overdrive_left - delta, 0.0)
		if _beam_overdrive_left <= 0.0:
			continuous_beam.set_overdrive(false)
	update_beam_charge()
	if beam_charge <= 0.0:
		_stop_beam()

func _start_beam() -> void:
	var overdrive := is_equal_approx(beam_charge, loadout.beam_capacity)
	beam_active = true
	_beam_overdrive_left = STATS.beam_overdrive_duration if overdrive else 0.0
	continuous_beam.damage_interval = STATS.beam_damage_interval
	continuous_beam.beam_width = STATS.beam_width * loadout.beam_width_multiplier
	continuous_beam.overdrive_width = STATS.beam_overdrive_width * loadout.beam_width_multiplier
	continuous_beam.collision_width_multiplier = STATS.beam_collision_width_multiplier
	continuous_beam.overdrive_damage_multiplier = STATS.beam_overdrive_damage_multiplier
	continuous_beam.extra_targets = loadout.beam_extra_targets
	continuous_beam.activate(id_Player, (STATS.beam_damage + loadout.damage_bonus) * loadout.beam_damage_multiplier, overdrive)
	(full_beam_audio if overdrive else normal_beam_audio).play()
	var kick := 4.0 if overdrive else 2.0
	play_shot_recoil(kick, 0.1)
	Events.screen_shake_requested.emit(kick, 0.1)

func _stop_beam() -> void:
	if not beam_active:
		return
	beam_active = false
	_beam_overdrive_left = 0.0
	continuous_beam.deactivate()

func reset_weapon_input() -> void:
	shooting = false
	_stop_beam()

func _update_effects(motion: Vector2, delta: float) -> void:
	effects.update_reactor(motion.y, delta)

func add_beam_charge(amount: float) -> void:
	if state == State.DYING or state == State.DEAD or not is_finite(amount) or amount <= 0.0:
		return
	beam_charge = clampf(beam_charge + amount * loadout.plasma_pickup_multiplier, 0.0, loadout.beam_capacity)
	update_beam_charge()

func update_beam_charge() -> void:
	effects.update_plasma_reserve(beam_charge / loadout.beam_capacity)
	Events.beam_charge_changed.emit(id_Player, beam_charge, loadout.beam_capacity, is_equal_approx(beam_charge, loadout.beam_capacity))


func play_shot_recoil(amount := 1.0, duration := 0.07) -> void:
	if _recoil_tween:
		_recoil_tween.kill()
	ship_sprite.position = _ship_rest_position + Vector2(0, amount)
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(ship_sprite, "position", _ship_rest_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _hit_something(dmg := 1) -> void:
	defenses.take_hit(dmg)

# Continuous hazards enforce their own cadence instead of the ordinary hit grace period.
func _hit_by_beam() -> void:
	defenses.take_hit(1, true)

func _on_touchedReset_timeout() -> void:
	malusSpeed = 0
	if defenses.grace_left <= 0.0:
		touched = false
		if state == State.HIT: state = State.ACTIVE
	ship_sprite.set_modulate(Color(1, 1, 1, 1))

func setShootingDelay() -> void:
	shooting_delay_timer.set_wait_time(loadout.fire_delay)

func _on_ShootingDelay_timeout() -> void:
	canShooting = true

func update_energy() -> void:
	Events.energy_changed.emit(id_Player, energy)

func apply_upgrade(upgrade: UpgradeDefinition) -> UpgradeResult:
	if upgrade == null or state not in [State.ACTIVE, State.HIT]:
		return UpgradeResult.new(false, 0, 0, false)
	var canonical: UpgradeDefinition
	for entry in FOUNDATION.upgrades:
		if entry.id == upgrade.id: canonical = entry
	if canonical == null:
		return UpgradeResult.new(false, 0, 0, false)
	var applied := loadout.apply_foundation(canonical.id, {"energy": energy})
	var result := UpgradeResult.new(applied.applied, applied.rank, canonical.max_rank, applied.capped)
	if result.applied and canonical.category == UpgradeDefinition.Category.REWARD:
		if canonical.effect == UpgradeDefinition.Effect.ENERGY:
			energy = applied.reward.value
			update_energy()
	setShootingDelay()
	update_beam_charge()
	weapons.sync_support()
	defenses.sync_loadout()
	_publish_upgrade_result(canonical, result)
	publish_build()
	return result

func publish_build() -> void:
	Events.build_changed.emit(StringName(id_Player), loadout.foundation_snapshot())

func _publish_upgrade_result(upgrade: UpgradeDefinition, result: UpgradeResult) -> void:
	Events.upgrade_changed.emit(id_Player, upgrade.effect, result.rank, result.max_rank)
	Events.upgrade_feedback_requested.emit(id_Player, _upgrade_feedback_text(upgrade, result), result.capped)

func _upgrade_feedback_text(upgrade: UpgradeDefinition, result: UpgradeResult) -> String:
	if not result.applied and not result.capped:
		return "SLOTS / VITALS FULL"
	if upgrade.repeatable:
		return upgrade.display_name
	if result.capped:
		return "MAX +500"
	if result.rank >= result.max_rank:
		return String(upgrade.hud_label) + " MAX"
	return String(upgrade.hud_label) + " " + str(result.rank) + "/" + str(result.max_rank)

func _emit_upgrade_state() -> void:
	for upgrade in [UPGRADE_SPEED, UPGRADE_DAMAGE, UPGRADE_SIDE, UPGRADE_FIRE_RATE]:
		Events.upgrade_changed.emit(id_Player, upgrade.effect, loadout.rank_for(upgrade.effect), upgrade.max_rank)
	publish_build()

func increase_Speed() -> void:
	apply_upgrade(UPGRADE_SPEED)

func increase_SideShot() -> void:
	apply_upgrade(UPGRADE_SIDE)

func increase_Shot() -> void:
	apply_upgrade(UPGRADE_DAMAGE)

func increase_Shield() -> void:
	apply_upgrade(preload("res://data/upgrades/foundation/shield.tres"))

func debug_increase_fire_rate() -> void:
	apply_upgrade(UPGRADE_FIRE_RATE)

func debug_add_plasma() -> void:
	add_beam_charge(25.0)

func debug_max_stats() -> void:
	for upgrade in [UPGRADE_SPEED, UPGRADE_DAMAGE, UPGRADE_SIDE, UPGRADE_FIRE_RATE]:
		for rank in upgrade.max_rank:
			if not loadout.apply_foundation(upgrade.id).applied: break
	energy = STATS.energy_max
	beam_charge = loadout.beam_capacity
	defenses.sync_loadout()
	setShootingDelay()
	update_energy()
	update_beam_charge()
	_emit_upgrade_state()
	Events.upgrade_feedback_requested.emit(id_Player, "DEBUG MAX", false)

func _on_anim_animation_finished(n: StringName) -> void:
	if n == EXPLODE_ANIMATION:
		state = State.DEAD
		Events.player_died.emit()
		queue_free()

func play_death_effect() -> void:
	ship_sprite.visible = false
	explosion_sprite.visible = true
	explosion_sprite.frame = 0

func set_state(next_state: State) -> void:
	state = next_state
	if state >= State.DYING:
		defenses.shutdown()
		weapons.stop_support()
		var hit_effects := PlayerHitEffects.find_service(self)
		if hit_effects:
			hit_effects.stop_owner(StringName(id_Player))

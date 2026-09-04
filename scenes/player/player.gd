class_name Player
extends Area2D

const STATS: PlayerStats = preload("res://data/player/player_stats.tres")
const WEAPON_PRIMARY: WeaponDefinition = preload("res://data/weapons/primary.tres")
const WEAPON_SIDE: WeaponDefinition = preload("res://data/weapons/side.tres")
const UPGRADE_SPEED: UpgradeDefinition = preload("res://data/upgrades/speed.tres")
const UPGRADE_DAMAGE: UpgradeDefinition = preload("res://data/upgrades/damage.tres")
const UPGRADE_SIDE: UpgradeDefinition = preload("res://data/upgrades/side_shot.tres")
const UPGRADE_FIRE_RATE: UpgradeDefinition = preload("res://data/upgrades/fire_rate.tres")
const Layers := preload("res://core/collision_layers.gd")

@onready var effects: PlayerEffects = $Effects
@onready var ship_sprite: Sprite2D = $xWing
@onready var animation_player: AnimationPlayer = $anim
@onready var touched_reset_timer: Timer = $touchedReset
@onready var shooting_delay_timer: Timer = $ShootingDelay
@onready var shield: Variant = $shield
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var primary_origin: Marker2D = $shootFrom
@onready var left_origin: Marker2D = $shootFromLeft
@onready var right_origin: Marker2D = $shootFromRight
@onready var continuous_beam: ContinuousBeam = $ContinuousBeam
@onready var hit_audio: AudioStreamPlayer2D = $sound_Hit
@onready var explosion_audio: AudioStreamPlayer2D = $sound_Explode
@onready var shooting_audio: AudioStreamPlayer2D = $sound_Shooting
@onready var normal_beam_audio: AudioStreamPlayer2D = $sound_Beam_normal
@onready var full_beam_audio: AudioStreamPlayer2D = $sound_Beam_full

enum State { ACTIVE, HIT, DYING, DEAD }

var set_Player_2 := false # set before add_child for P2 colors and stats
var loadout: PlayerLoadout
var weapons: PlayerWeapons
var vitals: PlayerVitals
var energy: int
var touched := false
var canShooting := true
var malusSpeed := 0
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

func _ready() -> void:
	energy = mini(STATS.starting_energy, STATS.energy_max)
	beam_charge = clampf(STATS.beam_charge_start, 0.0, STATS.beam_charge_max)
	_setup_components()
	_setup_player()

func _setup_components() -> void:
	loadout = PlayerLoadout.new(STATS)
	weapons = PlayerWeapons.new(self)
	vitals = PlayerVitals.new(self)

func _setup_player() -> void:
	id_Player = "player2" if set_Player_2 else "player1"
	animation_player.play(id_Player + "_idle")
	var charge_texture := load("res://assets/sprites/player/" + id_Player + "_particle.png") as Texture2D
	effects.setup(charge_texture)
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

func update_controller() -> void:
	if global.coop:
		controller = global.saveData.config.player2 if set_Player_2 else global.saveData.config.player1
	else:
		controller = "all"

func _process(delta: float) -> void:
	if state == State.DYING or state == State.DEAD:
		return
	energy = min(energy, STATS.energy_max)
	_update_effects(_motion)

func _physics_process(delta: float) -> void:
	if state == State.DYING or state == State.DEAD:
		return
	_update_weapons(delta)
	_motion = _update_movement(delta)

func _update_movement(delta: float) -> Vector2:
	var motion := _movement_input()
	_update_movement_animation(motion.x)
	position = (position + motion * delta * _current_move_speed()).clamp(STATS.bound_min, STATS.bound_max)
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
	var animation := id_Player + "_idle"
	if horizontal_motion < 0.0:
		animation = id_Player + "_left"
	elif horizontal_motion > 0.0:
		animation = id_Player + "_right"
	if animation_player.current_animation != animation:
		animation_player.play(animation)

func _update_weapons(delta: float) -> void:
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
	continuous_beam.set_damage(STATS.beam_damage + loadout.damage_bonus)
	if _beam_overdrive_left > 0.0:
		_beam_overdrive_left = maxf(_beam_overdrive_left - delta, 0.0)
		if _beam_overdrive_left <= 0.0:
			continuous_beam.set_overdrive(false)
	update_beam_charge()
	if beam_charge <= 0.0:
		_stop_beam()

func _start_beam() -> void:
	var overdrive := is_equal_approx(beam_charge, STATS.beam_charge_max)
	beam_active = true
	_beam_overdrive_left = STATS.beam_overdrive_duration if overdrive else 0.0
	continuous_beam.damage_interval = STATS.beam_damage_interval
	continuous_beam.beam_width = STATS.beam_width
	continuous_beam.overdrive_width = STATS.beam_overdrive_width
	continuous_beam.collision_width_multiplier = STATS.beam_collision_width_multiplier
	continuous_beam.overdrive_damage_multiplier = STATS.beam_overdrive_damage_multiplier
	continuous_beam.activate(id_Player, STATS.beam_damage + loadout.damage_bonus, overdrive)
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

func _update_effects(motion: Vector2) -> void:
	effects.update_reactors(motion.y)

func add_beam_charge(amount: float) -> void:
	if state == State.DYING or state == State.DEAD:
		return
	beam_charge = clampf(beam_charge + amount, 0.0, STATS.beam_charge_max)
	update_beam_charge()

func update_beam_charge() -> void:
	effects.update_plasma_reserve(beam_charge / STATS.beam_charge_max)
	Events.beam_charge_changed.emit(id_Player, beam_charge, STATS.beam_charge_max, is_equal_approx(beam_charge, STATS.beam_charge_max))


func play_shot_recoil(amount := 2.0, duration := 0.07) -> void:
	if _recoil_tween:
		_recoil_tween.kill()
	ship_sprite.position = _ship_rest_position + Vector2(0, amount)
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(ship_sprite, "position", _ship_rest_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _hit_something(dmg := 1) -> void:
	vitals.hit(dmg)

func _on_touchedReset_timeout() -> void:
	touched = false
	malusSpeed = 0
	if state == State.HIT:
		state = State.ACTIVE
	ship_sprite.set_modulate(Color(1, 1, 1, 1))

func setShootingDelay() -> void:
	shooting_delay_timer.set_wait_time(loadout.fire_delay)

func _on_ShootingDelay_timeout() -> void:
	canShooting = true

func update_energy() -> void:
	Events.energy_changed.emit(id_Player, energy)

func apply_upgrade(upgrade: UpgradeDefinition) -> UpgradeResult:
	if upgrade == null:
		return UpgradeResult.new(false, 0, 0, false)
	var result := UpgradeResult.new(true, 0, 0, false)

	match upgrade.effect:
		UpgradeDefinition.Effect.ENERGY:
			_apply_energy_upgrade(upgrade)
		UpgradeDefinition.Effect.SHIELD:
			_apply_shield_upgrade(upgrade)
		_:
			result = _apply_ranked_upgrade(upgrade)

	if upgrade.max_rank > 0:
		_publish_upgrade_result(upgrade, result)

	return result

func _apply_energy_upgrade(upgrade: UpgradeDefinition) -> void:
	energy += int(upgrade.value)
	update_energy()

func _apply_shield_upgrade(upgrade: UpgradeDefinition) -> void:
	shield.power = int(upgrade.value)

func _apply_ranked_upgrade(upgrade: UpgradeDefinition) -> UpgradeResult:
	var result := loadout.apply(upgrade)
	if result.capped:
		global.add_score(500)
	setShootingDelay()
	return result

func _publish_upgrade_result(upgrade: UpgradeDefinition, result: UpgradeResult) -> void:
	Events.upgrade_changed.emit(id_Player, upgrade.effect, result.rank, result.max_rank)
	Events.upgrade_feedback_requested.emit(id_Player, _upgrade_feedback_text(upgrade, result), result.capped)

func _upgrade_feedback_text(upgrade: UpgradeDefinition, result: UpgradeResult) -> String:
	if result.capped:
		return "MAX +500"
	if result.rank >= result.max_rank:
		return String(upgrade.hud_label) + " MAX"
	return String(upgrade.hud_label) + " " + str(result.rank) + "/" + str(result.max_rank)

func _emit_upgrade_state() -> void:
	for upgrade in [UPGRADE_SPEED, UPGRADE_DAMAGE, UPGRADE_SIDE, UPGRADE_FIRE_RATE]:
		Events.upgrade_changed.emit(id_Player, upgrade.effect, loadout.rank_for(upgrade.effect), upgrade.max_rank)

func increase_Speed() -> void:
	apply_upgrade(UPGRADE_SPEED)

func increase_SideShot() -> void:
	apply_upgrade(UPGRADE_SIDE)

func increase_Shot() -> void:
	apply_upgrade(UPGRADE_DAMAGE)

# Setter adds to power rather than replacing it.
func increase_Shield() -> void:
	shield.power = 1

func debug_increase_fire_rate() -> void:
	apply_upgrade(UPGRADE_FIRE_RATE)

func debug_add_plasma() -> void:
	add_beam_charge(25.0)

func debug_max_stats() -> void:
	for upgrade in [UPGRADE_SPEED, UPGRADE_DAMAGE, UPGRADE_SIDE, UPGRADE_FIRE_RATE]:
		while loadout.rank_for(upgrade.effect) < upgrade.max_rank:
			loadout.apply(upgrade)
	energy = STATS.energy_max
	beam_charge = STATS.beam_charge_max
	shield.power = 6
	setShootingDelay()
	update_energy()
	update_beam_charge()
	_emit_upgrade_state()
	Events.upgrade_feedback_requested.emit(id_Player, "DEBUG MAX", false)

func _on_anim_animation_finished(n: StringName) -> void:
	if n == id_Player + "_explode":
		state = State.DEAD
		Events.player_died.emit()
		queue_free()

func _on_player_area_entered(area: Area2D) -> void:
	if state != State.ACTIVE and state != State.HIT:
		return
	if area.is_in_group("mounted_turret"):
		return
	if area.is_in_group("enemy") and area.has_method("_hit_something"):
		_hit_something()
		area._hit_something(10)

func set_state(next_state: State) -> void:
	state = next_state

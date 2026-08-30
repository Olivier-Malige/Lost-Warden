class_name Player
extends Area2D

const STATS: PlayerStats = preload("res://data/player/player_stats.tres")
const WEAPON_PRIMARY: WeaponDefinition = preload("res://data/weapons/primary.tres")
const WEAPON_SIDE: WeaponDefinition = preload("res://data/weapons/side.tres")
const WEAPON_BEAM_MINI: WeaponDefinition = preload("res://data/weapons/beam_mini.tres")
const WEAPON_BEAM_NORMAL: WeaponDefinition = preload("res://data/weapons/beam_normal.tres")
const WEAPON_BEAM_FULL: WeaponDefinition = preload("res://data/weapons/beam_full.tres")
const UPGRADE_SPEED: UpgradeDefinition = preload("res://data/upgrades/speed.tres")
const UPGRADE_DAMAGE: UpgradeDefinition = preload("res://data/upgrades/damage.tres")
const UPGRADE_SIDE: UpgradeDefinition = preload("res://data/upgrades/side_shot.tres")
const UPGRADE_FIRE_RATE: UpgradeDefinition = preload("res://data/upgrades/fire_rate.tres")
const UPGRADE_BEAM: UpgradeDefinition = preload("res://data/upgrades/beam.tres")
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
@onready var hit_audio: AudioStreamPlayer2D = $sound_Hit
@onready var explosion_audio: AudioStreamPlayer2D = $sound_Explode
@onready var shooting_audio: AudioStreamPlayer2D = $sound_Shooting
@onready var mini_beam_audio: AudioStreamPlayer2D = $sound_Beam_mini
@onready var normal_beam_audio: AudioStreamPlayer2D = $sound_Beam_normal
@onready var full_beam_audio: AudioStreamPlayer2D = $sound_Beam_full

enum beam_State {EMPTY, SMALL, NORMAL, FULL}
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
var beam_Focusing := false
var accumBeam := 0.0
var beam_Power := beam_State.EMPTY
var state := State.ACTIVE
var _recoil_tween: Tween
var _ship_rest_position := Vector2.ZERO
var _motion := Vector2.ZERO

func _ready() -> void:
	energy = mini(STATS.starting_energy, STATS.energy_max)
	_setup_components()
	_setup_player()

func _setup_components() -> void:
	loadout = PlayerLoadout.new(STATS)
	weapons = PlayerWeapons.new(self)
	vitals = PlayerVitals.new(self)

func _setup_player() -> void:
	id_Player = "player2" if set_Player_2 else "player1"
	animation_player.play(id_Player + "_idle")
	effects.setup(global.saveData.config.graphic == "low")
	_ship_rest_position = ship_sprite.position
	update_controller()
	update_energy()
	shooting_delay_timer.set_wait_time(loadout.fire_delay)
	add_to_group("player")
	_configure_collision()
	_emit_upgrade_state()

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
	_update_weapons(delta)
	_update_effects(_motion)

func _physics_process(delta: float) -> void:
	if state == State.DYING or state == State.DEAD:
		return
	_motion = _update_movement(delta)

func _update_movement(delta: float) -> Vector2:
	var motion := _movement_input()
	_update_movement_animation(motion.x)
	position = (position + motion * delta * (loadout.move_speed() - malusSpeed)).clamp(STATS.bound_min, STATS.bound_max)
	Events.player_motion_changed.emit(id_Player, -motion.y)
	return motion

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
	beam_Focusing = Input.is_action_pressed(beam_action)
	var beam_fired := _update_beam(delta, beam_action)
	shooting = Input.is_action_pressed(fire_action) and not beam_Focusing and not beam_fired
	if shooting and canShooting:
		weapons.fire_primary()

func _update_beam(delta: float, beam_action: String) -> bool:
	if beam_Focusing:
		accumBeam += delta
		_update_beam_charge()
		return false
	var beam_fired := Input.is_action_just_released(beam_action) and beam_Power != beam_State.EMPTY
	if beam_fired:
		weapons.fire_beam(beam_Power)
	accumBeam = 0.0
	if beam_Power != beam_State.EMPTY:
		_set_Power_Beam(beam_State.EMPTY)
	return beam_fired

func reset_weapon_input() -> void:
	shooting = false
	beam_Focusing = false
	accumBeam = 0.0
	_set_Power_Beam(beam_State.EMPTY)

func _update_effects(motion: Vector2) -> void:
	effects.update_reactors(motion.y)
	effects.update_charge_particles(beam_Focusing, accumBeam, beam_Power, _max_available_beam_charge())

func _update_beam_charge() -> void:
	var next := beam_State.EMPTY
	var charge_multiplier := loadout.beam_charge_multiplier()
	var beam_rank := loadout.rank_for(UpgradeDefinition.Effect.BEAM)
	var tiers := [[STATS.beam_mini * charge_multiplier, beam_State.SMALL]]
	if beam_rank >= 3:
		tiers.push_front([STATS.beam_normal * charge_multiplier, beam_State.NORMAL])
	if beam_rank >= 8:
		tiers.push_front([STATS.beam_full * charge_multiplier, beam_State.FULL])
	for tier in tiers:
		if accumBeam >= tier[0]:
			next = tier[1]
			break
	if next != beam_Power:
		_set_Power_Beam(next)

func _set_Power_Beam(power) -> void:
	beam_Power = power
	if power == beam_State.EMPTY:
		effects.hide_charge()

func _max_available_beam_charge() -> float:
	var multiplier := loadout.beam_charge_multiplier()
	var rank := loadout.rank_for(UpgradeDefinition.Effect.BEAM)
	if rank >= 8:
		return STATS.beam_full * multiplier
	if rank >= 3:
		return STATS.beam_normal * multiplier
	return STATS.beam_mini * multiplier


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
	for upgrade in [UPGRADE_SPEED, UPGRADE_DAMAGE, UPGRADE_SIDE, UPGRADE_FIRE_RATE, UPGRADE_BEAM]:
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

func debug_increase_beam() -> void:
	apply_upgrade(UPGRADE_BEAM)

func debug_max_stats() -> void:
	for upgrade in [UPGRADE_SPEED, UPGRADE_DAMAGE, UPGRADE_SIDE, UPGRADE_FIRE_RATE, UPGRADE_BEAM]:
		while loadout.rank_for(upgrade.effect) < upgrade.max_rank:
			loadout.apply(upgrade)
	energy = STATS.energy_max
	shield.power = 6
	setShootingDelay()
	update_energy()
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

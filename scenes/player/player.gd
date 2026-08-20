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
const Layers := preload("res://core/collision_layers.gd")

var set_Player_2 := false # set before add_child for P2 colors and stats
var loadout: PlayerLoadout
var weapons: PlayerWeapons
var vitals: PlayerVitals
@onready var energy = STATS.energy_max / 2
@onready var touched = false
@onready var canShooting = true
@onready var malusSpeed = 0
@onready var controller
@onready var id_Player
@onready var shooting
@onready var beam_Focusing
@onready var accumBeam = 0
enum beam_State {EMPTY, SMALL, NORMAL, FULL}
@onready var beam_Power = beam_State.EMPTY


func _ready() -> void:
	loadout = PlayerLoadout.new(STATS)
	weapons = PlayerWeapons.new(self)
	vitals = PlayerVitals.new(self)
	_setup_Player()
	update_controller()
	update_energy()
	$ShootingDelay.set_wait_time(loadout.fire_delay)
	add_to_group("player")
	collision_layer = Layers.PLAYER
	collision_mask = Layers.ENEMY | Layers.ENEMY_SHOT | Layers.PICKUP | Layers.ASTEROID

func update_controller() -> void:
	if global.coop:
		controller = global.saveData.config.player2 if set_Player_2 else global.saveData.config.player1
	else:
		controller = "all"

func _process(delta: float) -> void:
	energy = min(energy, STATS.energy_max)

	var motion := Vector2.ZERO
	var anim: String = id_Player + "_idle"
	_set_reactors(true, 0.4)
	if Input.is_action_pressed(controller + "_up"):
		motion.y -= 1
		_set_reactors(true, 0.7)
	if Input.is_action_pressed(controller + "_down"):
		motion.y += 1
		_set_reactors(false)
	if Input.is_action_pressed(controller + "_left"):
		motion.x -= 1
		anim = id_Player + "_left"
	if Input.is_action_pressed(controller + "_right"):
		motion.x += 1
		anim = id_Player + "_right"
	if $anim.current_animation != anim:
		$anim.play(anim)

	position = (position + motion * delta * (loadout.move_speed() - malusSpeed)).clamp(STATS.bound_min, STATS.bound_max)

	shooting = Input.is_action_just_pressed(controller + "_fire")
	beam_Focusing = Input.is_action_pressed(controller + "_fire")
	_update_beam_charge()

	if Input.is_action_just_released(controller + "_fire") and beam_Power != beam_State.EMPTY:
		weapons.fire_beam(beam_Power)

	accumBeam = accumBeam + delta if beam_Focusing else 0.0
	if beam_Focusing or shooting:
		_set_reactors(true, 0.1)
	if shooting and canShooting:
		weapons.fire_primary()

func _setup_Player() -> void:
	id_Player = "player2" if set_Player_2 else "player1"
	var tex = load("res://assets/sprites/player/" + id_Player + "_particle.png")
	for p in [$BeamParticlesLeft, $BeamParticlesRight, $reactorParticles, $reactorParticles2]:
		p.set_texture(tex)
	$anim.play(id_Player + "_idle")

func _update_beam_charge() -> void:
	var next := beam_State.EMPTY
	for tier in [[STATS.beam_full, beam_State.FULL], [STATS.beam_normal, beam_State.NORMAL], [STATS.beam_mini, beam_State.SMALL]]:
		if accumBeam >= tier[0]:
			next = tier[1]
			break
	if next != beam_Power:
		_set_Power_Beam(next)

func _set_Power_Beam(power) -> void:
	beam_Power = power
	match power:
		beam_State.EMPTY:
			_set_beam_particles(false)
		beam_State.SMALL:
			malusSpeed = STATS.malus_speed
			_set_beam_particles(true, 1)
		beam_State.NORMAL:
			_set_beam_particles(true, 5)
		beam_State.FULL:
			_set_beam_particles(true, 20)

func _set_reactors(emitting: bool, lifetime := 0.4) -> void:
	for p in [$reactorParticles, $reactorParticles2]:
		p.set_emitting(emitting)
		p.set_lifetime(lifetime)

func _set_beam_particles(emitting: bool, amount := -1) -> void:
	for p in [$BeamParticlesLeft, $BeamParticlesRight]:
		p.emitting = emitting
		p.visible = emitting
		if amount >= 0:
			p.amount = amount

func _hit_something(dmg := 1) -> void:
	vitals.hit(dmg)

func _on_touchedReset_timeout() -> void:
	touched = false
	if beam_Power == beam_State.EMPTY:
		malusSpeed = 0
	$xWing.set_modulate(Color(1, 1, 1, 1))


func setShootingDelay() -> void:
	$ShootingDelay.set_wait_time(loadout.fire_delay)

func _on_ShootingDelay_timeout() -> void:
	canShooting = true

func update_energy() -> void:
	Events.energy_changed.emit(id_Player, energy)

func apply_upgrade(upgrade: UpgradeDefinition) -> void:
	if upgrade == null:
		return
	match upgrade.effect:
		UpgradeDefinition.Effect.ENERGY:
			energy += int(upgrade.value)
			update_energy()
		UpgradeDefinition.Effect.SHIELD:
			$shield.power = int(upgrade.value)
		_:
			loadout.apply(upgrade)
			setShootingDelay()

func increase_Speed() -> void:
	apply_upgrade(UPGRADE_SPEED)

func increase_SideShot() -> void:
	apply_upgrade(UPGRADE_SIDE)

func increase_Shot() -> void:
	apply_upgrade(UPGRADE_DAMAGE)

# Setter adds to power rather than replacing it.
func increase_Shield() -> void:
	$shield.power = 1

func _on_anim_animation_finished(n: StringName) -> void:
	if n == id_Player + "_explode":
		Events.player_died.emit()
		queue_free()


func _on_player_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") and area.has_method("_hit_something"):
		_hit_something()
		area._hit_something(10)

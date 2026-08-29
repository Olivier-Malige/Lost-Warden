class_name PlayerEffects
extends Node

@export var config: PlayerEffectsConfig
@export_node_path("GPUParticles2D") var left_reactor_path: NodePath
@export_node_path("GPUParticles2D") var right_reactor_path: NodePath
@export_node_path("GPUParticles2D") var charge_particles_path: NodePath

var _reactors: Array[GPUParticles2D] = []
var _charge_particles: GPUParticles2D
var _reactor_amount_ratio := -1.0

func setup(low_graphics: bool) -> void:
	_reactors = [
		get_node(left_reactor_path) as GPUParticles2D,
		get_node(right_reactor_path) as GPUParticles2D,
	]
	_charge_particles = get_node(charge_particles_path) as GPUParticles2D
	for reactor in _reactors:
		reactor.emitting = true
		reactor.visible = true
		if low_graphics:
			reactor.amount = ceili(float(reactor.amount) * config.low_graphics_amount_scale)

func update_reactors(vertical_motion: float) -> void:
	var amount_ratio := config.idle_amount_ratio
	if vertical_motion < 0.0:
		amount_ratio = config.forward_amount_ratio
	elif vertical_motion > 0.0:
		amount_ratio = config.reverse_amount_ratio
	if is_equal_approx(amount_ratio, _reactor_amount_ratio):
		return
	for reactor in _reactors:
		reactor.amount_ratio = amount_ratio
	_reactor_amount_ratio = amount_ratio

func update_charge_particles(focusing: bool, charge: float, power: int, max_charge: float, low_graphics: bool) -> void:
	if not focusing or charge < config.visible_after:
		hide_charge()
		return
	var intensity := maxf(_power_intensity(power), clampf(charge / max_charge, 0.0, 1.0))
	var amount := roundi(lerpf(config.minimum_particles, config.maximum_particles, intensity))
	if low_graphics:
		amount = ceili(float(amount) * config.low_graphics_amount_scale_charge)
	_charge_particles.visible = true
	_charge_particles.emitting = true
	_charge_particles.amount = amount
	_charge_particles.speed_scale = lerpf(config.minimum_speed_scale, config.maximum_speed_scale, intensity)

func hide_charge() -> void:
	if _charge_particles:
		_charge_particles.emitting = false
		_charge_particles.visible = false

func stop() -> void:
	for reactor in _reactors:
		reactor.emitting = false
	hide_charge()

func _power_intensity(power: int) -> float:
	match power:
		Player.beam_State.SMALL:
			return 0.55
		Player.beam_State.NORMAL:
			return 0.78
		Player.beam_State.FULL:
			return 1.0
		_:
			return 0.3

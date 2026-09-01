class_name PlayerEffects
extends Node

@export var config: PlayerEffectsConfig
@export_node_path("GPUParticles2D") var left_reactor_path: NodePath
@export_node_path("GPUParticles2D") var right_reactor_path: NodePath
@export_node_path("GPUParticles2D") var charge_particles_path: NodePath

var _reactors: Array[GPUParticles2D] = []
var _charge_particles: GPUParticles2D
var _charge_material: ParticleProcessMaterial
var _reactor_amount_ratio := -1.0
var _quality_amount_scale := 1.0
var _configured := false

func setup(low_graphics: bool, charge_texture: Texture2D) -> void:
	if config == null or not config.is_valid():
		push_error("PlayerEffects requires a valid PlayerEffectsConfig.")
		return
	_reactors = [
		get_node_or_null(left_reactor_path) as GPUParticles2D,
		get_node_or_null(right_reactor_path) as GPUParticles2D,
	]
	_charge_particles = get_node_or_null(charge_particles_path) as GPUParticles2D
	if _reactors.has(null) or _charge_particles == null or not _charge_particles.process_material is ParticleProcessMaterial:
		push_error("PlayerEffects particle paths must reference GPUParticles2D nodes.")
		return
	_charge_material = _charge_particles.process_material.duplicate() as ParticleProcessMaterial
	_charge_particles.process_material = _charge_material
	_configured = true
	_quality_amount_scale = config.low_graphics_amount_scale if low_graphics else 1.0
	_charge_particles.texture = charge_texture
	_charge_particles.scale = Vector2.ONE
	for reactor in _reactors:
		reactor.emitting = true
		reactor.visible = true

func update_reactors(vertical_motion: float) -> void:
	if not _configured:
		return
	var amount_ratio := config.idle_amount_ratio
	if vertical_motion < 0.0:
		amount_ratio = config.forward_amount_ratio
	elif vertical_motion > 0.0:
		amount_ratio = config.reverse_amount_ratio
	amount_ratio *= _quality_amount_scale
	if is_equal_approx(amount_ratio, _reactor_amount_ratio):
		return
	for reactor in _reactors:
		reactor.amount_ratio = amount_ratio
	_reactor_amount_ratio = amount_ratio

func update_plasma_reserve(charge_ratio: float) -> void:
	if not _configured:
		return
	var intensity := clampf(charge_ratio, 0.0, 1.0)
	if is_zero_approx(intensity):
		hide_charge()
		return
	_charge_particles.visible = true
	_charge_particles.emitting = true
	_charge_particles.amount_ratio = lerpf(config.minimum_amount_ratio, config.maximum_amount_ratio, intensity) * _quality_amount_scale
	_charge_particles.speed_scale = lerpf(config.minimum_speed_scale, config.maximum_speed_scale, intensity)
	_charge_material.emission_sphere_radius = lerpf(config.minimum_emission_radius, config.maximum_emission_radius, intensity)
	var particle_scale := lerpf(config.minimum_particle_scale, config.maximum_particle_scale, intensity)
	_charge_material.scale_min = particle_scale
	_charge_material.scale_max = particle_scale

func hide_charge() -> void:
	if _charge_particles:
		_charge_particles.emitting = false
		_charge_particles.visible = false

func stop() -> void:
	for reactor in _reactors:
		if reactor:
			reactor.emitting = false
	hide_charge()

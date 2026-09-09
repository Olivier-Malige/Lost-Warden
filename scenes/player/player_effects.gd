class_name PlayerEffects
extends Node

@export var config: PlayerEffectsConfig
@export var player_two_core_ramp: GradientTexture1D
@export var player_two_ember_ramp: GradientTexture1D
@export_node_path("Node2D") var reactor_path: NodePath
@export_node_path("GPUParticles2D") var charge_particles_path: NodePath

var _reactor: Node2D
var _reactor_particles: Array[GPUParticles2D] = []
var _charge_particles: GPUParticles2D
var _charge_material: ParticleProcessMaterial
var _reactor_amount_ratio := 0.0
var _reactor_speed_scale := 0.0
var _reactor_length_scale := 1.0
var _reactor_brightness := 1.0
var _configured := false

func setup(charge_texture: Texture2D, use_player_two_palette: bool) -> void:
	if config == null or not config.is_valid():
		push_error("PlayerEffects requires a valid PlayerEffectsConfig.")
		return
	_reactor = get_node_or_null(reactor_path) as Node2D
	_reactor_particles.clear()
	if _reactor:
		for child in _reactor.get_children():
			if child is GPUParticles2D:
				_reactor_particles.append(child)
	_charge_particles = get_node_or_null(charge_particles_path) as GPUParticles2D
	if _reactor_particles.is_empty() or _charge_particles == null or not _charge_particles.process_material is ParticleProcessMaterial:
		push_error("PlayerEffects particle paths must reference GPUParticles2D nodes.")
		return
	if use_player_two_palette:
		_apply_player_two_reactor_palette()
	_charge_material = _charge_particles.process_material.duplicate() as ParticleProcessMaterial
	_charge_particles.process_material = _charge_material
	_configured = true
	_charge_particles.texture = charge_texture
	_charge_particles.scale = Vector2.ONE
	_reactor_amount_ratio = config.idle_amount_ratio
	_reactor_speed_scale = config.idle_speed_scale
	_reactor_length_scale = config.idle_length_scale
	_reactor_brightness = config.idle_brightness
	_reactor.scale = Vector2(1.0, _reactor_length_scale)
	_reactor.modulate.a = _reactor_brightness
	for particles in _reactor_particles:
		particles.amount_ratio = _reactor_amount_ratio
		particles.speed_scale = _reactor_speed_scale
		particles.visible = true
		particles.emitting = true

func _apply_player_two_reactor_palette() -> void:
	if player_two_core_ramp == null or player_two_ember_ramp == null:
		push_error("PlayerEffects requires both player-two reactor gradients.")
		return
	for particles in _reactor_particles:
		if not particles.process_material is ParticleProcessMaterial:
			continue
		var material := particles.process_material.duplicate() as ParticleProcessMaterial
		material.color_ramp = player_two_core_ramp if particles.name == &"CoreParticles" else player_two_ember_ramp
		particles.process_material = material

func update_reactor(vertical_motion: float, delta: float) -> void:
	if not _configured:
		return
	var forward_input := maxf(-vertical_motion, 0.0)
	var backward_input := maxf(vertical_motion, 0.0)
	var target_amount := lerpf(config.idle_amount_ratio, config.forward_amount_ratio, forward_input)
	target_amount = lerpf(target_amount, config.backward_amount_ratio, backward_input)
	var target_speed := lerpf(config.idle_speed_scale, config.forward_speed_scale, forward_input)
	target_speed = lerpf(target_speed, config.backward_speed_scale, backward_input)
	var target_length := lerpf(config.idle_length_scale, config.forward_length_scale, forward_input)
	target_length = lerpf(target_length, config.backward_length_scale, backward_input)
	var target_brightness := lerpf(config.idle_brightness, config.forward_brightness, forward_input)
	target_brightness = lerpf(target_brightness, config.backward_brightness, backward_input)
	var step := config.reactor_response_speed * delta
	_reactor_amount_ratio = move_toward(_reactor_amount_ratio, target_amount, step)
	_reactor_speed_scale = move_toward(_reactor_speed_scale, target_speed, step)
	_reactor_length_scale = move_toward(_reactor_length_scale, target_length, step)
	_reactor_brightness = move_toward(_reactor_brightness, target_brightness, step)
	_reactor.scale = Vector2(1.0, _reactor_length_scale)
	_reactor.modulate.a = _reactor_brightness
	for particles in _reactor_particles:
		particles.amount_ratio = _reactor_amount_ratio
		particles.speed_scale = _reactor_speed_scale

func update_plasma_reserve(charge_ratio: float) -> void:
	if not _configured:
		return
	var intensity := clampf(charge_ratio, 0.0, 1.0)
	if is_zero_approx(intensity):
		hide_charge()
		return
	_charge_particles.visible = true
	_charge_particles.emitting = true
	_charge_particles.amount_ratio = lerpf(config.minimum_amount_ratio, config.maximum_amount_ratio, intensity)
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
	for particles in _reactor_particles:
		particles.emitting = false
	hide_charge()

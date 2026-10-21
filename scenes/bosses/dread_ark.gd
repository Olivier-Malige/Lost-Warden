extends Enemy

signal defeated()
signal reinforcements_requested()
signal phase_transition_started()

const BOSS_SHOT := preload("res://scenes/bosses/dread_ark_shot.tscn")
const BOSS_ORB := preload("res://scenes/bosses/dread_ark_orb.tscn")
const DAMAGED_HULLS := [
	preload("res://assets/sprites/bosses/dread_ark_port_destroyed_sheet.png"),
	preload("res://assets/sprites/bosses/dread_ark_starboard_destroyed_sheet.png"),
	preload("res://assets/sprites/bosses/dread_ark_both_destroyed_sheet.png"),
]
const PART_FEEDBACK := preload("res://scenes/effects/combat_feedback.gd")
const PART_HIT_SHADER := preload("res://scenes/bosses/dread_ark_hit_flash.gdshader")
const DEATH_EFFECT := preload("res://scenes/bosses/dread_ark_death_effect.gd")
const MOVEMENT_POINTS := [Vector2(0.85, 0.2), Vector2(-0.45, -0.5), Vector2(0.25, 0.8), Vector2(-0.95, -0.8), Vector2(0.55, 0.5), Vector2(-0.15, 0.0)]
const VISUALS := {
	"phase_1": [0, 3, 0.72], "volley_charge": [4, 9, 0.6],
	"volley_fire": [10, 12, 0.18], "volley_recover": [13, 16, 0.52],
	"open_bays": [17, 22, 0.78], "phase_2": [23, 26, 0.72],
	"launch": [27, 32, 0.72], "port_charge": [33, 37, 0.6],
	"port_fire": [38, 40, 0.21], "port_recover": [41, 44, 0.52],
	"starboard_charge": [45, 49, 0.6], "starboard_fire": [50, 52, 0.21],
	"starboard_recover": [53, 56, 0.52], "core_transition": [57, 64, 0.96],
	"phase_3": [65, 68, 0.72],
	"beam_charge": [69, 76, 0.96], "beam_fire": [77, 80, 0.32],
	"beam_recover": [81, 86, 0.84],
}

enum Attack { ENTERING, IDLE, CHARGE, FIRE, RECOVER, TRANSITION, LAUNCH, BEAM_CHARGE, BEAM_FIRE, BEAM_RECOVER }

var boss_data: BossDefinition
var run_coop := false
var phase := 0
var attack := Attack.ENTERING
var combat_active := true
var _movement_leg := 0
var _movement_pause := 0.0
var _reposition_velocity := Vector2.ZERO
var _attack_left := 0.0
var can_launch_reinforcements: Callable
var _pattern: BossAttackPattern
var _burst_index := 0
var _gap_angle := 0.0
var _pattern_angle := 0.0
var _ring_side := 1.0
var _spiral_direction := 1.0
var _active_spiral_direction := 1.0
var _locked_target := Vector2.ZERO
var _gun_side := 0
var _visual := "phase_1"
var _visual_time := 0.0
var _attack_cycle := 0
var _transition_tags: Array[String] = []
var _launch_emitted := false
var _salvos_left := 0
var _cannon_flash_tweens: Array[Tween] = [null, null]

@onready var _beam = $Beam
@onready var _cannons: Array[Node] = [$PortCannon, $StarboardCannon]
@onready var _main_muzzle: Marker2D = $MainMuzzle
@onready var _pattern_flash: AnimatedSprite2D = $MainMuzzle/PatternFlash

func _ready() -> void:
	if boss_data == null or not boss_data.is_valid():
		push_error("Dread Ark requires a valid BossDefinition before entering the tree.")
		queue_free()
		return
	add_to_group("boss")
	super._ready()
	var hit_material := ShaderMaterial.new()
	hit_material.shader = PART_HIT_SHADER
	$Sprite2D.material = hit_material
	_set_cannon_flash(0.0, 0)
	_set_cannon_flash(0.0, 1)
	_attack_left = boss_data.attack_pause
	_beam.width = boss_data.beam_width
	_beam.central_width = boss_data.central_beam_width
	_beam.damage_interval = boss_data.beam_damage_interval
	for side in 2:
		_cannons[side].configure(boss_data.cannon_health * (boss_data.coop_health_multiplier if run_coop else 1.0))
		_cannons[side].hit.connect(_on_cannon_hit.bind(side))
		_cannons[side].critical_hit.connect(_on_cannon_hit.bind(side, true))
		_cannons[side].broken.connect(_on_cannon_broken.bind(side))
	Events.boss_health_changed.emit(life, max_life, phase + 1)

func _apply_definition() -> void:
	super._apply_definition()
	life = boss_data.health * (boss_data.coop_health_multiplier if run_coop else 1.0)

func _initialize_movement() -> void:
	_movement_leg = posmod(_spawn_context.movement_seed, MOVEMENT_POINTS.size())
	_ring_side = -1.0 if posmod(_spawn_context.movement_seed, 2) else 1.0
	_spiral_direction = _ring_side

func _play_spawn_animation() -> void:
	_play_visual("phase_1")

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	_update_visual(delta)
	if not combat_active:
		return
	hitByPlayerShot = false
	if attack == Attack.ENTERING:
		position.y = move_toward(position.y, 82.0, delta * 72.0)
		if is_equal_approx(position.y, 82.0):
			attack = Attack.TRANSITION
			_transition_tags.assign(["open_bays"])
			_next_transition()
		return
	_move_between_positions(delta)
	_attack_left -= delta
	if attack == Attack.LAUNCH and not _launch_emitted and _visual_time >= 0.36:
		_launch_emitted = true
		reinforcements_requested.emit()
	if _attack_left > 0.0:
		return
	match attack:
		Attack.IDLE:
			_begin_next_attack()
		Attack.CHARGE:
			_salvos_left = _pattern.burst_count
			_fire_salvo()
		Attack.FIRE:
			while _attack_left <= 0.0 and attack == Attack.FIRE:
				if _salvos_left > 0:
					var overshoot := _attack_left
					_fire_salvo()
					_attack_left += overshoot
				else:
					_begin_recovery()
		Attack.LAUNCH:
			_attack_cycle += 1
			_idle()
		Attack.RECOVER:
			if _pattern.kind == BossAttackPattern.Kind.AIMED:
				_gun_side = 1 - _gun_side
			_attack_cycle += 1
			_idle()
		Attack.TRANSITION:
			_next_transition()
		Attack.BEAM_CHARGE:
			attack = Attack.BEAM_FIRE
			_attack_left = boss_data.beam_fire_time
			_play_visual("beam_fire")
			_beam.fire()
		Attack.BEAM_FIRE:
			_beam.stop()
			attack = Attack.BEAM_RECOVER
			_attack_left = 0.84
			_play_visual("beam_recover")
		Attack.BEAM_RECOVER:
			_attack_cycle += 1
			_idle()

func attack_patterns() -> Array[BossAttackPattern]:
	return boss_data.phase_one_patterns if phase == 0 else boss_data.phase_two_patterns

func get_attack_pattern_name() -> String:
	return BossAttackPattern.Kind.keys()[_pattern.kind] if _pattern else ""

func _begin_next_attack() -> void:
	var patterns := attack_patterns()
	for attempt in patterns.size():
		_pattern = patterns[_attack_cycle % patterns.size()]
		if _pattern.kind == BossAttackPattern.Kind.AIMED and _available_guns().is_empty():
			_attack_cycle += 1
			continue
		if _pattern.kind == BossAttackPattern.Kind.DRONES:
			var cap := ceili(boss_data.reinforcement_cap * (boss_data.coop_reinforcement_multiplier if run_coop else 1.0))
			if get_tree().get_node_count_in_group("boss_add") >= cap or (can_launch_reinforcements.is_valid() and not can_launch_reinforcements.call()):
				_attack_cycle += 1
				continue
			attack = Attack.LAUNCH
			_launch_emitted = false
			_attack_left = 0.72
			_play_visual("launch")
			return
		if _pattern.kind == BossAttackPattern.Kind.BEAM:
			attack = Attack.BEAM_CHARGE
			_attack_left = boss_data.beam_charge_time
			_play_visual("beam_charge")
			_beam.warn()
			return
		var sides := _available_guns()
		if not sides.is_empty() and _gun_side not in sides:
			_gun_side = sides[0]
		_locked_target = _find_target()
		_pattern_angle = _main_muzzle.global_position.direction_to(_locked_target).angle()
		if _pattern.kind == BossAttackPattern.Kind.RINGS:
			_gap_angle = _pattern_angle + deg_to_rad(_pattern.gap_offset_degrees) * _ring_side
			_ring_side *= -1.0
		if _pattern.kind == BossAttackPattern.Kind.SPIRAL:
			_active_spiral_direction = _spiral_direction
			_spiral_direction *= -1.0
		_burst_index = 0
		attack = Attack.CHARGE
		_attack_left = _pattern.telegraph_time
		_play_visual(_pattern_visual("charge"))
		return
	_idle()

func _pattern_visual(action: String) -> String:
	if _is_circular_pattern():
		return _idle_visual()
	return _gun_tag(action)

func _is_circular_pattern() -> bool:
	return _pattern != null and _pattern.kind in [BossAttackPattern.Kind.RINGS, BossAttackPattern.Kind.SPIRAL]

func _begin_recovery() -> void:
	attack = Attack.RECOVER
	_attack_left = _pattern.recovery_time
	_play_visual(_pattern_visual("recover"))

func _move_between_positions(delta: float) -> void:
	if attack in [Attack.BEAM_CHARGE, Attack.BEAM_FIRE, Attack.BEAM_RECOVER]:
		_reposition_velocity = Vector2.ZERO
		return
	if _movement_pause > 0.0:
		_movement_pause = maxf(_movement_pause - delta, 0.0)
		return
	var point: Vector2 = MOVEMENT_POINTS[_movement_leg % MOVEMENT_POINTS.size()]
	var goal := Vector2(get_viewport_rect().size.x * 0.5 + point.x * boss_data.movement_ranges[phase], 82.0 + point.y * boss_data.vertical_movement_range)
	var offset := goal - global_position
	var distance := offset.length()
	var maximum: float = boss_data.movement_speeds[phase] * (0.55 if attack == Attack.FIRE else 1.0)
	var desired := offset.normalized() * minf(maximum, sqrt(2.0 * boss_data.movement_acceleration * distance))
	_reposition_velocity = _reposition_velocity.move_toward(desired, boss_data.movement_acceleration * delta)
	var step := _reposition_velocity * delta
	if distance <= 2.0 or (step.dot(offset) > 0.0 and step.length() >= distance):
		global_position = goal
		_reposition_velocity = Vector2.ZERO
		_movement_pause = boss_data.movement_arrival_pause
		_movement_leg += 1
	else:
		global_position += step

func _idle_visual() -> String:
	return "phase_%d" % (phase + 2)

func _next_transition() -> void:
	if _transition_tags.is_empty():
		_idle()
		return
	var tag: String = _transition_tags.pop_front()
	_play_visual(tag)
	_attack_left = 0.4 if String(tag).begins_with("phase_") else float(VISUALS[tag][2])

func _idle() -> void:
	attack = Attack.IDLE
	_attack_left = boss_data.attack_pause
	_play_visual(_idle_visual())

func _gun_tag(action: String) -> String:
	return "%s_%s" % ["volley" if phase == 0 else ("port" if _gun_side == 0 else "starboard"), action]

func _find_target() -> Vector2:
	var target := global_position + Vector2(0, 300)
	var nearest := INF
	for player in get_tree().get_nodes_in_group("player"):
		if player.get("state") != null and int(player.state) >= 2:
			continue
		var distance: float = global_position.distance_squared_to(player.global_position)
		if distance < nearest:
			nearest = distance
			target = player.global_position
	return target

func _fire_salvo() -> void:
	if _pattern.kind == BossAttackPattern.Kind.AIMED and _available_guns().is_empty():
		_salvos_left = 0
		_begin_recovery()
		return
	var already_firing := attack == Attack.FIRE
	_salvos_left -= 1
	if _pattern.kind == BossAttackPattern.Kind.AIMED:
		_locked_target = _find_target()
		_fire_volley()
	else:
		_fire_circular()
	_burst_index += 1
	attack = Attack.FIRE
	_attack_left = _pattern.burst_interval if _salvos_left > 0 else 0.21
	if not already_firing or not _is_circular_pattern():
		_play_visual(_pattern_visual("fire"))

func _fire_volley() -> void:
	var sides := _available_guns()
	if sides.is_empty():
		return
	if phase > 0:
		if _gun_side not in sides:
			_gun_side = sides[0]
		sides = [_gun_side]
	for side in sides:
		var origin := global_position + Vector2(-40 if side == 0 else 40, 32)
		var aim := origin.direction_to(_locked_target)
		if aim.y < 0.2:
			aim = Vector2.DOWN
		for index in _pattern.projectile_count:
			var angle := (index - (_pattern.projectile_count - 1) * 0.5) * _pattern.angular_step_degrees
			_spawn_missile(origin, aim.rotated(deg_to_rad(angle)) * _pattern.projectile_speed)
	$sound_Shooting.play()

func _fire_circular() -> void:
	var origin := _main_muzzle.global_position
	for index in _pattern.projectile_count:
		var angle := _pattern_angle + TAU * index / _pattern.projectile_count
		var step := deg_to_rad(_pattern.angular_step_degrees) * _burst_index
		angle += step * (_active_spiral_direction if _pattern.kind == BossAttackPattern.Kind.SPIRAL else 1.0)
		if _pattern.kind == BossAttackPattern.Kind.RINGS and absf(wrapf(angle - (_gap_angle + step), -PI, PI)) <= deg_to_rad(_pattern.gap_degrees * 0.5):
			continue
		_spawn_missile(origin, Vector2.from_angle(angle) * _pattern.projectile_speed)
	$sound_Shooting.play()

func _spawn_missile(origin: Vector2, velocity: Vector2) -> void:
	var shot = ProjectilePool.spawn(BOSS_ORB if _is_circular_pattern() else BOSS_SHOT, origin, get_parent())
	shot.speedX = velocity.x
	shot.speedY = velocity.y
	shot.set_meta("boss_owner_id", get_instance_id())

func _available_guns() -> Array[int]:
	var sides: Array[int] = []
	for side in 2:
		if not _cannons[side].destroyed:
			sides.append(side)
	return sides

func can_damage_parts() -> bool:
	return not destroyed and combat_active and attack != Attack.ENTERING

func get_cannon_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for cannon in _cannons:
		result.append({"health": cannon.life, "maximum": cannon.max_life, "destroyed": cannon.destroyed})
	return result

func _on_cannon_broken(side: int) -> void:
	var state := (1 if _cannons[0].destroyed else 0) + (2 if _cannons[1].destroyed else 0)
	$Sprite2D.texture = DAMAGED_HULLS[state - 1]
	var offsets := PackedFloat32Array()
	if not _cannons[0].destroyed:
		offsets.append(-40.0)
	offsets.append(0.0)
	if not _cannons[1].destroyed:
		offsets.append(40.0)
	_beam.offsets = offsets
	_beam.queue_redraw()
	_cannons[side].get_node("ExplosionSound").play()
	PART_FEEDBACK.spawn(self, _cannons[side].global_position, Color("ff8248"))
	Events.screen_shake_requested.emit(3.0, 0.12)
	if _available_guns().is_empty() and attack in [Attack.CHARGE, Attack.FIRE] and _pattern and _pattern.kind == BossAttackPattern.Kind.AIMED:
		_salvos_left = 0
		_begin_recovery()

func _on_cannon_hit(side: int, critical := false) -> void:
	if _cannon_flash_tweens[side] and _cannon_flash_tweens[side].is_valid():
		_cannon_flash_tweens[side].kill()
	_set_cannon_flash(1.0, side)
	var tween := create_tween()
	_cannon_flash_tweens[side] = tween
	tween.tween_interval(0.08 if critical else 0.04)
	tween.tween_method(_set_cannon_flash.bind(side), 1.0, 0.0, 0.16 if critical else 0.12)

func _set_cannon_flash(amount: float, side: int) -> void:
	$Sprite2D.set_instance_shader_parameter(&"port_hit_flash" if side == 0 else &"starboard_hit_flash", amount)

func can_receive_player_hit() -> bool:
	return super.can_receive_player_hit() and combat_active and attack != Attack.ENTERING

func _hit_something(damage: float = 0.0, _feedback := true) -> void:
	if destroyed or not combat_active or attack == Attack.ENTERING:
		return
	super._hit_something(damage, false)
	if destroyed:
		return
	var next_phase := phase
	while next_phase < boss_data.phase_thresholds.size() and life / max_life <= boss_data.phase_thresholds[next_phase]:
		next_phase += 1
	if next_phase != phase:
		phase = next_phase
		attack = Attack.TRANSITION
		_salvos_left = 0
		_transition_tags.clear()
		if _visual == "open_bays":
			_transition_tags.append("open_bays")
		_transition_tags.append("core_transition")
		_clear_missiles()
		phase_transition_started.emit()
		_beam.stop()
		_attack_cycle = 0
		_pattern = null
		_next_transition()
	Events.boss_health_changed.emit(life, max_life, phase + 1)

func _clear_missiles() -> void:
	for shot in get_tree().get_nodes_in_group("enemy_Shot"):
		if not shot.get_meta("pooled", false) and shot.get_meta("boss_owner_id", 0) == get_instance_id():
			ProjectilePool.despawn(shot)

func stop_combat() -> void:
	combat_active = false
	_pattern_flash.hide()
	_pattern_flash.stop()
	_salvos_left = 0
	_clear_missiles()
	_beam.stop()
	for zone in [$PortCannon, $StarboardCannon, $Armor]:
		zone.disable_collision()
		zone.hide()
	$CollisionShape2D.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func _destroy() -> void:
	if destroyed:
		return
	stop_combat()
	var effect := DEATH_EFFECT.new()
	effect.hull_texture = $Sprite2D.texture
	effect.hull_frame = $Sprite2D.frame
	get_parent().add_child(effect)
	effect.global_position = global_position
	$Sprite2D.hide()
	$ExplosionSprite.show()
	super._destroy()
	Events.boss_health_changed.emit(0.0, max_life, phase + 1)
	defeated.emit()

func _award_player_kill() -> void:
	super._award_player_kill()

func _plasma_amount_for_roll(_roll: int) -> float:
	return 25.0

func _on_screen_exited() -> void:
	pass

func _play_visual(tag: String) -> void:
	var circular := _is_circular_pattern() and attack in [Attack.CHARGE, Attack.FIRE, Attack.RECOVER]
	if not circular or _visual != tag:
		_visual_time = 0.0
	_visual = tag
	if circular:
		var action := &"charge" if attack == Attack.CHARGE else (&"fire" if attack == Attack.FIRE else &"recover")
		if not _pattern_flash.visible or _pattern_flash.animation != action:
			_pattern_flash.play(action)
			_pattern_flash.set_frame_and_progress(0, 0.0)
		_pattern_flash.show()
	else:
		_pattern_flash.hide()
		_pattern_flash.stop()
	_update_visual(0.0)

func _update_visual(delta: float) -> void:
	_visual_time += delta
	var clip: Array = VISUALS[_visual]
	var duration := float(clip[2])
	if _pattern and not _is_circular_pattern() and attack == Attack.CHARGE:
		duration = _pattern.telegraph_time
	elif _pattern and not _is_circular_pattern() and attack == Attack.RECOVER:
		duration = _pattern.recovery_time
	var progress := fmod(_visual_time, duration) / duration if _visual.begins_with("phase_") or _visual == "beam_fire" else minf(_visual_time / duration, 0.9999)
	$Sprite2D.frame = int(clip[0]) + floori(progress * (int(clip[1]) - int(clip[0]) + 1))

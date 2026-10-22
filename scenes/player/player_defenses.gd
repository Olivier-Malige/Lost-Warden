class_name PlayerDefenses
extends Node

const SHIELD: UpgradeDefinition = preload("res://data/upgrades/foundation/shield.tres")
const ARMOR: UpgradeDefinition = preload("res://data/upgrades/reactive_armor.tres")
const RIPOSTE: UpgradeDefinition = preload("res://data/upgrades/retaliation_pulse.tres")
const PULSE := preload("res://scenes/player/weapons/retaliation_pulse.gd")
const Layers := preload("res://core/collision_layers.gd")

var player: Player
var charges := 0
var maximum := 0
var recharge_left := 0.0
var recharge_duration := 0.0
var grace_left := 0.0
var pulse_cooldown := 0.0
var _rank := 0
var _stopped := false
var _pulse_pending := false
var _pulse_request := {}
var _bodies: Dictionary[StringName, Dictionary] = {}
var _pulses: Array[WeakRef] = []
var _circle := CircleShape2D.new()

func setup(owner_player: Player) -> void:
	player = owner_player
	_circle.radius = SHIELD.shield_radius
	player.shield.setup()
	sync_loadout()

func alive() -> bool:
	return not _stopped and is_instance_valid(player) and player.is_inside_tree() and player.state < Player.State.DYING

func active() -> bool:
	return alive() and charges > 0

func sync_loadout() -> void:
	if not alive(): return
	var next_rank := player.loadout.rank_for(UpgradeDefinition.Effect.SHIELD)
	if next_rank == _rank: return
	var old_maximum := maximum
	var remaining_fraction := recharge_left / recharge_duration if recharge_duration > 0.0 else 0.0
	_rank = next_rank
	maximum = roundi(SHIELD.rank_value(_rank))
	recharge_duration = SHIELD.recharge_value(_rank)
	if _rank == 0:
		charges = 0
		recharge_left = 0.0
	elif recharge_left > 0.0:
		recharge_left = remaining_fraction * recharge_duration
	else:
		charges = clampi(charges + maximum - old_maximum, 0, maximum)
		if old_maximum == 0: player.shield.returned()
	_publish()

func _physics_process(delta: float) -> void:
	if not alive() or get_tree().paused: return
	sync_loadout()
	player.shield.advance(delta)
	if _pulse_pending: _spawn_pulse()
	if grace_left > 0.0:
		grace_left = maxf(0.0, grace_left - delta)
		if grace_left == 0.0:
			player.touched = false
			if player.state == Player.State.HIT: player.state = Player.State.ACTIVE
	pulse_cooldown = maxf(0.0, pulse_cooldown - delta)
	for id in _bodies.keys():
		var target: Node = _bodies[id].target.get_ref()
		_bodies[id].left -= delta
		if _bodies[id].left <= 0.0 or not is_instance_valid(target) or target.get("destroyed") == true:
			_bodies.erase(id)
	if recharge_left > 0.0:
		recharge_left = maxf(0.0, recharge_left - delta)
		if recharge_left == 0.0:
			charges = maximum
			player.shield.returned()
		_publish()
	if active():
		var world := player.get_parent() as Node2D
		var shots := CombatTargeting.query_areas(world, _circle, Transform2D(0.0, player.global_position), Layers.ENEMY_SHOT)
		shots.sort_custom(func(a: Area2D, b: Area2D): return int(a.get_meta("spawn_sequence", a.get_instance_id())) < int(b.get_meta("spawn_sequence", b.get_instance_id())))
		for shot in shots:
			if shot is Shot: intercept_in_world(shot)
	_body_contacts()
	_pulses = _pulses.filter(func(reference: WeakRef): return is_instance_valid(reference.get_ref()))

func intercept_projectile(shot: Shot) -> bool:
	if not alive() or get_tree().paused or shot.get_meta("pooled", false): return false
	if shot.trowbackByShield: return true
	if not active() or not shot.is_in_group(&"enemy_Shot") or not shot.has_method("set_reflected_owner"): return false
	var world := player.get_parent() as Node2D
	if shot not in CombatTargeting.query_areas(world, _circle, Transform2D(0.0, player.global_position), Layers.ENEMY_SHOT): return false
	shot.trowbackByShield = true
	shot.set("noDamageToGroup", "")
	shot.call("set_reflected_owner", player)
	shot.speedX = -shot.speedX
	shot.speedY = -shot.speedY
	player.shield.reflected()
	_consume_charge()
	return true

# Resolve overlapping co-op fields before a projectile can reach either hull callback.
static func intercept_in_world(shot: Shot) -> bool:
	if shot.trowbackByShield: return true
	var candidates: Array[Node2D] = []
	for pilot in shot.get_tree().get_nodes_in_group(&"player"):
		var defenses: Node = pilot.get("defenses")
		if defenses != null and defenses.active() and pilot.get_parent().is_ancestor_of(shot): candidates.append(pilot)
	candidates.sort_custom(func(a: Node2D, b: Node2D):
		var left := a.global_position.distance_squared_to(shot.global_position)
		var right := b.global_position.distance_squared_to(shot.global_position)
		return String(a.id_Player) < String(b.id_Player) if left == right else left < right
	)
	for pilot in candidates:
		if pilot.defenses.intercept_projectile(shot): return true
	return false

func take_hit(damage: int = 1, continuous := false) -> bool:
	if not alive() or get_tree().paused or damage <= 0: return false
	if active():
		_consume_charge()
		return false
	return player.vitals.hit(damage, continuous)

func _consume_charge() -> void:
	if not active(): return
	charges -= 1
	player.shield.impacted()
	if charges == 0:
		recharge_left = recharge_duration
		player.shield.ruptured()
		request_pulse()
	_publish()

func hull_damaged() -> void:
	grace_left = 1.0 + ARMOR.rank_value(player.loadout.rank_for(UpgradeDefinition.Effect.REACTIVE_ARMOR))
	request_pulse()

func request_pulse() -> void:
	if not alive() or pulse_cooldown > 0.0 or player.loadout.rank_for(UpgradeDefinition.Effect.RETALIATION_PULSE) == 0: return
	pulse_cooldown = RIPOSTE.proc_cooldown
	_pulse_request = {"position": player.global_position, "rank": player.loadout.rank_for(UpgradeDefinition.Effect.RETALIATION_PULSE), "multiplier": player.loadout.direct_damage_multiplier}
	_pulse_pending = true
	_spawn_pulse.call_deferred()

func _spawn_pulse() -> void:
	if not _pulse_pending: return
	if get_tree().paused: return
	_pulse_pending = false
	if not alive(): return
	var pulse := PULSE.new()
	if not pulse.configure(player, _pulse_request):
		pulse.free()
		return
	_pulses.append(weakref(pulse))
	_pulse_request.clear()
	player.get_parent().add_child(pulse)

func _body_contacts() -> void:
	if not alive() or player.collision_shape.disabled or player.collision_mask & (Layers.ENEMY | Layers.ASTEROID) == 0: return
	var world := player.get_parent() as Node2D
	var hull := CombatTargeting.query_areas(world, player.collision_shape.shape, player.collision_shape.global_transform, Layers.ENEMY | Layers.ASTEROID)
	var nearby: Array[Area2D] = hull.duplicate()
	if active():
		for target in CombatTargeting.query_areas(world, _circle, Transform2D(0.0, player.global_position), Layers.ENEMY | Layers.ASTEROID):
			if target not in nearby: nearby.append(target)
	nearby.sort_custom(func(a: Area2D, b: Area2D):
		var left := _body_id(a)
		var right := _body_id(b)
		return a.get_instance_id() < b.get_instance_id() if left == right else String(left) < String(right)
	)
	var seen := {}
	for target in nearby:
		if not alive(): return
		if target.is_in_group(&"mounted_turret") or target.get("destroyed") == true or not target.is_visible_in_tree(): continue
		var id := _body_id(target)
		if seen.has(id): continue
		seen[id] = true
		if active():
			if _bodies.has(id): continue
			_bodies[id] = {"left": SHIELD.contact_cooldown, "target": weakref(CombatTargeting.damage_group(target))}
			_consume_charge()
		elif target in hull:
			player.vitals.hit(1)

func _body_id(target: Area2D) -> StringName:
	var id := CombatTargeting.group_identity(target)
	return id if id != &"" else StringName(str(CombatTargeting.damage_group(target).get_instance_id()))

func intersects_beam(beam_rect: Rect2, hull_rect: Rect2) -> bool:
	if not active(): return beam_rect.intersects(hull_rect)
	var closest := player.global_position.clamp(beam_rect.position, beam_rect.end)
	return closest.distance_squared_to(player.global_position) <= SHIELD.shield_radius * SHIELD.shield_radius

func snapshot() -> Dictionary:
	return {"alive": alive(), "rank": _rank, "charges": charges, "maximum": maximum, "recharge_left": recharge_left,
		"recharge_duration": recharge_duration, "grace_left": grace_left, "pulse_cooldown": pulse_cooldown}

func _publish() -> void:
	if is_instance_valid(player.shield): player.shield.present(charges)
	if player.is_inside_tree(): Events.defense_state_changed.emit(StringName(player.id_Player), snapshot())

func shutdown() -> void:
	if _stopped: return
	_stopped = true
	charges = 0
	recharge_left = 0.0
	grace_left = 0.0
	_pulse_pending = false
	_pulse_request.clear()
	_bodies.clear()
	for reference in _pulses:
		var pulse: Node = reference.get_ref()
		if is_instance_valid(pulse): pulse.cancel()
	_pulses.clear()
	if is_instance_valid(player):
		_publish()
		if is_instance_valid(player.shield): player.shield.hide()
	set_physics_process(false)

func _exit_tree() -> void:
	shutdown()

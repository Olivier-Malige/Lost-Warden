class_name PlayerDefenses
extends Node

const SHIELD: UpgradeDefinition = preload("res://data/upgrades/foundation/shield.tres")
const ARMOR: UpgradeDefinition = preload("res://data/upgrades/reactive_armor.tres")
const RIPOSTE: UpgradeDefinition = preload("res://data/upgrades/retaliation_pulse.tres")
const PULSE := preload("res://scenes/player/weapons/retaliation_pulse.gd")
const PulseIndicator := preload("res://scenes/player/retaliation_indicator.gd")
const Layers := preload("res://core/collision_layers.gd")
const REPAIR_FEEDBACK_DURATION := 0.8

var player: Player
var charges := 0
var maximum := 0
var recharge_left := 0.0
var recharge_duration := 0.0
var grace_left := 0.0
var repair_left := 0.0
var repair_duration := 0.0
var repair_flash_left := 0.0
var pulse_cooldown := 0.0
var pulse_recharge_duration := 0.0
var pulse_protection_left := 0.0
var _rank := 0
var _stopped := false
var _pulse_pending := false
var _pulse_request := {}
var _pulses: Array[WeakRef] = []
var _circle := CircleShape2D.new()
var _pulse_indicator: PulseIndicator

func setup(owner_player: Player) -> void:
	player = owner_player
	_circle.radius = SHIELD.shield_radius
	player.shield.setup()
	_pulse_indicator = PulseIndicator.new()
	_pulse_indicator.name = "RetaliationIndicator"
	_pulse_indicator.z_index = 2
	_pulse_indicator.modulate = Color("ffb34a")
	player.add_child(_pulse_indicator)
	sync_loadout()

func alive() -> bool:
	return not _stopped and is_instance_valid(player) and player.is_inside_tree() and player.state < Player.State.DYING

func active() -> bool:
	return alive() and charges > 0

func sync_loadout() -> void:
	if not alive(): return
	var next_repair := ARMOR.interval_value(player.loadout.rank_for(UpgradeDefinition.Effect.REACTIVE_ARMOR))
	var repair_changed := next_repair != repair_duration
	if repair_changed:
		repair_left = repair_left * next_repair / repair_duration if repair_duration > 0.0 else 0.0
		repair_duration = next_repair
		if next_repair == 0.0: repair_flash_left = 0.0
	if repair_left > 0.0 and player.energy >= player.STATS.energy_max:
		repair_left = 0.0
		repair_changed = true
	if repair_changed: _publish()
	var next_duration := RIPOSTE.recharge_value(player.loadout.rank_for(UpgradeDefinition.Effect.RETALIATION_PULSE))
	if next_duration != pulse_recharge_duration:
		pulse_cooldown = pulse_cooldown * next_duration / pulse_recharge_duration if pulse_recharge_duration > 0.0 else 0.0
		pulse_recharge_duration = next_duration
	_present_pulse()
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
	_advance_repair(delta)
	player.shield.advance(delta)
	if _pulse_pending: _spawn_pulse()
	if grace_left > 0.0:
		grace_left = maxf(0.0, grace_left - delta)
		if grace_left == 0.0:
			player.touched = false
			if player.state == Player.State.HIT: player.state = Player.State.ACTIVE
	pulse_cooldown = maxf(0.0, pulse_cooldown - delta)
	pulse_protection_left = maxf(0.0, pulse_protection_left - delta)
	_present_pulse(delta)
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

func take_hit(damage: int = 1, continuous := false, body_contact := false) -> bool:
	if not alive() or get_tree().paused or damage <= 0: return false
	if active() and body_contact: _consume_charge(charges)
	if pulse_protection_left > 0.0: return false
	if active() and not continuous:
		_consume_charge()
		return false
	return player.vitals.hit(damage, continuous, body_contact)

func _consume_charge(amount := 1) -> void:
	if not active(): return
	charges = maxi(0, charges - amount)
	player.shield.impacted()
	if charges == 0:
		recharge_left = recharge_duration
		player.shield.ruptured()
	_publish()

func hull_damaged() -> void:
	grace_left = 1.0
	repair_duration = ARMOR.interval_value(player.loadout.rank_for(UpgradeDefinition.Effect.REACTIVE_ARMOR))
	repair_left = repair_duration
	repair_flash_left = 0.0
	_publish()

# A completed repair is consumed, so old injuries cannot become continuous regeneration.
func _advance_repair(delta: float) -> void:
	var changed := repair_flash_left > 0.0 or repair_left > 0.0
	repair_flash_left = maxf(0.0, repair_flash_left - delta)
	if repair_left > 0.0:
		repair_left = maxf(0.0, repair_left - delta)
		if repair_left == 0.0 and player.vitals.repair_hull(roundi(ARMOR.rank_value(player.loadout.rank_for(UpgradeDefinition.Effect.REACTIVE_ARMOR)))) and alive():
			repair_flash_left = REPAIR_FEEDBACK_DURATION
	if changed: _publish()

func absorb_hull_hit(body_contact: bool) -> bool:
	if not alive() or get_tree().paused: return false
	return pulse_protection_left > 0.0 or (body_contact and request_pulse())

func request_pulse() -> bool:
	if not alive() or get_tree().paused or active() or pulse_cooldown > 0.0 or player.loadout.rank_for(UpgradeDefinition.Effect.RETALIATION_PULSE) == 0: return false
	pulse_cooldown = pulse_recharge_duration
	pulse_protection_left = RIPOSTE.protection_duration
	_present_pulse()
	_pulse_request = {"position": player.global_position, "rank": player.loadout.rank_for(UpgradeDefinition.Effect.RETALIATION_PULSE), "multiplier": player.loadout.direct_damage_multiplier}
	_pulse_pending = true
	_spawn_pulse.call_deferred()
	return true

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

# Preserve a physics-confirmed contact even if movement has ended the overlap before polling.
func contact_body(target: Area2D) -> void:
	if not alive() or get_tree().paused or player.collision_shape.disabled: return
	if not is_instance_valid(target) or not player.get_parent().is_ancestor_of(target): return
	if player.collision_mask & target.collision_layer & (Layers.ENEMY | Layers.ASTEROID) == 0: return
	if target.is_in_group(&"mounted_turret") or target.get("destroyed") == true or target.is_queued_for_deletion() or not target.is_visible_in_tree(): return
	if CombatTargeting.damage_group(target).get("destroyed") == true: return
	if active(): _consume_charge(charges)
	player.vitals.hit(1, false, true)

func _body_contacts() -> void:
	if not alive() or player.collision_shape.disabled or player.collision_mask & (Layers.ENEMY | Layers.ASTEROID) == 0: return
	var world := player.get_parent() as Node2D
	var hull := CombatTargeting.query_areas(world, player.collision_shape.shape, player.collision_shape.global_transform, Layers.ENEMY | Layers.ASTEROID)
	var nearby: Array[Area2D] = hull.duplicate()
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
		contact_body(target)

func _body_id(target: Area2D) -> StringName:
	var id := CombatTargeting.group_identity(target)
	return id if id != &"" else StringName(str(CombatTargeting.damage_group(target).get_instance_id()))

func intersects_beam(beam_rect: Rect2, hull_rect: Rect2) -> bool:
	return beam_rect.intersects(hull_rect)

func snapshot() -> Dictionary:
	return {"alive": alive(), "rank": _rank, "charges": charges, "maximum": maximum, "recharge_left": recharge_left,
		"recharge_duration": recharge_duration, "grace_left": grace_left, "pulse_cooldown": pulse_cooldown,
		"pulse_recharge_duration": pulse_recharge_duration, "pulse_protection_left": pulse_protection_left,
		"repair_left": repair_left, "repair_duration": repair_duration, "repair_flash_left": repair_flash_left}

func _publish() -> void:
	if is_instance_valid(player.shield): player.shield.present(charges)
	if player.is_inside_tree(): Events.defense_state_changed.emit(StringName(player.id_Player), snapshot())

func _present_pulse(delta := 0.0) -> void:
	if is_instance_valid(_pulse_indicator):
		var can_trigger := alive() and player.loadout.rank_for(UpgradeDefinition.Effect.RETALIATION_PULSE) > 0 and pulse_cooldown == 0.0
		_pulse_indicator.present(can_trigger, pulse_protection_left / RIPOSTE.protection_duration if alive() else 0.0, delta)

func shutdown() -> void:
	if _stopped: return
	_stopped = true
	pulse_protection_left = 0.0
	pulse_cooldown = 0.0
	_present_pulse()
	charges = 0
	recharge_left = 0.0
	grace_left = 0.0
	repair_left = 0.0
	repair_duration = 0.0
	repair_flash_left = 0.0
	_pulse_pending = false
	_pulse_request.clear()
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

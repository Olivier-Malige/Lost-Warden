class_name PlayerHitEffects
extends Node

signal hit_accepted(hit: PlayerHitSnapshot, target_id: StringName, position: Vector2, first_impact: bool)

const _CriticalImpact := preload("res://scenes/effects/critical_impact.gd")
const _EnergyChain := preload("res://scenes/combat/energy_chain.tscn")
const _ChainDefinition: UpgradeDefinition = preload("res://data/upgrades/energy_chains.tres")

var _players: Dictionary[StringName, WeakRef] = {}
var _sequences: Dictionary[StringName, int] = {}
var _disabled_owners := {}
var _roots := {}
var _requests := {}
var _reservations := {}
var _request_sequence := 0
var _generation := 0
var _running := false
var _random: RunRandom
var _chain_requests := {}
var _chain_cooldowns: Dictionary[StringName, float] = {}

static func find_service(node: Node) -> PlayerHitEffects:
	var parent := node.get_parent()
	while parent:
		var service := parent.get_node_or_null("PlayerHitEffects") as PlayerHitEffects
		if service:
			return service
		parent = parent.get_parent()
	return null

func start(players: Array, random: RunRandom) -> void:
	cancel()
	_random = random
	_sequences.clear()
	_players.clear()
	_disabled_owners.clear()
	for player in players:
		_players[StringName(player.id_Player)] = weakref(player)
	_running = true

func owner_alive(owner_id: StringName) -> bool:
	var reference: WeakRef = _players.get(owner_id)
	var player: Node = reference.get_ref() if reference else null
	return _running and not _disabled_owners.has(owner_id) and is_instance_valid(player) and player.is_inside_tree() and int(player.state) < 2

func combat_random(owner_id: StringName) -> RandomNumberGenerator:
	return _random.combat_for(owner_id) if _random else null

func create_hit(owner_id: StringName, base: float, direct: float, modifiers: Dictionary = {}, kind: PlayerHitSnapshot.Kind = PlayerHitSnapshot.Kind.GUN, critical_chance := 0.0) -> PlayerHitSnapshot:
	if not owner_alive(owner_id) or not is_finite(base) or not is_finite(direct) or base <= 0.0 or direct <= 0.0:
		return null
	_sequences[owner_id] = _sequences.get(owner_id, 0) + 1
	var critical := false
	if kind in [PlayerHitSnapshot.Kind.GUN, PlayerHitSnapshot.Kind.MISSILE, PlayerHitSnapshot.Kind.DRONE] and critical_chance > 0.0:
		var random := combat_random(owner_id)
		critical = random != null and is_critical_roll(random.randf(), critical_chance)
	var hit := PlayerHitSnapshot.new(owner_id, _sequences[owner_id], base, direct, modifiers, kind, critical, _generation)
	_roots[hit.root_id()] = {"leases": 1, "groups": {}, "first": true}
	return hit

static func is_critical_roll(roll: float, chance: float) -> bool:
	return is_finite(roll) and is_finite(chance) and roll >= 0.0 and roll < clampf(chance, 0.0, 1.0)

# Retain root history while a queued child or a flying projectile can still use it.
func retain_root(hit: PlayerHitSnapshot) -> bool:
	if hit == null or not _running or not _roots.has(hit.root_id()):
		return false
	_roots[hit.root_id()].leases += 1
	return true

func release_root(hit: PlayerHitSnapshot) -> void:
	if hit == null or not _roots.has(hit.root_id()):
		return
	var entry: Dictionary = _roots[hit.root_id()]
	entry.leases -= 1
	if entry.leases <= 0:
		_roots.erase(hit.root_id())

func resolve_hit(hit: PlayerHitSnapshot, target: Area2D, feedback := true, impact_position := Vector2.INF) -> bool:
	if not _running or hit == null or not _roots.has(hit.root_id()) or not is_instance_valid(target) or not get_parent().is_ancestor_of(target) or not target.has_method("receive_player_hit"):
		return false
	var entry: Dictionary = _roots[hit.root_id()]
	var group := CombatTargeting.group_identity(target)
	if group == &"" or entry.groups.has(group):
		return false
	var position := impact_position if impact_position.is_finite() else target.global_position
	var local_impact := target.to_local(position)
	if not target.receive_player_hit(hit.damage(), hit.owner_id(), feedback):
		return false
	entry.groups[group] = true
	var first: bool = entry.first and hit.is_direct() and owner_alive(hit.owner_id())
	if hit.kind() != PlayerHitSnapshot.Kind.SECONDARY:
		entry.first = false
	if first:
		_queue_chain(hit, target, position, local_impact)
	hit_accepted.emit(hit.copy(), CombatTargeting.identity(target), position, first)
	if hit.is_critical() and hit.is_direct():
		_CriticalImpact.spawn(get_parent(), position, hit.owner_id())
		if is_instance_valid(target) and target.has_method("play_critical_feedback"):
			target.play_critical_feedback()
	return true

# Copy the impact and retain its root before the source projectile can be recycled.
func _queue_chain(hit: PlayerHitSnapshot, target: Area2D, at: Vector2, local_impact: Vector2) -> void:
	if hit.kind() in [PlayerHitSnapshot.Kind.MISSILE, PlayerHitSnapshot.Kind.DRONE]:
		return
	var rank := clampi(hit.modifier_rank(&"energy_chains"), 0, _ChainDefinition.max_rank)
	if rank == 0 or _chain_cooldowns.get(hit.owner_id(), 0.0) > 0.0 or not retain_root(hit):
		return
	_chain_cooldowns[hit.owner_id()] = _ChainDefinition.proc_cooldown
	_request_sequence += 1
	_chain_requests[_request_sequence] = {"hit": hit.secondary_hit(hit.pre_critical_damage() * _ChainDefinition.secondary_damage_scale),
		"position": at, "budget": int(_ChainDefinition.rank_value(rank)), "radius": _ChainDefinition.range_value(rank),
		"anchor": {"target": weakref(target), "offset": local_impact},
		"exclude": CombatTargeting.origin_exclusions(target), "generation": _generation}
	call_deferred("_resolve_chain", _request_sequence)

func _physics_process(delta: float) -> void:
	for owner_id in _chain_cooldowns.keys():
		_chain_cooldowns[owner_id] = maxf(0.0, _chain_cooldowns[owner_id] - delta)
	for id in _chain_requests.keys():
		_resolve_chain(id)

func _resolve_chain(id: int) -> void:
	if not _chain_requests.has(id) or get_tree().paused:
		return
	var request: Dictionary = _chain_requests[id]
	_chain_requests.erase(id)
	var hit: PlayerHitSnapshot = request.hit
	if request.generation != _generation or not owner_alive(hit.owner_id()) or not _roots.has(hit.root_id()) or get_parent().is_queued_for_deletion():
		release_root(hit)
		return
	var origin: Vector2 = request.position
	var exclusions: Array[RID] = []
	exclusions.assign(request.exclude)
	var links: Array[PackedVector2Array] = []
	var anchors: Array[Dictionary] = [request.anchor]
	for jump in request.budget:
		if not owner_alive(hit.owner_id()) or not _roots.has(hit.root_id()):
			break
		var candidates := CombatTargeting.targets(get_parent(), origin, request.radius, _roots[hit.root_id()].groups, true, exclusions)
		var accepted := false
		for target in candidates:
			if not CombatTargeting.eligible(get_parent(), target):
				continue
			var endpoint := target.global_position
			var origin_shapes := CombatTargeting.origin_exclusions(target)
			var anchor := {"target": weakref(target), "offset": target.to_local(endpoint)}
			if resolve_hit(hit, target, false, endpoint):
				links.append(PackedVector2Array([origin, endpoint]))
				anchors.append(anchor)
				exclusions.append_array(origin_shapes)
				origin = endpoint
				accepted = true
				break
		if not accepted:
			break
	if not links.is_empty() and is_inside_tree() and not get_parent().is_queued_for_deletion():
		var effect := _EnergyChain.instantiate()
		effect.configure(links, hit.owner_id(), anchors)
		get_parent().add_child(effect)
	release_root(hit)

# Reserve capacity and root lifetime before scheduling any CollisionObject2D creation.
func queue_projectile(hit: PlayerHitSnapshot, packed: PackedScene, position: Vector2, velocity: Vector2, lifetime: float, capacity: int, damage_scale := 1.0) -> bool:
	if hit == null or not hit.is_direct() or packed == null or not owner_alive(hit.owner_id()) or not is_finite(lifetime) or lifetime <= 0.0 or not is_finite(damage_scale) or damage_scale <= 0.0 or capacity <= 0:
		return false
	var key := StringName("%s:%s" % [hit.owner_id(), packed.resource_path])
	if int(_reservations.get(key, 0)) >= capacity or not retain_root(hit):
		return false
	_reservations[key] = int(_reservations.get(key, 0)) + 1
	_request_sequence += 1
	var request := {"id": _request_sequence, "generation": _generation, "hit": hit.secondary_hit(hit.pre_critical_damage() * damage_scale),
		"packed": packed, "position": position, "velocity": velocity, "lifetime": lifetime, "key": key}
	_requests[request.id] = request
	call_deferred("_materialize", request.id)
	return true

func queue_missile(owner_id: StringName, upgrade: UpgradeDefinition, rank: int, position: Vector2, target: Area2D, multiplier: float, modifiers: Dictionary, critical_chance: float) -> bool:
	if rank < 1 or rank > upgrade.max_rank:
		return false
	var weapon := upgrade.weapon
	if weapon == null or not owner_alive(owner_id) or not CombatTargeting.eligible(get_parent(), target):
		return false
	var key := StringName("%s:%s" % [owner_id, weapon.projectile.resource_path])
	if int(_reservations.get(key, 0)) >= weapon.active_limit:
		return false
	var allowed := modifiers.duplicate()
	allowed.erase(&"piercing")
	allowed.erase(&"ricochet")
	allowed.erase(&"energy_chains")
	var base := upgrade.rank_value(rank)
	var hit := create_hit(owner_id, base, base * multiplier, allowed, PlayerHitSnapshot.Kind.MISSILE, critical_chance)
	if hit == null:
		return false
	_reservations[key] = int(_reservations.get(key, 0)) + 1
	_request_sequence += 1
	_requests[_request_sequence] = {"id": _request_sequence, "generation": _generation, "hit": hit,
		"packed": weapon.projectile, "position": position, "weapon": weapon, "rank": rank, "target": weakref(target), "key": key}
	call_deferred("_materialize", _request_sequence)
	return true

func queue_drone_bolt(owner_id: StringName, upgrade: UpgradeDefinition, rank: int, position: Vector2, direction: Vector2, multiplier: float, modifiers: Dictionary, critical_chance: float) -> bool:
	if rank < 1 or rank > upgrade.max_rank or not owner_alive(owner_id) or not direction.is_finite() or direction.is_zero_approx():
		return false
	var weapon := upgrade.weapon
	if weapon == null:
		return false
	var key := StringName("%s:%s" % [owner_id, weapon.projectile.resource_path])
	if int(_reservations.get(key, 0)) >= weapon.active_limit:
		return false
	var base := upgrade.rank_value(rank)
	var allowed := modifiers.duplicate()
	allowed.erase(&"energy_chains")
	var hit := create_hit(owner_id, base, base * multiplier, allowed, PlayerHitSnapshot.Kind.DRONE, critical_chance)
	if hit == null:
		return false
	_reservations[key] = int(_reservations.get(key, 0)) + 1
	_request_sequence += 1
	_requests[_request_sequence] = {"id": _request_sequence, "generation": _generation, "hit": hit,
		"packed": weapon.projectile, "position": position, "velocity": direction.normalized() * weapon.projectile_speed,
		"lifetime": weapon.projectile_lifetime, "key": key}
	call_deferred("_materialize", _request_sequence)
	return true

func _materialize(id: int) -> void:
	if not _requests.has(id):
		return
	var request: Dictionary = _requests[id]
	_requests.erase(id)
	if request.generation != _generation or not owner_alive(request.hit.owner_id()) or not is_inside_tree() or get_parent().is_queued_for_deletion():
		release_reservation(request.key)
		release_root(request.hit)
		return
	var shot := ProjectilePool.spawn(request.packed, request.position, get_parent())
	if request.has("weapon"):
		shot.configure_missile(request.hit, self, request.key, request.weapon, request.target, request.rank)
		return
	if not shot.has_method("configure_hit"):
		release_reservation(request.key)
		release_root(request.hit)
		ProjectilePool.despawn(shot)
		return
	shot.configure_hit(request.hit, self, request.key)
	shot.damage = request.hit.damage()
	shot.player_Id = String(request.hit.owner_id())
	shot.speedX = request.velocity.x
	shot.speedY = request.velocity.y
	shot.remaining_lifetime = request.lifetime
	shot.setPowerAnim()

func release_reservation(key: StringName) -> void:
	if key == &"" or not _reservations.has(key):
		return
	_reservations[key] -= 1
	if _reservations[key] <= 0:
		_reservations.erase(key)

func stop_owner(owner_id: StringName) -> void:
	_disabled_owners[owner_id] = true
	_chain_cooldowns.erase(owner_id)
	for id in _chain_requests.keys():
		var hit: PlayerHitSnapshot = _chain_requests[id].hit
		if hit.owner_id() == owner_id:
			_chain_requests.erase(id)
			release_root(hit)
	for id in _requests.keys():
		var request: Dictionary = _requests[id]
		if request.hit.owner_id() == owner_id:
			_requests.erase(id)
			release_reservation(request.key)
			release_root(request.hit)

func cancel() -> void:
	_running = false
	_generation += 1
	_requests.clear()
	_chain_requests.clear()
	_chain_cooldowns.clear()
	_reservations.clear()
	_roots.clear()
	_players.clear()
	_random = null

func get_debug_snapshot() -> Dictionary:
	var reservations := 0
	for count in _reservations.values():
		reservations += int(count)
	return {"roots": _roots.size(), "requests": _requests.size() + _chain_requests.size(), "reservations": reservations}

func _exit_tree() -> void:
	cancel()

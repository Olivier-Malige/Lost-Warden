class_name PlayerHitEffects
extends Node

signal hit_accepted(hit: PlayerHitSnapshot, target_id: StringName, position: Vector2, first_impact: bool)

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

func create_hit(owner_id: StringName, base: float, direct: float, modifiers: Dictionary = {}, kind: PlayerHitSnapshot.Kind = PlayerHitSnapshot.Kind.GUN) -> PlayerHitSnapshot:
	if not owner_alive(owner_id) or not is_finite(base) or not is_finite(direct) or base <= 0.0 or direct <= 0.0:
		return null
	_sequences[owner_id] = _sequences.get(owner_id, 0) + 1
	var hit := PlayerHitSnapshot.new(owner_id, _sequences[owner_id], base, direct, modifiers, kind, false, _generation)
	_roots[hit.root_id()] = {"leases": 1, "groups": {}, "first": true}
	return hit

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
	if not target.receive_player_hit(hit.damage(), hit.owner_id(), feedback):
		return false
	entry.groups[group] = true
	var first: bool = entry.first and hit.kind() == PlayerHitSnapshot.Kind.GUN and owner_alive(hit.owner_id())
	if hit.kind() != PlayerHitSnapshot.Kind.SECONDARY:
		entry.first = false
	hit_accepted.emit(hit.copy(), CombatTargeting.identity(target), position, first)
	return true

# Reserve capacity and root lifetime before scheduling any CollisionObject2D creation.
func queue_projectile(hit: PlayerHitSnapshot, packed: PackedScene, position: Vector2, velocity: Vector2, lifetime: float, capacity: int, damage_scale := 1.0) -> bool:
	if hit == null or hit.kind() != PlayerHitSnapshot.Kind.GUN or packed == null or not owner_alive(hit.owner_id()) or not is_finite(lifetime) or lifetime <= 0.0 or not is_finite(damage_scale) or damage_scale <= 0.0 or capacity <= 0:
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
	_reservations.clear()
	_roots.clear()
	_players.clear()
	_random = null

func get_debug_snapshot() -> Dictionary:
	var reservations := 0
	for count in _reservations.values():
		reservations += int(count)
	return {"roots": _roots.size(), "requests": _requests.size(), "reservations": reservations}

func _exit_tree() -> void:
	cancel()

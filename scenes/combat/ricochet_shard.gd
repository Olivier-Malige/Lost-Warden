extends Node2D

const Layers := preload("res://core/collision_layers.gd")
const TEXTURE := preload("res://assets/sprites/combat/ricochet_shard.png")
const DEFINITION: UpgradeDefinition = preload("res://data/upgrades/ricochet.tres")

var hit: PlayerHitSnapshot
var service: PlayerHitEffects
var reservation: StringName
var target: WeakRef
var remaining := 0
var age := 0.0
var exclusions: Array[RID] = []
var impact_age := -1.0
var team_row := 0
var previous_impact := Vector2.ZERO
var impact_left := 0.0
var last_group: StringName
var visited := {}

func configure(packet: PlayerHitSnapshot, effects: PlayerHitEffects, key: StringName, budget: int, exclude: Array[RID], initial_target: WeakRef = null, origin_group: StringName = &"") -> void:
	hit = packet
	service = effects
	reservation = key
	remaining = budget
	age = 0.0
	impact_age = -1.0
	exclusions = exclude.duplicate()
	team_row = 0 if hit.owner_id() == &"player1" else 1
	impact_left = 0.0
	last_group = origin_group
	visited = {origin_group: true}
	target = initial_target
	if target == null: acquire_target()
	queue_redraw()

# Prefer fresh hulls, but let a small surviving group sustain physical return trips.
func acquire_target() -> bool:
	var forbidden := service.visited_groups(hit, &"ricochet")
	forbidden[last_group] = true
	var fresh := forbidden.duplicate()
	fresh.merge(visited, true)
	var candidates := CombatTargeting.targets(get_parent(), global_position, DEFINITION.range_value(1), fresh, true, exclusions)
	if candidates.is_empty():
		candidates = CombatTargeting.targets(get_parent(), global_position, DEFINITION.range_value(1), forbidden, true, exclusions)
	target = weakref(candidates[0]) if not candidates.is_empty() else null
	return target != null

func _physics_process(delta: float) -> void:
	if hit == null or get_tree().paused: return
	if not service or not service._running or not service._roots.has(hit.root_id()):
		ProjectilePool.despawn(self)
		return
	age += delta
	if impact_left > 0.0: queue_redraw()
	impact_left = maxf(0.0, impact_left - delta)
	if age >= DEFINITION.weapon.projectile_lifetime:
		ProjectilePool.despawn(self)
		return
	if impact_age >= 0.0:
		impact_age += delta
		queue_redraw()
		if impact_age >= 0.12: ProjectilePool.despawn(self)
		return
	var destination: Area2D = target.get_ref() if target else null
	if not CombatTargeting.eligible(get_parent(), destination) or CombatTargeting.group_identity(destination) == last_group or service.visited_groups(hit, &"ricochet").has(CombatTargeting.group_identity(destination)):
		if not acquire_target():
			ProjectilePool.despawn(self)
			return
		destination = target.get_ref()
	var endpoint := global_position.move_toward(destination.global_position, DEFINITION.weapon.projectile_speed * delta)
	var ray := PhysicsRayQueryParameters2D.create(global_position, endpoint, Layers.ENEMY | Layers.ASTEROID, exclusions)
	ray.collide_with_areas = true
	ray.collide_with_bodies = false
	ray.hit_from_inside = true
	var contact := get_world_2d().direct_space_state.intersect_ray(ray)
	rotation = (endpoint - global_position).angle()
	global_position = endpoint
	if contact.is_empty(): return
	global_position = contact.position
	var surface := contact.collider as Area2D
	if surface == null or surface.get("armored") == true or CombatTargeting.group_identity(surface) == last_group or not service.resolve_hit(hit, surface, true, global_position, &"ricochet"):
		impact_age = 0.0
		return
	remaining -= 1
	last_group = CombatTargeting.group_identity(surface)
	visited[last_group] = true
	previous_impact = global_position
	impact_left = 0.12
	exclusions = CombatTargeting.origin_exclusions(surface)
	hit = hit.secondary_hit(hit.damage() * DEFINITION.secondary_damage_retention)
	if remaining <= 0 or not acquire_target(): impact_age = 0.0
	queue_redraw()

func _draw() -> void:
	var frame := 0 if impact_age < 0.0 else mini(3, 1 + int(impact_age / 0.04))
	draw_texture_rect_region(TEXTURE, Rect2(-8, -8, 16, 16), Rect2(frame * 16, team_row * 16, 16, 16))
	if impact_left > 0.0 and impact_age < 0.0:
		draw_texture_rect_region(TEXTURE, Rect2(to_local(previous_impact) - Vector2(8, 8), Vector2(16, 16)), Rect2((1 + mini(2, int((0.12 - impact_left) / 0.04))) * 16, team_row * 16, 16, 16))

func reset_hit_state() -> void:
	if service:
		service.release_reservation(reservation)
		service.release_root(hit)
	hit = null
	service = null
	reservation = &""
	target = null
	remaining = 0
	age = 0.0
	impact_age = -1.0
	impact_left = 0.0
	last_group = &""
	visited.clear()
	exclusions.clear()
	rotation = 0.0

func _exit_tree() -> void:
	reset_hit_state()

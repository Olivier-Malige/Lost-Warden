class_name CombatTargeting
extends RefCounted

const Layers := preload("res://core/collision_layers.gd")

static func damage_group(target: Node) -> Node:
	return target.player_damage_group() if target.has_method("player_damage_group") else target

static func identity(target: Node) -> StringName:
	return target.get_combat_identity() if target.has_method("get_combat_identity") else &""

static func group_identity(target: Node) -> StringName:
	return identity(damage_group(target))

# A jump can leave an overlapping vulnerable group, while its armor still occludes rays.
static func origin_exclusions(target: Area2D) -> Array[RID]:
	var group := damage_group(target)
	var surfaces: Array[Node] = [group]
	surfaces.append_array(group.find_children("*", "Area2D", true, false))
	var result: Array[RID] = []
	for surface in surfaces:
		if surface is Area2D and damage_group(surface) == group and surface.get("armored") != true:
			result.append(surface.get_rid())
	return result

static func eligible(world: Node2D, target: Node2D) -> bool:
	if not is_instance_valid(target) or not world.is_ancestor_of(target) or not target.is_visible_in_tree():
		return false
	if identity(target) == &"" or not target.has_method("can_receive_player_hit") or not target.can_receive_player_hit():
		return false
	return world.get_viewport_rect().has_point(target.get_global_transform_with_canvas().origin)

static func has_line_of_sight(world: Node2D, origin: Vector2, target: Area2D, exclude: Array[RID] = []) -> bool:
	var query := PhysicsRayQueryParameters2D.create(origin, target.global_position, Layers.ENEMY | Layers.ASTEROID, exclude)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := world.get_world_2d().direct_space_state.intersect_ray(query)
	return not result.is_empty() and result.collider == target

# Sort surfaces before reducing logical groups, so equally distant boss parts have stable ownership.
static func targets(world: Node2D, origin: Vector2, radius: float, excluded_groups: Dictionary = {}, require_sight := true, exclude: Array[RID] = [], forward_degrees := 360.0) -> Array[Area2D]:
	var candidates: Array[Area2D] = []
	for group in [&"enemy", &"boss_hit_zone"]:
		for target in world.get_tree().get_nodes_in_group(group):
			if target is Area2D and eligible(world, target) and not excluded_groups.has(group_identity(target)) and origin.distance_squared_to(target.global_position) <= radius * radius:
				if forward_degrees < 360.0 and not in_forward_cone(origin, target.global_position, forward_degrees):
					continue
				if not require_sight or has_line_of_sight(world, origin, target, exclude):
					candidates.append(target)
	candidates.sort_custom(func(a: Area2D, b: Area2D) -> bool:
		var da := origin.distance_squared_to(a.global_position)
		var db := origin.distance_squared_to(b.global_position)
		return String(identity(a)) < String(identity(b)) if da == db else da < db
	)
	var result: Array[Area2D] = []
	var seen := {}
	for target in candidates:
		var id := group_identity(target)
		if not seen.has(id):
			seen[id] = true
			result.append(target)
	return result

# Nomad faces screen-up; a passed target must not pull a guided missile backward.
static func in_forward_cone(origin: Vector2, point: Vector2, angle_degrees: float) -> bool:
	var offset := point - origin
	return offset.y < 0.0 and offset.normalized().dot(Vector2.UP) >= cos(deg_to_rad(angle_degrees * 0.5)) - 0.00001

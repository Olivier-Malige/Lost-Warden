class_name ProjectilePool
extends Node

class ProjectileBucket:
	extends RefCounted
	var nodes: Array[Node] = []

var _free: Dictionary[String, ProjectileBucket] = {}


func _ready() -> void:
	add_to_group("projectile_pool")


func acquire(packed: PackedScene) -> Node:
	var key := packed.resource_path
	var bucket: ProjectileBucket = _free.get(key)
	var node: Node
	if bucket:
		while not bucket.nodes.is_empty():
			node = bucket.nodes.pop_back()
			if is_instance_valid(node):
				break
			node = null
	if node == null:
		node = packed.instantiate()
		node.set_meta("pool_key", key)
	else:
		if node.get_parent() == self:
			remove_child(node)
		node.set_meta("pooled", false)
		node.process_mode = Node.PROCESS_MODE_INHERIT
		node.set_process(true)
		node.set_physics_process(true)
		if node is CanvasItem:
			(node as CanvasItem).visible = true
		if node is Area2D:
			(node as Area2D).monitoring = true
			(node as Area2D).monitorable = true
		if node.has_method("prepare"):
			node.prepare()
	return node


func release(node: Node) -> void:
	if not is_instance_valid(node) or node.get_meta("pooled", false):
		return
	node.set_meta("pooled", true)
	node.set_process(false)
	node.set_physics_process(false)
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	call_deferred("_park", node)


# Reparent after the physics callback so Area2D can leave the world safely.
func _park(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is Area2D:
		(node as Area2D).monitoring = false
		(node as Area2D).monitorable = false
	var parent := node.get_parent()
	if parent and parent != self:
		parent.remove_child(node)
	if node.get_parent() != self:
		add_child(node)
	var key: String = node.get_meta("pool_key", node.scene_file_path)
	if not _free.has(key):
		_free[key] = ProjectileBucket.new()
	var bucket := _free[key]
	if not bucket.nodes.has(node):
		bucket.nodes.append(node)


static func spawn(packed: PackedScene, world_pos: Vector2, parent: Node) -> Node:
	var pool := parent.get_tree().get_first_node_in_group("projectile_pool")
	var node: Node
	if pool:
		node = pool.acquire(packed)
	else:
		node = packed.instantiate()
	parent.add_child(node)
	if node is Node2D:
		(node as Node2D).global_position = world_pos
	return node


static func despawn(node: Node) -> void:
	if not is_instance_valid(node) or node.get_meta("pooled", false):
		return
	var pool: Node = null
	if node.is_inside_tree():
		pool = node.get_tree().get_first_node_in_group("projectile_pool")
	if pool:
		pool.release(node)
	else:
		node.queue_free()

extends "res://scenes/waves/wave_spawner.gd"

const ECONOMY_ENEMY := preload("res://tests/fixtures/xp_economy_enemy.gd")

var bodies: Array[Dictionary] = []
var tick := 0
var spawn_trace: Array = []
var kills := 0
var fragments := 0

func _ready() -> void:
	pass

# Dispatch outside the engine physics flush so virtual time needs no wall-time frame.
func _flush_pending() -> void:
	var due: Array[Dictionary] = []
	for item in _pending:
		if item.at <= director.elapsed + 0.000001:
			due.append(item)
	for item in due:
		_pending.erase(item)
		_materialize(item)

func _materialize(item: Dictionary) -> void:
	_release_reservation(item)
	if not _running or item.generation != _generation:
		return
	var enemy := (item.scene as PackedScene).instantiate() as Enemy
	_prepare(enemy)
	enemy.configure_spawn(item.context)
	enemy.position = item.position
	add_child(enemy)
	_register(enemy)
	enemy_spawned.emit(enemy)

# Only deferred dispatch is replaced; the shipped cap and fragment construction are used.
func queue_enemy(enemy: Enemy) -> bool:
	if not _running or director.state not in [EncounterDirector.State.REGULAR, EncounterDirector.State.BOSS_APPROACH] or _available_members(enemy.definition) < 1:
		enemy.free()
		return false
	_prepare(enemy)
	add_child(enemy)
	_register(enemy)
	enemy_spawned.emit(enemy)
	return true

func _prepare(enemy: Enemy) -> void:
	if enemy.definition.sprite_variants > 1:
		var saved_definition := enemy.definition
		var saved_context := enemy._spawn_context
		enemy.set_script(ECONOMY_ENEMY)
		enemy.definition = saved_definition
		enemy.configure_spawn(saved_context)
	_freeze(enemy)

func _freeze(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is Area2D:
		node.monitoring = false
		node.monitorable = false
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		_freeze(child)

func _register(enemy: Enemy) -> void:
	_freeze(enemy)
	var mounted: Array[Enemy] = []
	for child in enemy.get_children():
		if child is Enemy:
			mounted.append(child)
	# Resolve separately scripted mounted targets before their hull can retire them.
	for child in mounted:
		_register(child)
	bodies.append({"enemy": enemy, "kill_at": tick + 60, "free_at": -1})
	spawn_trace.append([tick, String(enemy.definition.id), enemy.position.x, enemy.position.y,
		enemy._spawn_context.movement_seed, enemy.elite, enemy._spawn_context.asteroid_fragment])
	fragments += int(enemy._spawn_context.asteroid_fragment)

func advance() -> void:
	_physics_process(1.0 / 60.0)
	for body in bodies.duplicate():
		if not is_instance_valid(body.enemy):
			bodies.erase(body)
			continue
		var enemy: Enemy = body.enemy
		if body.free_at >= 0:
			if tick >= body.free_at:
				enemy.free()
				bodies.erase(body)
		elif tick >= body.kill_at:
			enemy.destroyed = true
			enemy._award_player_kill()
			kills += 1
			if enemy.definition.drops_on_destroy:
				enemy._drop_debris()
			var animation := enemy.get_node("anim") as AnimationPlayer
			body.free_at = tick + ceili(animation.get_animation("explode").length * 60.0)

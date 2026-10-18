extends SceneTree

var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _player(stage: Node2D, at: Vector2, second := false) -> Variant:
	var player = load("res://scenes/player/player.tscn").instantiate()
	player.set_Player_2 = second
	stage.add_child(player)
	player.position = at
	player.set_physics_process(false)
	player.hit_audio.stream = null
	player.explosion_audio.stream = null
	player.energy = 12
	return player

func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var first = _player(stage, Vector2(320, 300))
	var second = _player(stage, Vector2(400, 300), true)
	var beam = load("res://scenes/bosses/dread_ark_beam.gd").new()
	stage.add_child(beam)
	beam.set_physics_process(false)
	beam.position = Vector2(320, 100)
	beam.offsets = PackedFloat32Array([-40, 0, 40])
	beam.warn()
	_check(beam.warning and not beam.visible, "beam preparation keeps its state without projecting lane indicators")
	beam._physics_process(1.0)
	_check(first.energy == 12 and second.energy == 12, "warnings never drain real player energy")
	first._hit_something()
	first._hit_something()
	_check(first.energy == 11 and first.touched, "ordinary impacts retain the existing hit protection")
	beam.fire()
	_check(beam.visible, "the actual beam becomes visible when firing begins")
	beam._physics_process(0.01)
	_check(first.energy == 10 and second.energy == 12, "beam contact damages a real player despite ordinary hit protection")
	beam._physics_process(0.34)
	_check(first.energy == 10, "beam contact respects its configured damage interval")
	beam._physics_process(0.02)
	_check(first.energy == 9, "remaining in the beam causes another energy loss before normal protection ends")
	second.position.x = 360
	beam._physics_process(0.01)
	_check(first.energy == 9 and second.energy == 11, "co-op entry causes immediate damage without sharing the other player's cooldown")
	first.position.x = 400
	beam._physics_process(0.1)
	first.position.x = 320
	beam._physics_process(0.01)
	_check(first.energy == 9, "briefly leaving and reentering cannot cause an extra hit within one interval")
	first.position.x = 400
	beam._physics_process(0.5)
	_check(first.energy == 9 and second.energy == 10, "leaving stops damage while the partner's exposure continues")
	first.position.x = 320
	beam._physics_process(0.01)
	_check(first.energy == 8, "reentry after the cooldown causes a fresh contact hit")
	beam.offsets = PackedFloat32Array([0])
	beam._physics_process(0.4)
	_check(first.energy == 7 and second.energy == 10, "removing a destroyed cannon's lane immediately stops its contact damage")
	var shape := first.get_node("CollisionShape2D") as CollisionShape2D
	shape.disabled = true
	beam._physics_process(0.4)
	_check(first.energy == 7, "disabled player collision shapes remain immune")
	shape.disabled = false
	beam.stop()
	beam._physics_process(1.0)
	_check(first.energy == 7 and beam._contact_cooldowns.is_empty(), "stopping clears contact timers and cancels damage")
	first.energy = 3
	first.touched = true
	beam.fire()
	beam._physics_process(0.01)
	_check(first.energy == 2, "a new firing cycle starts with fresh contact damage")
	beam._physics_process(0.36)
	_check(first.energy == 1, "sustained exposure drains a second point")
	beam._physics_process(0.36)
	_check(first.energy == 0 and first.state == first.State.DYING, "standing in the beam can exhaust starting energy within the firing window")
	var explosion_position: Vector2 = first.explosion_sprite.position
	beam._physics_process(0.5)
	first._hit_by_beam()
	_check(first.energy == 0 and first.explosion_sprite.position == explosion_position, "dying players cannot receive further continuous damage")
	beam.stop()
	beam.warn()
	beam._physics_process(1.0)
	_check(second.energy == 10 and beam._contact_cooldowns.is_empty(), "later warning cycles remain harmless and clear contact history")
	var definition = load("res://data/bosses/dread_ark.tres").duplicate()
	_check(is_equal_approx(definition.beam_damage_interval, 0.35) and definition.is_valid(), "boss damage cadence is authored in its resource")
	for invalid_interval in [0.0, -0.1]:
		definition.beam_damage_interval = invalid_interval
		_check(not definition.is_valid(), "boss definitions reject nonpositive damage intervals")
	for player in [first, second]:
		player.weapons.player = null
		player.vitals.player = null
	stage.free()
	await process_frame
	print("Boss beam continuous damage: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)

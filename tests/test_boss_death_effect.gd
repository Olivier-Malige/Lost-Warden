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

func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var layer := CanvasLayer.new()
	layer.name = "FeedbackLayer"
	var flash := ColorRect.new()
	flash.name = "Flash"
	flash.color = Color(1, 1, 1, 0)
	layer.add_child(flash)
	stage.add_child(layer)
	var feedback = load("res://scenes/world/combat_feedback.gd").new()
	stage.add_child(feedback)
	feedback.set_process(false)
	feedback._noise_position = 0.0
	feedback._on_screen_shake_requested(26.0, 0.9)
	feedback._process(0.05)
	var normal_offset: float = feedback.offset.length()
	_check(feedback._shake_strength == feedback.MAX_SHAKE, "ordinary combat impacts retain their original shake cap")
	feedback._process(2.0)
	feedback._noise_position = 0.0
	feedback._on_screen_shake_requested(52.0, 1.15)
	feedback._process(0.05)
	_check(feedback.offset.length() > normal_offset * 1.9, "the heavier boss impulse produces roughly twice the actual camera displacement")
	feedback._process(2.0)
	var events = root.get_node("Events")
	var shakes: Array[Vector2] = []
	var on_shake := func(strength: float, duration: float): shakes.append(Vector2(strength, duration))
	events.screen_shake_requested.connect(on_shake)
	var data = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	boss.position = Vector2(320, 82)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss._physics_process(2.0)
	boss._hit_something(boss.life, false)
	var effects := get_nodes_in_group("boss_death_effect")
	_check(effects.size() == 1 and boss.destroyed and not boss.combat_active, "boss defeat creates exactly one cosmetic death sequence while stopping combat immediately")
	boss._hit_something(1000.0, false)
	_check(get_nodes_in_group("boss_death_effect").size() == 1, "repeated lethal hits do not duplicate death explosions")
	var effect = effects[0]
	effect.set_process(false)
	_check(effect.get_parent() == stage and effect.global_position == boss.global_position, "death effects belong to the world and remain anchored to the defeated boss position")
	effect._process(0.0)
	_check(effect._next_burst == 1 and not effect._final_fired, "the chain starts with a small hull explosion")
	effect._process(0.36)
	_check(effect._next_burst == 4 and not effect._final_fired, "secondary explosions advance across separate hull positions")
	var count := shakes.size()
	effect._process(0.0)
	_check(shakes.size() == count, "each secondary explosion requests shake only once")
	effect.set_process(true)
	paused = true
	var before: float = effect._elapsed
	await create_timer(0.1).timeout
	_check(effect._elapsed == before, "pause freezes the death sequence and its scheduled final blast")
	effect.set_process(false)
	paused = false
	effect._process(0.61)
	_check(effect._next_burst == 8 and effect._final_fired, "eight hull explosions lead into a larger central detonation")
	_check(shakes.back() == Vector2(52.0, 1.15), "the final detonation requests a stronger and longer boss shake")
	_check(feedback._shake_strength == feedback.MAX_STRONG_SHAKE and feedback._shake_time >= 1.15, "the world camera reaches its larger scripted-impact limit at the final blast")
	feedback._on_screen_shake_requested(6.0, 0.2)
	_check(feedback._shake_strength == feedback.MAX_STRONG_SHAKE, "a small subsequent impact does not truncate the stronger boss shake")
	_check(flash.color.a > 0.0 and layer.transform == Transform2D.IDENTITY, "the final blast flashes briefly without displacing the HUD layer")
	count = shakes.size()
	effect._process(0.0)
	_check(shakes.size() == count, "the final shock is emitted exactly once")
	var position_before: Vector2 = effect.global_position
	boss.free()
	_check(is_instance_valid(effect) and effect.global_position == position_before, "the destruction sequence survives removal of the original boss actor")
	feedback._process(1.3)
	_check(feedback.offset == Vector2.ZERO and feedback._shake_strength == 0.0, "the strong shake decays completely without leaving the camera offset")
	feedback._on_screen_shake_requested(26.0, 0.45)
	_check(feedback._shake_strength == feedback.MAX_SHAKE, "ordinary combat returns to its normal shake cap after the boss effect ends")
	effect._process(1.0)
	await process_frame
	_check(not is_instance_valid(effect), "the effect cleans itself up after the final blast")
	events.screen_shake_requested.disconnect(on_shake)
	stage.free()
	await process_frame
	print("Boss death sequence: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)

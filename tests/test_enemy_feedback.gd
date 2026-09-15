extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func make_enemy(kind: String) -> Variant:
	var enemy = load("res://scenes/enemies/" + kind + ".tscn").instantiate()
	root.add_child(enemy)
	enemy.position = Vector2(300, 100)
	enemy.set_physics_process(false)
	enemy.set_deferred("monitoring", false)
	for timer in enemy.find_children("*", "Timer", true, false):
		timer.stop()
	for sound in enemy.find_children("*", "AudioStreamPlayer2D", true, false):
		sound.stream = null
	enemy.life = 100
	enemy.get_node("anim").advance(0.0)
	return enemy

func run() -> void:
	for kind in ["drone", "interceptor", "tie", "turret", "mother_ship", "asteroid", "big_asteroid"]:
		var enemy = make_enemy(kind)
		var other = make_enemy(kind)
		var sprite: Sprite2D = enemy._hit_sprite
		if kind in ["drone", "interceptor", "tie"]:
			check(sprite.flip_v, kind + ": nose must face down the playfield")
		if kind in ["interceptor", "tie"]:
			check(enemy.get_node("shootFrom").position.y >= 13.0, kind + ": shots must originate at the nose")
		sprite.self_modulate = Color(0.5, 0.8, 1.0)
		enemy._hit_something(1)
		check(sprite.get_instance_shader_parameter("hit_flash") == 1.0, kind + ": each hit must flash immediately")
		check(other._hit_sprite.get_instance_shader_parameter("hit_flash") != 1.0, kind + ": another enemy must not flash")
		await create_timer(0.08).timeout
		check(float(sprite.get_instance_shader_parameter("hit_flash")) < 1.0, kind + ": flash must fade after its white peak")
		enemy._hit_something(1)
		check(sprite.get_instance_shader_parameter("hit_flash") == 1.0, kind + ": consecutive hits must restart the flash")
		await create_timer(0.16).timeout
		check(is_zero_approx(float(sprite.get_instance_shader_parameter("hit_flash"))), kind + ": flash must fully settle")
		check(sprite.self_modulate == Color(0.5, 0.8, 1.0), kind + ": flash must preserve elite tint")
		var origin: Vector2 = enemy.position
		enemy._hit_something(1, false)
		check(sprite.get_instance_shader_parameter("hit_flash") == 1.0, kind + ": beam damage must also flash")
		check(enemy.position == origin, kind + ": beam feedback must not add recoil")
		enemy.queue_free()
		other.queue_free()
		await process_frame
	for kind in ["tie_shot", "interceptor_side_shot"]:
		var shot = load("res://scenes/combat/" + kind + ".tscn").instantiate()
		var sprite: Sprite2D = shot.get_node("Sprite2D")
		var collider: CollisionShape2D = shot.get_node("CollisionShape2D")
		check(sprite.scale == Vector2.ONE, kind + ": lasers must retain native pixel scale")
		check(sprite.texture.get_height() >= 10, kind + ": laser must be long enough to read")
		check(collider.shape.size == sprite.texture.get_size(), kind + ": collision must match the new laser dimensions")
		check(collider.position == sprite.position, kind + ": collision must be centered on the laser")
		shot.free()
	print("Enemy feedback: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

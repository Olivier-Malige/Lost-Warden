extends SceneTree

const ELITE_DEFINITION := preload("res://data/enemies/elite_definition.tres")

var failures := 0
var stage: Node2D

func _initialize() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func make_enemy(kind: String, is_elite := false) -> Variant:
	var enemy = load("res://scenes/enemies/" + kind + ".tscn").instantiate()
	if is_elite:
		var context := EnemySpawnContext.new()
		context.elite = true
		context.elite_definition = ELITE_DEFINITION
		enemy.configure_spawn(context)
	stage.add_child(enemy)
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

func make_mounted_turret() -> Variant:
	var turret = load("res://scenes/enemies/mother_ship_turret.tscn").instantiate()
	stage.add_child(turret)
	turret.position = Vector2(300, 100)
	turret.set_physics_process(false)
	turret.set_deferred("monitoring", false)
	for timer in turret.find_children("*", "Timer", true, false):
		timer.stop()
	for sound in turret.find_children("*", "AudioStreamPlayer2D", true, false):
		sound.stream = null
	turret.life = 100
	turret.get_node("anim").advance(0.0)
	return turret

func check_lethal_transition(enemy: Variant, label: String) -> void:
	enemy.life = 1
	enemy._hit_something(1)
	check(enemy.destroyed, label + ": lethal damage must mark the enemy destroyed")
	check(enemy.get_node("anim").current_animation == "explode", label + ": lethal damage must keep the explosion animation")

func check_animation_frames(enemy: Variant, label: String) -> void:
	var sprite: Sprite2D = enemy._hit_sprite
	var animation_player: AnimationPlayer = enemy.get_node("anim")
	var frame_count := sprite.hframes * sprite.vframes
	for animation_name in animation_player.get_animation_list():
		check(not String(animation_name).begins_with("hit"), label + ": obsolete hit animation must be removed")
		var animation := animation_player.get_animation(animation_name)
		for track in animation.get_track_count():
			if not String(animation.track_get_path(track)).ends_with(":frame"):
				continue
			for key in animation.track_get_key_count(track):
				var frame := int(animation.track_get_key_value(track, key))
				check(frame >= 0 and frame < frame_count, label + ": " + animation_name + " references an invalid frame")

func check_asteroid_variants(kind: String, variant_count: int) -> void:
	for variant in range(1, variant_count + 1):
		var enemy: Variant = make_enemy(kind)
		enemy.indexSprites = variant
		enemy.get_node("anim").play("start" + str(variant))
		var animation_before_hit: StringName = enemy.get_node("anim").current_animation
		enemy._hit_something(1)
		check(enemy.get_node("anim").current_animation == animation_before_hit, kind + " variant " + str(variant) + ": hit shader must preserve rotation")
		check(enemy._hit_sprite.get_instance_shader_parameter("hit_flash") == 1.0, kind + " variant " + str(variant) + ": must use the shared hit shader")
		enemy.queue_free()
		await process_frame

func run() -> void:
	for kind in ["drone", "interceptor", "tie", "turret", "mother_ship", "asteroid", "big_asteroid"]:
		var enemy = make_enemy(kind)
		var other = make_enemy(kind)
		var sprite: Sprite2D = enemy._hit_sprite
		var animation: AnimationPlayer = enemy.get_node("anim")
		check_animation_frames(enemy, kind)
		if kind in ["drone", "interceptor", "tie"]:
			check(sprite.flip_v, kind + ": nose must face down the playfield")
			check(animation.has_animation(&"bank_left") and animation.has_animation(&"bank_right"), kind + ": must expose authored left and right banking animations")
			enemy.speedX = -120.0
			enemy._update_ship_banking(0.016)
			check(animation.current_animation == &"bank_left", kind + ": left movement must play the authored left banking frames")
			enemy._hit_something(1)
			check(animation.current_animation == &"bank_left", kind + ": hit shader must preserve the active left bank")
			check(sprite.get_instance_shader_parameter("hit_flash") == 1.0, kind + ": banking hits must trigger the shared shader")
			enemy.speedX = 120.0
			enemy._update_ship_banking(0.016)
			check(animation.current_animation == &"bank_right", kind + ": right movement must play the authored right banking frames")
			enemy.speedX = 0.0
			enemy._update_ship_banking(0.016)
			check(animation.current_animation == &"start", kind + ": neutral movement must return to idle")
		if kind in ["interceptor", "tie"]:
			check(enemy.get_node("shootFrom").position.y >= 13.0, kind + ": shots must originate at the nose")
		sprite.self_modulate = Color(0.5, 0.8, 1.0)
		var animation_before_hit: StringName = animation.current_animation
		enemy._hit_something(1)
		check(sprite.get_instance_shader_parameter("hit_flash") == 1.0, kind + ": each hit must flash immediately")
		check(animation.current_animation == animation_before_hit, kind + ": hit shader must preserve the current movement animation")
		check(other._hit_sprite.get_instance_shader_parameter("hit_flash") != 1.0, kind + ": another enemy must not flash")
		await create_timer(0.08).timeout
		check(float(sprite.get_instance_shader_parameter("hit_flash")) < 1.0, kind + ": flash must fade after its white peak")
		enemy._hit_something(1)
		check(sprite.get_instance_shader_parameter("hit_flash") == 1.0, kind + ": consecutive hits must restart the flash")
		await create_timer(0.16).timeout
		check(is_zero_approx(float(sprite.get_instance_shader_parameter("hit_flash"))), kind + ": flash must fully settle")
		check(animation.current_animation == animation_before_hit, kind + ": surviving hits must keep their movement animation")
		check(sprite.self_modulate == Color(0.5, 0.8, 1.0), kind + ": flash must preserve elite tint")
		var origin: Vector2 = enemy.position
		enemy._hit_something(1, false)
		check(sprite.get_instance_shader_parameter("hit_flash") == 1.0, kind + ": beam damage must also flash")
		check(enemy.position == origin, kind + ": beam feedback must not add recoil")
		check_lethal_transition(enemy, kind)
		enemy.queue_free()
		other.queue_free()
		await process_frame
	await check_asteroid_variants("asteroid", 3)
	await check_asteroid_variants("big_asteroid", 4)
	for kind in ["drone", "interceptor", "tie", "turret", "mother_ship"]:
		var elite: Variant = make_enemy(kind, true)
		var elite_sprite: Sprite2D = elite._hit_sprite
		check(elite.elite, kind + " elite: spawn context must be applied")
		check(elite.get_node_or_null("EliteIndicator") != null, kind + " elite: indicator must be present")
		check(elite_sprite.self_modulate == Color.WHITE, kind + " elite: approved markings must retain their source colors")
		elite._hit_something(1)
		check(elite_sprite.get_instance_shader_parameter("hit_flash") == 1.0, kind + " elite: hits must flash without losing identity")
		check(elite_sprite.self_modulate == Color.WHITE, kind + " elite: hit feedback must preserve source colors")
		check_lethal_transition(elite, kind + " elite")
		elite.queue_free()
		await process_frame
	var mounted: Variant = make_mounted_turret()
	var mounted_sprite: Sprite2D = mounted.get_node("Sprite2D")
	mounted._attack_state = mounted.AttackState.RING_TELEGRAPH
	mounted._physics_process(0.2)
	check(is_zero_approx(mounted_sprite.rotation), "mounted turret: radial telegraph must not spin its housing")
	mounted._patterns_started = true
	mounted._attack_state = mounted.AttackState.AIM_COOLDOWN
	mounted._on_attack_timer_timeout()
	check(mounted._attack_state == mounted.AttackState.AIM_TELEGRAPH, "mounted turret: aimed bursts must repeat without a radial ring")
	mounted.stop_patterns()
	var mounted_origin: Vector2 = mounted.position
	mounted._hit_something(1)
	check_animation_frames(mounted, "mounted turret")
	check(mounted_sprite.get_instance_shader_parameter("hit_flash") == 1.0, "mounted turret: hits must flash independently")
	check(mounted.get_node("anim").current_animation == "start", "mounted turret: hit shader must preserve its current animation")
	check(mounted.position == mounted_origin, "mounted turret: hit feedback must preserve its mount position")
	check_lethal_transition(mounted, "mounted turret")
	mounted.queue_free()
	await process_frame
	var pool := ProjectilePool.new()
	stage.add_child(pool)
	var collision_sizes := [Vector2(6, 12), Vector2(5, 5), Vector2(3, 10), Vector2(4, 4), Vector2(5, 5)]
	var kinds := ["tie_shot", "interceptor_shot", "interceptor_side_shot", "turret_shot", "mother_ship_shot"]
	for index in kinds.size():
		var kind: String = kinds[index]
		var packed: PackedScene = load("res://scenes/combat/" + kind + ".tscn")
		var shot = ProjectilePool.spawn(packed, Vector2(300, 100), stage)
		shot.set_physics_process(false)
		var sprite: Sprite2D = shot.get_node("Sprite2D")
		var collider: CollisionShape2D = shot.get_node("CollisionShape2D")
		var animation: AnimationPlayer = shot.get_node("AnimationPlayer")
		var frame_size := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
		var expected_scale := Vector2(0.75, 0.75) if index < 3 else Vector2.ONE
		check(sprite.scale == expected_scale, kind + ": small lasers must use the reduced visual footprint")
		check(frame_size == Vector2(32, 32), kind + ": animated projectiles must use the authored 32-pixel cells")
		check(animation.has_animation(&"flight"), kind + ": animated projectiles must expose their flight loop")
		check(collider.shape.size.x <= frame_size.x and collider.shape.size.y <= frame_size.y, kind + ": collision must remain inside the animated frame")
		check(collider.position == sprite.position, kind + ": collision must be centered on the laser")
		check(collider.shape.size == collision_sizes[index], kind + ": visual changes must preserve collision dimensions")
		check(not shot.rotate, kind + ": flight pulses must not spin rapidly")
		if kind != "turret_shot":
			check(shot.get_node_or_null("ProjectileGlow") == null, kind + ": authored red lasers must not have an oversized green halo")
		animation.pause()
		var flight := animation.get_animation(&"flight")
		check(is_equal_approx(flight.length, 0.48 if index < 3 else 0.64), kind + ": flight cadence must remain readable")
		for frame in range(4):
			animation.seek(flight.length * frame / 4.0 + 0.001, true)
			check(sprite.frame == frame, kind + ": playback must actually update frame " + str(frame))
		animation.play(&"flight")
		animation.advance(flight.length / 4.0)
		check(sprite.frame == 0, kind + ": flight must loop")
		animation.pause()
		animation.seek(flight.length * 0.75 + 0.001, true)
		ProjectilePool.despawn(shot)
		await process_frame
		var reused = ProjectilePool.spawn(packed, Vector2(300, 100), stage)
		check(reused == shot, kind + ": regression must exercise a reused projectile")
		reused.set_physics_process(false)
		await process_frame
		check(animation.is_playing() and sprite.frame == 0, kind + ": reuse must restart flight at the first frame")
		ProjectilePool.despawn(reused)
		await process_frame
	print("Enemy feedback: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

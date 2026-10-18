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

func _start(boss: Variant, kind: int) -> void:
	boss._clear_missiles()
	boss.attack = boss.Attack.IDLE
	boss._attack_left = 0.0
	for index in boss.attack_patterns().size():
		if boss.attack_patterns()[index].kind == kind:
			boss._attack_cycle = index
			break
	boss._physics_process(0.001)

func _first_shot(boss: Variant) -> Variant:
	for shot in get_nodes_in_group("enemy_Shot"):
		if not shot.get_meta("pooled", false) and shot.get_meta("boss_owner_id", 0) == boss.get_instance_id():
			return shot
	return null

func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var pool = load("res://scenes/combat/projectile_pool.gd").new()
	stage.add_child(pool)
	var data = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	boss.position = Vector2(320, 82)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss._physics_process(0.01)
	boss._physics_process(0.78)
	boss._movement_pause = 1000.0
	var flash := boss.get_node("MainMuzzle/PatternFlash") as AnimatedSprite2D
	_check(boss.get_node("MainMuzzle").position == Vector2(0, 42), "the main muzzle matches the approved atlas slice pivot")
	for animation in [&"charge", &"fire", &"recover"]:
		var duration := 4.0 / flash.sprite_frames.get_animation_speed(animation)
		_check(is_equal_approx(duration, 0.6 if animation == &"charge" else (0.3 if animation == &"fire" else 0.4)), "main cannon animation durations match charge, firing and recovery")
		_check(flash.sprite_frames.get_animation_loop(animation) == (animation == &"fire"), "only the continuous firing effect loops")
	for phase_index in 2:
		boss.phase = phase_index
		for kind in [BossAttackPattern.Kind.RINGS, BossAttackPattern.Kind.SPIRAL]:
			_start(boss, kind)
			_check(boss._visual == ("phase_2" if phase_index == 0 else "phase_3") and flash.visible and flash.animation == &"charge", "core patterns retain the correct hull and use a local charging effect")
			boss._physics_process(0.6)
			_check(flash.animation == &"fire" and flash.is_playing(), "the central cannon starts its looping firing animation")
			var shot = _first_shot(boss)
			_check(shot.scene_file_path.ends_with("dread_ark_orb.tscn") and not shot.align_with_velocity, "rings and spirals select round non-directional projectiles")
			_check(shot.global_position.is_equal_approx(boss.get_node("MainMuzzle").global_position), "the first orb originates exactly at the main cannon mouth")
			flash.set_frame_and_progress(2, 0.4)
			var clock: float = boss._visual_time
			boss._physics_process(boss._pattern.burst_interval)
			_check(flash.frame == 2 and is_equal_approx(flash.frame_progress, 0.4), "subsequent emissions do not restart the firing animation")
			_check(boss._visual_time > clock, "the hull idle animation also remains continuous across emissions")
			while boss._salvos_left > 0:
				boss._physics_process(boss._pattern.burst_interval)
			boss._physics_process(0.21)
			_check(flash.animation == &"recover" and flash.visible, "a completed pattern plays local recovery")
			boss._physics_process(0.4)
			_check(not flash.visible, "the local effect hides at the end of recovery")
	_start(boss, BossAttackPattern.Kind.AIMED)
	boss._physics_process(0.6)
	var missile = _first_shot(boss)
	_check(missile.scene_file_path.ends_with("dread_ark_shot.tscn") and missile.align_with_velocity and not flash.visible, "targeted salvos retain elongated oriented missiles and lateral animations")
	var missile_shape := missile.get_node("CollisionShape2D") as CollisionShape2D
	var service = load("res://scenes/combat/projectile_pool.gd")
	var orb = service.spawn(boss.BOSS_ORB, Vector2(400, 200), stage)
	var orb_shape := orb.get_node("CollisionShape2D") as CollisionShape2D
	_check(orb.damage == missile.damage and orb_shape.shape.size == missile_shape.shape.size and orb_shape.position == missile_shape.position, "orb damage and collision geometry remain identical to the missile")
	var texture: Texture2D = orb.get_node("Sprite2D").texture
	_check(texture.get_size() == Vector2(64, 16) and orb.get_node("Sprite2D").hframes == 4, "the orb atlas contains four 16-pixel cells")
	var image := texture.get_image()
	for frame in 4:
		var min_x := 16
		var max_x := -1
		var min_y := 16
		var max_y := -1
		var symmetric := true
		for y in 16:
			for x in 16:
				var opaque := image.get_pixel(frame * 16 + x, y).a > 0.0
				if opaque:
					min_x = mini(min_x, x)
					max_x = maxi(max_x, x)
					min_y = mini(min_y, y)
					max_y = maxi(max_y, y)
				symmetric = symmetric and opaque == (image.get_pixel(frame * 16 + 15 - x, y).a > 0.0) and opaque == (image.get_pixel(frame * 16 + x, 15 - y).a > 0.0)
		_check(max_x - min_x + 1 == 8 and max_y - min_y + 1 == 8 and symmetric, "every flight frame has a round eight-pixel silhouette without a tail")
	var orb_id: int = orb.get_instance_id()
	var missile_id: int = missile.get_instance_id()
	service.despawn(orb)
	boss._clear_missiles()
	await process_frame
	orb = service.spawn(boss.BOSS_ORB, Vector2(300, 200), stage)
	_check(orb.get_instance_id() == orb_id and not orb.align_with_velocity and orb.rotation == 0.0, "orb reuse restores flight state from its own pool bucket")
	missile = service.spawn(boss.BOSS_SHOT, Vector2(350, 200), stage)
	_check(missile.get_instance_id() != orb_id and orb.get_instance_id() != missile_id and missile.align_with_velocity, "missile and orb pool buckets cannot exchange presentation")
	var player = load("res://scenes/player/player.tscn").instantiate()
	stage.add_child(player)
	player.position = Vector2(500, 350)
	player.set_physics_process(false)
	player.shield.power = 1
	player.shield.get_node("sound_trowback").stream = null
	orb.speedX = 35.0
	orb.speedY = 145.0
	player.shield._on_shield_area_entered(orb)
	_check(orb.trowbackByShield and orb.speedX == -35.0 and orb.speedY == -145.0, "the shield reflects a round projectile through the normal velocity path")
	var health: float = boss.life
	orb._on_shot_area_entered(boss)
	_check(boss.life == health - orb.damage and orb.get_meta("pooled", false), "a reflected orb damages the boss and returns to its own pool")
	player.weapons.player = null
	player.vitals.player = null
	player.free()
	_start(boss, BossAttackPattern.Kind.RINGS)
	boss.get_node("PortCannon")._hit_something(10000.0)
	boss.get_node("StarboardCannon")._hit_something(10000.0)
	_check(flash.visible and boss.get_node("Sprite2D").texture == boss.DAMAGED_HULLS[2], "central charging coexists with both persistent cannon wrecks")
	boss._physics_process(0.6)
	boss.stop_combat()
	_check(not flash.visible and not flash.is_playing(), "run stop cancels the local cannon effect immediately")
	stage.free()
	await process_frame
	print("Boss main cannon presentation: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)

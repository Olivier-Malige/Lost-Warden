extends SceneTree

var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)

func _make_shot() -> Shot:
	var shot = load("res://scenes/combat/tie_shot.tscn").instantiate()
	root.add_child(shot)
	shot.position = Vector2(1000, 1000)
	shot.set_physics_process(false)
	shot.speedX = 30.0
	shot.speedY = 275.0
	shot.noDamageToGroup = "tie"
	return shot

func _run() -> void:
	var packed = load("res://scenes/player/player.tscn")
	for team in ["player1", "player2"]:
		var player = packed.instantiate()
		player.set_Player_2 = team == "player2"
		root.add_child(player)
		player.set_physics_process(false)
		var shield = player.shield
		var animation: AnimationPlayer = shield.get_node("AnimationPlayer")
		animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		shield.get_node("sound_trowback").stream = null
		for tier in range(1, 7):
			shield.power = -6
			shield.power = tier
			animation.advance(0.0)
			var base_frame: int = shield.get_node("Sprite2D").frame
			var guard_size: Vector2 = shield.get_node("CollisionShape2D").shape.size
			var shot := _make_shot()
			shield._on_shield_area_entered(shot)
			animation.advance(0.0)
			_check(shot.trowbackByShield and shot.speedY == -275.0 and shot.speedX == -30.0, "impact must reverse the projectile immediately")
			_check(shot.noDamageToGroup.is_empty(), "reflected shot must be able to hit its source")
			_check(shield.get_node("Sprite2D").frame == base_frame + 6, "impact must use the team's flash frame")
			var echo: Sprite2D = shield.get_node("ThrowbackEcho")
			_check(echo.frame == base_frame + 6 and echo.self_modulate.a > 0.0, "echo must match the shield's team and tier")
			var origin := echo.position
			shield._on_shield_area_entered(shot)
			_check(shot.speedY == -275.0, "the same shot must not be reflected twice")
			animation.advance(0.07)
			_check(shield.get_node("Sprite2D").frame == base_frame, "flash must settle within 70 ms")
			_check(echo.position.y < origin.y, "echo must travel toward the reflected shot")
			_check(shield.get_node("CollisionShape2D").shape.size == guard_size, "visual echo must not enlarge the guard")
			animation.advance(0.12)
			_check(echo.self_modulate.a == 0.0, "echo must disappear within 190 ms")
			_check(shield.power == tier, "shorter feedback must not consume a charge early")
			shot.queue_free()
		shield.power = -6
		shield.power = 1
		var shot := _make_shot()
		shield._on_shield_area_entered(shot)
		animation.advance(0.19)
		await create_timer(0.3).timeout
		_check(shield.power == 1, "charge must remain after the visual response")
		var followup := _make_shot()
		shield._on_shield_area_entered(followup)
		_check(shield.get_node("ChargeUseTimer").time_left < 0.8, "another shot must not postpone charge consumption")
		animation.advance(0.19)
		await create_timer(0.8).timeout
		await process_frame
		_check(shield.power == 0 and not shield.visible, "last charge must expire after the original one-second window")
		_check(not shield.monitoring and shield.get_node("CollisionShape2D").disabled, "depleted shield must disable its collider safely")
		shield.power = 1
		var refill_shot := _make_shot()
		shield._on_shield_area_entered(refill_shot)
		animation.advance(0.02)
		shield.power = 1
		_check(shield.get_node("ThrowbackEcho").self_modulate.a == 0.0, "pickup must clear an interrupted echo")
		_check(shield.get_node("ChargeUseTimer").is_stopped(), "pickup must retain the existing charge-window reset behavior")
		shot.queue_free()
		followup.queue_free()
		refill_shot.queue_free()
		player.weapons.player = null
		player.vitals.player = null
		player.queue_free()
		await process_frame
	print("Shield throwback: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)

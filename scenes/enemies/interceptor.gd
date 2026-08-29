extends Enemy


func _on_ShootTimer_timeout() -> void:
	$sound_Shooting.playing = true
	var origin: Vector2 = $shootFrom.global_position
	_spawn_shot(preload("res://scenes/combat/interceptor_side_shot.tscn"), origin, -150.0)
	_spawn_shot(preload("res://scenes/combat/tie_shot.tscn"), origin)
	_spawn_shot(preload("res://scenes/combat/interceptor_side_shot.tscn"), origin, 250.0)

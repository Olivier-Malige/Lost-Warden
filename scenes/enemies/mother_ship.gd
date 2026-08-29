extends Enemy


func _on_ShootTimer_timeout() -> void:
	$sound_Shooting.playing = true
	var packed: PackedScene = preload("res://scenes/combat/mother_ship_shot.tscn")
	_spawn_shot(packed, $ShootPos.global_position, -400.0)
	_spawn_shot(packed, $ShootPos1.global_position, 400.0)
	_spawn_shot(packed, $ShootPos2.global_position, -40.0)
	_spawn_shot(packed, $ShootPos3.global_position, 40.0)

func _on_anim_animation_finished(n: StringName) -> void:
	if n == "explode" or $anim.current_animation == "explode":
		for p in [$droneReactorParticles, $droneReactorParticles2, $droneReactorParticles3, $droneReactorParticles4]:
			p.queue_free()
		set_physics_process(false)
		queue_free()
	else:
		$anim.play("start")

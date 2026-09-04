extends Enemy


func shoot() -> void:
	_spawn_shot(preload("res://scenes/combat/tie_shot.tscn"), $shootFrom.global_position)
	$sound_Shooting.playing = true

func _on_shootTimer_timeout() -> void:
	shoot()

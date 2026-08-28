class_name PlayerVitals
extends RefCounted

var player: Player

func _init(p_player: Player) -> void:
	player = p_player

func hit(_dmg := 1) -> void:
	if player.touched:
		return
	if player.energy > 1:
		player.get_node("sound_Hit").playing = true
		player.energy -= 1
		player.update_energy()
		player.get_node("touchedReset").start()
		player.get_node("xWing").set_modulate(Color(2, 0.4, 0.4, 1))
		player.malusSpeed = player.STATS.malus_speed
		player.touched = true
		Events.screen_shake_requested.emit(12.0, 0.22)
		Events.screen_flash_requested.emit(Color(0.88, 0.12, 0.16, 0.2), 0.14)
	else:
		player.energy = 0
		player.get_node("sound_Explode").playing = true
		player.update_energy()
		player.get_node("anim").play(player.id_Player + "_explode")
		Events.screen_shake_requested.emit(18.0, 0.4)
		Events.screen_flash_requested.emit(Color(1.0, 0.35, 0.3, 0.28), 0.25)
		player.set_process(false)
		player.get_node("reactorParticles").set_emitting(false)
		player.get_node("reactorParticles2").set_emitting(false)
		player.get_node("CollisionShape2D").set_deferred("disabled", true)
		player.set_deferred("monitoring", false)
		player.set_deferred("monitorable", false)
		var shield := player.get_node_or_null("shield")
		if shield:
			shield.power = -shield.power
			shield.set_deferred("monitoring", false)
			shield.set_deferred("monitorable", false)

class_name PlayerVitals
extends RefCounted

var player: Player

func _init(p_player: Player) -> void:
	player = p_player

func hit(_dmg := 1) -> void:
	if player.touched:
		return
	if player.energy > 1:
		player.hit_audio.playing = true
		player.energy -= 1
		player.update_energy()
		player.touched_reset_timer.start()
		player.ship_sprite.set_modulate(Color(2, 0.4, 0.4, 1))
		player.malusSpeed = player.STATS.malus_speed
		player.touched = true
		player.set_state(Player.State.HIT)
		Events.screen_shake_requested.emit(12.0, 0.22)
		Events.screen_flash_requested.emit(Color(0.88, 0.12, 0.16, 0.2), 0.14)
	else:
		player.energy = 0
		player.reset_weapon_input()
		player.explosion_audio.playing = true
		player.update_energy()
		player.animation_player.play(player.id_Player + "_explode")
		Events.screen_shake_requested.emit(18.0, 0.4)
		Events.screen_flash_requested.emit(Color(1.0, 0.35, 0.3, 0.28), 0.25)
		player.set_state(Player.State.DYING)
		player.set_process(false)
		player.set_physics_process(false)
		player.effects.stop()
		player.collision_shape.set_deferred("disabled", true)
		player.set_deferred("monitoring", false)
		player.set_deferred("monitorable", false)
		player.shield.power = -player.shield.power
		player.shield.set_deferred("monitoring", false)
		player.shield.set_deferred("monitorable", false)

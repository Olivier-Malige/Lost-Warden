class_name PlayerVitals
extends RefCounted

var player: Player

func _init(p_player: Player) -> void:
	player = p_player

func repair_hull(amount: int) -> bool:
	if amount <= 0 or player.get_tree().paused or player.state >= Player.State.DYING or player.energy <= 0 or player.energy >= player.STATS.energy_max:
		return false
	player.energy = mini(player.STATS.energy_max, player.energy + amount)
	player.update_energy()
	return true

func hit(_dmg := 1, continuous_damage := false, body_contact := false) -> bool:
	if _dmg <= 0 or player.get_tree().paused or player.state >= Player.State.DYING or (player.touched and not continuous_damage):
		return false
	if player.defenses.absorb_hull_hit(body_contact):
		return false
	if player.energy > 1:
		player.hit_audio.playing = true
		player.energy -= 1
		player.update_energy()
		player.touched_reset_timer.start()
		player.ship_sprite.set_modulate(Color(2, 0.4, 0.4, 1))
		player.malusSpeed = player.STATS.malus_speed
		player.touched = true
		player.set_state(Player.State.HIT)
		player.defenses.hull_damaged()
		Events.screen_shake_requested.emit(18.0, 0.28)
		Events.screen_flash_requested.emit(Color(0.88, 0.12, 0.16, 0.2), 0.14)
	else:
		player.energy = 0
		player.reset_weapon_input()
		player.explosion_audio.playing = true
		player.update_energy()
		player.play_death_effect()
		player.animation_player.play(Player.EXPLODE_ANIMATION)
		Events.screen_shake_requested.emit(26.0, 0.45)
		Events.screen_flash_requested.emit(Color(1.0, 0.35, 0.3, 0.28), 0.25)
		player.set_state(Player.State.DYING)
		player.set_process(false)
		player.set_physics_process(false)
		player.effects.stop()
		player.collision_shape.set_deferred("disabled", true)
		player.set_deferred("monitoring", false)
		player.set_deferred("monitorable", false)
	return true

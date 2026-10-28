extends "res://tests/player/test_defensive_pack.gd"

func asteroid_body(path: String) -> Area2D:
	var body: Area2D = load(path).instantiate()
	var context := EnemySpawnContext.new()
	context.combat_id = &"shield_impact"
	body.configure_spawn(context)
	stage.add_child(body)
	body.position = p1.position
	body.set_physics_process(false)
	body.collision_mask = 0
	for timer in body.find_children("*", "Timer", true, false): timer.stop()
	for audio in body.find_children("*", "AudioStreamPlayer2D", true, false): audio.stream = null
	return body

func run() -> void:
	setup_stage()
	for value in range(1, 4):
		for path in ["asteroid", "big_asteroid", "drone"]:
			await reset_case()
			p1.collision_mask = CombatTargeting.Layers.ENEMY | CombatTargeting.Layers.ASTEROID
			equip(p1, SHIELD, value)
			var body := asteroid_body("res://scenes/enemies/%s.tscn" % path)
			var life_before: float = body.life
			await settle()
			p1.defenses._physics_process(0)
			check(p1.defenses.charges == 0 and p1.defenses.recharge_left == SHIELD.recharge_value(value), "a single real body impact shatters the entire sphere at every rank")
			check(p1.energy == 11 and body.life == life_before and p1.shield._rupture > 0, "reflection presents a break but cannot absorb a physical collision")
			body._on_area_entered(p1)
			p1.defenses._physics_process(0)
			check(p1.energy == 11, "callback and polling cannot duplicate the same hull injury")
			p1.defenses._physics_process(1.01)
			check(p1.energy == 10, "continued body overlap remains dangerous at ordinary injury cadence")
	for value in range(1, 4):
		for path in ["asteroid", "big_asteroid", "drone"]:
			await reset_case()
			p1.collision_mask = CombatTargeting.Layers.ENEMY | CombatTargeting.Layers.ASTEROID
			equip(p1, SHIELD, value)
			equip(p1, RIPOSTE, value)
			var body := asteroid_body("res://scenes/enemies/%s.tscn" % path)
			body.life = 100
			body._on_area_entered(p1)
			check(p1.defenses.charges == 0 and p1.energy == 12 and p1.defenses.pulse_cooldown == RIPOSTE.recharge_value(value), "enemy and asteroid contact break reflection and trigger retaliation at every rank")
			check(is_equal_approx(p1.defenses.pulse_protection_left, RIPOSTE.protection_duration), "asteroid and enemy collisions grant the same escape protection")
			if not p1.defenses._pulse_pending: continue
			body._on_area_entered(p1)
			pulse_now()
			check(p1.defenses._pulses.size() == 1 and p1.energy == 12, "repeated body callbacks create a single protective counterattack")
			p1.defenses._physics_process(RIPOSTE.protection_duration + 0.01)
			body._on_area_entered(p1)
			check(p1.energy == 11 and p1.defenses._pulses.size() == 1 and not p1.defenses._pulse_pending, "body collisions wound normally during recharge after protection ends")
	for value in range(1, 4): await projectile_capacity(value)
	await beam_contacts()
	effects.cancel()
	stage.free()
	await settle()
	print("Shield body rupture: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

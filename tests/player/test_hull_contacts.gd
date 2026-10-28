extends "res://tests/player/test_defensive_pack.gd"

class ContactCrossing extends Node:
	var player: Node2D
	var enemy: Node2D
	func _physics_process(delta: float) -> void:
		player.position += Vector2(240, 0) * delta
		enemy.position += Vector2(0, 300) * delta

func real_body(path: String, at: Vector2) -> Variant:
	var body = load(path).instantiate()
	var context := EnemySpawnContext.new()
	context.combat_id = &"contact_actor"
	body.configure_spawn(context)
	body.position = at
	stage.add_child(body)
	body.set_physics_process(false)
	body.collision_mask = 0
	for timer in body.find_children("*", "Timer", true, false): timer.stop()
	for audio in body.find_children("*", "AudioStreamPlayer2D", true, false): audio.stream = null
	return body

func enable_contacts() -> void:
	p1.collision_mask = CombatTargeting.Layers.ENEMY | CombatTargeting.Layers.ASTEROID

func run() -> void:
	setup_stage()
	await reset_case()
	enable_contacts()
	var hunter = real_body("res://scenes/enemies/drone_hunter.tscn", p1.position + Vector2(0, -21))
	await settle()
	p1.defenses._physics_process(0)
	check(p1.energy == 11, "the visible hunter nose reaching the player core must wound the hull")
	hunter.speedX = 175
	hunter.speedY = 0
	hunter._update_ship_banking(0)
	check(is_equal_approx(hunter.get_node("CollisionShape2D").rotation, hunter.get_node("Sprite2D").rotation), "the hunter collision footprint must follow its visible heading")
	await reset_case()
	enable_contacts()
	equip(p1, SHIELD, 1)
	var body = real_body("res://scenes/enemies/drone.tscn", p1.position)
	var initial_life: float = body.life
	await settle()
	p1.defenses._physics_process(0)
	check(p1.defenses.charges == 0 and p1.energy == 11 and body.life == initial_life, "an enemy hull breaks reflection and damages the player without ram damage")
	await sustained_contacts()
	await hunter_headings()
	await movement_passages()
	await transient_pulse_contacts()
	await callback_defenses()
	await asteroid_contacts()
	await boss_contacts()
	await boss_callback_contacts()
	await build_capacity()
	if DisplayServer.get_name() != "headless": await native_contacts()
	effects.cancel()
	stage.free()
	await settle()
	print("Hull contacts: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func sustained_contacts() -> void:
	await reset_case()
	enable_contacts()
	equip(p1, ARMOR, 3)
	var body = real_body("res://scenes/enemies/drone.tscn", p1.position)
	var life_before: float = body.life
	await settle()
	p1.defenses._physics_process(0)
	check(p1.energy == 11, "ordinary central contact immediately wounds an unshielded player")
	p1.defenses._physics_process(0.9)
	p1._on_touchedReset_timeout()
	check(p1.energy == 11 and p1.touched and p1.malusSpeed == 0, "ordinary grace still prevents an early repeated wound while repair waits")
	body.position.x += 80
	await settle()
	body.position = p1.position
	await settle()
	p1.defenses._physics_process(0.05)
	check(p1.energy == 11, "exiting and reentering cannot bypass ordinary injury grace")
	p1.defenses._physics_process(0.06)
	check(p1.energy == 10 and body.life == life_before and p1.defenses.repair_left == 4, "continued contact wounds after ordinary grace and restarts repair without ram damage")
	paused = true
	p1.defenses._physics_process(8)
	check(p1.energy == 10 and p1.defenses.grace_left == 1 and p1.defenses.repair_left == 4, "pause freezes overlap wounds, grace and repair")
	paused = false
	p1.set_state(p1.State.DYING)
	p1.defenses._physics_process(8)
	check(p1.energy == 10, "death stops body processing")
	await reset_case()
	enable_contacts()
	equip(p1, SHIELD, 1)
	for impact in 3: p1.defenses.take_hit()
	real_body("res://scenes/enemies/drone.tscn", p1.position)
	await settle()
	p1.defenses._physics_process(8)
	check(p1.energy == 11 and p1.defenses.charges == 0, "a returning projectile sphere cannot protect an already overlapping enemy hull")

func hunter_headings() -> void:
	for heading in [0.0, PI / 2, PI, -PI / 2, PI / 4]:
		await reset_case()
		enable_contacts()
		var core: Vector2 = p1.collision_shape.global_position
		var body = real_body("res://scenes/enemies/drone_hunter.tscn", core - Vector2(0, 20).rotated(heading))
		var velocity := Vector2.DOWN.rotated(heading) * 175
		body.speedX = velocity.x
		body.speedY = velocity.y
		body._update_ship_banking(0)
		await settle()
		p1.defenses._physics_process(0)
		check(p1.energy == 11, "a rotated hunter nose touching the player core is dangerous at every heading")
		check(body.get_node("CollisionShape2D").rotation == body.get_node("Sprite2D").rotation, "visible heading and physical contact surface remain aligned")
	await reset_case()
	enable_contacts()
	real_body("res://scenes/enemies/drone_hunter.tscn", p1.position + Vector2(35, 0))
	await settle()
	p1.defenses._physics_process(0)
	check(p1.energy == 12 and p1.collision_shape.shape.size == Vector2(16, 16) and p1.collision_shape.position == Vector2(0, -2), "a genuine near miss remains safe and the forgiving player core is unchanged")

func movement_passages() -> void:
	for path in ["drone.tscn", "drone_hunter.tscn", "interceptor.tscn"]:
		for direction in [Vector2.DOWN, Vector2.RIGHT, Vector2(1, 1)]:
			for speed in [180.0, 240.0]:
				await reset_case()
				enable_contacts()
				var center := Vector2(300, 220)
				var body = real_body("res://scenes/enemies/" + path, center)
				var before: float = body.life
				p1.position = center - direction * 48 + Vector2(0, 2)
				for step in 40:
					p1.position += direction * speed / 60.0
					await physics_frame
					await process_frame
					p1.defenses._physics_process(1.0 / 60.0)
				check(p1.energy < 12 and body.life == before, "front, side and diagonal passages through real hulls wound at authored movement speeds without ram damage")

func transient_pulse_contacts() -> void:
	for mode in ["none", "ready", "cooldown"]:
		await reset_case()
		enable_contacts()
		if mode != "none": equip(p1, RIPOSTE, 1)
		if mode == "cooldown": p1.defenses.pulse_cooldown = 10
		p1.position = Vector2(280, 270)
		p1.monitorable = true
		var body = real_body("res://scenes/enemies/drone_hunter.tscn", Vector2(320, 190))
		body.life = 1000
		body.collision_mask = CombatTargeting.Layers.PLAYER
		var contacts := {"count": 0}
		p1.area_entered.connect(func(area: Area2D):
			if area == body: contacts.count += 1
		)
		var crossing := ContactCrossing.new()
		crossing.player = p1
		crossing.enemy = body
		stage.add_child(crossing)
		stage.move_child(crossing, 2)
		p1.defenses.set_physics_process(true)
		for tick in 24:
			await physics_frame
			await process_frame
		crossing.set_physics_process(false)
		p1.defenses.set_physics_process(false)
		check(contacts.count > 0, "the moving hulls produce a real physics overlap during the grazing crossing")
		if mode == "ready":
			check(p1.energy == 12 and p1.defenses.pulse_cooldown > 0, "a transient enemy overlap triggers the ready pulse even after the hull has moved away")
		else:
			check(p1.energy == 11 and p1.defenses.pulse_protection_left == 0, "a transient enemy overlap wounds once without a ready pulse, including during recharge")

func callback_defenses() -> void:
	await reset_case()
	equip(p1, RIPOSTE, 1)
	var body = real_body("res://scenes/enemies/drone.tscn", p1.position)
	p1.collision_mask = CombatTargeting.Layers.ASTEROID
	body._on_area_entered(p1)
	check(p1.energy == 12 and p1.defenses.pulse_cooldown == 0, "enemy callbacks cannot override a player mask that excludes enemy bodies")
	enable_contacts()
	body._on_area_entered(p1)
	check(p1.energy == 12 and p1.defenses.pulse_cooldown > 0, "an allowed body callback triggers the ready contact countermeasure")
	await reset_case()
	enable_contacts()
	equip(p1, SHIELD, 1)
	equip(p1, RIPOSTE, 1)
	body = real_body("res://scenes/enemies/drone.tscn", p1.position)
	await settle()
	body._on_area_entered(p1)
	p1.defenses._physics_process(0)
	check(p1.energy == 12 and p1.defenses.charges == 0 and p1.defenses.pulse_cooldown > 0, "body callbacks break reflection while retaliation provides the contact protection")
	body._on_area_entered(p1)
	p1.defenses._physics_process(0)
	check(p1.defenses.charges == 0 and p1.energy == 12 and p1.defenses._pulses.size() <= 1, "callback and polling cannot duplicate a body-triggered retaliation")

func asteroid_contacts() -> void:
	await reset_case()
	enable_contacts()
	var asteroid = real_body("res://scenes/enemies/asteroid.tscn", p1.position)
	asteroid.rotation = PI / 3
	await settle()
	p1.defenses._physics_process(0)
	check(p1.energy == 11, "a real rotated asteroid wounds a central hull overlap")
	for path in ["asteroid", "big_asteroid"]:
		for layer in [CombatTargeting.Layers.ENEMY, CombatTargeting.Layers.ASTEROID]:
			await reset_case()
			equip(p1, RIPOSTE, 1)
			var body = real_body("res://scenes/enemies/%s.tscn" % path, p1.position)
			body.collision_layer = layer
			body._on_area_entered(p1)
			check(p1.energy == 12 and p1.defenses.pulse_cooldown == 0, "asteroid callbacks respect a player mask that excludes their layer")
			p1.collision_mask = layer
			body._on_area_entered(p1)
			check(p1.energy == 12 and p1.defenses._pulse_pending and p1.defenses.pulse_cooldown > 0, "small and large asteroid callbacks activate retaliation on either body layer")
			body._on_area_entered(p1)
			check(p1.energy == 12 and p1.defenses.pulse_cooldown == RIPOSTE.recharge_value(1), "duplicate asteroid callbacks cannot restart protection or recharge")

func boss_contacts() -> void:
	await reset_case()
	enable_contacts()
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"contact_boss"
	boss.configure_spawn(context)
	boss.position = p1.position
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	await settle()
	p1.defenses._physics_process(0)
	check(p1.energy == 11, "an unshielded overlap with the real boss wounds once across its logical parts")

func boss_callback_contacts() -> void:
	await reset_case()
	enable_contacts()
	equip(p1, RIPOSTE, 1)
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"callback_boss"
	boss.configure_spawn(context)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	var cannon: Area2D = boss.get_node("PortCannon")
	p1.position = cannon.global_position
	cannon.destroyed = true
	cannon.area_entered.emit(p1)
	check(p1.energy == 12 and p1.defenses.pulse_cooldown == 0, "a queued callback from a broken boss part cannot become a live boss hull contact")
	cannon.destroyed = false
	cannon.area_entered.emit(p1)
	check(p1.energy == 12 and p1.defenses.pulse_cooldown > 0, "a live boss part forwards its actual surface to the contact countermeasure")

func native_contacts() -> void:
	await reset_case()
	enable_contacts()
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(640, 400)
	RenderingServer.set_default_clear_color(Color("101522"))
	var body = real_body("res://scenes/enemies/drone_hunter.tscn", p1.position + Vector2(0, -42))
	body.speedX = 0
	body.speedY = 175
	body._chase_committed = true
	body._chase_exit_y = INF
	var health := Label.new()
	health.position = Vector2(140, 120)
	stage.add_child(health)
	for step in 30:
		body._physics_process(1.0 / 60)
		await physics_frame
		await process_frame
		p1.defenses._physics_process(1.0 / 60.0)
		health.text = "CORE CONTACT: ENERGY %d / 12" % p1.energy
		if step in [0, 8, 12, 16, 24]:
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://contact_native_%02d.webp" % step), true) == OK, "native contact evidence saves with visible hulls and actual energy")
	check(p1.energy == 11, "a native moving hunter visibly wounds the hull once during its crossing")

func build_capacity() -> void:
	await reset_case()
	for id in [&"critical_hits", &"energy_chains", &"impact_explosions"]:
		check(p1.apply_upgrade(load("res://data/upgrades/%s.tres" % id)).applied, "criticals, chains and explosions each occupy one offensive family")
	for id in [&"micro_missiles", &"escort_drone", &"orbiting_satellites"]:
		check(p2.apply_upgrade(load("res://data/upgrades/%s.tres" % id)).applied, "the co-op partner independently acquires three different offensive families")
	p1.increase_SideShot()
	p1.debug_max_stats()
	check(not p1.loadout.side_shot and p1.loadout.foundation_snapshot().offensive_count == 3 and p1.loadout.foundation_snapshot().utility_count == 3, "debug side shots and maximum cannot add a fourth offensive or extra utilities")
	check(p2.loadout.foundation_snapshot().offensive_count == 3 and not p2.apply_upgrade(load("res://data/upgrades/critical_hits.tres")).applied, "a full co-op build rejects a fourth offensive independently")
	check(p1.apply_upgrade(load("res://data/upgrades/critical_hits.tres")).rank == 2 and p2.apply_upgrade(load("res://data/upgrades/micro_missiles.tres")).rank == 2, "both owners can rank acquired families at full capacity")
	p1._update_beam(0.01, true)
	check(p1.beam_active and p1.continuous_beam.overdrive and p1.loadout.foundation_snapshot().offensive_count == 3, "the full-reserve signature remains available outside the three offensive slots")

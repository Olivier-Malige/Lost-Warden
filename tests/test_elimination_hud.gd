extends SceneTree

var checks := 0
var failures := 0
var world: Node2D
var globals: Node
var events: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func actor(kind: String, id: StringName, at: Vector2) -> Variant:
	var target = load("res://scenes/enemies/%s.tscn" % kind).instantiate()
	target.definition = target.definition.duplicate()
	target.definition.max_health = 20.0
	target.definition.xp_drop_chance = 0
	target.definition.plasma_drop_chance = 0
	target.definition.drops_on_destroy = false
	var context := EnemySpawnContext.new()
	context.combat_id = id
	target.configure_spawn(context)
	target.position = at
	world.add_child(target)
	target.set_physics_process(false)
	for timer in target.find_children("*", "Timer", true, false): timer.stop()
	for sound in target.find_children("*", "AudioStreamPlayer2D", true, false): sound.stream = null
	return target

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = true
	root.size = Vector2i(640, 400)
	world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	world.get_node("waveGenerator").stop_run()
	for player in world.progression.players: player.set_physics_process(false)
	var hud := world.get_node("hud")
	var counter: Label = hud.get_node("LeftColumn/Eliminations")
	check(globals.eliminations == 0 and counter.text == "ELIMINATIONS\n0", "new runs start with a zero elimination counter")
	check(not hud.has_node("LeftColumn/score") and not hud.has_node("LeftColumn/combo"), "score and combo labels must be absent from the gameplay HUD")
	var first = actor("drone", &"counted_p1", Vector2(230, 150))
	check(first.receive_player_hit(1.0, &"player1") and globals.eliminations == 0, "damage without a kill must not increment the counter")
	check(first.receive_player_hit(30.0, &"player1") and globals.eliminations == 1 and counter.text == "ELIMINATIONS\n1", "a player-owned enemy kill updates the HUD once")
	check(not first.receive_player_hit(30.0, &"player2") and globals.eliminations == 1, "duplicate contacts on a dead target cannot count again")
	var second = actor("drone", &"counted_p2", Vector2(440, 150))
	check(second.receive_player_hit(30.0, &"player2") and globals.eliminations == 2 and counter.text == "ELIMINATIONS\n2", "P2 kills contribute to the same co-op counter")
	var asteroid = actor("asteroid", &"uncounted_asteroid", Vector2(270, 100))
	check(asteroid.receive_player_hit(30.0, &"player1") and globals.eliminations == 2, "destroyed asteroids are not enemy eliminations")
	var uncredited = actor("drone", &"uncounted_cleanup", Vector2(360, 100))
	uncredited._hit_something(30.0, false)
	check(globals.eliminations == 2, "uncredited collision or cleanup deaths cannot count as player eliminations")
	var score_before: int = globals.score
	globals.add_score(500)
	check(globals.score == score_before + 500 and globals.eliminations == 2 and counter.text == "ELIMINATIONS\n2", "salvage changes internal score without changing the elimination HUD")
	events.score_popup_requested.emit(100, 12, 2.0, Vector2(320, 150))
	await process_frame
	await process_frame
	check(get_nodes_in_group("score_popup").is_empty(), "legacy popup events must no longer display points or combo multipliers")
	for target in [first, second, asteroid, uncredited]: target.free()
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"counter_boss"
	boss.configure_spawn(context)
	boss.position = Vector2(320, 90)
	world.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	for sound in boss.find_children("*", "AudioStreamPlayer2D", true, false): sound.stream = null
	var packet = world.hit_effects.create_hit(&"player1", 1, 1, {}, PlayerHitSnapshot.Kind.GUN, 1.0)
	check(world.hit_effects.resolve_hit(packet, boss.get_node("PortCannon")), "a critical cannon impact must be accepted")
	world.hit_effects.release_root(packet)
	boss._cannon_flash_tweens[0].custom_step(0.06)
	check(boss.get_node("Sprite2D").get_instance_shader_parameter(&"port_hit_flash") == 1.0, "critical feedback must hold the struck cannon flash longer than a normal hit")
	boss.get_node("PortCannon").receive_player_hit(1000.0, &"player1")
	check(globals.eliminations == 2, "optional boss parts do not count as separate enemy eliminations")
	boss.receive_player_hit(10000.0, &"player1")
	check(globals.eliminations == 3 and counter.text == "ELIMINATIONS\n3", "the defeated boss counts once through its authoritative kill path")
	check(not boss.receive_player_hit(10000.0, &"player2") and globals.eliminations == 3, "a repeated boss kill cannot increment the counter")
	boss.free()
	var target = actor("drone", &"critical_flash", Vector2(300, 190))
	var ordinary = actor("drone", &"ordinary_flash", Vector2(400, 190))
	ordinary.receive_player_hit(2.0, &"player2", false)
	ordinary._hit_flash_tween.custom_step(0.06)
	packet = world.hit_effects.create_hit(&"player1", 1, 1, {}, PlayerHitSnapshot.Kind.GUN, 1.0)
	check(world.hit_effects.resolve_hit(packet, target), "critical enemy feedback follows a real accepted player hit")
	world.hit_effects.release_root(packet)
	target._hit_flash_tween.custom_step(0.06)
	check(target._hit_sprite.get_instance_shader_parameter(&"hit_flash") == 1.0 and ordinary._hit_sprite.get_instance_shader_parameter(&"hit_flash") < 1.0, "critical flashes remain fully lit after ordinary flashes begin fading")
	var impact = get_nodes_in_group(&"critical_impact").back()
	check(impact.texture.get_size() == Vector2(144, 48) and is_equal_approx(impact.FRAME_COUNT * impact.FRAME_SECONDS, 0.30), "critical art uses native 24px cells and a bounded 300ms sequence")
	check(hud._xp_bar != null and not hud._xp_bar.show_percentage and hud._level_label.text == "LEVEL 1", "level and its nonnumeric progress bar remain visible")
	if DisplayServer.get_name() != "headless":
		world.get_node("CombatFeedback")._shake_time = 0.0
		await process_frame
		paused = true
		for index in [0, 1, 3, 5]:
			for effect in get_nodes_in_group(&"critical_impact"): effect.free()
			for owner in [&"player1", &"player2"]:
				var effect = load("res://scenes/effects/critical_impact.gd").spawn(world, Vector2(300 if owner == &"player1" else 400, 180), owner)
				effect.frame = effect.team * 6 + index
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://critical_hud_%d.webp" % index), true) == OK, "native HUD and effect evidence must save")
		paused = false
	globals.reset_run(13)
	check(globals.eliminations == 0 and counter.text == "ELIMINATIONS\n0", "restart resets the counter through Events")
	world.free()
	await process_frame
	check(get_nodes_in_group(&"critical_impact").is_empty() and get_nodes_in_group("score_popup").is_empty(), "world teardown leaves no feedback objects")
	print("Elimination HUD and critical feedback: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

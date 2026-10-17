extends SceneTree

class Target:
	extends Node2D
	var state := 0

var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _freeze(enemy: Variant) -> void:
	enemy.set_physics_process(false)
	enemy.set_deferred("monitoring", false)
	enemy.set_deferred("monitorable", false)
	for sound in enemy.find_children("*", "AudioStreamPlayer2D", true, false):
		sound.stream = null

func _palette_counts(texture: Texture2D) -> Vector2i:
	var image := texture.get_image()
	var counts := Vector2i.ZERO
	for y in 32:
		for x in 32:
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			if pixel.r > 0.15 and pixel.r > pixel.g * 1.3 and pixel.b > pixel.g * 1.3:
				counts.x += 1
			if pixel.r > 0.5 and pixel.g > 0.29 and pixel.b < pixel.g * 0.65:
				counts.y += 1
	return counts

func _test_catalog() -> void:
	var catalog = load("res://data/waves/wave_catalog.tres")
	var spawner = load("res://scenes/waves/wave_spawner.gd").new()
	var mixed := 0
	for wave in catalog.waves:
		_check(wave.is_encounter_valid(), "every encounter remains valid after adding hunters")
		var hunters: Array = wave.rules.filter(func(rule): return rule.scene.resource_path.ends_with("drone_hunter.tscn"))
		if hunters.is_empty():
			continue
		mixed += 1
		var hunter = hunters[0]
		var originals: Array = wave.rules.filter(func(rule): return rule.scene.resource_path.ends_with("/drone.tscn") and rule.pattern == hunter.pattern and rule.interval == hunter.interval and rule.formation == hunter.formation)
		_check(originals.size() == 1 and is_equal_approx(originals[0].weight + hunter.weight, 1.0), "hunters split an existing drone group's selection weight")
		_check(hunter.movement_profile_override.mode == MovementProfile.Mode.CHASE and hunter.movement_profile_override.chase_commit_distance == 64.0, "authored hunters use the shared early-commit pursuit profile")
		_check(spawner._rule_definition(hunter) == load("res://data/enemies/drone.tres"), "hunter scenes resolve the original drone family and threat costs")
	_check(mixed == 6 and catalog.waves.size() == 18, "six existing encounters mix hunters with formation drones without adding encounters")
	spawner.free()

func _test_approach_and_art() -> void:
	var target := Target.new()
	target.position = Vector2(360, 300)
	target.add_to_group("player")
	root.add_child(target)
	var hunter = load("res://scenes/enemies/drone_hunter.tscn").instantiate()
	hunter.position = Vector2(280, 160)
	root.add_child(hunter)
	_freeze(hunter)
	hunter._update_movement(0.1)
	_check(hunter.speedX > 0.0 and not hunter._chase_committed, "a distant hunter steers toward the player's current position")
	hunter.position.y = 240.0
	var velocity := Vector2(hunter.speedX, hunter.speedY)
	hunter._update_movement(0.1)
	_check(hunter._chase_committed and hunter.position.y < target.position.y, "the hunter locks its attack before passing the player's height")
	_check(Vector2(hunter.speedX, hunter.speedY) == velocity, "committing preserves the current velocity instead of snapping to a new direction")
	target.position = Vector2(120, 200)
	var before: Vector2 = hunter.position
	hunter._update_movement(0.5)
	_check(hunter.position.is_equal_approx(before + velocity * 0.5) and hunter.speedY > 0.0, "the final approach stays straight when the player dodges behind the drone")
	hunter.position.x = 525.0
	hunter._update_movement(0.5)
	_check(hunter.position.x > 525.0 and Vector2(hunter.speedX, hunter.speedY) == velocity, "a committed hunter exits naturally rather than bouncing at horizontal bounds")
	var normal = load("res://scenes/enemies/drone.tscn").instantiate()
	root.add_child(normal)
	_freeze(normal)
	_check(normal._movement_profile.mode == MovementProfile.Mode.SINE, "ordinary drones retain their coordinated formation movement")
	_check(hunter.get_node("Sprite2D").texture != normal.get_node("Sprite2D").texture, "hunters have a distinct magenta texture")
	_check(_palette_counts(hunter.get_node("Sprite2D").texture).x > 100, "the imported hunter hull stays visibly magenta rather than losing its palette")
	_check(hunter.definition == normal.definition and hunter.max_life == normal.max_life, "hunter identity changes preserve shared family health and rewards")
	var elite = load("res://scenes/enemies/drone_hunter.tscn").instantiate()
	var context := EnemySpawnContext.new()
	context.elite = true
	context.elite_definition = load("res://data/enemies/elite_definition.tres")
	elite.configure_spawn(context)
	root.add_child(elite)
	_freeze(elite)
	var sprite = elite.get_node("Sprite2D")
	_check(sprite.texture == elite.ELITE_TEXTURE and sprite.hframes == 8 and sprite.vframes == 4, "elite hunters retain gold markings with their own compatible animation sheet")
	var palette := _palette_counts(sprite.texture)
	_check(palette.x > 100 and palette.y >= 8, "the elite hunter combines visible magenta hull pixels and preserved gold markings")
	_check(not elite.get_node("EliteIndicator").visible and elite._movement_profile.mode == MovementProfile.Mode.CHASE, "elite hunters keep their pursuit behavior without an overhead health bar")
	var profile = hunter.CHASE.duplicate()
	profile.chase_commit_distance = -1.0
	_check(not profile.is_valid(), "pursuit profiles reject negative commitment distances")
	for node in [hunter, normal, elite, target]:
		node.free()

func _trace(coop: bool, noise: bool) -> Array[String]:
	var globals = root.get_node("global")
	globals.coop = coop
	globals.reset_run(42)
	var spawner = load("res://scenes/waves/wave_spawner.gd").new()
	spawner.config = load("res://data/waves/wave_spawner_config.tres").duplicate()
	spawner.config.bosses = spawner.config.bosses.duplicate()
	spawner.config.bosses.clear()
	var wave = load("res://data/waves/wave_00.tres").duplicate()
	wave.rules = wave.rules.filter(func(rule): return rule.scene.resource_path.contains("drone"))
	spawner.catalog = WaveCatalog.new()
	spawner.catalog.waves.append(wave)
	for index in 12:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % index
		marker.position = Vector2(116 + index * 37, -28)
		spawner.add_child(marker)
	root.add_child(spawner)
	spawner.start_run()
	spawner.set_physics_process(false)
	var result: Array[String] = []
	spawner.enemy_spawned.connect(func(enemy):
		_freeze(enemy)
		result.append("%s|%s|%s|%s" % [enemy.scene_file_path, enemy.position, enemy._movement_profile.id, enemy._spawn_context.movement_seed])
	)
	for tick in 180:
		if noise:
			randf()
			globals.run_random.drops.randi()
		spawner._physics_process(0.25)
		_check(spawner._budget_left >= 0.0 and spawner._active_enemy_count() <= spawner._enemy_cap(), "mixed drone spawning respects threat budgets and solo/co-op body caps")
		await process_frame
	_check(result.any(func(entry): return entry.contains("drone_hunter.tscn")) and result.any(func(entry): return entry.contains("/drone.tscn")), "the regular spawner materializes both hunters and formation drones")
	spawner.stop_run()
	spawner.free()
	await process_frame
	return result

func _run() -> void:
	_test_catalog()
	_test_approach_and_art()
	var trace := await _trace(false, false)
	_check(trace == await _trace(false, true), "mixed-role spawn traces remain seeded and independent of cosmetic/drop randomness")
	await _trace(true, false)
	var boss = load("res://data/bosses/dread_ark.tres")
	_check(boss.reinforcements[0].scene.resource_path.ends_with("drone_hunter.tscn"), "boss reinforcements use the same recognizable hunter appearance")
	print("Drone hunters: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)

extends SceneTree

var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)

func _check_sprites(node: Node, path: String) -> void:
	if node is Sprite2D:
		_check(node.scale == Vector2.ONE, path + ": " + node.name + " must use native pixels")
	for child in node.get_children():
		_check_sprites(child, path)

func _run() -> void:
	_check(ProjectSettings.get_setting("display/window/size/viewport_width") == 640, "native width")
	_check(ProjectSettings.get_setting("display/window/size/viewport_height") == 400, "native height")
	_check(ProjectSettings.get_setting("display/window/stretch/scale_mode") == "fractional", "display must fit the available screen space")
	_check(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep", "display must preserve sprite proportions")
	for directory in ["player", "enemies", "combat", "world", "ui", "menu", "main"]:
		for file in DirAccess.get_files_at("res://scenes/" + directory):
			if not file.ends_with(".tscn"):
				continue
			var path: String = "res://scenes/" + directory + "/" + file
			var scene = load(path).instantiate()
			_check_sprites(scene, path)
			scene.free()
	var stats = load("res://data/player/player_stats.tres")
	var small = load("res://scenes/enemies/asteroid.tscn").instantiate()
	var large = load("res://scenes/enemies/big_asteroid.tscn").instantiate()
	_check(small.scale == Vector2.ONE, "small asteroids must retain their native footprint")
	_check(large.scale == Vector2(2, 2), "large asteroids must visibly differ at an integer scale")
	var large_sprite: Sprite2D = large.get_node("SpriteAsteroid")
	var large_width: float = large_sprite.texture.get_width() / float(large_sprite.hframes) * large.scale.x
	_check(large_width == 64.0, "large asteroid frames must occupy 64 world pixels")
	_check(large.get_node("CollisionShape2D").shape.radius * large.scale.x == 26.0, "large asteroid collision must grow with its sprite")
	var fragment = large.definition.drop_scene.instantiate()
	_check(fragment.scale == small.scale, "detached fragments must retain the small asteroid footprint")
	fragment.free()
	large.free()
	small.free()
	var world = load("res://scenes/world/world.tscn").instantiate()
	_check(world.get_node("CombatFeedback").position == Vector2(320, 200), "camera must center the native viewport")
	_check(world.get_node("CombatFeedback").zoom == Vector2.ONE, "camera must not zoom sprites")
	_check(world.get_node("hud/LeftColumn").offset_right == 104, "left HUD must have room for readable labels")
	_check(world.get_node("hud/RightColumn").offset_left == 536, "right HUD must leave the combat area clear")
	for lane in range(12):
		var marker = world.get_node("waveGenerator/spawnPos" + str(lane))
		_check(marker.position.x > 104 and marker.position.x < 536, "spawn lanes must stay between HUD panels")
	world.free()
	_check(stats.bound_min == Vector2(112.5, 12) and stats.bound_max == Vector2(527.5, 392), "player must remain inside the new playfield")
	_check(is_equal_approx(stats.speed / 400.0, 360.0 / 800.0), "relative travel speed must be preserved")
	_check(stats.beam_width == 8.0 and stats.beam_overdrive_width == 16.0, "beam texels must match sprite pixels")
	for file in DirAccess.get_files_at("res://data/enemies/movement"):
		if not file.ends_with(".tres"):
			continue
		var profile = load("res://data/enemies/movement/" + file)
		_check(profile.is_valid(), file + ": movement profile must remain valid")
		_check(profile.max_x <= 640.0, file + ": movement bounds must fit native width")
	for name in ["background_native", "background_2_native"]:
		var texture = load("res://assets/sprites/world/" + name + ".png")
		_check(texture.get_size() == Vector2(600, 450), "background must match native parallax repeat")
	print("Native scale: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)

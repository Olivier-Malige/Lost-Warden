extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func sprite_bounds(sprite: Sprite2D) -> Rect2:
	var frame_size := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
	var origin := Vector2(sprite.frame % sprite.hframes, int(float(sprite.frame) / sprite.hframes)) * frame_size
	var pixels := sprite.texture.get_image().get_region(Rect2i(origin, frame_size)).get_used_rect()
	if sprite.flip_h:
		pixels.position.x = int(frame_size.x) - pixels.end.x
	if sprite.flip_v:
		pixels.position.y = int(frame_size.y) - pixels.end.y
	return Rect2(sprite.position + sprite.offset - frame_size * 0.5 + Vector2(pixels.position), Vector2(pixels.size))

func run() -> void:
	var foundation_only := "--foundation-only" in OS.get_cmdline_user_args()
	var world := Node2D.new()
	root.add_child(world)
	for folder in ["enemies", "combat", "ui"]:
		for file in DirAccess.get_files_at("res://scenes/" + folder):
			if foundation_only and (folder != "ui" or file != "plasma_cell.tscn"):
				continue
			if not file.ends_with(".tscn"):
				continue
			var instance = load("res://scenes/" + folder + "/" + file).instantiate()
			var collider = instance.get_node_or_null("CollisionShape2D")
			if collider != null and collider.shape != null:
				var sprites = instance.find_children("*", "Sprite2D", true, false)
				check(not sprites.is_empty(), file + ": collision must have a visible counterpart")
				if not sprites.is_empty():
					var sprite: Sprite2D = sprites[0]
					var frames: Array[int] = []
					for animation_player in instance.find_children("*", "AnimationPlayer", true, false):
						for animation_name in animation_player.get_animation_list():
							if "explode" in animation_name.to_lower() or animation_name == "RESET":
								continue
							var animation: Animation = animation_player.get_animation(animation_name)
							for track in animation.get_track_count():
								if str(animation.track_get_path(track)) != str(instance.get_path_to(sprite)) + ":frame":
									continue
								for key in animation.track_get_key_count(track):
									var frame: int = animation.track_get_key_value(track, key)
									if not frames.has(frame):
										frames.append(frame)
					if frames.is_empty():
						frames.append(sprite.frame)
					for frame in frames:
						sprite.frame = frame
						var bounds := sprite_bounds(sprite)
						var collision_bounds: Rect2 = collider.shape.get_rect()
						collision_bounds.position += collider.position
						check(collider.scale == Vector2.ONE, file + ": collider must use native units")
						check(bounds.grow(0.01).encloses(collision_bounds), file + ": collision must stay within visible bounds")
						check(collision_bounds.size.x >= bounds.size.x * 0.7 and collision_bounds.size.y >= bounds.size.y * 0.7, file + ": collision must cover the main body")
			instance.free()
	for name in ["player_shot", "player_side_shot"]:
		var scene = load("res://scenes/player/" + name + ".tscn")
		var first = scene.instantiate()
		var second = scene.instantiate()
		world.add_child(first)
		world.add_child(second)
		first.set_physics_process(false)
		second.set_physics_process(false)
		var shape = first.get_node("CollisionShape2D")
		var sprite = first.get_node("sprite" if name == "player_shot" else "Sprite2D")
		var other_shape = second.get_node("CollisionShape2D").shape
		var other_size: Vector2 = other_shape.size
		check(shape.shape != other_shape, name + ": collider resources must be per-instance")
		for team in ["player1", "player2"]:
			first.player_Id = team
			for damage in [first.power_Small, first.power_Normal, first.power_Big, first.power_Large, first.power_Full]:
				first.damage = damage
				first.setPowerAnim()
				var bounds := sprite_bounds(sprite)
				check(shape.scale == Vector2.ONE, name + ": collider must use native units")
				check(shape.position.is_equal_approx(bounds.get_center()), name + ": collider must center on visible pixels")
				check(shape.shape.size.is_equal_approx(bounds.size), name + ": collider must match visible tier dimensions")
				check(other_shape.size == other_size, name + ": changing one tier must not resize another shot")
	var player = load("res://scenes/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	var shield = player.shield
	player.defenses.set_physics_process(false)
	check(not shield.visible and player.defenses.charges == 0, "an unacquired shield has no active protection")
	for rank in range(1, 4):
		player.apply_upgrade(load("res://data/upgrades/foundation/shield.tres"))
		shield.advance(0.13)
		var bounds := sprite_bounds(shield.get_node("Sprite2D"))
		check(shield.position == Vector2.ZERO and shield.scale == Vector2.ONE, "the native sphere remains centered on the player")
		check(player.defenses._circle.radius == 20 and bounds.size.x >= 39 and bounds.size.y >= 39, "the visible sphere agrees with the fixed protection radius at every rank")
		player.defenses.take_hit()
		check(player.defenses._circle.radius == 20, "contact feedback never changes the protection geometry")
	while player.defenses.charges > 0: player.defenses.take_hit()
	shield.advance(0.13)
	check(not shield.visible and not player.defenses.active(), "depletion leaves no invisible active protection")
	player.weapons.player = null
	player.vitals.player = null
	world.queue_free()
	await process_frame
	print("Collision alignment: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var background = load("res://scenes/world/background.tscn").instantiate()
	root.add_child(background)
	check(is_zero_approx(background.speed_Y), "loader background must start stationary")
	var repeat_width := ceilf(root.get_visible_rect().size.x / 640.0) * 640.0
	for layer_name in ["b3", "b2", "b1"]:
		var layer: ParallaxLayer = background.get_node(layer_name)
		var sprite: Sprite2D = layer.get_child(0)
		check(sprite.texture.get_size() == Vector2(640, 450), layer_name + ": texture must use the native 640 by 450 canvas")
		check(sprite.scale == Vector2.ONE, layer_name + ": texture must retain native pixel scale")
		check(layer.motion_mirroring == Vector2(repeat_width, 450), layer_name + ": repeat distance must cover the viewport with complete texture tiles")
		check(sprite.modulate == Color.WHITE and layer.modulate == Color.WHITE, layer_name + ": authored alpha must not be attenuated by a historical tint")
	check(background.get_node("b1/stars").material is ShaderMaterial, "near debris must use the opaque-object material")
	check(background.get_node("PlanetsLayer/Planets").material is ShaderMaterial, "mid planets must have an independent opaque pass")
	var far_stars: Sprite2D = background.get_node("b3/stars")
	var mid_cloud: Sprite2D = background.get_node("b2/stars2")
	var near_stars: Sprite2D = background.get_node("b1/StarPoints")
	var planets: Sprite2D = background.get_node("PlanetsLayer/Planets")
	var debris: Sprite2D = background.get_node("b1/stars")
	var planets_layer: ParallaxLayer = background.get_node("PlanetsLayer")
	check(planets_layer.motion_scale.y < background.get_node("b2").motion_scale.y and planets_layer.motion_scale.y > background.get_node("b3").motion_scale.y, "planets must drift more slowly than the mid clouds")
	check(planets_layer.motion_mirroring == Vector2(repeat_width, 450), "planet layer must repeat with complete texture tiles across the viewport")
	check(far_stars.z_index < mid_cloud.z_index and mid_cloud.z_index < near_stars.z_index and near_stars.z_index < planets.z_index and planets.z_index < debris.z_index, "stars must draw behind planets and debris")
	check(not far_stars.z_as_relative and not mid_cloud.z_as_relative and not near_stars.z_as_relative and not planets.z_as_relative and not debris.z_as_relative, "background draw order must be independent of parallax layer order")
	check((near_stars.material as ShaderMaterial).get_shader_parameter("draw_mode") == 3 and (debris.material as ShaderMaterial).get_shader_parameter("draw_mode") == 4, "near stars and debris must use separate opaque passes")
	check(background.get_node("b3/stars").texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "gameplay background must keep sharp native sampling")
	background._process(0.1)
	check(is_equal_approx(background.speed_Y, 6.5), "background speed must retain the existing smooth ramp")
	background._on_player_motion_changed("player1", 1.0)
	background._process(1.0)
	check(is_equal_approx(background.speed_Y, 50.0), "forward player intent must retain maximum scroll speed")
	background._on_player_motion_changed("player2", -1.0)
	background._process(1.0)
	check(is_equal_approx(background.speed_Y, 40.0), "co-op intent must average both players before scrolling")
	background._on_player_motion_changed("player2", 1.0)
	background._process(1.0)
	var offset_before_cycles: float = background.scroll_base_offset.y
	background._process(54.0)
	var far_layer: ParallaxLayer = background.get_node("b3")
	var far_distance: float = (background.scroll_base_offset.y - offset_before_cycles) * far_layer.motion_scale.y
	check(is_equal_approx(far_distance, 1350.0), "far layer must traverse three complete 450-pixel repeats at maximum speed")
	background.queue_free()
	var game_over = load("res://scenes/menu/game_over.tscn").instantiate()
	var game_over_background: ParallaxBackground = game_over.get_node("background")
	check(game_over_background.lock_scroll_speed and is_zero_approx(game_over_background.speed_Y), "game over background must remain stationary")
	var game_over_offset: Vector2 = game_over_background.scroll_base_offset
	game_over_background._process(1.0)
	check(game_over_background.scroll_base_offset == game_over_offset, "game over background must not scroll between frames")
	check(game_over_background.scale == Vector2.ONE, "game over background must retain its native scale")
	game_over.free()

	var themed_background = load("res://scenes/world/background.tscn").instantiate()
	themed_background.wave_theme_enabled = true
	root.add_child(themed_background)
	check(themed_background.get_node("b3/stars").texture.resource_path.ends_with("gameplay_background/far.png"), "waves 1 to 6 must retain the frozen graveyard")
	themed_background._on_wave_changed(7)
	check(themed_background.get_node("b3/Incoming").texture.resource_path.ends_with("gameplay_background/violet_orbit/far.png"), "wave 7 must begin a violet orbit transition")
	check(themed_background.get_node("PlanetsLayer/Planets").texture.resource_path.ends_with("gameplay_background/violet_orbit/mid.png"), "planet silhouettes must keep their separate pass during theme transitions")
	check(themed_background.get_node("b1/stars").texture.resource_path.ends_with("gameplay_background/violet_orbit/near.png"), "near debris must follow theme transitions")
	check(themed_background.get_node("b1/StarPoints").texture.resource_path.ends_with("gameplay_background/violet_orbit/near.png"), "near stars must follow theme transitions")
	themed_background._process(4.0)
	check(themed_background.get_node("b3/stars").modulate.a > 0.0 and themed_background.get_node("b3/Incoming").modulate.a > 0.0, "theme transition must blend both backgrounds")
	themed_background._process(4.0)
	check(themed_background.get_node("b3/stars").texture.resource_path.ends_with("gameplay_background/violet_orbit/far.png"), "waves 7 to 12 must use the violet orbit")
	themed_background._on_wave_changed(13)
	themed_background._process(8.0)
	check(themed_background.get_node("b3/stars").texture.resource_path.ends_with("gameplay_background/red_rift/far.png"), "wave 13 onward must use the red rift")
	themed_background.queue_free()
	await process_frame
	var wide_viewport := SubViewport.new()
	wide_viewport.size = Vector2i(960, 400)
	root.add_child(wide_viewport)
	var wide_background = load("res://scenes/world/background.tscn").instantiate()
	wide_viewport.add_child(wide_background)
	wide_background.set_process(false)
	for width in [960, 640, 1424, 960]:
		wide_viewport.size.x = width
		await process_frame
		var expected_width := ceilf(width / 640.0) * 640.0
		for layer in wide_background.get_children():
			check(layer.motion_mirroring == Vector2(expected_width, 450), "%s: resizing to %d must update the repeat interval" % [layer.name, width])
			for sprite in layer.get_children():
				check(sprite.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED, sprite.name + ": horizontal regions must repeat rather than stretch the texture")
				check(sprite.region_enabled and sprite.region_rect == Rect2(0, 0, expected_width, 450), sprite.name + ": the repeated region must cover the resized viewport")
	wide_viewport.queue_free()
	await process_frame
	print("Background: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

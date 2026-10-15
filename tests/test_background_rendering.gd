extends SceneTree

const BACKGROUND_SHADER := preload("res://scenes/world/background_opaque_objects.gdshader")

var _failures := 0
var _checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _render(texture: Texture2D, draw_mode: int, horizontal_blend_width := 0.0) -> Image:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(texture.get_size())
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	material.shader = BACKGROUND_SHADER
	material.set_shader_parameter("draw_mode", draw_mode)
	if horizontal_blend_width > 0.0:
		material.set_shader_parameter("horizontal_blend_width", horizontal_blend_width)
	sprite.material = material
	viewport.add_child(sprite)
	root.add_child(viewport)
	await RenderingServer.frame_post_draw
	var rendered := viewport.get_texture().get_image()
	viewport.queue_free()
	await process_frame
	return rendered

func _check_shader_alpha() -> void:
	var source := Image.create(7, 1, false, Image.FORMAT_RGBA8)
	var colors := [
		Color(0.88, 0.35, 0.26, 0.02),
		Color(0.88, 0.35, 0.26, 0.3),
		Color(0.8, 0.8, 0.8, 0.02),
		Color(0.8, 0.8, 0.8, 0.74),
		Color(0.85, 0.6, 0.2, 0.58),
		Color(0.05, 0.06, 0.08, 0.01),
		Color(0.05, 0.06, 0.08, 0.72),
	]
	for index in colors.size():
		source.set_pixel(index, 0, colors[index])
	var texture := ImageTexture.create_from_image(source)
	for mode in [1, 5]:
		var rendered := await _render(texture, mode)
		for index in [0, 1, 2]:
			_check(absf(rendered.get_pixel(index, 0).a - source.get_pixel(index, 0).a * 0.68) < 0.015, "cloud pass %d must retain authored transparency at pixel %d" % [mode, index])
		for index in [3, 4]:
			_check(rendered.get_pixel(index, 0).a > 0.98, "cloud pass %d must keep real stars visible" % mode)
	var stars := await _render(texture, 3)
	for index in [0, 1, 2, 5]:
		_check(stars.get_pixel(index, 0).a < 0.01, "star pass must not turn cloud or edge pixel %d into a bright speck" % index)
	var debris := await _render(texture, 4)
	for index in [5, 6]:
		_check(absf(debris.get_pixel(index, 0).a - source.get_pixel(index, 0).a * 0.78) < 0.015, "debris pass must retain authored edge coverage at pixel %d" % index)
	var red_mid := await _render(load("res://assets/sprites/world/gameplay_background/red_rift/mid.png"), 1)
	_check(red_mid.get_pixel(46, 5).a < 0.03, "Red Rift's faint cloud edge must not become opaque")
	var red_near := await _render(load("res://assets/sprites/world/gameplay_background/red_rift/near.png"), 4)
	_check(red_near.get_pixel(30, 36).a < 0.02, "Red Rift's faint debris edge must not become a dark blotch")

func _capture_themes() -> void:
	root.get_node("global").wave = 1
	var background = load("res://scenes/world/background.tscn").instantiate()
	background.wave_theme_enabled = true
	root.add_child(background)
	background.set_process(false)
	for wave in [1, 7, 13, 19, 27]:
		background._on_wave_changed(wave)
		background._process(8.0)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_webp("res://.godot/background_wave_%d.webp" % wave)
	background.queue_free()
	await process_frame

func _check_nebula_seam() -> void:
	var source := Image.create(128, 16, false, Image.FORMAT_RGBA8)
	source.fill(Color(0.88, 0.35, 0.26, 0.25))
	source.fill_rect(Rect2i(64, 0, 64, 16), Color(0.2, 0.3, 0.8, 0.08))
	var texture := ImageTexture.create_from_image(source)
	for mode in [1, 5]:
		var original := await _render(texture, mode)
		var blended := await _render(texture, mode, 32.0)
		var left := blended.get_pixel(0, 8)
		var right := blended.get_pixel(127, 8)
		_check(absf(left.a - right.a) < 0.01, "nebula pass %d must join mismatched edge opacity" % mode)
		_check(absf(left.r - right.r) < 0.01 and absf(left.b - right.b) < 0.01, "nebula pass %d must join mismatched edge colors" % mode)
		_check(left.a > 0.04 and right.a > 0.04, "nebula pass %d must retain cloud matter across the seam" % mode)
		for x in [40, 87]:
			_check(blended.get_pixel(x, 8).is_equal_approx(original.get_pixel(x, 8)), "nebula seam blending must preserve interior pixel %d" % x)
	source.set_pixel(0, 8, Color(0.8, 0.8, 0.8, 0.74))
	texture.update(source)
	var stars := await _render(texture, 1, 32.0)
	_check(stars.get_pixel(0, 8).a > 0.98, "seam blending must preserve stars at the edge")
	source.set_pixel(0, 8, Color(0.05, 0.06, 0.08, 0.72))
	texture.update(source)
	for mode in [2, 4]:
		var original := await _render(texture, mode)
		var blended := await _render(texture, mode, 32.0)
		_check(blended.get_pixel(0, 8).is_equal_approx(original.get_pixel(0, 8)), "seam blending must not change planet or debris pass %d" % mode)

func _check_background_repeat() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 400)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background = load("res://scenes/world/background.tscn").instantiate()
	viewport.add_child(background)
	background.set_process(false)
	var camera := Camera2D.new()
	viewport.add_child(camera)
	var reference := SubViewport.new()
	reference.size = viewport.size
	reference.transparent_bg = true
	reference.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(reference)
	for wave in [1, 7, 13]:
		background._on_wave_changed(wave)
		background._process(8.0)
		for width in [640, 960, 1424]:
			viewport.size.x = width
			reference.size.x = width
			camera.position = Vector2(width * 0.5, 200.0)
			await process_frame
			for layer in background.get_children():
				for other in background.get_children():
					other.visible = other == layer
				var tiles := Node2D.new()
				reference.add_child(tiles)
				for source in layer.get_children():
					if source is not Sprite2D or source.texture == null:
						continue
					for row in range(3):
						for column in range(4):
							var sprite := source.duplicate() as Sprite2D
							sprite.region_enabled = false
							sprite.position = Vector2(column * 640, row * 450)
							tiles.add_child(sprite)
				for offset in [Vector2.ZERO, Vector2(-13, 409), Vector2(13, 818)]:
					background.scroll_base_offset = offset
					camera.offset = Vector2(offset.x, 0.0)
					camera.force_update_scroll()
					await process_frame
					var origin: Vector2 = layer.get_global_transform_with_canvas().origin
					tiles.position = Vector2(fposmod(origin.x, 640.0) - 640.0, fposmod(origin.y, 450.0) - 450.0)
					await RenderingServer.frame_post_draw
					var actual := viewport.get_texture().get_image()
					var expected := reference.get_texture().get_image()
					var mismatches := 0
					for y in range(4, 400, 8):
						for x in range(4, width, 8):
							var pixel := actual.get_pixel(x, y)
							var target := expected.get_pixel(x, y)
							if absf(pixel.a - target.a) > 0.02 or absf(pixel.r - target.r) > 0.02:
								mismatches += 1
					_check(mismatches == 0, "wave %d, %s, width %d, offset %s: %d repeat glitches" % [wave, layer.name, width, offset, mismatches])
				tiles.queue_free()
				await process_frame
	viewport.queue_free()
	reference.queue_free()
	await process_frame

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("Background rendering: SKIP (requires a rendering display driver)")
		quit()
		return
	await _check_shader_alpha()
	await _check_nebula_seam()
	await _check_background_repeat()
	await _capture_themes()
	print("Background rendering: %s (%d checks)" % ["PASS" if _failures == 0 else "FAIL", _checks])
	quit(0 if _failures == 0 else 1)

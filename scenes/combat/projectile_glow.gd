class_name ProjectileGlow
extends RefCounted

const TEXTURE_SIZE := Vector2(64.0, 64.0)

static var _shared_texture: GradientTexture2D
static var _shared_material: CanvasItemMaterial


static func create(
	source: Sprite2D,
	color: Color,
	core_brightness: float,
	size_multiplier: Vector2,
	material: Material = null
) -> Sprite2D:
	source.self_modulate = Color(core_brightness, core_brightness, core_brightness, 1.0)
	var glow := Sprite2D.new()
	glow.name = "ProjectileGlow"
	glow.texture = _get_texture()
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.material = material if material != null else _get_material()
	glow.z_index = source.z_index + 1
	source.get_parent().add_child(glow)
	sync(source, glow, color, size_multiplier)
	return glow


static func sync(source: Sprite2D, glow: Sprite2D, color: Color, size_multiplier: Vector2) -> void:
	var frame_size := source.texture.get_size() / Vector2(source.hframes, source.vframes)
	var source_scale := Vector2(absf(source.scale.x), absf(source.scale.y))
	glow.position = source.position
	glow.rotation = source.rotation
	glow.scale = frame_size * source_scale * size_multiplier / TEXTURE_SIZE
	glow.modulate = color
	glow.visible = source.visible


static func _get_texture() -> GradientTexture2D:
	if _shared_texture != null:
		return _shared_texture
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.36),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	_shared_texture = GradientTexture2D.new()
	_shared_texture.width = int(TEXTURE_SIZE.x)
	_shared_texture.height = int(TEXTURE_SIZE.y)
	_shared_texture.fill = GradientTexture2D.FILL_RADIAL
	_shared_texture.fill_from = Vector2(0.5, 0.5)
	_shared_texture.fill_to = Vector2(1.0, 0.5)
	_shared_texture.gradient = gradient
	return _shared_texture


static func _get_material() -> CanvasItemMaterial:
	if _shared_material == null:
		_shared_material = CanvasItemMaterial.new()
		_shared_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _shared_material

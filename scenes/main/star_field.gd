extends CPUParticles2D

@export var star_count: int = 72

func _ready() -> void:
	show_behind_parent = true
	z_index = -1
	texture = preload("res://assets/sprites/world/light.png")
	amount = star_count
	lifetime = 4.0
	preprocess = 4.0
	explosiveness = 0.0
	randomness = 1.0
	local_coords = true
	emission_shape = EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(450, 260)
	direction = Vector2.ZERO
	spread = 180.0
	gravity = Vector2.ZERO
	initial_velocity_min = 0.0
	initial_velocity_max = 3.0
	scale_amount_min = 0.015
	scale_amount_max = 0.08
	color = Color(0.92, 0.95, 1.0, 0.85)
	hue_variation_min = -0.04
	hue_variation_max = 0.12
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = blend
	emitting = true

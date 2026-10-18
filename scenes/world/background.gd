extends ParallaxBackground

const BASE_SPEED_Y := 40.0
const MIN_SPEED_Y := 30.0
const MAX_SPEED_Y := 50.0
const SPEED_RESPONSE := 65.0
const WAVES_PER_THEME := 6
const THEME_FADE_SECONDS := 8.0

const THEME_TEXTURES := [
	[
		preload("res://assets/sprites/world/gameplay_background/far.png"),
		preload("res://assets/sprites/world/gameplay_background/mid.png"),
		preload("res://assets/sprites/world/gameplay_background/near.png"),
	],
	[
		preload("res://assets/sprites/world/gameplay_background/violet_orbit/far.png"),
		preload("res://assets/sprites/world/gameplay_background/violet_orbit/mid.png"),
		preload("res://assets/sprites/world/gameplay_background/violet_orbit/near.png"),
	],
	[
		preload("res://assets/sprites/world/gameplay_background/red_rift/far.png"),
		preload("res://assets/sprites/world/gameplay_background/red_rift/mid.png"),
		preload("res://assets/sprites/world/gameplay_background/red_rift/near.png"),
	],
]

@export var speed_Y: float = BASE_SPEED_Y
@export var speed_X: float = 0.0
@export var lock_scroll_speed := false
@export var wave_theme_enabled := false

var _player_intents := {}
var _target_speed_y := BASE_SPEED_Y
var _theme_index := -1
var _theme_fade_elapsed := THEME_FADE_SECONDS

func _ready() -> void:
	get_viewport().size_changed.connect(_update_horizontal_repeat)
	_update_horizontal_repeat()
	Events.player_motion_changed.connect(_on_player_motion_changed)
	if wave_theme_enabled:
		Events.wave_changed.connect(_on_wave_changed)
		_apply_theme_for_wave(maxi(global.wave, 1))


# ParallaxLayer draws only two copies, so each repeat must cover the viewport width.
func _update_horizontal_repeat() -> void:
	var tile_size: Vector2 = $"b3/stars".texture.get_size()
	var repeat_width := ceilf(get_viewport().get_visible_rect().size.x / tile_size.x) * tile_size.x
	for parallax_layer in get_children():
		if parallax_layer is not ParallaxLayer:
			continue
		parallax_layer.motion_mirroring.x = repeat_width
		for sprite in parallax_layer.get_children():
			if sprite is Sprite2D:
				sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
				sprite.region_enabled = true
				sprite.region_rect = Rect2(Vector2.ZERO, Vector2(repeat_width, tile_size.y))


func _process(delta: float) -> void:
	if not lock_scroll_speed:
		speed_Y = move_toward(speed_Y, _target_speed_y, SPEED_RESPONSE * delta)
	scroll_base_offset += Vector2(speed_X, speed_Y) * delta
	if _theme_fade_elapsed < THEME_FADE_SECONDS:
		_theme_fade_elapsed = minf(_theme_fade_elapsed + delta, THEME_FADE_SECONDS)
		var blend := smoothstep(0.0, 1.0, _theme_fade_elapsed / THEME_FADE_SECONDS)
		for sprites in _theme_sprites():
			sprites[0].modulate.a = 1.0 - blend
			sprites[1].modulate.a = blend
		if _theme_fade_elapsed >= THEME_FADE_SECONDS:
			for sprites in _theme_sprites():
				sprites[0].texture = sprites[1].texture
				sprites[0].modulate.a = 1.0
				sprites[1].texture = null
				sprites[1].modulate.a = 0.0

func _on_player_motion_changed(player_id: String, vertical_intent: float) -> void:
	_player_intents[player_id] = clampf(vertical_intent, -1.0, 1.0)
	var total := 0.0
	for intent in _player_intents.values():
		total += float(intent)
	var average := total / float(_player_intents.size())
	_target_speed_y = lerpf(MIN_SPEED_Y, MAX_SPEED_Y, (average + 1.0) * 0.5)


func _on_wave_changed(wave: int) -> void:
	_apply_theme_for_wave(wave)


func _apply_theme_for_wave(wave: int) -> void:
	var theme_index := mini(maxi(floori(float(wave - 1) / float(WAVES_PER_THEME)), 0), THEME_TEXTURES.size() - 1)
	if theme_index == _theme_index:
		return
	_theme_index = theme_index
	var textures: Array = THEME_TEXTURES[theme_index]
	var sprites := _theme_sprites()
	if _theme_fade_elapsed >= THEME_FADE_SECONDS and sprites[0][0].texture == textures[0]:
		return
	$"PlanetsLayer/Planets".texture = textures[1]
	$"b1/stars".texture = textures[2]
	$"b1/StarPoints".texture = textures[2]
	if wave <= 1:
		for index in sprites.size():
			sprites[index][0].texture = textures[index]
		return
	_theme_fade_elapsed = 0.0
	for index in sprites.size():
		sprites[index][1].texture = textures[index]
		sprites[index][1].modulate.a = 0.0


func _theme_sprites() -> Array:
	return [
		[$"b3/stars", $"b3/Incoming"],
		[$"b2/stars2", $"b2/Incoming"],
	]

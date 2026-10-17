extends Node2D

const TEXTURE := preload("res://assets/sprites/effects/dread_ark_explosion_sheet.png")
const SMALL_SOUND := preload("res://assets/audio/sfx/enemies/drone_explode.wav")
const FINAL_SOUND := preload("res://assets/audio/sfx/enemies/mother_ship_explode.wav")
const BURSTS := [
	[0.0, Vector2(-40, 20), 40.0],
	[0.12, Vector2(40, 18), 44.0],
	[0.24, Vector2(-50, -4), 48.0],
	[0.36, Vector2(48, -8), 48.0],
	[0.48, Vector2(-18, -26), 52.0],
	[0.60, Vector2(18, -28), 52.0],
	[0.72, Vector2(0, 10), 64.0],
	[0.84, Vector2(0, -14), 72.0],
]
const FINAL_TIME := 0.96
const DURATION := 1.9

var hull_texture: Texture2D
var hull_frame := 0
var _elapsed := 0.0
var _next_burst := 0
var _final_fired := false
var _small_sound := AudioStreamPlayer2D.new()
var _final_sound := AudioStreamPlayer2D.new()

func _ready() -> void:
	add_to_group("boss_death_effect")
	z_index = 10
	_small_sound.stream = SMALL_SOUND
	_small_sound.volume_db = -8.0
	add_child(_small_sound)
	_final_sound.stream = FINAL_SOUND
	add_child(_final_sound)

func _process(delta: float) -> void:
	_elapsed += delta
	while _next_burst < BURSTS.size() and _elapsed >= BURSTS[_next_burst][0]:
		_small_sound.position = BURSTS[_next_burst][1]
		_small_sound.play()
		Events.screen_shake_requested.emit(6.0, 0.2)
		_next_burst += 1
	if not _final_fired and _elapsed >= FINAL_TIME:
		_final_fired = true
		_final_sound.play()
		Events.screen_shake_requested.emit(52.0, 1.15)
		Events.screen_flash_requested.emit(Color(1.0, 0.72, 0.35, 0.18), 0.24)
	queue_redraw()
	if _elapsed >= DURATION:
		queue_free()

func _draw() -> void:
	if hull_texture and _elapsed < FINAL_TIME:
		var source := Rect2((hull_frame % 12) * 128, floori(hull_frame / 12.0) * 96, 128, 96)
		var alpha := 1.0 - clampf((_elapsed - 0.6) / 0.36, 0.0, 1.0)
		draw_texture_rect_region(hull_texture, Rect2(-64, -48, 128, 96), source, Color(1, 1, 1, alpha))
	for burst in BURSTS:
		_draw_burst(_elapsed - burst[0], burst[1], burst[2])
	var final_age := _elapsed - FINAL_TIME
	if final_age >= 0.0:
		_draw_burst(final_age, Vector2.ZERO, 192.0)
		if final_age < 0.65:
			draw_arc(Vector2.ZERO, 18.0 + final_age * 180.0, 0.0, TAU, 64, Color(1.0, 0.62, 0.3, (1.0 - final_age / 0.65) * 0.6), 2.0)

func _draw_burst(age: float, at: Vector2, width: float) -> void:
	if age < 0.0 or age >= 0.56:
		return
	var frame := mini(int(age / 0.04), 13)
	var size := Vector2(TEXTURE.get_width() / 14.0, TEXTURE.get_height())
	var drawn_size := Vector2(width, width * size.y / size.x)
	draw_texture_rect_region(TEXTURE, Rect2(at - drawn_size * 0.5, drawn_size), Rect2(Vector2(frame * size.x, 0), size))

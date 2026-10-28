extends Node2D

const SHEET := preload("res://assets/sprites/player/reflector_sphere.png")
const BREAK_DURATION := 0.22

var _team := 0
var _age := 0.0
var _charges := 0
var _flash := 0.0
var _rupture := 0.0
var _return := 0.0

func setup() -> void:
	_team = 1 if get_parent().set_Player_2 else 0
	present(0)

func present(charges: int) -> void:
	_charges = charges
	_render()

func advance(delta: float) -> void:
	_age += delta
	_flash = maxf(0.0, _flash - delta)
	_rupture = maxf(0.0, _rupture - delta)
	_return = maxf(0.0, _return - delta)
	_render()

func impacted() -> void:
	_flash = 0.12

func reflected() -> void:
	if not $sound_trowback.playing: $sound_trowback.play()

func ruptured() -> void:
	_rupture = BREAK_DURATION
	if $SoundBreak.stream: $SoundBreak.play()

func returned() -> void:
	_return = 0.12
	if $SoundReturn.stream: $SoundReturn.play()

func _render() -> void:
	visible = _charges > 0 or _rupture > 0.0
	var frame := int(_age / 0.08) % 4
	if _charges == 0:
		frame = 6
	elif _flash > 0.0:
		frame = 4 if _flash > 0.06 else 5
	elif _return > 0.0:
		frame = 7
	$Sprite2D.frame = _team * 8 + frame
	modulate.a = _rupture / BREAK_DURATION if _charges == 0 else 1.0
	queue_redraw()

func _draw() -> void:
	var tint := Color("ff5a4d") if _team == 0 else Color("7ad9ff")
	if _charges == 0 and _rupture > 0.0:
		var progress := 1.0 - _rupture / BREAK_DURATION
		for index in 8:
			var direction := Vector2.from_angle(TAU * index / 8)
			var point := direction * (20 + progress * 10)
			draw_line(point.round(), (point + direction * 3).round(), tint, 1.0)
	elif _flash > 0.0:
		for side in [-1, 1]:
			var point := Vector2(side * 22, 0)
			draw_line(point, point + Vector2(side * 6, 0), tint, 1.0)
			draw_polyline(PackedVector2Array([point + Vector2(side * 3, -3), point + Vector2(side * 6, 0), point + Vector2(side * 3, 3)]), tint, 1.0)

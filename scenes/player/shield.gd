extends Node2D

const SHEET := preload("res://assets/sprites/player/reflector_sphere.png")

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
	_rupture = 0.12
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
	modulate.a = _rupture / 0.12 if _charges == 0 else 1.0

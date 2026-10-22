extends Node2D

const SHEET := preload("res://assets/sprites/combat/impact_explosion.png")
const FRAME_COUNT := 8
const MAX_ACTIVE := 8

var owner_id: StringName = &""
var rank := 0
var age := 0.0
var _sprite: Sprite2D

func configure(at: Vector2, player_id: StringName, effect_rank: int) -> void:
	position = at.round()
	owner_id = player_id
	rank = clampi(effect_rank, 1, 3)
	age = 0.0

func _ready() -> void:
	if get_tree().get_nodes_in_group(&"impact_explosion").size() >= MAX_ACTIVE:
		set_process(false)
		queue_free()
		return
	add_to_group(&"impact_explosion")
	z_index = 6
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = FRAME_COUNT
	_sprite.vframes = 6
	add_child(_sprite)
	_sprite.frame = ((3 if owner_id == &"player2" else 0) + rank - 1) * FRAME_COUNT

# The combat service owns the clock so the bright front and damage cannot drift apart.
func set_elapsed(elapsed: float, lifetime: float) -> void:
	age = elapsed
	var row := (3 if owner_id == &"player2" else 0) + rank - 1
	_sprite.frame = row * FRAME_COUNT + mini(int(age * FRAME_COUNT / lifetime), FRAME_COUNT - 1)

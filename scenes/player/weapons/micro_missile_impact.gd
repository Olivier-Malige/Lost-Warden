extends Sprite2D

const SHEET := preload("res://assets/sprites/player/weapons/micro_missile_sheet.png")
const MAX_ACTIVE := 24
var age := 0.0
var team := 0

static func spawn(parent: Node, at: Vector2, player_id: StringName) -> void:
	if parent.get_tree().get_nodes_in_group(&"micro_missile_impact").size() >= MAX_ACTIVE:
		return
	var effect := new()
	effect.team = 1 if player_id == &"player2" else 0
	parent.add_child(effect)
	effect.global_position = at.round()

func _ready() -> void:
	add_to_group(&"micro_missile_impact")
	texture = SHEET
	hframes = 16
	vframes = 2
	frame = team * 16 + 12
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 8

func _process(delta: float) -> void:
	age += delta
	if age >= 0.2:
		queue_free()
	else:
		frame = team * 16 + 12 + int(age / 0.05)

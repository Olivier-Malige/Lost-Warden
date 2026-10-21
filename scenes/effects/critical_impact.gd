extends Sprite2D

const SHEET := preload("res://assets/sprites/effects/critical_impact_sheet.png")
const MAX_ACTIVE := 32
const FRAME_SECONDS := 0.05
const FRAME_COUNT := 6

var age := 0.0
var team := 0

static func spawn(parent: Node, at: Vector2, player_id: StringName) -> Sprite2D:
	if parent.get_tree().get_nodes_in_group(&"critical_impact").size() >= MAX_ACTIVE:
		return null
	var effect := new()
	effect.team = 1 if player_id == &"player2" else 0
	parent.add_child(effect)
	effect.global_position = at.round()
	return effect

func _ready() -> void:
	add_to_group(&"critical_impact")
	texture = SHEET
	hframes = FRAME_COUNT
	vframes = 2
	frame = team * FRAME_COUNT
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 8

func _process(delta: float) -> void:
	age += delta
	var index := int(age / FRAME_SECONDS)
	if index >= FRAME_COUNT:
		queue_free()
	else:
		frame = team * FRAME_COUNT + index

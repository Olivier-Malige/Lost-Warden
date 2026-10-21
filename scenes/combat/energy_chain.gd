extends Node2D

const SHEET := preload("res://assets/sprites/combat/energy_chain.png")
const FRAME_SECONDS := 0.06
const FRAME_COUNT := 4
const MAX_ACTIVE := 16

var links: Array[PackedVector2Array] = []
var owner_id: StringName
var age := 0.0
var _textures: Array[AtlasTexture] = []
var _anchors: Array[Sprite2D] = []
var _lines: Array[Line2D] = []
var _cores: Array[Line2D] = []
var _sparks: Array[Line2D] = []
var _tracked_anchors: Array[Dictionary] = []

func configure(segments: Array[PackedVector2Array], player_id: StringName, tracked: Array[Dictionary] = []) -> void:
	links.assign(segments.duplicate(true))
	owner_id = player_id
	_tracked_anchors.assign(tracked.duplicate(true))

func _ready() -> void:
	if get_tree().get_nodes_in_group(&"energy_chain").size() >= MAX_ACTIVE:
		set_process(false)
		queue_free()
		return
	add_to_group(&"energy_chain")
	z_index = 7
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var row := 16 if owner_id == &"player2" else 0
	for link in links:
		var start := to_local(link[0]).round()
		var finish := to_local(link[1]).round()
		var line := Line2D.new()
		line.width = 3
		line.default_color = Color("ff5a4d") if row == 0 else Color("7ad9ff")
		add_child(line)
		_lines.append(line)
		var core := line.duplicate() as Line2D
		core.width = 1
		core.default_color = Color("fff8e8")
		add_child(core)
		_cores.append(core)
		var sparks := line.duplicate() as Line2D
		sparks.width = 8
		sparks.default_color = Color.WHITE
		sparks.texture_mode = Line2D.LINE_TEXTURE_TILE
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = Rect2(0, row, 32, 8)
		_textures.append(texture)
		sparks.texture = texture
		add_child(sparks)
		_sparks.append(sparks)
		for at in [start, finish]:
			var anchor := Sprite2D.new()
			anchor.texture = SHEET
			anchor.region_enabled = true
			anchor.region_rect = Rect2(32, row, 16, 16)
			anchor.position = at
			add_child(anchor)
			_anchors.append(anchor)
	_update_links()

# Visual attachment never reacquires targets or changes the already resolved damage path.
func _update_links() -> void:
	for index in links.size():
		var link := links[index]
		for endpoint in 2:
			var anchor_index := index + endpoint
			if anchor_index >= _tracked_anchors.size():
				continue
			var anchor := _tracked_anchors[anchor_index]
			var target: Node2D = anchor.target.get_ref()
			if is_instance_valid(target) and target.is_inside_tree() and not target.is_queued_for_deletion():
				link[endpoint] = target.to_global(anchor.offset)
		links[index] = link
		var start := to_local(link[0]).round()
		var finish := to_local(link[1]).round()
		var direction := finish - start
		var normal := direction.normalized().orthogonal()
		var points := PackedVector2Array([start, (start + direction * 0.25 + normal * 3).round(), (start + direction * 0.5 - normal * 3).round(), (start + direction * 0.75 + normal * 2).round(), finish])
		_lines[index].points = points
		_cores[index].points = points
		_sparks[index].points = points
		_anchors[index * 2].position = start
		_anchors[index * 2 + 1].position = finish

func _process(delta: float) -> void:
	age += delta
	var index := int(age / FRAME_SECONDS)
	if index >= FRAME_COUNT:
		links.clear()
		_tracked_anchors.clear()
		queue_free()
		return
	_update_links()
	for texture in _textures:
		texture.region.position.x = index * 48
	for anchor in _anchors:
		anchor.region_rect.position.x = index * 48 + 32
	for line in _lines:
		line.width = 3 if index < 2 else 2
		line.default_color = (Color("ff5a4d") if owner_id == &"player1" else Color("7ad9ff")) if index < 2 else (Color("c82436") if owner_id == &"player1" else Color("216bc2"))
	for core in _cores:
		core.visible = index < 3

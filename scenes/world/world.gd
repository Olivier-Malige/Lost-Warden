extends Node2D
var nbr_Player := 0
func _ready() -> void:
	Events.player_died.connect(_on_player_died)
	global.score = 0
	Events.score_changed.emit(0)
	if $music.stream:
		$music.stream.loop = true
	var offsets := [Vector2(-50, 0), Vector2(50, 0)] if global.coop else [Vector2.ZERO]
	nbr_Player = offsets.size()
	for i in nbr_Player:
		_spawn_player(i == 1, offsets[i])

func _spawn_player(is_p2: bool, offset: Vector2) -> void:
	var p = preload("res://scenes/player/player.tscn").instantiate()
	p.set_Player_2 = is_p2
	p.position = $playerSpawn.global_position + offset
	add_child(p, true)

func _on_player_died() -> void:
	nbr_Player -= 1
	if nbr_Player <= 0:
		Events.game_over_requested.emit()
		queue_free()

extends CanvasLayer

var _pips := {}
var _scenes := {}

func _ready() -> void:
	Events.score_changed.connect(_on_score_changed)
	Events.wave_changed.connect(_on_wave_changed)
	Events.energy_changed.connect(_on_energy_changed)

func _on_score_changed(score: int) -> void:
	$LeftColumn/score.set_text("SCORE\n" + str(score))

func _on_wave_changed(wave: int) -> void:
	$RightColumn/wave.set_text("WAVE\n" + str(wave))

func _on_energy_changed(player_id: String, energy: int) -> void:
	var column := "LeftColumn" if player_id == "player1" else "RightColumn"
	var holder := get_node_or_null(column + "/energy_" + player_id)
	if holder == null:
		return
	if not _pips.has(player_id):
		_pips[player_id] = []
		_scenes[player_id] = load("res://scenes/player/" + player_id + "_energy.tscn")
	var pips: Array = _pips[player_id]
	while pips.size() < energy:
		var pip = _scenes[player_id].instantiate()
		holder.add_child(pip)
		holder.move_child(pip, 0)
		pips.append(pip)
	for i in pips.size():
		pips[i].visible = i < energy

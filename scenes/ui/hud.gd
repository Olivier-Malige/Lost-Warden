extends CanvasLayer

var _pips := {}
var _scenes := {}
var _combo_tween: Tween

func _ready() -> void:
	Events.score_changed.connect(_on_score_changed)
	Events.combo_changed.connect(_on_combo_changed)
	Events.wave_changed.connect(_on_wave_changed)
	Events.energy_changed.connect(_on_energy_changed)

func _on_score_changed(score: int) -> void:
	$LeftColumn/score.set_text("SCORE\n" + str(score))

func _on_combo_changed(combo: int, multiplier: float, _time_left: float) -> void:
	if combo < 2:
		$LeftColumn/combo.set_text("COMBO\n—")
		$LeftColumn/combo.modulate = Color.WHITE
	else:
		$LeftColumn/combo.set_text("COMBO " + str(combo) + "\nx" + str(snapped(multiplier, 0.1)))
		$LeftColumn/combo.modulate = Color(0.86, 0.79, 0.42)
		if _combo_tween:
			_combo_tween.kill()
		$LeftColumn/combo.scale = Vector2(1.06, 1.06)
		_combo_tween = create_tween()
		_combo_tween.tween_property($LeftColumn/combo, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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

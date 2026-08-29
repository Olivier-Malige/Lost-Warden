extends CanvasLayer

var _pips := {}
var _scenes := {}
var _combo_tween: Tween
var _feedback_tweens := {}
const RANK_LABELS := {
	UpgradeDefinition.Effect.SPEED: "SPD",
	UpgradeDefinition.Effect.DAMAGE: "DMG",
	UpgradeDefinition.Effect.FIRE_RATE: "RATE",
	UpgradeDefinition.Effect.SIDE_SHOT: "SIDE",
	UpgradeDefinition.Effect.BEAM: "BEAM",
}

func _ready() -> void:
	Events.score_changed.connect(_on_score_changed)
	Events.combo_changed.connect(_on_combo_changed)
	Events.wave_changed.connect(_on_wave_changed)
	Events.energy_changed.connect(_on_energy_changed)
	Events.upgrade_changed.connect(_on_upgrade_changed)
	Events.upgrade_feedback_requested.connect(_on_upgrade_feedback_requested)

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

func _on_upgrade_changed(player_id: String, effect: int, rank: int, max_rank: int) -> void:
	if not RANK_LABELS.has(effect):
		return
	var column := "LeftColumn" if player_id == "player1" else "RightColumn"
	var label := get_node_or_null(column + "/ranks_" + player_id) as Label
	if label == null:
		return
	var rows: PackedStringArray = label.get_meta("rows", PackedStringArray(["SPD 0/8", "DMG 0/8", "RATE 0/8", "SIDE 0/7", "BEAM 0/8"]))
	var prefix := String(RANK_LABELS[effect])
	var value := prefix + " MAX" if rank >= max_rank else prefix + " " + str(rank) + "/" + str(max_rank)
	for index in rows.size():
		if rows[index].begins_with(prefix + " "):
			rows[index] = value
			break
	label.set_meta("rows", rows)
	label.text = "UPGRADES\n" + "\n".join(rows)
	label.visible = true
	var panel_name := "LeftRankPanel" if player_id == "player1" else "RightRankPanel"
	var panel := get_node_or_null(panel_name) as Panel
	if panel:
		panel.visible = true

func _on_upgrade_feedback_requested(player_id: String, text: String, capped: bool) -> void:
	var label := get_node_or_null("Feedback_" + player_id) as Label
	if label == null:
		return
	if _feedback_tweens.has(player_id):
		_feedback_tweens[player_id].kill()
	label.text = text
	label.modulate = Color(0.9, 0.78, 0.2) if capped else Color(0.95, 0.92, 0.87)
	label.visible = true
	label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): label.visible = false)
	_feedback_tweens[player_id] = tween

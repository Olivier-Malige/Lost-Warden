extends CanvasLayer

const PLAYER_STATS: PlayerStats = preload("res://data/player/player_stats.tres")

var _pips := {}
var _scenes := {}
var _combo_tween: Tween
var _feedback_tweens := {}
var _beam_tweens := {}
var _build_controls := {}
var _level_label: Label
var _xp_bar: ProgressBar
const FONT := preload("res://assets/fonts/slkscr.ttf")
const ART := preload("res://assets/sprites/ui/phase_3_upgrade_ui.png")
const MINI_ICONS := preload("res://assets/sprites/ui/upgrade_miniatures.png")

func _ready() -> void:
	Events.score_changed.connect(_on_score_changed)
	Events.combo_changed.connect(_on_combo_changed)
	Events.run_time_changed.connect(_on_run_time_changed)
	Events.energy_changed.connect(_on_energy_changed)
	Events.beam_charge_changed.connect(_on_beam_charge_changed)
	Events.build_changed.connect(_on_build_changed)
	Events.progression_changed.connect(_on_progression_changed)
	Events.upgrade_feedback_requested.connect(_on_upgrade_feedback_requested)

func _on_score_changed(score: int) -> void:
	$LeftColumn/score.set_text("SCORE\n" + str(score))

func _on_combo_changed(combo: int, multiplier: float, _time_left: float) -> void:
	if _combo_tween:
		_combo_tween.kill()
	if combo < 2:
		$LeftColumn/combo.set_text("COMBO\n-")
		$LeftColumn/combo.modulate = Color.WHITE
	else:
		$LeftColumn/combo.set_text("COMBO " + str(combo) + "\nx" + str(snapped(multiplier, 0.1)))
		$LeftColumn/combo.modulate = Color.WHITE
		_combo_tween = create_tween()
		_combo_tween.tween_property($LeftColumn/combo, "modulate", Color(0.86, 0.79, 0.42), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_run_time_changed(survival_seconds: float) -> void:
	var text := "SURVIVAL\n" + global.format_survival_time(survival_seconds)
	if $RightColumn/wave.text != text:
		$RightColumn/wave.text = text

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

func _on_beam_charge_changed(player_id: String, current: float, maximum: float, overdrive_ready: bool) -> void:
	var column := "LeftColumn" if player_id == "player1" else "RightColumn"
	var holder := get_node_or_null(column + "/plasma_holder_" + player_id) as VBoxContainer
	var bar := get_node_or_null(column + "/plasma_holder_" + player_id + "/plasma_" + player_id) as ProgressBar
	if holder == null or bar == null:
		return
	holder.visible = player_id == "player1" or global.coop
	bar.max_value = maximum
	bar.value = current
	if overdrive_ready:
		_start_beam_pulse(player_id, holder)
		return
	_stop_beam_pulse(player_id)
	holder.modulate = Color(0.45, 0.45, 0.55, 1.0) if current < PLAYER_STATS.beam_activation_min else Color.WHITE

func _start_beam_pulse(player_id: String, holder: Control) -> void:
	var current_tween: Tween = _beam_tweens.get(player_id)
	if current_tween and current_tween.is_running():
		return
	holder.modulate = Color.WHITE
	var tween := create_tween().set_loops()
	tween.tween_property(holder, "modulate", Color(1.0, 0.72, 0.96, 1.0), 0.3)
	tween.tween_property(holder, "modulate", Color.WHITE, 0.3)
	_beam_tweens[player_id] = tween

func _stop_beam_pulse(player_id: String) -> void:
	var tween: Tween = _beam_tweens.get(player_id)
	if tween:
		tween.kill()
		_beam_tweens.erase(player_id)

func _on_build_changed(player_id: StringName, snapshot: Dictionary) -> void:
	var column := "LeftColumn" if player_id == "player1" else "RightColumn"
	get_node(column + "/ranks_" + player_id).hide()
	var panel_name := "LeftRankPanel" if player_id == "player1" else "RightRankPanel"
	var panel := get_node_or_null(panel_name) as Panel
	if panel: panel.hide()
	if not _build_controls.has(player_id):
		var holder := VBoxContainer.new()
		holder.name = "Build" + String(player_id).capitalize().replace(" ", "")
		holder.custom_minimum_size = Vector2(96, 76)
		holder.alignment = BoxContainer.ALIGNMENT_CENTER
		holder.add_theme_constant_override("separation", 0)
		get_node(column).add_child(holder)
		get_node(column).move_child(holder, 2)
		_build_controls[player_id] = holder
	var holder: VBoxContainer = _build_controls[player_id]
	for child in holder.get_children():
		child.hide()
		child.queue_free()
	for category in [UpgradeDefinition.Category.OFFENSIVE, UpgradeDefinition.Category.UTILITY]:
		var title := _text("OFFENSE" if category == UpgradeDefinition.Category.OFFENSIVE else "UTILITY", 8)
		holder.add_child(title)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 2)
		holder.add_child(row)
		var equipped := []
		for family in snapshot.families:
			if family.category == category: equipped.append(family)
		for index in (4 if category == UpgradeDefinition.Category.OFFENSIVE else 3):
			var slot := TextureRect.new()
			slot.custom_minimum_size = Vector2(18, 24)
			slot.texture = _atlas(Rect2(96 if category == UpgradeDefinition.Category.OFFENSIVE else 112, 32, 16, 16))
			slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			row.add_child(slot)
			if index < equipped.size():
				var icon := TextureRect.new()
				icon.texture = equipped[index].icon
				if player_id == &"player2" and icon.texture is AtlasTexture and icon.texture.atlas == MINI_ICONS:
					var team_icon := icon.texture.duplicate() as AtlasTexture
					team_icon.region = Rect2(team_icon.region.position + Vector2(0, 16), team_icon.region.size)
					icon.texture = team_icon
				icon.position = Vector2(1, 0)
				icon.size = Vector2(16, 16)
				slot.add_child(icon)
				var rank := _text(str(equipped[index].rank), 8)
				rank.position = Vector2(0, 14)
				rank.size = Vector2(18, 10)
				slot.add_child(rank)
				slot.tooltip_text = equipped[index].display_name

func _on_progression_changed(snapshot: Dictionary) -> void:
	if _level_label == null:
		var holder := VBoxContainer.new()
		holder.name = "Progression"
		holder.custom_minimum_size = Vector2(96, 28)
		holder.add_theme_constant_override("separation", 1)
		$RightColumn.add_child(holder)
		$RightColumn.move_child(holder, 1)
		_level_label = _text("", 12)
		holder.add_child(_level_label)
		_xp_bar = ProgressBar.new()
		_xp_bar.name = "LevelProgress"
		_xp_bar.custom_minimum_size = Vector2(84, 5)
		_xp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_xp_bar.show_percentage = false
		for state in ["background", "fill"]:
			var style := StyleBoxTexture.new()
			style.texture = ART
			style.region_rect = Rect2(0 if state == "background" else 8, 48, 8, 4)
			style.texture_margin_left = 2
			style.texture_margin_right = 2
			_xp_bar.add_theme_stylebox_override(state, style)
		holder.add_child(_xp_bar)
	_level_label.text = "LEVEL %d" % snapshot.level
	_xp_bar.max_value = snapshot.next_threshold
	_xp_bar.value = snapshot.xp

func _text(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f3ebdd"))
	return label

func _atlas(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ART
	texture.region = region
	return texture

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

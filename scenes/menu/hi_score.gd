extends Control


func _ready() -> void:
	$Center/Panel/Margin/Content/Records/Solo/Card/ScoreValue.text = "%06d" % global.saveData.solo.hiscore
	$Center/Panel/Margin/Content/Records/Solo/Card/WaveValue.text = "%02d" % global.saveData.solo.bestWave
	$Center/Panel/Margin/Content/Records/Coop/Card/ScoreValue.text = "%06d" % global.saveData.coop.hiscore
	$Center/Panel/Margin/Content/Records/Coop/Card/WaveValue.text = "%02d" % global.saveData.coop.bestWave
	_animate_screen()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start") and not event.is_echo():
		Events.start_screen_requested.emit()
		queue_free()
		get_viewport().set_input_as_handled()


func _animate_screen() -> void:
	var title := $Center/Panel/Margin/Content/Title
	var line := $Center/Panel/Margin/Content/Line
	var solo := $Center/Panel/Margin/Content/Records/Solo
	var coop := $Center/Panel/Margin/Content/Records/Coop
	var hint := $Center/Panel/Margin/Content/ReturnHint
	title.modulate.a = 0.0
	title.scale = Vector2(0.9, 0.9)
	line.scale.x = 0.0
	solo.modulate.a = 0.0
	coop.modulate.a = 0.0
	solo.scale = Vector2(0.94, 0.94)
	coop.scale = Vector2(0.94, 0.94)
	await get_tree().process_frame
	title.pivot_offset = title.size * 0.5
	line.pivot_offset = line.size * 0.5
	for card in [solo, coop]:
		card.pivot_offset = card.size * 0.5

	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(title, "modulate:a", 1.0, 0.3)
	entrance.tween_property(title, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(line, "scale:x", 1.0, 0.45).set_delay(0.15)
	entrance.tween_property(solo, "modulate:a", 1.0, 0.35).set_delay(0.25)
	entrance.tween_property(solo, "scale", Vector2.ONE, 0.45).set_delay(0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(coop, "modulate:a", 1.0, 0.35).set_delay(0.4)
	entrance.tween_property(coop, "scale", Vector2.ONE, 0.45).set_delay(0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await entrance.finished

	var pulse := create_tween().set_loops()
	pulse.tween_property(hint, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(hint, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

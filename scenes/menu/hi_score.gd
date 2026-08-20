extends Node2D


func _ready() -> void:
	$score_solo.set_text("Best score : " + str(global.saveData.solo.hiscore))
	$score_coop.set_text("Best score : " + str(global.saveData.coop.hiscore))
	$wave_solo.set_text("higher wave : " + str(global.saveData.solo.bestWave))
	$wave_coop.set_text("higher wave : " + str(global.saveData.coop.bestWave))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start") and not event.is_echo():
		Events.start_screen_requested.emit()
		queue_free()

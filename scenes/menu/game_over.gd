extends Control


func _ready() -> void:
	if $music.stream:
		$music.stream.loop = true

	game_over()
	var rec: Dictionary = global.saveData.coop if global.coop else global.saveData.solo
	$Center/Panel/Margin/Content/BestScore.set_text("HISCORE : " + str(rec.hiscore))
	$Center/Panel/Margin/Content/HigherWave.set_text("BEST SURVIVAL : " + global.format_survival_time(rec.get("bestTime", 0)))
	$Center/Panel/Margin/Content/wave.set_text("SURVIVAL : " + global.format_survival_time(global.survival_time))
	$Center/Panel/Margin/Content/Score.set_text("SCORE : " + str(global.score))

func game_over() -> void:
	global.update_Data()

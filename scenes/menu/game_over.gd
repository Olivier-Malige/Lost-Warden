extends Control


func _ready() -> void:
	if $music.stream:
		$music.stream.loop = true

	var rec: Dictionary = global.saveData.coop if global.coop else global.saveData.solo
	$Center/Panel/Margin/Content/BestScore.set_text("HISCORE : " + str(rec.hiscore))
	$Center/Panel/Margin/Content/HigherWave.set_text("HIGHEST WAVE : " + str(rec.bestWave))
	$Center/Panel/Margin/Content/wave.set_text("WAVE : " + str(global.wave))
	$Center/Panel/Margin/Content/Score.set_text("SCORE : " + str(global.score))
	game_over()

func game_over() -> void:
	global.update_Data()

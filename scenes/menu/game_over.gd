extends Node2D


func _ready() -> void:
	if $music.stream:
		$music.stream.loop = true

	$AnimationPlayer.play("start")
	var rec: Dictionary = global.saveData.coop if global.coop else global.saveData.solo
	$BestScore.set_text("HISCORE : " + str(rec.hiscore))
	$BestScore/HigherWave.set_text("Higher Wave : " + str(rec.bestWave))
	$Score/wave.set_text("Wave : " + str(global.wave))
	$Score.set_text("SCORE : " + str(global.score))
	game_over()

func game_over() -> void:
	global.update_Data()

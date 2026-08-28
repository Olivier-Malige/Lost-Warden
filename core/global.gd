extends Node

const _Save := preload("res://core/save_service.gd")

var Debug := false
var score := 0
var combo := 0
var combo_time_left := 0.0
var wave := 0
var hiscoreSolo := 0
var hiscoreCoop := 0
var saveData := {
	solo = {
		hiscore = 0,
		bestWave = 0,
	},
	coop = {
		hiscore = 0,
		bestWave = 0,
	},
	config = {
		music = true,
		sound = true,
		fullscreen = true,
		player1 = "gamepad1",
		player2 = "keyboard",
		graphic = "high",
	}
}
var coop := false
var sav_path := "user://data.json"

func _process(delta: float) -> void:
	if combo <= 0:
		return
	combo_time_left = maxf(combo_time_left - delta, 0.0)
	if combo_time_left <= 0.0:
		combo = 0
		Events.combo_changed.emit(combo, 1.0, combo_time_left)

func _ready() -> void:
	saveData = _Save.load_data(saveData)
	if saveData.config.graphic == "hight":
		saveData.config.graphic = "high"
	setSound(saveData.config.sound)
	setMusic(saveData.config.music)

func setSound(state: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sounds"), not state)

func setMusic(state: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not state)

func save_Data() -> void:
	_Save.save_data(saveData)

func update_Data() -> void:
	var mode: Dictionary = saveData.coop if coop else saveData.solo
	var changed := false
	if wave > mode.bestWave:
		mode.bestWave = wave
		changed = true
	if score > mode.hiscore:
		mode.hiscore = score
		changed = true
	if changed:
		save_Data()

func reset_run() -> void:
	score = 0
	combo = 0
	combo_time_left = 0.0
	Events.combo_changed.emit(combo, 1.0, combo_time_left)

func register_kill(points: int) -> void:
	combo = mini(combo + 1, 10)
	combo_time_left = 2.0
	var multiplier := 1.0 + float(combo - 1) * 0.1
	score += roundi(float(points) * multiplier)
	Events.score_changed.emit(score)
	Events.combo_changed.emit(combo, multiplier, combo_time_left)

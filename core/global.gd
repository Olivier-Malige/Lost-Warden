extends Node

const _Save := preload("res://core/save_service.gd")

var Debug := OS.is_debug_build()
var score := 0
var eliminations := 0
var combo := 0
var combo_time_left := 0.0
var wave := 0
var survival_time := 0.0
var run_random := RunRandom.new()
var hiscoreSolo := 0
var hiscoreCoop := 0
var saveData := {
	solo = {
		hiscore = 0,
		bestWave = 0,
		bestTime = 0,
	},
	coop = {
		hiscore = 0,
		bestWave = 0,
		bestTime = 0,
	},
	config = {
		music = true,
		sound = true,
		fullscreen = true,
		player1 = "gamepad1",
		player2 = "keyboard",
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
	var seconds := maxi(floori(survival_time), 0)
	if not mode.has("bestTime") or seconds > int(mode.bestTime):
		mode.bestTime = seconds
		changed = true
	if score > mode.hiscore:
		mode.hiscore = score
		changed = true
	if changed:
		save_Data()

func reset_run(run_seed: int = -1) -> void:
	if run_seed < 0:
		var seed_source := RandomNumberGenerator.new()
		seed_source.randomize()
		run_seed = seed_source.randi()
	run_random = RunRandom.new(run_seed)
	wave = 0
	survival_time = 0.0
	if Debug:
		print("Run seed: %d" % run_seed)
	score = 0
	eliminations = 0
	Events.eliminations_changed.emit(eliminations)
	combo = 0
	combo_time_left = 0.0
	Events.combo_changed.emit(combo, 1.0, combo_time_left)

func format_survival_time(seconds: float) -> String:
	var total := maxi(floori(seconds), 0)
	return "%02d:%02d" % [floori(float(total) / 60.0), total % 60]

func register_kill(points: int, count_elimination := true) -> int:
	combo = mini(combo + 1, 99)
	combo_time_left = 2.0
	var multiplier := combo_multiplier(combo)
	var awarded_points := roundi(float(points) * multiplier)
	score += awarded_points
	Events.score_changed.emit(score)
	Events.combo_changed.emit(combo, multiplier, combo_time_left)
	if count_elimination:
		eliminations += 1
		Events.eliminations_changed.emit(eliminations)
	return awarded_points

func add_score(points: int) -> void:
	score += points
	Events.score_changed.emit(score)

func combo_multiplier(combo_count: int) -> float:
	if combo_count >= 12:
		return 2.0
	if combo_count >= 8:
		return 1.75
	if combo_count >= 5:
		return 1.5
	if combo_count >= 2:
		return 1.25
	return 1.0

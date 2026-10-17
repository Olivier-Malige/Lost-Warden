extends SceneTree

var _failures := 0
var _checks := 0
var _globals: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _make_spawner(seed_value: int) -> Variant:
	var spawner = load("res://scenes/waves/wave_spawner.gd").new()
	spawner.config = load("res://data/waves/wave_spawner_config.tres")
	spawner.catalog = load("res://data/waves/wave_catalog.tres")
	spawner.set_movement_seed(seed_value)
	for lane in spawner.config.lane_count:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % lane
		spawner.add_child(marker)
	root.add_child(spawner)
	spawner.start_run()
	spawner.set_physics_process(false)
	return spawner

func _check_progression(seed_value: int) -> void:
	var hud := CanvasLayer.new()
	hud.set_script(load("res://scenes/ui/hud.gd"))
	var column := Control.new()
	column.name = "RightColumn"
	hud.add_child(column)
	var label := Label.new()
	label.name = "wave"
	column.add_child(label)
	root.add_child(hud)
	var spawner = _make_spawner(seed_value)
	var recent: Array[StringName] = []
	for encounter_number in range(1, 46):
		_check(_globals.wave == encounter_number, "transitional run counter must reach encounter %d" % encounter_number)
		_check(label.text == "SURVIVAL\n00:00", "encounter selection must not advance the displayed survival timer")
		var chosen: StringName = spawner.director.encounter.id
		_check(chosen not in recent, "seeded encounters must avoid the previous two when alternatives exist")
		recent.append(chosen)
		if recent.size() > 2:
			recent.pop_front()
		if encounter_number < 45:
			spawner._begin_encounter()
	var before: float = spawner.director.danger_offset
	spawner.goto_Next_Wave()
	_check(is_equal_approx(spawner.director.danger_offset, before + 0.2), "debug next raises the danger offset")
	spawner.goto_Previous_Wave()
	_check(is_equal_approx(spawner.director.danger_offset, before), "debug previous lowers the danger offset")
	_check(_globals.wave == 45, "debug danger changes must not jump encounter history")
	spawner.stop_run()
	spawner.free()
	hud.free()

func _check_game_over(coop: bool, survival_seconds: float, formatted: String) -> void:
	_globals.coop = coop
	_globals.saveData.solo = {"hiscore": 1000, "bestWave": 8}
	_globals.saveData.coop = {"hiscore": 2000, "bestWave": 6}
	_globals.wave = 999
	_globals.survival_time = survival_seconds
	_globals.score = 14947
	var legacy_best := 6 if coop else 8
	var other_mode: Dictionary = (_globals.saveData.solo if coop else _globals.saveData.coop).duplicate(true)
	var screen = load("res://scenes/menu/game_over.tscn").instantiate()
	root.add_child(screen)
	var content: Node = screen.get_node("Center/Panel/Margin/Content")
	_check(content.get_node("wave").text == "SURVIVAL : " + formatted, "game over must display the final survival time independently of encounter count")
	_check(content.get_node("HigherWave").text == "BEST SURVIVAL : " + formatted, "game over includes the current run in the survival record")
	_check(content.get_node("BestScore").text == "HISCORE : 14947", "game over must include the current run in the score record")
	_check(content.get_node("Score").text == "SCORE : 14947", "game over must retain the run score")
	_check((_globals.saveData.solo if coop else _globals.saveData.coop) == other_mode, "records for the other mode must remain unchanged")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://data.json"))
	var record: Dictionary = saved.coop if coop else saved.solo
	_check(record.bestWave == legacy_best and record.hiscore == 14947, "score updates must preserve the legacy wave record")
	_check(record.bestTime == floori(survival_seconds), "survival records persist as completed seconds")
	screen.free()
	_globals.wave = 3
	_globals.score = 100
	_globals.survival_time = 1.9
	screen = load("res://scenes/menu/game_over.tscn").instantiate()
	root.add_child(screen)
	content = screen.get_node("Center/Panel/Margin/Content")
	_check(content.get_node("HigherWave").text == "BEST SURVIVAL : " + formatted, "a shorter run must preserve the survival record")
	_check(content.get_node("wave").text == "SURVIVAL : 00:01", "shorter run displays its own duration")
	_check(content.get_node("BestScore").text == "HISCORE : 14947", "a lower score must preserve the score record")
	screen.free()
	_globals.survival_time = survival_seconds + 60.0
	_globals.update_Data()
	saved = JSON.parse_string(FileAccess.get_file_as_string("user://data.json"))
	record = saved.coop if coop else saved.solo
	_check(record.bestTime == floori(survival_seconds) + 60 and record.hiscore == 14947, "a longer run saves its duration even without a higher score")
	_check(record.bestWave == legacy_best, "survival records never replace legacy wave values")

func _check_legacy_save() -> void:
	var service = load("res://core/save_service.gd")
	var defaults: Dictionary = _globals.saveData.duplicate(true)
	defaults.solo.bestTime = 0
	defaults.coop.bestTime = 0
	var legacy := {"solo": {"hiscore": 12345, "bestWave": 18}, "coop": {"hiscore": 54321, "bestWave": 25}, "config": {"music": false}}
	var file := FileAccess.open("user://legacy_survival_records.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var loaded: Dictionary = service.load_data(defaults, "user://legacy_survival_records.json")
	for mode in ["solo", "coop"]:
		_check(loaded[mode].bestTime == 0, "legacy saves receive a zero survival record without guessing from waves")
		_check(loaded[mode].hiscore == legacy[mode].hiscore and loaded[mode].bestWave == legacy[mode].bestWave, "legacy scores and wave records survive loading")
	_check(not loaded.config.music, "adding survival records preserves saved preferences")
	_globals.saveData = loaded
	_globals.coop = false
	_globals.survival_time = 332.8
	_globals.score = 500
	_globals.update_Data()
	var reloaded: Dictionary = service.load_data(defaults)
	_check(reloaded.solo.bestTime == 332 and reloaded.coop.bestTime == 0, "new solo survival records survive a save/load round trip without affecting co-op")
	_check(reloaded.solo.hiscore == 12345 and reloaded.coop.hiscore == 54321, "survival-only saves retain both existing scores")
	_check(reloaded.solo.bestWave == 18 and reloaded.coop.bestWave == 25, "save round trips preserve both legacy wave records")
	_globals.reset_run(42)
	_check(is_zero_approx(_globals.survival_time) and _globals.saveData.solo.bestTime == 332, "new runs reset current survival without resetting records")

func _check_hiscore_screen() -> void:
	_globals.saveData.solo = {"hiscore": 14947, "bestWave": 18, "bestTime": 332}
	_globals.saveData.coop = {"hiscore": 25400, "bestWave": 25, "bestTime": 3661}
	var screen = load("res://scenes/menu/hi_score.tscn").instantiate()
	root.add_child(screen)
	await create_timer(1.0).timeout
	var records: Node = screen.get_node("Center/Panel/Margin/Content/Records")
	_check(records.get_node("Solo/Card/WaveLabel").text == "BEST SURVIVAL" and records.get_node("Coop/Card/WaveLabel").text == "BEST SURVIVAL", "both record cards replace highest wave with best survival")
	_check(records.get_node("Solo/Card/WaveValue").text == "05:32", "solo card displays the saved survival record")
	_check(records.get_node("Coop/Card/WaveValue").text == "61:01", "co-op card displays its independent survival record beyond one hour")
	_check(records.get_node("Solo/Card/ScoreValue").text == "014947" and records.get_node("Coop/Card/ScoreValue").text == "025400", "hiscore cards retain score formatting")
	var event := InputEventAction.new()
	event.action = &"start"
	event.pressed = true
	screen._input(event)
	await process_frame
	_check(not is_instance_valid(screen), "the records screen still returns on Start")

func _check_survival_timer(coop: bool) -> void:
	_globals.coop = coop
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var spawner = world.get_node("waveGenerator")
	spawner.set_physics_process(false)
	var label: Label = world.get_node("hud/RightColumn/wave")
	_check(label.text == "SURVIVAL\n00:00", "solo/co-op survival starts at zero")
	spawner.director.elapsed = 59.5
	spawner._physics_process(0.75)
	_check(is_equal_approx(_globals.survival_time, 60.25), "director publishes the current survival snapshot for end-of-run screens")
	_check(label.text == "SURVIVAL\n01:00", "survival advances from actual run time across the minute boundary")
	var text := label.text
	_globals.Debug = true
	spawner.debug_skip_encounter()
	_check(label.text == text, "skipping an encounter does not advance displayed survival")
	spawner.goto_Next_Wave()
	_check(label.text == text, "debug danger is not displayed in the player HUD")
	_globals.Debug = false
	root.get_node("Events").wave_changed.emit(999)
	_check(label.text == text, "encounter notifications cannot restore the wave counter")
	spawner.director.state = EncounterDirector.State.BOSS
	spawner._physics_process(1.0)
	_check(label.text == "SURVIVAL\n01:01", "survival continues during boss state independently of regular encounter time")
	spawner.director.state = EncounterDirector.State.REGULAR
	var before: float = spawner.director.elapsed
	text = label.text
	paused = true
	spawner.set_physics_process(true)
	await create_timer(0.05).timeout
	_check(is_equal_approx(spawner.director.elapsed, before) and label.text == text, "pause freezes both survival state and its display")
	spawner.set_physics_process(false)
	paused = false
	spawner.stop_run()
	spawner._physics_process(10.0)
	_check(label.text == text, "survival display freezes when the run stops")
	root.get_node("Events").run_time_changed.emit(3661.9)
	_check(label.text == "SURVIVAL\n61:01", "long runs display total minutes without wrapping at one hour")
	root.get_node("Events").run_time_changed.emit(59.99)
	_check(label.text == "SURVIVAL\n00:59", "survival seconds are floored rather than rounded ahead")
	world.queue_free()
	await process_frame
	await process_frame

func _run() -> void:
	_globals = root.get_node("global")
	_globals.Debug = false
	_check_legacy_save()
	for coop in [false, true]:
		_globals.coop = coop
		_check_progression(17)
		_check_progression(8)
		_check_game_over(coop, 332.8, "05:32")
		_check_game_over(coop, 3661.9, "61:01")
		await _check_survival_timer(coop)
	await _check_hiscore_screen()
	_globals.wave = 45
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	_check(_globals.wave == 1, "a new run must restart at wave one")
	_check(world.get_node("hud/RightColumn/wave").text == "SURVIVAL\n00:00", "a new run HUD must reset survival time")
	world.queue_free()
	await process_frame
	await process_frame
	print("Wave progression: %s (%d checks)" % ["PASS" if _failures == 0 else "FAIL", _checks])
	quit(0 if _failures == 0 else 1)

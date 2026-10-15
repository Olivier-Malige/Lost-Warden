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

func _make_spawner(loop_start: int) -> Variant:
	var spawner = load("res://scenes/waves/wave_spawner.gd").new()
	spawner.config = load("res://data/waves/wave_spawner_config.tres").duplicate(true)
	spawner.config.loop_start_index = loop_start
	spawner.catalog = load("res://data/waves/wave_catalog.tres").duplicate(true)
	for wave in spawner.catalog.waves:
		for rule in wave.rules:
			rule.start_delay = 60.0
	for lane in spawner.config.lane_count:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % lane
		spawner.add_child(marker)
	root.add_child(spawner)
	return spawner

func _check_progression(loop_start: int) -> void:
	var hud := CanvasLayer.new()
	hud.set_script(load("res://scenes/ui/hud.gd"))
	var column := Control.new()
	column.name = "RightColumn"
	hud.add_child(column)
	var label := Label.new()
	label.name = "wave"
	column.add_child(label)
	root.add_child(hud)
	var spawner = _make_spawner(loop_start)
	for wave_number in range(1, 46):
		_check(_globals.wave == wave_number, "run counter must reach wave %d (loop start %d)" % [wave_number, loop_start])
		_check(label.text == "WAVE\n%d" % wave_number, "HUD must display wave %d (loop start %d)" % [wave_number, loop_start])
		var expected_index := wave_number - 1
		if wave_number > 18:
			expected_index = loop_start + (wave_number - 19) % (18 - loop_start)
		_check(spawner.wave_index == expected_index, "catalog must retain its configured loop at wave %d" % wave_number)
		if wave_number < 45:
			spawner._master.timeout.emit()
	for wave_number in range(44, 0, -1):
		spawner.goto_Previous_Wave()
		_check(_globals.wave == wave_number, "debug previous must return to wave %d (loop start %d)" % [wave_number, loop_start])
	spawner.goto_Previous_Wave()
	_check(_globals.wave == 1, "debug previous must stop at wave one")
	spawner.free()
	hud.free()

func _check_game_over(coop: bool, wave_number: int) -> void:
	_globals.coop = coop
	_globals.saveData.solo = {"hiscore": 1000, "bestWave": 8}
	_globals.saveData.coop = {"hiscore": 2000, "bestWave": 6}
	_globals.wave = wave_number
	_globals.score = 14947
	var other_mode: Dictionary = (_globals.saveData.solo if coop else _globals.saveData.coop).duplicate(true)
	var screen = load("res://scenes/menu/game_over.tscn").instantiate()
	root.add_child(screen)
	var content: Node = screen.get_node("Center/Panel/Margin/Content")
	_check(content.get_node("wave").text == "WAVE : %d" % wave_number, "game over must display the reached wave")
	_check(content.get_node("HigherWave").text == "HIGHEST WAVE : %d" % wave_number, "game over must include the current run in the wave record")
	_check(content.get_node("BestScore").text == "HISCORE : 14947", "game over must include the current run in the score record")
	_check(content.get_node("Score").text == "SCORE : 14947", "game over must retain the run score")
	_check((_globals.saveData.solo if coop else _globals.saveData.coop) == other_mode, "records for the other mode must remain unchanged")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://data.json"))
	var record: Dictionary = saved.coop if coop else saved.solo
	_check(record.bestWave == wave_number and record.hiscore == 14947, "updated records must persist")
	screen.free()
	_globals.wave = 3
	_globals.score = 100
	screen = load("res://scenes/menu/game_over.tscn").instantiate()
	root.add_child(screen)
	content = screen.get_node("Center/Panel/Margin/Content")
	_check(content.get_node("HigherWave").text == "HIGHEST WAVE : %d" % wave_number, "a shorter run must preserve the wave record")
	_check(content.get_node("BestScore").text == "HISCORE : 14947", "a lower score must preserve the score record")
	screen.free()

func _run() -> void:
	_globals = root.get_node("global")
	_globals.Debug = false
	for coop in [false, true]:
		_globals.coop = coop
		_check_progression(17)
		_check_progression(8)
		_check_game_over(coop, 18)
		_check_game_over(coop, 25)
	_globals.wave = 45
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	_check(_globals.wave == 1, "a new run must restart at wave one")
	_check(world.get_node("hud/RightColumn/wave").text == "WAVE\n1", "a new run HUD must restart at wave one")
	world.queue_free()
	await process_frame
	print("Wave progression: %s (%d checks)" % ["PASS" if _failures == 0 else "FAIL", _checks])
	quit(0 if _failures == 0 else 1)

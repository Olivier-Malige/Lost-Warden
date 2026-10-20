extends SceneTree

var _failures := 0
var _main: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)

func _run() -> void:
	root.get_node("global").saveData.config.fullscreen = false
	_main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(_main)
	_main.get_node("loader/Timer").stop()
	_main.get_node("loader").queue_free()
	await process_frame
	_main.go_Start_Screen()
	await process_frame
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(960, 600)
		await create_timer(0.9).timeout
	await _capture("title")
	await _check_hiscore_music()
	await _check_transition("world", _main.go_World_Screen, "start", "game")
	_check(not _main.get_node("TitleMusic").playing, "title music must stop when gameplay starts")
	var catalog = load("res://data/upgrades/foundation_catalog.tres")
	var config = load("res://data/progression/progression_config.tres")
	var random := RandomNumberGenerator.new()
	random.seed = 8
	var build := {"ranks": {}, "offensive_count": 0, "utility_count": 0}
	var hand: Dictionary = catalog.generate_offers(build, {"energy": 3, "shield": 0}, random, config, true)
	_main._open_selection(99, {&"player1": {"build": build, "offers": hand.offers}}, {"level": 2, "xp": 0, "next_threshold": 13})
	_check(paused and _main._selection_pause, "selection must be active before real navigation")
	await _check_transition("gameOver", _main.go_GameOver_Screen, "world", "game_over")
	_check(_main._selection == null and not _main._selection_pause, "real screen navigation must cancel selection and its pending callbacks")
	await _check_transition("start", _main.go_Start_Screen, "gameOver", "return_title")
	_main.queue_free()
	await process_frame
	print("Screen fades: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)

func _check_hiscore_music() -> void:
	var music: AudioStreamPlayer = _main.get_node("TitleMusic")
	await create_timer(0.1).timeout
	var position := music.get_playback_position()
	_check(music.playing and music.stream.loop, "title music must play in a loop")
	_main.go_Hiscore_Screen()
	_main.go_Hiscore_Screen()
	await create_timer(0.1).timeout
	_check(_main.has_node("hiscore") and not _main.has_node("start"), "hiscores must replace the title screen")
	_check(music.playing and music.get_playback_position() > position, "title music must advance without restarting on hiscores")
	position = music.get_playback_position()
	var master_volume := AudioServer.get_bus_volume_db(0)
	_main.go_Start_Screen()
	_check(_main._transitioning, "returning from hiscores must retain the visual fade")
	var deadline := Time.get_ticks_msec() + 3000
	while _main._transitioning and Time.get_ticks_msec() < deadline:
		_check(is_equal_approx(AudioServer.get_bus_volume_db(0), master_volume), "hiscore return must preserve audio volume throughout the visual fade")
		_check(music.playing, "hiscore return must keep title music playing throughout the visual fade")
		await process_frame
	_check(not _main._transitioning, "hiscore return must complete its visual fade")
	await process_frame
	_check(_main.get_node("TitleMusic") == music and music.playing, "returning to the title must retain the same music player")
	_check(music.get_playback_position() > position, "returning from hiscores must not restart title music")

func _check_transition(destination: String, request: Callable, source: String, label: String) -> void:
	var master_volume := AudioServer.get_bus_volume_db(0)
	var music_volume := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	var sounds_volume := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sounds"))
	request.call()
	request.call()
	_check(_main.get("_transitioning"), "transition must lock duplicate requests")
	_check(paused, "combat must pause during a transition")
	_check(_main.has_node(source) and not _main.has_node(destination), "outgoing screen must remain until covered")
	_main.set_Pause()
	_check(not _main.menuShow, "pause input must not open a menu during a fade")
	var cover: ColorRect = _main.get_node("ScreenFade/Black")
	_check(cover.visible and _main.get_node("ScreenFade").layer > 10, "fade must cover the HUD and game over")
	await create_timer(0.15, true).timeout
	_check(cover.color.a > 0.0 and cover.color.a < 1.0, "fade must interpolate instead of cutting")
	_check(AudioServer.get_bus_volume_db(0) < master_volume, "outgoing audio must fade with the image")
	for audio in _main.find_children("*", "AudioStreamPlayer", true, false):
		_check(audio.process_mode == Node.PROCESS_MODE_ALWAYS, "music must continue playing while combat is paused")
	await _capture(label + "_fade_out")
	var deadline := Time.get_ticks_msec() + 3000
	while not _main.has_node(destination) and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(_main.has_node(destination), "destination must be created")
	_check(is_equal_approx(cover.color.a, 1.0), "scene swap must happen under opaque black")
	_check(AudioServer.get_bus_volume_db(0) <= master_volume - 79.0, "scene swap must happen while audio is silent")
	while _main.get("_transitioning") and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not _main.get("_transitioning") and not paused, "transition must finish and resume processing")
	_check(not cover.visible and is_zero_approx(cover.color.a), "fade must leave the new screen uncovered")
	_check(not _main.has_node(source), "outgoing screen must be removed")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(0), master_volume), "audio fade must restore the original master level")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), music_volume), "audio fade must preserve the music mix")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sounds")), sounds_volume), "audio fade must preserve the sound effects mix")
	var default_audio := AudioStreamPlayer.new()
	for audio in _main.get_node(destination).find_children("*", "AudioStreamPlayer", true, false):
		if audio.bus == &"Music":
			_check(audio.process_mode == default_audio.process_mode, "music must recover its normal pause behavior after the fade")
	default_audio.free()
	var count := 0
	for child in _main.get_children():
		if child.name == destination:
			count += 1
	_check(count == 1, "duplicate requests must not create duplicate screens")
	await _capture(label)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_webp("res://.godot/fade_" + label + ".webp")

extends Control

enum {
	OPTION_RETURN, OPTION_CONTROLLER, OPTION_PLAYER1, OPTION_PLAYER2, OPTION_MUSIC, OPTION_SOUND,
	OPTION_RESUME, OPTION_RESTART, OPTION_SOLO, OPTION_COOP, OPTION_OPTIONS, OPTION_HISCORE,
	OPTION_EXIT, OPTION_FULLSCREEN
}
enum {MODE_SOLO, MODE_COOP}
enum {MENU_START, MENU_OPTIONS, MENU_PAUSE, MENU_CONTROLLER}

const CONTROLLERS := ["gamepad1", "gamepad2", "keyboard"]
const BUTTON_GROUP := "Center/Panel/Margin/Content/buttonGroup"
const OPTION_NODES := {
	OPTION_RETURN: BUTTON_GROUP + "/return",
	OPTION_CONTROLLER: BUTTON_GROUP + "/Controller",
	OPTION_PLAYER1: BUTTON_GROUP + "/player1",
	OPTION_PLAYER2: BUTTON_GROUP + "/player2",
	OPTION_MUSIC: BUTTON_GROUP + "/music",
	OPTION_SOUND: BUTTON_GROUP + "/sound",
	OPTION_RESUME: BUTTON_GROUP + "/resume",
	OPTION_RESTART: BUTTON_GROUP + "/restart",
	OPTION_SOLO: BUTTON_GROUP + "/solo",
	OPTION_COOP: BUTTON_GROUP + "/coop",
	OPTION_OPTIONS: BUTTON_GROUP + "/options",
	OPTION_HISCORE: BUTTON_GROUP + "/hiscore",
	OPTION_EXIT: BUTTON_GROUP + "/exit",
	OPTION_FULLSCREEN: BUTTON_GROUP + "/fullscreen",
}

var config = global.saveData.config
var _first_option: Button
var _menu_mode := MENU_START


func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")) and not event.is_echo():
		$sound_switch.playing = true


func _ready() -> void:
	hide()


func set_mode(menu_mode: int) -> void:
	_menu_mode = menu_mode
	var enabled: Array = []
	match menu_mode:
		MENU_START:
			enabled = [OPTION_SOLO, OPTION_COOP, OPTION_OPTIONS, OPTION_HISCORE, OPTION_EXIT]
		MENU_OPTIONS:
			enabled = [OPTION_MUSIC, OPTION_SOUND, OPTION_RETURN, OPTION_CONTROLLER, OPTION_FULLSCREEN]
			_set_toggle(BUTTON_GROUP + "/music", "MUSIC : ", config.music)
			_set_toggle(BUTTON_GROUP + "/sound", "SOUND : ", config.sound)
			_set_toggle(BUTTON_GROUP + "/fullscreen", _fullscreen_label().to_upper(), config.fullscreen)
		MENU_PAUSE:
			enabled = [OPTION_RESUME, OPTION_OPTIONS, OPTION_RESTART, OPTION_EXIT]
		MENU_CONTROLLER:
			enabled = [OPTION_RETURN, OPTION_PLAYER1, OPTION_PLAYER2]
			get_node(BUTTON_GROUP + "/player1").set_text("PLAYER 1 : " + config.player1.to_upper())
			get_node(BUTTON_GROUP + "/player2").set_text("PLAYER 2 : " + config.player2.to_upper())
	_set_presentation(menu_mode)
	_show_options(enabled)


func _show_options(enabled: Array) -> void:
	var first: Button = null
	for option in OPTION_NODES:
		var node: Button = get_node(OPTION_NODES[option])
		var on: bool = option in enabled
		node.visible = on
		node.disabled = true
		node.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
		if on and first == null:
			first = node
	show()
	_first_option = first
	call_deferred("_enable_visible_options")


func _enable_visible_options() -> void:
	for option in OPTION_NODES:
		var node: Button = get_node(OPTION_NODES[option])
		node.disabled = not node.visible
	if _first_option:
		_first_option.grab_focus()


func _set_presentation(menu_mode: int) -> void:
	var title := ""
	var top := 100.0
	var bottom := -100.0
	var exit_label := "EXIT"
	if OS.has_feature("web"):
		exit_label = "RETURN TO TITLE" if menu_mode == MENU_PAUSE else "RETURN TO ITCH.IO"
	get_node(BUTTON_GROUP + "/exit").text = exit_label
	match menu_mode:
		MENU_START:
			top = 410.0
			bottom = -35.0
		MENU_PAUSE:
			top = 320.0
			bottom = -60.0
		MENU_OPTIONS:
			top = 320.0
			bottom = -30.0
			title = "OPTIONS"
		MENU_CONTROLLER:
			top = 320.0
			bottom = -30.0
			title = "CONTROLS"
	$Center.offset_top = top
	$Center.offset_bottom = bottom
	$Center/Panel/Margin/Content/MenuTitle.visible = not title.is_empty()
	$Center/Panel/Margin/Content/MenuLine.visible = not title.is_empty()
	$Center/Panel/Margin/Content/MenuTitle.text = title


func start_game(game_mode: int) -> void:
	global.coop = game_mode != MODE_SOLO
	Events.world_requested.emit()


func _on_Solo_button_down() -> void:
	if await _play_start():
		start_game(MODE_SOLO)


func _on_Coop_button_down() -> void:
	if await _play_start():
		start_game(MODE_COOP)


func _on_Exit_button_down() -> void:
	if OS.has_feature("web"):
		if _menu_mode == MENU_PAUSE:
			Events.start_screen_requested.emit()
			queue_free()
			return
		_release_gameplay_input()
		JavaScriptBridge.eval("""
			const target = document.referrer;
			if (target && target !== window.location.href) {
				window.open(target, '_top');
			} else if (document.fullscreenElement) {
				document.exitFullscreen();
			}
		""")
		config.fullscreen = false
		get_window().mode = Window.MODE_WINDOWED
		global.save_Data()
		return
	get_tree().quit()


func _on_Resume_button_down() -> void:
	Events.resume_requested.emit()
	queue_free()


func _on_Restart_button_down() -> void:
	Events.restart_requested.emit()
	queue_free()


func _on_Hiscore_button_down() -> void:
	await _play_select()
	Events.hiscore_requested.emit()
	queue_free()


func _on_options_button_down() -> void:
	await _play_select()
	set_mode(MENU_OPTIONS)


func _on_return_button_down() -> void:
	await _play_select()
	var game := get_tree().get_first_node_in_group("game")
	if game.worldScreen:
		set_mode(MENU_PAUSE)
	elif game.startScreen:
		set_mode(MENU_START)


func _on_sound_button_down() -> void:
	config.sound = not config.sound
	_set_toggle(BUTTON_GROUP + "/sound", "SOUND : ", config.sound)
	global.setSound(config.sound)
	global.save_Data()


func _on_music_button_down() -> void:
	config.music = not config.music
	_set_toggle(BUTTON_GROUP + "/music", "MUSIC : ", config.music)
	global.setMusic(config.music)
	global.save_Data()


func _on_Controller_button_down() -> void:
	await _play_select()
	set_mode(MENU_CONTROLLER)


func _on_fullscreen_button_down() -> void:
	_release_gameplay_input()
	config.fullscreen = not config.fullscreen
	get_window().mode = Window.MODE_FULLSCREEN if config.fullscreen else Window.MODE_WINDOWED
	_set_toggle(BUTTON_GROUP + "/fullscreen", _fullscreen_label().to_upper(), config.fullscreen)
	global.save_Data()
	call_deferred("_release_gameplay_input")


func _on_player1_button_down() -> void:
	_cycle_controller(1)


func _on_player2_button_down() -> void:
	_cycle_controller(2)


func _cycle_controller(player: int) -> void:
	var key := "player%d" % player
	var other := "player%d" % (2 if player == 1 else 1)
	config[key] = _next_controller(config[key])
	if config[key] == config[other]:
		config[key] = _next_controller(config[key])
	get_node(BUTTON_GROUP + "/" + key).set_text("PLAYER %d : %s" % [player, config[key].to_upper()])
	global.save_Data()


func _next_controller(current: String) -> String:
	return CONTROLLERS[(CONTROLLERS.find(current) + 1) % CONTROLLERS.size()]


func _set_toggle(path: String, prefix: String, on: bool) -> void:
	get_node(path).set_text(prefix + ("ON" if on else "OFF"))


func _fullscreen_label() -> String:
	return "BROWSER FULLSCREEN : " if OS.has_feature("web") else "FULLSCREEN : "


func _release_gameplay_input() -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("release_gameplay_input"):
		game.release_gameplay_input()


func _play_start() -> bool:
	if $sound_start.is_playing():
		return false
	$sound_start.playing = true
	await $sound_start.finished
	return true


func _play_select() -> void:
	$sound_select.playing = true
	await $sound_select.finished

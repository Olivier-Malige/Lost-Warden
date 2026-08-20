extends Control

enum {
	OPTION_RETURN, OPTION_CONTROLLER, OPTION_PLAYER1, OPTION_PLAYER2, OPTION_MUSIC, OPTION_SOUND,
	OPTION_RESUME, OPTION_RESTART, OPTION_SOLO, OPTION_COOP, OPTION_OPTIONS, OPTION_HISCORE,
	OPTION_EXIT, OPTION_FULLSCREEN, OPTION_GRAPHIC
}
enum {MODE_SOLO, MODE_COOP}
enum {MENU_START, MENU_OPTIONS, MENU_PAUSE, MENU_CONTROLLER}

const CONTROLLERS := ["gamepad1", "gamepad2", "keyboard"]
const OPTION_NODES := {
	OPTION_RETURN: "buttonGroup/return",
	OPTION_CONTROLLER: "buttonGroup/Controller",
	OPTION_PLAYER1: "buttonGroup/player1",
	OPTION_PLAYER2: "buttonGroup/player2",
	OPTION_MUSIC: "buttonGroup/music",
	OPTION_SOUND: "buttonGroup/sound",
	OPTION_RESUME: "buttonGroup/resume",
	OPTION_RESTART: "buttonGroup/restart",
	OPTION_SOLO: "buttonGroup/solo",
	OPTION_COOP: "buttonGroup/coop",
	OPTION_OPTIONS: "buttonGroup/options",
	OPTION_HISCORE: "buttonGroup/hiscore",
	OPTION_EXIT: "buttonGroup/exit",
	OPTION_FULLSCREEN: "buttonGroup/fullscreen",
	OPTION_GRAPHIC: "buttonGroup/graphic",
}

var config = global.saveData.config


func _input(event):
	if (event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")) and not event.is_echo():
		$sound_switch.playing = true


func _ready():
	hide()
	$optionTimer.process_mode = Node.PROCESS_MODE_ALWAYS


func set_mode(menu_mode):
	var enabled: Array = []
	match menu_mode:
		MENU_START:
			enabled = [OPTION_SOLO, OPTION_COOP, OPTION_OPTIONS, OPTION_HISCORE, OPTION_EXIT]
		MENU_OPTIONS:
			enabled = [OPTION_MUSIC, OPTION_SOUND, OPTION_RETURN, OPTION_CONTROLLER, OPTION_FULLSCREEN, OPTION_GRAPHIC]
			_set_toggle("buttonGroup/music", "music : ", config.music)
			_set_toggle("buttonGroup/sound", "sound : ", config.sound)
			_set_toggle("buttonGroup/fullscreen", "fullscreen : ", config.fullscreen)
			get_node("buttonGroup/graphic").set_text("graphic : " + config.graphic)
		MENU_PAUSE:
			enabled = [OPTION_RESUME, OPTION_OPTIONS, OPTION_RESTART, OPTION_EXIT]
		MENU_CONTROLLER:
			enabled = [OPTION_RETURN, OPTION_PLAYER1, OPTION_PLAYER2]
			$buttonGroup/player1.set_text("player 1 : " + config.player1)
			$buttonGroup/player2.set_text("player 2 : " + config.player2)
	_show_options(enabled)


func _show_options(enabled: Array = []) -> void:
	var first: Control = null
	for option in OPTION_NODES:
		var node: Control = get_node(OPTION_NODES[option])
		var on: bool = option in enabled
		node.visible = on
		node.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
		if on:
			node.size.x = 800
			if first == null:
				first = node
	$buttonGroup.size = Vector2(800, 0)
	show()
	if first:
		first.grab_focus()


func start_game(game_mode):
	global.coop = game_mode != MODE_SOLO
	Events.world_requested.emit()


func _on_Solo_button_down():
	if await _play_start():
		start_game(MODE_SOLO)


func _on_Coop_button_down():
	if await _play_start():
		start_game(MODE_COOP)


func _on_Exit_button_down():
	get_tree().quit()


func _on_Resume_button_down():
	if await _play_start():
		Events.resume_requested.emit()
		queue_free()


func _on_Restart_button_down():
	if await _play_start():
		Events.restart_requested.emit()
		queue_free()


func _on_Hiscore_button_down():
	await _play_select()
	Events.hiscore_requested.emit()
	queue_free()


func _on_options_button_down():
	await _play_select()
	set_mode(MENU_OPTIONS)


func _on_return_button_down():
	await _play_select()
	var game := get_tree().get_first_node_in_group("game")
	if game.worldScreen:
		set_mode(MENU_PAUSE)
	elif game.startScreen:
		set_mode(MENU_START)


func _on_sound_button_down():
	config.sound = not config.sound
	_set_toggle("buttonGroup/sound", "Sound : ", config.sound)
	global.setSound(config.sound)
	global.save_Data()


func _on_music_button_down():
	config.music = not config.music
	_set_toggle("buttonGroup/music", "Music : ", config.music)
	global.setMusic(config.music)
	global.save_Data()


func _on_Controller_button_down():
	await _play_select()
	set_mode(MENU_CONTROLLER)


func _on_fullscreen_button_down():
	config.fullscreen = not config.fullscreen
	get_window().mode = Window.MODE_FULLSCREEN if config.fullscreen else Window.MODE_WINDOWED
	_set_toggle("buttonGroup/fullscreen", "fullscreen : ", config.fullscreen)
	global.save_Data()


func _on_player1_button_down():
	_cycle_controller(1)


func _on_player2_button_down():
	_cycle_controller(2)


func _on_graphic_button_down():
	config.graphic = "low" if config.graphic == "high" else "high"
	$buttonGroup/graphic.set_text("graphic : " + config.graphic)
	Events.graphic_changed.emit(config.graphic)
	global.save_Data()


func _cycle_controller(player: int) -> void:
	var key := "player%d" % player
	var other := "player%d" % (2 if player == 1 else 1)
	config[key] = _next_controller(config[key])
	if config[key] == config[other]:
		config[key] = _next_controller(config[key])
	$buttonGroup.get_node(key).set_text("player %d : %s" % [player, config[key]])
	global.save_Data()


func _next_controller(current: String) -> String:
	return CONTROLLERS[(CONTROLLERS.find(current) + 1) % CONTROLLERS.size()]


func _set_toggle(path: String, prefix: String, on: bool) -> void:
	get_node(path).set_text(prefix + ("on" if on else "off"))


func _play_start() -> bool:
	if $sound_start.is_playing():
		return false
	$sound_start.playing = true
	await $sound_start.finished
	return true


func _play_select() -> void:
	$sound_select.playing = true
	await $sound_select.finished

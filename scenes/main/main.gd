extends Node
var startScreen := false
var worldScreen := false
var gameOverScreen := false
var menu = load("res://scenes/menu/menu.tscn")
var paused = load("res://scenes/ui/paused.tscn")

var menuShow := false
var _game_over_input_ready_at := 0
var _transitioning := false
var _fade_audio_volume_db := 0.0
var _fade_audio_modes: Dictionary[int, int] = {}
var _debug_screen: CanvasLayer
var _debug_full_open := false
var _debug_compact_enabled := true
var _debug_pause_owned := false
const FADE_DURATION := 0.3
@onready var _screen_fade: ColorRect = $ScreenFade/Black
@onready var _title_music: AudioStreamPlayer = $TitleMusic
const PLAYER_CHEATS := {
	"debug_Key3": "increase_Speed",
	"debug_Key4": "increase_Shot",
	"debug_Key5": "increase_SideShot",
	"debug_Key6": "increase_Shield",
	"debug_Key7": "debug_increase_fire_rate",
	"debug_Key8": "debug_add_plasma",
	"debug_Key9": "debug_max_stats",
}
const PLAYER_INPUT_ACTIONS := [
	"all_up", "all_down", "all_left", "all_right", "all_fire", "all_beam",
	"keyboard_up", "keyboard_down", "keyboard_left", "keyboard_right", "keyboard_fire", "keyboard_beam",
	"gamepad1_up", "gamepad1_down", "gamepad1_left", "gamepad1_right", "gamepad1_fire", "gamepad1_beam",
	"gamepad2_up", "gamepad2_down", "gamepad2_left", "gamepad2_right", "gamepad2_fire", "gamepad2_beam",
]

func _ready() -> void:
	add_to_group("game")
	_title_music.stream.loop = true
	if OS.has_feature("web"):
		global.saveData.config.fullscreen = get_window().mode == Window.MODE_FULLSCREEN
		get_window().size_changed.connect(_on_window_size_changed)
	else:
		get_window().mode = Window.MODE_FULLSCREEN if global.saveData.config.fullscreen else Window.MODE_WINDOWED
	set_process_mode(PROCESS_MODE_ALWAYS)
	Events.world_requested.connect(go_World_Screen)
	Events.hiscore_requested.connect(go_Hiscore_Screen)
	Events.start_screen_requested.connect(go_Start_Screen)
	Events.resume_requested.connect(set_Resume)
	Events.restart_requested.connect(set_Restart)
	Events.game_over_requested.connect(go_GameOver_Screen)


func _input(event: InputEvent) -> void:
	if _transitioning:
		get_viewport().set_input_as_handled()
		return
	if worldScreen:
		if global.Debug and event.is_action_pressed("debug_screen") and not event.is_echo():
			_set_debug_full(not _debug_full_open)
			get_viewport().set_input_as_handled()
			return
		if global.Debug and event.is_action_pressed("debug_compact") and not event.is_echo():
			_debug_compact_enabled = not _debug_compact_enabled
			_update_debug_view()
			get_viewport().set_input_as_handled()
			return
		if _debug_full_open:
			if event is InputEventMouse:
				return
			if event is InputEventKey:
				_debug_screen.handle_key(event)
			if _debug_full_open and event.is_action_pressed("start") and not event.is_echo():
				_set_debug_full(false)
			get_viewport().set_input_as_handled()
			return
		if not menuShow and event.is_action_pressed("start") and not event.is_echo():
			set_Pause()
			get_viewport().set_input_as_handled()
		if global.Debug:
			_debug_cheats(event)
	if gameOverScreen:
		if Time.get_ticks_msec() >= _game_over_input_ready_at and event.is_action_pressed("start") and not event.is_echo():
			go_Start_Screen()

func _update_debug_view() -> void:
	if not is_instance_valid(_debug_screen):
		if not global.Debug or not worldScreen:
			return
		_debug_screen = load("res://scenes/debug/debug_screen.tscn").instantiate()
		add_child(_debug_screen)
		_debug_screen.close_requested.connect(func(): _set_debug_full(false))
		_debug_screen.debug_disabled.connect(_hide_debug)
	_debug_screen.set_view(_debug_compact_enabled and worldScreen, _debug_full_open)

# Only release a pause acquired by the inspector; an existing menu pause belongs to screen flow.
func _set_debug_full(open: bool) -> void:
	if open == _debug_full_open:
		return
	release_gameplay_input()
	if open:
		_debug_pause_owned = not get_tree().paused
		get_tree().paused = true
	elif _debug_pause_owned:
		get_tree().paused = false
		_debug_pause_owned = false
	_debug_full_open = open
	_update_debug_view()

func _hide_debug() -> void:
	_set_debug_full(false)
	if is_instance_valid(_debug_screen):
		_debug_screen.set_view(false, false)

func _debug_cheats(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("debug_Key1"):
		$world/waveGenerator.goto_Previous_Wave()
	elif event.is_action_pressed("debug_Key2"):
		$world/waveGenerator.goto_Next_Wave()
	elif event.is_action_pressed("debug_next_wave"):
		$world/waveGenerator.debug_skip_encounter()
	elif event.is_action_pressed("debug_boss"):
		$world/waveGenerator.debug_start_boss()
	else:
		for action in PLAYER_CHEATS:
			if event.is_action_pressed(action):
				_call_players(PLAYER_CHEATS[action])
				return

func _call_players(method: StringName) -> void:
	for path in ["world/player", "world/player2"]:
		if has_node(path):
			get_node(path).call(method)

func _on_Timer_timeout() -> void:
	$loader.queue_free()
	go_Start_Screen()

func set_Pause() -> void:
	if _transitioning:
		return
	if not menuShow:
		_set_debug_full(false)
		get_tree().paused = true
		var p = paused.instantiate()
		add_child(p)
		var m = menu.instantiate()
		add_child(m)
		m.set_mode(m.MENU_PAUSE)
		menuShow = true
		# Parallax layers otherwise draw over the pause overlay.
		_set_world_background(false)

func set_Restart() -> void:
	if _transitioning:
		return
	menuShow = false
	release_gameplay_input()
	get_tree().paused = false
	get_tree().reload_current_scene()

func set_Resume() -> void:
	if _transitioning:
		return
	if worldScreen and menuShow:
		_set_debug_full(false)
		menuShow = false
		release_gameplay_input()
		var pause_overlay := get_node_or_null("paused")
		if pause_overlay:
			pause_overlay.queue_free()
		get_tree().paused = false
		_set_world_background(true)
		_call_players("update_controller")

func go_Start_Screen() -> void:
	if _transitioning or (startScreen and has_node("start")):
		return
	if worldScreen or gameOverScreen or has_node("hiscore"):
		await _fade_to(_show_start_screen, not has_node("hiscore"))
	else:
		_show_start_screen()

func _show_start_screen() -> void:
	menuShow = false
	get_tree().paused = false
	release_gameplay_input()
	for node_name in ["world", "paused", "gameOver", "hiscore"]:
		var current_screen := get_node_or_null(node_name)
		if current_screen:
			current_screen.queue_free()
	worldScreen = false
	startScreen = true
	gameOverScreen = false
	_set_title_stars(true)
	var start = preload("res://scenes/menu/start.tscn").instantiate()
	add_child(start)
	if not _title_music.playing:
		_title_music.play()


func release_gameplay_input() -> void:
	for action in PLAYER_INPUT_ACTIONS:
		Input.action_release(action)
	_call_players("reset_weapon_input")


func _on_window_size_changed() -> void:
	release_gameplay_input()


func go_Hiscore_Screen() -> void:
	if _transitioning or not startScreen:
		return
	startScreen = false
	var hiscore = preload("res://scenes/menu/hi_score.tscn").instantiate()
	add_child(hiscore)
	$start.queue_free()


func go_World_Screen() -> void:
	if _transitioning or worldScreen:
		return
	await _fade_to(_show_world_screen)

func _show_world_screen() -> void:
	_title_music.stop()
	_set_title_stars(false)
	var world = preload("res://scenes/world/world.tscn").instantiate()
	add_child(world)
	worldScreen = true
	startScreen = false
	gameOverScreen = false
	if has_node("start"):
		$start.queue_free()
	_update_debug_view()


func _set_title_stars(on: bool) -> void:
	var stars := get_node_or_null("Stars")
	if stars:
		stars.visible = on
		stars.emitting = on

func _set_world_background(on: bool) -> void:
	for layer in $world.get_node("background").get_children():
		layer.visible = on

func go_GameOver_Screen() -> void:
	if _transitioning or (gameOverScreen and has_node("gameOver")):
		return
	await _fade_to(_show_game_over_screen)

func _show_game_over_screen() -> void:
	get_tree().paused = false
	menuShow = false
	release_gameplay_input()
	gameOverScreen = true
	_game_over_input_ready_at = Time.get_ticks_msec() + 750
	worldScreen = false
	startScreen = false
	var pause_overlay := get_node_or_null("paused")
	if pause_overlay:
		pause_overlay.queue_free()
	var current_world := get_node_or_null("world")
	if current_world:
		_set_world_background(false)
		current_world.visible = false
		current_world.process_mode = Node.PROCESS_MODE_DISABLED
		var hud := current_world.get_node_or_null("hud")
		if hud:
			hud.visible = false
		current_world.queue_free()
	var game_over_layer := CanvasLayer.new()
	game_over_layer.name = "gameOver"
	game_over_layer.layer = 10
	add_child(game_over_layer)
	var game_over = preload("res://scenes/menu/game_over.tscn").instantiate()
	game_over.name = "Overlay"
	game_over_layer.add_child(game_over)
	game_over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# Swap screens only under an opaque cover, and keep combat stopped until the reveal ends.
func _fade_to(show_screen: Callable, fade_audio := true) -> void:
	_hide_debug()
	_transitioning = true
	_fade_audio_volume_db = AudioServer.get_bus_volume_db(0)
	_keep_transition_audio_running()
	release_gameplay_input()
	get_viewport().gui_release_focus()
	get_tree().paused = true
	_screen_fade.show()
	var fade_out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	fade_out.tween_property(_screen_fade, "color:a", 1.0, FADE_DURATION).set_trans(Tween.TRANS_SINE)
	if fade_audio:
		fade_out.tween_method(_set_fade_audio_volume, 1.0, 0.0, FADE_DURATION).set_trans(Tween.TRANS_SINE)
	await fade_out.finished
	show_screen.call()
	_keep_transition_audio_running()
	get_tree().paused = true
	await get_tree().process_frame
	var fade_in := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	fade_in.tween_property(_screen_fade, "color:a", 0.0, FADE_DURATION).set_trans(Tween.TRANS_SINE)
	if fade_audio:
		fade_in.tween_method(_set_fade_audio_volume, 0.0, 1.0, FADE_DURATION).set_trans(Tween.TRANS_SINE)
	await fade_in.finished
	_screen_fade.hide()
	release_gameplay_input()
	get_tree().paused = false
	_restore_transition_audio()
	_transitioning = false

# Audio must keep playing while combat is paused so it can fade instead of cutting off.
func _keep_transition_audio_running() -> void:
	var players := find_children("*", "AudioStreamPlayer", true, false)
	players.append_array(find_children("*", "AudioStreamPlayer2D", true, false))
	for player in players:
		var id := player.get_instance_id()
		if not _fade_audio_modes.has(id):
			_fade_audio_modes[id] = player.process_mode
			player.process_mode = Node.PROCESS_MODE_ALWAYS

func _set_fade_audio_volume(level: float) -> void:
	AudioServer.set_bus_volume_db(0, _fade_audio_volume_db + linear_to_db(maxf(level, 0.0001)))

func _restore_transition_audio() -> void:
	AudioServer.set_bus_volume_db(0, _fade_audio_volume_db)
	for id in _fade_audio_modes:
		var player := instance_from_id(id) as Node
		if is_instance_valid(player):
			player.process_mode = _fade_audio_modes[id] as Node.ProcessMode
	_fade_audio_modes.clear()

func _exit_tree() -> void:
	if _debug_pause_owned:
		get_tree().paused = false
	if _transitioning:
		_restore_transition_audio()

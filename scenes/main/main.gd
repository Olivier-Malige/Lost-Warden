extends Node
var startScreen := false
var worldScreen := false
var gameOverScreen := false
var menu = load("res://scenes/menu/menu.tscn")
var paused = load("res://scenes/ui/paused.tscn")

var menuShow := false
var _game_over_input_ready_at := 0
const PLAYER_CHEATS := {
	"debug_Key3": "increase_Speed",
	"debug_Key4": "increase_Shot",
	"debug_Key5": "increase_SideShot",
	"debug_Key6": "increase_Shield",
	"debug_Key7": "debug_increase_fire_rate",
	"debug_Key8": "debug_increase_beam",
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
	set_Graphic(global.saveData.config.graphic)
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
	Events.graphic_changed.connect(set_Graphic)


func _input(event: InputEvent) -> void:
	if worldScreen:
		if not menuShow and event.is_action_pressed("start") and not event.is_echo():
			set_Pause()
			get_viewport().set_input_as_handled()
		if global.Debug:
			_debug_cheats(event)
	if gameOverScreen:
		if Time.get_ticks_msec() >= _game_over_input_ready_at and event.is_action_pressed("start") and not event.is_echo():
			go_Start_Screen()

func _debug_cheats(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("debug_Key1"):
		$world/waveGenerator.goto_Previous_Wave()
	elif event.is_action_pressed("debug_Key2"):
		$world/waveGenerator.goto_Next_Wave()
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
	if not menuShow:
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
	menuShow = false
	release_gameplay_input()
	get_tree().paused = false
	get_tree().reload_current_scene()

func set_Resume() -> void:
	if worldScreen and menuShow:
		menuShow = false
		release_gameplay_input()
		var pause_overlay := get_node_or_null("paused")
		if pause_overlay:
			pause_overlay.queue_free()
		get_tree().paused = false
		_set_world_background(true)
		_call_players("update_controller")

func go_Start_Screen() -> void:
	menuShow = false
	get_tree().paused = false
	release_gameplay_input()
	for node_name in ["world", "paused", "gameOver"]:
		var current_screen := get_node_or_null(node_name)
		if current_screen:
			current_screen.queue_free()
	worldScreen = false
	startScreen = true
	gameOverScreen = false
	_set_title_stars(true)
	var start = preload("res://scenes/menu/start.tscn").instantiate()
	add_child(start)


func release_gameplay_input() -> void:
	for action in PLAYER_INPUT_ACTIONS:
		Input.action_release(action)
	_call_players("reset_weapon_input")


func _on_window_size_changed() -> void:
	release_gameplay_input()


func go_Hiscore_Screen() -> void:
	startScreen = false
	var hiscore = preload("res://scenes/menu/hi_score.tscn").instantiate()
	add_child(hiscore)
	$start.queue_free()


func go_World_Screen() -> void:
	_set_title_stars(false)
	var world = preload("res://scenes/world/world.tscn").instantiate()
	add_child(world)
	worldScreen = true
	startScreen = false
	gameOverScreen = false
	if has_node("start"):
		$start.queue_free()


func _set_title_stars(on: bool) -> void:
	var stars := get_node_or_null("Stars")
	if stars:
		stars.visible = on
		stars.emitting = on

func _set_world_background(on: bool) -> void:
	for layer in $world.get_node("background").get_children():
		layer.visible = on

func go_GameOver_Screen() -> void:
	if gameOverScreen and has_node("gameOver"):
		return
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

func set_Graphic(level: String) -> void:
	_set_title_stars(level == "high")

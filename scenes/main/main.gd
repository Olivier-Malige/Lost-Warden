extends Node
var startScreen := false
var worldScreen := false
var gameOverScreen := false
var menu = load("res://scenes/menu/menu.tscn")
var paused = load("res://scenes/ui/paused.tscn")

var menuShow := false
const ZOOM_OUT := Vector2(0.6, 0.6)
const ZOOM_IN := Vector2(1.0, 1.0)
const PLAYER_CHEATS := {
	"debug_Key3": "increase_Speed",
	"debug_Key4": "increase_Shot",
	"debug_Key5": "increase_SideShot",
	"debug_Key6": "increase_Shield",
}
var _camera_tween: Tween

func _ready() -> void:
	add_to_group("game")
	set_Graphic(global.saveData.config.graphic)
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
		if event.is_action_pressed("start") and not event.is_echo():
			set_Pause()
		if global.Debug:
			_debug_cheats(event)
	if gameOverScreen:
		if event.is_action_pressed("start") and not event.is_echo():
			go_Start_Screen()
			gameOverScreen = false
			$gameOver.queue_free()

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
	set_Resume()
	get_tree().reload_current_scene()

func set_Resume() -> void:
	if worldScreen:
		menuShow = false
		$paused.queue_free()
		get_tree().paused = false
		_set_world_background(true)
		_call_players("update_controller")

func go_Start_Screen() -> void:
	worldScreen = false
	startScreen = true
	_set_title_stars(true)
	_tween_camera($camera_Pos_Out.position, ZOOM_OUT, 1.1)
	var start = preload("res://scenes/menu/start.tscn").instantiate()
	add_child(start)


func go_Hiscore_Screen() -> void:
	startScreen = false
	var hiscore = preload("res://scenes/menu/hi_score.tscn").instantiate()
	add_child(hiscore)
	$start.queue_free()


func go_World_Screen() -> void:
	_set_title_stars(false)
	_tween_camera($camera_Pos_In.position, ZOOM_IN, 1.15)
	var world = preload("res://scenes/world/world.tscn").instantiate()
	add_child(world)
	worldScreen = true
	startScreen = false
	gameOverScreen = false
	if has_node("start"):
		$start.queue_free()


# Title starfield sits behind the TV sprite so it cannot cover the frame or console.
func _set_title_stars(on: bool) -> void:
	var stars := get_node_or_null("background/Stars")
	if stars:
		stars.visible = on
		stars.emitting = on

func _set_world_background(on: bool) -> void:
	for layer in $world.get_node("background").get_children():
		layer.visible = on

func _tween_camera(target_pos: Vector2, target_zoom: Vector2, duration: float) -> void:
	if _camera_tween:
		_camera_tween.kill()
	if $Camera2D.position.is_equal_approx(target_pos) and $Camera2D.zoom.is_equal_approx(target_zoom):
		return
	_camera_tween = create_tween().set_parallel(true)
	_camera_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property($Camera2D, "position", target_pos, duration)
	_camera_tween.tween_property($Camera2D, "zoom", target_zoom, duration)


func go_GameOver_Screen() -> void:
	gameOverScreen = true
	worldScreen = false
	var gameOver = preload("res://scenes/menu/game_over.tscn").instantiate()
	add_child(gameOver)

func set_Graphic(level: String) -> void:
	var high := level == "high"
	for ch in $background/Lights.get_children():
		ch.visible = high
	_set_title_stars(high)

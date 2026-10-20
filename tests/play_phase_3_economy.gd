extends SceneTree

var globals: Node
var events: Node
var main: Node
var world: Node
var seed_value := 0
var smoke := false
var choices := 0
var ended := false
var evidence := {}
var output_path := ""
var original_settings := {}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			seed_value = maxi(argument.trim_prefix("--seed=").to_int(), 0)
		elif argument == "--smoke":
			smoke = true
	globals.Debug = false
	globals.coop = false
	original_settings = {"fullscreen": globals.saveData.config.fullscreen, "player1": globals.saveData.config.player1}
	globals.saveData.config.fullscreen = false
	globals.saveData.config.player1 = "keyboard"
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.get_node("loader/Timer").stop()
	main.get_node("loader").free()
	events.player_died.connect(func(): finish("death"))
	main._show_world_screen()
	world = main.get_node("world")
	# World initializes a random run in _ready; replace it before its deferred spawner starts.
	globals.reset_run(seed_value)
	world.progression.start(world.progression.players, globals.run_random.upgrades)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	root.title = "Lost Warden - solo XP / seed %d" % seed_value
	auto_accept_quit = false
	root.close_requested.connect(func():
		finish("closed-early")
		quit()
	)
	evidence = {"kind": "technical-smoke" if smoke else "real-solo-playtest", "seed": seed_value,
		"godot": Engine.get_version_info().string, "selections": [], "choice_requests": [], "choices": [],
		"status": "in-progress", "feedback": {"xp_recovery": null, "useful_choices": null,
		"selection_readability": null, "overall_rhythm": null}}
	output_path = "user://phase_3_solo_%d_%d.json" % [seed_value, Time.get_unix_time_from_system()]
	events.upgrade_selection_requested.connect(on_selection)
	events.upgrade_choice_requested.connect(on_choice)
	events.upgrade_choice_applied.connect(on_choice_applied)
	events.restart_requested.connect(func(): finish("restarted"))
	events.start_screen_requested.connect(func(): finish("returned-to-title"))
	write_evidence()
	print("Solo economy playtest, seed %d. Keyboard input; normal combat and damage." % seed_value)
	print("Evidence: %s" % ProjectSettings.globalize_path(output_path))
	main.set_Pause()
	for frame in 3:
		await process_frame
	if smoke:
		var valid: bool = globals.run_random.run_seed == seed_value and world.get_node("waveGenerator").director.random == globals.run_random and world.progression._random == globals.run_random.upgrades and paused and is_zero_approx(globals.survival_time)
		restore_settings()
		for key in original_settings:
			valid = valid and globals.saveData.config[key] == original_settings[key]
		evidence.status = "smoke-passed" if valid else "smoke-failed"
		write_evidence()
		print("Seeded playtest smoke: %s" % ("PASS" if valid else "FAIL"))
		main.free()
		paused = false
		await process_frame
		quit(0 if valid else 1)
		return
	while not ended:
		await process_frame
		if globals.survival_time >= 300.0:
			finish("five-minutes")

func on_selection(_id: int, _participants: Dictionary, progression: Dictionary) -> void:
	if ended:
		return
	evidence.selections.append({"time": globals.survival_time, "level": progression.selection_level})
	write_evidence()

func on_choice(_id: int, player_id: StringName, upgrade_id: StringName) -> void:
	if not ended:
		evidence.choice_requests.append({"time": globals.survival_time, "player": String(player_id), "upgrade": String(upgrade_id)})
		write_evidence()

func on_choice_applied(_id: int, player_id: StringName) -> void:
	if ended:
		return
	choices += 1
	evidence.choices.append({"time": globals.survival_time, "player": String(player_id)})
	write_evidence()
	if choices >= 5:
		call_deferred("finish", "five-choices")

func finish(reason: String) -> void:
	if ended:
		return
	ended = true
	evidence.status = reason
	evidence.completed_choices = choices
	write_evidence()
	restore_settings()
	print("Solo sample complete: %s at %.2f simulation seconds; maintainer feedback is still required." % [reason, globals.survival_time])
	if reason in ["five-choices", "five-minutes"]:
		main.call_deferred("set_Pause")

func restore_settings() -> void:
	for key in original_settings:
		globals.saveData.config[key] = original_settings[key]

func write_evidence() -> void:
	evidence.elapsed = globals.survival_time
	if is_instance_valid(world) and is_instance_valid(world.progression):
		evidence.progression = world.progression.progression.snapshot()
		evidence.pool = world.progression.pool.snapshot()
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	output.store_string(JSON.stringify(evidence, "\t"))

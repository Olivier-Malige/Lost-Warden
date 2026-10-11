extends SceneTree

var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)

func _run() -> void:
	var player := Area2D.new()
	root.add_child(player)
	player.add_to_group("player")
	var expected := {
		"speed": ["sound_Speed_Up", "powers-speed_up.wav"],
		"energy": ["sound_Energy_Up", "powers_health_up.wav"],
		"side_shot": ["sound_Lateral_Shot", "powers-side_shots_up.wav"],
		"damage": ["sound_Shot_Up", "powers-lazer_up.wav"],
		"shield": ["sound_Shield", "powers-shield_up.wav"],
		"fire_rate": ["sound_Shot_Up", "powers-lazer_up.wav"],
	}
	for id in expected:
		var pickup = load("res://scenes/ui/power_up.tscn").instantiate()
		root.add_child(pickup)
		pickup.set_physics_process(false)
		var upgrade = load("res://data/upgrades/" + id + ".tres")
		pickup.set("_upgrade", upgrade)
		pickup.get_node("anim").play(String(upgrade.anim))
		pickup.call("_on_powerUp_area_entered", player)
		var sound: AudioStreamPlayer2D = pickup.get_node(expected[id][0])
		_check(sound.playing, id + " collection must start its pickup sound")
		_check(sound.stream.resource_path == "res://assets/audio/sfx/pickups/" + expected[id][1], id + " must use the matching sample")
		for other in pickup.find_children("*", "AudioStreamPlayer2D", false, false):
			_check(other == sound or not other.playing, id + " must not start another bonus sound")
		sound.stop()
		await process_frame
		pickup.free()
	var cell = load("res://scenes/ui/plasma_cell.tscn").instantiate()
	root.add_child(cell)
	cell.call("_on_area_entered", player)
	var beam_sound: AudioStreamPlayer2D = cell.get_node("PickupSound")
	_check(beam_sound.playing, "plasma collection must start the beam pickup sound")
	_check(beam_sound.stream.resource_path == "res://assets/audio/sfx/pickups/powers_plasma_energy_up.wav", "beam recharge must use plasma_energy_up, never speed_up")
	beam_sound.stop()
	await process_frame
	cell.free()
	player.free()
	await _check_queue()
	print("pickup audio: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)

func _check_queue() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var player := Area2D.new()
	stage.add_child(player)
	player.add_to_group("player")
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_8_BITS
	clip.mix_rate = 8000
	var samples := PackedByteArray()
	samples.resize(800)
	clip.data = samples
	var completion_order: Array[int] = []
	var pickups: Array[Node] = []
	var sounds: Array[AudioStreamPlayer2D] = []
	for i in range(3):
		var is_plasma := i == 1
		var path := "res://scenes/ui/plasma_cell.tscn" if is_plasma else "res://scenes/ui/power_up.tscn"
		var pickup = load(path).instantiate()
		stage.add_child(pickup)
		pickup.set_physics_process(false)
		var sound: AudioStreamPlayer2D
		if is_plasma:
			sound = pickup.get_node("PickupSound")
		else:
			pickup.set("_upgrade", load("res://data/upgrades/speed.tres"))
			sound = pickup.get_node("sound_Speed_Up")
		sound.stream = clip
		sound.finished.connect(func(): completion_order.append(i))
		pickup.call("_on_area_entered" if is_plasma else "_on_powerUp_area_entered", player)
		pickups.append(pickup)
		sounds.append(sound)
		_check(pickup.get("_collected"), "queued audio must not delay pickup collection")
	_check(sounds[0].playing, "the first collected bonus must play immediately")
	_check(not sounds[1].playing and not sounds[2].playing, "later bonuses must wait, including plasma")
	var deadline := Time.get_ticks_msec() + 3000
	while completion_order.size() < 3 and Time.get_ticks_msec() < deadline:
		var playing := 0
		for sound in sounds:
			if is_instance_valid(sound) and sound.playing:
				playing += 1
		_check(playing <= 1, "pickup sounds must never overlap")
		await process_frame
	_check(completion_order == [0, 1, 2], "pickup sounds must finish in collection order")
	await process_frame
	for pickup in pickups:
		_check(not is_instance_valid(pickup), "finished pickups must be freed")
	stage.free()

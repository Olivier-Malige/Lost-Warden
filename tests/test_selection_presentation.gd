extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var music := AudioStreamPlayer.new()
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 8000
	var samples := PackedByteArray()
	samples.resize(32000)
	stream.data = samples
	music.stream = stream
	music.bus = &"Music"
	root.add_child(music)
	music.play(0.5)
	await create_timer(0.05).timeout
	var before := music.get_playback_position()
	var audio := UpgradeSelectionAudio.new()
	root.add_child(audio)
	audio.begin(music)
	check(music.stream_paused and audio.session_count == 1, "local audio must pause the same gameplay player")
	paused = true
	await create_timer(0.12).timeout
	check(absf(music.get_playback_position() - before) < 0.1, "gameplay playback position must remain frozen during choices")
	audio.begin(music)
	check(audio.session_count == 1, "a second player or queued level must not restart the musical session")
	check(audio._voices.Sting.bus == &"Music" and audio._voices.Navigate.bus == &"Sounds", "musical and UI streams must use independent buses")
	var globals := root.get_node("global")
	globals.setMusic(false)
	globals.setSound(true)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Sounds")), "independent mute settings must remain honored")
	audio.finish()
	check(not music.stream_paused and music.playing and music.get_playback_position() >= before - 0.1, "null selection streams must resume the same gameplay player without rewinding")
	globals.setMusic(true)
	audio.begin(music)
	audio.finish(false)
	check(music.stream_paused, "navigation cancellation must not resume a retiring gameplay player")
	var loop = load("res://assets/audio/music/loader.ogg")
	var original_loop: bool = loop.loop
	audio.loop_stream = loop
	audio.begin(music)
	check(audio._voices.Loop.stream != loop and audio._voices.Loop.stream.loop and loop.loop == original_loop, "selection must loop a local stream without mutating a shared supplied master")
	audio.finish(false)
	paused = false
	music.stream_paused = false
	music.stop()
	audio.queue_free()
	music.queue_free()
	var stopped_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - stopped_at < 80:
		await process_frame
	print("Selection presentation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

class_name UpgradeSelectionAudio
extends Node

@export var sting_stream: AudioStream
@export var loop_stream: AudioStream
@export var return_stream: AudioStream
@export var navigate_stream: AudioStream = preload("res://assets/audio/sfx/ui/menu.wav")
@export var confirm_stream: AudioStream = preload("res://assets/audio/sfx/ui/menu_select.wav")

var session_count := 0
var _gameplay: AudioStreamPlayer
var _previous_pause := false
var _session := false
var _voices: Dictionary[StringName, AudioStreamPlayer] = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in [&"Sting", &"Loop", &"Return", &"Navigate", &"Confirm"]:
		var voice := AudioStreamPlayer.new()
		voice.name = id
		voice.bus = &"Sounds" if id in [&"Navigate", &"Confirm"] else &"Music"
		voice.volume_db = -8.0
		add_child(voice)
		_voices[id] = voice
	_voices.Sting.finished.connect(_start_loop)

func begin(gameplay: AudioStreamPlayer) -> void:
	if _session:
		return
	_session = true
	session_count += 1
	_gameplay = gameplay
	if is_instance_valid(_gameplay):
		_previous_pause = _gameplay.stream_paused
		_gameplay.stream_paused = true
	if sting_stream:
		_play(&"Sting", sting_stream)
	else:
		_start_loop()

func _start_loop() -> void:
	if _session and loop_stream:
		var playback := loop_stream.duplicate() as AudioStream
		if playback is AudioStreamOggVorbis or playback is AudioStreamMP3:
			playback.loop = true
		_play(&"Loop", playback)

func navigate() -> void:
	_play(&"Navigate", navigate_stream)

func confirm() -> void:
	_play(&"Confirm", confirm_stream)

func finish(resume_gameplay := true) -> void:
	_session = false
	for voice in _voices.values():
		voice.stop()
		voice.stream = null
	if resume_gameplay:
		if is_instance_valid(_gameplay):
			_gameplay.stream_paused = _previous_pause
		_play(&"Return", return_stream)
	_gameplay = null

func _play(id: StringName, stream: AudioStream) -> void:
	if stream != null and _voices.has(id):
		_voices[id].stream = stream
		_voices[id].play()

func _exit_tree() -> void:
	finish(false)

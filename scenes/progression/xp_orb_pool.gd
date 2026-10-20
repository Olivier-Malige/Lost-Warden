class_name XpOrbPool
extends Node

const ORB := preload("res://scenes/progression/xp_orb.tscn")
const CAPACITY := 128
const SOUND_INTERVAL_MS := 60
@export var collection_stream: AudioStream = preload("res://assets/audio/sfx/pickups/xp_orb_collect.wav")
var targets: Callable
var emitted := 0
var collected := 0
var lost := 0
var _entries: Array[Dictionary] = []
var _free: Array[XpOrb] = []
var _sequence := 0
var _running := false
var _audio: AudioStreamPlayer
var _next_sound_at := 0

func _ready() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.name = "CollectionAudio"
	_audio.bus = &"Sounds"
	_audio.volume_db = -2.0
	_audio.max_polyphony = 2
	_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_audio)

func start(player_provider: Callable) -> void:
	targets = player_provider
	_running = true
	_next_sound_at = 0

func living_players() -> Array:
	return targets.call() if targets.is_valid() else []

# Reserve before deferring materialization so simultaneous physics rewards obey the cap.
func spawn(amount: int, world_position: Vector2) -> void:
	if not _running or amount <= 0:
		return
	emitted += amount
	if _entries.size() >= CAPACITY:
		var oldest := _entries[0]
		oldest.amount += amount
		if is_instance_valid(oldest.node):
			oldest.node.value = oldest.amount
			oldest.node._update_sprite()
		return
	_sequence += 1
	var reservation := {"sequence": _sequence, "amount": amount, "position": world_position, "node": null}
	_entries.append(reservation)
	call_deferred("_materialize", reservation)

func _materialize(reservation: Dictionary) -> void:
	if not _running or not _entries.has(reservation) or reservation.node != null:
		return
	var world := get_parent().get_parent() as Node2D
	if world == null or world.is_queued_for_deletion():
		return
	var orb: XpOrb
	while not _free.is_empty() and orb == null:
		var candidate: XpOrb = _free.pop_back()
		if is_instance_valid(candidate): orb = candidate
	if orb == null:
		orb = ORB.instantiate()
	elif orb.get_parent():
		orb.get_parent().remove_child(orb)
	orb.position = world.to_local(reservation.position)
	world.add_child(orb)
	reservation.node = orb
	orb.prepare(reservation.amount, self, reservation)

func collect(orb: XpOrb, collector_id: StringName) -> void:
	if orb.get_meta("pooled", true) or not _entries.has(orb.entry):
		return
	var amount := orb.value
	collected += amount
	_release(orb)
	_play_collection_sound(amount)
	Events.xp_collected.emit(amount, collector_id)

# A batch of attracted orbs shares a short cue without delaying any XP credit.
func _play_collection_sound(amount: int) -> void:
	var now := Time.get_ticks_msec()
	if collection_stream == null or now < _next_sound_at:
		return
	_next_sound_at = now + SOUND_INTERVAL_MS
	if _audio.stream != collection_stream:
		_audio.stream = collection_stream
	_audio.pitch_scale = 1.12 if amount >= 4 else 1.0
	_audio.play()

func release(orb: XpOrb) -> void:
	if not orb.get_meta("pooled", true):
		lost += orb.value
		_release(orb)

func _release(orb: XpOrb) -> void:
	_entries.erase(orb.entry)
	orb.set_meta("pooled", true)
	orb.visible = false
	orb.set_physics_process(false)
	orb.set_deferred("monitoring", false)
	orb.set_deferred("monitorable", false)
	orb.get_node("CollisionShape2D").set_deferred("disabled", true)
	call_deferred("_park", orb)

func _park(orb: XpOrb) -> void:
	if not is_instance_valid(orb):
		return
	if orb.get_parent(): orb.get_parent().remove_child(orb)
	add_child(orb)
	orb.value = 0
	orb.target = null
	orb.collected = false
	orb.entry = {}
	orb.process_mode = Node.PROCESS_MODE_DISABLED
	if not _free.has(orb): _free.append(orb)

func snapshot() -> Dictionary:
	var reserved := 0
	var active_value := 0
	for entry in _entries:
		reserved += int(entry.node == null)
		active_value += entry.amount
	return {"active": _entries.size() - reserved, "reserved": reserved, "parked": _free.size(), "value": active_value, "emitted": emitted, "collected": collected, "lost": lost}

func stop() -> void:
	_running = false
	targets = Callable()
	for entry in _entries:
		lost += entry.amount
		if is_instance_valid(entry.node):
			entry.node.set_meta("pooled", true)
			entry.node.visible = false
			entry.node.set_physics_process(false)
			entry.node.set_deferred("monitoring", false)
			entry.node.set_deferred("monitorable", false)
			entry.node.get_node("CollisionShape2D").set_deferred("disabled", true)
			entry.node.value = 0
			entry.node.target = null
			entry.node.entry = {}
			entry.node.call_deferred("queue_free")
	_entries.clear()
	if is_instance_valid(_audio):
		_audio.stop()
		_audio.stream = null
	_next_sound_at = 0

func _exit_tree() -> void:
	stop()

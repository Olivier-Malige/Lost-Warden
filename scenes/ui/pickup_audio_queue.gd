class_name PickupAudioQueue
extends Node

var _pending: Array[AudioStreamPlayer2D] = []
var _active: AudioStreamPlayer2D

# Scope the queue to the pickup container so screen changes also discard pending sounds.
static func enqueue(sound: AudioStreamPlayer2D) -> void:
	var container := sound.get_parent().get_parent()
	var queue := container.get_node_or_null("PickupAudioQueue") as PickupAudioQueue
	if queue == null:
		queue = PickupAudioQueue.new()
		queue.name = "PickupAudioQueue"
		container.add_child(queue)
	queue._pending.append(sound)
	queue._play_next()

func _play_next() -> void:
	if is_instance_valid(_active) or not is_inside_tree():
		return
	while not _pending.is_empty():
		var sound := _pending.pop_front() as AudioStreamPlayer2D
		if not is_instance_valid(sound) or not sound.is_inside_tree():
			continue
		_active = sound
		sound.finished.connect(_on_finished, CONNECT_ONE_SHOT)
		sound.tree_exiting.connect(_on_source_exiting, CONNECT_ONE_SHOT)
		sound.play()
		return

func _on_finished() -> void:
	if is_instance_valid(_active):
		_active.tree_exiting.disconnect(_on_source_exiting)
	_active = null
	_play_next()

func _on_source_exiting() -> void:
	if is_instance_valid(_active):
		_active.finished.disconnect(_on_finished)
	_active = null
	call_deferred("_play_next")

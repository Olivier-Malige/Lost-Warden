class_name RunProgression
extends RefCounted

const DEFAULT_CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")

var level: int = 1
var xp: int = 0
var _config: ProgressionConfig
var _pending_levels: Array[int] = []

func _init(config: ProgressionConfig = null) -> void:
	_config = config if config != null else DEFAULT_CONFIG
	reset()

func reset() -> void:
	level = 1
	xp = 0
	_pending_levels.clear()

func add_xp(amount: int) -> Array[int]:
	var earned: Array[int] = []
	if amount <= 0 or not _config.validation_errors().is_empty():
		return earned
	xp += amount
	while xp >= next_threshold():
		xp -= next_threshold()
		level += 1
		earned.append(level)
		_pending_levels.append(level)
	return earned

func next_threshold() -> int:
	return _config.threshold_for_level(level)

func pending_count() -> int:
	return _pending_levels.size()

func take_selection_level() -> int:
	return _pending_levels.pop_front() if not _pending_levels.is_empty() else 0

func snapshot() -> Dictionary:
	return {"level": level, "xp": xp, "next_threshold": next_threshold(), "pending_count": pending_count()}

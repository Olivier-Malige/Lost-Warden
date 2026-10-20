class_name RunRandom
extends RefCounted

var run_seed: int
var encounters := RandomNumberGenerator.new()
var enemies := RandomNumberGenerator.new()
var drops := RandomNumberGenerator.new()
var upgrades := RandomNumberGenerator.new()
var _combat: Dictionary[StringName, RandomNumberGenerator] = {}

func _init(value: int = 0) -> void:
	run_seed = value
	var streams := [encounters, enemies, drops, upgrades]
	for index in streams.size():
		streams[index].seed = int((value * 1664525 + (index + 1) * 1013904223) & 0x7fffffff)
	for index in 2:
		var random := RandomNumberGenerator.new()
		random.seed = int((value * 1664525 + (index + 5) * 1013904223) & 0x7fffffff)
		_combat[&"player1" if index == 0 else &"player2"] = random

func combat_for(owner_id: StringName) -> RandomNumberGenerator:
	return _combat.get(owner_id)

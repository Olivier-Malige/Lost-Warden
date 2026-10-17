class_name RunRandom
extends RefCounted

var run_seed: int
var encounters := RandomNumberGenerator.new()
var enemies := RandomNumberGenerator.new()
var drops := RandomNumberGenerator.new()
var upgrades := RandomNumberGenerator.new()

func _init(value: int = 0) -> void:
	run_seed = value
	var streams := [encounters, enemies, drops, upgrades]
	for index in streams.size():
		streams[index].seed = int((value * 1664525 + (index + 1) * 1013904223) & 0x7fffffff)

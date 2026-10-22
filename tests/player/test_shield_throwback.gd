extends "res://tests/player/test_defensive_pack.gd"

func run() -> void:
	setup_stage()
	await reset_case()
	for value in range(1, 4): await projectile_capacity(value)
	await ownership_and_pooling()
	await real_callbacks()
	effects.cancel()
	stage.free()
	await settle()
	print("Shield throwback: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

extends Node2D

const PlayerScene := preload("res://scenes/player/player.tscn")
const TurretScene := preload("res://scenes/enemies/turret.tscn")
const DroneScene := preload("res://scenes/enemies/drone.tscn")
const PlasmaCellScene := preload("res://scenes/ui/plasma_cell.tscn")
const Layers := preload("res://core/collision_layers.gd")

var _failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	await _test_continuous_damage()
	await _test_cell_collection()
	await _test_elite_rewards()
	if _failures.is_empty():
		print("Continuous beam harness: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_continuous_damage() -> void:
	global.coop = false
	var player := PlayerScene.instantiate() as Player
	var turret := TurretScene.instantiate() as Enemy
	add_child(player)
	add_child(turret)
	player.position = Vector2(533, 400)
	turret.position = Vector2(533, 200)
	turret.set_physics_process(false)
	await get_tree().physics_frame
	var original_position := turret.position
	var original_life := turret.life
	player.continuous_beam.damage_interval = 0.1
	player.continuous_beam.activate(player.id_Player, 3.0, false)
	for _frame in range(8):
		await get_tree().physics_frame
	_expect(turret.life <= original_life - 3, "A target remaining inside the beam must take its first damage tick.")
	var life_after_first_tick := turret.life
	for _frame in range(7):
		await get_tree().physics_frame
	_expect(turret.life <= life_after_first_tick - 3, "A target remaining inside the beam must take repeated damage ticks.")
	_expect(turret.position == original_position, "Continuous damage must not apply repeated impact recoil.")
	_expect((player.continuous_beam.collision_mask & Layers.ENEMY_SHOT) == 0, "The beam must never collide with enemy projectiles.")
	player.continuous_beam.deactivate()
	player.queue_free()
	turret.queue_free()
	await get_tree().process_frame

func _test_cell_collection() -> void:
	global.coop = true
	var player_one := PlayerScene.instantiate() as Player
	var player_two := PlayerScene.instantiate() as Player
	player_two.set_Player_2 = true
	var cell := PlasmaCellScene.instantiate() as PlasmaCell
	add_child(player_one)
	add_child(player_two)
	cell.position = Vector2(800, 700)
	add_child(cell)
	await get_tree().process_frame
	var one_before := player_one.beam_charge
	var two_before := player_two.beam_charge
	cell._on_area_entered(player_one)
	_expect(is_equal_approx(player_one.beam_charge, one_before + 12.5), "Cell collection must recharge player one.")
	_expect(is_equal_approx(player_two.beam_charge, two_before + 12.5), "Cell collection must share recharge with player two.")
	_expect(cell._collected, "A collected cell must ignore duplicate overlap callbacks.")
	cell._on_area_entered(player_two)
	_expect(is_equal_approx(player_one.beam_charge, one_before + 12.5), "Duplicate cell callbacks must not add charge twice.")
	player_one.beam_charge = 95.0
	player_one.add_beam_charge(12.5)
	_expect(is_equal_approx(player_one.beam_charge, 100.0), "Plasma collection must clamp to the reserve maximum.")
	player_one.queue_free()
	player_two.queue_free()
	cell.queue_free()
	await get_tree().process_frame
	global.coop = false

func _test_elite_rewards() -> void:
	var plasma_before := get_tree().get_node_count_in_group(&"plasma_cells")
	var power_up_before := get_tree().get_node_count_in_group(&"powersUp")
	var elite := DroneScene.instantiate() as Enemy
	add_child(elite)
	elite.elite = true
	await get_tree().process_frame
	elite._award_player_kill()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(get_tree().get_node_count_in_group(&"plasma_cells") == plasma_before + 1, "An elite must guarantee one plasma cell.")
	_expect(get_tree().get_node_count_in_group(&"powersUp") == power_up_before + 1, "An elite must guarantee one standard power-up.")
	for cell in get_tree().get_nodes_in_group(&"plasma_cells"):
		_expect(is_equal_approx((cell as PlasmaCell).charge_amount, 25.0), "An elite plasma cell must be worth twenty-five charge.")
		cell.queue_free()
	for power_up in get_tree().get_nodes_in_group(&"powersUp"):
		power_up.queue_free()
	elite.queue_free()
	await get_tree().process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

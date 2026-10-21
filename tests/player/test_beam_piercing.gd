extends "res://tests/player/test_beam_impact.gd"

const UPGRADE: UpgradeDefinition = preload("res://data/upgrades/beam_piercing.tres")
var _target_sequence := 0

func target(stage: Node2D, at: Vector2, width := 24.0) -> Variant:
	var enemy = _enemy(stage, at, width)
	_target_sequence += 1
	var context := EnemySpawnContext.new()
	context.combat_id = StringName("beam_target_%04d" % _target_sequence)
	enemy.configure_spawn(context)
	for audio in enemy.find_children("*", "AudioStreamPlayer2D", true, false): audio.stream = null
	return enemy

func _run() -> void:
	root.get_node("global").Debug = false
	_check(PackedFloat32Array(UPGRADE.damage_bonus_values) == PackedFloat32Array([0.2, 0.3, 0.4]) and PackedFloat32Array(UPGRADE.width_bonus_values) == PackedFloat32Array([0.25, 0.375, 0.5]), "the prototype authors stronger damage and width separately at all three ranks")
	var invalid := UPGRADE.duplicate() as UpgradeDefinition
	invalid.width_bonus_values = PackedFloat32Array([0.25])
	_check(not invalid.foundation_errors().is_empty(), "incomplete authored width ranks must be rejected before catalog activation")
	invalid.width_bonus_values = PackedFloat32Array([0.25, -0.1, 0.5])
	_check(not invalid.foundation_errors().is_empty(), "negative or decreasing width bonuses must be rejected")
	for rank in range(1, 4):
		await rank_contacts(rank, false)
	await rank_contacts(3, true)
	await boss_contacts()
	await live_loadout()
	print("Piercing beam: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)

func rank_contacts(rank: int, overdrive: bool) -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var beam = load("res://scenes/player/beam/continuous_beam.tscn").instantiate()
	stage.add_child(beam)
	beam.position = Vector2(240, 390)
	beam.beam_audio.stream = null
	beam.extra_targets = int(UPGRADE.rank_value(rank))
	beam.beam_width *= 1.0 + UPGRADE.width_bonus(rank)
	beam.overdrive_width *= 1.0 + UPGRADE.width_bonus(rank)
	var base_width: float = [10.0, 11.0, 12.0][rank - 1] * (2.0 if overdrive else 1.0)
	var targets: Array = []
	for index in 5: targets.append(target(stage, Vector2(240, 330 - index * 70)))
	var off_axis = target(stage, Vector2(240 + base_width * 0.55 + 2.0, 290), 4.0)
	await _settle()
	beam.activate("player1", 3.0 * (1.0 + UPGRADE.damage_bonus(rank)), overdrive)
	beam.set_physics_process(false)
	beam._update_geometry()
	_check(beam._contacts.size() == rank + 1 and beam._segments.size() == rank + 1, "each rank must stop after its authored additional target budget")
	for index in rank + 1:
		var width: float = base_width * pow(0.8, index)
		_check(is_equal_approx(beam._segments[index].width, width) and is_equal_approx(beam._outer_segments[index].width, width), "each visible beam segment narrows by exactly twenty percent")
		_check(is_equal_approx(beam._collision_segments[index].shape.size.x, width * beam.collision_width_multiplier), "each collision segment follows the same narrowed width and original tolerance")
		if index > 0:
			_check(beam._outer_segments[index].points[0].is_equal_approx(beam._outer_segments[index - 1].points[1]), "segments join continuously at each impact")
	beam._damage_overlaps()
	for index in 5:
		var expected: float = 3.0 * (1.0 + UPGRADE.damage_bonus(rank)) * (1.5 if overdrive else 1.0) * pow(0.8, index) if index <= rank else 0.0
		_check(is_equal_approx(100.0 - targets[index].life, expected), "real shaped contacts must apply the authored beam bonus, overdrive and decay once")
	_check(off_axis.life == 100.0, "a target inside the original width but outside a narrowed segment must remain untouched")
	off_axis.free()
	var next_before: float = targets[1].life
	targets[0].position.x = 310
	await _settle()
	beam._damage_overlaps()
	_check(beam._impact_target == targets[1] and is_equal_approx(beam._segments[0].width, base_width), "moving the first obstacle away restores full width on the new first target")
	_check(is_equal_approx(next_before - targets[1].life, beam.damage * (1.5 if overdrive else 1.0)), "the next target now receives full initial damage instead of accumulated attenuation")
	beam.set_physics_process(true)
	paused = true
	var flow: float = beam._flow_time
	var health: float = targets[1].life
	await create_timer(0.12, true).timeout
	_check(beam._flow_time == flow and targets[1].life == health, "selection pause freezes segmented flow and damage ticks")
	paused = false
	beam.deactivate()
	await _settle()
	_check(beam._contacts.is_empty() and beam._segments.is_empty() and beam._collision_segments.all(func(shape): return shape.disabled), "deactivation clears contacts and disables every segment collider")
	beam.extra_targets = 0
	beam.beam_width = 8.0
	beam.overdrive_width = 16.0
	beam.activate("player2", 3.0, false)
	beam.set_physics_process(false)
	_check(beam._segments.size() == 1 and beam._contacts.size() == 1 and beam._outer_segments.slice(1).all(func(line): return not line.visible), "reactivation without the upgrade restores one ordinary segment and hides old upper segments")
	beam.deactivate()
	stage.free()
	await process_frame

func boss_contacts() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var beam = load("res://scenes/player/beam/continuous_beam.tscn").instantiate()
	stage.add_child(beam)
	beam.position = Vector2(178, 390)
	beam.beam_audio.stream = null
	beam.extra_targets = 3
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	boss.position = Vector2(200, 150)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	var behind = target(stage, Vector2(178, 50))
	await _settle()
	beam.activate("player1", 3.9, false)
	beam.set_physics_process(false)
	beam._damage_overlaps()
	_check(beam._impact_target == boss.get_node("Armor") and beam._segments.size() == 1 and behind.life == 100.0 and boss.life == boss.max_life, "armor must stop even rank-three piercing without damage behind it")
	boss.get_node("Armor").position.x = 200
	boss.get_node("PortCannon").position = Vector2.ZERO
	boss.get_node("StarboardCannon").position = Vector2.ZERO
	beam.position.x = 200
	behind.position.x = 200
	await _settle()
	var health: float = boss.life + boss.get_node("PortCannon").life + boss.get_node("StarboardCannon").life
	beam._damage_overlaps()
	_check(is_equal_approx(health - boss.life - boss.get_node("PortCannon").life - boss.get_node("StarboardCannon").life, 3.9), "one plasma tick must hit only one logical boss group even across overlapping surfaces")
	_check(is_equal_approx(behind.life, 96.88), "a separate enemy behind the boss receives one attenuated tick")
	beam.deactivate()
	stage.free()
	await process_frame

func live_loadout() -> void:
	var globals := root.get_node("global")
	globals.coop = true
	root.size = Vector2i(640, 400)
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	world.get_node("waveGenerator").stop_run()
	var p1 = world.progression.players[0]
	var p2 = world.progression.players[1]
	for player in [p1, p2]:
		player.set_physics_process(false)
		for kind in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
			for audio in player.find_children("*", kind, true, false): audio.stream = null
	for rank in range(1, 4):
		_check(p1.apply_upgrade(UPGRADE).applied and p1.loadout.beam_extra_targets == rank and is_equal_approx(p1.loadout.beam_damage_multiplier, 1.0 + UPGRADE.damage_bonus(rank)) and is_equal_approx(p1.loadout.beam_width_multiplier, 1.0 + UPGRADE.width_bonus(rank)), "all three real personal ranks derive targets, damage and width from the resource")
		_check(p1.loadout.foundation_snapshot().utility_count == 1 and p1.loadout.foundation_snapshot().offensive_count == 0 and p1.beam_charge == 0.0, "beam piercing consumes one utility slot, no offensive slot and grants no free plasma")
	_check(not p1.apply_upgrade(UPGRADE).applied and p2.loadout.beam_extra_targets == 0, "the family caps at three and cannot change the partner's beam")
	_check(not p1.loadout.can_apply_foundation(&"piercing"), "the old gun-piercing card is no longer available in normal runs")
	p2.beam_charge = 50
	p2._update_beam(0.0, true)
	p2.continuous_beam.set_physics_process(false)
	_check(p2.continuous_beam.damage == 3.0 and p2.continuous_beam.beam_width == 8.0 and p2.continuous_beam.overdrive_width == 16.0, "the unupgraded partner retains original damage and normal/overdrive widths")
	p2._stop_beam()
	var targets: Array = []
	for index in 3: targets.append(target(world, Vector2(p1.position.x, 300 - index * 70)))
	await _settle()
	p1.beam_charge = 50
	p1._update_beam(0.1, true)
	p1.continuous_beam.set_physics_process(false)
	_check(is_equal_approx(p1.beam_charge, 48.0) and is_equal_approx(p1.continuous_beam.damage, 4.2) and p1.continuous_beam.extra_targets == 3 and p1.continuous_beam.beam_width == 12.0 and p1.continuous_beam.overdrive_width == 24.0, "manual plasma retains its normal drain while receiving beam-specific damage and width bonuses")
	p1.continuous_beam._damage_overlaps()
	for index in targets.size():
		_check(is_equal_approx(100.0 - targets[index].life, 4.2 * pow(0.8, index)) and targets[index].last_player_hit_owner == &"player1", "the live plasma service must resolve every attenuated contact with the original player credit")
	_check(world.hit_effects.get_debug_snapshot().roots == 0 and p1.continuous_beam._segments.size() == 4, "a beam with spare traversal budget extends its last narrowed segment to the top and releases its tick root")
	for actor in targets: actor.free()
	p1._stop_beam()
	p1.apply_upgrade(load("res://data/upgrades/foundation/damage.tres"))
	p1._update_beam(0.0, true)
	p1.continuous_beam.set_physics_process(false)
	_check(is_equal_approx(p1.continuous_beam.damage, 3.25 * 1.4), "existing additive beam damage is multiplied once, without the primary cannon multiplier")
	p1._stop_beam()
	p1.loadout.reset()
	p1.publish_build()
	_check(p1.loadout.beam_extra_targets == 0 and p1.loadout.beam_damage_multiplier == 1.0 and p1.loadout.beam_width_multiplier == 1.0, "reset removes the signature upgrade and both bonuses")
	p1._update_beam(0.0, true)
	p1.continuous_beam.set_physics_process(false)
	_check(p1.continuous_beam.damage == 3.0 and p1.continuous_beam.beam_width == 8.0, "restarting the beam after a build reset restores its base damage and width")
	p1._stop_beam()
	await create_timer(0.26).timeout
	await _settle()
	var baseline := get_node_count()
	for cycle in 5:
		p1.continuous_beam.extra_targets = 3
		p1.continuous_beam.activate("player1", 3.9, cycle % 2 == 0)
		p1.continuous_beam.deactivate()
		await _settle()
		_check(get_node_count() == baseline and world.hit_effects.get_debug_snapshot().roots == 0, "repeated segmented beam activation must not add nodes or retain hit roots")
	if DisplayServer.get_name() != "headless":
		p1.position = Vector2(220, 370)
		p2.position = Vector2(420, 370)
		for player in [p1, p2]:
			for rank in 3: player.apply_upgrade(UPGRADE)
			for index in 4: target(world, Vector2(player.position.x, 315 - index * 65), 12.0)
			player.beam_charge = 100
			player._update_beam(0.0, true)
			player.continuous_beam.set_physics_process(false)
		await _settle()
		for mode in [true, false]:
			for player in [p1, p2]:
				player.continuous_beam.set_overdrive(mode)
				player.continuous_beam._damage_overlaps()
			for sample in 3:
				for player in [p1, p2]: player.continuous_beam._physics_process(0.04)
				await RenderingServer.frame_post_draw
				_check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://beam_taper_%s_%d.webp" % ["overdrive" if mode else "normal", sample]), true) == OK, "native beam taper samples must save")
		for player in [p1, p2]: player._stop_beam()
		var ui = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
		root.add_child(ui)
		var offers := [UPGRADE.offer_snapshot(2), load("res://data/upgrades/critical_hits.tres").offer_snapshot(0), load("res://data/upgrades/foundation/beam_capacity.tres").offer_snapshot(0)]
		_check(ui._effect_lines(offers[0]) == "3 EXTRA TARGETS\n+40% DAMAGE / +50% WIDTH", "selection text must disclose the authored damage and width bonuses")
		ui.open(123, {&"player1": {"build": p1.loadout.foundation_snapshot(), "offers": offers}, &"player2": {"build": p2.loadout.foundation_snapshot(), "offers": offers}}, {"level": 4, "xp": 0, "next_threshold": 21})
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://beam_taper_choices.webp"), true)
		ui.free()
	world.free()
	await process_frame

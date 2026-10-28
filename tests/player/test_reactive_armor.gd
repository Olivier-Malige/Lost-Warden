extends "res://tests/player/test_defensive_pack.gd"

func run() -> void:
	setup_stage()
	check(ARMOR.foundation_errors().is_empty() and ARMOR.rank_values == PackedFloat32Array([1, 1, 1]) and ARMOR.interval_values == PackedFloat32Array([8, 6, 4]), "repair amounts and quiet delays are authored at every rank")
	for delays in [PackedFloat32Array(), PackedFloat32Array([8, 6]), PackedFloat32Array([8, NAN, 4]), PackedFloat32Array([8, 0, 4]), PackedFloat32Array([8, 10, 4])]:
		var invalid := ARMOR.duplicate() as UpgradeDefinition
		invalid.interval_values = delays
		check(not invalid.foundation_errors().is_empty(), "missing, invalid or increasing repair delays reject before offers")
	var invalid := ARMOR.duplicate() as UpgradeDefinition
	invalid.rank_values = PackedFloat32Array([1, 1, 2])
	check(not invalid.foundation_errors().is_empty(), "armor cannot bank multiple repaired hull points per injury")
	for value in range(1, 4): await rank_timing(value)
	await damage_restarts()
	await absorbed_hits()
	await ranks_and_capacity()
	await personal_state_and_death()
	if DisplayServer.get_name() != "headless": await native_repair()
	effects.cancel()
	stage.free()
	await settle()
	print("Reactive repair armor: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func rank_timing(value: int) -> void:
	await reset_case()
	p1.energy = 6
	equip(p1, ARMOR, value)
	var delay := ARMOR.interval_value(value)
	p1.defenses._physics_process(20)
	check(p1.energy == 6 and p1.defenses.repair_left == 0, "acquiring armor while injured does not repair an old wound for free")
	p1._hit_something()
	check(p1.energy == 5 and p1.defenses.grace_left == 1 and p1.defenses.repair_left == delay, "a real wound starts repair but preserves ordinary injury grace")
	p1._hit_something()
	check(p1.energy == 5 and p1.defenses.repair_left == delay, "ordinary invulnerability blocks duplicate injury and repair resets")
	p1.defenses._physics_process(delay - 0.01)
	check(p1.energy == 5 and p1.defenses.repair_left > 0, "every rank waits for its complete quiet interval")
	paused = true
	var before: Dictionary = p1.defenses.snapshot()
	p1.defenses._physics_process(100)
	check(p1.energy == 5 and p1.defenses.snapshot() == before, "selection pause freezes repair and its published progress")
	paused = false
	p1.defenses._physics_process(0.02)
	check(p1.energy == 6 and p1.defenses.repair_left == 0 and p1.defenses.repair_flash_left > 0, "quiet time restores exactly one hull point and presents completion feedback")
	p1.defenses._physics_process(30)
	check(p1.energy == 6 and p1.defenses.repair_flash_left == 0, "one injury cannot become continuous regeneration")
	var selector = load("res://scenes/ui/upgrade_selection.gd").new()
	var offer := ARMOR.offer_snapshot(value - 1)
	var copy: String = selector._effect_lines(offer)
	selector.free()
	check(offer.next_value == 1 and offer.next_interval == delay and copy.contains("REPAIR 1 HP") and copy.contains("%.0fS WITHOUT DAMAGE" % delay), "offers explain the repaired point, trigger and ranked quiet delay")

func damage_restarts() -> void:
	await reset_case()
	equip(p1, ARMOR, 1)
	p1.energy = 9
	p1._hit_something()
	p1.defenses._physics_process(3)
	p1._hit_something()
	check(p1.energy == 7 and p1.defenses.repair_left == 8, "another accepted wound restarts the entire quiet delay")
	p1.defenses._physics_process(7.99)
	check(p1.energy == 7, "the original wound's deadline cannot trigger an early repair")
	p1.defenses._physics_process(0.02)
	check(p1.energy == 8, "several wounds before recovery still produce a single repaired point")
	await reset_case()
	equip(p1, ARMOR, 3)
	p1._hit_by_beam()
	p1.defenses._physics_process(0.3)
	p1._hit_by_beam()
	check(p1.energy == 10 and p1.defenses.repair_left == 4, "continuous beam ticks remain damaging and restart repair")
	p1.defenses._physics_process(3.99)
	check(p1.energy == 10, "beam damage also requires the full quiet interval")
	p1.defenses._physics_process(0.02)
	check(p1.energy == 11, "surviving a beam permits one later repair")

func absorbed_hits() -> void:
	await reset_case()
	for data in [ARMOR, SHIELD, RIPOSTE]: equip(p1, data, 1)
	p1.energy = 6
	p1._hit_something()
	check(p1.energy == 6 and p1.defenses.repair_left == 0, "reflection absorption cannot start repair without a hull injury")
	p1._hit_by_beam()
	p1.defenses._physics_process(2)
	var left: float = p1.defenses.repair_left
	p1._hit_something()
	check(p1.energy == 5 and p1.defenses.repair_left == left, "reflected impacts cannot reset an existing quiet interval")
	contact_hit(p1)
	check(p1.energy == 5 and p1.defenses.charges == 0 and p1.defenses.pulse_protection_left > 0 and p1.defenses.repair_left == left, "retaliation cancelling a contact preserves the pending repair")
	p1._hit_by_beam()
	check(p1.energy == 5 and p1.defenses.repair_left == left, "retaliation protection also prevents false repair resets from beams")

func ranks_and_capacity() -> void:
	await reset_case()
	equip(p1, ARMOR, 1)
	p1.energy = 6
	p1._hit_something()
	p1.defenses._physics_process(2)
	paused = true
	check(p1.apply_upgrade(ARMOR).applied, "repair armor ranks through ordinary paused selection")
	check(p1.energy == 5 and p1.defenses.repair_duration == 6 and is_equal_approx(p1.defenses.repair_left, 4.5), "ranking preserves elapsed repair percentage without granting an immediate heal")
	check(p1.apply_upgrade(ARMOR).applied, "repair armor reaches its third rank")
	check(p1.defenses.repair_duration == 4 and p1.defenses.repair_left == 3, "the final rank preserves repair progress again")
	paused = false
	p1.defenses._physics_process(3.01)
	check(p1.energy == 6, "the upgraded repair completes only after its remaining interval")
	await reset_case()
	equip(p1, ARMOR, 1)
	p1._hit_something()
	check(p1.apply_upgrade(load("res://data/upgrades/foundation/energy.tres")).applied, "ordinary energy recovery remains compatible")
	check(p1.energy == p1.STATS.energy_max and p1.defenses.repair_left == 0, "reaching full hull cancels repair instead of banking a future point")
	p1.energy -= 2
	p1.defenses._physics_process(20)
	check(p1.energy == 10, "a cancelled full-hull repair cannot heal unrelated later state changes")
	check(p1.vitals.repair_hull(99) and p1.energy == p1.STATS.energy_max, "the vitals owner caps hull recovery at maximum energy")

func personal_state_and_death() -> void:
	await reset_case()
	equip(p1, ARMOR, 3)
	equip(p2, ARMOR, 3)
	p1.energy = 2
	p2.energy = 6
	p1._hit_something()
	p2._hit_something()
	p1._hit_by_beam()
	check(p1.state == p1.State.DYING and p1.energy == 0 and p1.defenses.repair_left == 0, "lethal damage cancels repair immediately")
	p1.defenses._physics_process(100)
	check(not p1.vitals.repair_hull(1) and p1.energy == 0, "repair cannot resurrect a dying owner")
	p2.defenses._physics_process(4.01)
	check(p2.energy == 6 and p2.defenses.repair_left == 0, "one owner's death cannot cancel the partner's repair")

func native_repair() -> void:
	stage.hide()
	for layout in ["solo", "coop", "wide"]:
		root.size = Vector2i(960 if layout == "wide" else 640, 400)
		globals.coop = layout != "solo"
		var world = load("res://scenes/world/world.tscn").instantiate()
		root.add_child(world)
		world.get_node("waveGenerator").stop_run()
		var players: Array = world.progression.players
		var side_width := maxf((root.size.x - 640) * 0.5, 0)
		for index in players.size():
			var pilot = players[index]
			pilot.position = Vector2((220 if index == 0 else 420) + side_width, 285)
			pilot.set_physics_process(false)
			pilot.defenses.set_physics_process(false)
			pilot.energy = 6
			pilot.update_energy()
			equip(pilot, ARMOR, 2 if layout == "solo" else 1 if index == 0 else 3)
		var previous := stage
		stage = world
		for pilot in players: hostile(pilot.position)
		stage = previous
		await settle()
		var hud = world.get_node("hud")
		for pilot in players:
			var holder = hud._defense_controls[StringName(pilot.id_Player)]
			check(pilot.energy == 5 and pilot.defenses.repair_left > 0 and holder.visible and holder.get_node("RepairProgress").visible and not holder.get_node("State").visible, "actual native projectiles start visible repair even without Reflection")
		await repair_capture("repair_%s_start" % layout)
		for pilot in players:
			pilot.defenses._physics_process(pilot.defenses.repair_duration * 0.5)
			pilot._on_touchedReset_timeout()
			var bar: ProgressBar = hud._defense_controls[StringName(pilot.id_Player)].get_node("RepairProgress")
			check(is_equal_approx(bar.value / bar.max_value, 0.5), "event-driven HUD shows each owner's repair progress")
		await repair_capture("repair_%s_half" % layout)
		for pilot in players:
			pilot._hit_by_beam()
			check(pilot.energy == 4 and pilot.defenses.repair_left == pilot.defenses.repair_duration, "native damage restarts each owner's indicator")
		await repair_capture("repair_%s_restart" % layout)
		var owner = players[0]
		owner.apply_upgrade(SHIELD)
		await repair_capture("repair_%s_with_shield" % layout)
		for pilot in players:
			pilot.defenses._physics_process(pilot.defenses.repair_left + 0.01)
			var holder = hud._defense_controls[StringName(pilot.id_Player)]
			var pips: Array = hud._pips[String(pilot.id_Player)]
			check(pilot.energy == 5 and holder.get_node("RepairState").text == "REPAIRED +1" and not holder.get_node("RepairProgress").visible and pips.filter(func(pip): return pip.visible).size() == 5, "native completion restores one visible hull pip and displays success")
		await repair_capture("repair_%s_complete" % layout)
		var menu = load("res://scenes/ui/upgrade_selection.tscn").instantiate()
		root.add_child(menu)
		var participants := {}
		for pilot in players:
			participants[StringName(pilot.id_Player)] = {"build": pilot.loadout.foundation_snapshot(), "offers": [ARMOR.offer_snapshot(1), SHIELD.offer_snapshot(1), RIPOSTE.offer_snapshot(0)]}
		menu.open(1400, participants, {"level": 4, "xp": 0, "next_threshold": 21})
		await create_timer(0.6).timeout
		await repair_capture("repair_%s_choices" % layout)
		menu.free()
		world.free()
		await settle()
	root.size = Vector2i(640, 400)
	globals.coop = true
	stage.show()

func repair_capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	capture(label)

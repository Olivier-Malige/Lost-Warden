extends "res://tests/test_upgrade_selection.gd"

func run() -> void:
	events = root.get_node("Events")
	globals = root.get_node("global")
	globals.Debug = false
	globals.saveData.config.fullscreen = false
	AudioServer.set_bus_mute(0, true)
	var captures := 0
	var selectable: Array[UpgradeDefinition] = []
	for definition in CATALOG.upgrades:
		if definition.category != UpgradeDefinition.Category.FALLBACK: selectable.append(definition)
	for coop in [false, true]:
		globals.coop = coop
		main = load("res://scenes/main/main.tscn").instantiate()
		root.add_child(main)
		main.get_node("loader/Timer").stop()
		main.get_node("loader").free()
		main._show_world_screen()
		main.get_node("world/waveGenerator").stop_run()
		for player in main.get_node("world").progression.players:
			player.set_physics_process(false)
		for width in [640, 800]:
			root.size = Vector2i(width, 400)
			await process_frame
			for batch in range(0, selectable.size(), 3):
				var snapshots := {}
				for id in [&"player1", &"player2"] if coop else [&"player1"]:
					var build := PlayerLoadout.new(STATS)
					build.initialize_foundation(CONFIG, CATALOG.upgrades)
					var hand: Array = []
					for index in range(batch, mini(batch + 3, selectable.size())):
						var definition := selectable[index]
						if definition.is_family():
							for rank in maxi(0, definition.max_rank - 1):
								check(build.apply_foundation(definition.id).applied, "preview rank matches the legal personal build")
						hand.append(definition.offer_snapshot(int(build.acquired_ranks.get(definition.id, 0))))
					for definition in CATALOG.upgrades:
						if not definition.is_family() or build.acquired_ranks.has(definition.id): continue
						var state := build.foundation_snapshot()
						if definition.category == UpgradeDefinition.Category.OFFENSIVE and state.offensive_count >= 3: continue
						if definition.category == UpgradeDefinition.Category.UTILITY and state.utility_count >= 3: continue
						for rank in definition.max_rank:
							check(build.apply_foundation(definition.id).applied, "preview fills six ordinary legal build slots")
					snapshots[id] = {"build": build.foundation_snapshot(), "offers": hand}
				events.upgrade_selection_requested.emit(1000 + captures, snapshots, {"level": 20, "xp": 1, "next_threshold": 100})
				var ui = main._selection
				await create_timer(0.35).timeout
				check_categories(ui)
				for player_id in ui._panels:
					var panel: Control = ui._panels[player_id]
					for card in panel.get_meta("cards"):
						check(Rect2(Vector2.ZERO, panel.size).encloses(Rect2(card.position, card.size)), "every catalog card fits its personal panel")
						var icon: TextureRect = card.get_node("Icon")
						var texture: AtlasTexture = icon.texture
						var image := texture.atlas.get_image().get_region(Rect2i(texture.region))
						check(not image.is_invisible(), "every final-catalog team illustration is visible")
						for child in card.get_children():
							if child is Label:
								check(child.get_minimum_size().x <= child.size.x + 0.1, "card labels fit the available width")
								check(Rect2(Vector2.ZERO, card.size).encloses(Rect2(child.position, child.size)), "card label '%s' rectangle %s / %s remains inside %s" % [child.text, child.position, child.size, card.size])
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					check(root.get_texture().get_image().save_png("user://phase3_cards_%s_%d_%d.png" % ["coop" if coop else "solo", width, batch]) == OK, "native card evidence saves")
				captures += 1
				if "--smoke" in OS.get_cmdline_user_args():
					main._cancel_selection()
					paused = false
					main.free()
					await process_frame
					print("Presentation smoke: %d checks, %d failures" % [checks, failures])
					quit(1 if failures else 0)
					return
		main._cancel_selection()
		paused = false
		main.free()
		for frame in 5: await process_frame
	print("Phase 3 presentation: %d layouts, %d checks, %d failures" % [captures, checks, failures])
	quit(1 if failures else 0)

extends CanvasLayer

signal close_requested()
signal debug_disabled()

const REFRESH_INTERVAL := 0.25
const PAGE_NAMES := ["RUN", "ENEMIES", "PLAYERS", "PERF", "EVENTS"]

var _pages: Dictionary[String, RichTextLabel] = {}
var _snapshot := {}
var _refresh_left := 0.0
var _copied_until := 0

@onready var _tabs: TabContainer = $Panel/Margin/Content/Tabs
@onready var _status: Label = $Panel/Margin/Content/Header/Status

func _ready() -> void:
	for page_name in PAGE_NAMES:
		var page := RichTextLabel.new()
		page.name = String(page_name).capitalize()
		page.bbcode_enabled = true
		page.selection_enabled = true
		page.focus_mode = Control.FOCUS_NONE
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_tabs.add_child(page)
		_tabs.set_tab_title(_tabs.get_tab_count() - 1, page_name)
		_pages[page_name] = page
	_tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	$Panel/Margin/Content/Header/Close.pressed.connect(func(): close_requested.emit())
	$Panel/Margin/Content/Header/Copy.pressed.connect(_copy_snapshot)
	Events.debug_snapshot_updated.connect(_on_snapshot_updated)
	set_view(false, false)

func set_view(compact: bool, full: bool) -> void:
	$Panel.visible = full
	$Compact.visible = compact and not full
	visible = (compact or full) and global.Debug
	set_process(visible)
	if visible:
		_refresh_left = REFRESH_INTERVAL
		Events.debug_snapshot_requested.emit()

func _process(delta: float) -> void:
	if not global.Debug:
		debug_disabled.emit()
		set_view(false, false)
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_INTERVAL
		Events.debug_snapshot_requested.emit()

func handle_key(event: InputEventKey) -> void:
	if not visible or not $Panel.visible or not global.Debug or not event.pressed:
		return
	match event.keycode:
		KEY_LEFT, KEY_RIGHT, KEY_TAB:
			if not event.echo:
				var direction := -1 if event.keycode == KEY_LEFT or (event.keycode == KEY_TAB and event.shift_pressed) else 1
				_tabs.current_tab = wrapi(_tabs.current_tab + direction, 0, _tabs.get_tab_count())
		KEY_ESCAPE:
			if not event.echo:
				close_requested.emit()
		KEY_UP, KEY_DOWN, KEY_PAGEUP, KEY_PAGEDOWN, KEY_HOME, KEY_END:
			var scroll := _pages[PAGE_NAMES[_tabs.current_tab]].get_v_scroll_bar()
			match event.keycode:
				KEY_UP: scroll.value -= 20.0
				KEY_DOWN: scroll.value += 20.0
				KEY_PAGEUP: scroll.value -= scroll.page
				KEY_PAGEDOWN: scroll.value += scroll.page
				KEY_HOME: scroll.value = scroll.min_value
				KEY_END: scroll.value = scroll.max_value - scroll.page

func _copy_snapshot() -> void:
	if visible and global.Debug and not _snapshot.is_empty():
		DisplayServer.clipboard_set(JSON.stringify(_snapshot, "\t"))
		_copied_until = Time.get_ticks_msec() + 1500
		_status.text = "SNAPSHOT COPIED"

func _on_snapshot_updated(snapshot: Dictionary) -> void:
	if not visible or not global.Debug:
		return
	_snapshot = snapshot.duplicate(true)
	var d: Dictionary = snapshot.director
	if d.has("elapsed"):
		$Compact/Margin/Stats.text = "%d FPS D %.2f\nFOES %d/%d +%d\nTHREAT %.0f\nENC %d / %.0fs\nF10 FULL / F11" % [snapshot.performance.fps, d.danger, d.bodies, d.cap, d.reserved, d.budget_left, d.encounter_number, d.encounter_left]
	if not $Panel.visible:
		return
	_status.text = "PAUSED / 4 Hz" if snapshot.paused else "LIVE / 4 Hz"
	if Time.get_ticks_msec() < _copied_until:
		_status.text = "SNAPSHOT COPIED"
	_status.modulate = Color("d6d653") if snapshot.paused else Color("72c95c")
	_write_page("RUN", _run_text(snapshot))
	_write_page("ENEMIES", _enemies_text(snapshot))
	_write_page("PLAYERS", _players_text(snapshot))
	_write_page("PERF", _performance_text(snapshot))
	_write_page("EVENTS", "[color=#d6d653]RECENT EVENTS / NEWEST FIRST / MAX 64[/color]\n\n" + "\n".join(snapshot.events))

func _write_page(page_name: String, text: String) -> void:
	var page := _pages[page_name]
	if page.text == text:
		return
	var scroll := page.get_v_scroll_bar().value
	page.text = text
	page.get_v_scroll_bar().set_deferred("value", scroll)

func _run_text(data: Dictionary) -> String:
	var d: Dictionary = data.director
	if not d.has("elapsed"):
		return "Waiting for the encounter director."
	var lines: Array[String] = [
		"[color=#d6d653]RUN / %s / %s[/color]" % ["CO-OP" if d.coop else "SOLO", d.state],
		"Seed: %d   Running: %s   Players alive: %d" % [d.seed, d.running, data.players_alive],
		"Survival: %s   Regular time: %s" % [global.format_survival_time(d.elapsed), global.format_survival_time(d.regular_elapsed)],
		"Danger: %.3f   Debug offset: %+.2f" % [d.danger, d.danger_offset],
		"Score: %d   Combo: %d / x%.2f / %.2fs left" % [data.score, data.combo, data.combo_multiplier, data.combo_left],
		"", "[color=#d6d653]ENCOUNTER / %d / %s[/color]" % [d.encounter_number, d.encounter],
		"Time left: %.2fs   Formation cycle: %d" % [d.encounter_left, d.formation_cycle],
		"Threat left: %.2f   Budget rate: %.2f / s" % [d.budget_left, d.budget_rate],
		"Next formation: %.2fs   Pending entries: %d" % [d.next_formation, d.pending],
		"Body slots: %d live-tree + %d reserved / %d cap" % [d.bodies, d.reserved, d.cap],
		"Recorded body spawns: %d   Rolling minute: %d" % [data.spawn_total, data.spawns_last_minute],
		"Player kills: %d   Escaped: %d   Other removals: %d" % [data.enemy_removed.killed, data.enemy_removed.escaped, data.enemy_removed.other],
		"Recent encounters: " + ", ".join(d.recent),
		"", "[color=#d6d653]DIFFICULTY MODEL[/color]",
		"Health x%.3f   Movement x%.3f   Fire delay x%.3f" % [d.health_scale, d.speed_scale, d.fire_scale],
		"Elite chance: %.1f%%   Elites: %d + %d reserved / %d" % [d.elite_chance * 100.0, d.elites, d.reserved_elites, d.elite_cap],
		"Recovery left: %.2fs" % d.recovery_left,
		"Next boss in %s regular time" % global.format_survival_time(d.boss_in),
		"Boss approach clear window: %.2fs" % d.get("boss_approach_clear_left", 0.0),
		"XP is not integrated yet.",
	]
	if not d.boss.is_empty():
		var boss: Dictionary = d.boss
		if boss.has("cannons"):
			var cannons: Array = boss.cannons
			lines.insert(5, "Cannons L %.1f / %.1f%s | R %.1f / %.1f%s" % [cannons[0].health, cannons[0].maximum, " DESTROYED" if cannons[0].destroyed else "", cannons[1].health, cannons[1].maximum, " DESTROYED" if cannons[1].destroyed else ""])
		lines.insert(5, "\n[color=#d6d653]BOSS / %s / PHASE %d[/color]\nHP %.1f / %.1f / %s / %s\nReinforcements: %d + %d queued / %d" % [boss.name, boss.phase, boss.health, boss.maximum, boss.attack, boss.get("pattern", ""), boss.adds, boss.reserved_adds, boss.add_cap])
	return "\n".join(lines)

func _enemies_text(data: Dictionary) -> String:
	var d: Dictionary = data.director
	if not d.has("families"):
		return "Waiting for enemy data."
	var lines: Array[String] = [
		"[color=#d6d653]ENEMY BODIES / INCLUDING MOUNTED TURRETS[/color]",
		"Alive: %d   Exploding: %d   Elites: %d" % [d.alive, d.bodies - d.alive, d.elites],
		"Reserved: %d   Capacity: %d / %d" % [d.reserved, d.bodies + d.reserved, d.cap],
		"", "[color=#d6d653]FAMILIES CURRENTLY IN PLAY[/color]",
	]
	var ids: Array = d.families.keys()
	ids.sort()
	for id in ids:
		var family: Dictionary = d.families[id]
		lines.append("%s: %d alive / %d bodies / %d elite / %.1f HP" % [id, family.alive, family.bodies, family.elites, family.health])
	if ids.is_empty():
		lines.append("No enemy bodies in the scene tree.")
	lines.append("\n[color=#d6d653]CURRENT COMPOSITION RULES[/color]")
	for rule in d.rules:
		lines.append("%s / %s x%d / lanes %d-%d" % [rule.family, rule.pattern, rule.formation, rule.lanes.x, rule.lanes.y])
		var status := "READY" if rule.eligible else "BLOCKED"
		lines.append("  Cost %.1f / Weight %.3f / Slots %d / %s" % [rule.cost, rule.weight, rule.available, status])
	return "\n".join(lines)

func _players_text(data: Dictionary) -> String:
	var lines: Array[String] = []
	for player in data.players:
		lines.append("[color=#d6d653]%s / %s / %s[/color]" % [player.id.to_upper(), player.controller, player.state])
		lines.append("Position %s   Health %d/%d   Shield %d" % [player.position, player.energy, player.energy_max, player.shield])
		var defenses: Dictionary = player.get("defenses", {})
		if not defenses.is_empty():
			lines.append("Sphere %d/%d   Recharge %.2fs   Grace %.2fs   Retaliation %.2fs" % [defenses.charges, defenses.maximum, defenses.recharge_left, defenses.grace_left, defenses.pulse_cooldown])
		lines.append("Speed %.1f   Weapon movement x%.2f   Hit malus %d" % [player.move_speed, player.weapon_speed_multiplier, player.hit_slowdown])
		lines.append("Primary damage %.2f   Interval %.3fs   Ready %s" % [player.primary_damage, player.fire_delay, player.can_fire])
		lines.append("Side shots %s   Side damage %.2f   Hit protection %s" % [player.side_shot, player.side_damage, player.touched])
		lines.append("Plasma %.1f/%.1f   Beam %s   Overdrive %.2fs" % [player.plasma, player.plasma_max, player.beam_active, player.overdrive_left])
		var ranks: Array[String] = []
		for effect in player.ranks:
			ranks.append("%s %d" % [effect, player.ranks[effect]])
		lines.append("Ranks: " + (", ".join(ranks) if not ranks.is_empty() else "none"))
		lines.append("")
	if lines.is_empty():
		return "No player nodes remain in this run."
	return "\n".join(lines)

func _performance_text(data: Dictionary) -> String:
	var p: Dictionary = data.performance
	var pool: Dictionary = data.pool
	var lines: Array[String] = [
		"[color=#d6d653]ENGINE / %s[/color]" % Engine.get_version_info().string,
		"FPS: %d   Process: %.3f ms   Physics: %.3f ms" % [p.fps, p.process_ms, p.physics_ms],
		"Static memory: %.1f MiB   Video memory: %.1f MiB" % [p.memory_mb, p.video_mb],
		"Nodes: %d   Resources: %d   Orphan nodes: %d" % [p.nodes, p.resources, p.orphans],
		"Draw calls: %d   Collision pairs: %d" % [p.draw_calls, p.collision_pairs],
		"Logical viewport: %s" % p.viewport,
		"", "[color=#d6d653]PROJECTILES / PARKED SHOTS EXCLUDED FROM ACTIVE[/color]",
		"Active player: %d   Active enemy: %d   Parked: %d" % [pool.active.player, pool.active.enemy, pool.parked],
	]
	var keys: Array = pool.buckets.keys()
	keys.sort()
	for key in keys:
		lines.append("%s: %d parked" % [key, pool.buckets[key]])
	if data.director.has("rng_states"):
		lines.append("\n[color=#d6d653]RNG STATES / READ ONLY[/color]")
		for key in data.director.rng_states:
			lines.append("%s: %s" % [key, data.director.rng_states[key]])
	return "\n".join(lines)

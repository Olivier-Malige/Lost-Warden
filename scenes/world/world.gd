extends Node2D

const CORE_WIDTH := 640.0

var nbr_Player := 0
var _debug_events: Array[String] = []
var _debug_spawn_buckets: Dictionary[int, int] = {}
var _debug_spawn_total := 0
var _debug_removed := {"killed": 0, "escaped": 0, "other": 0}
var _debug_boss_phase := 0
var progression: ProgressionController


func _ready() -> void:
	Events.player_died.connect(_on_player_died)
	Events.debug_snapshot_requested.connect(_on_debug_snapshot_requested)
	Events.encounter_started.connect(_on_debug_encounter_started)
	Events.boss_started.connect(func(_id, title, health): _debug_log("Boss started / %s / %.0f HP" % [title, health]))
	Events.boss_health_changed.connect(_on_debug_boss_health_changed)
	Events.boss_defeated.connect(func(id): _debug_log("Boss defeated / %s / recovery 8s" % id))
	Events.upgrade_changed.connect(_on_debug_upgrade_changed)
	Events.debug_enemy_removed.connect(_on_debug_enemy_removed)
	Events.plasma_collected.connect(_on_debug_plasma_collected)
	$waveGenerator.enemy_spawned.connect(_on_debug_enemy_spawned)
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	global.reset_run()
	Events.score_changed.emit(0)
	if $music.stream:
		$music.stream.loop = true
	var offsets := [Vector2(-25, 0), Vector2(25, 0)] if global.coop else [Vector2.ZERO]
	nbr_Player = offsets.size()
	var registered: Array[Player] = []
	for i in nbr_Player:
		registered.append(_spawn_player(i == 1, offsets[i]))
	progression = ProgressionController.new()
	progression.name = "ProgressionController"
	add_child(progression)
	progression.start(registered, global.run_random.upgrades)


func _layout_for_viewport() -> void:
	_layout_for_width(get_viewport_rect().size.x)


func _layout_for_width(viewport_width: float) -> void:
	var side_width := maxf((viewport_width - CORE_WIDTH) * 0.5, 0.0)
	$CombatFeedback.position.x = CORE_WIDTH * 0.5 + side_width
	$hud.offset = Vector2(side_width, 0.0)
	$hud/leftRail.offset_left = -side_width
	$hud/leftRail.offset_right = 104.0
	$hud/rightRail.offset_left = 536.0
	$hud/rightRail.offset_right = CORE_WIDTH + side_width
	$waveGenerator.position.x = side_width
	$playerSpawn.position.x = CORE_WIDTH * 0.5 + side_width
	$ForegroundSpeedParticles.position.x = CORE_WIDTH * 0.5 + side_width

func _spawn_player(is_p2: bool, offset: Vector2) -> Player:
	var p = preload("res://scenes/player/player.tscn").instantiate()
	p.set_Player_2 = is_p2
	p.position = $playerSpawn.global_position + offset
	add_child(p, true)
	return p

func _on_player_died() -> void:
	nbr_Player -= 1
	_debug_log("Player lost; %d alive" % nbr_Player)
	if nbr_Player <= 0:
		$waveGenerator.stop_run()
		if progression: progression.cancel()
		call_deferred("_request_game_over")

func _request_game_over() -> void:
	Events.game_over_requested.emit()

func _debug_log(message: String) -> void:
	if not global.Debug:
		return
	_debug_events.push_front("%s  %s" % [global.format_survival_time(global.survival_time), message])
	if _debug_events.size() > 64:
		_debug_events.pop_back()

func _on_debug_encounter_started(id: StringName, number: int) -> void:
	_debug_log("Encounter %d / %s" % [number, id])

func _on_debug_boss_health_changed(health: float, maximum: float, phase: int) -> void:
	if health > 0.0 and phase != _debug_boss_phase:
		_debug_boss_phase = phase
		if phase > 1:
			_debug_log("Boss phase %d / %.1f/%.1f HP" % [phase, health, maximum])

func _on_debug_upgrade_changed(player_id: String, effect: int, rank: int, maximum: int) -> void:
	if rank > 0:
		_debug_log("%s / %s %d/%d" % [player_id, UpgradeDefinition.Effect.keys()[effect], rank, maximum])

func _on_debug_enemy_removed(_family_id: StringName, reason: String) -> void:
	if global.Debug and _debug_removed.has(reason):
		_debug_removed[reason] += 1

func _on_debug_plasma_collected(amount: float) -> void:
	_debug_log("Plasma collected +%.1f" % amount)

func _on_debug_enemy_spawned(enemy: Enemy) -> void:
	if not global.Debug:
		return
	var count := 1
	for child in enemy.get_children():
		if child is Enemy:
			count += 1
	var second := floori(global.survival_time)
	_debug_spawn_total += count
	_debug_spawn_buckets[second] = _debug_spawn_buckets.get(second, 0) + count
	_prune_debug_spawn_buckets(second)
	if enemy.elite:
		_debug_log("Elite spawned / %s" % enemy.definition.id)

func _prune_debug_spawn_buckets(second: int) -> void:
	for key in _debug_spawn_buckets.keys():
		if key <= second - 60:
			_debug_spawn_buckets.erase(key)

func _on_debug_snapshot_requested() -> void:
	if not global.Debug:
		return
	var players: Array[Dictionary] = []
	for child in get_children():
		if child is Player:
			players.append(child.get_debug_snapshot())
	_prune_debug_spawn_buckets(floori(global.survival_time))
	var recent_spawns := 0
	for count in _debug_spawn_buckets.values():
		recent_spawns += count
	Events.debug_snapshot_updated.emit({
		"paused": get_tree().paused, "score": global.score, "combo": global.combo,
		"combo_multiplier": global.combo_multiplier(global.combo), "combo_left": global.combo_time_left,
		"players_alive": nbr_Player, "players": players,
		"director": $waveGenerator.get_debug_snapshot(), "pool": $projectilePool.get_debug_snapshot(),
		"progression": progression.progression.snapshot() if progression else {},
		"xp_pool": progression.pool.snapshot() if progression else {},
		"spawn_total": _debug_spawn_total, "spawns_last_minute": recent_spawns,
		"enemy_removed": _debug_removed.duplicate(),
		"events": _debug_events.duplicate(),
		"performance": {
			"fps": Engine.get_frames_per_second(), "process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			"memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			"video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
			"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"collision_pairs": Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS),
			"viewport": get_viewport_rect().size,
		},
	})

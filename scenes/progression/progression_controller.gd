class_name ProgressionController
extends Node

const CONFIG: ProgressionConfig = preload("res://data/progression/progression_config.tres")
const CATALOG: UpgradeTable = preload("res://data/upgrades/foundation_catalog.tres")
static var _next_selection_id := 0
var progression := RunProgression.new(CONFIG)
var players: Array[Player] = []
var pool: XpOrbPool
var selection_id := 0
var offers := {}
var confirmed := {}
var _random: RandomNumberGenerator
var _running := false
var _scheduled := false
var _batch_active := false
var _visible_selection_id := 0

func _ready() -> void:
	pool = XpOrbPool.new()
	pool.name = "XpOrbPool"
	add_child(pool)
	Events.xp_spawn_requested.connect(_spawn_xp)
	Events.xp_collected.connect(_collect_xp)
	Events.upgrade_choice_requested.connect(_choose)

func start(registered: Array[Player], random: RandomNumberGenerator) -> void:
	players = registered.duplicate()
	_random = random
	progression.reset()
	_running = true
	pool.start(living_players)
	_publish()
	for player in living_players(): player.publish_build()

func living_players() -> Array[Player]:
	var result: Array[Player] = []
	for player in players:
		if is_instance_valid(player) and player.state in [Player.State.ACTIVE, Player.State.HIT]:
			result.append(player)
	return result

func _spawn_xp(amount: int, world_position: Vector2) -> void:
	if _running: pool.spawn(amount, world_position)

func _collect_xp(amount: int, _collector_id: StringName) -> void:
	if not _running:
		return
	progression.add_xp(amount)
	_publish()
	_schedule_selection()

func _schedule_selection() -> void:
	if _scheduled or not _running:
		return
	_scheduled = true
	call_deferred("_advance_selection")

func _advance_selection() -> void:
	_scheduled = false
	if get_parent().is_queued_for_deletion():
		cancel()
		return
	if not _running or not offers.is_empty():
		return
	var eligible := living_players()
	if eligible.is_empty():
		cancel()
		return
	if progression.pending_count() == 0:
		if _batch_active:
			_batch_active = false
			Events.upgrade_selection_finished.emit(_visible_selection_id)
		return
	var level := progression.take_selection_level()
	_next_selection_id += 1
	selection_id = _next_selection_id
	confirmed.clear()
	var participants := {}
	for player in eligible:
		participants[StringName(player.id_Player)] = {"build": player.loadout.foundation_snapshot(), "vitals": {"energy": player.energy, "shield": int(player.shield.power)}}
	var hands := CATALOG.generate_player_offers(participants, _random, CONFIG, level == 2)
	var display := {}
	for id in [&"player1", &"player2"]:
		if not hands.has(id): continue
		if hands[id].offers.is_empty():
			global.add_score(hands[id].fallback_score)
			Events.upgrade_feedback_requested.emit(String(id), "SALVAGE +%d" % hands[id].fallback_score, false)
		else:
			offers[id] = hands[id].offers
			display[id] = {"build": participants[id].build, "offers": hands[id].offers}
	_publish()
	if display.is_empty():
		_schedule_selection()
		return
	_batch_active = true
	_visible_selection_id = selection_id
	var view := progression.snapshot()
	view["selection_level"] = level
	Events.upgrade_selection_requested.emit(selection_id, display, view)

func _choose(id: int, player_id: StringName, upgrade_id: StringName) -> void:
	if not _running or id != selection_id or not offers.has(player_id) or confirmed.has(player_id):
		return
	var chosen: UpgradeDefinition
	for offer in offers[player_id]:
		if offer.id == upgrade_id:
			for definition in CATALOG.upgrades:
				if definition.id == upgrade_id: chosen = definition
	if chosen == null: return
	for player in living_players():
		if player.id_Player != player_id: continue
		if not player.apply_upgrade(chosen).applied: return
		confirmed[player_id] = true
		Events.upgrade_choice_applied.emit(id, player_id)
		Events.powerup_collected.emit(chosen)
		if confirmed.size() == offers.size():
			offers.clear()
			_schedule_selection()
		return

func _publish() -> void:
	Events.progression_changed.emit(progression.snapshot())

func cancel() -> void:
	_running = false
	offers.clear()
	confirmed.clear()
	if pool: pool.stop()
	if _batch_active:
		_batch_active = false
		Events.upgrade_selection_cancelled.emit(_visible_selection_id)

func _exit_tree() -> void:
	cancel()

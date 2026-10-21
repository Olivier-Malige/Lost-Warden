extends Node2D

const UPGRADE: UpgradeDefinition = preload("res://data/upgrades/escort_drone.tres")
const MAX_LAG := 8.0
const HOVER_AMPLITUDE := Vector2(0.65, 1.5)

var wait := 0.0
var age := 0.0
var flash := 0.0
var team := 0
var bank := 0
var _last_anchor := Vector2.ZERO
var _lag := Vector2.ZERO
var _glide := Vector2.ZERO
var _hover_phase := 0.0
var _follow_response := 9.0
var _reactors: Array[Node2D] = []
var _reactor_mounts: Array[Node2D] = []
@onready var hull: Sprite2D = $Hull
@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	add_to_group(&"escort_drone")
	var player := get_parent() as Player
	team = 1 if player.set_Player_2 else 0
	_last_anchor = global_position
	_hover_phase = team * 1.4 + (2.1 if position.x < 0 else 0.0)
	_follow_response = 11.0 if position.x < 0 else 9.0
	hull.frame = team * 18
	for side in [-1, 1]:
		var mount := Node2D.new()
		mount.position = Vector2(side * 3.5, 5)
		mount.scale = Vector2(0.45, 0.45)
		mount.show_behind_parent = true
		add_child(mount)
		var reactor := player.effects.create_reactor_copy()
		if reactor:
			reactor.position = Vector2.ZERO
			mount.add_child(reactor)
			_reactors.append(reactor)
			_reactor_mounts.append(mount)
	_sync_edge_offset()

func tick(delta: float) -> void:
	var player := get_parent() as Player
	if player == null or player.state >= Player.State.DYING or get_tree().paused:
		return
	_sync_edge_offset()
	wait = maxf(0.0, wait - delta)
	if wait > 0.0:
		return
	var service := PlayerHitEffects.find_service(player)
	if service == null or not service.owner_alive(StringName(player.id_Player)):
		return
	var targets := CombatTargeting.targets(player.get_parent(), muzzle.global_position, UPGRADE.weapon.target_range, {}, true, [], UPGRADE.weapon.forward_angle_degrees)
	if targets.is_empty():
		return
	var rank := player.loadout.rank_for(UpgradeDefinition.Effect.ESCORT_DRONE)
	wait = UPGRADE.interval_value(rank) * maxf(player.loadout.fire_delay / 0.20, 0.6)
	var direction := targets[0].global_position - muzzle.global_position
	if service.queue_drone_bolt(StringName(player.id_Player), UPGRADE, rank, muzzle.global_position, direction,
		player.loadout.direct_damage_multiplier, player.loadout.acquired_ranks, player.loadout.critical_chance):
		flash = 0.1

func _process(delta: float) -> void:
	age += delta
	if delta > 0.0:
		_lag = (_lag + _last_anchor - global_position).limit_length(MAX_LAG)
		_last_anchor = global_position
		_lag *= exp(-_follow_response * delta)
		var phase := age * (2.4 if position.x < 0 else 2.1) + _hover_phase
		_glide = _lag + Vector2(sin(phase * 0.7), sin(phase)) * HOVER_AMPLITUDE
	_sync_edge_offset()
	flash = maxf(0.0, flash - delta)
	var player := get_parent() as Player
	bank = 1 if player._motion.x < 0 else (2 if player._motion.x > 0 else 0)
	hull.frame = (team * 3 + bank) * 6 + (4 + mini(int((0.1 - flash) / 0.05), 1) if flash > 0.0 else int(age / 0.08) % 4)
	for reactor in _reactors:
		player.effects.sync_reactor_copy(reactor)

# Keep shoulder anchors fixed, tucking outer companions away from the HUD at the edges.
func _sync_edge_offset() -> void:
	var player := get_parent() as Player
	var screen := get_global_transform_with_canvas().origin
	var side_width := maxf((get_viewport_rect().size.x - 640.0) * 0.5, 0.0)
	var left := player.STATS.bound_min.x + side_width
	var right := player.STATS.bound_max.x + side_width
	var offset := _glide.round()
	offset.x = clampf(screen.x + offset.x, left, right) - screen.x
	var desired_y := screen.y + offset.y
	if screen.x < left or screen.x > right:
		desired_y += -20.0 if screen.y >= 44.0 else 36.0
	offset.y = clampf(desired_y, 12.0, get_viewport_rect().size.y - 12.0) - screen.y
	hull.position = offset
	muzzle.position = offset + Vector2(0, -7)
	for mount in _reactor_mounts:
		mount.position = offset + Vector2(-3.5 if mount == _reactor_mounts[0] else 3.5, 5)

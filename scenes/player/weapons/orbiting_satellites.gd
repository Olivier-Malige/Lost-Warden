extends Node2D

const UPGRADE: UpgradeDefinition = preload("res://data/upgrades/orbiting_satellites.tres")
const SHEET := preload("res://assets/sprites/player/weapons/orbiting_satellites_sheet.png")
const Layers := preload("res://core/collision_layers.gd")

var rank := 0
var phase := 0.0
var spin_phase := 0.0
var age := 0.0
var _team := 0
var _orbiters: Array[Area2D] = []
var _flashes: Array[float] = []
var _cooldowns: Dictionary[StringName, Dictionary] = {}
var _rebuild_scheduled := false
var _stopping := false

func _ready() -> void:
	add_to_group(&"orbiting_satellites")
	_team = 1 if get_parent().set_Player_2 else 0
	phase = PI if _team == 1 else 0.0
	spin_phase = phase

func sync_rank(value: int) -> void:
	if _stopping or value == rank:
		return
	rank = value
	if not _rebuild_scheduled:
		_rebuild_scheduled = true
		call_deferred("_rebuild_orbiters")

func _rebuild_orbiters() -> void:
	_rebuild_scheduled = false
	if _stopping or not is_inside_tree():
		return
	var count := UPGRADE.support_count(rank)
	while _orbiters.size() > count:
		var orb := _orbiters.pop_back() as Area2D
		_flashes.pop_back()
		_disable_orbiter(orb)
		orb.queue_free()
	while _orbiters.size() < count:
		var orb := Area2D.new()
		orb.name = "Satellite%d" % (_orbiters.size() + 1)
		orb.collision_layer = 0
		orb.collision_mask = Layers.ENEMY | Layers.ASTEROID
		orb.monitorable = false
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = UPGRADE.contact_radius
		shape.shape = circle
		orb.add_child(shape)
		var sprite := Sprite2D.new()
		sprite.texture = SHEET
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.hframes = 8
		sprite.vframes = 2
		sprite.z_index = 4
		orb.add_child(sprite)
		add_child(orb)
		_orbiters.append(orb)
		_flashes.append(0.0)
	_sync_positions()

func _sync_positions() -> void:
	for index in _orbiters.size():
		var angle := phase + TAU * index / _orbiters.size()
		var orb := _orbiters[index]
		orb.position = Vector2.from_angle(angle) * UPGRADE.orbit_radius
		var spin_angle := spin_phase + TAU * index / _orbiters.size()
		var frame := 4 + mini(int((0.2 - _flashes[index]) / 0.05), 3) if _flashes[index] > 0 else int(age / 0.08) % 4
		var sprite := orb.get_child(1) as Sprite2D
		sprite.rotation = spin_angle
		sprite.frame = _team * 8 + frame

func _physics_process(delta: float) -> void:
	if _stopping or get_tree().paused:
		return
	var player := get_parent() as Player
	if player.state >= Player.State.DYING:
		shutdown()
		return
	age += delta
	phase = fposmod(phase + TAU * delta / UPGRADE.orbit_period, TAU)
	spin_phase = fposmod(spin_phase + TAU * delta / UPGRADE.spin_period, TAU)
	for index in _flashes.size(): _flashes[index] = maxf(0.0, _flashes[index] - delta)
	for group in _cooldowns.keys():
		var target: Node = _cooldowns[group].target.get_ref()
		_cooldowns[group].left -= delta
		if not is_instance_valid(target) or not target.is_inside_tree() or target.is_queued_for_deletion() or target.get("destroyed") == true or _cooldowns[group].left <= 0.0:
			_cooldowns.erase(group)
	_sync_positions()
	_resolve_contacts()

func _resolve_contacts() -> void:
	if _stopping or get_tree().paused:
		return
	var player := get_parent() as Player
	var world := player.get_parent() as Node2D
	var service := PlayerHitEffects.find_service(player)
	if service == null or not service.owner_alive(StringName(player.id_Player)):
		return
	var contacts: Array[Dictionary] = []
	for index in _orbiters.size():
		for target in _orbiters[index].get_overlapping_areas():
			if CombatTargeting.eligible(world, target):
				contacts.append({"target": target, "group": CombatTargeting.group_identity(target), "id": CombatTargeting.identity(target), "index": index})
	contacts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.group != b.group: return String(a.group) < String(b.group)
		if a.id != b.id: return String(a.id) < String(b.id)
		return a.index < b.index
	)
	for contact in contacts:
		if _stopping or not service.owner_alive(StringName(player.id_Player)):
			return
		if _cooldowns.has(contact.group):
			continue
		if service.resolve_satellite_contact(StringName(player.id_Player), contact.target, UPGRADE.rank_value(rank), player.loadout.direct_damage_multiplier,
			player.loadout.acquired_ranks, player.loadout.critical_chance, _orbiters[contact.index].global_position):
			_cooldowns[contact.group] = {"target": weakref(CombatTargeting.damage_group(contact.target)), "left": UPGRADE.contact_cooldown * maxf(player.loadout.fire_delay / 0.20, 0.6)}
			_flashes[contact.index] = 0.2
	_sync_positions()

func _disable_orbiter(orb: Area2D) -> void:
	orb.set_deferred("monitoring", false)
	orb.set_deferred("monitorable", false)
	(orb.get_child(0) as CollisionShape2D).set_deferred("disabled", true)

func shutdown() -> void:
	if _stopping:
		return
	_stopping = true
	set_physics_process(false)
	hide()
	_cooldowns.clear()
	for orb in _orbiters: _disable_orbiter(orb)
	call_deferred("queue_free")

extends SceneTree

var checks := 0
var failures := 0
var globals: Node
var events: Node
var stage: Node2D
var effects: Variant
var pool: Variant
var p1: Variant
var p2: Variant
var accepted: Array = []
var xp_events := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 3:
		await physics_frame
		await process_frame

func enemy(id: StringName, at: Vector2, health := 20.0) -> Variant:
	var target = load("res://scenes/enemies/drone.tscn").instantiate()
	target.definition = target.definition.duplicate()
	target.definition.max_health = health
	target.definition.xp_drop_chance = 100
	target.definition.plasma_drop_chance = 0
	var context := EnemySpawnContext.new()
	context.combat_id = id
	target.configure_spawn(context)
	target.position = at
	stage.add_child(target)
	target.set_physics_process(false)
	for audio in target.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stream = null
	return target

func fire(player: Node) -> Variant:
	player.weapons.fire_primary()
	var shot: Variant = null
	for candidate in get_nodes_in_group("player_Shot"):
		if not candidate.get_meta("pooled", false) and candidate.player_Id == player.id_Player:
			shot = candidate
	check(shot != null and shot.hit_snapshot != null, "real weapon emission must attach a root snapshot")
	shot.set_physics_process(false)
	return shot

func root_hit(damage := 10.0) -> Variant:
	return effects.create_hit(&"player1", damage, damage)

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = true
	globals.reset_run(123)
	root.size = Vector2i(640, 400)
	stage = Node2D.new()
	root.add_child(stage)
	pool = load("res://scenes/combat/projectile_pool.gd").new()
	stage.add_child(pool)
	effects = load("res://scenes/combat/player_hit_effects.gd").new()
	effects.name = "PlayerHitEffects"
	stage.add_child(effects)
	p1 = load("res://scenes/player/player.tscn").instantiate()
	p2 = load("res://scenes/player/player.tscn").instantiate()
	p2.set_Player_2 = true
	p1.position = Vector2(200, 350)
	p2.position = Vector2(450, 350)
	stage.add_child(p1)
	stage.add_child(p2)
	for player in [p1, p2]:
		player.set_physics_process(false)
		player.set_process(false)
		for kind in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
			for audio in player.find_children("*", kind, true, false):
				audio.stream = null
	effects.start([p1, p2], globals.run_random)
	effects.hit_accepted.connect(func(hit, target, position, first): accepted.append({"hit": hit, "target": target, "position": position, "first": first}))
	events.xp_spawn_requested.connect(func(_amount, _position): xp_events += 1)
	var target = enemy(&"target_a", Vector2(200, 150))
	check(not target.receive_player_hit(0.0) and not target.receive_player_hit(NAN) and target.life == 20, "nonpositive/nonfinite hits must reject without credit")
	p1.loadout.apply_foundation(&"damage")
	var shot = fire(p1)
	var saved: PlayerHitSnapshot = shot.hit_snapshot.copy()
	var values := saved.snapshot()
	values.modifiers[&"damage"] = 999
	p1.loadout.apply_foundation(&"damage")
	check(saved.owner_id() == &"player1" and saved.source_sequence() == 1 and saved.modifier_rank(&"damage") == 1 and saved.damage() == 1.25, "emission values must be detached from loadout and public snapshots")
	var impact: Vector2 = target.position + Vector2(0, 3)
	shot.position = impact
	await settle()
	check(is_equal_approx(target.life, 18.75) and target.last_player_hit_owner == &"player1", "real contact applies snapshotted damage once and records its owner")
	check(shot.get_meta("pooled", false) and shot.hit_snapshot == null and effects.get_debug_snapshot().roots == 0, "callback recycling must immediately retire its snapshot and root lease")
	check(accepted.size() == 1 and accepted[0].first and accepted[0].position == impact, "one direct root snapshots the actual impact before recoil or recycling")
	shot.remaining_penetrations = 8
	shot.steering_target = weakref(target)
	shot.remaining_lifetime = 0.5
	var reused = fire(p2)
	check(reused == shot and reused.hit_snapshot.owner_id() == &"player2" and reused.hit_snapshot.source_sequence() == 1, "pool reuse must replace owner and personal source sequence")
	check(reused.damage == 1.0 and reused.hit_snapshot.modifier_rank(&"damage") == 0 and reused.remaining_penetrations == 0 and reused.steering_target == null and reused.remaining_lifetime == -1.0 and reused._visited_groups.is_empty(), "reuse must clear modifiers, penetration, steering and lifetime")
	ProjectilePool.despawn(reused)
	await settle()
	target.life = 1
	var score_before: int = globals.score
	shot = fire(p1)
	shot.position = target.position
	await settle()
	check(target.destroyed and xp_events == 1 and globals.score > score_before, "a real lethal hit awards normal score and XP exactly once")
	check(not target.receive_player_hit(100.0, &"player2") and xp_events == 1, "a destroyed target cannot accept another credit or reward")
	await check_deferred_children()
	await check_boss_groups()
	await check_plasma_and_reflection()
	await check_owner_and_generation()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_webp(ProjectSettings.globalize_path("res://phase3_hit_contract.webp"), true) == OK, "native combat capture must save")
	effects.cancel()
	check(effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "world cancellation must clear all owned bookkeeping")
	stage.free()
	await process_frame
	print("Player hit contract: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check_deferred_children() -> void:
	var packet = root_hit(2.0)
	var packed: PackedScene = load("res://scenes/player/player_shot.tscn")
	check(effects.queue_projectile(packet, packed, Vector2(530, 300), Vector2.ZERO, 1.0, 1, 0.5), "reserve a copied child before materialization")
	check(not effects.queue_projectile(packet, packed, Vector2.ZERO, Vector2.ZERO, 1.0, 1), "pending reservations must obey the same cap as active children")
	effects.release_root(packet)
	check(effects.get_debug_snapshot() == {"roots": 1, "requests": 1, "reservations": 1}, "queued work must retain its released root's history")
	await settle()
	var child: Variant = null
	for candidate in get_nodes_in_group("player_Shot"):
		if not candidate.get_meta("pooled", false):
			child = candidate
	check(child != null and child.damage == 1.0 and child.hit_snapshot.kind() == PlayerHitSnapshot.Kind.SECONDARY and not child.hit_snapshot.is_critical(), "deferred child keeps copied pre-critical values and disables recursive modifiers")
	check(not effects.queue_projectile(child.hit_snapshot, packed, Vector2.ZERO, Vector2.ZERO, 1.0, 1), "secondary damage cannot request recursive children")
	var target = enemy(&"secondary_target", Vector2(530, 200), 1.0)
	var before := xp_events
	child.position = target.position
	await settle()
	check(target.destroyed and target.last_player_hit_owner == &"player1" and xp_events == before + 1 and not accepted.back().first, "secondary collision kills retain owner/reward without another first-impact trigger")
	check(effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "child retirement releases both reservation and root")
	var callback_target = enemy(&"callback_target", Vector2(250, 200))
	var queued: Array = []
	effects.hit_accepted.connect(func(hit, _target, _position, _first):
		queued.append(effects.queue_projectile(hit, packed, Vector2(500, 280), Vector2.ZERO, 1.0, 1, 0.5))
	, CONNECT_ONE_SHOT)
	var source = fire(p1)
	var source_sequence: int = source.hit_snapshot.source_sequence()
	source.position = callback_target.position
	await settle()
	check(queued == [true] and source.get_meta("pooled", false) and source.hit_snapshot == null, "a real physics callback can reserve work before its source recycles")
	var callback_child: Variant = null
	for candidate in get_nodes_in_group("player_Shot"):
		if not candidate.get_meta("pooled", false):
			callback_child = candidate
	check(callback_child != null and callback_child.hit_snapshot.source_sequence() == source_sequence and callback_child.damage == 0.75, "deferred work cannot read a recycled source's changed values")
	callback_child.remaining_lifetime = 0.001
	await settle()
	check(callback_child.get_meta("pooled", false) and effects.get_debug_snapshot().roots == 0 and effects.get_debug_snapshot().reservations == 0, "bounded child expiry must release root and capacity")

func check_boss_groups() -> void:
	var data: BossDefinition = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.combat_id = &"boss_a"
	boss.configure_spawn(context)
	boss.position = Vector2(320, 82)
	stage.add_child(boss)
	boss.set_physics_process(false)
	var port = boss.get_node("PortCannon")
	var starboard = boss.get_node("StarboardCannon")
	var armor = boss.get_node("Armor")
	var packet = root_hit()
	check(not effects.resolve_hit(packet, boss) and not effects.resolve_hit(packet, port), "entering boss and cannons reject without granting group history")
	boss.attack = boss.Attack.IDLE
	check(not effects.resolve_hit(packet, armor) and not armor.hitByPlayerShot, "armor rejects without player credit")
	check(effects.resolve_hit(packet, port) and not effects.resolve_hit(packet, boss) and not effects.resolve_hit(packet, starboard), "one root can accept only one surface of the logical boss")
	var group_health: float = boss.life + port.life + starboard.life
	check(effects.queue_projectile(packet, load("res://scenes/player/player_shot.tscn"), boss.global_position, Vector2.ZERO, 1.0, 1), "boss root history can be reserved for a pending child")
	effects.release_root(packet)
	await settle()
	check(is_equal_approx(boss.life + port.life + starboard.life, group_health) and effects.get_debug_snapshot().roots == 0, "a real deferred child cannot hit another boss part after its root was released")
	var next_packet = root_hit()
	check(effects.resolve_hit(next_packet, boss), "a new root may damage the boss normally")
	effects.release_root(next_packet)
	port.position = Vector2.ZERO
	starboard.position = Vector2.ZERO
	armor.position = Vector2(200, 0)
	var before: float = boss.life + port.life + starboard.life
	var shot = fire(p1)
	var expected: float = shot.damage
	shot.piercing = true
	shot.position = boss.position
	await settle()
	check(is_equal_approx(before - boss.life - port.life - starboard.life, expected), "real overlapping boss callbacks cannot multiply one root's damage")
	ProjectilePool.despawn(shot)
	await settle()
	boss.free()

func check_plasma_and_reflection() -> void:
	var target = enemy(&"plasma_target", Vector2(100, 180), 100.0)
	var beam = load("res://scenes/player/beam/continuous_beam.tscn").instantiate()
	stage.add_child(beam)
	beam.position = Vector2(100, 350)
	beam.beam_audio.stream = null
	beam.activate("player1", 3.0, true)
	beam.set_physics_process(false)
	await settle()
	beam._damage_overlaps()
	check(is_equal_approx(target.life, 95.5) and target.last_player_hit_owner == &"player1" and not accepted.back().first and accepted.back().hit.authored_base() == 3.0, "plasma preserves its authored/overdrive damage without gun modifiers or procs")
	beam.deactivate()
	beam.free()
	var reflected = ProjectilePool.spawn(load("res://scenes/combat/mother_ship_shot.tscn"), p2.shield.global_position, stage)
	reflected.set_physics_process(false)
	p2.shield.power = 1
	await settle()
	check(reflected.trowbackByShield and reflected.reflected_owner_id == &"player2" and reflected.hit_snapshot.kind() == PlayerHitSnapshot.Kind.REFLECTED, "actual shield contact snapshots the reflecting player's ownership")
	var reflected_damage: float = reflected.damage
	reflected.position = target.position
	await settle()
	check(is_equal_approx(target.life, 95.5 - reflected_damage) and target.last_player_hit_owner == &"player2" and not accepted.back().first, "reflected collisions use original enemy damage and cannot trigger offensive modifiers")
	var reused = ProjectilePool.spawn(load("res://scenes/combat/mother_ship_shot.tscn"), Vector2(400, 30), stage)
	check(reused == reflected and not reused.trowbackByShield and reused.hit_snapshot == null and reused.reflected_owner_id == &"" and reused.noDamageToGroup == reused._base_no_damage_group, "enemy-shot reuse restores exclusion and clears reflection ownership")
	ProjectilePool.despawn(reused)
	await settle()

func check_owner_and_generation() -> void:
	var packet = root_hit()
	var packed: PackedScene = load("res://scenes/player/player_shot.tscn")
	effects.queue_projectile(packet, packed, Vector2(500, 300), Vector2.ZERO, 1.0, 1)
	p1.set_state(p1.State.DYING)
	check(effects.get_debug_snapshot().requests == 0 and effects.get_debug_snapshot().reservations == 0 and effects.create_hit(&"player1", 1, 1) == null, "DYING cancels new requests and blocks new owner emissions")
	var active_shots := get_nodes_in_group("player_Shot").filter(func(shot): return not shot.get_meta("pooled", false)).size()
	p1.weapons.fire_primary()
	check(get_nodes_in_group("player_Shot").filter(func(shot): return not shot.get_meta("pooled", false)).size() == active_shots, "weapon entry points cannot emit new roots for a DYING owner")
	var target = enemy(&"surviving_direct", Vector2(300, 200))
	check(effects.resolve_hit(packet, target) and not accepted.back().first, "already flying direct damage remains valid after DYING without new proc opportunities")
	effects.release_root(packet)
	var old = effects.create_hit(&"player2", 2, 2)
	effects.queue_projectile(old, packed, Vector2(500, 300), Vector2.ZERO, 0.1, 1)
	effects.start([p2], globals.run_random)
	var fresh = effects.create_hit(&"player2", 2, 2)
	check(not effects.resolve_hit(old, target) and effects.resolve_hit(fresh, target), "a restarted service cannot resolve an earlier generation against reused source sequences")
	effects.release_root(fresh)
	await settle()
	check(effects.get_debug_snapshot() == {"roots": 0, "requests": 0, "reservations": 0}, "generation cancellation leaves no stale emissions or root leases")

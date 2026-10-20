extends SceneTree

var checks := 0
var failures := 0
var stage: Node2D
var pool: Variant
var players := []
var receipts: Array[Array] = []
var callbacks := 0
var audio_survived := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func living_players() -> Array:
	return players.filter(func(player): return is_instance_valid(player) and player.state in [player.State.ACTIVE, player.State.HIT])

func receipt(amount: int, collector: StringName) -> void:
	receipts.append([amount, collector])
	audio_survived = pool._audio.playing and pool._audio.get_parent() == pool

func spawn(amount: int, point: Vector2) -> Variant:
	pool.spawn(amount, point)
	var entry: Dictionary = pool._entries.back()
	pool._materialize(entry)
	entry.node.set_physics_process(false)
	return entry.node

func run() -> void:
	root.get_node("global").coop = true
	stage = Node2D.new()
	root.add_child(stage)
	var owner := Node.new()
	stage.add_child(owner)
	pool = load("res://scenes/progression/xp_orb_pool.gd").new()
	owner.add_child(pool)
	for p2 in [false, true]:
		var player = load("res://scenes/player/player.tscn").instantiate()
		player.set_Player_2 = p2
		stage.add_child(player)
		player.global_position = Vector2(240 if p2 else 200, 300)
		player.set_physics_process(false)
		players.append(player)
	players.reverse()
	pool.start(living_players)
	check(pool.collection_stream != null and pool.collection_stream.resource_path.ends_with("xp_orb_collect.wav") and pool._audio.bus == &"Sounds", "live orbs must provide their dedicated XP collection cue on the Sounds bus")
	pool.collection_stream = load("res://assets/audio/sfx/ui/menu_select.wav")
	root.get_node("Events").xp_collected.connect(receipt)
	var p1: Variant = players[1]
	var p2: Variant = players[0]
	var orb: Variant = spawn(4, p1.global_position)
	var large_glow_scale: Vector2 = orb.get_node("XpGlow").scale
	check(orb.get_node("XpGlow").material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "XP halos must use additive light without changing collection geometry")
	orb.area_entered.connect(func(_area): callbacks += 1)
	for frame in 4: await physics_frame
	await process_frame
	check(callbacks > 0 and receipts == [[4, &"player1"]], "real Area2D callbacks must credit shared XP exactly once")
	check(audio_survived, "optional collection audio must belong outside the immediately recycled orb")
	check(orb.get_meta("pooled") and orb.value == 0 and not orb.monitoring and not orb.is_physics_processing(), "collected orbs must park and clear their value/collision/processing state")
	orb._on_screen_exited()
	pool.release(orb)
	check(pool.collected == 4 and pool.lost == 0, "parked exits and repeated release must not spend XP twice")
	var reused: Variant = spawn(1, Vector2(220, 300))
	check(reused == orb and not reused.collected and reused.target == null and reused.value == 1, "pool reuse must clear collection and target state")
	check(reused.get_node("XpGlow").scale.x < large_glow_scale.x and is_equal_approx(reused.get_node("XpGlow").modulate.a, 0.8), "recycled low-value orbs must restore their smaller halo and initial pulse")
	reused._physics_process(0.001)
	check(reused.target.get_ref() == p1, "equal distance must choose P1 even if registration order is reversed")
	p2.global_position = reused.global_position + Vector2(1, 0)
	reused._physics_process(0.001)
	check(reused.target.get_ref() == p1, "a nearer second player must not steal a retained homing target")
	p1.state = p1.State.DYING
	reused._physics_process(0.001)
	check(receipts.back() == [1, &"player2"], "a dying target must permit reacquisition and collection by the living partner")
	await process_frame
	p2.state = p2.State.DYING
	var falling: Variant = spawn(2, Vector2(300, 100))
	falling._physics_process(0.1)
	check(falling.get_node("XpGlow").modulate.a > 0.8, "active orb halos must pulse while the orb falls")
	check(is_equal_approx(falling.position.y, 106), "unattracted orbs must fall at sixty native pixels per second")
	falling.global_position.y = root.get_visible_rect().size.y + 30.0
	falling._physics_process(0.01)
	await process_frame
	check(pool.lost == 2, "ordinary off-screen loss must recycle value once")
	for index in 140:
		pool.spawn(1, Vector2(300, 100))
	check(pool.snapshot().reserved + pool.snapshot().active == 128 and pool.snapshot().value == 140, "active plus reserved saturation must retain every emitted XP point")
	check(pool._entries[0].amount == 13, "overflow must merge into the oldest reservation deterministically")
	await process_frame
	check(pool.snapshot().reserved == 0 and pool.snapshot().active == 128, "deferred materialization must keep the active cap")
	var oldest: Variant = pool._entries[0].node
	check(oldest.value == 13 and oldest.get_node("Sprite2D").frame == 1, "merged high-value orbs must retain value and use their distinct silhouette")
	check(oldest.get_node("XpGlow").scale == large_glow_scale, "saturation merges must update high-value halo size without adding new glow nodes")
	pool.spawn(10, Vector2(310, 100))
	check(oldest.value == 23 and pool.snapshot().value == 150, "overflow may also merge into an already active oldest orb")
	pool.release(oldest)
	await process_frame
	var next: Variant = spawn(5, Vector2(320, 100))
	check(next == oldest and next.value == 5 and next.target == null and not next.collected, "saturated reuse must reset all old collection/target/value fields")
	check(pool.snapshot().emitted == pool.snapshot().value + pool.collected + pool.lost, "emitted XP must equal active/reserved value plus collected and lost XP")
	pool._next_sound_at = 0
	pool.collect(next, &"player1")
	var voice: AudioStreamPlayback = pool._audio.get_stream_playback()
	check(voice != null and pool._audio.playing and is_equal_approx(pool._audio.pitch_scale, 1.12), "high-value collection must start a slightly higher cue owned by the pool")
	var collected_before: int = pool.collected
	for index in 3: pool.collect(pool._entries[0].node, &"player1")
	check(pool.collected == collected_before + 3 and pool._audio.get_stream_playback() == voice, "simultaneous collections must all award XP while sharing the active cue")
	check(pool._audio.process_mode == Node.PROCESS_MODE_ALWAYS and pool._audio.max_polyphony == 2, "collection tails must finish across level-up pause with bounded overlapping voices")
	pool.collection_stream = null
	pool._next_sound_at = 0
	collected_before = pool.collected
	pool.collect(pool._entries[0].node, &"player1")
	check(pool.collected == collected_before + 1, "a missing or replaced collection cue must never block XP credit")
	pool.stop()
	await process_frame
	check(pool.snapshot().active == 0 and pool.snapshot().reserved == 0, "teardown must cancel every active/reserved orb")
	check(pool.emitted == pool.collected + pool.lost, "teardown must account for all uncollected value")
	check(not pool._audio.playing and pool._audio.stream == null, "run teardown must stop and release collection playback")
	pool.spawn(99, Vector2.ZERO)
	check(pool.snapshot().value == 0, "stopped pools must reject late rewards")
	stage.queue_free()
	var stopped_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - stopped_at < 80: await process_frame
	print("XP orbs: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

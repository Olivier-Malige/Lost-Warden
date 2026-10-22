extends Shot

const SPEED_Y := 275.0
const _ProjectileGlow := preload("res://scenes/combat/projectile_glow.gd")

@export var damage := 10
@export var noDamageToGroup := ""
@export var glow_color := Color(1.0, 0.2, 0.1, 0.0)
@export_range(1.0, 3.0, 0.05) var core_brightness := 1.0
@export var glow_spread := Vector2(1.65, 0.85)
var hit_snapshot: PlayerHitSnapshot
var _hit_effects: WeakRef
var _base_no_damage_group := ""
var _base_damage := 0

func _ready() -> void:
	super._ready()
	_base_no_damage_group = noDamageToGroup
	_base_damage = damage
	speedY = SPEED_Y
	_create_projectile_glow()


func _create_projectile_glow() -> void:
	var source_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if source_sprite == null or glow_color.a <= 0.0:
		return
	_ProjectileGlow.create(source_sprite, glow_color, core_brightness, glow_spread)

func prepare() -> void:
	reset_hit_state()
	damage = _base_damage
	noDamageToGroup = _base_no_damage_group
	speedY = SPEED_Y
	speedX = 0.0
	trowbackByShield = false
	rotation = 0
	_restart_flight.call_deferred()

func set_reflected_owner(player: Node) -> void:
	reset_hit_state()
	reflected_owner_id = StringName(player.id_Player)
	var effects := PlayerHitEffects.find_service(self)
	if effects:
		hit_snapshot = effects.create_hit(reflected_owner_id, damage, damage, {}, PlayerHitSnapshot.Kind.REFLECTED)
		_hit_effects = weakref(effects)

func reset_hit_state() -> void:
	var effects: PlayerHitEffects = _hit_effects.get_ref() if _hit_effects else null
	if is_instance_valid(effects):
		effects.release_root(hit_snapshot)
	hit_snapshot = null
	_hit_effects = null
	reflected_owner_id = &""

func _exit_tree() -> void:
	reset_hit_state()


func _restart_flight() -> void:
	if not is_inside_tree() or get_meta("pooled", false):
		return
	var animation_player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player:
		animation_player.stop()
		animation_player.play(&"flight")
		animation_player.advance(0.0)

func is_enemy() -> bool:
	return true

func _on_shot_area_entered(area: Area2D) -> void:
	if get_meta("pooled", false) or get_tree().paused:
		return
	if area.is_in_group("player"):
		if trowbackByShield or PlayerDefenses.intercept_in_world(self):
			return
		if area.get("vitals") != null:
			area.vitals.hit(damage)
		elif area.has_method("_hit_something"):
			area._hit_something(damage)
		ProjectilePool.despawn(self)
	elif area.is_in_group("asteroid"):
		_hit_area(area)
	elif trowbackByShield and (area.is_in_group("enemy") or area.is_in_group("boss_hit_zone")) and not area.is_in_group(noDamageToGroup):
		_hit_area(area)


func _hit_area(area: Area2D) -> void:
	if trowbackByShield and area.has_method("receive_player_hit"):
		var effects: PlayerHitEffects = _hit_effects.get_ref() if _hit_effects else null
		if hit_snapshot and is_instance_valid(effects):
			effects.resolve_hit(hit_snapshot, area, true, global_position)
		else:
			area.receive_player_hit(damage, reflected_owner_id)
	elif area.has_method("_hit_something"):
		area._hit_something(damage)
	ProjectilePool.despawn(self)
